local db = require "DbMgr"
local dateUtil = require "utils/dateutil"
local core = require "sys.core"
local crypt = require "sys.crypt"
local json = require "sys.json"

local mindmapKey2Id = {}
local subId = 0
local loadAllMindmap = 0

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

local function QueryOneMindmapRecordByKey(key)

	local childrenNameTbl = {}
	local detail = "详细内容"
	local category = "分类"
	local children
	
	local id = mindmapKey2Id[key]
	if not id then
		return {key = key, detail = detail, category = category, children = childrenNameTbl}
	end
	
	if id then
		local queryResult = db:GetMindmapById(id)
		PrintTable(queryResult)

		local childStr = queryResult[1].Children
		local propStr = queryResult[1].ExtendProps
		children = json.decode(childStr) or {}
		local props = json.decode(propStr) or {}

		print("debug children", childStr)
		PrintTable(children)
		PrintTable(json.decode(json.encode({})))

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

	if loadAllMindmap == 0 then
		loadAllMindmap = 1
		local queryResult = db:GetAllMindmap()
		for k,v in pairs(queryResult) do
			local id = v.Id
			local keyStr = v.Name
			mindmapKey2Id[keyStr] = id
		end
	end

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

	local children = {}
	local result = {key = key, detail = discription, category = category, children = children}


	local childrenStr = json.encode(children)
	local propStr = json.encode({category = category})
	local id = GenUUId()

	print("newid", id)

	db:AddNewMindmap(id, key, discription, childrenStr, propStr)

	Gas2Gac:ReplyMindMap(fd, result)
end


function Gac2Gas:RequestGetMinmapForEdit(fd, args)
	
	print("handle rpc RequestGetMinmapForEdit...")

	PrintTable(args)

	local key = args.key
	local result = QueryOneMindmapRecordByKey(key)

	Gas2Gac:ReplyMindMapForEdit(fd, result)
end

function Gac2Gas:RequestMinmapAddChild(fd, args)
	
	print("handle rpc RequestMinmapAddChild...")
	local key = args.key
	local discription = args.discription
	local category = args.category

	local newChild = args.newChild
	local id =  mindmapKey2Id[newChild] or GenUUId()

	local fatherId = mindmapKey2Id[key]
	if fatherId then
		print("get fatherid")
		local queryResult = db:GetMindmapById(fatherId)
		if queryResult and queryResult[1] then
			local childStr = queryResult[1].Children
			local childrenIdTbl = json.decode(childStr) or {}
			table.insert(childrenIdTbl, id)
			print("try to update children")
			db:MindmapAddChildById(fatherId, json.encode(childrenIdTbl))
		end
	end

	if not mindmapKey2Id[newChild] then
		db:AddNewMindmap(id, newChild, key.."的子节点之一", json.encode({}), json.encode({category = category}))
	end

	local result = QueryOneMindmapRecordByKey(key)

	Gas2Gac:ReplyMindMap(fd, result)
end


