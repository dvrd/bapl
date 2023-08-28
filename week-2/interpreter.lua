local lpeg = require "lpeg"
local inspect = require "inspect"
local f = require "F"
-- + = OR
-- * = AND
-- ^ = N or more

local loc = lpeg.locale() -- utilities by locale
local p = lpeg.P          -- Match pattern
local s = lpeg.S          -- Match sequence
-- local r = lpeg.R					-- Match range
-- local c = lpeg.C					-- Capture a pattern
-- local cc = lpeg.Cc 				-- Capture a constant
local ct = lpeg.Ct -- Capture a table
-- local cp = lpeg.Cp 				-- Capture a point?
local v = lpeg.V   -- Link to a grammar

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

local operations = {}
operations = {
	add = function(x, y) return x + y end,
	sub = function(x, y) return x - y end,
	mul = function(x, y) return x * y end,
	quo = function(x, y) return x / y end,
	mod = function(x, y) return x % y end,
	pow = function(x, y) return math.pow(x, y) end,
	fact = function(n)
		local acc = 1
		local val = n
		while val > 1 do
			acc = acc * val
			val = val - 1
		end
		return f
	end
}

local function fold(lst)
	local acc = lst[1]
	for i = 2, #lst, 2 do
		local op = lst[i]
		acc = op(acc, lst[i + 1])
	end
	return acc
end

local function tonode(t)
	return function(val)
		return {
			tag = t,
			val = t == "number" and tonumber(val) or val,
		}
	end
end

-- local no_colon = (1 - p(";")) ^ 0 * ";"

local kw = { "if", "then", "else", "while", "do" }
local keywords = p(false)
for _, w in ipairs(kw) do
	keywords = keywords + w
end
keywords = keywords * -loc.alnum

local space = loc.space ^ 0
local id = (loc.alpha * loc.alnum ^ 0) - keywords
local ident = id / tonode("ident") * space
local comma = "," * space
local eq = "=" * space
local OP = "(" * space
local CP = ")" * space

local assign = ident * eq

local sign = s "+-" ^ -1
local digit = loc.digit ^ 1
local numeral = (sign * digit / tonode("number")) * space

local op_add = p "+" / tonode("add") * space
local op_sub = p "-" / tonode("sub") * space
local op_mul = p "*" / tonode("mul") * space
local op_quo = p "/" / tonode("quo") * space
local op_mod = p "%" / tonode("mod") * space
local op_exp = p "^" / tonode("pow") * space

local vector = v "vector"
local factor = v "factor"
local exponent = v "exponent"
local term = v "term"
local expression = v "expression"

local calc = p { "expression",
	vector     = OP * (numeral * (comma * numeral) ^ 0) / tovector * CP,
	exponent   = space * factor * (op_exp * factor) ^ 0,
	term       = space * exponent * ((op_mul + op_quo + op_mod) * exponent) ^ 0,
	expression = space * term * ((op_add + op_sub) * term) ^ 0,
	factor     = numeral + (OP * expression * CP) + vector,
}

calc = ct((assign * calc) + calc) * -1
local function parse(input)
	return calc:match(input)
end

while true do
	io.write(">> ")
	local input = io.read()
	local ast = parse(input)
	print(inspect(ast))
end
