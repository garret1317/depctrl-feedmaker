#!/usr/bin/env lua5.1
local json = require "json"
local sha1 = require "sha1"
local lfs  = require "lfs"
local inspect = require "inspect"
local argparse = require "argparse"
local moonscript = require "moonscript.base"

local parser = argparse() {description = "experimental DependencyControl feed generator"}
parser:option("--macros", "Macro Directory")
parser:option("--modules", "Module Directory")
parser:option("-o --output", "Output File", "DependencyControl.json")
parser:option("-c --config", "Feed Configuration file")
local args = parser:parse()

local config = loadfile(args.config)()

local function valid_namespace(str)
--[[ #### Rules for a valid namespace: ####

 1. contains _at least_ one dot
 2. must **not** start or end with a dot
 3. must **not** contain series of two or more dots
 4. the character set is restricted to: `A-Z`, `a-z`, `0-9`, `.`, `_`, `-`

__Examples__:
 * l0.ASSFoundation
 * l0.ASSFoundation.Common (for a separately version-controlled 'submodule')
 * l0.ASSWipe
 * a-mo.LineCollection
 ]]

-- written by chatgpt lol

	-- Check if the string contains at least one dot
	if not string.find(str, '%.') then
		return false
	end

	-- Check if the string starts or ends with a dot
	if string.sub(str, 1, 1) == '.' or string.sub(str, -1) == '.' then
		return false
	end

	-- Check if the string contains a series of two or more dots
	if string.find(str, '%.%.') then
		return false
	end

	-- Check if the string contains invalid characters
	if string.find(str, '[^%w%.%-_]') then
		return false
	end

	-- If all checks pass, the string is valid
	return true
end

local function clean_path(path, file)
	-- don't want to be pedantic about paths, but still don't want paths with // in them
	if path:sub(-1, -1) == "/" then path = path:sub(1, -2) end
	return path .. "/" .. file
end

local function join_itables(dst, src)
	if dst == nil then return src end
	if src == nil then return dst end
	for _, v in ipairs(src) do
		table.insert(dst, v)
	end
	return dst
end

local function join_ktables(dst, src)
	if dst == nil then return src end
	if src == nil then return dst end
	for k, v in pairs(src) do
		dst[k] = v
	end
	return dst
end

local function readfile(filename)
	local f = io.open(filename)
	local txt = f:read("*all")
	f:close()
	return txt
end

local function get_iso8601_date(time)
	return os.date("%Y-%m-%d", time)
end

local function output_writer(file)
	local is_file, f = pcall(io.open, file, "w")
	if is_file then return f end
	return io.stdout
end

local function err(msg)
	if type(msg) == "table" then msg = inspect(msg) end
	io.stderr:write(msg.."\n")
end

local function split_filename(file)
	local name, extension = file:match("^(.*)%.(.*)$") -- anything.anything
	return name, extension
end

local function get_files(path, are_macros)
	local files = {}
	for file in lfs.dir(path) do
		local name, extension = split_filename(file)
		local absolute = clean_path(path, file)
		if file == "." or file == ".." then -- silently skip dir and 1-level-up dir
		elseif pcall(lfs.dir, absolute) then file = join_itables(files, get_files(absolute)) -- search recursively
		elseif extension ~= "lua" and extension ~= "moon" then err(absolute .. ": not a lua or moonscript file, skipping")
		elseif ((not valid_namespace(name)) and are_macros) then err(absolute .. ": invalid namespace, skipping")
		else table.insert(files, absolute) end
	end
	return files
end

local function get_file_metadata(file)
	local hash = sha1.sha1(readfile(file))
	local lastmodified = get_iso8601_date(lfs.attributes(file, "modification"))
	return hash, lastmodified
end

local function deepcopy(orig, copies) -- copied and pasted from https://lua-users.org/wiki/CopyTable
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
			end
			setmetatable(copy, deepcopy(getmetatable(orig), copies))
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

-- fake libraries so scripts don't throw a fit about not having stuff

local noop = function() end
local return_input = function(i) return i end

local function fake_depctrl(i)
	__feedmaker_version = i
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

local function fake_aegisub()
	local aegisub = {}

	aegisub.register_macro = noop
	aegisub.register_filter = noop

	aegisub.progress = {}
	aegisub.progress.set = noop
	aegisub.progress.task = noop
	aegisub.progress.title = noop
	aegisub.progress.is_cancelled = noop

	aegisub.debug = {}

	aegisub.debug.out = noop
	aegisub.log = noop

	aegisub.dialog = {}

	aegisub.dialog.display = noop
	aegisub.dialog.open = noop
	aegisub.dialog.save = noop

	aegisub.cancel = noop
	aegisub.text_extents = noop
	aegisub.gettext = return_input

	aegisub.frame_from_ms = noop
	aegisub.ms_from_frame = noop
	aegisub.video_size = noop
	aegisub.keyframes = noop
	aegisub.decode_path = noop
	aegisub.project_properties = noop

	return aegisub
end

local function sandbox_require(obj)
	if obj == "l0.DependencyControl" then
		return fake_depctrl
	else
		local got, lib = pcall(require, obj)
		if got then
			return lib
		else
			err("tried to require " .. obj .. " but couldn't. skipping and hoping it won't matter.")
			return {} --Some default value, hopefully it should be fine with it
		end
	end
end

