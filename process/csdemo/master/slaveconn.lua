local core			= require "sys.core"
local server		= require "saux.server"
local rpchandledef	= require "slave2master"
local rpcsenderdef	= require "master2slave"
					  require "dispatch"

local ip = core.envget "server_ip"
local port = core.envget "server_port"

core.debug("server bind ".. ip .. ":" .. port)
local function onaccept(clientId, fd, addr)
	print("accept", clientId, fd, addr)
end

local function onclose(clientId, fd, addr, errno)
	print("connection closed", clientId, fd, addr, errno)
end

local function precheck(clientid, fd, rpcname, ...)
	return true
end

server:init(ip, port, rpchandledef, precheck, rpcsenderdef, onaccept, onclose)

return server
