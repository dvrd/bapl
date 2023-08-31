local i = require "week-2.interpreter"
local utils = require "utils.core"

local flags = utils.parseArgs(arg)

local function exec(input)
	local ast = i.parse(input)

	if ast ~= nil then
		local code = i.compile(ast)
		local result = i.run(code, {}, flags)
		print(result[1])
	else
		utils.pf "error: dont know how to parse that yet buddy"
	end
end

local input = ""
if flags["expression"] then
	input = flags["expression"]
	exec(input)
elseif flags["filename"] then
	local f = io.open(flags["filename"], "r")
	if f then
		input = f:read("*all")
		f:close()
		exec(input)
	end
else
	while true do
		io.write(">> ")
		input = io.read()

		if input == "q" then
			os.exit()
		elseif input == "clear" then
			os.execute("clear")
		else
			exec(input)
		end
	end
end
