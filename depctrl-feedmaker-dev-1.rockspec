package = "depctrl-feedmaker"
version = "dev-1"
source = {
   url = "git+https://git.427738.xyz/depctrl-feedmaker"
}
description = {
   summary = "Makes DependencyControl update feeds for Aegisub automations, so you don't have to write all that JSON by hand.",
   homepage = "https://git.427738.xyz/depctrl-feedmaker/about/",
   license = "BSD-2-Clause"
}
dependencies = {
   "lua ~> 5.1",
   "luajson",
   "sha1",
   "luafilesystem",
   "argparse",
   "moonscript",
   "inspect" -- not actually used
}
build = {
   type = "none",
   install = {
      bin = {"make-feed.lua"}
   }
}
