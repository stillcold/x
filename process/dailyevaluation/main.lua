local core = require "sys.core"
local mysql = require "sys.db.mysql"
local json = require "sys/json"



core.start(function()

	local id = os.time()
	local remindTime = os.time() + 1000
	local prop = {}
	prop.info = "hi"
	local propStr = json.encode(prop)

	require "HttpServer"

end)



