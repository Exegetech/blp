local lpeg = require"lpeg"

local function I(msg)
  return lpeg.P(function ()
    print(msg)
    return true
  end)
end

local open  = lpeg.P('"')
local close = open
local backslash = lpeg.P("\\")
local escapedClose = backslash * close

--local close = -lpeg.B("\\", 1) * open
local p = I("match open") * open
        * I("match mid")* lpeg.C(
          ((2 - escapedClose)
          + (1 - close))^0
        )
        * I("match close") * close

-- make these assertions to pass
assert([[a\"b]] == p:match([["a\"b"]]))
assert([[a\\]] == p:match([["a\\"]]))
assert([[xyz\\]] == p:match([["xyz\\"]]))
