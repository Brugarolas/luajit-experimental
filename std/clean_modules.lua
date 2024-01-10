-- advanced_clean_modules.lua
--
-- By: Andrés Brugarolas Martínez
-- Copyright (c) (2023) under PROSL license
-- https://www.andres-brugarolas.com/
-- https://www.github.com/brugarolas/
--
-- Proof of concept of a module system that allows you to
-- declare "clean" modules: those whose non-local variables
-- does not pollude global environment.
--
-- This code has not been tested deeply, so use it at your own
-- risk. It might not be production ready. It is here for educational
-- purposes.
--
-- Also, it is under a 'source available' but not a strictly 'open source'
-- license, named PROSL (Progressive Restrictive Open Source License), so if you
-- intend to use it in any other way that a non-comercial personal project
-- (which is allowed, I consider the development of the economy a good thing),
-- you should definitively read the license first, as it is a value-driven
-- license which imposes some restrictions on its use like prohibiting all
-- kind of use in activities related to police agencies, military companies,
-- armed forces, intelligence agencies, paramilitary groups, etc. and it also
-- states that you require explicit consent for any commercial activity.
--
-- But really, ask me, I'm a nice guy and I will probably say yes. I just
-- want to have control over what my software is used for. But I'm happy
-- if my code helps any individual, freelancer, small company or medium
-- company in any way. And even larger corporations, but then I may ask
-- something in return (like unlimited free access to your SaaS).

-- Store original environment for possible future uses
_G.main_env = getfenv(1)

