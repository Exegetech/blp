local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testAssignment()
  local cases = {
    { input = "k1 = 1; k1 + k1", output = 2 },
    { input = "k0 = 0; k1 = 1; k1 + k0", output = 1 },
    { input = "k1 = 1; k10 = 10; (k1 + k1) * k10", output = 20 },
    { input = "_k2 = -2; _k2", output = -2 },
  }

  for _, case in ipairs(cases) do
    local input = "function main() {" .. case.input .. "}"
    local parsed = parser.parse(input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end
