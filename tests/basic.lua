-- Basic LuaJIT Test Suite

-- Arithmetic and Logic Tests
local function testArithmeticAndLogic()
    print("Testing Arithmetic and Logic...")
    assert(1 + 1 == 2)
    assert(5 - 3 == 2)
    assert(3 * 3 == 9)
    assert(10 / 2 == 5)
    assert(10 % 3 == 1)
    print("Arithmetic and Logic Tests Passed.")
end

-- String Manipulation Tests
local function testStringManipulation()
    print("Testing String Manipulation...")
    assert("Hello " .. "World" == "Hello World")
    assert(string.sub("Hello", 1, 4) == "Hell")
    assert(string.find("Hello", "ell") == 2)
    print("String Manipulation Tests Passed.")
end

-- Table Operations Tests
local function testTableOperations()
    print("Testing Table Operations...")
    local t = {1, 2, 3}
    table.insert(t, 4)
    assert(#t == 4)
    table.remove(t, 1)
    assert(t[1] == 2)
    local nestedTable = {t, {5, 6}}
    assert(nestedTable[2][1] == 5)
    print("Table Operations Tests Passed.")
end

-- Function Execution Tests
local function testFunctionExecution()
    print("Testing Function Execution...")
    local function square(x) return x * x end
    assert(square(3) == 9)
    local cube = function(x) return x * x * x end
    assert(cube(2) == 8)
    print("Function Execution Tests Passed.")
end

-- Control Structures Tests
local function testControlStructures()
    print("Testing Control Structures...")
    local x = 5
    if x > 3 then
        x = x + 1
    end
    assert(x == 6)

    local sum = 0
    for i = 1, 5 do sum = sum + i end
    assert(sum == 15)

    local j = 0
    while j < 3 do j = j + 1 end
    assert(j == 3)

    local k = 3
    repeat k = k - 1 until k == 0
    assert(k == 0)
    print("Control Structures Tests Passed.")
end

-- Basic Garbage Collection Test
local function testGarbageCollection()
    print("Testing Garbage Collection...")
    local function createObjects()
        for i = 1, 10000 do
            local t = {i, tostring(i)}
        end
    end
    createObjects()
    collectgarbage("collect")
    print("Garbage Collection Test Passed (observational).")
end

-- Running Tests
testArithmeticAndLogic()
testStringManipulation()
testTableOperations()
testFunctionExecution()
testControlStructures()
testGarbageCollection()

print("All Tests Passed.")