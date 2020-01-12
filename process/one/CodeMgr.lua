local client = require "http.client"
local core = require "sys.core"
require "sys.tick"
local CodeConfig = SAConfig.CodeConfig

local CodeMgr = {}

function CodeMgr:ConvertReturnToFile(httpBody, targetFilePath)
	local file = io.open(targetFilePath, "w+")
	if file then
		if file:write(httpBody) == nil then return false end
		io.close(file)
		return true
	else
		print("fail write code to "..targetFilePath)
		return false
	end
end

function CodeMgr:DownloadOneFile(toDownload, targetFilePath)
	local url = "http://"..CodeConfig.Host..":"..CodeConfig.Port.."/"..CodeConfig.DownloadPreUrl..toDownload
	print("getting code->"..url)
	local status, head, body = client.GET(url)

	if status == 200 then
		print("downloading "..toDownload.." as "..targetFilePath)
		self:ConvertReturnToFile(body, targetFilePath or toDownload)
	end
end

function CodeMgr:DownLoadCode()
	local hasDownloaded = {}
	global.__extraDownload = {}
	for _, toDownload in pairs(CodeConfig.Alias) do
		self:DownloadOneFile(toDownload[1], toDownload[2])
		hasDownloaded[toDownload[1]] = true
	end

	for _, toDownloadDirInfo in pairs(CodeConfig.DownloadDir or {}) do
		local toDownloadDirName = toDownloadDirInfo[1]
		local url = "http://"..CodeConfig.Host..":"..CodeConfig.Port.."/"..CodeConfig.ListDirPreUrl..toDownloadDirName
		local status, head, body = client.GET(url)

		if status == 200 then
			for fileName in string.gmatch(body, "([^|]+)") do
				local toDownloadFilePrefix = string.match(fileName, "([%w_]+).lua")
				if toDownloadFilePrefix then
					local downloadKey = toDownloadDirName.."/"..toDownloadFilePrefix
					if not hasDownloaded[downloadKey] then
						self:DownloadOneFile(downloadKey, "process/one/"..toDownloadDirName.."/"..fileName)
						table.insert(global.__extraDownload, toDownloadFilePrefix)
					end
				end
				
			end
		end

	end

	print("Code all set, start all modules now...")
	
	require "HttpServer"

end

function CodeMgr:TestPatch()
	print("a")
end

return CodeMgr

