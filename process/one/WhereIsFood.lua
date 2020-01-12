local WhereIsFood = {}

local foodTbl = {
	-- 权重, 名字, 距离, tag, 地点
	{90, "太二酸菜鱼", 3000,{"鱼","微辣","米饭","不拉肚子","好吃","优惠停车" },  "天街" },
	{90, "太和板面", 2000,{"面","不辣","不拉肚子" },  "小区东门" },
	{90, "耿记面馆", 1500,{"面","不辣","不拉肚子" },  "小区东门" },
	{80, "新农村土灶台", 1000,{"地锅鸡","微辣","不拉肚子","米饭" },  "小区东门" },
	{90, "御荣府", 6000,{"火锅","微辣","米饭","好吃","免费停车" },  "星光大道1期" },
	{80, "马路边边", 10000,{"冷锅串串","辣" },  "星耀城" },
	{80, "兰州拉面", 500,{"拉面"},  "小区东门" },
	{80, "三环路西", 3000,{"冷锅串串","辣","优惠停车","好吃" },  "天街" },
	{80, "老潼关肉夹馍", 2000,{"肉夹馍","不辣","凉皮" },  "滨兴东苑" },
	{80, "淮南牛肉汤", 2000,{"牛肉汤","不辣","饼" },  "滨兴东苑" },
	{70, "过桥米线", 7000,{"面","不辣","过桥米线" },  "滨康小区" },
	{80, "盘熟里炭火烤肉", 3000,{"烤肉","不辣","优惠停车","实惠" },  "天街" },
	{80, "亚萃", 3000,{"南洋菜","不辣","优惠停车","米饭","不拉肚子" },  "天街" },
	{70, "江边城外", 3000,{"烤鱼","不辣","优惠停车" },  "天街" },
	{70, "醉李白", 3000,{"川菜","优惠停车","好吃" },  "天街" },
	{70, "邓文琪小龙虾盖浇饭", 10000,{"外卖","小龙虾","好吃" },  "未知" },
	{70, "戒不了小龙虾", 500,{"烧烤","烤鱼","打折" },  "中南" },
	{80, "黄焖鸡米饭", 1000,{"外卖","鸡","实惠","米饭" },  "未知" },
}

function WhereIsFood:GetTagMatchFactor(toSearchTbl, tags)
	local matchCount = 0
	for _, tag in pairs(tags) do
		for __, kw in pairs(toSearchTbl) do
			if kw ~= "吃" then
				if string.find(tag, kw) then
					matchCount = matchCount + 1
				end
			end
		end
	end

	return matchCount
end

function WhereIsFood:GetDistanceWeight(toSearchTbl, distance)
	local p = 10000
	local distanceFactor = 0.01

	for k,v in pairs(toSearchTbl) do
		if string.find(v, "近") or string.find(v, "距离") then
			distanceFactor = 10
		end
	end

	return math.floor(p * distanceFactor / distance)
end

function WhereIsFood:IsRandom(toSearchTbl)
	for k,v in pairs(toSearchTbl) do
		if string.find(v, "随机") then
			return true
		end
	end
end

function WhereIsFood:GetFood(toSearchTbl)
	local ret = {}
	local adjustWeightTbl 	= {}
	for idx, data in pairs(foodTbl) do
		local baseWeight 	= data[1]
		local matchBase		= 100
		local tags 			= data[4]
		local name			= data[2]
		local location		= data[5]
		local distance		= data[3]
		local distanceWeight= self:GetDistanceWeight(toSearchTbl, distance)
		local matchFactor 	= self:GetTagMatchFactor(toSearchTbl, tags)
		local matchWeight 	= matchFactor * matchBase
		local adjustWeight 	= baseWeight + matchWeight + distanceWeight
		local isRandom		= self:IsRandom(toSearchTbl)
		if isRandom then
			adjustWeight = math.random(1, 100)
		end
		print(data[2], adjustWeight, matchFactor)
		local toShowTxt 	= "<em>"..name.."</em>,&nbsp&nbsp距离"..distance.."米,&nbsp位于"..location.."&nbsp标签:<b>"..table.concat(tags, ",").."</b>&nbsp".."总权重:<b>"..adjustWeight.."</b>,基础权重"..baseWeight.."匹配权重"..matchWeight.."距离权重"..distanceWeight
		table.insert(adjustWeightTbl, {adjustWeight, toShowTxt})
	end

	table.sort(adjustWeightTbl, function(a, b)
		if a[1] > b[1] then
			return true
		end
	end)

	for i = 1,3 do
		local info = adjustWeightTbl[i]
		if not info then break end

		table.insert(ret, info[2])
	end

	return table.concat(ret, "<br>")
end

return WhereIsFood
