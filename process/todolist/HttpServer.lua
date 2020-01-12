
local server = require "http.server"
local write = server.write
local httpIndex = require "Index"
local console = require "sys.console"
local db = require "DbMgr"
local json = require "sys/json"
local dateUtil = require "utils/dateutil"
local httpClient = require "http.client"
local core = require "sys.core"
require "utils.tableutils"

local dispatch = {}

local defaultHead = httpIndex.Head
local defaultTail = httpIndex.Tail
local default = defaultHead..defaultTail

local content = ""
local cachedBirthday = {}

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

local function getTodayDataStr()
	local todayTimeForShow = os.date("*t", os.time())
	
	local wdayForShow = todayTimeForShow.wday
	wdayForShow = wdayForShow - 1
	if wdayForShow == 0 then
		wdayForShow = "日"
	end
	
	local todayTimeStrForShow = "今天是 "..todayTimeForShow.year.."年"..todayTimeForShow.month.."月"..todayTimeForShow.day.."日,星期"..wdayForShow.."<br><br>"
	return todayTimeStrForShow
end

local function getBirthdayInfo(dayRange, LowTime, HighTime)
	
	-- 检查生日部分
	local nowTime = os.time()
	local isCacheHit = false
	if cachedBirthday.expire and cachedBirthday.expire > nowTime then
		if cachedBirthday[dayRange] then
			
			isCacheHit = true
			return cachedBirthday[dayRange]
		end
	else
		cachedBirthday = {expire = (nowTime + 3600 *24)}
	end

if not isCacheHit then

	local birthdayTxt = ""

	local today = os.date("*t", nowTime)
	queryResult = db:GetAllBirthdayRecord(LowTime, HighTime)
	for k,v in pairs (queryResult or {}) do
		local jsonStr = v.AllProps
		local jsonTbl = json.decode(jsonStr)
		print(k, jsonTbl.date)
		local year, month, day = string.match(jsonTbl.date or "", "(%d+)[^%d]+(%d+)[^%d]+(%d+)")
		local isYangLi = jsonTbl.isYangLi
		year 	= tonumber(year)
		month 	= tonumber(month)
		day 	= tonumber(day)
		
		local birthdayDate = {year = year, month = month, day = day}
		
		-- 农历
		if isYangLi == false or isYangLi == "false" then
		    PrintTable(birthdayDate)
			local birthDayYangLiDate = dateUtil:NongLi2ThisYearYangLi(birthdayDate)
			PrintTable(birthDayYangLiDate)
			local todayNongLiDate = dateUtil:YangLi2NongLiDate({year = today.year, month = today.month, day = today.day})
			if dateUtil:IsBirthdayDateNear(nowTime, birthdayDate, true, dayRange) then
				local text = v.Name
				local nongliText = "(农历 "..birthdayDate.year.."-"..birthdayDate.month.."-"..birthdayDate.day..")"
				birthdayTxt = birthdayTxt..birthDayYangLiDate.month.."月"..birthDayYangLiDate.day.."日"..nongliText.."是<em>"..text.."</em>的生日"..[[<br>]]
			end
			
		-- 阳历
		else
			local yangLiDayOfThisYear = {year = today.year, month = birthdayDate.month, day = birthdayDate.day, hour = 12, min = 0, sec = 0}
			local yangLiTimeOfThisYear = os.time(yangLiDayOfThisYear)
		
			if yangLiTimeOfThisYear >= LowTime and yangLiTimeOfThisYear <= HighTime then
				local text = v.Name
				local yangliText = "(阳历 "..birthdayDate.year.."-"..birthdayDate.month.."-"..birthdayDate.day..")"
				birthdayTxt = birthdayTxt..birthdayDate.month.."月"..birthdayDate.day.."日"..yangliText.."是<em>"..text.."</em>的生日"..[[<br>]]
			end
		end
		
	end

	cachedBirthday[dayRange] = birthdayTxt
	
end

	return birthdayTxt or ""
end

dispatch["/"] = function(fd, request, body)

	
	local body = default
	local head = {
		"Content-Type: text/html",
		}

	if not checkValidRequest(request) then
		write(fd, 200, head, "access deny.")
		return
	end

	write(fd, 200, head, body)
end


