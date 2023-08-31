local inspect = require "inspect"
local f = require "F"

local function pt(t)
	print(inspect(t))
end

local function pf(t)
	print(f(t))
end

local function ef(t)
	error(f(t))
end

local function help(exitCode)
	io.stderr:write("Usage: " .. arg[0] .. " ")
	io.stderr:write("[--debug] ")
	io.stderr:write("[--trace] ")
	io.stderr:write("-e '<expr>' | -f 'prog.exp' | -\n")
	os.exit(exitCode)
end

local function parseArgs(args)
	local flags = {
		["debug"] = false,
		["trace"] = false,
		["filename"] = false,
	}

	local flag = nil
	for i = 1, #args do
		flag = args[i]

		if flag == "-h" or flag == "--help" then
			help(0)
		elseif flag == "-e" then
			flags["expression"] = args[i + 1]
			i = i + 1
		elseif flag:match("-e") then
			local _, _, _, expression = flag:find("(-e)(.*)")
			flags["expression"] = expression
		elseif flag == "-f" then
			flags["filename"] = args[i + 1]
			i = i + 1
		elseif flag:match("-f") then
			local _, _, _, filename = flag:find("(-f)(.*)")
			flags["filename"] = filename
		elseif flag == "-" then
		elseif flag == "--debug" then
			flags["debug"] = true
		elseif flag == "--trace" then
			flags["trace"] = true
		end
	end

	return flags
end

return {
	pt = pt,
	pf = pf,
	ef = ef,
	help = help,
	parseArgs = parseArgs,
}
