local lpeg = require"lpeg"
lpeg.locale(lpeg)

local function I(msg)
  return lpeg.P(function ()
    print(msg)
    return true
  end)
end

local keywords = {"if", "elseif", "else", "end"}
local alnum = lpeg.alnum^1
local keyword = lpeg.P(false)
for _, kw in ipairs(keywords) do
  keyword = keyword + (I("match " .. kw) * kw)
end
keyword = keyword * -alnum

-- make these assertions to pass
assert(lpeg.match(keyword, "else") == 5)
assert(lpeg.match(keyword, "elseif") == 7)
assert(lpeg.match(keyword, "else1") == nil)
