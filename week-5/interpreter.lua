local inspect = require "inspect"
local utils = require "utils.core"
local grammar = require "week-5.grammar"
local debug = require "week-5.debug"
local compiler = require "week-5.compiler"
local vm = require "week-5.vm"

local M = {
	inspect = inspect
}

M.parse = function(input)
	local ret = grammar:match(input)
	if not ret then
		debug.syntaxError(input)
	end
	return ret
end

return M
