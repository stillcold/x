local localConfig = require "LocalConfig"
local keywordDatabaseMgr = {}

function keywordDatabaseMgr:Add(item)
	
	PrintTable(item)
	local title = item.title or os.time()
	local parseRule = item.parseRule or 2
	local itemType = item.itemType or "text"
	local content = item.content
	local keyword = item.keyword
	
	local filePath = localConfig.HttpDir.."x_code_deploy_dir/keywords/"..title..".lua"
	local f = io.open(filePath, "w")
	local fileContent = 
[===[
local title = "]===]..title..[===[(Patch)"
local extra = {title = title, parseRule = ]===]..parseRule..[===[}

local keyWord2Answer = {
{
key = "]===]..keyword..[===[",
richTxt = [=[]===]..content..[===[
]=],
priority = 1000,
textType = "]===]..itemType..[===[",
},



}


return {keyWord2Answer,extra}
]===]
	f:write(fileContent)
	f:close()
	return "ok"
end

return keywordDatabaseMgr
