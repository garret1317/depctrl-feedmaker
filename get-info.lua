#!/usr/bin/env lua5.1
local inspect = require "inspect"
print(arg[1])
local run_macro = loadfile(arg[1])

local conf = loadfile("conf.lua")()

run_macro()

print(script_name)
print(script_description)
print(script_author)
print(script_version)
print(script_namespace)
print(inspect(__feedmaker_version))
print(inspect(conf))
--print(inspect(_G))
