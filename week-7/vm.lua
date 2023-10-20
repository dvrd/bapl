local utils = require "utils.core"
local debug = require "week-7.debug"

local M = {}

local function compare(expr)
	if expr then
		return 1
	else
		return 0
	end
end

local binops = {
	["add"] = function(x, y) return x + y end,
	["sub"] = function(x, y) return x - y end,
	["mul"] = function(x, y) return x * y end,
	["div"] = function(x, y) return x / y end,
	["mod"] = function(x, y) return x % y end,
	["pow"] = function(x, y) return math.pow(x, y) end,
	["gte"] = function(x, y) return compare(x >= y) end,
	["lte"] = function(x, y) return compare(x <= y) end,
	["neq"] = function(x, y) return compare(x ~= y) end,
	["eq"]  = function(x, y) return compare(x == y) end,
	["gt"]  = function(x, y) return compare(x > y) end,
	["lt"]  = function(x, y) return compare(x < y) end
}

local unops = {
	["neg"] = function(x) return -x end,
	["pos"] = function(x) return x end,
	["not"] = function(x) return x > 0 and 0 or 1 end,
}

local Stack = {}

function Stack:new(top)
	top = top or 0
	local t = { top = top, data = {} }
	self.__index = self
	setmetatable(t, self)
	return t
end

function Stack:push(...)
	local vals = table.pack(...)
	for i = 1, vals.n do
		self.top = self.top + 1
		self.data[self.top] = vals[i]
	end
end

function Stack:pop(n)
	n = n or 1
	local t = {}
	for i = n, 1, -1 do
		t[i] = self.data[self.top]
		self.data[self.top] = nil
		self.top = self.top - 1
	end
	return table.unpack(t)
end

function Stack:peek(n, loc)
	n = n or 1
	loc = loc or 0
	local t = {}
	for i = 1, n do
		t[n - (i - 1)] = self.data[self.top - (i - 1)]
	end
	return table.unpack(t)
end

M.exec = function(code, mem, stack, flags)
	local pc = 1
	local instruction = nil
	local trace_data = nil

	local dispatch = {
		["call"] = function()
			pc = pc + 1
			local fnCode = code[pc]
			stack.top = M.exec(fnCode, mem, stack, flags)
		end,
		["dup"] = function()
			stack:push(stack:peek())
		end,
		["2dup"] = function()
			stack:push(stack:peek(2))
		end,
		["newarray"] = function()
			local size = stack:pop()
			stack:push({ size = size })
		end,
		["getarray"] = function()
			local array, index = stack:pop(2)
			assert(array.size > index and index >= 0, "IndexError: index out of range")
			stack:push(array[index])
		end,
		["setarray"] = function()
			io.write("SETTING ARRAY")
			local array, index, value = stack:pop(3)
			assert(array.size > index and index >= 0, "IndexError: index out of range")
			array[index] = value
		end,
		["ret"] = function()
			local n = code[pc + 1]
			stack:pop(n)
			return true
		end,
		["print"] = function()
			local value = stack:pop()
			if type(value) == "table" then
				io.write("[")
				for idx = 0, #value do
					if idx ~= #value then
						io.write(value[idx] .. ", ")
					else
						io.write(value[idx])
					end
				end
				io.write("]\n")
			else
				print(value)
			end
		end,
		["dec"] = function()
			stack:push(stack:pop() - 1)
		end,
		["pop"] = function()
			pc = pc + 1
			stack:pop(code[pc])
		end,
		["push"] = function()
			pc = pc + 1
			stack:push(code[pc])
		end,
		["load"] = function()
			pc = pc + 1
			local id = code[pc]
			assert(mem[id], "UndefinedError: variable has not been assigned inside current scope")
			stack:push(mem[id])
		end,
		["store"] = function()
			pc = pc + 1
			local id = code[pc]
			mem[id] = stack:pop()
		end,
		["jmpZ"] = function()
			pc = pc + 1
			local label = stack:peek()
			if label == 0 then
				pc = code[pc]
			end
			stack:pop()
		end,
		["jmpZP"] = function()
			pc = pc + 1
			local label = stack:peek()
			if label == 0 then
				pc = code[pc]
			else
				stack:pop()
			end
		end,
		["jmpNZP"] = function()
			pc = pc + 1
			local label = stack:peek()
			if label ~= 0 then
				pc = code[pc]
			else
				stack:pop()
			end
		end,
		["jmp"] = function()
			pc = pc + 1
			pc = code[pc]
		end,
	}

	while true do
		---[[
		utils.pt(code)
		print("INSTRUCTION: " .. code[pc])
		--]]
		instruction = code[pc]

		if dispatch[instruction] then
			local fn = dispatch[instruction]
			trace_data = instruction == "print" and stack:peek() or code[pc + 1]
			if fn() then return stack.top end
		elseif binops[instruction] then
			local fn = binops[instruction]
			trace_data = stack:peek(2)
			local a, b = stack:pop(2)
			stack:push(fn(a, b))
		elseif unops[instruction] then
			local fn = unops[instruction]
			stack:push(fn(stack:pop()))
		else
			print("ERROR: unknown instruction '" .. instruction .. "'")
			os.exit(1)
		end

		debug.trace(stack, stack.top, instruction, trace_data, flags)
		pc = pc + 1
	end
end

M.stack = Stack

return M
