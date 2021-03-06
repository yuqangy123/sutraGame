

local UserData = class("UserData")

local cacheToServerData = {}

function UserData:ctor( ... )
    
    self:init()

end



function UserData:init( ... )
	--[[self.songDay = CacheUtil:getCacheVal(CacheType.songDay)
		
	--我的物品
	self.toolList = CacheUtil:getCacheVal(CacheType.tools)
	
	
	
	self.buddhasLightLevel = CacheUtil:getCacheVal(CacheType.buddhasLightLevel)
	
	if self.buddhasLightLevel == 0 then
		self.buddhasLightLevel = 1
		CacheUtil:setCacheVal(CacheType.buddhasLightLevel, self.buddhasLightLevel)
	end
	
	self.birthday = CacheUtil:getCacheVal(CacheType.birthday)
	if self.birthday == 0 then
		self.birthday = os.time()
		CacheUtil:setCacheVal(CacheType.birthday, self.birthday)
	end
	
	self.buddhasLightDay = CacheUtil:getCacheVal(CacheType.buddhasLightDay)
	if self.buddhasLightDay == 0 then 
		self.buddhasLightDay = os.time()
		CacheUtil:setCacheVal(CacheType.buddhasLightDay, self.buddhasLightDay)
	end
	
	--解析我的物品数据
	local tools = string.split(self.toolList, ",")
	self.toolList = {}
	for k,v in pairs(tools) do 
		local tool = string.split(v, ":")
		self.toolList[tostring(tool[1])] = tonumber(tool[2])
	end--]]

	self:setToday(os.time())
		
	self.buddhasLightLevel = 3--佛光定为3级
	
	--改成只有一种木鱼
	self.usedTool = "1"
	
	--界面显示的佛祖
	self.buddhasId = CacheUtil:getCacheVal(CacheType.buddhasId)
	
	
	
	--local incenseLastDate1 = self:getDayByTime(1524058749)
	
	
	--[[self.songCount = 0	
	self.songContinueCount = 0	
	self.signCount = 0
	self.signContinueCount = 0--]]
	
	--当前选中的佛经
	self.selectSongId = CacheUtil:getCacheVal(CacheType.selectSongId)
	
	--净土已打开数据
	self.jingtuOpenData = CacheUtil:getCacheVal(CacheType.jingtuOpenData)
	
	--综合排名
	self.totalRank = CacheUtil:getCacheVal(CacheType.totalRank)
	
	
	--上香
	self.censerNum = CacheUtil:getCacheVal(CacheType.censerNum)
	self.censerRank = CacheUtil:getCacheVal(CacheType.censerRank)
	self.incenseLastTime = CacheUtil:getCacheVal(CacheType.incenseLastTime)
	local incenseLastDate = self:getDayByTime(self.incenseLastTime)
	self.todayCanIncense = true
	--self.todayCanIncense = (incenseLastDate.year ~= self.today.year and incenseLastDate.month ~= self.today.month and incenseLastDate.day ~= self.today.day)
	
	
	--签到数据
	self.signLine = CacheUtil:getCacheVal(CacheType.signLine)
	self.signDay = CacheUtil:getCacheVal(CacheType.signDay)
	self.signNum = CacheUtil:getCacheVal(CacheType.signNum)
	self.signRank = CacheUtil:getCacheVal(CacheType.signRank)
	self.todayCanSign = true
	self.monthWeekDay = {}
	self:calcSign()
	
	--诵经
	self.sutraNum = CacheUtil:getCacheVal(CacheType.sutraNum)
	self.sutraRank = CacheUtil:getCacheVal(CacheType.sutraRank)
	self.sutraLastTime = CacheUtil:getCacheVal(CacheType.sutraLastTime)
	self.todayCanSong = true
	self:calcTodayCanSong(self.sutraLastTime)
	
	--莲花数量
	self.lotusNum = CacheUtil:getCacheVal(CacheType.lotusNum)
	
	
	
	
	self:loadMusicRhythmData()
end

