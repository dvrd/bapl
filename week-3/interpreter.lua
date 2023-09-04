local inspect = require "inspect"
local utils = require "utils.core"
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
		utils.ef "error: invalid tree {ast}"
	end
end

M.compile = function(ast)
	local state = { code = {} }
	codeExp(state, ast)
	return state.code
end

local function dumpStack(stack, top)
	for i = 1, top do
		io.stderr:write(stack[i])

		if i ~= top then
			io.stderr:write(" ")
		end
	end
end

local function trace(stack, top)
	return function(op, val)
		io.stderr:write("[TRACE]\t")

		if val then
			io.stderr:write(op .. " " .. val .. "\t\t--> ")
		else
			io.stderr:write(op .. "\t\t--> ")
		end

		dumpStack(stack, top)
		io.stderr:write("\n")
	end
end


M.run = function(code, stack, flags)
	local pc = 1
	local top = 0

	if flags["trace"] then
		trace = trace(stack, top)
	else
		trace = function() end
	end

	while pc <= #code do
		if code[pc] == "push" then
			pc = pc + 1
			top = top + 1
			stack[top] = code[pc]

			trace("push", code[pc])
		elseif code[pc] == "add" then
			stack[top - 1] = stack[top - 1] + stack[top]
			top = top - 1

			trace("add")
		elseif code[pc] == "sub" then
			stack[top - 1] = stack[top - 1] - stack[top]
			top = top - 1

			trace("sub")
		elseif code[pc] == "mul" then
			stack[top - 1] = stack[top - 1] * stack[top]
			top = top - 1

			trace("mul")
		elseif code[pc] == "div" then
			stack[top - 1] = stack[top - 1] / stack[top]
			top = top - 1

			trace("div")
		elseif code[pc] == "mod" then
			stack[top - 1] = stack[top - 1] % stack[top]
			top = top - 1

			trace("mod")
		elseif code[pc] == "pow" then
			stack[top - 1] = math.pow(stack[top - 1], stack[top])
			top = top - 1

			trace("pow")
		elseif code[pc] == "gte" then
			stack[top - 1] = stack[top - 1] >= stack[top] and 1 or 0
			top = top - 1

			trace("gte")
		elseif code[pc] == "lte" then
			stack[top - 1] = stack[top - 1] <= stack[top] and 1 or 0
			top = top - 1

			trace("lte")
		elseif code[pc] == "neq" then
			stack[top - 1] = stack[top - 1] ~= stack[top] and 1 or 0
			top = top - 1

			trace("neq")
		elseif code[pc] == "eq" then
			stack[top - 1] = stack[top - 1] == stack[top] and 1 or 0
			top = top - 1

			trace("eq")
		elseif code[pc] == "gt" then
			stack[top - 1] = stack[top - 1] > stack[top] and 1 or 0
			top = top - 1

			trace("gt")
		elseif code[pc] == "lt" then
			stack[top - 1] = stack[top - 1] < stack[top] and 1 or 0
			top = top - 1

			trace("lt")
		else
			utils.pf "error: unknown instruction {code[pc]}"
		end
		pc = pc + 1
	end
	return stack
end

return M
