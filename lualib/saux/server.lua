local console	= require "sys.console"
local core		= require "sys.core"
local proto		= require "saux.xproto"
local rpc		= require "saux.rpc"
local rpcDef	= require "saux.rpcDef"

require "sys.serialize"

local server = {
	m_rpcserver		= nil,
	m_clientid2fd = {},
	m_clientid2addr = {},
}

local rpcserver

function server:gen_clientid()
	for i = 1, 2^32 - 1 do
		if not self.m_clientid2fd[i] then
			return i
		end
	end
	
end

-- This function is very slow, do not use it frequenly.
function server:get_clientid_by_fd(conn)
	for k,v in pairs(self.m_clientid2fd) do
		if v == conn then
			return k
		end
	end
end

function server:get_clientfd_by_id(id)
	return self.m_clientid2fd[id]
end

function server:get_clientaddr_by_id(id)
	return self.m_clientid2addr[id]
end

function server:clean_clientinfo(id)
	self.m_clientid2fd[id] = nil
	self.m_clientid2addr[id] = nil
end

--------
-- rpchandledef:
--		define info of handlers for in-direction rpc.
-- rpcprecheckfunc:
--		common check for every in-direction rpc
--		should be a function nil
--		function signature is 
--		bool fun(clientid, fd, rpcname, ...), ... represents for all args
--		
--------
function server:init(ip, port, rpcHandleDef, rpcprecheckfunc, rpcSenderDef, onaccept, onclose)

	local precheckhandle
	if rpcprecheckfunc then
		precheckhandle = function(fd, rpcname, ...)
			local clientid = self:get_clientid_by_fd(fd)
			if not clientid then
				return false, "no clientid found"
			end
			return rpcprecheckfunc(clientid, fd, rpcname, ...)
		end
	end
	local rpcHandle = rpcDef:InitRpcHandle(rpcHandleDef, precheckhandle)

	rpcserver 	= rpc.createserver{
		addr    = ip..":"..port,
		proto   = proto,
		
		accept  = function(fd, addr)
			core.log("accept", fd, addr)

			local clientId = self:gen_clientid()

			self.m_clientid2fd[clientId] = fd
			self.m_clientid2addr[clientId] = addr
			
			if onaccept then
				core.pcall(onaccept, clientId, fd, addr)
			end
		end,

		close   = function(fd, errno)
			core.log("connection closed ", fd, errno)
			
			local clientId = self:get_clientid_by_fd(fd)
			if clientId then
				local addr = self:get_clientaddr_by_id(clientId)

				if onclose then
					core.pcall(onclose, clientId, fd, addr, errno)
				end

				core.log("clean client info on close id="..clientId..
					", fd=".. fd..", addr=".. addr..", error="..errno)
				self:clean_clientinfo(clientId)
			else
				core.log("connection closed without clientId, fd="..fd..
					", errno="..errno)
			end
		end,

		call	= function(fd, cmd, msg)
			return rpcHandle["rpc"](fd, cmd, msg)
		end,
	}
	local b_server = true
	rpcDef:AttachRpcSender(rpcSenderDef, rpcserver, b_server)
	self.m_rpcserver = rpcserver
	return rpcserver
end

function server:listen()
	local ok = self.m_rpcserver:listen()
	core.log("server start result: ", ok)
	return ok
end

return server
