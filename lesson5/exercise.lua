local lpeg = require("lpeg")

local posCapture = lpeg.P(function (_, pos)
  return true, pos
end)

local p = lpeg.P("he") * posCapture * lpeg.P("llo")

-- should be 3 because posCapture is located in position 3
print(p:match("hello")) 

local literalCapture = function(str, pos)
  local val = string.sub(str, pos, pos)
  return true, val
end

local p = lpeg.P("he") * literalCapture * lpeg.P("llo")

-- should be 3 because literalCapture is located in position 3, which is character l
print(p:match("hello")) -- should be l
