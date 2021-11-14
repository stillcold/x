local db = require "DbMgr"
local dateUtil = require "utils/dateutil"
local core = require "sys.core"
local crypt = require "sys.crypt"
local json = require "sys.json"

local mindmapKey2Id = {}
local mindmap2Father = {}
local subId = 0
local loadAllMindmap = 0
local mindmapMainKey = "最近"

local loadAllHealth = 0
local healthRecord = {}


local function GenUUId(typefiled)
	local UUID_PACK_FORMAT = "bHbLI"

	subId = subId + 1
	if subId >= 2^10 then
		subId = 1
	end

	local typefiled = typefiled or 127
	local serverId = 12345
	local processId = 127
	local timestamp = os.time()
	local bin = string.pack(UUID_PACK_FORMAT, typefiled, serverId, processId, timestamp, subId)
	local uuid = crypt.base64encode(bin)
	print(uuid)
	return uuid
end

function Gac2Gas:RequestGetRecentTaskAndBirthday(fd, args)

	print("handle rpc...")

	local rangeBegin = args.rangeBegin
	local rangeEnd = args.rangeEnd

	if not rangeBegin then
		core.log("invalid data detected")
		return
	end

	local todo = {}
	local birthday = {}

	local queryResult = db:GetRecordByRemindTimeRange(rangeBegin, rangeEnd)

	local today = os.date("*t")

	for k,v in pairs (queryResult or {}) do
		local jsonStr   = v.AllProps
		local jsonTbl   = json.decode(jsonStr)
		local text      = jsonTbl.content
		local pin       = jsonTbl.pin
		local color		= jsonTbl.color
		local remindTime = v.RemindTime
		local t = os.date("*t", remindTime)
		local dateForCompare = os.time({year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0})
		table.insert(todo, {content = text, pin = pin, date = dateForCompare, realTime = remindTime, finished = v.Finished, color = color})
	end

	core.log("handle todo done, prepare to handle birthday...")

	queryResult = db:GetAllBirthdayRecord(rangeBegin, rangeEnd)

	for k,v in pairs (queryResult or {}) do
		core.log("one birthday record", v.Name)
		local jsonStr = v.AllProps
		local jsonTbl = json.decode(jsonStr)
		core.log(v.Name, jsonTbl.date)
		local year, month, day = string.match(jsonTbl.date or "", "(%d+)[^%d]+(%d+)[^%d]+(%d+)")
		local isYangLi = jsonTbl.isYangLi
		year    = tonumber(today.year)
		month   = tonumber(month)
		day     = tonumber(day)
		local birthdayDate = {year = year, month = month, day = day}
		local birthDayYangLiDate

		if isYangLi == false or isYangLi == "false" then
			birthDayYangLiDate = dateUtil:NongLi2ThisYearYangLi(birthdayDate)
		else
			birthDayYangLiDate = birthdayDate
		end
		birthDayYangLiDate.hour = 0
		birthDayYangLiDate.min = 0
		birthDayYangLiDate.sec = 0

		-- PrintTable(birthDayYangLiDate)
		local date = os.time(birthDayYangLiDate)

		table.insert(birthday, {name = v.Name, date = date})
	end

	core.log("all data selected from db done...")

	local data = {
		todo = todo,
		birthday = birthday,
	}

	core.log("ready to send rpc")

	Gas2Gac:ReplyRecentTaskAndBrithday(fd, data)
end

