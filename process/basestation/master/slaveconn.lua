local core			= require "sys.core"
local server		= require "saux.server"
local rpchandledef	= require "slave2master"
local rpcsenderdef	= require "master2slave"
					  require "dispatch"

local ip = core.envget "master_listen_ip"
local port = core.envget "master_listen_port"

core.debug("server bind ".. ip .. ":" .. port)
local function onaccept(clientid, fd, addr)
	print("accept", clientid, fd, addr)
end

local function onclose(clientid, fd, addr, errno)
	print("closed", clientid, fd, addr, errno)
end

local function precheck(clientid, fd, rpcname, ...)
	print(rpcname)
	if rpcname == "auth" then return true end

	if not g_authmgr:is_auth_client(clientid) then
		core.debug(1, "client is not authed")
		return false
	end
	return true
end

server:init(ip, port, rpchandledef, precheck, rpcsenderdef, onaccept, onclose)

return server
