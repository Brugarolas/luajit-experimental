-- Metaclass for creating new classes
Class = {
    prototype = {},
    mixins = {}
}

-- Setting Class's metatable to itself
setmetatable(Class, Class)

-- Method to create a new class
function Class:extend(extendFunc)
    local newClass = {}
    newClass.super = self
    newClass.mixins = {}
    newClass.prototype = {}
    setmetatable(newClass, newClass)
    
    -- Allows newClass to use methods defined in Class.prototype
    setmetatable(newClass.prototype, { __index = self.prototype })

    if extendFunc then
        extendFunc(newClass)
    end

    return newClass
end

-- Method to instantiate a class
function Class:new(...)
    if self == Class then
        error("You cannot instantiate a metaclass")
    end

    local instance = setmetatable({}, self.prototype)
    instance.class = self
    instance.type = "instance"

    if instance.constructor then
        instance:constructor(...)
    end

    return instance
end

-- Basic methods for all classes
Class.prototype.isSame = function(self, other)
    return self.class == other.class
end

Class.prototype.isEqual = function(self, other)
    -- Implementation of shallow equality check
end

Class.prototype.isDeepEqual = function(self, other)
    -- Implementation of deep equality check
end

Class.prototype.toString = function(self)
    -- Implementation of toString method
end

Class.prototype.isInstanceOf = function(self, aClass)
    local currentClass = self.class
    while currentClass ~= nil do
        if currentClass == aClass then
            return true
        end
        currentClass = currentClass.super
    end
    return false
end

-- TODO: Implement classes String, Number, Thenable, Promise, Future, Deferred, Task, Channel, Event, Worker, Coroutine

-- Object class, more user-friendly and with table methods
Object = Class:extend(function (Object)
    -- Populate Object.prototype with table methods
    for k, v in pairs(table) do
        Object.prototype[k] = function(self, ...)
            return v(self, ...)
        end
    end
end)