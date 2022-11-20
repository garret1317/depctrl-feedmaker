-- untested, may or may not work

local function ignore()
	return script_namespace == "garret.restyler"
end

local conf = {
	name = "garret's aegisub scripts",
	description =  "Little utilities for aegisub that make my life easier",
	maintainer = "garret",
	knownFeeds = {},
	url = "https://github.com/garret1317/aegisub-scripts/",
	baseUrl = "https://github.com/garret1317/aegisub-scripts/",
	fileBaseUrl = "https://raw.githubusercontent.com/garret1317/aegisub-scripts/@{channel}/@{namespace}",
	scriptUrl = "@{baseUrl}",
	fileUrl = "@{fileBaseUrl}@{fileName}",
	ignoreCondition = ignore,
	channel = "release"
}

return conf
