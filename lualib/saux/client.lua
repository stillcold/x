local core		= require "sys.core"
local rpc		= require "saux.rpcraw"
local rpcproto	= require "saux.xproto"
local dns		= require "sys.dns"
local serialize	= require "sys.serialize"
local rpcDef	= require "saux.rpcDef"

local client 	= {
	m_Server = nil
}

local rpcclient

-- global function like getserverfd can be define somewhere.
function client:getserverfd()
	return rpcclient.fd
end

function client:close()
	rpcclient:close()
end

function client:init(host, port, rpcHandleDef, rpcSenderDef, onClose)
	local ip 	= dns.resolve(host, "A")
	local addr	= ip..":"..port

	local rpcHandle = rpcDef:InitRpcHandle(rpcHandleDef)

	rpcclient	= rpc.createclient{
		addr	= addr,

		proto	= rpcproto,

		timeout	= 5000,

		call	= function(fd, cmd, msg)
			core.debug(0, "rpc call in", fd, cmd, msg)
			return rpcHandle["rpc"](fd, cmd, msg)
		end,

		close	= function(fd, errno)
			core.debug(1, "connection closed ", fd, errno)
			if onClose then
				core.pcall(onClose, fd, addr, errno)
			end
		end,
	}

	local bServer = false
	rpcDef:AttachRpcSender(rpcSenderDef, rpcclient, bServer)

	return rpcclient
end

function client:connect()
	local ok = rpcclient:connect()
	core.debug(1, "client connect result:", ok)
	return ok
end

return client
