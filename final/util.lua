local function pt(x, id, visited)
  visited = visited or {}
  id = id or ""
  if type(x) == "string" then return "'" .. tostring(x) .. "'"
  elseif type(x) ~= "table" then return tostring(x)
  elseif visited[x] then return "..."    -- cycle
  else
    visited[x] = true
    local s = id .. "{\n"
    for k,v in pairs(x) do
      s = s .. id .. tostring(k) .. " = " .. pt(v, id .. "  ", visited) .. ";\n"
    end
    s = s .. id .. "}"
    return s
  end
end

local function I(msg)
  return lpeg.P(function ()
    print(msg)
    return true
  end)
end

-- Using metaprogramming
-- local function createNode(tag, ...)
--   local labels = table.pack(...)
--   local params = table.concat(labels, ", ")
--   local fields = string.gsub(params, "(%w+)", "%1 = %1")
--   local code = string.format(
--     "return function (%s) return { tag = '%s', %s } end",
--     params, tag, fields
--   )

--   return assert(load(code)())
-- end

-- Without using meta programming
local function createNode(tag, ...)
	local labels = table.pack(...)

	return function(...)
		local params = table.pack(...)
		local result = { tag = tag }

		for i = 1, #labels do
			result[labels[i]] = params[i]
		end

		return result
  end
end

local function countNewLine(str)
  local count = 0

  for i = 1, #str do
    if string.sub(str, i, i) == "\n" then
      count = count + 1
    end
  end

  if string.sub(str, -1) == "\n" then
    count = count + 1
  end

  return count
end

local function negate(val)
  if val == 0 then
    return 1
  else
    return 0
  end
end

return {
  pt = pt,
  I = I,
  createNode = createNode,
  negate = negate,
  countNewLine = countNewLine,
}
