function slave2master:querysearchrepo_overview(conn)
	local tosyncdata = g_filesyncmgr:get_searchrepo_overview()
	master2slave:syncsearchrepo_overview(conn, tosyncdata)
end

function slave2master:requestdownloadfile(fd, filename)
	local filecontent = g_filesyncmgr:getfilecontent(filename)
	if not filecontent then return end
	master2slave:syncfilecontent(fd, filename, filecontent)
	core.debug(1, "server sync "..filename)
end

function slave2master:requestuploadfile(fd, filename, filecontent)
	g_filesyncmgr:writedownfilecontent(fd, filename, filecontent)
end

function slave2master:redirectHttpRequest(fd, httpFd, requestUri, extra)
	-- todo
	print("slave to master done")
	local head = {"Content-Type: text/html"}
	local content = "ok"

	if not string.find(requestUri, "http") then
		requestUri = "https://"..requestUri
	end

	local cmd = "curl "..requestUri
	print("cmd is ", cmd)

	local t = io.popen(cmd)
	local a = t:read("*all")


	master2slave:replyHttpResult(fd, httpFd, head, a)
end

