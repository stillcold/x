MODULE("filesyncmgr")

function filesyncmgr:handlesearchrepo_overview(fd, overview)
	-- PrintTable(overview)
	local searchrepodir 	= core.envget("search_repo_dir")
	for filename, modification in pairs(overview) do
		local fullpath 	= searchrepodir..filename
		local attr 		= lfs.attributes(fullpath)

		if attr.modification < modification then
			slave2master:requestdownloadfile(fd, filename)
		end
		if attr.modification > modification then
			local file 			= io.open(fullpath, "rb")
			if file then
				local filecontent 	= file:read("*a")
				file:close()
				slave2master:requestuploadfile(fd, filename, filecontent)
				core.debug(1, "uploaded ".. filename .. "to server")
			end
		end
	end
end

function filesyncmgr:writedownfilecontent(filename, filecontent)
	
	local repodir 		= core.envget("search_repo_dir")
	local fullpath		= repodir.."/"..filename

	local file = io.open(fullpath, "wb")
	if not file then return end

	file:write(filecontent)
	file:close()
	core.debug(1, "write down "..fullpath)
end

