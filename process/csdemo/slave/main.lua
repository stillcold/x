require "sys.tick"
require "utils.tableutils"
core 				= require "sys.core"
local masterconn 	= require "masterconn"
require "reciever"

function getmasterfd()
	-- This result maybe nil!!
	return masterconn:getserverfd()
end


core.start(function()
	if not masterconn:connect() then
		core.debug(1, "connect server fail, app will quit")
		core.exit()
		return
	end

	core.debuglevel(1, -1)

	registertickwithcount(function()
		core.debug(1, "master conn is", getmasterfd())
		slave2master:test(getmasterfd(), 100, "send to server", {hello = "world"})
	end, 3 * 1000, 2)

	local count = 0
	registertick(function()
		if not getmasterfd() then
			core.debug(1, "master connection has lost, app will quilt")
			core.exit()
			return
		end
		count = count + 1
		core.debug(1, "tick count", count)
		if count >= 10 then
			masterconn:close()
		end
	end, 1*1000)
end)

