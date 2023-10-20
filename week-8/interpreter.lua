local inspect = require "inspect"
local utils = require "utils.core"
local grammar = require "week-8.grammar"
local debug = require "week-8.debug"
local compiler = require "week-8.compiler"
local vm = require "week-8.vm"

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
