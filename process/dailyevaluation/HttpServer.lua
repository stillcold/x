
local server = require "http.server"
local write = server.write
local httpIndex = require "Index"
local console = require "sys.console"
local json = require "sys/json"
local dateUtil = require "utils/dateutil"
local httpClient = require "http.client"
local core = require "sys.core"
require "utils.tableutils"

local dispatch = {}

local expireTime = 0
local defaultData = {
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
	}
local latest = {
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
		0,0,0,0,0,
	}

local pastData = {}

pastData[1] = defaultData
pastData[2] = defaultData
pastData[3] = defaultData

local idx2key = {
		"c1", "c2", "c3", "c4", "c5",
		"c6", "c7", "c8", "c9", "ca",
		"cb", "cc", "cd", "ce", "cf",
		"cg", "ch", "ci", "cj", "ck",
		"cl", "cm", "cn", "co", "cp",
		"cq", "cr", "cs", "ct", "cu",
	}

local key2idx = {}

for k,v in pairs(idx2key) do
	key2idx[v] = k
end

local function getNextDay()
	local now = os.time()
	local today = os.date("*t", now)
	local nextDay = os.time({
		year = today.year, 
		month = today.month,
		day = today.day + 1,
		hour = 0,
		min = 0,
		sec = 0,
		isdst = false;
	})
	return nextDay
end

local function checkValidRequest(request)
	local sign = request and request.form and request.form.sign
	if not sign or sign ~= core.envget("Sign") then
		print("invalid 1")
		return
	end
	if request.Cookie ~= core.envget("Cookie") then
		print("invalid 2")
		return
	end
	
	return true
end

local function parseData(data)
	local ret = {}
	for key, v in pairs(data) do
		local idx = key2idx[key]
		ret[idx] = v
	end
	
	for i = 1, 50 do
		if not ret[i] then
			ret[i] = 0
		end
	end
	PrintTable(ret)
	return ret
end

dispatch["/"] = function(fd, request, body)

	print("request")
	PrintTable(request)
	print("body")
	print(body)

	local head = {
		"Content-Type: text/html",
		"Access-Control-Allow-Origin: http://inthinkng.tech",
		"Access-Control-Allow-Credentials: true"
	}
	
	local default = json.encode(defaultData)
	
	if not checkValidRequest(request) then
		-- write(fd, 200, head, default)
		-- return
	end
	
	local requestBodyObj = json.decode(body)
	local ack
	local now = os.time()
	if requestBodyObj.cmd == "init" then
		-- 尚未过期
		if expireTime > now then
			ack = latest
		else
		-- 过期了使用默认数据
			ack = defaultData
			
			pastData[1] = pastData[2] or defaultData
			pastData[2] = pastData[3] or defaultData
			pastData[3] = latest
		
		end
	-- 页面上发了更新的请求
	elseif requestBodyObj.cmd == "update" then
		ack = parseData(requestBodyObj.data)
		latest = ack
		
	end
	
	expireTime = getNextDay()
	
	pastData[4] = ack
	
	write(fd, 200, head, json.encode(pastData))
end



-- Entry!
server.listen(":8091", function(fd, request, body)
	local c = dispatch[request.uri]
	if c then
		c(fd, request, body)
	else
		print("Unsupport uri", request.uri)
		write(fd, 404, {"Content-Type: text/plain"}, "404 Page Not Found")
	end
end)


console {
	addr = ":2324"
	}

