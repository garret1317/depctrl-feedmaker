#!/usr/bin/env lua5.1
local json = require "json"
local sha1 = require "sha1"
local lfs  = require "lfs"
local inspect = require "inspect"
--local argparse = require "argparse"

--local parser = argparse()
--local args = parser:parse()

local args = {macro_dir = "/home/g/subs/automation-scripts/macros", config = "conf.lua", output = "DependencyControl.json"}

local config = loadfile(args.config)()

local function valid_namespace(name)
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

	return name:match("^[^.][%a%d._-]*%.[%a%d._-]*[^.]$") ~= nil
	-- not 100% sure this works. it matches the examples, but idk if it matches invalid ones as well
end

local function clean_path(path, file)
	-- don't want to be pedantic about paths, but still don't want paths with // in them
	if path:sub(-1, -1) == "/" then path = path:sub(1, -2) end
	return path .. "/" .. file
end

local function join_tables(dst, src)
	for i, v in ipairs(src) do
		table.insert(dst, v)
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

local function get_files(path)
	local files = {}
	for file in lfs.dir(path) do
		local name, extension = file:match("^(.*)%.(.*)$") -- anything.anything
		local absolute = clean_path(path, file)
		if file == "." or file == ".." then -- silently skip dir and 1-level-up dir
		elseif pcall(lfs.dir, absolute) then file = join_tables(files, get_files(absolute)) -- search recursively
		elseif extension ~= "lua" then err(absolute .. ": not a lua file, skipping")
		elseif not valid_namespace(name) then err(absolute .. ": invalid namespace, skipping")
		else table.insert(files, absolute) end
	end
	return files
end

local function get_metadata(file)
	local meta = {filename = nil, name = nil, description = nil, version = nil, author = nil, namespace = nil, depctrl = nil, sha1 = nil, release = nil}
	-- having all those nils in the table doesn't really do anything in terms of functionality, but it lets me see what i need to put in it

	meta.filename = file
	meta.sha1 = sha1.sha1(readfile(file))
	meta.release = get_iso8601_date(lfs.attributes(file, "modification"))

	loadfile(file)()
	-- script_name etc are now in our global scope
	if config.ignoreCondition() then return nil end
	meta.name = script_name
	meta.description = script_description
	meta.version = script_version
	meta.author = script_author
	meta.namespace = script_namespace
	meta.depctrl = __feedmaker_version
	return meta
end

local function clean_depctrl(depctrl)
	local required = {}
	for _, mod in ipairs(depctrl) do
		if type(mod[1]) == "string" then
			mod["moduleName"] = mod[1]
			mod[1] = nil
		else
			mod[1]["moduleName"] = mod[1][1]
			mod[1][1] = nil
		end
		table.insert(required, mod)
	end
	return required
end

local function make_feed(macros)
	local feed = {
		dependencyControlFeedFormatVersion = "0.3.0",
		name = config.name,
		description = config.description,
		knownFeeds = {},
		baseUrl = config.baseUrl,
		url = config.url,
		maintainer = config.maintainer,
		fileBaseUrl = config.fileBaseUrl,
		macros = {}
	}
	for _, script in ipairs(macros) do
		local macro = {url = config.scriptUrl, author = script.author, name = script.name, description = script.description, channels = {}}
		local channel_info = {version = script.version, released = script.release, default = true, files = {}}
		channel_info.requiredModules = clean_depctrl(script.depctrl)
		channel_info.files[".lua"] = {name = ".lua", url = config.fileUrl, sha1 = script.sha1}
		macro.channels[config.channel] = channel_info
		feed.macros[script.namespace] = macro
	end
	return json.encode(feed)
end

local function main()
	local files = get_files(args.macro_dir)
	local meta = {}
	for _, file in ipairs(files) do
		table.insert(meta, get_metadata(file))
	end
	local feed = make_feed(meta)

	local out = output_writer(args.output)
	out:write(feed)
	out:close()
end

main()
