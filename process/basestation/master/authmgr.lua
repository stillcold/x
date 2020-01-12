local crypt 		= require "sys.crypt"

local authmgr = {
	authed_client 	= {},
}

function authmgr:is_auth_client(clientid)
	local expire = self.authed_client[clientid]
	if not expire then return false end
	return (os.time() < expire)
end

function authmgr:record_auth_client(clientid, expire)
	self.authed_client[clientid] = expire
end

function slave2master:auth(fd, cryptstr, authcode)
	local authsalt  = core.envget("auth_salt")
	local decoded	= crypt.aesdecode(authsalt, cryptstr)
	if decoded == authcode then
		core.debug(2, "auth done")
		local clientid = g_slaveconn:get_clientid_by_fd(fd)
		if not clientid then
			core.debug(1, "auth excption, no clientid found")
			return
		end
		local expire = os.time() + 10
		g_authmgr:record_auth_client(clientid, expire)
	end
end

return authmgr
