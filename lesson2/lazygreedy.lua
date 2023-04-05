local lpeg  = require("lpeg")
local pt    = require("pt")

local lazy = lpeg.C(lpeg.P({"P",
  P = lpeg.P("o") + lpeg.P(1) * lpeg.V("P")
}))

local greedy = lpeg.C(lpeg.P({"P",
  P = lpeg.P(1) * lpeg.V("P") + lpeg.P("o")
}))

print(lazy:match("hello world"))
print(greedy:match("hello world"))

