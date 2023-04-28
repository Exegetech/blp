local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testComparison()
  local cases = {
    { input = "1 < 2", output = 1 },
    { input = "1 > 2", output = 0 },
    { input = "1 <= 2", output = 1 },
    { input = "2 <= 2", output = 1 },
    { input = "1 >= 2", output = 0 },
    { input = "1 == 2", output = 0 },
    { input = "2 == 2", output = 1 },
    { input = "2 != 2", output = 0 },
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
      vm.run(code, memory, stack, false, 0)

      local result = stack[1]
      lu.assertEquals(result, case.output)
    end
  end
end
