local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testSequence()
  local cases = {
    { input = "result = 3", result = 3 },
    { input = "{ result = 5 }", result = 5 },
    { input = "{ result = 6; result2 = 7; }", result = 6, result2 = 7 },
    { input = "{ result = 9;; }", result = 9 },
    { input = "{ result = 9;   ; }", result = 9 },
  }

  for _, case in ipairs(cases) do
    local input = "function main() {" .. case.input .. "}"
    local parsed = parser.parse(input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack, false, 0)

    lu.assertEquals(memory[1], case.result)
    if case.result2 then
      lu.assertEquals(memory[2], case.result2)
    end
  end
end