function UserData:saveUseTool( val )
	self.usedTool = tostring(val)
	self.usedTool = "1"--改成只有一种木鱼
	CacheUtil:setCacheVal(CacheType.usedTool, self.usedTool)
end

--所有保存数据的时间点以server下发的servertime为准，client算好上传
--保存登录数据
function UserData:saveSignData( ... )
	
	
	--同步到服务器
	local signLine = CGame:bitOperate(2, self.signLine, CGame:bitOperate(5, self.today.day-1, 1))
	self.signLine = signLine
	CacheUtil:setCacheVal(CacheType.signLine, self.signLine)
	networkControl:sendMessage("updateUserData", {type="signLine", data=signLine, ostime=self.ostime, isSync=false})
	localCacheServerCtrl:addCache("signLine", {signLine=signLine, time=self.ostime})
end

--保存点香数据
function UserData:saveIncenseData( ... )
	self.incenseLastTime = self.ostime
	CacheUtil:setCacheVal(CacheType.incenseLastTime, self.incenseLastTime)
	networkControl:sendMessage("updateUserData", {type="censerNum", data="", ostime=self.ostime, isSync=false})
	localCacheServerCtrl:addCache("censerNum", {time=self.ostime})
end

--保存诵经数据
function UserData:saveSongData( id, score, clickCount )
	self.sutraLastTime = self.ostime
	local data = id..":"..score .. "," .. clickCount
	networkControl:sendMessage("updateUserData", {type="songScore", data=data, ostime=self.ostime, isSync=false})
	localCacheServerCtrl:addCache("songScore", {songData=data, time=self.ostime})
end

--计算登录数据
function UserData:calcSign( ... )
	local signDay = self.signDay
	
	if not self.signDay[self.today.year] then self.signDay[self.today.year] = {} end
	if not self.signDay[self.today.year][self.today.month] then
		self.signDay[self.today.year][self.today.month] = {}
		for i=1, 31 do self.signDay[self.today.year][self.today.month][i] = false end
	end
	
	--當月
	self.todayCanSign = true
	for i=1, 31 do
		local dayTime = self:getTimeByDay(self.today.year, self.today.month, i)
		if not dayTime then
			break
		end
		
		local day = self:getDayByTime(dayTime)
		
		local sign = false
		if signDay[day.year] and signDay[day.year][day.month] and signDay[day.year][day.month][day.day] then--是否簽到
			if day.year == self.today.year and day.month == self.today.month and day.day == self.today.day then
				self.todayCanSign = false
			end
			sign = true
		else
		end
		self.monthWeekDay[i] = {wday = (day.wday==1) and 7 or day.wday-1, sign=sign}--星期天为1
	end
	
	
	--登錄累計
	self.signCount = 0
	for y,yd in pairs(signDay) do
		for m,md in pairs(yd) do
			for d,dd in pairs(md) do
				if dd then self.signCount = self.signCount + 1 end
			end
		end
	end
	
	--连续登录
	self.signContinueCount = 0
	local curTime = self:getDayNoByTime( self.ostime )
	local ondayTime = 60*60*24
	while true do
		local tday = self:getDayByTime(curTime)
		if signDay[tday.year] and signDay[tday.year][tday.month] and signDay[tday.year][tday.month][tday.day] then
			self.signContinueCount = self.signContinueCount + 1
		else
			break
		end
		curTime = curTime - ondayTime
	end
	
	CacheUtil:setCacheVal(CacheType.signDay, self.signDay)
	if self.gameLayer then self.gameLayer:setSignButtonTipsVisible(self.todayCanSign) end
end

