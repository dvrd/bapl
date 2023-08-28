-- This is a little arithmetic parser (lap)
-- you can make simple calculations making use of
-- a lpeg parser grammar being exposed from the return

local lpeg = require "lpeg"
-- local inspect = require "inspect"
local f = require "F"
-- + = OR
-- * = AND
-- ^ = N or more

local pattern = lpeg.P
local sequence = lpeg.S
local range = lpeg.R
local capture = lpeg.C
-- local capture_position = lpeg.Cp
local capture_table = lpeg.Ct

local function tovector(t)
	if #t > 2 then
		error "error: only 2d vectors are allowed"
	end
	local convert = function(a)
		if type(a) == "table" then
			return a
		elseif type(a) == "number" then
			return { a, a }
		else
			error(f "error: can't make a vector out of {type(a)}")
		end
	end

	return setmetatable(t, {
		__mul = function(a, b)
			a, b = convert(a), convert(b)
			return a[1] * b[1] + a[2] * b[2]
		end,
		__add = function(a, b)
			a, b = convert(a), convert(b)
			return { a[1] + b[1], a[2] + b[2] }
		end,
		__sub = function(a, b)
			a, b = convert(a), convert(b)
			return { a[1] - b[1], a[2] - b[2] }
		end
	})
end

local function factorial(n)
	if n == 1 then
		return 1
	else
		return n * factorial(n - 1)
	end
end

local function fold(lst)
	local acc = lst[1]
	for i = 2, #lst, 2 do
		if lst[i] == "+" then
			acc = acc + lst[i + 1]
		elseif lst[i] == "-" then
			acc = acc - lst[i + 1]
		elseif lst[i] == "*" then
			acc = acc * lst[i + 1]
		elseif lst[i] == "/" then
			acc = acc / lst[i + 1]
		elseif lst[i] == "%" then
			acc = acc % lst[i + 1]
		elseif lst[i] == "^" then
			acc = acc ^ lst[i + 1]
		elseif lst[i] == "!" then
			acc = factorial(acc)
		else
			error("unknown operator")
		end
	end
	return acc
end

local space = sequence " \n\t" ^ 0
local OP = pattern "(" * space
local CP = pattern ")" * space
local numeral = (range "09" ^ 1 / tonumber) * space
local op_add = capture(sequence "+-") * space
local op_mul = capture(sequence "*/%") * space
local op_exp = capture(pattern "^") * space
local op_fact = capture(pattern "!") * space

local vector = lpeg.V "vector"
local primary = lpeg.V "primary"
local fac = lpeg.V "fac"
local exponent = lpeg.V "exponent"
local term = lpeg.V "term"
local expression = lpeg.V "expression"

local grammar = lpeg.P { "expression",
	vector     = OP * capture_table(numeral * ("," * space * numeral) ^ 0) / tovector * CP,
	primary    = numeral + (OP * expression * CP) + vector,
	fac        = space * capture_table(primary * op_fact ^ -1) / fold,
	exponent   = space * capture_table(fac * (op_exp * fac) ^ 0) / fold,
	term       = space * capture_table(exponent * (op_mul * exponent) ^ 0) / fold,
	expression = space * capture_table(term * (op_add * term) ^ 0) / fold,
}

local grammar = grammar * -1

return grammar

-- local subject = "5! * (2 + 4) + (10, 2) * 10"
-- print(subject)
-- print(inspect(grammar:match(subject)))
