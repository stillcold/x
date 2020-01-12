require "sys.tick"
require "utils.tableutils"
core 				= require "sys.core"
local crypt			= require "sys.crypt"
local masterconn 	= require "masterconn"

require "reciever"

function getmasterfd()
	return masterconn:getserverfd()
end


core.start(function()
	local loglevel 	= tonumber(core.envget("log_level"))
	local logdefault= tonumber(core.envget("log_default"))
	core.debug(1, "set debug level to ".. loglevel ..", log default flag:"..logdefault)
	core.debuglevel(loglevel, logdefault)
	if not masterconn:connect() then
		core.exit()
		return
	end

	local authsalt 	= core.envget("auth_salt")
	local authcode	= core.envget("auth_code")
	local cryptstr 	= crypt.aesencode(authsalt, authcode)
	slave2master:auth(getmasterfd(), cryptstr, authcode)
end)

