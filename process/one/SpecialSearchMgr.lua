local WhereIsFood = require "WhereIsFood"

local SpecialSearchMgr = {}

function SpecialSearchMgr:WhereIsFood(toSearchTbl)
	return WhereIsFood:GetFood(toSearchTbl)
end

function SpecialSearchMgr:GetSpecialResult(toSearchTbl)
	local bMatched, specialResult
	for k,v in ipairs(toSearchTbl) do
		if string.find(v, "吃") then
			bMatched = true
			specialResult = self:WhereIsFood(toSearchTbl)
		end
	end

	if not specialResult then
		return false
	end

	return bMatched, specialResult.."<br>"
end

return SpecialSearchMgr
