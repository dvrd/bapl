local f = require "F"

local M = {}

M.tovector = function(t)
	if #t > 2 then
		error "error: only 2d vectors are allowed"
	end

	local convert = function(a)
		if type(a) == "table" then
			return a
		elseif type(a) == "number" then
			return { a, a }
		else
			error(f "error: can't make a vector out of {type(a)}")
		end
	end

	return setmetatable(t, {
		__mul = function(a, b)
			a, b = convert(a), convert(b)
			return a[1] * b[1] + a[2] * b[2]
		end,
		__add = function(a, b)
			a, b = convert(a), convert(b)
			return { a[1] + b[1], a[2] + b[2] }
		end,
		__sub = function(a, b)
			a, b = convert(a), convert(b)
			return { a[1] - b[1], a[2] - b[2] }
		end
	})
end

return M
