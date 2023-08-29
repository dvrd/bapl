local inspect = require "inspect"
local f = require "F"
local grammar = require "week-2.grammar"

local M = {
	inspect = inspect
}

M.parse = function(input)
	return grammar:match(input)
end

local function addCode(state, op)
	local code = state.code
	code[#code + 1] = op
end

local function codeExp(state, ast)
	if ast.tag == "number" then
		addCode(state, "push")
		addCode(state, ast.val)
	elseif ast.tag == "binop" then
		codeExp(state, ast.e1)
		codeExp(state, ast.e2)
		addCode(state, ast.op.tag)
	elseif ast.tag == "ident" then
	else
		error(f "error: invalid tree {ast}")
	end
end

M.compile = function(ast)
	local state = { code = {} }
	codeExp(state, ast)
	return state.code
end

M.run = function(code, stack)
	local pc = 1
	local top = 0
	while pc <= #code do
		if code[pc] == "push" then
			print(f "debug: {code[pc]} -> {code[pc + 1]}")
			pc = pc + 1
			top = top + 1
			stack[top] = code[pc]
		elseif code[pc] == "add" then
			print(f "debug: {code[pc]} -> {stack[top - 1]} {stack[top]}")
			stack[top - 1] = stack[top - 1] + stack[top]
			top = top - 1
		elseif code[pc] == "sub" then
			print(f "debug: {code[pc]} -> {stack[top - 1]} {stack[top]}")
			stack[top - 1] = stack[top - 1] - stack[top]
			top = top - 1
		elseif code[pc] == "mul" then
			print(f "debug: {code[pc]} -> {stack[top - 1]} {stack[top]}")
			stack[top - 1] = stack[top - 1] * stack[top]
			top = top - 1
		elseif code[pc] == "quo" then
			print(f "debug: {code[pc]} -> {stack[top - 1]} {stack[top]}")
			stack[top - 1] = stack[top - 1] / stack[top]
			top = top - 1
		elseif code[pc] == "mod" then
			print(f "debug: {code[pc]} -> {stack[top - 1]} {stack[top]}")
			stack[top - 1] = stack[top - 1] % stack[top]
			top = top - 1
		elseif code[pc] == "pow" then
			print(f "debug: {code[pc]} -> {stack[top - 1]} {stack[top]}")
			stack[top - 1] = math.pow(stack[top - 1], stack[top])
			top = top - 1
		else
			print(f "error: unknown instruction {code[pc]}")
		end
		pc = pc + 1
	end
	return stack
end

return M