dispatch["/search"] = function(fd, request, body)
	
	local body = default
	local head = {
		"Content-Type: text/html",
		}

	if not checkValidRequest(request) then
		write(fd, 200, head, "access deny.")
		return
	end
	-- write(fd, 200, {"Content-Type: text/plain"}, content)
	if request.form.Hello then
		content = request.form.Hello
	end
	
	-- local body = httpIndex.SearchResultHead..searchMgr:GetAnswer(content)..httpIndex.SearchResultTail
	local HighTime = os.time() + 24 * 3600
	local LowTime = os.time() - 2 * 24 * 3600
	local dayRange = 1
	if content == "today" or content == "today todo" or content == "今日任务" then
		HighTime = os.time() + 24 * 3600
		dayRange = 2
	end
	
	if content == "week" or content == "week todo" or content == "本周任务" or content == "weeklyReport" then
		LowTime = os.time() - 7 * 24 * 3600
		HighTime = os.time() + 10 * 24 * 3600
		dayRange = 10
	end
	
	if content == "month" or content == "month todo" or content == "本月任务" then
		LowTime = os.time() - 31 * 24 * 3600
		HighTime = os.time() + 33 * 24 * 3600
		dayRange = 33
	end
	
	if content == "all" or content == "all todo" or content == "所有任务" then
		LowTime = 0
		HighTime = os.time() + 24 * 3600 * 366 * 10 -- 10年
		dayRange = -1
	end
	
	local queryResult = db:GetRecordByRemindTimeRange(LowTime, HighTime)
	local showTbl = {}
	local result = ""
	local wdayCache = {}
	local weekCache = {}
	local dayOfYearCache = {}
	local weekDayBeginTag = "<em>"
	local weekDayEndTag = "</em>"
	local lineDateBeginTag = "<i>"
	local lineDateEndTag = "</i>"
	
	local todayTimeStrForShow = getTodayDataStr()
	result = result.."<br>"..todayTimeStrForShow
	
	for k,v in pairs (queryResult or {}) do
		print(k,v.AllProps)
		print(v.Id)
		showTbl[v.Id] = v.AllProps
		local jsonStr = v.AllProps
		local jsonTbl = json.decode(jsonStr)
		local text = jsonTbl.content
		local nowTime = os.time()
		local nowDateW = tonumber(os.date("%W", nowTime))
		
		if content == "week" or content == "week todo" or content == "本周任务" then
		
			local dateT = os.date("*t", v.RemindTime)
			local dateR = tonumber(os.date("%W", v.RemindTime))
			local dateY = tonumber(os.date("%j", v.RemindTime))
			local weekDayBeginTag = "<em>"
			local weekDayEndTag = "</em>"
			
			local wday = dateT.wday
			wday = wday - 1
			if wday == 0 then
				wday = "日"
			end
		
			if not dayOfYearCache[dateY] then
				dayOfYearCache[dateY] = 1
				if dateR == nowDateW - 1 then
					result = result..weekDayBeginTag.."上周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW then
					result = result..weekDayBeginTag.."本周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW + 1 then
					result = result..weekDayBeginTag.."下周"..wday..weekDayEndTag.."<br>"
				else
					result = result..weekDayBeginTag.."较远"..weekDayEndTag.."<br>"
				end
			end
		end
		local lineBeginDate = os.date("*t", v.RemindTime)
		local textWithDate = lineDateBeginTag..lineBeginDate.month.."月"..lineBeginDate.day.."日"..lineDateEndTag.."&nbsp&nbsp"..text
		result = result..[[<a href = "advance?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">advance</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "postpone?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">postpone</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "delete?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">done</a>&nbsp;&nbsp;]]..textWithDate..[[<br>]]
	end
	
	result = result.."<br>"
	
	-- result = result.. cachedBirthday[dayRange]
	result = result..getBirthdayInfo(dayRange, LowTime, HighTime)
	
	if content == "weeklyReport" then
		local diarySaveInfoTbl = {keyworld = text, action = "weekly", tag = "text_from_todo"}
		local code, header, weeklyResult = httpClient.POST("http://127.0.0.1:8086/mail_weekly_content.php", {"Content-Type: text/plain"}, json.encode(diarySaveInfoTbl))

		print("check what in res", weeklyResult)
		-- for k,v in pairs(weeklyResult) do
		-- 	print(k,v)
		-- end
		result = result..weeklyResult
	end

	-- local result = json.encode(showTbl)
	local body = httpIndex.SearchResultHead..result..httpIndex.SearchResultTail
	local head = {
		"Content-Type: text/html",
		}
	write(fd, 200, head, body)

	
