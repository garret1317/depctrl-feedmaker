local inspect = require "inspect"

local noop = function() end

local function get_version_record(i)
	local f = io.open("version", "w")
	f:write(inspect(i))
	f:flush()
	f:close()
	return {
		checkVersion = noop,
		getConfigFileName = noop,
		getConfigHandler = noop,
		getLogger = noop,
		getVersionNumber = noop,
		getVersionString = noop,
		loadConfig = noop,
		loadModule = noop,
		moveFile = noop,
		register = noop,
		registerMacro = noop,
		registerMacros = noop,
		registerTests = noop,
		requireModules = noop,
		writeConfig = noop,
		getUpdaterErrorMsg = noop,
		getUpdaterLock = noop,
		releaseUpdaterLock = noop,
		update = noop,
	}
end

return get_version_record