local function QueryDailyTaskAndBirthdayAndSync(fd, day, rangeBegin, rangeEnd)
	local todo = {}
	local birthday = {}

	local queryResult = db:GetRecordByRemindTimeRange(rangeBegin, rangeEnd)

	local today = os.date("*t")

	for k,v in pairs (queryResult or {}) do
		local jsonStr   = v.AllProps
		local jsonTbl   = json.decode(jsonStr)
		local text      = jsonTbl.content
		local pin       = jsonTbl.pin
		local color		= jsonTbl.color
		local remindTime = v.RemindTime
		local t = os.date("*t", remindTime)
		local dateForCompare = os.time({year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0})
		table.insert(todo, {id = v.Id, content = text, pin = pin, date = dateForCompare, realTime = remindTime, finished = v.Finished, color = color})
	end

	core.log("handle todo done, prepare to handle birthday...")

	queryResult = db:GetAllBirthdayRecord(rangeBegin, rangeEnd)

	for k,v in pairs (queryResult or {}) do
		core.log("one birthday record", v.Name)
		local jsonStr = v.AllProps
		local jsonTbl = json.decode(jsonStr)
		core.log(v.Name, jsonTbl.date)
		local year, month, day = string.match(jsonTbl.date or "", "(%d+)[^%d]+(%d+)[^%d]+(%d+)")
		local isYangLi = jsonTbl.isYangLi
		year    = tonumber(today.year)
		month   = tonumber(month)
		day     = tonumber(day)
		local birthdayDate = {year = year, month = month, day = day}
		local birthDayYangLiDate

		if isYangLi == false or isYangLi == "false" then
			birthDayYangLiDate = dateUtil:NongLi2ThisYearYangLi(birthdayDate)
		else
			birthDayYangLiDate = birthdayDate
		end
		birthDayYangLiDate.hour = 0
		birthDayYangLiDate.min = 0
		birthDayYangLiDate.sec = 0

		-- PrintTable(birthDayYangLiDate)
		local date = os.time(birthDayYangLiDate)

		table.insert(birthday, {name = v.Name, date = date})
	end

	core.log("all data selected from db done...")

	local data = {
		todo = todo,
		birthday = birthday,
		day = day,
	}

	core.log("ready to send rpc")

	Gas2Gac:ReplyDailyTaskAndBirthday(fd, data)

end

function Gac2Gas:RequestDailyTaskAndBirthday(fd, args)
	
	print("handle rpc...")
	
	local targetDay = args.day
	local rangeBegin = targetDay - 24*3600
	local rangeEnd = targetDay + 24*3600

	QueryDailyTaskAndBirthdayAndSync(fd, targetDay, rangeBegin, rangeEnd)
end

function Gac2Gas:RequestPostponeTaskByIdFromDaily(fd, args)
	
	print("handle rpc RequestPostponeTaskByIdFromDaily...")

	PrintTable(args)

	local targetDay = args.day
	local rangeBegin = targetDay - 24*3600
	local rangeEnd = targetDay + 24*3600
	local id = args.id
	local lastTime = args.lastTime

	print("args check", id, lastTime)

	db:PostponeRecordById(id, lastTime)

	QueryDailyTaskAndBirthdayAndSync(fd, targetDay, rangeBegin, rangeEnd)
end

function Gac2Gas:RequestAdvanceTaskByIdFromDaily(fd, args)
	
	print("handle rpc RequestAdvanceTaskByIdFromDaily...")

	PrintTable(args)

	local targetDay = args.day
	local rangeBegin = targetDay - 24*3600
	local rangeEnd = targetDay + 24*3600
	local id = args.id
	local lastTime = args.lastTime

	print("args check", id, lastTime)

	db:AdvanceRecordById(id, lastTime)

	QueryDailyTaskAndBirthdayAndSync(fd, targetDay, rangeBegin, rangeEnd)
end

function Gac2Gas:RequestDeleteTaskByIdFromDaily(fd, args)
	
	print("handle rpc RequestAdvanceTaskByIdFromDaily...")

	PrintTable(args)

	local targetDay = args.day
	local rangeBegin = targetDay - 24*3600
	local rangeEnd = targetDay + 24*3600
	local id = args.id

	print("args check", id)

	db:DeleteRecordById(id)

	QueryDailyTaskAndBirthdayAndSync(fd, targetDay, rangeBegin, rangeEnd)
end

function Gac2Gas:RequestSetTaskFinishedStatus(fd, args)
	
	print("handle rpc RequestSetTaskFinishedStatus...")

	PrintTable(args)

	local targetDay = args.day
	local rangeBegin = targetDay - 24*3600
	local rangeEnd = targetDay + 24*3600
	local id = args.id
	local finished = args.finished

	print("args check", id, finished)

	db:MarkRecordFinishedStaus(id, finished)

	-- QueryDailyTaskAndBirthdayAndSync(fd, targetDay, rangeBegin, rangeEnd)
