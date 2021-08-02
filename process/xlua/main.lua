local core = require "sys.core"
local mysql = require "sys.db.mysql"
local json = require "sys.json"
local gateway = require "gateway"
local pb = require "pb"
local protoc = require "protoc"
local socket = require "sys.socket"

protoc:load ([==[
	message rpc {
		optional string cmd			= 1;
		optional string sign		= 2;
		optional int64 sessionId	= 3;
    	optional string context     = 4;
    }
]==])


local Gac2Gas = {}
local Gas2Gac = {}
local localId = 0

local function SendRpc(fd, sessionId, cmd, context)
	
	sign = tostring(os.time())

	local data = {
		sessionId 	= sessionId,
		cmd 		= cmd,
		sign 		= sign,
		context 	= json.encode(context),-- 这里只是为了快速开发直接用了json,其实可以考虑protobuffer.
	}

	local bytes = assert(pb.encode("rpc", data))
	socket.write(fd, string.pack("<I4", #bytes)..bytes)
end

function Gac2Gas:RequestInitRecommend(fd, sessionId, context)

	local firstName = context
	local result = {
		{-360,0,firstName.."锄"},
		{-180,0,firstName.."禾"},
		{0,0,firstName.."日"},
		{180,0,firstName.."当"},
		{360,0,firstName.."午"},
	}

	SendRpc(fd, sessionId, "SyncRecommendName", result)
end

local function Dispatch(fd, str)

	local rpcInfo = pb.decode("rpc",str)
	if not rpcInfo then 
		core.log("decode rpc failed")
		return
	end
	local cmd = rpcInfo.cmd
	local rpcHandler = Gac2Gas[cmd]
	if not rpcHandler then
		core.log("rpc handler not found")
		return
	end

	local sessionId = rpcInfo.sessionId
	if not sessionId then
		localId = localId + 1
		sessionId = localId
	end

	core.log("rpc come in, cmd:", cmd, ", sessionId:", sessionId)

	rpcHandler(Gac2Gas, fd, sessionId, rpcInfo.context)
	return true
end

core.start(function()
	
	addr = core.envget("port")
	core.log("server start at:", addr)

	gateway.listen(addr, Dispatch)
	-- require "HttpServer"
end)

