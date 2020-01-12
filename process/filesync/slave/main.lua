require "SAConfig"

local core 		= require "sys.core"
local rpc 		= require "saux.rpc"
local rpcproto = require "rpcproto"
local dns = require "sys.dns"
require "sys.serialize"

local host = core.envget "service_host"
local port = core.envget "service_port"

g_RpcClient = nil

print(lfs.currentdir())

function writeToFile(path, content)
	local file = io.open(path, "wb")
	if not file then return end

	file:write(content)

	file:close()
end

core.start(function()
	
	-- 转成IPV4格式的ip地址
	local ip = dns.resolve(host, "A")
	print("ip is", ip)

	g_RpcClient = rpc.createclient {
		addr = ip..":"..port,
		proto = rpcproto,
		timeout = 5000,
		call = function (fd, cmd, msg)
			core.log("rpc call in")
		end,
		close = function(fd, errno)
			core.log("close", fd, errno)
		end
	}


	local ok = g_RpcClient:connect()
	core.log("rpc connect status", ok)
	assert(ok)
	local result = g_RpcClient:call("rrpc_sum", {val1 = 1, val2 = 2, suffix = "test"})
	if not( result and result.suffix == "connected") then
		return
	end

	local clientName = core.envget("client_name")
	print(clientName)
	local tryTimes = 0
	result = g_RpcClient:call("Handshake", {name = clientName})

	while (result and result.val ~= "done" ) do
		tryTimes = tryTimes + 1
		if tryTimes > 10 then
			print("Register name try too many times. App will quit.")
			return
		end
		clientName = core.envget("client_name").."+"..tryTimes
		result = g_RpcClient:call("Handshake", {name = clientName})
	end
	if not result then
		return
	end

	local overview_local = {}
	local dirPath =  core.envget("search_repo_path")
	
	for filePath in lfs.dir(dirPath) do
		if filePath ~= "." and filePath ~= ".." then
			local fullPath = dirPath.."/"..filePath
			local att = lfs.attributes(fullPath)
	
			overview_local[filePath]= {}
			overview_local[filePath].size = att.size or 0
			overview_local[filePath].modification = att.modification or 0
			print("find local file att", filePath, att.size, att.mofication)
		end
	end

	local benchmarkLow = tonumber(core.envget("benchmark_seria_low"))
	local benchmarkHigh = tonumber(core.envget("benchmark_seria_high"))

	local toUseMasterFile = {}

	result = g_RpcClient:call("GetSearchRepoOverview", {})
	local overview_master = unserialize(result.overview)
	for filePath,att in pairs(overview_master) do
		local localAtt = overview_local[filePath]
		if not localAtt then
			print("no local file found, will use matser file", filePath)
			toUseMasterFile[filePath] = 1
		end
		if localAtt and att.size ~= localAtt.size and att.size then
			local fileflag = string.match(filePath, "(%d+)") or 0
			local fileSerialNum = tonumber(fileflag)

			if fileSerialNum > benchmarkHigh or fileSerialNum < benchmarkLow then
				toUseMasterFile[filePath] = 1
				print("local is not benchmark, will use master file", filePath)
			elseif localAtt.size and localAtt.size > 0 then
				local fullPath = dirPath.."/"..filePath
				print("will upload local file to master,", fullPath)
				local file = io.open(fullPath, "rb")
				if file then
					local content = file:read("*a")
					file:close()
					result = g_RpcClient:call("UploadSlaveFileContent",{fileName = filePath, fileContent = content})
				end
			end
		end

	end

	print("handle all done")

	for filePath, _ in pairs(toUseMasterFile) do
		print("get file from master:", filePath)
		result = g_RpcClient:call("GetMasterFileContent", {fileName = filePath})
		local fileContent = result.fileContent

		if fileContent then
			local fullPath = dirPath.."/"..filePath
			writeToFile(fullPath, fileContent)
		end
	end
	
	local privateLow = tonumber(core.envget("private_seria_low"))
	local privateHigh = tonumber(core.envget("private_seria_high"))

	for filePath, _ in pairs(overview_local) do
		local fileflag = string.match(filePath, "(%d+)") or 0
		local fileSerialNum = tonumber(fileflag)

		if not overview_master[filePath] and not(fileSerialNum >= privateLow and fileSerialNum <= privateHigh) then
			local fullPath = dirPath.."/"..filePath
			local file = io.open(fullPath, "rb")
			if file then
				local content = file:read("*a")
				file:close()
				local ret = g_RpcClient:call("UploadSlaveFileContent",{fileName = filePath, fileContent = content})
			end
		end
	end

	print("All jobs done.")	

end)

