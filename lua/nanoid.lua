local urlAlphabet = 'useandom-26T198340PX75pxJACKVERYMINDBUSHWOLF_GQZbfghjklqvwyzrict'

local function customAlphabet(alphabet, defaultSize)
  defaultSize = defaultSize or 21
  return function(size)
    size = size or defaultSize
    local id = ''
    local i = size
    while i > 0 do
      id = id .. alphabet:sub(math.random(1, #alphabet), math.random(1, #alphabet))
      i = i - 1
    end
    return id
  end
end

local function nanoid(size)
  size = size or 21
  local id = ''
  local i = size
  while i > 0 do
    id = id .. urlAlphabet:sub(math.random(1, #urlAlphabet), math.random(1, #urlAlphabet))
    i = i - 1
  end
  return id
end


