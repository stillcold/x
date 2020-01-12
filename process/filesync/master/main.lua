require "SAConfig"

local console 	= require "sys.console"
local core 		= require "sys.core"
local proto = require "rpcproto"
local rpc 		= require "saux.rpc"

require "sys.serialize"
require "Slave2Master"

g_RpcServer = nil
g_Name2Fd = {}

print(proto)
local handle = {}
for funcName,func in pairs(Slave2Master) do
	print(funcName, proto:tag(funcName))
	handle[proto:tag(funcName)] = func
end

print(lfs.currentdir())

g_RpcServer = rpc.createserver {
	addr = core.envget "service_addr",
	-- addr = "127.0.0.1:9002",
	proto = proto,
	accept = function(fd, addr)
		print("accept", addr)
		core.log("accept", fd, addr)

		g_RpcServer:call(fd, "rrpc_name", {val = 1, suffix = "ask"})
	end,
	close = function(fd, errno)
		core.log("close", fd, errno)
		for k,v in pairs(g_Name2Fd) do
			if v == fd then
				-- this is not a good way, but, whatever.
				g_Name2Fd[k] = nil
				core.log("name released.")
				print("name released", k)
			end
		end
	end,
	call = function(fd, cmd, msg)
		print("call in", cmd, msg)
		return handle[cmd](Slave2Master, fd, msg)
		-- return assert(Slave2Master[cmd])(fd, cmd, msg)
	end,
}

local ok = g_RpcServer:listen()
core.log("rpc server start:", ok)

addr = core.envget ("service_addr")
print("addr", addr)

console {
	addr =  ":"..core.envget("admin_port")
}
