#!/usr/bin/env lua5.1
local inspect = require "inspect"
print(arg[1])
local run_macro = loadfile(arg[1])

run_macro()
local f = io.open("version", "r")
version = f:read()

print(script_name)
print(script_description)
print(script_author)
print(script_version)
print(script_namespace)
print(version)
--print(inspect(_G))
