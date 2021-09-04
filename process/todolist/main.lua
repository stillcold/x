local core = require "sys.core"
local mysql = require "sys.db.mysql"
local json = require "sys/json"
local gateway = require "saux.gateway"

Gac2Gas = {}
Gas2Gac = {}

require "Gac2Gas"

core.start(function()

	local id = os.time()
	local remindTime = os.time() + 1000
	local prop = {}
	prop.info = "hi"
	local propStr = json.encode(prop)

	-- db:InsertRecord(id, remindTime, propStr)
	
	require "HttpServer"
	
	gateway:startService(Gac2Gas, Gas2Gac, [==[
		message rpc {
			optional string cmd         = 1;
			optional string sign        = 2;
			optional int64 sessionId    = 3;
			optional string context     = 4;
		}
	]==])
end)


