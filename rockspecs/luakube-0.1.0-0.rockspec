package = "luakube"
version = "0.1.0-0"

source = {
	-- url = "http://luaforge.net/frs/download.php/3637/luajson-0.10.tar.bz2",
	-- md5 = "0b6fa5e3a07daabe79241922b0bfda92"
}

description = {
	summary = "Kubernetes API library for Lua",
	detailed = [[
		LuaKube is a simple client library to access the Kubernetes
		API. It does not abstract much from the API, allowing for full
		control, but provides some convenience functions for quick
		scripting.
	]],
	homepage = "https://github.com/jakobbeckmann/luakube",
	maintainer = "Jakob Beckmann <beckmann_jakob@hotmail.fr>",
	license = "MIT"
}

dependencies = {
	"lua == 5.3",
	"lyaml >= 6.2",
	"luajson >= 1.3",
	"luasocket >= 3.0",
	"luasec >= 1.0",
	"base64 >= 1.5",
	"fun >= 0.1",
}

build = {
	type = "module",
	modules = {
		kube = "src/kube.lua",
		["kube.config"] = "src/kube/config.lua",
	}
}
