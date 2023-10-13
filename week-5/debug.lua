local M = {}

M.trace = function(stack, top, op, val, flags)
	if flags and flags["trace"] then
		io.stderr:write("[TRACE]\t")

		if val then
			io.stderr:write(op .. " " .. val .. " --> stack [")
		else
			io.stderr:write(op .. " --> stack ")
		end

		if #stack > 0 then M.dumpStack(stack, top) end

		if val then io.stderr:write("]") end
		io.stderr:write("\n")
	end
end

M.dumpStack = function(stack, top)
	for i = 1, top do
		io.stderr:write(stack[i])

		if i ~= top then
			io.stderr:write(", ")
		end
	end
end

M.findPrevStmt = function(input, pos)
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

M.syntaxError = function(input)
	local high = MAXMATCH + 20 > #input and 0 or MAXMATCH + 20
	local prev = M.findPrevStmt(input, MAXMATCH)
	local low = prev > 0 and prev or 0

	io.stderr:write("SYNTAX ERROR at position ", MAXMATCH, " of ", #input, "\n")
	io.stderr:write("on line ", LAST_LINE, ": ")

	io.stderr:write(string.sub(input, low, MAXMATCH - 3))                                  -- Pre-error

	io.stderr:write("\27[1;4;31m", string.sub(input, MAXMATCH - 2, MAXMATCH + 2), "\27[0m") -- Error highlighting

	io.stderr:write(string.sub(input, MAXMATCH + 3, high), "\n")                           -- Post-error
end

return M
