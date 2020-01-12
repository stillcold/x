local core = require "sys.core"
local patch = require "sys.patch"
local console = require "sys.console"
local proto = require "rpcproto"
local rpc = require "saux.rpc"
local DO = require "rpcl"

local server = rpc.createserver {
	addr = core.envget "rpcd_port",
	-- addr = "127.0.0.1:9002",
	proto = proto,
	accept = function(fd, addr)
		print("accept", addr)
		core.log("accept", fd, addr)
	end,
	close = function(fd, errno)
		core.log("close", fd, errno)
	end,
	call = function(fd, cmd, msg)
		return assert(DO[cmd])(fd, cmd, msg)
	end,
}

local ok = server:listen()
core.log("rpc server start:", ok)

addr = core.envget ("rpcd_port")
print("addr", addr)

console {
	addr = ":2323"
}

