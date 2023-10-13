local utils = require "utils.core"
local debug = require "week-5.debug"

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

local function exec(code, mem, stack, flags)
	local pc = 1
	local top = 0
	local instruction = nil
	local trace_data = nil

	local dispatch = {
		["newarray"] = function()
			local size = stack[top]
			stack[top] = { size = size }
		end,
		["getarray"] = function()
			local array = stack[top - 1]
			local index = stack[top]
			if array.size > index and index > 0 then
				stack[top - 1] = array[index]
			else
				print("error: index out of bounds")
				stack[top - 1] = nil
			end
			top = top - 1
		end,
		["setarray"] = function()
			local array = stack[top - 2]
			local index = stack[top - 1]
			if array.size > index and index > 0 then
				local value = stack[top]
				array[index] = value
			else
				print("error: assignment index out of bounds")
			end
			top = top - 3
		end,
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
		["jmpZ"] = function()
			pc = pc + 1
			if stack[top] == 0 or stack[top] == nil then
				pc = code[pc]
			end
			top = top - 1
		end,
		["jmpZP"] = function()
			pc = pc + 1
			if stack[top] == 0 or stack[top] == nil then
				pc = code[pc]
			else
				top = top - 1
			end
		end,
		["jmpNZP"] = function()
			pc = pc + 1
			if stack[top] == 0 or stack[top] == nil then
				top = top - 1
			else
				pc = code[pc]
			end
		end,
		["jmp"] = function()
			pc = pc + 1
			pc = code[pc]
			top = top - 1
		end,
	}

	while true do
		--[[
		print("INSTRUCTION: " .. code[pc])
		io.write("pc: " .. pc .. " | code: ")
		utils.pt(code)
		io.write("top: " .. top .. " | stack: ")
		utils.pt(stack)
		io.write("mem: ")
		utils.pt(mem)
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
			utils.ef "error: unknown instruction {instruction}"
		end

		debug.trace(stack, top, instruction, trace_data, flags)
		pc = pc + 1
	end
end

return {
	exec = exec
}