--计算点香数据
function UserData:calcIncense( ... )
	
	--[[local incenseDay = self.incenseDay
	if not self.incenseDay[self.today.year] then self.incenseDay[self.today.year] = {} end
	if not self.incenseDay[self.today.year][self.today.month] then
		self.incenseDay[self.today.year][self.today.month] = {}
		for i=1, 31 do self.incenseDay[self.today.year][self.today.month][i] = false end
	end
	
	
	if self.incenseDay[self.today.year] and self.incenseDay[self.today.year][self.today.month] and self.incenseDay[self.today.year][self.today.month][self.today.day] then
		self.todayCanIncense = false
	end
	
	
	--上香累计
	self.censerNum = 0
	for y,yd in pairs(self.incenseDay) do
		for m,md in pairs(yd) do
			for d,dd in pairs(md) do
				if dd then self.censerNum = self.censerNum + 1 end
			end
		end
	end
	
	--连续上香的佛光等级增益
	local tday = self:getDayByTime( self.buddhasLightDay )
	local lastInc = incenseDay[tday.year] and incenseDay[tday.year][tday.month] and incenseDay[tday.year][tday.month][tday.day]
	local curTime = self:getDayNoByTime( os.time() )
	local effLv = 0
	local ondayTime = 60*60*24
	local incTime = self.buddhasLightDay
	while true do
		if curTime < self:getDayNoByTime(incTime) then
			break
		end
		tday = self:getDayByTime( incTime )
		local inc = incenseDay[tday.year] and incenseDay[tday.year][tday.month] and incenseDay[tday.year][tday.month][tday.day]
		if inc ~= lastInc then
			effLv = 0
			log("!!!!", inc and "true" or "false", lastInc and "true" or "false")
			lastInc = inc
		end
		--log(">>", self:getDayNoByTime(incTime), curTime, inc and "true" or "false", tday, effLv, lastInc)
		incTime = incTime + ondayTime
		effLv = effLv + 1
		if effLv%3 == 0 then
			self.buddhasLightDay = incTime
			self.buddhasLightLevel = math.min(3, math.max(0, self.buddhasLightLevel + (lastInc and 1 or -1)))
			self.buddhasLightLevel = 3--佛光定为3级
		end
	end--]]
end

function UserData:calcTodayCanSong( lastSongTime )
	local last = self:getDayByTime(lastSongTime)
	log("UserData:setSutraLastTime", last)
	if last.year == self.today.year and last.month == self.today.month and last.day == self.today.day then
		self.todayCanSong = false
	else
		self.todayCanSong = true
	end
end

function UserData:calcSong( ... )
	local songDay = self.songDay
	if not songDay[self.today.year] then songDay[self.today.year] = {} end
	if not songDay[self.today.year][self.today.month] then
		songDay[self.today.year][self.today.month] = {}
		for i=1, 31 do songDay[self.today.year][self.today.month][i] = false end
	end
	
	
	if songDay[self.today.year] and songDay[self.today.year][self.today.month] and songDay[self.today.year][self.today.month][self.today.day] then
		self.todayCanSong = false
	end
	
	--念经总数
	self.songCount = 0
	for y,yd in pairs(songDay) do
		for m,md in pairs(yd) do
			for d,dd in pairs(md) do
				if dd then self.songCount = self.songCount + 1 end
			end
		end
	end
	
	--连续念经天数
	self.songContinueCount = 0
	local curTime = self:getDayNoByTime( os.time() )
	local ondayTime = 60*60*24
	while true do
		local tday = self:getDayByTime(curTime)
		if songDay[tday.year] and songDay[tday.year][tday.month] and songDay[tday.year][tday.month][tday.day] then
			self.songContinueCount = self.songContinueCount + 1
		else
			break
		end
		curTime = curTime - ondayTime
	end
end

function UserData:signToday(  )
	if self.todayCanSign then
		self.todayCanSign = false
		
		self.signDay[self.today.year][self.today.month][self.today.day] = true
		self:calcSign()
		self:saveSignData()		
	end
end

function UserData:incenseToday(  )
	if self.todayCanIncense then
		--self.incenseDay[self.today.year][self.today.month][self.today.day] = true
		--self:calcIncense()
		self:saveIncenseData()
		
		self.todayCanIncense = false
		self.gameLayer:updateCenserState()
	end
end

