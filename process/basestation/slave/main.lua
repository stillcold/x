require "sys.tick"
require "utils.tableutils"
core 				= require "sys.core"
crypt				= require "sys.crypt"

require "sys.module"
local masterconn 	= require "masterconn"
require "reciever"
require "filesync/filesyncmgr"
local server = require "http.server"
local write = server.write

local httpDispatch = {}
httpDispatch["/"] = function(fd, request, body)
	slave2master:redirectHttpRequest(getmasterfd(), fd, request.uri, "")
	-- print("request is", request)
	-- PrintTable(request)
	-- write(fd, 200, {"Content-Type: text/plain"}, "ok")
	-- print(fd, type(fd))
end

-- Entry!
server.listen(":10002", function(fd, request, body)
     local c = httpDispatch[request.uri]
     if c then
         c(fd, request, body)
	 else
         print("Unsupport uri", request.uri)
         write(fd, 404, {"Content-Type: text/plain"}, "404 Page Not Found")
     end
end)


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
	-- slave2master:querysearchrepo_overview(getmasterfd())
end)

function master2slave:replyHttpResult(fd, httpFd, headTbl, content)
	write(httpFd, 200, headTbl, content)
end
