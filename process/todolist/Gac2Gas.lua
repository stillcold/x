local core = require "sys.core"
local mysql = require "sys.db.mysql"
local json = require "sys.json"
local gateway = require "saux.gateway"
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

local fd2sessionId = {}
local Gac2Gas = {}
local Gas2Gac = {}
local localId = 0

local function SendRpc(fd, cmd, context)

	if not context then return end
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
	socket.write(fd, string.pack("<I4", #bytes)..bytes)
end

function Gac2Gas:RequestAuth(fd, args)

	-- PrintTable(args)

	local userId = 0
	if requestInfo and args.userId and args.userId ~= 0 then
		userId = args.userId
	else
		localId = localId + 1
		userId = localId
	end

	print("request auth, userId is", userId)

	local authInfo = {
		userId		= userId,
		initTime 	= os.time(),
		token 		= "8e32af9d03",
	}
	SendRpc(fd, "RequestAuthDone", authInfo)	
end

function Gac2Gas:RequestInitRecommend(fd, context)

	local firstName = context.input
	if #firstName <= 0 then
		firstName = "赵"
	end

	local result = {
		{-360,0,firstName.."锄"},
		{-180,0,firstName.."禾"},
		{0,0,firstName.."日"},
		{180,0,firstName.."当"},
		{360,0,firstName.."午"},
	}

	SendRpc(fd, "SyncRecommendName", result)
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

	core.log("rpc come in, cmd:", cmd)

	local requestArgs = json.decode(rpcInfo.context)
	if not requestArgs then
		core.log("rpc come in, invalid context, cmd:", cmd)
		return
	end

	rpcHandler(Gac2Gas, fd, requestArgs)

	core.log("handle rpc sucessfully. cmd:", cmd)
	return true
end
	
local function run()

	local addr = core.envget("port")
	core.log("gac2gas service start at:", addr)
	gateway.listen(addr, Dispatch)
end

run()

