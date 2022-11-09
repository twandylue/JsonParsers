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

function json.encode(val)
  return encode(val)
end

local test = { 1, 2, 3, { key = 456, key2 = true, key3 = 789 } }
-- local test = { 1, 2, 3 }
-- local test = { 0, 0, 0 }
-- local test = {}
-- local test = { "test1", "test2" }
-- local test = { key = "test", "test2" }
local result = json.encode(test)
print(result)
