
function master2slave:Test(conn, tbl)
	core.debug(1, "rpc from server is ")
	PrintTable(tbl)
end

function master2slave:syncsearchrepo_overview(fd, overview)
	g_filesyncmgr:handlesearchrepo_overview(fd, overview)
end

function master2slave:syncfilecontent(fd, filename, filecontent)
	g_filesyncmgr:writedownfilecontent(filename, filecontent)
end

function master2slave:syncauthresult(fd, result)
	core.debug(1, "auth result", result)
end
