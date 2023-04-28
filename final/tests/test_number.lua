local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testNumbers()
  local cases = {
    { input = "1", output = 1 },
    { input = " 1", output = 1 },
    { input = " 1 ", output = 1 },
    { input = "01 ", output = 1 },
    { input = " 010", output = 10 },
    { input = " -010", output = -10 },
    { input = " +010", output = 10 },
    { input = "0.5", output = 0.5 },
    { input = ".3", output = 0.3 },
    { input = "3.", output = 3.0 },
    { input = "1.3", output = 1.3 },
    { input = "000.9", output = 0.9 },
    { input = "000.8b", output = nil },
    { input = "+0000.7", output = 0.7 },
    { input = "-0000.7", output = -0.7 },
    { input = "2e3", output = 2000.0 },
    { input = "2.3e-5", output = 0.000023 },
    { input = "2.3e-5.3", output = nil },
    { input = "1a", output = nil },
    { input = "0xF", output = 15 },
    { input = "0xFF", output = 255 },
    { input = "0xff", output = 255 },
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
