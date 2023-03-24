local lpeg  = require("lpeg")
local pt    = require("pt")

local P  = lpeg.P
local S  = lpeg.S
local R  = lpeg.R
local C  = lpeg.C
local Ct = lpeg.Ct
local V  = lpeg.V

local str1 = "AAABAAAB"
local str2 = "AAAB"

local p1 = (S("AZ")^0 * P("B")

-- local pattern = (lpeg.alpha-"B")^1 * "B"

print(pattern:match(str1))
print(pattern:match(str2))
