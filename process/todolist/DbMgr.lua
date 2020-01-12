local mysql = require "sys.db.mysql"
local json = require "sys/json"
local core = require "sys.core"

local DbMgr = {}

DbMgr.db = nil

function DbMgr:SelectTable()
	local db = mysql.create {
		host=core.envget("DbHost"),
		user=core.envget("DbUser"),
		password=core.envget("DbPass"),
	}
	db:connect()
	local status, res = db:query("show databases;")
	print("mysql show databases;", status)
	if not status then return end
	status, res = db:query("use todo;")
	print("use todo;", status)
	self.db = db
	return db
end

function DbMgr:InsertRecord(Id, RemindTime, AllProps, Name, FartherId, ChildId, BeginTime, EndTime)

	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	Id = Id or os.time()
	FartherId = FartherId or 0
	ChildId = ChildId or 0
	Name = Name or "name"
	RemindTime = RemindTime or os.time()
	BeginTime = BeginTime or os.time()
	EndTime = EndTime or os.time()
	AllProps = AllProps or "{}"

	local statement = string.format ("insert into todo (Id,FartherId,ChildId,Name,RemindTime,BeginTime,EndTime,AllProps) values (%.0f, %.0f, %.0f, '%s', %.0f, %.0f, %.0f, '%s')",Id,FartherId,ChildId,Name,RemindTime,BeginTime,EndTime,AllProps)

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)
	for k,v in pairs (res) do
		print(k,v)
	end
end

function DbMgr:GetRecordByRemindTimeRange(LowTime, HighTime)

	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	local statement = string.format ("select * from todo where RemindTime > %.0f and RemindTime < %0.f order by RemindTime asc",LowTime, HighTime)

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)
	
	return res
end

function DbMgr:DeleteRecordById(id)

	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	-- id = string.sub(id, 1, 10)

	print(id)

	if not id then return end

	local statement = string.format ("delete from todo where id = %s",id)

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)

	for k,v in pairs(res) do
		print(k,v)
	end
	
	return res
end

function DbMgr:PostponeRecordById(id, remindTime)

	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	-- id = string.sub(id, 1, 10)

	print(id)

	if not id then return end

	local statement = string.format ("update todo set RemindTime = %.0f where id = %s", (remindTime + 24 * 3600), id)

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)

	for k,v in pairs(res) do
		print(k,v)
	end
	
	return res
end

function DbMgr:AdvanceRecordById(id, remindTime)

	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	-- id = string.sub(id, 1, 10)

	print(id)

	if not id then return end

	local statement = string.format ("update todo set RemindTime = %.0f where id = %s", (remindTime - 24 * 3600), id)

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)

	for k,v in pairs(res) do
		print(k,v)
	end
	
	return res
end

function DbMgr:InsertBirthdayRecord(Name, AllProps)
	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	Name = Name or "name"
	AllProps = AllProps or "{}"

	local statement = string.format ("insert into birthday (Name,AllProps) values ('%s', '%s')",Name,AllProps)

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)
	for k,v in pairs (res) do
		print(k,v)
	end

end


function DbMgr:DeleteAllBirthdayRecord()
	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	local statement = string.format ("delete from birthday")

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)
	for k,v in pairs (res) do
		print(k,v)
	end

end

function DbMgr:GetAllBirthdayRecord()
	if not DbMgr.db or DbMgr.db.state ~= 1 then
		self:SelectTable()
	end

	local statement = string.format ("select * from birthday")

	print(statement)
	local status,res = self.db:query(statement)
	print(status, res)
	
	return res
end

return DbMgr
