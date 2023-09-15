local inspect = require "inspect"
local utils = require "utils.core"
local grammar = require "week-4.grammar"

local M = {
	inspect = inspect
}

local function findPrevStmt(input, pos)
	local match = 0
	local newPos = 0
	for i = pos - 1, 0, -1 do
		newPos = i
		if string.sub(input, i, i) == ";" then
			match = match + 1
		end
		if match == 3 then
			return newPos
		end
		i = i - 1
	end
	return newPos
end

local function syntaxError(input)
	local high = MAXMATCH + 20 > #input and 0 or MAXMATCH + 20
	local prev = findPrevStmt(input, MAXMATCH)
	local low = prev > 0 and prev or 0

	io.stderr:write("SYNTAX ERROR at position ", MAXMATCH, " of ", #input, "\n")
	io.stderr:write("on line ", LAST_LINE, ": ")

	io.stderr:write(string.sub(input, low, MAXMATCH - 3))                                  -- Pre-error

	io.stderr:write("\27[1;4;31m", string.sub(input, MAXMATCH - 2, MAXMATCH + 2), "\27[0m") -- Error highlighting

	io.stderr:write(string.sub(input, MAXMATCH + 3, high), "\n")                           -- Post-error
end

M.parse = function(input)
	local ret = grammar:match(input)
	if not ret then
		syntaxError(input)
	end
	return ret
end

local Compiler = { code = {}, vars = {}, nvars = 0 }

function Compiler:addCode(op)
	self.code[#self.code + 1] = op
end

function Compiler:var2num(id)
	local num = self.vars[id]
	if not num then
		num = self.nvars + 1
		self.nvars = num
		self.vars[id] = num
	end
	return num
end

function Compiler:codeExp(ast)
	if ast.tag == "number" then
		self:addCode("push")
		self:addCode(ast.val)
	elseif ast.tag == "unop" then
		self:codeExp(ast.e)
		self:addCode(ast.op.tag)
	elseif ast.tag == "binop" then
		self:codeExp(ast.e1)
		self:codeExp(ast.e2)
		self:addCode(ast.op.tag)
	elseif ast.tag == "variable" then
		self:addCode("load")
		self:addCode(self:var2num(ast.val))
	elseif ast.tag == "assign" then
		self:addCode("store")
		self:addCode(ast.val)
	else
		if type(ast) == "table" then
			io.write("error: invalid expression -> ")
			utils.pt(ast)
		else
			print("error: invalid expression -> " .. ast)
		end
	end
end

function Compiler:codeStat(ast)
	if ast.tag == "assign" then
		self:codeExp(ast.exp)
		self:addCode("store")
		self:addCode(self:var2num(ast.val))
	elseif ast.tag == "sequence" then
		self:codeStat(ast.st1)
		self:codeStat(ast.st2)
	elseif ast.tag == "block" then
		if ast.st then self:codeStat(ast.st) end
	elseif ast.tag == "print" then
		self:codeExp(ast.exp)
		self:addCode("print")
	elseif ast.tag == "ret" then
		self:codeExp(ast.exp)
		self:addCode("ret")
	else
		self:codeExp(ast)
	end
end

M.compile = function(ast)
	---[[
	io.write("ast: ")
	utils.pt(ast)
	utils.pt(Compiler)
	--]]
	Compiler:codeStat(ast)
	Compiler:addCode("push")
	Compiler:addCode(0)
	Compiler:addCode("ret")

	local result = Compiler.code
	Compiler.code = {}
	return result
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

local unops = {
	["neg"] = function(x) return -x end,
	["pos"] = function(x) return x end,
	["not"] = function(x) return x > 0 and 0 or 1 end,
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
		---[[
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
		elseif unops[instruction] then
			local fn = unops[instruction]
			stack[top] = fn(stack[top])
		else
			utils.ef "error: unknown instruction {pc}"
		end

		trace(stack, top, instruction, trace_data, flags)
		pc = pc + 1
	end
end

return M
