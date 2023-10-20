local utils = require "utils.core"

local Compiler = {
	code = {},
	functions = {},
	vars = {},
	nvars = 0,
	locals = {}
}

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
	if self.functions[id] then
		print("ERROR: conflict with function name")
		os.exit(1)
	end
	local num = self.vars[id]
	if not num then
		num = self.nvars + 1
		self.nvars = num
		self.vars[id] = num
	end
	return num
end

function Compiler:codeCall(ast)
	local fn = self.functions[ast.name]
	if not fn then error("ERROR: undefined function name") end
	self:addCode("call")
	self:addCode(fn.code)
end

function Compiler:codeExpr(ast)
	if ast.tag == "number" then
		self:addCode("push")
		self:addCode(ast.val)
	elseif ast.tag == "call" then
		self:codeCall(ast)
	elseif ast.tag == "variable" then
		self:addCode("load")
		local var = self:var2num(ast.val)
		if not var then
			print("ERROR: undeclared variable " .. ast.val)
			os.exit(1)
		end
		self:addCode(var)
	elseif ast.tag == "indexed" then
		self:codeExpr(ast.array)
		self:codeExpr(ast.index)
		self:addCode("getarray")
	elseif ast.tag == "new" then
		self:codeExpr(ast.size)
		self:addCode("newarray")
		if ast.eltype ~= nil then
			self:codeExpr(ast.size)
			self:addCode("jmpZP")
			self:addCode(0)
			local l1 = self:currentPosition()
			self:addCode("2dup")
			self:codeExpr(ast.eltype)
			self:addCode("setarray")
			self:addCode("dec")
			self:addCode("jmp")
			self:addCode(l1 - self:currentPosition() - 3)
			self:fixJmp2here(l1)
			self:addCode("pop")
		end
	elseif ast.tag == "unop" then
		self:codeExpr(ast.e)
		self:addCode(ast.op.tag)
	elseif ast.tag == "binop" then
		if ast.op.tag == "and" then
			self:codeExpr(ast.e1)
			local jmp = self:codeJmp("jmpZP")
			self:codeExpr(ast.e2)
			self:fixJmp2here(jmp)
		elseif ast.op.tag == "or" then
			self:codeExpr(ast.e1)
			local jmp = self:codeJmp("jmpNZP")
			self:codeExpr(ast.e2)
			self:fixJmp2here(jmp)
		else
			self:codeExpr(ast.e1)
			self:codeExpr(ast.e2)
			self:addCode(ast.op.tag)
		end
	else
		if type(ast) == "table" then
			io.write("ERROR: invalid expression -> ")
			utils.pt(ast)
			os.exit(1)
		else
			print("ERROR: invalid expression -> " .. ast)
			os.exit(1)
		end
	end
end

function Compiler:codeAssgn(ast)
	local lhs = ast.lhs
	if lhs.tag == "variable" then
		self:codeExpr(ast.exp)
		self:addCode("store")
		self:addCode(self:var2num(lhs.val))
	elseif lhs.tag == "indexed" then
		self:codeExpr(lhs.array)
		self:codeExpr(lhs.index)
		self:codeExpr(ast.exp)
		self:addCode("setarray")
	else
		print("ERROR: unknown code assignment tag")
		os.exit(1)
	end
end

function Compiler:codeBlock(ast)
	self:codeStat(ast.body)
end

function Compiler:codeStat(ast)
	if ast.tag == "assign" then
		self:codeAssgn(ast)
	elseif ast.tag == "local" then
		self:codeExpr(ast.init)
		self.locals[#(self.locals) + 1] = ast.name
	elseif ast.tag == "call" then
		self:codeCall(ast)
		self:addCode("pop")
		self:addCode(1)
	elseif ast.tag == "sequence" then
		self:codeStat(ast.st1)
		self:codeStat(ast.st2)
	elseif ast.tag == "block" then
		self:codeBlock(ast)
	elseif ast.tag == "print" then
		self:codeExpr(ast.exp)
		self:addCode("print")
	elseif ast.tag == "ret" then
		self:codeExpr(ast.exp)
		self:addCode("ret")
		self:addCode(#self.locals)
	elseif ast.tag == "if" then
		self:codeExpr(ast.cond)
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
		self:codeExpr(ast.cond)
		local jmp = self:codeJmp("jmpZ")
		self:codeStat(ast.body)
		self:codeJmp("jmp", label)
		self:fixJmp2here(jmp)
	elseif ast.tag == "function" then
		self:codeFunction(ast)
	else
		self:codeExpr(ast)
	end
end

function Compiler:codeFunction(ast)
	local code = {}
	if self.functions[ast.name] then
		print("ERROR: duplicate function name")
		os.exit(1)
	end
	self.functions[ast.name] = {
		code = code
	}
	self.code = code
	self:codeStat(ast.body)
	self:addCode("push")
	self:addCode(0)
	self:addCode("ret")
	self:addCode(#self.locals)
end

return {
	compile = function(ast)
		---[[
		io.write("ast: ")
		utils.pt(ast)
		--]]
		for i = 1, #ast do
			if ast.tag == "function" then
				Compiler:codeFunction(ast[i])
			else
				Compiler:codeStat(ast[i])
				Compiler:addCode("push")
				Compiler:addCode(0)
				Compiler:addCode("ret")
			end
		end

		local main = Compiler.functions["main"]

		if not main then
			return Compiler.code
		end

		return main.code
	end
}
