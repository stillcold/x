local core = require "sys.core"

Slave2Master = {}

function writeToFile(path, content)
	local file = io.open(path, "wb")
	if not file then return end
	
	file:write(content)
	file:close()
end

function Slave2Master:rrpc_sum(pipe, ...)
	local args = {...}
	for k,v in pairs(args) do
		print(k,v)
	end
	return "arpc_sum",{val = 1, suffix = "connected"}
end

function Slave2Master:Handshake(pipe, data)
	local name = data.name

	if g_Name2Fd[name] then
		print("try register name fail", name)
		return "HandshakeDone", {val = "taken"}
	end
	
	g_Name2Fd[name] = pipe
	print("name resgiter done", name)
	return "HandshakeDone", {val = "done"}	
end

-- 查询搜索库的文件概况
function Slave2Master:GetSearchRepoOverview()
	local data = {}

	local dirPath = core.envget("search_repo_path")
	
	local privateLow = tonumber(core.envget("private_seria_low"))
    local privateHigh = tonumber(core.envget("private_seria_high"))

	for filePath in lfs.dir(dirPath) do
		local fileflag = string.match(filePath, "(%d+)") or 0
		local fileSerialNum = tonumber(fileflag)
	
		if filePath ~= "." and filePath ~= ".." and not (fileSerialNum >= privateLow and fileSerialNum <= privateHigh) then
			local fullPath = dirPath.."/"..filePath
			print(fullPath)
			local att = lfs.attributes(fullPath)

			data[filePath] = {}
			data[filePath].size = att.size or 0
			data[filePath].modification = att.modification or 0
			-- table.insert(data, filePath)
			-- table.insert(data, att.size or 0)
			-- table.insert(data, att.modification or 0)
		end
	end

	local str = serialize(data)

	return "ReplySearchRepoOverview", {overview = str}
end

function Slave2Master:GetMasterFileContent(pipe, data)
	local filePath = data and data.fileName
	
	if not filePath then
		return
	end
	
	local dirPath = core.envget("search_repo_path")
	local fullPath = dirPath.."/"..filePath
	local file = io.open(fullPath, "rb")
	if not file then
		return
	end
	
	local content = file:read("*a")
	file:close()
	
	return "ReplyMasterFileContent", {fileName = filePath, fileContent = content}
end

function Slave2Master:UploadSlaveFileContent(pipe, data)
	local filePath = data and data.fileName
	local fileflag = string.match(filePath, "(%d+)") or 0
    local fileSerialNum = tonumber(fileflag)
	
	local benchmarkLow = tonumber(core.envget("benchmark_seria_low"))
    local benchmarkHigh = tonumber(core.envget("benchmark_seria_high"))
	
	local dirPath = core.envget("search_repo_path")
	local fullPath = dirPath.."/"..filePath
	
	if fileSerialNum <= benchmarkHigh and fileSerialNum >= benchmarkLow then
		local testFile = io.open(fullPath, "r")
		if testFile then
			testFile:close()
			
			print("master refuse file cause its master benchmark", filePath)
			return "SyncUploadSlaveFileContent", {fileName = filePath}
		end
		
    end
	
	local content = data.fileContent
	
	if not content then return end
	
	writeToFile(fullPath, content)
	print("master accept file ", filePath)
	
	return "SyncUploadSlaveFileContent", {fileName = filePath}
end