local function run_file(file, extension)
	local runner
	local env = {
	_VERSION = _VERSION,
	assert = assert,
	collectgarbage = collectgarbage,
	dofile = dofile,
	error = error,
	getfenv = getfenv,
	getmetatable = getmetatable,
	ipairs = ipairs,
	load = load,
	loadfile = loadfile,
	loadstring = loadstring,
	module = module,
	next = next,
	pairs = pairs,
	pcall = pcall,
	print = print,
	rawequal = rawequal,
	rawget = rawget,
	rawset = rawset,
	select = select,
	setfenv = setfenv,
	setmetatable = setmetatable,
	tonumber = tonumber,
	tostring = tostring,
	type = type,
	unpack = unpack,
	xpcall = xpcall,
	coroutine = coroutine,
	debug = debug,
	file = file,
	io = io,
	math = math,
	os = os,
	package = {},
	string = string,
	table = table,
	
	require = sandbox_require,
	aegisub = fake_aegisub(),
	}

	if extension == "moon" then
		runner = moonscript.loadfile(file)
	else
		runner = loadfile(file)
	end
	if runner == nil then err(file .. " didn't load!") return nil end

	setfenv(runner, env)

	local worked, out = pcall(runner)
	if not worked then err("error when executing "..file..": ".. out) return nil end
	return env
end

local function get_macro_metadata(file)
	local meta = {file = file, name = nil, description = nil, version = nil, author = nil, namespace = nil, depctrl = nil, sha1 = nil, release = nil}
	-- having all those nils in the table doesn't really do anything in terms of functionality, but it lets me see what i need to put in it
	meta.sha1, meta.release = get_file_metadata(file)
	meta.basename, meta.extension = split_filename(file)

	__feedmaker_version = nil

	function include() end -- so it doesnt die with karaskel imports and such

	local macro = run_file(file, meta.extension)
	if macro == nil then return nil end

	meta.name = macro.script_name
	meta.description = macro.script_description
	meta.version = macro.script_version
	meta.author = macro.script_author
	meta.namespace = macro.script_namespace
	meta.changelog = macro.script_changelog
	meta.depctrl = __feedmaker_version

	if not meta.namespace then
		err(file .. ": no script_namespace, skipping")
		return nil
	end

	if config.macros.ignoreCondition(meta) then
		err(file .. ": ignored by config, skipping")
		return nil
	end
	return meta
end

local function get_module_metadata(file)

	local meta = {file = file, name = nil, description = nil, version = nil, author = nil, namespace = nil, depctrl = nil, sha1 = nil, release = nil}

	meta.sha1, meta.release = get_file_metadata(file)
	meta.basename, meta.extension = split_filename(file)

	local mod = run_file(file, meta.extension)
	if mod == nil then return nil end

	local depctrl = __feedmaker_version
	meta.name = depctrl.name
	meta.version = depctrl.version
	meta.author = depctrl.author
	meta.namespace = depctrl.moduleName
	meta.depctrl = depctrl[1]
	
	if config.modules.ignoreCondition(meta) then
		err(file .. ": ignored by config, skipping")
		return nil
	end
	
	return meta
end

local function clean_depctrl(depctrl)
	local required = {}
	local feeds = {}
	if depctrl == nil or #depctrl == 0 then return nil end
	for _, mod in ipairs(depctrl) do
		if type(mod) == "string" then mod = {mod} end
		if type(mod[1]) ~= "string" then mod = mod[1] end
		local modname = mod[1]
		mod["moduleName"] = modname
		mod[1] = nil
		table.insert(required, mod)
		feeds[modname] = mod["feed"]
	end
	return required, feeds
end

local function get_feed_entry(script, fileBaseUrl)
	local macro = {url = config.scriptUrl, author = script.author, name = script.name, description = script.description, changelog = script.changelog, channels = {}}
	local channel_info = {version = script.version, released = script.release, default = true, files = {}}
	local requiredModules, feeds = clean_depctrl(script.depctrl)

	macro.fileBaseUrl = fileBaseUrl -- let it be known that i'm not happy about this and i want it gone
	-- but depctrl doesn't comply with its own damn spec

	channel_info.requiredModules = requiredModules
	table.insert(channel_info.files, {name = "." .. script.extension, url = config.fileUrl, sha1 = script.sha1})
	macro.channels[config.channel] = channel_info
	return macro, feeds
end
local function make_feed(meta)
	local feed = {
		dependencyControlFeedFormatVersion = "0.3.0",
		name = config.name,
		description = config.description,
		knownFeeds = config.knownFeeds,
		baseUrl = config.baseUrl,
		url = config.url,
		maintainer = config.maintainer,
		fileBaseUrl = config.fileBaseUrl,
--		macros = {},
--		modules = {}
	}
	if next(meta.macros) then
		config.macros.ignoreCondition = nil
		feed.macros = feed.macros or {}
		for _, script in ipairs(meta.macros) do
			local macro, feeds = get_feed_entry(script, config.macros.fileBaseUrl)
			feed.knownFeeds = join_ktables(feed.knownFeeds, feeds)
			feed.macros[script.namespace] = macro
		end
	end

	if next(meta.modules) then
		config.modules.ignoreCondition = nil
		feed.modules = feed.modules or {}
		for _, script in ipairs(meta.modules) do
			local mod, feeds = get_feed_entry(script, config.modules.fileBaseUrl)
			feed.knownFeeds = join_ktables(feed.knownFeeds, feeds)
			feed.modules[script.namespace] = mod
		end
	end

	return json.encode(feed)
end

local function main()
	local meta = {macros = {}, modules = {}}
	if args.macros then
		local macro_files = get_files(args.macros, true)
		for _, file in ipairs(macro_files) do
			table.insert(meta.macros, get_macro_metadata(file))
		end
	end
	if args.modules then
		local module_files = get_files(args.modules)
		for _, file in ipairs(module_files) do
			table.insert(meta.modules, get_module_metadata(file))
		end
	end
	local feed = make_feed(meta)

	local out = output_writer(args.output)
	out:write(feed)
	out:close()
end

main()
