local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testFunction()
  local cases = {
    { input = [[
      function main() {
        return 2;
      }
    ]], output = 2 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack, false, 0)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end

function Test:testFunctionNameConflict()
  local cases = {
    { input = [[
      function main() {
        return 2;
      }

      function main() {
        return 3;
      }
    ]], output = 2 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)

    local helper = function()
      ast.compile(parsed)
    end

    lu.assertErrorMsgContains("already has function with name main", helper)
  end
end

function Test:testFunctionGlobalVariableConflict()
  local cases = {
    { input = [[
      function main() {
        main = 3;
        return main;
      }
    ]], output = 2 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)

    local helper = function()
      ast.compile(parsed)
    end

    lu.assertErrorMsgContains("cannot have global variable with the same name as a function", helper)
  end
end
