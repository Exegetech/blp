local lpeg = require "lpeg"

lpeg.P("hello"):match("hello world")
lpeg.P("hella()[]"):match("hella()[]")

lpeg.S("aeiou"):match("alo")
lpeg.S("aeiou"):match("ei")
lpeg.S("aeiou"):match("hello")

lpeg.R("AZ"):match("Ap")
lpeg.R("AZ"):match("(")
lpeg.R("AZ"):match("az")

lpeg.P(3):match("hello")
lpeg.P(3):match("hy")