end

function Gac2Gas:RequestAddRecord(fd, args)
	
	print("handle rpc RequestAddRecord...")

	PrintTable(args)

	local remindTime = args.remindTime or os.time()
	local name = "from app"
	local extra = args.extra
	extra.tag = extra.tag or "todoD"
	extra.pin = extra.pin or 0
	extra.content = extra.content or args.content
	
	local jsonStr = json.encode(extra)
	print("args check", id, jsonStr)

	local Id = nil

	db:InsertRecord(Id, remindTime, jsonStr, name)

end

local function CheckPreloadAllMindMap()
	if loadAllMindmap == 0 then
		loadAllMindmap = 1
		local queryResult = db:GetAllMindmap()
		for k,v in pairs(queryResult) do
			local id = v.Id
		
			local childStr = v.Children
			local children = json.decode(childStr) or {}

			local keyStr = v.Name
			mindmapKey2Id[keyStr] = id

			print("father", keyStr, "children", childStr)

			for k,childId in ipairs(children) do
				if childId then
					local queryResultSub = db:GetMindmapById(childId)
					if queryResultSub and queryResultSub[1] then
						mindmap2Father[queryResultSub[1].Name] = keyStr
						print("child", queryResultSub[1].Name, "father", keyStr)
					end
				end	
			end
		end
	end

	print("打印子节点到父节点的映射")
	PrintTable(mindmap2Father)
end

local function QueryOneMindmapRecordByKey(key)

	local childrenNameTbl = {}
	local detail = "没有找到记录"
	local category = "无"
	local children
	local default = {key = key, detail = detail, category = category, children = childrenNameTbl}
	
	local id = mindmapKey2Id[key]
	if not id then
		return default
	end
	
	if id then
		local queryResult = db:GetMindmapById(id)
		PrintTable(queryResult)

		if not queryResult or not queryResult[1] then
			return default
		end

		local childStr = queryResult[1].Children
		local propStr = queryResult[1].ExtendProps
		children = json.decode(childStr) or {}
		local props = json.decode(propStr) or {}

		detail = queryResult[1].Discription
		category = props.category or ""

		for k,childId in ipairs(children) do
			if childId then
				local queryResultSub = db:GetMindmapById(childId)
				if queryResultSub and queryResultSub[1] then
					table.insert(childrenNameTbl, queryResultSub[1].Name)
				end
			end	
		end
	end

	local result = {key = key, detail = detail, category = category, children = childrenNameTbl}
	return result, children
end

function Gac2Gas:RequestGetMinmap(fd, args)
	
	print("handle rpc RequestGetMinmap...")

	PrintTable(args)

	CheckPreloadAllMindMap()

	local key = args.key
	local result = QueryOneMindmapRecordByKey(key)

	Gas2Gac:ReplyMindMap(fd, result)
end

function Gac2Gas:RequestGetUIToWorldScale(fd, args)
	
	print("handle rpc RequestGetUIToWorldScale...")

	local result = {
		UIToWolrdBaseX = 0,
		UIToWolrdBaseY = -0.2,
		UIToWorldscale = 1.5,
		mindmapBaseX = -370,
		mindmapBaseY = 0,
		mindmapScale = 1.5
	}

	Gas2Gac:ReplyUIToWorldScale(fd, result)
end

function Gac2Gas:RequestAddMindmap(fd, args)
	
	print("handle rpc RequestAddMindmap...")
	local key = args.key
	local discription = args.discription
	local category = args.category

	CheckPreloadAllMindMap()

	if mindmapKey2Id[key] then
		return
	end

	local children = {}
	local result = {key = key, detail = discription, category = category, children = children}


	local childrenStr = json.encode(children)
	local propStr = json.encode({category = category})
	local id = GenUUId()
	mindmapKey2Id[key] = id

	print("newid", id)

	db:AddNewMindmap(id, key, discription, childrenStr, propStr)

	Gas2Gac:ReplyMindMap(fd, result)
end


