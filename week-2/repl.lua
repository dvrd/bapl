local f = require "F"
local i = require "week-2.interpreter"

local function exec(input)
	local ast = i.parse(input)

	if ast ~= nil then
		local code = i.compile(ast)
		local result = i.run(code, {})
		print(result[1])
	else
		print(f "error: dont know how to parse that yet buddy")
	end
end

while true do
	io.write(">> ")
	local input = io.read()

	if input == "q" then
		os.exit()
	elseif input == "clear" then
		os.execute("clear")
	else
		exec(input)
	end
end
