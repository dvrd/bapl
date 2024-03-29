local lpeg = require "lpeg"
---[[
local utils = require "utils.core"
--]]

local loc = lpeg.locale()
local p = lpeg.P
local s = lpeg.S
local r = lpeg.R
local ct = lpeg.Ct
local v = lpeg.V

local function tonode(t)
	return function(data, more)
		local node = { tag = t }
		if t == "number" then
			node.val = tonumber(data)
		elseif t == "assign" then
			node.val = data.val
			node.exp = more
		elseif t == "sequence" then
			if more == nil then
				return data
			else
				node.st1 = data
				node.st2 = more
			end
		elseif t == "block" then
			if type(data) == "table" then
				node.st = data
			else
				node.st = nil
			end
		elseif t == "ret" or t == "print" then
			node.exp = data
		elseif t == "unary" then
			utils.pt(data)
			if data == "-" then
				node.tag = "neg"
			elseif data == "+" then
				node.tag = "pos"
			elseif data == "!" then
				node.tag = "not"
			end
		else
			node.val = data
		end
		---[[
		utils.pt(node)
		--]]
		return node
	end
end

local function foldUnary(op, exp, val)
	return { tag = "unop", op = op, e = exp }
end

local function fold(lst)
	local ast = lst[1]
	for i = 2, #lst, 2 do
		ast = { tag = "binop", e1 = ast, op = lst[i], e2 = lst[i + 1] }
	end
	return ast
end

local space = loc.space ^ 0

-- Keywords
local ret = "return" * space

local SC = ";" * space
local OP = "(" * space
local CP = ")" * space
local OB = "{" * space
local CB = "}" * space
local ID = ("_" + loc.alpha) * (loc.alnum + "_") ^ 0
local var = ID / tonode "variable" * space
local assign = "=" * space

-- Symbols
local dot = p "."
local underscore = p "_"

local digit = loc.digit ^ 1

local hex_prefix = "0" * s "xX"
local hex_digit = r("09", "af", "AF")
local hex = hex_prefix * hex_digit * hex_digit ^ -5 * -hex_digit

local decimal = (digit * dot * digit) + (digit * dot) + (dot * digit)

local scientific = (decimal + digit) * s "eE" * underscore ^ -1 * digit
local numeral = (hex + scientific + decimal + digit) / tonode "number" * space

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

local op_unary = s "!+-" ^ -1 / tonode "unary" * space

local pow = v "pow"
local mul = v "mul"
local div = v "div"
local add = v "add"
local sub = v "sub"
local cmp = v "cmp"
local atom = v "atom"
local term = v "term"
local stmt = v "stmt"
local expr = v "expr"
local stmts = v "stmts"
local block = v "block"
local unary = v "unary"

local print = p "@" * space

local grammar = p { "base",
	base  = stmts + expr,
	stmt  = block
			+ print * expr / tonode "print"
			+ var * assign * cmp / tonode "assign"
			+ ret * expr / tonode "ret",
	stmts = (stmt * SC ^ -1) * stmts ^ -1 / tonode "sequence",
	block = OB * stmts ^ 0 * CB / tonode "block",
	expr  = cmp,
	atom  = var + numeral,
	term  = atom + (OP * expr * CP),
	unary = op_unary * unary / foldUnary + term,
	pow   = ct(unary * (op_pow * unary) ^ 0) / fold,
	mul   = ct(pow * (op_mul * pow) ^ 0) / fold,
	div   = ct(mul * (op_quo * mul) ^ 0) / fold,
	add   = ct(div * (op_add * div) ^ 0) / fold,
	sub   = ct(add * (op_sub * add) ^ 0) / fold,
	cmp   = ct(sub * (op_cmp * sub) ^ 0) / fold,
}

return space * grammar * -1