function Gac2Gas:RequestGetMinmapForEdit(fd, args)
	
	print("handle rpc RequestGetMinmapForEdit...")

	PrintTable(args)

	CheckPreloadAllMindMap()

	local key = args.key
	local result = QueryOneMindmapRecordByKey(key)

	Gas2Gac:ReplyMindMapForEdit(fd, result)
end

function Gac2Gas:RequestMinmapAddChild(fd, args)
	
	print("handle rpc RequestMinmapAddChild...")
	local key = args.key
	local discription = args.discription
	local category = args.category
	local newKey = args.newKey

	PrintTable(args)

	if not newKey then newKey = key end

	local newChild = args.newChild
	local childId
	if newChild then
		childId =  mindmapKey2Id[newChild] or GenUUId()
	end

	CheckPreloadAllMindMap()

	local fatherId = mindmapKey2Id[key]
	if fatherId then
		if newKey ~= key then
			mindmapKey2Id[newKey] = fatherId
			mindmapKey2Id[key] = nil
			mindmap2Father[newKey] = mindmap2Father[key]
			mindmap2Father[key] = nil
			
			for k,v in pairs(mindmap2Father) do
				if v == key then
					mindmap2Father[k] = newKey
				end
			end
		end

		print("get fatherid")
		local queryResult = db:GetMindmapById(fatherId)
		if queryResult and queryResult[1] then
			local childStr = queryResult[1].Children
			local childrenIdTbl = json.decode(childStr) or {}
			if newChild then
				local alreadyIn = false
				for i,v in ipairs(childrenIdTbl) do
					if v == childId then
						alreadyIn = true
						break
					end
				end
				if not alreadyIn then
					table.insert(childrenIdTbl, childId)
					mindmap2Father[newChild] = newKey
				end
			end
			print("try to update everything")
			db:MindmapAddChildById(fatherId, newKey, json.encode(childrenIdTbl), discription, json.encode({category = category}))
		end
	end

	if newChild and not mindmapKey2Id[newChild] then
		mindmapKey2Id[newChild] = childId
		db:AddNewMindmap(childId, newChild, newKey.."的子节点之一", json.encode({}), json.encode({category = category}))
	end

	local result = QueryOneMindmapRecordByKey(newKey)

	Gas2Gac:ReplyMindMap(fd, result)
end

function Gac2Gas:RequestGetUpLevelMinmap(fd, args)
	
	print("handle rpc RequestGetUpLevelMinmap...")

	PrintTable(args)

	CheckPreloadAllMindMap()

	local key = args.key
	local fatherKey = mindmap2Father[key]
	if not fatherKey then
		Gas2Gac:ShowMessage(fd, {message = "没有找到父节点"})
		return
	end

	local result = QueryOneMindmapRecordByKey(fatherKey)

	Gas2Gac:ReplyMindMap(fd, result)
end

function Gac2Gas:RequestDelChild(fd, args)
	
	print("handle rpc RequestDelChild...")

	PrintTable(args)

	local key = args.key
	local child = args.child

	CheckPreloadAllMindMap()

	local fatherId = mindmapKey2Id[key]
	local childId = mindmapKey2Id[child]

	if fatherId and childId then
		
		local queryResult = db:GetMindmapById(fatherId)
		if queryResult and queryResult[1] then
			local childStr = queryResult[1].Children
			local childrenIdTbl = json.decode(childStr) or {}
			local isIn = false
			for i,v in ipairs(childrenIdTbl) do
				if v == childId then
					isIn = true
					table.remove(childrenIdTbl, i)
					break
				end
			end

			if isIn then
				print("try to update children")
				db:MindmapUpdateChildById(fatherId, json.encode(childrenIdTbl))
			end
		end
	end

	local result = QueryOneMindmapRecordByKey(key)

	Gas2Gac:ReplyMindMapForEdit(fd, result)
	-- Gas2Gac:ShowMessage(fd, {message = "删除子节点成功"})
end

