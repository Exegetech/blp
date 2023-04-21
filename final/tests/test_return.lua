local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testReturn()
  local cases = {
    { input = "return 3", output = 3 },
    { input = "x = 3; return x", output = 3 },
    { input = "a = 2; return a + 3", output = 5 },
    { input = "returned = 4; return returned", output = 4 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {
      k0 = 0,
      k1 = 1,
      _k2 = -2,
      k10 = 10,
    }

    vm.run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end