end


dispatch["/delete"] = function(fd, request, body)

	local body = default
	local head = {
		"Content-Type: text/html",
		}

	if not checkValidRequest(request) then
		write(fd, 200, head, "access deny.")
		return
	end
	
	print("try delete")
	-- write(fd, 200, {"Content-Type: text/plain"}, content)
	local content, editTarget, text
	if request.form then
		content 	= request.form.todoType
		editTarget 	= request.form.id
		text  		= request.form.text
	end

	db:DeleteRecordById(editTarget)
	local diarySaveInfoTbl = {keyworld = text, action = "add", tag = "text_from_todo"}
	
	httpClient.POST("http://127.0.0.1:8086/diary/writedown.php", {"Content-Type: text/plain"}, json.encode(diarySaveInfoTbl))
	
	-- local body = httpIndex.SearchResultHead..searchMgr:GetAnswer(content)..httpIndex.SearchResultTail
	local HighTime = os.time() + 24 * 3600
	local LowTime = os.time() - 2 * 24 * 3600
	if content == "today" or content == "today todo" or content == "今日任务" then
		HighTime = os.time() + 24 * 3600
	end
	
	if content == "week" or content == "week todo" or content == "本周任务" then
		LowTime = os.time() - 7 * 24 * 3600
		HighTime = os.time() + 2 * 7 * 24 * 3600
		dayRange = 10
	end
	
	if content == "month" or content == "month todo" or content == "本月任务" then
		LowTime = os.time() - 31 * 24 * 3600
		HighTime = os.time() + 33 * 24 * 3600
		dayRange = 33
	end
	
	if content == "all" or content == "all todo" or content == "所有任务" then
		LowTime = 0
		HighTime = os.time() + 24 * 3600 * 366 * 10 -- 10年
		dayRange = -1
	end
	
	local queryResult = db:GetRecordByRemindTimeRange(LowTime, HighTime)
	local showTbl = {}
	local result = ""
	
	local todayTimeStrForShow = getTodayDataStr()
	result = result.."<br>"..todayTimeStrForShow
	
	local wdayCache = {}
	local weekCache = {}
	local dayOfYearCache = {}
	local weekDayBeginTag = "<em>"
	local weekDayEndTag = "</em>"
	local lineDateBeginTag = "<i>"
	local lineDateEndTag = "</i>"

	for k,v in pairs (queryResult or {}) do
		print(k,v.AllProps)
		print(v.Id)
		showTbl[v.Id] = v.AllProps
		local jsonStr = v.AllProps
		local jsonTbl = json.decode(jsonStr)
		local text = jsonTbl.content
		
		local nowTime = os.time()
		local nowDateW = tonumber(os.date("%W", nowTime))
		
		if content == "week" or content == "week todo" or content == "本周任务" then
		
			local dateT = os.date("*t", v.RemindTime)
			local dateR = tonumber(os.date("%W", v.RemindTime))
			local dateY = tonumber(os.date("%j", v.RemindTime))
			
			local wday = dateT.wday
			wday = wday - 1
			if wday == 0 then
				wday = "日"
			end
			if not dayOfYearCache[dateY] then
				dayOfYearCache[dateY] = 1
				if dateR == nowDateW - 1 then
					result = result..weekDayBeginTag.."上周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW then
					result = result..weekDayBeginTag.."本周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW + 1 then
					result = result..weekDayBeginTag.."下周"..wday..weekDayEndTag.."<br>"
				else
					result = result..weekDayBeginTag.."较远"..weekDayEndTag.."<br>"
				end
			end
			
		end
		
		result = result..[[<a href = "advance?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">advance</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "postpone?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">postpone</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "delete?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">done</a>&nbsp;&nbsp;]]..text..[[<br>]]
	end
	
	result = result.."<br>"
	result = result..getBirthdayInfo(dayRange, LowTime, HighTime)
	
	-- local result = json.encode(showTbl)
	local body = httpIndex.SearchResultHead..result..httpIndex.SearchResultTail

	local head = {
		"Content-Type: text/html",
		}
	write(fd, 200, head, body)
end


