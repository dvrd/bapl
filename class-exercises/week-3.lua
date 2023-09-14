local lpeg = require"lpeg"
local pt = require"pt"

local function foldBin (lst)
  local tree = lst[1]
  for i = 2, #lst, 2 do
    tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
  end
  return tree
end

local function packUn (op, exp)
  return { tag = "unop", op = op, e = exp }
end

local space = lpeg.S" \t\n"^0
local numeral = lpeg.C(lpeg.R"09"^1) * space
local OP = "(" * space
local CP = ")" * space
local opA = lpeg.C(lpeg.S"+-") * space
local opM = lpeg.C(lpeg.S"*/%") * space

local basic = lpeg.V"basic"
local term1 = lpeg.V"term1"
local term2 = lpeg.V"term2"
local exp = lpeg.V"exp"

grammar = lpeg.P{"exp",
  basic = numeral + OP * exp * CP,
  term1 = lpeg.C("-") * basic / packUn + basic,
  term2 = lpeg.Ct(term1 * (opM * term1)^0) / foldBin,
  exp = lpeg.Ct(term2 * (opA * term2)^0) / foldBin,
}

print(pt.pt(grammar:match(io.read("*a"))))
