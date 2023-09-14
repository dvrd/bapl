local i = require "week-4.interpreter"

local function check(case, expect)
	io.write("CASE: " .. case)
	local ast = i.parse(case)
	local code = i.compile(ast)
	local stack = {}
	local mem = {}
	i.run(code, mem, stack, {})
	print("\nresult: " .. tostring(stack[1]) .. " | expected: " .. expect .. "\n")
	assert(stack[1] == expect, "failed: " .. case)
end

local cases = {
	test_add = { "10 + 2", 10 + 2 },
	test_sub = { "10 - 2", 10 - 2 },
	test_mul = { "10 * 2", 10 * 2 },
	test_div = { "10 / 2", 10 / 2 },
	test_mod = { "10 % 2", 10 % 2 },
	test_exp = { "10 ^ 2", 10 ^ 2 },
	test_hex = { "0x0a * 0X02", 0x0a * 0X02 },
	test_float = { "2. + .5 + 0.5", 2. + .5 + 0.5 },
	test_sci = { "2e3 - 2e1", 2e3 - 2e1 },
	test_eq_1 = { "10 == 10", 1 },
	test_eq_0 = { "10 == 20", 0 },
	test_neq_1 = { "10 != 20", 1 },
	test_neq_0 = { "10 != 10", 0 },
	test_gte_1_eq = { "20 >= 20", 1 },
	test_gte_1_gt = { "30 >= 20", 1 },
	test_gte_0 = { "10 >= 11", 0 },
	test_lte_1_eq = { "20 <= 20", 1 },
	test_lte_1_lt = { "20 <= 30", 1 },
	test_lte_0 = { "11 <= 10", 0 },
	test_gt_1 = { "30 > 20", 1 },
	test_gt_0 = { "10 > 11", 0 },
	test_lt_1 = { "20 < 30", 1 },
	test_lt_0 = { "11 < 10", 0 },
	test_neg_sign = { "-11 + 21", -11 + 21 },
	test_paren = { "2 * (2 + 3)", 2 * (2 + 3) },
	test_unary_neg = { "2 + -3", 2 + -3 },
	test_unary_neg_no_op = { "2 -3", 2 - 3 },
	test_assign_of_x = { "x = 1; @ x", 1 },
	test_assign_x_add_y = { "x = 1; y = 2; @ x + y", 3 },
	test_block = { "{ x = 1; y = 2; }; @ x + y", 3 },
	test_empty_block = { "{};", 0 },
}

for test_name, case in pairs(cases) do
	print(test_name)
	check(case[1], case[2])
end