dispatch["/postpone"] = function(fd, request, body)

	local body = default
	local head = {
		"Content-Type: text/html",
		}

	if not checkValidRequest(request) then
		write(fd, 200, head, "access deny.")
		return
	end
	print("try postpone")
	-- write(fd, 200, {"Content-Type: text/plain"}, content)
	local content, editTarget, text
	if request.form then
		content 	= request.form.todoType
		editTarget 	= request.form.id
		text  		= request.form.text
		remindTime  = request.form.remindTime
	end

	db:PostponeRecordById(editTarget, tonumber(remindTime))
	
	-- local diarySaveInfoTbl = {keyworld = text, action = "add", tag = "text_from_todo"}
	-- httpClient.POST("http://127.0.0.1:80/diary/writedown.php", {"Content-Type: text/plain"}, json.encode(diarySaveInfoTbl))
	
	-- local body = httpIndex.SearchResultHead..searchMgr:GetAnswer(content)..httpIndex.SearchResultTail
	local HighTime = os.time() + 24 * 3600
	local LowTime = os.time() - 2 * 24 * 3600
	if content == "today" or content == "today todo" or content == "今日任务" then
		HighTime = os.time() + 24 * 3600
	end
	
	if content == "week" or content == "week todo" or content == "本周任务" then
		LowTime = os.time() - 7 * 24 * 3600
		HighTime = os.time() + 2 * 7 * 24 * 3600
		dayRange = 10
	end
	
	if content == "month" or content == "month todo" or content == "本月任务" then
		LowTime = os.time() - 31 * 24 * 3600
		HighTime = os.time() + 33 * 24 * 3600
		dayRange = 33
	end
	
	if content == "all" or content == "all todo" or content == "所有任务" then
		LowTime = 0
		HighTime = os.time() + 24 * 3600 * 366 * 10 -- 10年
		dayRange = -1
	end
	
	local queryResult = db:GetRecordByRemindTimeRange(LowTime, HighTime)
	local showTbl = {}
	local result = ""
	
	local todayTimeStrForShow = getTodayDataStr()
	result = result.."<br>"..todayTimeStrForShow
	
	local wdayCache = {}
	local weekCache = {}
	local dayOfYearCache = {}
	local weekDayBeginTag = "<em>"
	local weekDayEndTag = "</em>"
	local lineDateBeginTag = "<i>"
	local lineDateEndTag = "</i>"

	for k,v in pairs (queryResult or {}) do
		print(k,v.AllProps)
		print(v.Id)
		showTbl[v.Id] = v.AllProps
		local jsonStr = v.AllProps
		local jsonTbl = json.decode(jsonStr)
		local text = jsonTbl.content
		
		local nowTime = os.time()
		local nowDateW = tonumber(os.date("%W", nowTime))
		
		if content == "week" or content == "week todo" or content == "本周任务" then
		
			local dateT = os.date("*t", v.RemindTime)
			local dateR = tonumber(os.date("%W", v.RemindTime))
			local dateY = tonumber(os.date("%j", v.RemindTime))
			
			local wday = dateT.wday
			wday = wday - 1
			if wday == 0 then
				wday = "日"
			end
			if not dayOfYearCache[dateY] then
				dayOfYearCache[dateY] = 1
				if dateR == nowDateW - 1 then
					result = result..weekDayBeginTag.."上周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW then
					result = result..weekDayBeginTag.."本周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW + 1 then
					result = result..weekDayBeginTag.."下周"..wday..weekDayEndTag.."<br>"
				else
					result = result..weekDayBeginTag.."较远"..weekDayEndTag.."<br>"
				end
			end
			
		end
		
		result = result..[[<a href = "advance?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">advance</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "postpone?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">postpone</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "delete?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">done</a>&nbsp;&nbsp;]]..text..[[<br>]]
	end
	
	result = result.."<br>"
	result = result..getBirthdayInfo(dayRange, LowTime, HighTime)
	
	-- local result = json.encode(showTbl)
	local body = httpIndex.SearchResultHead..result..httpIndex.SearchResultTail

	local head = {
		"Content-Type: text/html",
		}
	write(fd, 200, head, body)
end


