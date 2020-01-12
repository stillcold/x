local core				= require "sys.core"

local localEnvConfig 	= require "localenvconfig"
local processconfig 	= require "processconfig"
local configMgr 		= {}
local client			= require "http.client"
local useDefault 		= (tonumber(core.envget("usedefault")) == 1)
local queryConfigUrl	= core.envget("queryconfigurl")
local showDoc			= (tonumber(core.envget("showdoc")) == 1)

function configMgr:ConfigOneFile(processName, fileConfig)
	local filePath 	= fileConfig.path
	local lineEnd 	= fileConfig.lineEnd
	local fileType	= fileConfig.fileType
	local items		= fileConfig.items
	local lineBegin	= ""
	
	local outFile = io.open(filePath, "w")

	print("\tconfig "..fileType.." file "..filePath)
	
	if fileType == "lua" then
		lineBegin	= "\t"
		outFile:write([[return {]].."\n")
	end

	for idx, item in ipairs(items) do
		local itemName		= item[1]
		local localEnvName 	= item[2]
		local defaultValue	= item[3]

		local value	= defaultValue
		if not useDefault and localEnvName then
			local url = queryConfigUrl..localEnvName
			local status, head, body = client.GET(url)
			local httpFound = false
			if status == 200 and body then
				if body ~= "notfound" then
					httpFound = true
					value = body
				end
			end

			if not httpFound then
				value = localEnvConfig[localEnvName] or defaultValue

				local toPrint = "\t\t Warning: server not response right for "
				toPrint = toPrint .. localEnvName
				toPrint = toPrint .. " --> status:"..status
				toPrint = toPrint .. " body:"..body
				print(toPrint)
			end
		end

		local lineContent = itemName .. " = "

		if type(value) == "number" then
			lineContent = lineContent .. value
		else
			lineContent = lineContent .. [["]]..value .. [["]]
		end

		print("\t\t config "..itemName.." to "..value)

		outFile:write(lineBegin..lineContent..lineEnd.."\n")
	end
	
	if fileType == "lua" then
		outFile:write([[}]])
	end

	outFile:close()
end

function configMgr:ConfigProcesses()
	for processName, processConfig in pairs(processconfig) do
		print("config process "..processName)
		for idx1, fileConfig in pairs(processConfig) do
			self:ConfigOneFile(processName, fileConfig)
		end
	end
end

function configMgr:ShowDoc()

	local rawDoc = 
[==[

Demos:

QueryConfig.php:
---
<?php

ini_set('display_errors', false);
error_reporting(E_ALL);

// 这就不用写注释了
require 'XConfig.php';
$itemName = $_GET['itemName'];
if (!isset($itemName)){
	echo "notfound";
}
$configValue = $XConfig[$itemName];
if (!isset($configValue)){
	echo "notfound";
}
echo $configValue;


XConfig.php:
---
<?php

$XConfig = array(
	// 浏览器访问本地http服务的时候,需要提供的cookie,
	// search(one) 和 todolist都是用的这个
	'Cookie' 				=> "hi=wow1",
	// 浏览器访问本地http服务需提供的sign
	// search(one) 和 todolist都是用的这个
	'Sign'					=> "sign",
	// 展示给浏览器中的网页中的链接中的host,支持域名
	'PublicHttpHost' 		=> "baidu.com",
	// 展示给浏览器中的网页中的链接中的port
	'PublicHttpPort'		=> 80,
	// 本地根据规则生成html文件时需要找到的目录,大概率是本地网站根目录
	'HttpDir'				=> "/var/www/html/",
	// 脑图文件目录,会在这个目录中生成一些新的文件
	// 也用于访问脑图
	'MindMapDir'			=> "mindmap/",
	// 本地Ip,大概率就是 127.0.0.1,目前多用于服务启动时候拉代码和配置信息
	'InternalIp' 			=> "127.0.0.1",
	// 本地部署的http端口,目前多用于服务器启动的时候拉代码和配置信息
	'InternalHttpPort' 		=> 80,
	// TodoList使用的数据库地址和端口
	'TodoDbHost' 			=> "127.0.0.1:3306",
	// TodoList使用的数据库用户
	'TodoDbUser' 			=> "todo",
	// TodoList使用的数据库密码
	'TodoDbPassword' 		=> "123456",
);

]==]

	local content = "Please put those two files to dir which match url:"..queryConfigUrl..rawDoc

	print(content)
end

-- 入口
function configMgr:DoGen()
	if showDoc then
		self:ShowDoc()
	else
		self:ConfigProcesses()
	end
	print("done! process will quit.")
	core.exit()
end

return configMgr
