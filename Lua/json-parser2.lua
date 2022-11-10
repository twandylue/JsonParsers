local json = {}

local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  if stack[val] then
    error("circle reference")
  end

  stack[val] = true
  -- if rawget(val, 1) ~= nil or next(val) == nil then
  if #val ~= 0 or next(val) == nil then
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    for _, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"
  else
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key type")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end

local function encode_string(val)
  return tostring(val)
  -- TODO:
  -- return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end

local function encode_nil(val)
  return "null"
end

local type_func_map = {
  ["nil"] = encode_nil,
  ["table"] = encode_table,
  ["string"] = encode_string,
  ["number"] = encode_number,
  ["boolean"] = tostring,
}

encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end

local parse

local literal_map = {
  ["true"] = true,
  ["false"] = false,
  ["null"] = nil,
}

local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[string.sub(str, i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end

local function decode_error(str, idx, message)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if string.sub(str, i, i) == "\n" then
      line_count = line_count + 1
      col_count = col_count + 1
    end
  end
  error(string.format("%s at line %d col %d", message, line_count, col_count))
end

local function create_set(list)
  local res = {}
  for i = 1, #list do
    res[list[i]] = true
  end

  return res
end

local space_chars = create_set({ " ", "\t", "\r", "\n" })
local escape_chars = create_set({ "\\", "/", '"', "b", "f", "n", "r", "t", "u" })
local literals = create_set({ "null", "true", "false" })
local delim_chars = create_set({ " ", "\t", "\r", "\n", "]", "}", "," })

local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = string.sub(str, i, x - 1)
  local num = tonumber(s)
  if not num then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end

  return num, x
end

local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = string.sub(str, i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end

  return literal_map[word], x
end

local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while true do
    local x
    i = next_char(str, i, space_chars, true)
    if string.sub(str, i, i) == "]" then
      i = i + 1
      break
    end

    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    i = next_char(str, i, space_chars, true)

    local char = string.sub(str, i, i)
    if char == "]" then
      i = i + 1
      break
    end
    if char ~= "," then
      decode_error(str, i, "expected ']' or ','")
    end
    i = i + 1
  end

  return res, i
end

-- TODO: parse_object
local function parse_object(str, i)
  local res = {}
  i = i + 1
  while true do
    local key
    local value
    i = next_char(str, i, space_chars, true)
    -- empty object
    if string.sub(str, i, i) == "}" then
      i = i + 1
      break
    end
    if string.sub(str, i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    i = next_char(str, i, space_chars, true)
    if string.sub(str, i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = i + 1
    i = next_char(str, i, space_chars, true)
    value, i = parse(str, i)
    res[key] = value
    if string.sub(str, i, i) == "}" then
      i = i + 1
      break
    end
    if string.sub(str, i, i) ~= "," then
      decode_error(str, i, "expected '}' or ','")
    end
    i = i + 1
  end

  return res, i
end

local char_func_map = {
  ["["] = parse_array,
  ["{"] = parse_object,
  ['"'] = parse_string,
  ["0"] = parse_number,
  ["1"] = parse_number,
  ["2"] = parse_number,
  ["3"] = parse_number,
  ["4"] = parse_number,
  ["5"] = parse_number,
  ["6"] = parse_number,
  ["7"] = parse_number,
  ["8"] = parse_number,
  ["9"] = parse_number,
  ["-"] = parse_number,
  ["t"] = parse_literal,
  ["f"] = parse_literal,
  ["n"] = parse_literal,
}

parse = function(str, idx)
  local char = string.sub(str, idx, idx)
  local f = char_func_map[char]
  if not f then
    decode_error(str, idx, "unexpected character '" .. char .. "'")
  end
  return f(str, idx)
end

function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end

  return res
end

function json.encode(val)
  return encode(val)
end

--- test cases ---
--
-- local test = { 1, 2, 3, { key = 456, key2 = true, key3 = 789 } }
-- local test = { 1, 2, 3 }
-- local test = { 0, 0, 0 }
-- local test = {}
-- local test = { nil, true, false } -- sparse array
-- local test = { true, false }
-- local test = { "test1", "test2" }
-- local test = { key = "test", "test2" }
-- print(json.encode(test))

-- print(json.decode("[true,false]"))
print(json.decode("[1,false,2]"))
for key, value in pairs(json.decode("[1,false,2]")) do
  print("key: " .. tostring(key) .. ", value: " .. tostring(value))
end
