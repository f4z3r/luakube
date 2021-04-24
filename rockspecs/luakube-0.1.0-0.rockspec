package = "luakube"
version = "0.1.0-0"

source = {
	-- url = "http://luaforge.net/frs/download.php/3637/luajson-0.10.tar.bz2",
	-- md5 = "0b6fa5e3a07daabe79241922b0bfda92"
}

description = {
	summary = "Kubernetes API library for Lua",
	-- detailed = [[
	--   LuaJSON is a customizable JSON decoder/encoder using
	--   LPEG for parsing.
	-- ]],
	homepage = "https://github.com/jakobbeckmann/luakube",
	maintainer = "Jakob Beckmann <beckmann_jakob@hotmail.fr>",
	license = "MIT"
}

dependencies = {
	"lua >= 5.3",
	"lyaml >= 6.2",
	"luajson >= 1.3",
}

build = {
	type = "module",
	modules = {
		kube = "src/kube.lua",
		-- ["json.util"] = "src/json/util.lua",
		-- ["json.encode.strings"] = "src/json/encode/strings.lua"
	}
}
