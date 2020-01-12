
local DateUtil = {}
DateUtil.__DebugFlag = false

function DateUtil:YangLi2NongLiDate(st)

	--天干名称
	local cTianGan = {"甲","乙","丙","丁","戊","己","庚","辛","壬","癸"}
	--地支名称
	local cDiZhi = {"子","丑","寅","卯","辰","巳","午", "未","申","酉","戌","亥"}
	--属相名称
	local cShuXiang = {"鼠","牛","虎","兔","龙","蛇", "马","羊","猴","鸡","狗","猪"}
	--农历日期名
	local cDayName =
	{
		"*","初一","初二","初三","初四","初五",
		"初六","初七","初八","初九","初十",
		"十一","十二","十三","十四","十五",
		"十六","十七","十八","十九","二十",
		"廿一","廿二","廿三","廿四","廿五",
		"廿六","廿七","廿八","廿九","三十"
	}
	--农历月份名
	local cMonName = {"*","正","二","三","四","五","六", "七","八","九","十","十一","腊"}

	--公历每月前面的天数
	local wMonthAdd = {0,31,59,90,120,151,181,212,243,273,304,334}
	-- 农历数据
	local wNongliData = {2635,333387,1701,1748,267701,694,2391,133423,1175,396438
	,3402,3749,331177,1453,694,201326,2350,465197,3221,3402
		,400202,2901,1386,267611,605,2349,137515,2709,464533,1738
		,2901,330421,1242,2651,199255,1323,529706,3733,1706,398762
		,2741,1206,267438,2647,1318,204070,3477,461653,1386,2413
		,330077,1197,2637,268877,3365,531109,2900,2922,398042,2395
		,1179,267415,2635,661067,1701,1748,398772,2742,2391,330031
		,1175,1611,200010,3749,527717,1452,2742,332397,2350,3222
		,268949,3402,3493,133973,1386,464219,605,2349,334123,2709
		,2890,267946,2773,592565,1210,2651,395863,1323,2707,265877}

	local wCurYear,wCurMonth,wCurDay;
	local nTheDate,nIsEnd,m,k,n,i,nBit;
	local szNongli, szNongliDay,szShuXiang;
	---取当前公历年、月、日---
	wCurYear = st.year
	wCurMonth = st.month
	wCurDay = st.day


	---计算到初始时间1921年2月8日的天数：1921-2-8(正月初一)---
	nTheDate = (wCurYear - 1921) * 365 + (wCurYear - 1921) / 4 + wCurDay + wMonthAdd[wCurMonth] - 38
	if (((wCurYear % 4) == 0) and (wCurMonth > 2)) then
		nTheDate = nTheDate + 1
	end


	--计算农历天干、地支、月、日---
	nIsEnd = 0;
	m = 0;
	while nIsEnd ~= 1 do
		if wNongliData[m+1] < 4095 then
			k = 11;
		else
			k = 12;
		end
		n = k;
		while n>=0 do
			--获取wNongliData(m)的第n个二进制位的值
			nBit = wNongliData[m+1];
			for i=1,n do
				nBit = math.floor(nBit/2);
			end

			nBit = nBit % 2;


			if nTheDate <= (29 + nBit) then
				nIsEnd = 1;
				break;
			end

			nTheDate = nTheDate - 29 - nBit;
			n = n - 1;
		end
		if nIsEnd ~= 0 then
			break;
		end
		m = m + 1;
	end

	wCurYear = 1921 + m
	wCurMonth = k - n + 1
	wCurDay = math.floor(nTheDate)
	if k == 12 then
		if wCurMonth == wNongliData[m+1] / 65536 + 1 then
			wCurMonth = 1 - wCurMonth;
		elseif wCurMonth > wNongliData[m+1] / 65536 + 1 then
			wCurMonth = wCurMonth - 1;
		end
	end
if self.__DebugFlag then
	print('农历', wCurYear, wCurMonth, wCurDay)
