local inspect = require "inspect"
local utils = require "utils.core"
local grammar = require "week-3.grammar"

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

local function var2num(state, id)
	local num = state.vars[id]
	if not num then
		num = state.nvars + 1
		state.nvars = num
		state.vars[id] = num
	end
	return num
end

local function codeExp(state, ast)
	if ast.tag == "number" then
		addCode(state, "push")
		addCode(state, ast.val)
	elseif ast.tag == "binop" then
		codeExp(state, ast.e1)
		codeExp(state, ast.e2)
		addCode(state, ast.op.tag)
	elseif ast.tag == "variable" then
		addCode(state, "load")
		addCode(state, var2num(state, ast.val))
	elseif ast.tag == "assign" then
		addCode(state, "store")
		addCode(state, ast.val)
	else
		if type(ast) == "table" then
			io.write("error: invalid expression -> ")
			utils.pt(ast)
		else
			print("error: invalid expression -> " .. ast)
		end
	end
end

local function codeStat(state, ast)
	if ast.tag == "assign" then
		codeExp(state, ast.exp)
		addCode(state, "store")
		addCode(state, var2num(state, ast.val))
	elseif ast.tag == "sequence" then
		codeStat(state, ast.st1)
		codeStat(state, ast.st2)
	elseif ast.tag == "block" then
		if ast.st then codeStat(state, ast.st) end
	elseif ast.tag == "print" then
		codeExp(state, ast.exp)
		addCode(state, "print")
	elseif ast.tag == "ret" then
		codeExp(state, ast.exp)
		addCode(state, "ret")
	else
		codeExp(state, ast)
	end
end

M.compile = function(ast)
	local state = { code = {}, vars = {}, nvars = 0 }
	-- io.write("ast: ")
	-- utils.pt(ast)
	codeStat(state, ast)
	addCode(state, "push")
	addCode(state, 0)
	addCode(state, "ret")

	return state.code
end

local function dumpStack(stack, top)
	for i = 1, top do
		io.stderr:write(stack[i])

		if i ~= top then
			io.stderr:write(", ")
		end
	end
end

local function trace(stack, top, op, val, flags)
	if flags and flags["trace"] then
		io.stderr:write("[TRACE]\t")

		if val then
			io.stderr:write(op .. " " .. val .. " --> stack [")
		else
			io.stderr:write(op .. " --> stack ")
		end

		if #stack > 0 then dumpStack(stack, top) end

		if val then io.stderr:write("]") end
		io.stderr:write("\n")
	end
end

local binops = {
	["add"] = function(x, y) return x + y end,
	["sub"] = function(x, y) return x - y end,
	["mul"] = function(x, y) return x * y end,
	["div"] = function(x, y) return x / y end,
	["mod"] = function(x, y) return x % y end,
	["pow"] = function(x, y) return math.pow(x, y) end,
	["gte"] = function(x, y) return x >= y and 1 or 0 end,
	["lte"] = function(x, y) return x <= y and 1 or 0 end,
	["neq"] = function(x, y) return x ~= y and 1 or 0 end,
	["eq"]  = function(x, y) return x == y and 1 or 0 end,
	["gt"]  = function(x, y) return x > y and 1 or 0 end,
	["lt"]  = function(x, y) return x < y and 1 or 0 end
}

M.run = function(code, mem, stack, flags)
	local pc = 1
	local top = 0
	local instruction = nil
	local trace_data = nil

	local dispatch = {
		["ret"] = function()
			return true -- signal to end loop
		end,
		["print"] = function()
			print(stack[top])
		end,
		["push"] = function()
			pc = pc + 1
			top = top + 1
			stack[top] = code[pc]
		end,
		["load"] = function()
			pc = pc + 1
			local id = code[pc]
			top = top + 1
			if mem[id] then
				stack[top] = mem[id]
			else
				print("error: variable have not been assigned")
				return
			end
		end,
		["store"] = function()
			pc = pc + 1
			local id = code[pc]
			mem[id] = stack[top]
			top = top - 1
		end,
	}

	while true do
		--[[
		io.write("pc: " .. pc .. " | code: ")
		utils.pt(code)
		io.write("top: " .. top .. " | stack: ")
		utils.pt(stack)
		--]]
		instruction = code[pc]

		if dispatch[instruction] then
			local fn = dispatch[instruction]
			trace_data = instruction == "print" and stack[top] or code[pc + 1]
			if fn() then return end
		elseif binops[instruction] then
			local fn = binops[instruction]
			trace_data = stack[top - 1] .. " " .. stack[top]
			stack[top - 1] = fn(stack[top - 1], stack[top])
			top = top - 1
		else
			utils.ef "error: unknown instruction {pc}"
		end

		trace(stack, top, instruction, trace_data, flags)
		pc = pc + 1
	end
end

return M
