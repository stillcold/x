require "utils.tableutils"
require "sys.tick"
local console 		= require "sys.console"
core				= require "sys.core"

local slaveconn		= require "slaveconn"

console {
	addr =  ":"..core.envget("admin_port")
}
core.start(function()
	core.debuglevel(1, -1)
	-- core.debuglevel(1)
	core.debug(0, "check debug out")
	core.debug(1, "debug level 1")
	core.debug(2, "debug level 2")
	core.debug("default debug")
	slaveconn:listen()

	registertick(function()
		local conn = slaveconn:get_clientfd_by_id(1)
		if conn then
			master2slave:test(conn, {testmaster2slave = "hahaha"})
		end
	end, 5 * 1000)
end)

