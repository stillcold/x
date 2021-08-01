local db = require "DbMgr"
local json = require "sys/json"
local core = require "sys.core"

core.start(function()

	local wholeRecord = {
	
{date = "1989-1-7", isYangLi = true, name = "孙恬"},
{date = "2000-1-20", isYangLi = true, name = "钟克顺"},
{date = "1990-1-14", isYangLi = false, name = "黄思瑶"},
{date = "1990-1-15", isYangLi = false, name = "易路宇"},
{date = "1989-1-16", isYangLi = false, name = "尹素芳"},
{date = "1989-1-17", isYangLi = false, name = "邹丽颖"},
{date = "2000-2-29", isYangLi = true, name = "李文雄"},
{date = "2000-3-23", isYangLi = true, name = "朱德龙"},
{date = "2000-3-26", isYangLi = true, name = "杨波"},
{date = "2000-3-31", isYangLi = true, name = "罗江"},
{date = "1989-4-21", isYangLi = true, name = "范高忻"},
{date = "2000-4-23", isYangLi = true, name = "类红瑞"},
{date = "1989-4-23", isYangLi = true, name = "钱勤"},
{date = "1961-03-10", isYangLi = false, name = "老爸"},
{date = "1989-4-3", isYangLi = false, name = "向敏"},
{date = "2000-5-14", isYangLi = true, name = "罗慧"},
{date = "1989-7-7", isYangLi = false, name = "刘烨"},
{date = "1989-9-2", isYangLi = true, name = "吴蓉"},
{date = "1989-9-4", isYangLi = true, name = "陈晨"},
{date = "1989-7-24", isYangLi = false, name = "王超越"},
{date = "2000-8-1", isYangLi = false, name = "刘静"},
{date = "2000-10-01", isYangLi = true, name = "朱晓庆"},
{date = "2000-10-10", isYangLi = true, name = "张骏"},
{date = "1987-8-28", isYangLi = false, name = "王逵"},
{date = "1989-9-3", isYangLi = false, name = "李婷"},
{date = "1986-10-23", isYangLi = true, name = "高大兵"},
{date = "1990-10-24", isYangLi = true, name = "颜文静"},
{date = "1989-9-25", isYangLi = false, name = "钱菁菁"},
{date = "2000-10-07", isYangLi = false, name = "老妈"},
{date = "1987-11-16", isYangLi = true, name = "戴赛楠"},
{date = "2000-12-3", isYangLi = true, name = "王晨"},
{date = "1989-12-10", isYangLi = true, name = "肖葱葱"},

	}
	
	db:DeleteAllBirthdayRecord()
	for _,record in pairs(wholeRecord) do
		db:InsertBirthdayRecord(record.name, json.encode(record))
	end
	

end)



