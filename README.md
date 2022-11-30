# depctrl feed maker

Makes [DependencyControl](https://github.com/TypesettingTools/DependencyControl) update feeds for [Aegisub](https://tilde.club/~garret/fansub.html#recommended-aegisub-builds) automations, so you don't have to write all that JSON by hand.

![xkcd 1319](https://imgs.xkcd.com/comics/automation.png)

## Requirements

you'll need Lua 5.1, LuaJSON, LuaFileSystem, `argparse`, Moonscript, and `sha1`.
Currently you'll also need `inspect`, because I use it for debugging, and haven't bothered to get rid of the `require` yet.

Ubuntu install commands:
```
sudo apt install lua5.1 lua-json lua-filesystem lua-argparse lua-inspect luarocks
sudo luarocks install sha1 moonscript
```
I think that might install LuaFileSystem twice. Not entirely sure, pls boop if you have better commands.

## Usage

Configuration is done via a Lua script. An example config is maintained in `conf.lua`.

To make a feed, run:

```
make-feed.lua --macros /path/to/your/macros/ --modules /path/to/your/modules/ --config /path/to/your/conf.lua --output /path/to/DependencyControl.json
```

You can omit `--macros` or `--modules` if you don't have any. You can omit both, but then you just get a feed with no scripts.

You can also omit `--output`, and the feed will output to `DependencyControl.json`. If you want to output to stdout, use `--output /dev/stdout`.

You may not omit `--config`. If you want to read it from stdin, use `--config /dev/stdin`.

`--output` and `--config` can be abbreviated to `-o` and `-c` respectively.

## A word on security

no.

Yes, this executes arbitrary code. No effort is made to prevent scripts from doing bad things.
This shouldn't be a problem, however, because it's _your_ arbitrary code. _You_ wrote it, so you should know if it does bad things.

If you make scripts that do bad things, run them, and bad things happen, the only person you have to blame is yourself.
