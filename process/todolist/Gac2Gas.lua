local db = require "DbMgr"
local dateUtil = require "utils/dateutil"
local core = require "sys.core"
local json = require "sys.json"

function Gac2Gas:RequestGetRecentTask(fd, args)

	print("handle rpc...")
	
	local rangeBegin = args.rangeBegin
	local rangeEnd = args.rangeEnd

	local todo = {}
	local birthday = {}

	local queryResult = db:GetRecordByRemindTimeRange(rangeBegin, rangeEnd)

	local today = os.date("*t", nowTime)

	for k,v in pairs (queryResult or {}) do
		local jsonStr   = v.AllProps
		local jsonTbl   = json.decode(jsonStr)
		local text      = jsonTbl.content
		local pin       = jsonTbl.pin
		local remindTime = v.RemindTime
		local t = os.date("*t", remindTime)
		local dateForCompare = os.time({year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0})
		table.insert(todo, {content = text, pin = pin, date = dateForCompare})
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

	-- SendRpc(fd, "ReplyRecentTask", data)	
	Gas2Gac:ReplyRecentTask(fd, data)
end

function Gac2Gas:RequestInitRecommend(fd, context)

	local firstName = context.input
	if #firstName <= 0 then
		firstName = "赵"
	end

	local result = {
		{-360,0,firstName.."锄"},
		{-180,0,firstName.."禾"},
		{0,0,firstName.."日"},
		{180,0,firstName.."当"},
		{360,0,firstName.."午"},
	}

	SendRpc(fd, "SyncRecommendName", result)
end

