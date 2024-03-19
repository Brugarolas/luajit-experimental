local concat = table.concat
local assert = assert
local error = error
local getinfo = debug.getinfo
local find = string.find
local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local match = string.match
local sub = string.sub
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local forcesetmetatable = debug.setmetatable
local sort = table.sort
local tostring = tostring
local type = type
local pcall = pcall
local require = require

-- Aux functions
local function deepCopy(val, key, circular)
    if type(val) ~= 'table' then
        return val
    end

    -- Check for circular reference using the table reference directly
    if circular[val] then
        return nil, format('Unable to copy circularly referenced values: %q refers to %q', key, circular[val])
    end

    circular[val] = key
    local tbl = {}
    for k, v in pairs(val) do
        local cpy, err = deepCopy(v, key .. '.' .. k, circular)
        if err then
            return nil, err
        end
        tbl[k] = cpy
    end
    circular[val] = nil

    return tbl
end

--- trim_space returns s with all leading and trailing whitespace removed.
--- @param s string
--- @return string
local function trim_space(_, s)
    if type(s) ~= 'string' then
        error(format('invalid argument #1 (string expected, got %s)', type(s)), 2)
    elseif s == '' then
        return ''
    end

    -- remove leading whitespaces
    local _, pos = find(s, '^%s+')
    if pos then
        s = sub(s, pos + 1)
    end

    -- remove trailing whitespaces
    pos = find(s, '%s+$')
    if pos then
        return sub(s, 1, pos - 1)
    end

    return s
end

