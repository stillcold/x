function MODULE(modulename)
	if not modulename then
		core.debug(100, "no modulename found, app will quit")
		core.exit()
	end
	
	local globalname = "g_"..modulename
	if _G[globalname] then
		core.debug(100, "modulename repeat, app will quit")
		core.exit()
	end

	local tbl = {}

	_G[modulename] = tbl
	_G[globalname] = tbl
end
