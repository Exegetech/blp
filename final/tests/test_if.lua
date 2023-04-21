local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testIf()
  local cases = {
    { input = [[
      a = 1;
      if a { b = 5; };
      return b;
    ]], output = 5 },
    { input = [[
      a = 0;
      b = 0;
      if a { b = 5; };
      return b;
    ]], output = 0 },
    { input = [[
      a = 0;
      b = 0;
      if a {
        b = 5;
      } else {
        b = 2;
      };
      return b;
    ]], output = 2 },
    { input = [[
      a = 0;
      b = 1;
      c = 0;
      if a {
        c = 10;
      } elseif b {
        c = 15;
      };
      return c;
    ]], output = 15 },
    { input = [[
      a = 0;
      b = 1;
      c = 0;
      if a {
        c = 10;
      } elseif b {
        c = 15;
      } else {
        c = 5;
      };
      return c;
    ]], output = 15 },
    { input = [[
      a = 0;
      b = 0;
      c = 0;
      if a {
        c = 10;
      } elseif b {
        c = 15;
      } else {
        c = 5;
      };
      return c;
    ]], output = 5 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end
