MODULE("filesyncmgr")

function filesyncmgr:get_searchrepo_overview()

	local repodir = core.envget("search_repo_dir")
	core.debug(1, "ls dir:")
	for entry in lfs.dir(repodir) do
		local fullpath = repodir.."/"..entry
		local attr = lfs.attributes(fullpath)

		if (type(attr) == "table") then
			if(attr.mode == "directory") then
				core.debug(1, fullpath .." is a dir")
			elseif attr.mode=="file" then
				core.debug(1, fullpath.." is a file")
			end
		else
			core.debug(2, "query "..fullpath.." failed")
		end

	end
end


