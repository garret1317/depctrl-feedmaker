local function macro_ignore()
	return script_namespace == "garret.restyler"
end

local function module_ignore()
end

local conf = {
	name = "garret's aegisub scripts",
	description =  "Little utilities for aegisub that make my life easier",
	maintainer = "garret",
	knownFeeds = {},
	url = "https://github.com/garret1317/aegisub-scripts/",
	baseUrl = "https://raw.githubusercontent.com/garret1317/aegisub-scripts/master",
	scriptUrl = "@{baseUrl}#@{namespace}",
	macros = {
		fileBaseUrl = "@{baseUrl}/macros/@{namespace}",
		ignoreCondition = macro_ignore,
	},
	modules = {
		fileBaseUrl = "@{baseUrl}/modules/@{namespacePath}",
		ignoreCondition = module_ignore,
	},
	fileUrl = "@{fileBaseUrl}@{fileName}",
	channel = "master"
}

return conf
