local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testComment()
  local cases = {
    { input = [[
      a = 1; # hello world;
      a + 2
    ]], output = 3 },
    { input = [[
      a = 1; # hello world
      a + 2
    ]], output = 3 },
    { input = [[
      return 2 #{ hello world #};
    ]], output = 2 },
    { input = [[
      return 2; #{ hello world #}
    ]], output = 2 },
    { input = [[
     #{ hello world #} return 2;
    ]], output = 2 },
    { input = [[
     #{ #} return 2;
    ]], output = 2 },
    { input = [[
     #{#} return 2;
    ]], output = 2 },
    { input = [[
     #{##} return 2;
    ]], output = 2 },
    { input = [[
     #{#{#} return 2;
    ]], output = 2 },
    { input = [[
      a = 1;
      #{ hello world #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello
      world #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello
      world
      #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world #} #{ foo bar #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world #} y = 2; #{ foo bar #}
      a + y
    ]], output = 3 },
    { input = [[
      a = 1;
      #{ hello world #}
      #{ foo bar #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world; a = 2 #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world #}
      return a;
    ]], output = 1 },
    { input = [[
      a = 1;
      return a #{ hello world #};
    ]], output = 1 },
    { input = [[
      a = 1;
      #{ hello world #} return a;
    ]], output = 1 },
    { input = [[
      a = 1;
      #{ hello world #} b = 10;
      a + b
    ]], output = 11 },
    { input = [[
      a = 1;
      #{ hello world #} b = 1 #{ foo bar #};
      a + b
    ]], output = 2 },
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
