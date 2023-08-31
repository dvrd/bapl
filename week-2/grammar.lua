local lpeg = require "lpeg"

local loc = lpeg.locale()
local p = lpeg.P
local s = lpeg.S
local r = lpeg.R
local ct = lpeg.Ct
local v = lpeg.V

local function tonode(t)
	return function(val)
		return {
			tag = t,
			val = t == "number" and tonumber(val) or val,
		}
	end
end

local function fold(lst)
	local ast = lst[1]
	for i = 2, #lst, 2 do
		ast = { tag = "binop", e1 = ast, op = lst[i], e2 = lst[i + 1] }
	end
	return ast
end

local space = loc.space ^ 0
local OP = "(" * space
local CP = ")" * space

local sign = p "-" ^ -1
local digit = loc.digit ^ 1

local hex_prefix = "0" * s "xX"
local hex_digit = r("09", "af", "AF")
local hex = hex_prefix * hex_digit * hex_digit ^ -5 * -hex_digit

local dot = p "."
local decimal = (digit * dot * digit) + (digit * dot) + (dot * digit)

local scientific = (decimal + digit) * s "eE" * (p "-" ^ -1) * digit
local numeral = (sign * (hex + scientific + decimal + digit) / tonode "number") * space

local add = p "+" / tonode "add" * space
local sub = p "-" / tonode "sub" * space
local mul = p "*" / tonode "mul" * space
local div = p "/" / tonode "div" * space
local mod = p "%" / tonode "mod" * space
local pow = p "^" / tonode "pow" * space
local gte = p ">=" / tonode "gte" * space
local lte = p "<=" / tonode "lte" * space
local neq = p "!=" / tonode "neq" * space
local gt = p ">" / tonode "gt" * space
local lt = p "<" / tonode "lt" * space
local eq = p "==" / tonode "eq" * space

local op_add = add + sub
local op_mul = mul + div + mod
local op_exp = pow
local op_cmp = gte + lte + gt + lt + neq + eq

local exponent = v "exponent"
local term = v "term"
local expression = v "expression"
local cmp = v "cmp"
local factor = v "factor"

local grammar = p { "cmp",
	exponent   = space * ct(factor * (op_exp * factor) ^ 0) / fold,
	term       = space * ct(exponent * (op_mul * exponent) ^ 0) / fold,
	expression = space * ct(term * (op_add * term) ^ 0) / fold,
	cmp        = space * ct(expression * (op_cmp * expression) ^ 0) / fold,
	factor     = space * numeral + (OP * cmp * CP),
}

return space * grammar * -1
