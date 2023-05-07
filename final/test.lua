local lu = require("luaunit")

local tests = {
  -- "tests/test_number",
  -- "tests/test_arithmetic",
  -- "tests/test_comparison",
  -- "tests/test_assignment",
  -- "tests/test_sequence",
  -- "tests/test_return",
  -- "tests/test_print",
  -- "tests/test_undefined_variable",
  -- "tests/test_syntax_error",
  -- "tests/test_comment",
  -- "tests/test_negation",
  -- "tests/test_if",
  -- "tests/test_while",
  -- "tests/test_logical",
  -- "tests/test_array",
  "tests/test_function",
}

for _, test in ipairs(tests) do
  require(test)
  lu.run()
end

