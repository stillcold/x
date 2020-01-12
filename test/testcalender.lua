
local solarC = calender.solartolunar({
	year = 2019,
	month = 10,
	day = 21,
})

print(solarC.year, solarC.month, solarC.day, solarC.isLeap)

local lunarC = calender.lunartosolar({
	year = 1989,
	month = 9,
	day = 25,
	isLeap = 0,
})

print(lunarC.year, lunarC.month, lunarC.day)