end
	--生成农历天干、地支、属相 ==> wNongli--
	szShuXiang = cShuXiang[(((wCurYear - 4) % 60) % 12) + 1]
	szNongli = szShuXiang .. '(' .. cTianGan[(((wCurYear - 4) % 60) % 10)+1] .. cDiZhi[(((wCurYear - 4) % 60) % 12) + 1] .. ')年'
	--szNongli,"%s(%s%s)年",szShuXiang,cTianGan[((wCurYear - 4) % 60) % 10],cDiZhi[((wCurYear - 4) % 60) % 12]);

	--生成农历月、日 ==> wNongliDay--*/
	if wCurMonth < 1 then
		szNongliDay =  "闰" .. cMonName[(-1 * wCurMonth) + 1]
	else
		szNongliDay = cMonName[wCurMonth+1]
	end

	szNongliDay =  szNongliDay .. "月" .. cDayName[wCurDay+1]
	return {year = wCurYear, month = wCurMonth, day = wCurDay}, szNongli .. szNongliDay
end

function DateUtil:GetNextMonth(date)
	if date.month >= 12 then
		return {year = date.year + 1, month = 1, day = date.day}
	end
	return {year = date.year , month = 1 + date.month, day = date.day}
end

function DateUtil:GetPreviousMonth(date)
	if date.month <= 1 then
		return {year = date.year - 1, month = 12, day = date.day}
	end
	return {year = date.year , month = date.month - 1, day = date.day}
end

function DateUtil:GetYangLiNextDay(date)
	local date2Time = os.time({year=date.year,month=date.month,day=date.day,hour=8,min=0,sec=0,isdst=false})
	return os.date("*t", date2Time + 24* 3600)
end

function DateUtil:IsSameDate(day1, day2, bIgnoreYear)
	if not bIgnoreYear then
		if day1.year ~= day2.year then return false end
	end
	if day1.month ~= day2.month then return false end
	if day1.day ~= day2.day then return false end

	return true
end

function DateUtil:IsBirthdayDateNear(yangLiTime, nongliDate2, bIgnoreYear, range)
	local base = yangLiTime
	if range == -1 then return true end
	for i = - range, range do
		local targetDayTime = base + i * 24 * 3600
		local targetDate = os.date("*t", targetDayTime)
		local targetNongli = self:YangLi2NongLiDate({year = targetDate.year, month = targetDate.month, day = targetDate.day})
		if self:IsSameDate(nongliDate2, targetNongli, true) then
			return true
		end
	end
end

-- 阳历和农历比较,第一个参数是阳历,1表示前面的大,0表示相等
function DateUtil:YangLiCompareNongLi(yDate, nDate)
	local y2n = self:YangLi2NongLiDate(yDate)
	if self:IsSameDate(y2n, nDate) then return 0 end

	if y2n.year > nDate.year then return 1 end
	if y2n.year < nDate.year then return -1 end

	if y2n.month > nDate.month then return 1 end
	if y2n.month < nDate.month then return -1 end

	if y2n.day > nDate.day then return 1 end
	return -1

end

function DateUtil:NongLi2ThisYearYangLi(target)
	local today = os.date("*t", os.time())

	local needed = {
		year = today.year,
		month = target.month,
		day = target.day,
		isleap = 0,
		isLeap = 0
	}
	return calender.lunartosolar(needed)
end

-- 农历转阳历
function DateUtil:NongLi2YangLiDate(target)

	if true then
		local needed = {
			year = target.year,
			month = target.month,
			day = target.day,
			isleap = 0
		}
		return calender.lunartosolar(needed)
	end
	-- 找到这个月的阳历月初
	local try = {year = target.year, month = target.month, day = 1}
	-- 阳历一般比农历往后延1个月
	try = self:GetNextMonth(try)

	if self:YangLiCompareNongLi(try, target) == 0  then return try end

	local yTest
	while self:YangLiCompareNongLi(try, target) == 1 do
if self.__DebugFlag then
		print("move to next month")
end
		try = self:GetPreviousMonth(try)
	end
	
	if self:YangLiCompareNongLi(try, target) == 0 then return try end
	
	yTest = try

	for i = 1, 62 do
		if self:YangLiCompareNongLi(yTest, target) == 0 then
			return yTest
		end
if self.__DebugFlag then
		print("move to next day")
end
		yTest = self:GetYangLiNextDay(yTest)
	end
if self.__DebugFlag then
	print("fail to find")
end
	return nil

end

function DateUtil:__test_entry(bOPenDebug)
	self.__DebugFlag = bOPenDebug
	local st = {}
	st.year = 2019
	st.month = 6
	st.day = 25
	self:YangLi2NongLiDate(st)
	
	
	local target = {year = 1992, month = 5, day = 23}
	local res = self:NongLi2YangLiDate(target)
	print("input is "..target.year,target.month,target.day,"\ntarget yangli is ", res.year, res.month, res.day)


end

return DateUtil

