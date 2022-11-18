local inspect = require "inspect"

local noop = function() end

local function get_version_record(i)
	local f = io.open("version", "w")
	f:write(inspect(i))
	f:flush()
	f:close()
	return { requireModules = noop, registerMacro = noop, registerMacros = noop }
end

return get_version_record
