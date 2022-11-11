local function print_string(val, i, stack)
  if stack[i] then
    stack[i] = string.format("%s: %s", stack[i], val)
  else
    stack[i] = tostring(val)
  end

  return i + 1
end

local function print_number(val, i, stack)
  if stack[i] then
    stack[i] = string.format("%s: %s", stack[i], val)
  else
    stack[i] = tostring(val)
  end

  return i + 1
end

local function print_table(val, i, stack)
  local cur
  if not stack[i] then
    cur = "{"
  else
    cur = string.format("%s: {", stack[i])
  end
  stack[i] = cur
  i = i + 1

  -- array
  if #val ~= 0 then
    for _, value in pairs(val) do
      i = beautify(value, i, stack)
    end
  else
    -- table
    for key, value in pairs(val) do
      stack[i] = string.format("%s", key)
      i = beautify(value, i, stack)
    end
  end

  stack[i] = "}"
  return i + 1
end

local action_map = {
  ["table"] = print_table,
  ["string"] = print_string,
  ["number"] = print_number,
  ["nil"] = print_nil,
  ["boolean"] = print_bool,
}

function beautify(val, i, stack)
  if not action_map[type(val)] then
    error("not defined print action")
  end
  local f = action_map[type(val)]
  i = f(val, i, stack)

  return i
end

local stack = {}
-- beautify('{"target", "like", {"test", "test2"}}', 0, stack)
-- beautify({ "target", "like", "test", { "test", "test123", 1, { 23, 4 } }, 56, 233 }, 1, stack)
-- beautify({ "target" }, 1, stack)
-- beautify({ 1, 2 }, 1, stack)
-- beautify({ "target", { "like", "test", { "test1", "test2" }, "test3" } }, 1, stack)
-- beautify({ key = "test1", key2 = "test2", key3 = { "test1", "test2" } }, 1, stack)
-- beautify({ key = "test1", key2 = "test2" }, 1, stack)
-- beautify({ "test1", "test2" }, 1, stack)
beautify({ "test1", key = "test4", { "test1", "test2" } }, 1, stack) -- TODO: failed

-- for key, val in pairs(stack) do
--   print(key, val)
-- end

local function generate_spaces(i)
  local res = ""
  for _ = 1, i do
    res = res .. "  "
  end
  return res
end

local c = 0
for _, val in ipairs(stack) do
  if val == "{" then
    print(generate_spaces(c) .. val)
    c = c + 1
  elseif val == "}" then
    c = c - 1
    print(generate_spaces(c) .. val .. ",")
  else
    print(generate_spaces(c) .. val .. ",")
  end
end

-- -- local index, value = nil, nil
-- -- index, value = next(stack)
-- -- while index ~= nil do
-- --   print(index, value)
-- --   index, value = next(stack, index)
-- -- end
