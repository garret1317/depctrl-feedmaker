local function macro_ignore()
	return script_namespace == "garret.restyler" -- exclude a specific script
end

local function module_ignore()
end

-- most values mean the same thing as they would be in a DependencyControl feed, so will not be explained.
-- DepCtrl docs (an oxymoron if i've ever heard one): https://github.com/TypesettingTools/DependencyControl/blob/master/README.md

local conf = {
	name = "garret's aegisub scripts",
	description = "Little utilities for aegisub that make my life easier",
	maintainer = "garret",
	knownFeeds = {arch1 = "https://raw.githubusercontent.com/arch1t3cht/Aegisub-Scripts/main/DependencyControl.json"},
	-- hash table of feeds you want to reference, but are not necessarily required by one of your scripts.
	baseUrl = "https://github.com/garret1317/aegisub-scripts/",
	url = "@{baseUrl}",
	scriptUrl = "@{baseUrl}#@{namespace}", -- the url for details about a script
	fileBaseUrl = "https://raw.githubusercontent.com/garret1317/aegisub-scripts/master",

	macros = {
		-- contains values referenced by feedmaker when processing macros.
		fileBaseUrl = "@{fileBaseUrl}/macros/@{namespace}",
		-- macro-specific fileBaseUrl, so you can store macros and modules differently
		ignoreCondition = macro_ignore,
		-- feedmaker ignores a macro if it matches the specified condition - that is, if the supplied function returns true.
		-- ignoreConditions are given access to feedmaker's global scope, which in turn also contains the global scope
		-- of the macro it's processing, so checks with stuff like script_namespace just work™
	},
	modules = {
		-- the same as the macros table, but for modules.
		fileBaseUrl = "@{fileBaseUrl}/modules/@{namespacePath}",
		ignoreCondition = module_ignore,
		-- module details can be accessed from the `depctrl` table,
		-- which contains the DependencyControl version record the module defines
	},
	fileUrl = "@{fileBaseUrl}@{fileName}", -- used as the `url` value in the files section of a macro/module. Where the actual file is.
	channel = "master" -- the default (and only) channel defined in the files section. It doesn't really matter what you put here.
}

return conf -- actually provide the config table to feedmaker