function UserData:songToday(id, score, clickCount)
	self:saveSongData(id, score, clickCount)
	
	
	--[[if self.todayCanSong then
		self.songDay[self.today.year][self.today.month][self.today.day] = true
		self:calcSong()--]]
		
		
		--[[--1 玉石木鱼
		--2 白玉木鱼
		--3 莲花
		if self.songContinueCount >= 7 and self.songContinueCount < 30 then if not self.toolList["1"] then TipViewEx:showTip(TipViewEx.tipType.getTool) end self.toolList["1"] = 1 end
		
		if self.songContinueCount >= 30 and self.songContinueCount < 108 then if not self.toolList["2"] then TipViewEx:showTip(TipViewEx.tipType.getTool) end self.toolList["2"] = 1 end
		
		--if self.songContinueCount >= 108 then if not self.toolList["3"] then TipViewEx:showTip(TipViewEx.tipType.getTool) end self.toolList["3"] = 108 end
	end
	--]]
end

function UserData:setTool_lotus( cnt )
	if not self.toolList["3"] then self.toolList["3"] = 0 end
	self.toolList["3"] = self.toolList["3"] + cnt
	
	self:saveToolsData()
end
function UserData:getTool_lotus(  )
	if not self.toolList["3"] then self.toolList["3"] = 0 end
	return self.toolList["3"]
end

--保存我的道具数据
function UserData:saveToolsData()
	local str = ""
	for k,v in pairs(self.toolList) do
		str = str .. "," .. k .. ":" .. v
	end
	if string.len(str) > 0 then
		str = string.sub(str, 2, string.len(str))
	end
	
	CacheUtil:setCacheVal(CacheType.tools, str)
end


function UserData:getDayByTime( t )
	local dates = os.date("*t", t)
	return dates
end

function UserData:getTimeByDay( year, month, day )
	
	return os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day), hour=0})
end

--返回日历起总的第几天
function UserData:getDayNoByTime( t )
	local y = os.date("%Y", t)
	local d = os.date("%j", t)
	return y*366 + d
end

function UserData:loadMusicRhythmData()
	if not self.musicData then
		local ret = csvParse.LoadMusicRhythm("res/songData.csv")
		for k,v in pairs(ret) do
			v.score = 0
		end
		
		table.sort(ret, function (a, b)
			return a.id < b.id
		end)
		
		self.musicData={}
		for k,v in pairs(ret) do
			v.id = tonumber(v.id)
			self.musicData[v.id] = DeepCopy(v)
		end
		
		return self.musicData
	else
		return self.musicData
	end
end

--获取选中的经文的佛祖信息
function UserData:getSelectSongInfo()
	if self.selectSongId == 0 then
		return nil
	end
	local musicData = self:loadMusicRhythmData()
	return musicData[self.selectSongId]
end

function UserData:setSelectSongId(id)
	self.selectSongId = tonumber(id) or 0
	CacheUtil:setCacheVal(CacheType.selectSongId, self.selectSongId)
end
function UserData:getSelectSongId()
	return self.selectSongId
end

--设置每个music的分数
function UserData:setMusicScoreWithID(id, score)
	for k,v in pairs(self.musicData) do
		if v.id == id then
			v.score = score
			break
		end
	end
end

--设置净土已打开数据
function UserData:setJingtuOpenData(jingtuName, openNum)
	if not self.jingtuOpenData[jingtuName] or self.jingtuOpenData[jingtuName] < openNum then
		CacheUtil:setCustomCacheVal("jingtu_buttonTips", true)
	end
	self.jingtuOpenData[jingtuName] = openNum
	CacheUtil:setCacheVal(CacheType.jingtuOpenData, self.jingtuOpenData)	
end
function UserData:getJingtuOpenData(jingtuName)
	for k,v in pairs( self.jingtuOpenData ) do
		if k == jingtuName then
			return v
		end
	end
end

--综合排名
function UserData:setTotalRank(r)
	self.totalRank = r
	CacheUtil:setCacheVal(CacheType.totalRank, self.totalRank)
end
function UserData:getTotalRank()
	return self.totalRank
end