-- Yes, I know I can call require without the parenthesis, but I don't like it
-- (Lua, you are so weird, part #0)
local logger = require("lua_logging.simple_logger")
local utils = require("lua_serialize.utils")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Part I: Compatibility functions for Lua 5.2+                               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Check Lua version
-- LuaJIT is actually Lua 5.1 (with some additions), but would not be accurate
-- to define just as 'Lua 5.1' so it returns 'LuaJIT' instead.
-- (I barely understand anything of this, just copied from some place in the 
-- internet I can't find anymore, but that guy deserves all the credit)
local getLuaVersion = function()
    if ({false, [1] = true})[1] then   -- luacheck: ignore 314
        return 'LuaJIT'
    elseif 1 / 0 == 1 / '-0' then
        return 0 + '0' .. '' == '0' and 'Lua 5.4' or 'Lua 5.3'
    end
    -- This is me trying to understand this particular code snippet
    -- So let's summarize it: Ok, each time f() is called it returns a
    -- new annonymous function... I get it
    -- So calling it twice will return two different functions, right?
    -- Therefore, in Lua 5.1, f() == f() will return false, because
    -- what is compared is identity, the reference, and in fact they
    -- are not the same function, they are different instances. Ok...
    -- But in Lua 5.2+ it will return true, because the function is
    -- somehow compared... lexically? Is that? Lua 5.2 is able to
    -- compare if two functions are equal lexically? Is it? IS IT?
    local f = function() return function() end end
    return f() == f() and 'Lua 5.2' or 'Lua 5.1'
end

-- Check if the module is available based on the Lua version
-- Because in Lua 5.2 they introduced a BREAKING CHANGE like removing the
-- module function and adding _ENV, in a MINOR VERSION, good one PUC-Rio
-- You don't code in Lua, it's Lua who codes in you
-- (Probably should have been checked just if module is nil, but anyway,
-- that wouldn't justify using the previous function, which is so cool)
-- (Come on, who breaks the compatibility like this in a minor version?
-- Meanwhile, C++ guys are so scared of deprecating crappy 1985 stuff
-- Lua, you are so weird, part #1)
local hasModule = function()
    local luaVersion = getLuaVersion()

    return luaVersion == "Lua 5.1" or luaVersion == "LuaJIT"
end

-- Mock implementation of setfenv for Lua 5.2+
-- In Lua 5.2+ _ENV is a local variable, so it wasn't that hard to implement
-- (Note: you SHOULD NOT use debug functions in production code, but I haven't found
-- any other way to do this, anyway this is meant for Lua 5.1 because in Lua 5.2+
-- there are no modules, I just included this for completeness, 'cause I'm a nice guy)
local function _setfenv(fn, env)
    if hasModule() then
        return _G.setfenv(fn, env)
    end

    -- Check if debug library is available, it may happen that doesn't exist
    -- But we shouldn't crash the app because of it, should we?
    if (not debug) then
        logger.error("No debug library found, cannot set environment")
        return fn
    end

    local i = 1
    while true do
        local name = debug.getupvalue(fn, i)
        if name == "_ENV" then
            debug.setupvalue(fn, i, env)
            return fn
        elseif not name then
            -- If there is no _ENV upvalue, something EVIL is happening
            -- But we shouldn't crash the app because of it, should we?
            logger.error("No _ENV upvalue found in function %s", fn)
            return fn -- Or break...?
        end
        i = i + 1
    end
end

-- Mock implementation of getfenv for Lua 5.2+
-- In Lua 5.2+ _ENV is a local variable, so it wasn't that hard to implement
-- (Note: you SHOULD NOT use debug functions in production code, but I haven't found
-- any other way to do this)
local function _getfenv(fn)
    if hasModule() then
        return _G.getfenv(fn)
    end

    -- Check if debug library is available, it may happen that doesn't exist
    -- But we shouldn't crash the app because of it, should we?
    if (not debug) then
        logger.error("No debug library found, cannot set environment")
        return fn
    end

    local i = 1
    while true do
        local name, val = debug.getupvalue(fn, i)
        if name == "_ENV" then
            return val
        elseif not name then
            -- If there is no _ENV upvalue, something EVIL is happening
            -- But we shouldn't crash the app because of it, should we?
            logger.error("No _ENV upvalue found in function %s", fn)
            return fn -- Or break...?
        end
        i = i + 1
    end
end

-- Mock implementation of module for Lua 5.2+
-- In this version modname is mandatory as it is not inferred from the source file
-- or the require / loadfile function or however it works in Lua 5.1
-- (Note: you SHOULD NOT use debug functions in production code, but I haven't found
-- any other way to do this)
-- (Note #2: This has not been tested properly, use under your own risk, or don't use
-- it, if you are using Lua 5.2+ instead of LuaJIT you don't deserve this great module)
function __module (modname,...)
    local function findtable(tbl, fname)
        for key in string.gmatch(fname, "([%w_]+)") do
            if key and key ~= "" then
                local val = rawget(tbl, key)
                if not val then
                    local field = {}
                    tbl[key] = field
                    tbl = field
                elseif type(val)~="table" then
                    return nil
                else
                    tbl = val
                end
            end
        end
        return tbl
    end

    assert(type(modname)=="string")

    local value,modul = package.loaded[modname]

    if type(value) ~= "table" then
        modul = findtable(_G,modname)
        assert(modul, "name conflict for module '"..modname.."'" )
        package.loaded[modname] = modul
    else
        modul = value
    end

    local name = modul._NAME
    if not name then
        modul._M = modul
        modul._NAME = modname
        modul._PACKAGE = string.match(modname,"([%w%._]*)%.[%w_]*$")
    end

    local func = debug.getinfo(2,"f").func
    debug.setupvalue(func,1,modul)

    for _,f in ipairs{...} do
        f(modul)
    end
end

-- This is the real module function we are using in Lua 5.2+
-- It is just a wrapper around the previous function that adds the
-- module name using a debug function
-- (Which is WRONG but we are using it anyway in previous function, so whatever)
local function _module(...)
    if (hasModule()) then
        return _G.module(...)
    end

    local modname = debug.getinfo(2, "S").source:match("@?(.*/)(.*)"):gsub("%.lua$", "")
    return __module(modname)
end

-- Return the compatibility functions
-- return {
local compat = {
    module = _module,
    setfenv = _setfenv,
    getfenv = _getfenv
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Part II: Clean and enhanced module and require utils                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local configuration = {
    -- With strict mode enabled, the app will monkey patch all global
    -- module and require functions, to use our strict implementation.
    -- Be aware that this can have catastrophic consequences if you
    -- are using other libraries that rely on global vars.
    strict_global_mode = false,
    -- If true, it will allow modules to set global variables
    -- when explicitly declared with "_G.name = value".
    allow_global_vars = false,
    -- If true, it will compile and cache modules, so they are
    -- not compiled every time they are required.
    compile_and_cache_modules = true
}

-- Store function references for performance optimization
-- Lua find faster local variables than global ones, due to
-- how it handles the environment/context
-- (Lua, you are so weird, part #2)
-- Also, it's not a bad way to self-document the code a little more,
-- so you can imagine what is file this about
local getfenv = compat.getfenv --getfenv
local setfenv = compat.setfenv --setfenv
local module = compat.module --module
local setmetatable = setmetatable
local g_require = require -- Don't overwrite require, we may need a way to restore the original require
local pcall = pcall
local loadfile = loadfile
local ipairs = ipairs
local rawset = rawset

-- Cache for compiled modules
local __compiled_cache = {}

-- Track globals set by each module
local __module_globals = {}

-- List of the files which won't be unloaded
local __keep_in_memory = {
    -- Lua globals
    ["base"] = true,
    ["string"] = true,
    ["package"] = true,
    ["_G"] = true,
    ["os"] = true,
    ["table"] = true,
    ["math"] = true,
    ["coroutine"] = true,
    ["debug"] = true,
    ["io"] = true,

    -- LuaJIT
    ["bit"] = true,
    ["ffi"] = true,
    ["jit"] = true,

    -- This file
    -- (In Lua, the module file paths are not first-citizens? Lua, you are so weird, part #3)
    ["module.advanced_clean_modules"] = true
}

-- Function to safe require a module
local function __prequire(m)
    local ok, err = pcall(require, m) 
    if not ok then return nil, err end
    return ok, err
end

-- Returns a functions that wraps the function passed as argument and
-- logs if an exception is thrown during execution returning nil and allowing
-- Lua continuing its execution flow, because we don't want a "corrupted" module
-- to affect the rest of the modules and compromise the execution of the whole
-- app/game/framework/server. If the returned nil is not handled in calling module
-- or if the module is a core module and it is needed for other modules to work,
-- app will crash somewhere else and execution will be stopped, but it's important
-- it does NOT happen here
-- Note: in case you are wondering why, this library was initially made as
-- a framework for modding a game
local function __tryCatchHighOrderFunction(func)
    return function (...)
        -- (pcal instead of try-catch... Lua, you are so weird, part #4)
        local ok, err = pcall(func, ...)

        if not ok then
            logger.error("Error calling wrapped function: " .. tostring(func) .. " with params: " .. utils.jsonifyTable(arg) .. ". Error: " .. err)

            return nil, false
        end

        return ok, true
    end
end

-- Function to load a file (with loadfile, not with require,
-- so we should handle package.loaded manually in calling
-- functions), compile it, and save the compiled module
-- in a cache to save time if we are loading it again
local function __loadfile_compiled(name)
    local path = package.searchpath(name, package.path)
    if not path then
        -- (I would prefer a "throw error()", but whatever... Lua, you are so weird, part #5)
        error("Module '" .. name .. "' not found")
    end

    -- Check if already compiled and cached
    if __compiled_cache[path] then
        return __compiled_cache[path]
    end

    -- If not in cache, compile and store
    -- Unlike require, which also executes the file/module,
    -- loadfile just loads a Lua chunk from a file, but it
    -- does not run the chunk. Instead, it only compiles
    -- the chunk and returns the compiled chunk as a function
    local f, err = loadfile(path)
    if not f then
        error("Error loading module '" .. name .. "' from file '" .. path .. "':\n\t" .. err)
    end

    -- Save the compiled module in cache
    __compiled_cache[path] = f
    return f
end

-- Function to load and compile a module and save in a cache a file,
-- or just to load it, depending on `configuration.compile_and_cache_modules`
local function __loadfile_generic(name)
    if (configuration.compile_and_cache_modules) then
        return __loadfile_compiled(name)
    end

    local f = function (name)
        local ok, err = __prequire(name)
        if not ok then
            error("Error loading module '" .. name .. "':\n\t" .. err)
        end
        return ok
    end

    return f
end

-- Merge the properties of the second table into the first (main) table
local function __merge_table(main_table, secondary_table)
    if not secondary_table then return end

    for k, v in pairs(secondary_table) do main_table[k] = v end
end

-- Declare module cleanly:
--  module is registered in package.loaded,
--  but not inserted in the global namespace
--  so it does not pollute global environment
--  it only gets loaded into _G if specifically
--  declared as "_G.name = value"
local function _module(modname, ...)
    -- Convert module name to all lower case to avoid cases like "Main" and "main" potentially leading to separate tables
    local modulename = string.lower(modname)
    local _M = {}  -- namespace for module
    setfenv(2, _M)

    -- Define for partial compatibility with module()
    _M._M = _M
    _M._NAME = modulename

    -- Keeps track of global defined vars with "_G.name = value"
    local global_vars = {}

    -- Apply decorators to the module, like module_compiled.seeall
    if ... then
        for _, func in ipairs({...}) do
            local decorator_defined_global_vars = func(_M)

            __merge_table(global_vars, decorator_defined_global_vars)
        end
    end

    package.loaded[modulename] = _M
    __module_globals[modulename] = global_vars
end

-- Modified _seeall function to allow specific writes to _G
local function _seeall(_M)
    local priv = {}  -- private environment for module
    local global_vars = {} -- keep track of global vars defined with "_G.name = value"
    local privmt

    if configuration.allow_global_vars then
        privmt = {
            __index = function(priv, k)
                return _M[k] or _G[k]
            end,
            __newindex = function(t, k, v)
                if string.sub(k, 1, 3) == "_G." then
                    local propertyName = string.sub(k, 4)
    
                    _G[propertyName] = v
                    global_vars[propertyName] = v
                else
                    _M[k] = v
                end
            end
        }
    else
        privmt = {
            __index = function(privat, k)
                return _M[k] or _G[k]
            end,
            __newindex = function(t, k, v)
                _M[k] = v
            end
        }
    end

    setmetatable(priv, privmt)
    setfenv(3, priv)

    return global_vars -- return global vars so "_module" function can register and keep track of them
end

-- Require module with logging and cache
local function _require(name)
    -- Convert module name to all lower case to avoid cases like "Main" and "main" potentially leading to separate tables
    local modulename = string.lower(name)

    -- Check if the module is already loaded
    if package.loaded[modulename] then
        return package.loaded[modulename]
    end

    -- Use our compile and cache mechanism
    local loader = __loadfile_generic(modulename)
    local result = loader(modulename)

    package.loaded[modulename] = result
    rawset(getfenv(2), modulename, result)

    return result
end

-- Unload a module and clear the global variables it has set
-- (Ok, Lua, this is weird, part #6, but also
-- incredibly cool and I definitively love it)
local function _unrequire(name)
    -- Convert module name to all lower case to avoid cases like "Main" and "main" potentially leading to separate tables
    local modulename = string.lower(name)

    -- Remove global variables set by this module
    local globals = __module_globals[modulename]
    if globals then
        for k, _ in pairs(globals) do
            _G[k] = nil
        end
        __module_globals[modulename] = nil
    end

    -- Remove the module from package.loaded
    package.loaded[modulename] = nil
end

-- Clean all loaded packages except the ones we have
-- defined to keep in memory (mostly lua core stuff and
-- framework core stuff to)
local function _unrequire_all()
    -- Convert module name to all lower case to avoid cases like "Main" and "main" potentially leading to separate tables
    for module_name, _ in pairs(package.loaded) do
        if not __keep_in_memory[module_name] then
            _unrequire(module_name)
        end
    end
end

-- Force require a module without recompiling,
-- it loads and executes again an already loaded module,
-- but it skips the actual "loading" and compilating part
local function _force_require(name)
    -- Convert module name to all lower case to avoid cases like "Main" and "main" potentially leading to separate tables
    local modulename = string.lower(name)
    package.loaded[modulename] = nil
    return _require(modulename)
end

-- It is the same as regular _require but:
-- 1) It allows you to pass as an argument the namespace table where all variables will be saved
-- 2) So multiple modules can share the same namespace
local function _namespace_require(name, namespace_table)
    local modulename = string.lower(name)
    if package.loaded[modulename] then
        error("Module '" .. name .. "' already loaded, you can't load it again with a different namespace (check namespace_load_package instead)")
    end

    local loader = __loadfile_generic(modulename)

    local t = namespace_table or {}
    setmetatable(t, { __index = getfenv(1) })
    setfenv(loader, t)

    package.loaded[modulename] = result
    rawset(getfenv(2), modulename, result)

    return result
end

-- It is the same as previous file but:
-- 1) It does not checks if module is already loaded in package.loaded and does not register module there
local function _namespace_load_package(name, namespace_table)
    local loader = __loadfile_generic(modulename)

    local t = namespace_table or {}
    setmetatable(t, { __index = getfenv(1) })
    setfenv(loader, t)

    return loader(modulename)
end

-- Ironically, this module is not itself clean, so that it can be used with 'require'
-- ('Clean module' is not actually 'clean', and 40% of police officers beat their wives,
-- we live in a society full of contradictions)
-- (Note: I SWEAR that Github Copilot wrote that fact about the police officers, I love it)
-- (Note #2: I discovered where Github Copilot learned that, if you search "brutality" in
-- GitHub, the first result is "Project Brutality", a GREAT mod for classic Doom, and the
-- rest -thousands- of results are entire compilations about proofs of police brutality,
-- sad but true).
module(...)

-- Export functions
package = { seeall = _seeall }
module = __tryCatchHighOrderFunction(_module)
require = __tryCatchHighOrderFunction(_require)
unrequire = __tryCatchHighOrderFunction(_unrequire)
unrequire_all = __tryCatchHighOrderFunction(_unrequire_all)
force_require = __tryCatchHighOrderFunction(_force_require)
namespace_load_package = __tryCatchHighOrderFunction(_namespace_load_package)
namespace_require = __tryCatchHighOrderFunction(_namespace_require)

-- Override global require with a safer one.
-- This is an attempt to make the code more secure
-- So if a file fails, the app won't crash unless it's a
-- core module, so hopefully the app will continue running
-- and other services will continue working while you fix it.
-- This is also a nice way to self-test the file.
if not configuration.strict_global_mode then
    _G.require = require
    _G.module = module
    _G.package.seeall = package.seeall
end

-- Explicit return is not necessary the moment we declare a module,
-- but can and will be kept for clarity
return _M