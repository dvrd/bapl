local utils = require "utils.core"

local Compiler = { code = {}, vars = {}, nvars = 0 }

function Compiler:addCode(op)
	self.code[#self.code + 1] = op
end

function Compiler:currentPosition()
	return #self.code
end

function Compiler:fixJmp2here(jmp)
	self.code[jmp] = self:currentPosition()
end

function Compiler:codeJmp(op, label)
	label = label or 0
	self:addCode(op)
	self:addCode(label)
	return self:currentPosition()
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
	elseif ast.tag == "variable" then
		self:addCode("load")
		self:addCode(self:var2num(ast.val))
	elseif ast.tag == "indexed" then
		self:codeExp(ast.array)
		self:codeExp(ast.index)
		self:addCode("getarray")
	elseif ast.tag == "new" then
		self:codeExp(ast.size)
		self:addCode("newarray")
	elseif ast.tag == "unop" then
		self:codeExp(ast.e)
		self:addCode(ast.op.tag)
	elseif ast.tag == "binop" then
		if ast.op.tag == "and" then
			self:codeExp(ast.e1)
			local jmp = self:codeJmp("jmpZP")
			self:codeExp(ast.e2)
			self:fixJmp2here(jmp)
		elseif ast.op.tag == "or" then
			self:codeExp(ast.e1)
			local jmp = self:codeJmp("jmpNZP")
			self:codeExp(ast.e2)
			self:fixJmp2here(jmp)
		else
			self:codeExp(ast.e1)
			self:codeExp(ast.e2)
			self:addCode(ast.op.tag)
		end
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

function Compiler:codeAssgn(ast)
	local lhs = ast.lhs
	if lhs.tag == "variable" then
		self:codeExp(ast.exp)
		self:addCode("store")
		self:addCode(self:var2num(lhs.val))
	elseif lhs.tag == "indexed" then
		self:codeExp(lhs.array)
		self:codeExp(lhs.index)
		self:codeExp(ast.exp)
		self:addCode("setarray")
	else
		error("unknown code assignment tag")
	end
end

function Compiler:codeStat(ast)
	if ast.tag == "assign" then
		self:codeAssgn(ast)
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
	elseif ast.tag == "if" then
		self:codeExp(ast.cond)
		local jmp = self:codeJmp("jmpZ")
		self:codeStat(ast.thn)
		if ast.els == nil then
			self:fixJmp2here(jmp)
		else
			local jmp2 = self:codeJmp("jmp")
			self:fixJmp2here(jmp)
			self:codeStat(ast.els)
			self:fixJmp2here(jmp2)
		end
	elseif ast.tag == "while" then
		local label = self:currentPosition()
		self:codeExp(ast.cond)
		local jmp = self:codeJmp("jmpZ")
		self:codeStat(ast.body)
		self:codeJmp("jmp", label)
		self:fixJmp2here(jmp)
	else
		self:codeExp(ast)
	end
end

return {
	compile = function(ast)
		--[[
		io.write("ast: ")
		utils.pt(ast)
		--]]
		Compiler:codeStat(ast)
		Compiler:addCode("push")
		Compiler:addCode(0)
		Compiler:addCode("ret")

		local result = Compiler.code
		Compiler.code = {}
		return result
	end
}
