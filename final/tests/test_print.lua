local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testPrint()
  -- TODO: How to capture print statement in Luaunit?
  local cases = {
    { input = "@ 3" },
    { input = "@ 4 + 4" },
    { input = "x = 2; @ x + 4" },
    { input = "x = 2; @ x + 4; y = 8 + x; @ y" },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack)
    lu.assertEquals(true, true)
  end
end

