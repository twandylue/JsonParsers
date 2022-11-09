function JsonParser(content)
  local function skipWhitespace()
    while content[CONTEXT.ptr] == " "
        or content[CONTEXT.ptr] == "\n"
        or content[CONTEXT.ptr] == "\t"
        or content[CONTEXT.ptr] == "\r" do
      CONTEXT.ptr = CONTEXT.ptr + 1
    end
  end

  local function isHexadecimal(char)
    local n = tonumber(char)
    local b = string.byte(string.lower(char))
    return ((n >= 0 and n <= 9) and (b >= string.byte("a") and b <= string.byte("f")))
  end

  local function parseString()
    if content[CONTEXT.ptr] == '"' then
      CONTEXT.ptr = CONTEXT.ptr + 1
      local result = ""
      while CONTEXT.ptr < CONTEXT.length and content[CONTEXT.ptr] ~= '"' do
        if content[CONTEXT.ptr] == "\\" then
          local char = content[CONTEXT.ptr + 1]
          if char == '"'
              or char == "\\"
              or char == "/"
              or char == "b"
              or char == "f"
              or char == "n"
              or char == "r"
              or char == "t"
          then
            result = result .. char
            CONTEXT.ptr = CONTEXT.ptr + 1
          elseif char == "u" then
            if isHexadecimal(content[CONTEXT.ptr + 2])
                and isHexadecimal(content[CONTEXT.ptr + 3])
                and isHexadecimal(content[CONTEXT.ptr + 4])
                and isHexadecimal(content[CONTEXT.ptr + 5])
            then
              result = result .. utf8.char(tonumber(string.sub(content, CONTEXT.ptr + 2, CONTEXT.ptr + 5), 16))
              CONTEXT.ptr = CONTEXT.ptr + 5
            else
              CONTEXT.ptr = CONTEXT.ptr + 2
              expectEscapeUnicode()
            end
          else
            expectEscapeCharacter(result)
          end
        else
          result = result .. content[CONTEXT.ptr]
        end
        CONTEXT.ptr = CONTEXT.ptr + 1
      end
      expectNotEndOfInput('"')
      CONTEXT.ptr = CONTEXT.ptr + 1
      return result
    end

    local function parseValue(context)
      skipWhitespace()
      local value = parseString()
      skipWhitespace()
    end

    CONTEXT = { ptr = 0, length = string.len(content) }
    parseValue(CONTEXT)
  end
end

-- JsonParser("test")

-- print(string.byte("a"))
-- print(string.format("%#x", 0xaf))
local result = tonumber(string.sub("u0061", 2, 6), 16)
local ans = "answer:"
ans = result .. ":test:" .. utf8.char(result)

local t1 = { key = "test1", value = 123 }
local t2 = { key = "test1", value = 123 }

local function equals(o1, o2, ignore_mt)
  if o1 == o2 then
    return true
  end
  local o1Type = type(o1)
  local o2Type = type(o2)
  if o1Type ~= o2Type then
    return false
  end
  if o1Type ~= "table" then
    return false
  end

  if not ignore_mt then
    local mt1 = getmetatable(o1)
    if mt1 and mt1.__eq then
      --compare using built in method
      return o1 == o2
    end
  end

  local keySet = {}

  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    if value2 == nil or equals(value1, value2, ignore_mt) == false then
      return false
    end
    keySet[key1] = true
  end

  for key2, _ in pairs(o2) do
    if not keySet[key2] then
      return false
    end
  end
  return true
end

print(equals(t1, t2, true))