--当前显示的佛像
function UserData:setBuddhas(id)
	log("UserData:setBuddhas", id)
	self.buddhasId = id
	CacheUtil:setCacheVal(CacheType.buddhasId, self.buddhasId)
end
function UserData:getBuddhas()
	return self.buddhasId
end

--设置今天时间
function UserData:setToday(d)
	self.ostime = d
	self.today = {month=0, day=0, year=0}
	local todayStr = self:getDayByTime(d)
	self.today.month, self.today.day, self.today.year = todayStr.month, todayStr.day, todayStr.year
end

--设置每日签到数据，需要用到today
function UserData:setSignDayInfo(data)
	self.signDay[self.today.year] = {}
	self.signDay[self.today.year][self.today.month] = {}
	
	
	
	for i=1, 32 do
		local oper = CGame:bitOperate(5, i-1, 1)
		local bit = CGame:bitOperate(1, data, oper)
		local ret = oper == bit
		self.signDay[self.today.year][self.today.month][i] = ret
	end
	self.signLine = data
	
	self:calcSign()
end

function UserData:setSignNum(d)
	self.signNum = tonumber(d) or 0
	CacheUtil:setCacheVal(CacheType.signNum, self.signNum)
end
function UserData:getSignNum()
	return self.signNum
end
function UserData:setSignRank(d)
	self.signRank = d
	CacheUtil:setCacheVal(CacheType.signRank, self.signRank)
end
function UserData:getSignRank()
	return self.signRank
end

function UserData:setCenserNum(d)
	self.censerNum = tonumber(d) or 0
	CacheUtil:setCacheVal(CacheType.censerNum, self.censerNum)
end
function UserData:getCenserNum()
	return self.censerNum
end
function UserData:setCenserRank(d)
	self.censerRank = tonumber(d) or 0
	CacheUtil:setCacheVal(CacheType.censerRank, self.censerRank)
end
function UserData:getCenserRank()
	return self.censerRank
end

function UserData:setSutraNum(d)
	self.sutraNum = tonumber(d) or 0
	CacheUtil:setCacheVal(CacheType.sutraNum, self.sutraNum)
end
function UserData:getSutraNum()
	return self.sutraNum
end
function UserData:setSutraRank(d)
	self.sutraRank = tonumber(d) or 0
	CacheUtil:setCacheVal(CacheType.sutraRank, self.sutraRank)
end
function UserData:getSutraRank()
	return self.sutraRank
end
function UserData:setSutraLastTime(t)
	self.sutraLastTime = t
	CacheUtil:setCacheVal(CacheType.sutraLastTime, self.sutraLastTime)
	
	self:calcTodayCanSong(t)
end

function UserData:getTodayCanSong()
	return self.todayCanSong
end

function UserData:setTodayCanSong(b)
	self.todayCanSong = b
end



function UserData:setLotusNum(d)
	local lotusNum = tonumber(d) or 0
	if not self.lotusNum or self.lotusNum < lotusNum then
		CacheUtil:setCustomCacheVal("lotus_buttonTips", true)
	end
	
	self.lotusNum = lotusNum
	CacheUtil:setCacheVal(CacheType.lotusNum, self.lotusNum)
end
function UserData:getLotusNum()
	return self.lotusNum
end

function UserData:setIncenseLastTime(d)
	local t = tonumber(d) or 0
	self.incenseLastTime = t
	CacheUtil:setCacheVal(CacheType.incenseLastTime, self.incenseLastTime)
	
	local last = self:getDayByTime(t)	
	if last.year == self.today.year and last.month == self.today.month and last.day == self.today.day then
		self.todayCanIncense = false
	else
		self.todayCanIncense = true
	end
	log("self.todayCanIncense", self.todayCanIncense and 1 or 0)
	
	
	self.gameLayer:updateCenserState()
end

function UserData:getUUID()
	local uuid = AdManager:getUUID()
	print("uuid", uuid)
	return uuid
end

function UserData:setGameLayer(l)
	self.gameLayer = l
end
return UserData
