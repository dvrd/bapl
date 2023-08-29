local f = require "F"
local i = require "week-2.interpreter"

while true do
	io.write(">> ")
	local input = io.read()
	if input == "q" then
		os.exit()
	end
	local ast = i.parse(input)
	if ast ~= nil then
		local code = i.compile(ast)
		local result = i.run(code, {})
		print(result[1])
	else
		print(f "error: dont know how to parse that yet buddy")
	end
end
