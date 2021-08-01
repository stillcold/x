local core = require "sys.core"
local mysql = require "sys.db.mysql"
local json = require "sys/json"
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

local localId = 0
local fd2sessionId = {}

local function SendRpc(fd, sessionId, cmd, context)
	
	sign = os.time()

	local data = {
		sessionId 	= sessionId,
		cmd 		= cmd,
		sign 		= sign,
		context 	= json.encode(context),
	}

	local bytes = assert(pb.encode("rpc", data))
	socket.write(fd, string.pack("<I4", #bytes)..bytes)
end

local function Dispatch(fd, sessionId, sign, cmd, context)

	fd2SessionId[fd] = fd2SessionId[fd] or (localId + 1)

	local sessionId = fd2SessionId[fd]

	firstName =  context.firstName or ""

	local result = {
		{-360,0,firstName.."锄"},
		{-180,0,firstName.."禾"},
		{0,0,firstName.."日"},
		{180,0,firstName.."当"},
		{360,0,firstName.."午"},
	}

	SendRpc(fd, sessionId, "SyncRecommendName", result)

	return true
end

core.start(function()
	
	addr = core.envget("port")
	core.log("server start at:", addr)

	gateway.listen(addr, Dispatch)
	-- require "HttpServer"
end)