dispatch["/advance"] = function(fd, request, body)
	local body = default
	local head = {
		"Content-Type: text/html",
		}

	if not checkValidRequest(request) then
		write(fd, 200, head, "access deny.")
		return
	end
	print("try advance")
	-- write(fd, 200, {"Content-Type: text/plain"}, content)
	local content, editTarget, text
	if request.form then
		content 	= request.form.todoType
		editTarget 	= request.form.id
		text  		= request.form.text
		remindTime  = request.form.remindTime
	end

	db:AdvanceRecordById(editTarget, tonumber(remindTime))
	
	-- local diarySaveInfoTbl = {keyworld = text, action = "add", tag = "text_from_todo"}
	-- httpClient.POST("http://127.0.0.1:80/diary/writedown.php", {"Content-Type: text/plain"}, json.encode(diarySaveInfoTbl))
	
	-- local body = httpIndex.SearchResultHead..searchMgr:GetAnswer(content)..httpIndex.SearchResultTail
	local HighTime = os.time() + 24 * 3600
	local LowTime = os.time() - 2 * 24 * 3600
	if content == "today" or content == "today todo" or content == "今日任务" then
		HighTime = os.time() + 24 * 3600
	end
	
	if content == "week" or content == "week todo" or content == "本周任务" then
		LowTime = os.time() - 7 * 24 * 3600
		HighTime = os.time() + 2 * 7 * 24 * 3600
		dayRange = 10
	end
	
	if content == "month" or content == "month todo" or content == "本月任务" then
		LowTime = os.time() - 31 * 24 * 3600
		HighTime = os.time() + 33 * 24 * 3600
		dayRange = 33
	end
	
	if content == "all" or content == "all todo" or content == "所有任务" then
		LowTime = 0
		HighTime = os.time() + 24 * 3600 * 366 * 10 -- 10年
		dayRange = -1
	end
	
	local queryResult = db:GetRecordByRemindTimeRange(LowTime, HighTime)
	local showTbl = {}
	local result = ""
	
	local todayTimeStrForShow = getTodayDataStr()
	result = result.."<br>"..todayTimeStrForShow
	
	local wdayCache = {}
	local weekCache = {}
	local dayOfYearCache = {}
	local weekDayBeginTag = "<em>"
	local weekDayEndTag = "</em>"
	local lineDateBeginTag = "<i>"
	local lineDateEndTag = "</i>"

	for k,v in pairs (queryResult or {}) do
		print(k,v.AllProps)
		print(v.Id)
		showTbl[v.Id] = v.AllProps
		local jsonStr = v.AllProps
		local jsonTbl = json.decode(jsonStr)
		local text = jsonTbl.content
		
		local nowTime = os.time()
		local nowDateW = tonumber(os.date("%W", nowTime))
		
		if content == "week" or content == "week todo" or content == "本周任务" then
		
			local dateT = os.date("*t", v.RemindTime)
			local dateR = tonumber(os.date("%W", v.RemindTime))
			local dateY = tonumber(os.date("%j", v.RemindTime))
			
			local wday = dateT.wday
			wday = wday - 1
			if wday == 0 then
				wday = "日"
			end
			if not dayOfYearCache[dateY] then
				dayOfYearCache[dateY] = 1
				if dateR == nowDateW - 1 then
					result = result..weekDayBeginTag.."上周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW then
					result = result..weekDayBeginTag.."本周"..wday..weekDayEndTag.."<br>"
				elseif dateR == nowDateW + 1 then
					result = result..weekDayBeginTag.."下周"..wday..weekDayEndTag.."<br>"
				else
					result = result..weekDayBeginTag.."较远"..weekDayEndTag.."<br>"
				end
			end
			
		end
		
		result = result..[[<a href = "advance?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">advance</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "postpone?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">postpone</a>&nbsp;&nbsp;]]
		result = result..[[<a href = "delete?sign=antihack&todoType=]]..content..[[&id=]]..v.Id..[[&remindTime=]]..v.RemindTime..[[&text=]]..text..[[">done</a>&nbsp;&nbsp;]]..text..[[<br>]]
	end
	
	result = result.."<br>"
	result = result..getBirthdayInfo(dayRange, LowTime, HighTime)
	
	-- local result = json.encode(showTbl)
	local body = httpIndex.SearchResultHead..result..httpIndex.SearchResultTail

	local head = {
		"Content-Type: text/html",
		}
	write(fd, 200, head, body)
end



-- Entry!
server.listen(":8090", function(fd, request, body)
	local c = dispatch[request.uri]
	if c then
		c(fd, request, body)
	else
		print("Unsupport uri", request.uri)
		write(fd, 404, {"Content-Type: text/plain"}, "404 Page Not Found")
	end
end)


console {
	addr = ":2323"
	}

