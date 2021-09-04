local core = require "sys.core"
local mysql = require "sys.db.mysql"
local json = require "sys.json"
local gateway = require "saux.gac2gasgatewayproxy"
local pb = require "pb"
local protoc = require "protoc"
local socket = require "sys.socket"
local db = require "DbMgr"
local dateUtil = require "utils/dateutil"
require "utils.tableutils"

--[[ 
protoc:load ([==[
	message rpc {
		optional string cmd			= 1;
		optional string sign		= 2;
		optional int64 sessionId	= 3;
    	optional string context     = 4;
    }
]==])
--]]

local function SendRpc(fd, cmd, context)

	if not context then
		core.log("no content to send")
		return
	end

	if type(context) ~= "table" then
		core.log("invalid context type")
		return
	end

	sign = tostring(os.time())

	local data = {
		cmd 		= cmd,
		sign 		= sign,
		context 	= json.encode(context),-- 这里只是为了快速开发直接用了json,其实可以考虑protobuffer.
	}

	local bytes = assert(pb.encode("rpc", data))
	print("Send rpc, data len", #bytes)
	socket.write(fd, string.pack("<I4", #bytes)..bytes)
end

local gas2gac_mt = {
	__index = function(table, key)
		local doSend = function(table, fd, context)
			print("send rpc ", key, table)
			SendRpc(fd, key, context)
		end
		return doSend
	end
}

local gac2gas
local gas2gac

local fd2sessionId = {}
local localId = 0

local function Dispatch(fd, str)

	local rpcInfo = pb.decode("rpc",str)
	if not rpcInfo then 
		core.log("decode rpc failed")
		return
	end
	local cmd = rpcInfo.cmd
	local rpcHandler = gac2gas[cmd]
	if not rpcHandler then
		core.log("rpc handler not found")
		return
	end

	core.log("rpc come in, cmd:", cmd)

	local requestArgs = json.decode(rpcInfo.context)
	if not requestArgs then
		core.log("rpc come in, invalid context, cmd:", cmd)
		return
	end

	rpcHandler(gac2gas, fd, requestArgs)

	core.log("handle rpc sucessfully. cmd:", cmd)
	return true
end

local tbl = {}

function tbl:startService(Gac2Gas, Gas2Gac, protocal)
	protoc:load(protocal)

	gac2gas = Gac2Gas
	gas2gac = Gas2Gac
	
	setmetatable(Gas2Gac, gas2gac_mt)
	
	local addr = core.envget("port")
	core.log("gac2gas service start at:", addr)
	gateway.listen(addr, Dispatch)
end

return tbl

