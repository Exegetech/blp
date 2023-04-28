local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testArithmetic()
  local cases = {
    { input = "11+ +22", output = 33 },
    { input = "11+ -22", output = -11 },
    { input = "+13 +-25 +    +36", output = 24 },
    { input = "1 - 2", output = -1 },
    { input = "1 - -2", output = 3 },
    { input = "1 - -2 + 3 - 4", output = 2 },
    { input = "3 * 5", output = 15 },
    { input = "0xF / 3", output = 5.0 },
    { input = "0xA / 2", output = 5.0 },
    { input = "0xF + 0xA", output = 25 },
    { input = "0xF - 0xA", output = 5 },
    { input = "2 + 14 * 2 / 2", output = 16 },
    { input = "10 % 8", output = 2 },
    { input = "4 + 10 % 8", output = 6 },
    { input = "4 + 5 * 2 ^ 3 / 10", output = 8 },
    { input = "4 + 5 * 2 ^ 3 / 10 % 2", output = 4.0 },
    { input = "2 * (2 + 4) * 10", output = 120 },
  }

  for _, case in ipairs(cases) do
    local input = "function main() {" .. case.input .. "}"

    if case.output == nil then
      local parsed = parser.parse(input)
      lu.assertEquals(parsed, nil)
    else
      local parsed = parser.parse(input)
      local code = ast.compile(parsed)

      local stack = {}
      local memory = {}
      vm.run(code, memory, stack)

      local result = stack[1]
      lu.assertEquals(result, case.output)
    end
  end
end