function split_string(input, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(input, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(input, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(input, delimiter, from)
    end
    table.insert(result, string.sub(input, from))
    return result
end

--- normalize path string
---@param s string
---@return string
local function normalize(s)
    local res = {}
    local len = 0

    -- remove double slash
    s = gsub(s, '/+', '/')
    -- extract segments
    for seg in gmatch(s, '[^/]+') do
        if seg == '..' then
            -- remove last segment if exists
            if len > 0 then
                res[len] = nil
                len = len - 1
            end
        elseif seg ~= '.' then
            -- add segment
            len = len + 1
            res[len] = seg
        end
    end

    local fc = sub(s, 1, 1)
    if fc == '/' then
        -- absolute path
        return '/' .. concat(res, '/')
    elseif fc == '.' then
        -- relative path
        return './' .. concat(res, '/')
    end
    -- relative path
    return concat(res, '/')
end

--- return true if name is a valid package name
--- @param name string
--- @return boolean
local PAT_PKGNAME = '^[a-z0-9]+$'
local function isPackageName(name)
    if type(name) ~= 'string' then
        return false
    end

    for _, v in ipairs(split_string(name, '.')) do
        if not find(v, PAT_PKGNAME) then
            return false
        end
    end

    return true
end

--- return true if name is a valid module name
--- @param name string
--- @return boolean
local PAT_MODNAME = '^[A-Z][a-zA-Z0-9]*$'
local function isModuleName(name)
    return type(name) == 'string' and find(name, PAT_MODNAME) ~= nil
end

--- return true if name starts with two underscores(_)
--- @param name string
--- @return boolean
local PAT_METAMETHOD = '^__[a-z]+$'
local function isMetamethodName(name)
    return type(name) == 'string' and find(name, PAT_METAMETHOD) ~= nil
end

local is = {
    packageName = isPackageName,
    PAT_MODNAME = PAT_MODNAME,
    PAT_METAMETHOD = PAT_METAMETHOD,
    moduleName = isModuleName,
    metamethodName = isMetamethodName,
}

--- seal the table to prevent changes
---@param tbl table
local function make_readonly(tbl)
    assert(type(tbl) == 'table', 'tbl must be table')

    local function __newindex()
        error('Attempt to assign to a readonly table', 2)
    end

    forcesetmetatable(tbl, {
        __newindex = __newindex,
    })
end

--- constants
local function prepare_pkg_path()
    local list = split_string(package.path, ';')
    local res = {}

    sort(list)
    for _, path in ipairs(list) do
        path = trim_space(path)
        if #path > 0 then
            path = normalize(path)
            path = gsub(path, '[%.%-?]', {
                ['.'] = '%%.',
                ['-'] = '%%-',
                ['?'] = '(.+)'
            })
            res[#res + 1] = '^' .. path
        end
    end
    res[#res + 1] = '(.+)%.lua'

    return res
end

local PKG_PATH = prepare_pkg_path()

local REGISTRY = {
    -- data structure
    -- [<regname>] = {
    --     embeds = {
    --         [<list-of-embedded-module-names>, ...]
    --         [<embedded-module-name>] = <index-number-in-list>, ...]
    --     },
    --     metamethods = {
    --         __tostring = <function>,
    --         [<name> = <function>, ...]
    --     },
    --     methods = {
    --         init = <function>,
    --         instanceof = <function>,
    --         [<name> = <function>, ...]
    --     },
    --     vars = {
    --         _NAME = <string>,
    --         [_PACKAGE = <string>],
    --         [<name> = <non-function-value>, ...]
    --     }
    -- },
    -- [<instanceof-function>] = <regname>
}

local function DEFAULT_INITIALIZER(self)
    return self
end

local function DEFAULT_TOSTRING(self)
    return self._STRING
end

--- register new metamodule
--- @param s string
--- @vararg any
local function errorf(s, ...)
    local msg = format(s, ...)
    local calllv = 2
    local lv = 2
    local info = getinfo(lv, 'nS')

    while info do
        if info.what ~= 'C' and not find(info.source, 'metamodule') then
            calllv = lv
            break
        end
        -- prev = info
        lv = lv + 1
        info = getinfo(lv, 'nS')
    end

    return error(msg, calllv)
end

--- new_instance create new instance
--- @param constructor function
--- @param metatable table
--- @param index table<string, function>?
--- @return table _M
local function new_instance(constructor, metatable, index)
    local instance = constructor()
    instance._STRING = gsub(tostring(instance), 'table', instance._NAME)
    if index then
        local __index = metatable.__index
        metatable.__index = setmetatable(index, {
            __index = function(_, key)
                return __index(instance, key)
            end
        })
    end

    return setmetatable(instance, metatable)
end

--- register new metamodule
--- @param regname string
--- @param decl table
--- @return function constructor
--- @return string? error
local function register(regname, decl)
    -- already registered
    if REGISTRY[regname] then
        return nil, format('%q is already registered', regname)
    end

    -- set <instanceof> method
    decl.methods['instanceof'] = function()
        return regname
    end

    -- set default <init> method
    if not decl.methods['init'] then
        decl.methods['init'] = DEFAULT_INITIALIZER
    end
    -- set default <__tostring> metamethod
    if not decl.metamethods['__tostring'] then
        decl.metamethods['__tostring'] = DEFAULT_TOSTRING
    end

    REGISTRY[regname] = decl
    REGISTRY[instanceof] = regname

    -- create metatable
    local metatable = {}
    for k, v in pairs(decl.metamethods) do
        metatable[k] = v
    end

    -- create method table
    local index = {}
    -- append all embedded module methods to the __index field
    local embeds = {}
    for _, name in ipairs(decl.embeds) do
        embeds[#embeds + 1] = name
    end
    while #embeds > 0 do
        local tbl = {}

        for i = 1, #embeds do
            local name = embeds[i]
            local m = REGISTRY[name]
            local methods = {}
            for k, v in pairs(m.methods) do
                methods[k] = v
            end
            index[name] = methods
            -- keeps the embedded module names
            for _, v in ipairs(m.embeds) do
                tbl[#tbl + 1] = v
            end
        end
        embeds = tbl
    end
    -- append methods
    for k, v in pairs(decl.methods) do
        index[k] = v
    end

    -- set methods to __index field if __index is defined
    if type(metatable.__index) ~= 'function' then
        if metatable.__index ~= nil then
            errorf('__index must be function or nil')
        end
        metatable.__index = index
        index = nil
    end

    -- create new vars table generation function
    local constructor = function()
        local vars_copy = {}
        for k, v in pairs(decl.vars) do
            vars_copy[k] = v
        end
        return vars_copy
    end

    -- create constructor
    return function(...)
        local _M = new_instance(constructor, metatable, index)
        return _M:init(...)
    end
end

--- load registered module
--- @param regname string
--- @return table module
--- @return string? error
local function loadModule(regname)
    local m = REGISTRY[regname]

    -- if it is not registered yet, try to load a module
    if not m then
        local segs = split_string(regname, '.')
        local nseg = #segs
        local pkg = regname

        -- remove module-name
        if nseg > 1 and is.moduleName(segs[nseg]) then
            pkg = concat(segs, '.', 1, nseg - 1)
        end

        if is.packageName(pkg) then
            -- load package in protected mode
            local ok, err = pcall(function()
                require(pkg)
            end)

            if not ok then
                return nil, err
            end

            -- get loaded module
            m = REGISTRY[regname]
        end
    end

    if not m then
        return nil, 'not found'
    end

    return m
end

local IDENT_FIELDS = {
    ['_PACKAGE'] = true,
    ['_NAME'] = true,
    ['_STRING'] = true
}

--- embed methods and metamethods of modules to module declaration table and
--- returns the list of module names and the methods of all modules
--- @param decl table
--- @param ... string base module names
--- @return table moduleNames
local function embedModules(decl, ...)
    local moduleNames = {}
    local chkdup = {}
    local vars = {}
    local methods = {}
    local metamethods = {}

    for _, regname in ipairs({...}) do
        -- check for duplication
        if chkdup[regname] then
            errorf('cannot embed module %q twice', regname)
        end
        chkdup[regname] = true
        moduleNames[#moduleNames + 1] = regname
        moduleNames[regname] = #moduleNames

        local m, err = loadModule(regname)

        -- unable to load the specified module
        if err then
            errorf('cannot embed module %q: %s', regname, err)
        end

        -- embed m.vars
        local circular = {
            [tostring(m.vars)] = regname
        }
        for k, v in pairs(m.vars) do
            -- if no key other than the identity key is defined in the VAR,
            -- copy the key-value pairs.
            if not IDENT_FIELDS[k] and not decl.vars[k] then
                v, err = deepCopy(v, regname .. '.' .. k, circular)
                if err then
                    errorf('field %q cannot be used: %s', k, err)
                end
                -- overwrite the field of previous embedded module
                vars[k] = v
            end
        end

        -- embed m.metamethods
        for k, v in pairs(m.metamethods) do
            if not decl.metamethods[k] then
                -- overwrite the field of previous embedded module
                metamethods[k] = v
            end
        end

        -- add embedded module methods into methods.<regname> field
        for k, v in pairs(m.methods) do
            if not decl.methods[k] then
                -- overwrite the field of previous embedded module
                methods[k] = v
            end
        end
    end

    -- add vars, methods and metamethods field of embedded modules
    for src, dst in pairs({
        [vars] = decl.vars,
        [methods] = decl.methods,
        [metamethods] = decl.metamethods
    }) do
        for k, v in pairs(src) do
            if not dst[k] then
                dst[k] = v
            end
        end
    end

    return moduleNames
end

local RESERVED_FIELDS = {
    ['constructor'] = true,
    ['instanceof'] = true
}

local METAFIELD_TYPES = {
    __add = 'function',
    __sub = 'function',
    __mul = 'function',
    __div = 'function',
    __mod = 'function',
    __pow = 'function',
    __unm = 'function',
    __idiv = 'function',
    __band = 'function',
    __bor = 'function',
    __bxor = 'function',
    __bnot = 'function',
    __shl = 'function',
    __shr = 'function',
    __concat = 'function',
    __len = 'function',
    __eq = 'function',
    __lt = 'function',
    __le = 'function',
    __index = 'function',
    __newindex = 'function',
    __call = 'function',
    __tostring = 'function',
    __gc = 'function',
    __mode = 'string',
    __name = 'string',
    __close = 'function'
}

--- inspect module declaration table
--- @param regname string
--- @param moddecl table
--- @return table delc
local function inspect(regname, moddecl)
    local circular = {
        [tostring(moddecl)] = regname
    }
    local vars = {}
    local methods = {}
    local metamethods = {}

    for k, v in pairs(moddecl) do
        local vt = type(v)

        if type(k) ~= 'string' then
            errorf('field name must be string: %q', tostring(k))
        elseif IDENT_FIELDS[k] or RESERVED_FIELDS[k] then
            errorf('reserved field %q cannot be used', k)
        end

        if is.metamethodName(k) then
            if vt ~= 'function' then
                if METAFIELD_TYPES[k] == 'function' then
                    errorf('the type of metatable field %q must be %s', k, METAFIELD_TYPES[k])
                end

                -- use as variable
                local cpval, err = deepCopy(v, regname .. '.' .. k, circular)
                if err then
                    errorf('field %q cannot be used: %s', k, err)
                end
                v = cpval
            end
            metamethods[k] = v
        elseif vt == 'function' then
            -- use as method
            methods[k] = v
        elseif k == 'init' then
            errorf('field "init" must be function')
        else
            -- use as variable
            local cpval, err = deepCopy(v, regname .. '.' .. k, circular)
            if err then
                errorf('field %q cannot be used: %s', k, err)
            end
            -- use as variable
            vars[k] = cpval
        end
    end

    return {
        vars = vars,
        methods = methods,
        metamethods = metamethods
    }
end

--- create constructor of new metamodule
--- @param pkgname string
--- @param modname string
--- @param moddecl table
--- @param ... string base module names
--- @return function constructor
local function new(pkgname, modname, moddecl, ...)
    -- verify modname
    if modname ~= nil and not is.moduleName(modname) then
        errorf('module name must be the following pattern string: %q', is.PAT_MODNAME)
    end
    -- prepend package-name
    local regname = modname

    if not pkgname then
        if not modname then
            errorf('module name must not be nil')
        end
    elseif modname then
        regname = pkgname .. '.' .. modname
    else
        regname = pkgname
    end

    -- verify moddecl
    if type(moddecl) ~= 'table' then
        errorf('module declaration must be table')
    end

    -- prevent duplication
    if REGISTRY[regname] then
        if pkgname then
            errorf('module name %q already defined in package %q', modname or pkgname, pkgname)
        end
        errorf('module name %q already defined', modname)
    end

    -- inspect module declaration table
    local decl = inspect(regname, moddecl)

    -- embed another modules
    decl.embeds = embedModules(decl, ...)
    -- register to registry
    decl.vars._PACKAGE = pkgname
    decl.vars._NAME = regname
    local newfn, err = register(regname, decl)
    if err then
        errorf('failed to register %q: %s', regname, err)
    end

    -- Make read-only the declaration table to prevent misuse
    make_readonly(moddecl)

    return newfn
end

--- converts pathname in package.path to module names
--- @param s string
--- @return string|nil
local function pathname2modname(s)
    for _, pattern in ipairs(PKG_PATH) do
        local cap = match(s, pattern)
        if cap then
            -- remove '/init' suffix
            cap = gsub(cap, '/init$', '')
            return gsub(cap, '/', '.')
        end
    end
end

--- get the package name from the filepath of the 'new' function caller.
--- the package name is the same as the modname argument of the require function.
--- returns nil if called by a function other than the require function.
--- @return string|nil
local function get_pkgname()
    -- get a pathname of 'new' function caller
    local pathname = normalize(sub(getinfo(3, 'nS').source, 2))
    local lv = 4

    -- traverse call stack to search 'require' function
    repeat
        local info = getinfo(lv, 'nS')

        if info then
            if info.what == 'C' and info.name == 'require' then
                -- found source of 'require' function
                return pathname2modname(pathname)
            end
            -- check next level
            lv = lv + 1
        end
    until info == nil
end

--- instanceof
--- @param obj any
--- @param name? string
--- @return boolean
local function instanceof(obj, name)
    if type(name) ~= 'string' then
        error('name must be string', 2)
    elseif type(obj) ~= 'table' or type(obj.instanceof) ~= 'function' then
        return false
    end

    local regname = REGISTRY[obj.instanceof]
    if not regname then
        -- obj is not metamodule
        return false
    elseif regname == name then
        return true
    end

    -- search in embeds field
    return REGISTRY[regname].embeds[name] ~= nil
end

return {
    instanceof = instanceof,
    new = setmetatable({}, {
        __metatable = 1,
        __newindex = function(_, k)
            errorf('attempt to assign to a readonly property: %q', k)
        end,
        --- wrapper function to create a new metamodule
        -- usage: metamodule.<modname>([moddecl, [embed_module, ...]])
        __index = function(_, modname)
            local pkgname = get_pkgname()
            return function(...)
                return new(pkgname, modname, ...)
            end
        end,
        __call = function(_, ...)
            local pkgname = get_pkgname()
            return new(pkgname, nil, ...)
        end
    })
}