local lpeg = require "lpeg"
local math = require "math"
---[[
local utils = require "utils.core"
--]]

local loc = lpeg.locale()
local p = lpeg.P
local s = lpeg.S
local r = lpeg.R
local ct = lpeg.Ct
local c = lpeg.C
-- local cmt = lpeg.Cmt
local v = lpeg.V

local function node(tag, ...)
	local labels = table.pack(...)
	return function(...)
		local params = table.pack(...)
		local ast = { tag = tag }
		for idx, label in ipairs(labels) do
			ast[label] = params[idx]
		end
		return ast
	end
end

local function tonode(t)
	return function(data, more)
		local node = { tag = t }
		if t == "sequence" then
			if more == nil then
				return data
			else
				node.st1 = data
				node.st2 = more
			end
		elseif t == "unary" then
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
		return node
	end
end

local function packUnary(op, exp)
	return { tag = "unop", op = op, e = exp }
end

local function fold(lst)
	local ast = lst[1]
	for idx = 2, #lst, 2 do
		ast = { tag = "binop", e1 = ast, op = lst[idx], e2 = lst[idx + 1] }
	end
	return ast
end

local function foldIndex(lst)
	local ast = lst[1]
	for idx = 2, #lst do
		ast = { tag = "indexed", array = ast, index = lst[idx] }
	end
	return ast
end

local function foldNew(lst)
	local tree = { tag = "new", size = lst[#lst] }
	for i = #lst - 1, 1, -1 do
		tree = { tag = "new", size = lst[i], eltype = tree }
	end
	return tree
end

LAST_LINE = 0
MAXMATCH = 0
local space = v "space"

local reserved = { "return", "if", "else", "elsif", "while", "new", "fn", "let" }
local excluded = p(false)
for idx = 1, #reserved do
	excluded = excluded + reserved[idx]
end
excluded = excluded * -loc.alnum

local dot = p "."
local underscore = p "_"

local ID = v "ID"
local var = ID / node("variable", "val")
local block_comment = "#{" * (p(1) - p "#}") ^ 0
local comment = "#" * (p(1) - p "\n") ^ 0
local comments = block_comment + comment

local digit = loc.digit ^ 1

local hex_prefix = "0" * s "xX"
local hex_digit = r("09", "af", "AF")
local hex = hex_prefix * hex_digit * hex_digit ^ -5 * -hex_digit

local decimal = (digit * dot * digit) + (digit * dot) + (dot * digit)

local scientific = (decimal + digit) * s "eE" * underscore ^ -1 * digit
local numeral = (hex + scientific + decimal + digit) / tonumber / node("number", "val") * space

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

local _and = p "&&" / tonode "and" * space
local _or = p "||" / tonode "or" * space

local op_cmp = _or + _and + gte + lte + gt + lt + neq + eq

local op_unary = s "!+-" / tonode "unary" * space

-- Rules
local pow = v "pow"
local mul = v "mul"
local div = v "div"
local add = v "add"
local sub = v "sub"
local cmp = v "cmp"
local term = v "term"
local stmt = v "stmt"
local expr = v "expr"
local stmts = v "stmts"
local block = v "block"
local unary = v "unary"
local lhs = v "lhs"
local fun = v "fun"
local call = v "call"
local params = v "params"
local args = v "args"

local function token(t)
	return t * space
end

local function keyword(w)
	assert(excluded:match(w))
	return w * -loc.alnum * space
end

local function executionTracker(subject, pos, _)
	MAXMATCH = math.max(MAXMATCH, pos)
	if string.sub(subject, pos, pos + 1) == ";\n" then
		LAST_LINE = LAST_LINE + 1
	end
	return true
end

local op_print = token "@" * expr / node("print", "exp")
local op_assign = lhs * token "=" * expr / node("assign", "lhs", "exp")
local op_return = keyword "return" * expr / node("ret", "exp")
local op_else = (keyword "else" * block) ^ -1
local op_elsif = (keyword "elsif" * expr * block) ^ 1 * op_else / node("if", "cond", "thn", "els")
local op_if = keyword "if" * expr * block * (op_elsif + op_else) / node("if", "cond", "thn", "els")
local op_while = keyword "while" * expr * block / node("while", "cond", "body")
local op_new = ct(keyword "new" * (token "[" * expr * token "]") ^ 1) / foldNew
local op_lambda = ID * token "=" * token "(" * params * token ")" * token "=>" * block /
		node("function", "name", "params", "body")
local op_function = keyword "fn" * ID * token "(" * params * token ")" * block /
		node("function", "name", "params", "body")
local op_local_variable = keyword "let" * ID * token "=" * expr / node("local", "name", "init")

return p { "prog",
	ID     = (c((underscore + loc.alpha) * (loc.alnum + underscore) ^ 0) - excluded) * space,

	prog   = space * ct((fun + stmts + expr) ^ 1) * -1,

	fun    = op_lambda + op_function,

	params = ct((ID * (token "," * ID) ^ 0) ^ -1),

	args   = ct((expr * (token "," * expr) ^ 0) ^ -1),

	stmt   = fun + block + op_local_variable + op_print + op_if + op_while + call + op_assign + op_return,

	lhs    = ct(var * (token "[" * expr * token "]") ^ 0) / foldIndex,

	stmts  = (stmt * token ";" ^ 0) * stmts ^ -1 / tonode "sequence",

	block  = token "{" * stmts ^ 0 * token "}" / node("block", "body"), -- NOTE: Make empty functions work

	space  = (loc.space + comments) ^ 0 * p(executionTracker),

	call   = ID * token "(" * args * token ")" / node("call", "name", "args"),

	expr   = cmp,

	term   = op_new + numeral + (token "(" * expr * token ")") + call + lhs,

	unary  = op_unary * (numeral + unary) / packUnary + term,

	pow    = ct(unary * (op_pow * unary) ^ 0) / fold,

	mul    = ct(pow * (op_mul * pow) ^ 0) / fold,

	div    = ct(mul * (op_quo * mul) ^ 0) / fold,

	add    = ct(div * (op_add * div) ^ 0) / fold,

	sub    = ct(add * (op_sub * add) ^ 0) / fold,

	cmp    = ct(sub * (op_cmp * sub) ^ 0) / fold,
}
