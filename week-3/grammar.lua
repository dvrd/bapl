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
local ID = loc.alpha * loc.alnum ^ 0
local var = ID / tonode "variable" * space

local sign = p "-" ^ -1
local digit = loc.digit ^ 1

local hex_prefix = "0" * s "xX"
local hex_digit = r("09", "af", "AF")
local hex = hex_prefix * hex_digit * hex_digit ^ -5 * -hex_digit

local dot = p "."
local decimal = (digit * dot * digit) + (digit * dot) + (dot * digit)

local scientific = (decimal + digit) * s "eE" * (p "-" ^ -1) * digit
local numeral = (sign * (hex + scientific + decimal + digit) / tonode "number") * space

local op_add = p "+" / tonode "add" * space
local op_sub = p "-" / tonode "sub" * space
local op_mul = p "*" / tonode "mul" * space
local op_div = p "/" / tonode "div" * space
local op_mod = p "%" / tonode "mod" * space
local op_pow = p "^" / tonode "pow" * space

local op_quo = op_div + op_mod

local gte = p ">=" / tonode "gte" * space
local lte = p "<=" / tonode "lte" * space
local neq = p "!=" / tonode "neq" * space
local gt = p ">" / tonode "gt" * space
local lt = p "<" / tonode "lt" * space
local eq = p "==" / tonode "eq" * space
local op_cmp = gte + lte + gt + lt + neq + eq

local pow = v "pow"
local mul = v "mul"
local div = v "div"
local add = v "add"
local sub = v "sub"
local cmp = v "cmp"
local atom = v "atom"

local grammar = p { "cmp",
	pow  = space * ct(atom * (op_pow * atom) ^ 0) / fold,
	mul  = space * ct(pow * (op_mul * pow) ^ 0) / fold,
	div  = space * ct(mul * (op_quo * mul) ^ 0) / fold,
	add  = space * ct(div * (op_add * div) ^ 0) / fold,
	sub  = space * ct(add * (op_sub * add) ^ 0) / fold,
	cmp  = space * ct(sub * (op_cmp * sub) ^ 0) / fold,
	atom = space * numeral + (OP * cmp * CP) + var,
}

return space * grammar * -1
