MODULE("filesyncmgr")

function filesyncmgr:ismatchfilter(filename, filterpattern)
	if string.find(filename, filterpattern) then
		return true
	end
end

function filesyncmgr:handlesearchrepo_overview(fd, overview)
	-- PrintTable(overview)
	local searchrepodir 	= core.envget("search_repo_dir")
	for filename, modification in pairs(overview) do
		core.debug(1, "handling "..filename)
		core.debug(1, "filepath is ",searchrepodir, filename)
		local fullpath 	= searchrepodir..filename
		local file 		= io.open(fullpath, "rb")
		if not file then
		else
			file:close()
		end
		local attr 		= lfs.attributes(fullpath)
		if not attr then
			core.debug(1, "file not exist ", fullpath)
			slave2master:requestdownloadfile(fd, filename)
		else

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
			if attr.modification == modification then
				core.debug(1, "modification time is the same with "..filename)
			end
		end
	end

	local localfiles = {}
	
	local repodir 		= core.envget("search_repo_dir")
	local filterpattern	= core.envget("search_file_filter") or "%.lua"
	
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
						localfiles[toreportfilename] = modification
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

	for filename, modification in pairs(localfiles or {}) do
		if not overview[filename] then
			slave2master:requestuploadfile(fd, filename)
		end
	end
end

function filesyncmgr:writedownfilecontent(filename, filecontent)

	core.debug(1, "try writedown file ", filename)
	
	local repodir 		= core.envget("search_repo_dir")
	local fullpath		= repodir.."/"..filename

	local targetdir 	= repodir

	if not lfs.chdir(repodir) then
		core.debug(2, "change work dir failed", repodir)
		return
	end

	-- core.debug(1, "current dir", lfs.currentdir())
	
	for partpath in string.gmatch(filename, "([^/]+)/") do
		-- core.debug(1, "part path ", partpath)
		targetdir 	= targetdir.."/"..partpath
		-- core.debug(1, "targetdir ", targetdir)
		if not lfs.mkdir(partpath) then
			-- core.debug(2, "mkdir failed", partpath)
		end
		if not lfs.chdir(targetdir) then
			core.debug(2, "chang dir fialed", targetdir)
			return
		end
	end

	local file = io.open(fullpath, "wb")
	if not file then return end

	file:write(filecontent)
	file:close()
	core.debug(1, "done! write down "..fullpath)
end

