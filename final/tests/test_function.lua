local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")
local util = require("../util")

Test = {}

function Test:testFunction()
  local cases = {
    { input = [[
      function main() {
        return 2;
      }
    ]], output = 2 },
    { input = [[
      function foo() {
        return 33
      }

      function main() {
        return 2 + foo()
      }
    ]], output = 35 },
    { input = [[
      function foo() {
        return 33
      }

      function main() {
        a = foo();
        return 2 + a
      }
    ]], output = 35 },
    { input = [[
      function foo();

      function main() {
        a = foo();
        return 2 + a
      }

      function foo() {
        return 33
      }
    ]], output = 35 },
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

function Test:testFunctionMainCannotHaveParameters()
  local cases = {
    { input = [[
      function main(a) {
        return 3;
      }
    ]], output = 2 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)

    local helper = function()
      ast.compile(parsed)
    end

    lu.assertErrorMsgContains("main function cannot have parameters", helper)
  end
end

-- function Test:testFunctionGlobalVariableConflict()
--   local cases = {
--     { input = [[
--       function main() {
--         { var x = 10;
--           var x = 20;
--           return x;
--         }
--       }
--     ]], output = 2 },
--   }

--   for _, case in ipairs(cases) do
--     local parsed = parser.parse(case.input)

--     local helper = function()
--       ast.compile(parsed)
--     end

--     lu.assertErrorMsgContains("already have variable declared", helper)
--   end
-- end

function Test:testFunctionWithScope()
  local cases = {
    { input = [[
      function main() {
        var x = 10;
        var y = 20;
        return 1;
      }
    ]], output = 1 },
    { input = [[
      function main() {
        { var x = 10; };
        var y = 20;
        return 1;
      }
    ]], output = 1 },
    { input = [[
      function main() {
        var y;
        return 1;
      }
    ]], output = 1 },
    { input = [[
      function main() {
        { var x = 10;
          var y = 20;
          { var z = 30;
            return x / y + z;
          }
        }
      }
    ]], output = 30.5 },
    { input = [[
      function main() {
        { var x = 10;
          var y = 20;
          y = x + 3;
          return y;
        }
      }
    ]], output = 13 },
    { input = [[
      function main() {
        { var x = 10;
          { var x = 5;
            return x;
          };
        };
      }
    ]], output = 5 },
    { input = [[
      function main() {
        { var x = 10; };
        { var x = 5;
          return x;
        };
      }
    ]], output = 5 },
    { input = [[
      function main() {
        { var x = 10;
          { var x = 5; };
          return x;
        };
      }
    ]], output = 10 },


    -- { input = [[
    --   function main() {
    --     { var x = 10;
    --       var x = 20;
    --       { var y = 2;
    --         return y;
    --       }
    --     }
    --   }
    -- ]], output = 2 },
    -- { input = [[
    --   function main() {
    --     { var x = 10;
    --       { var x = 5;
    --        { var y = 2;
    --           return y;
    --         }
    --       }
    --     }
    --   }
    -- ]], output = 2 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)
    -- print(util.pt(parsed))
    local code = ast.compile(parsed)
    -- print(util.pt(code))

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack, false, 0)

    -- print(util.pt(stack))

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end

function Test:testFunctionWithParams()
  local cases = {
    { input = [[
      function fact(x, y) {
        return x - y;
      }

      function main() {
        return fact(10, 2);
      }
    ]], output = 8 },
    { input = [[
      function fact(n) {
        if n {
          return n  * fact(n - 1)
        } else {
          return 1
        }
      }

      function main() {
        return fact(6);
      }
    ]], output = 720 },
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

