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
    if case.output == nil then
      local parsed = parser.parse(case.input)
      lu.assertEquals(parsed, nil)
    else
      local parsed = parser.parse(case.input)
      local code = ast.compile(parsed)

      local stack = {}
      local memory = {}
      vm.run(code, memory, stack)

      local result = stack[1]
      lu.assertEquals(result, case.output)
    end
  end
end
