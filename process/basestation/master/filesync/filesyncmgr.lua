MODULE("filesyncmgr")

function filesyncmgr:ismatchfilter(filename, filterpattern)
	if string.find(filename, filterpattern) then
		return true
	end
end

function filesyncmgr:get_searchrepo_overview()
	local tosyncdata = {}
	
	local repodir 		= core.envget("search_repo_dir")
	local filterpattern	= core.envget("search_file_filter")
	
	local function querydir (relativepath)
		local toquerydir = repodir

		if relativepath then
			toquerydir = repodir.."/"..relativepath
		end

		for entry in lfs.dir(toquerydir) do
		
			local fullpath = toquerydir.."/"..entry
			local attr = lfs.attributes(fullpath)

			if (type(attr) == "table") then
				if(attr.mode == "directory") then
					core.debug(1, fullpath .." is a dir")
					if entry ~= "." and entry ~= ".." then
						if relativepath then
							querydir(relativepath.."/"..entry)
						else
							querydir(entry)
						end
					end
				elseif attr.mode=="file" then
					local toreportfilename = entry
					if relativepath then
						toreportfilename = relativepath.."/"..entry
					end

					if self:ismatchfilter(toreportfilename, filterpattern) then
						local modification = attr.modification
						core.debug(1, fullpath.." is a match file, modification time is ", modification)
						tosyncdata[toreportfilename] = modification
					else
						core.debug(1, fullpath.." is a mismatch file")
					end
				end
			else
				core.debug(2, "query "..fullpath.." failed")
			end
		end

	end

	core.debug(1, "ls dir:")
	querydir()

	return tosyncdata
end

function filesyncmgr:writedownfilecontent(filename, filecontent)
	
	local repodir 		= core.envget("search_repo_dir")
	local fullpath		= repodir.."/"..filename

	local file = io.open(fullpath, "wb")
	if not file then return end

	file:write(filecontent)
	file:close()
	core.debug(1, "wrie down "..fullpath)
end

function filesyncmgr:getfilecontent(filename)
	
	local repodir 		= core.envget("search_repo_dir")
	local fullpath		= repodir.."/"..filename

	local file = io.open(fullpath, "rb")
	if not file then
		return
	end
	local filecontent = file:read("*a")
	file:close()
	return filecontent
end