function Gac2Gas:RequestDelRoot(fd, args)
	
	print("handle rpc RequestDelRoot...")

	PrintTable(args)

	CheckPreloadAllMindMap()

	local key = args.key

	
	local fatherId = mindmapKey2Id[key]

	if fatherId then
		
		local queryResult = db:GetMindmapById(fatherId)
		if queryResult and queryResult[1] then
			local childStr = queryResult[1].Children
			local childrenIdTbl = json.decode(childStr) or {}
			local childCout = 0
			for i,v in ipairs(childrenIdTbl) do
				childCout = childCout + 1
			end

			if childCout > 0 then
				Gas2Gac:ShowMessage(fd, {message = "子节点不止一个，不能删除根节点"})
				return
			end

			db:MindmapDelById(fatherId)
			mindmapKey2Id[key] = nil
		end
	end

	local result = QueryOneMindmapRecordByKey(mindmapMainKey)
	if not result then
		return
	end

	Gas2Gac:ReplyMindMap(fd, result)
end

function Gac2Gas:RequestSearchMindmap(fd, args)
	
	print("handle rpc RequestSearchMinmap...")

	PrintTable(args)

	CheckPreloadAllMindMap()

	local key = args.key
	local result = QueryOneMindmapRecordByKey(key)

	Gas2Gac:ReplyMindMap(fd, result)
end

local function CheckAndLoadAllHealth()

	if loadAllHealth == 0 then
		healthRecord = {}
		local res = db:LoadAllHealthRecord()
		if res then
			for k,v in pairs(res) do
				local healthRecordStr = v.Props
				if #healthRecordStr <= 0 then
					healthRecord = {}
					break
				end
				local healthRecord = json.decode(healthRecordStr) or {}
				break
			end
		end
		loadAllHealth = 1
	end

	local nowTime = os.time()
	for timestamp, flag in pairs(healthRecord) do
		if nowTime - timestamp > 7*24*3600 then
			healthRecord[timestamp] = nil
		end
	end

end

function Gac2Gas:RequestGetRecentHealthRecord(fd, args)
	
	CheckAndLoadAllHealth()
	print("send rpc")
	Gas2Gac:SyncRecentHealthRecord(fd, healthRecord or {})
end

function Gac2Gas:RequestSetHealth(fd, args)
	local timestamp = args.timestamp
	local flag = args.flag

	CheckAndLoadAllHealth()
	local nowtime = os.time()

	if flag and flag ~= 0 and flag ~= 1 then
		return
	end

	local t = os.date("*t", timestamp)
	local dayBegin = os.time({year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0})
	if nowtime - dayBegin > 7*24*3600 then
		Gas2Gac:ShowMessage(fd, {message = "超过时间范围了"})
		return
	end

	dayBegin = tostring(dayBegin)
	if not flag then
		flag = 0
		local original = healthRecord[dayBegin] or 0
		if original == 0 then
			flag = 1
		end
	end

	print("flag is", flag)
	print("dayBegin is", dayBegin)

	healthRecord[dayBegin] = flag

	local id = 1
	local props = json.encode(healthRecord or {})

	print("id", id, "props", props)

	db:SetHealthRecord(id, props)

	print("after set db")

	Gas2Gac:SyncRecentHealthRecord(fd, healthRecord or {})
end

function Gac2Gas:RequestAddDiary(fd, args)
	local timestamp = args.timestamp
	local tag = args.tag
	local content = args.content

	db:AddNewDiary(tag, content, timestamp)

	Gas2Gac:ShowMessage(fd, {message = "新增成功"})
end

function Gac2Gas:QueryWeeklyReport(fd, args)
	local endTime = args.timestamp
	local tag = args.tag

	local result = db:QueryWeeklyReport(tag, endTime)
	local diarys = {}

	for id, diaryTbl in pairs(result) do
		local timeForShow = os.date("*t", diaryTbl.timeflag)
		local timeStr = timeForShow.year.."年"..timeForShow.month.."月"..timeForShow.day.."日 "..timeForShow.hour..":"..timeForShow.min
		diarys[id] = {content = diaryTbl.content, tag = diaryTbl.tag, timeForShow = timeStr}
	end

	Gas2Gac:SyncQueryWeeklyReport(fd, diarys or {})
end
