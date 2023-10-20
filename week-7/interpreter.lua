local inspect = require "inspect"
local utils = require "utils.core"
local grammar = require "week-7.grammar"
local debug = require "week-7.debug"
local compiler = require "week-7.compiler"
local vm = require "week-7.vm"

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
