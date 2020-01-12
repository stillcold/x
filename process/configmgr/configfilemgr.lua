-- This code is not in use anymore.

local configFileMgr = {}

local process2ConfigFileInfo = {
	one = {
		entry = "process/one/entry.config",
		localConfig = "process/one/LocalConfig.lua",
	},
	filesync = {
		masterEntry = "process/filesync/master/entry.config",
		masterLocal = "process/filesync/master/LocalConfig.lua",
		slaveEntry = "process/filesync/slave/entry.config",
		slaveLocal = "process/filesync/slave/LocalConfig.lua",
	},
	todolist = {
		entry = "process/todolist/entry.config",
	},
}

-- 返回迭代器
function configFileMgr:GetConfigFiles(process)

	local toOutputData = {}

	local processData = process2ConfigFileInfo[process]
	
	for k,v in pairs(processData or {}) do
		table.insert(toOutputData, { v, k})
	end

	local i = 1
	local len = #toOutputData

	return function()
		if i <= len then
			local ret = toOutputData[i]
			i = i + 1
			return ret
		end
	end
end

return configFileMgr

