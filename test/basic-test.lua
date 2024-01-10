-- Lua Comprehensive Test Script

local function log(message)
    print(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message)
end

log("Starting Lua Comprehensive Test Script")

-- 1. String Manipulation
log("Testing String Manipulation")
local testString = "Hello, Lua!"
log("Original String: " .. testString)
testString = string.gsub(testString, "Lua", "World")
log("Replaced String: " .. testString)
log("String Length: " .. #testString)

-- 2. Table Operations
log("Testing Table Operations")
local testTable = { "Lua", "is", "great!" }
table.insert(testTable, 2, "really")
log("Modified Table: " .. table.concat(testTable, " "))

-- 3. Mathematical Functions
log("Testing Mathematical Functions")
local x, y = 10, 3
log("x = " .. x .. ", y = " .. y)
log("x^y = " .. math.pow(x, y))
log("sqrt(x) = " .. math.sqrt(x))

-- 4. File I/O
log("Testing File I/O")
local fileName = "test.txt"
local file = io.open(fileName, "w")
file:write("LuaJIT Test File\n")
file:close()
log("File written: " .. fileName)

-- 5. Coroutines
log("Testing Coroutines")
local co = coroutine.create(function()
    for i = 1, 5 do
        log("Coroutine step: " .. i)
        coroutine.yield()
    end
end)
while coroutine.status(co) ~= "dead" do
    coroutine.resume(co)
end

-- 6. Error Handling
log("Testing Error Handling")
local status, err = pcall(function()
    error("Test Error")
end)
if not status then
    log("Caught Error: " .. err)
end

-- 7. Garbage Collection
log("Testing Garbage Collection")
collectgarbage("collect")
log("Garbage collection performed")

-- 8. Custom Functionality Test (if applicable)
-- Add any specific tests for your new features here

log("Lua Comprehensive Test Script Completed")