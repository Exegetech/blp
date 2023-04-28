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
    local input = "function main() {" .. case.input .. "}"
    local parsed = parser.parse(input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack, false, 0)
    lu.assertEquals(true, true)
  end
end

