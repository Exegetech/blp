local lu    = require("luaunit")
local lpeg  = require("lpeg")
local pt    = require("pt")

---------------- FRONTEND -----------------
local function numNode(num)
  return {
    tag = "number",
    val = tonumber(num),
  }
end

local function hexNode(num)
  return {
    tag = "hex",
    val = tonumber(num),
  }
end

local P = lpeg.P
local S = lpeg.S
local R = lpeg.R
local C = lpeg.C

local space  = S("\r\n\t ")^0
local number = (R("09")^1 / numNode) * space
local hex    = (P("0") * S("xX") * R("09", "AF", "af")^1 / hexNode) * space
local exp    = space * (hex + number)

local function parse(input)
  return exp:match(input)
end
---------------- FRONTEND -----------------

----------------- BACKEND -----------------
local function compile(ast)
  if ast.tag == "number" or ast.tag == "hex" then
    return {
      "push",
      ast.val
    }
  end
end

local function run(code, stack)
  local pc = 1
  local top = 0

  while pc <= #code do
    if code[pc] == "push" then
      pc = pc + 1
      top = top + 1
      stack[top] = code[pc]
    else
      error("unknown instructions")
    end
    pc = pc + 1
  end
end
----------------- BACKEND -----------------

------------------ TEST -------------------
Test = {}
function Test:testEvaluating()
  local cases = {
    { input = "1", output = 1 },
    { input = " 1", output = 1 },
    { input = " 1 ", output = 1 },
    { input = "01 ", output = 1 },
    { input = " 010", output = 10 },
    { input = "0xF", output = 15 },
    { input = "0xFF", output = 255 },
    { input = "0xff", output = 255 },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)
    local code = compile(parsed)

    local stack = {}
    run(code, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end

lu.run()
------------------ TEST -------------------
