
local GameLayer = class("GameLayer", cocosMake.viewBase)
local crypts = require("crypt")
--cocos studio生成的csb
GameLayer.ui_resource_file = {"GameLayerNode"}

GameLayer.ui_binding_file = {
	qiandao_btn    = {event = "click", method = "qiandao_btnClick"},
	songjing_btn    = {event = "click", method = "songjing_btnClick"},
	jingwen_btn    = {event = "click", method = "jingwen_btnClick"},
	exitGameBtn    = {event = "click", method = "exitGameBtnClick"},
	continueBtn    = {event = "click", method = "continueBtnClick"},
	pauseBtn    = {event = "click", method = "pauseBtnClick"},
}

function GameLayer:onCreate(param)
	
	UserData:setGameLayer(self)
	self:setSignButtonTipsVisible(UserData.todayCanSign)
	
	self:initUI()
	
	self:return_key()

    self.audio_background_handle = ccexp.AudioEngine:play2d(audioData.background, true)
	ccexp.AudioEngine:setVolume(self.audio_background_handle, 100)


	self.musicPlayerCtrl = new_class(luaFile.musicPlayerCtrl)
	
	
	--[[local path = cc.FileUtils:getInstance():fullPathForFilename("res/exit.png")
	log("res/exit.png full path : ", path)
	local testSpr = cocosMake.newSprite("res/exit.png", 300, 300)
	self:addChild(testSpr)
	
	local program = cc.GLProgram:create("Shaders/bolang.vsh", "Shaders/bolang.fsh")
	program:link()
	program:use()
	program:updateUniforms()
	local state = cc.GLProgramState:create(program)
	--testSpr:setGLProgramState(state)--]]
		
end

function GameLayer:initUI()
	self.censerPanel:setVisible(true)
	
	self:updateCenserState()
	
	--点击上香
	self.censerPanel:setTouchEnabled(true)
	self.censerPanel:onClicked(function()
		if UserData.todayCanIncense and not UserData.todayCanSign then
			self.censer_on:setVisible(true)
			self.censer_off:setVisible(false)
			self:showCenserFire()
			ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.censer, false), 70)
			UserData:incenseToday(  )
			
		elseif UserData.todayCanSign then
			TipViewEx:showTip(TipViewEx.tipType.signTip)
            ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.error, false), 70)
		end
	end)
	
	
	
	--if UserData.buddhasLightLevel == 0 then self.f_g:setVisible(false) end
	
	
	--阳光效果
	local action_list1 = {}
	action_list1[#action_list1 + 1] = cc.FadeOut:create(2.0)
	action_list1[#action_list1 + 1] = cc.FadeIn:create(2.0)
	local action1 = cc.RepeatForever:create(cc.Sequence:create(unpack(action_list1)))
	self.lightEff1:runAction(action1)
	
	local action_list2 = {}
	action_list2[#action_list2 + 1] = cc.FadeIn:create(2.0)
	action_list2[#action_list2 + 1] = cc.FadeOut:create(2.0)
	local action2 = cc.RepeatForever:create(cc.Sequence:create(unpack(action_list2)))
	self.lightEff2:runAction(action2)
	
	
	--动态佛光
	if UserData.buddhasLightLevel >= 3 then
		local scnt = 8
		local sp = 0.17
		for j=1,scnt do
			local frameName =string.format("res/Buddhas/buddhasLightEff/%04d.png",j)
			local s = cocosMake.newSprite(frameName, 0, 0)
			s:setVisible(false)
			
			local sequence = transition.sequence({
				cc.DelayTime:create((j-1)*sp),
				cc.Show:create(),
				cc.DelayTime:create(sp),
				cc.Hide:create(),
				cc.DelayTime:create(math.max(0,(scnt-j))*sp),
			})
			s:runAction(cc.RepeatForever:create(sequence))
			self.buddhasLight:addChild(s)
			self.buddhasLight.originalPos = cc.p(self.buddhasLight:getPosition())
		end
	end	
	
	--self:updateChenghao()
	
	self:showStartSpeak()
		
	self.touchMaskPanel:setSwallowTouches(false)
	self.touchMaskPanel:onClicked(function()end)
	self.touchMaskPanel:setVisible(true)
	
	
	
	--缓存图片
	cc.SpriteFrameCache:getInstance():addSpriteFrames("signBoard/clickNumberEffect.plist")
	cocosMake.newSprite("woodenFish/"..UserData.usedTool.."/".."m_01.png")
	cocosMake.newSprite("woodenFish/"..UserData.usedTool.."/".."m_02.png")

    self:setBuddhasImage(UserData:getBuddhas())
	
	self.continueBtn:setVisible(false)
	self.pauseBtn:setVisible(false)
	
	self:showBGFrameAnim()
end

function GameLayer:showBGFrameAnim()
	local cnt = 1
	schedule(self, function ()
		cnt = cnt + 1
		if cnt > 25 then
			cnt = 1
		end
		self.background:loadTexture(string.format("bg/gamelayer/BG%02d.jpg",  cnt))
		--self.background:setContentSize(self.background:getVirtualRendererSize())
	end, 0.10)
end

function GameLayer:showStartSpeak()
	self.startSpeak:setVisible(true)
	self.startSpeak:onClicked(function()
		self.startSpeak:removeFromParent()
	end)
end

local buddhasPosOffset={}
buddhasPosOffset.kqmw = cc.p(0,30)
buddhasPosOffset.nwamtf = cc.p(0,30)
buddhasPosOffset.nwbssjmnf = cc.p(0,5)
buddhasPosOffset.nwdzwps = cc.p(0,70)
buddhasPosOffset.nwgsyps = cc.p(0,60)
buddhasPosOffset.xzysysf = cc.p(0,30)
buddhasPosOffset.nwdlxsmlf = cc.p(0,30)
setmetatable(buddhasPosOffset, { __index = function(mytable, key) return cc.p(0,0) end })

local buddhasScale={}
buddhasScale.kqmw = 0.0
buddhasScale.nwgsyps = 0.8
buddhasScale.nwdzwps = 0.85
buddhasScale.nwamtf = 0.77
buddhasScale.nwbssjmnf = 0.7
buddhasScale.xzysysf = 0.8
buddhasScale.nwdlxsmlf = 0.8
setmetatable(buddhasScale, { __index = function(mytable, key) return 1.0 end })

function GameLayer:setBuddhasImage(res)
	log(res, string.len(res))
	self.buddhas:loadTexture(string.format("Buddhas/buddhas/%s.png",  res))
	self.buddhas:setContentSize(self.buddhas:getVirtualRendererSize())
	
	self.buddhasLight:setPosition(self.buddhasLight.originalPos.x+buddhasPosOffset[res].x,
								self.buddhasLight.originalPos.y+buddhasPosOffset[res].y)
	self.buddhasLight:setScale(buddhasScale[res])
end


function GameLayer:playClickCountNumberEff()
	local animateNode = new_class(luaFile.AnimationSprite, {
		startFrameIndex = 1,                             -- 开始帧索引
		isReversed = false,                              -- 是否反转
		plistFileName = "signBoard/clickNumberEffect.plist", -- plist文件
		pngFileName = "signBoard/clickNumberEffect.png",     -- png文件
		pattern = "clickNumberEffect/",                      -- 帧名称模式串
		frameNum = 8,                                   -- 帧数
		rate = 0.05,                                     -- 
		stay = true,                                    -- 是否停留（是否从cache中移除纹理）
		indexFormat = 4,                                 -- 整数位数
	})
	self.clickCountEffNode:addChild(animateNode)
	animateNode:playOnce(true, 0)	
	
	self:playClickWoodenFishEffect()
end


function GameLayer:updateChenghao( ... )
	--更新称号
	local chenghaoLv = 0
	local songCnt = UserData.songCount
	if songCnt >= 7 and songCnt < 15 then chenghaoLv = 1 end
	if songCnt >= 15 and songCnt < 30 then chenghaoLv = 2 end
	if songCnt >= 30 and songCnt < 60 then chenghaoLv = 3 end
	if songCnt >= 60 and songCnt < 120 then chenghaoLv = 4 end
	if songCnt >= 120 and songCnt < 180 then chenghaoLv = 5 end
	if songCnt >= 180 and songCnt < 360 then chenghaoLv = 6 end
	if songCnt >= 360 and songCnt < 720 then chenghaoLv = 7 end
	if songCnt >= 720 and songCnt < 1080 then chenghaoLv = 8 end
	if songCnt >= 1080 and songCnt < 1440 then chenghaoLv = 9 end
	if songCnt >= 1440 then chenghaoLv = 10 end
	if chenghaoLv > 0 then
		if self.chenghaoNode.chSpr then
			self.chenghaoNode.chSpr:removeAllChildren()
		end
		local chSpr = cocosMake.newSprite(string.format("homeUI/chenghao/rw_%02d.png", chenghaoLv))
		self.chenghaoNode:addChild(chSpr)
		self.chenghaoNode.chSpr = chSpr
	end
	UserData.chenghaoLv = chenghaoLv
	if self.lastChenghaoLv and self.lastChenghaoLv < chenghaoLv then
		TipViewEx:showTip(TipViewEx.tipType.getChenghao)
	end
	self.lastChenghaoLv = chenghaoLv
end


function GameLayer:onClose( ... )
end

local function makekey()
	local max = 256
	local encodeMap = {}
	local encodeList = {}
	
	for i=1, max do encodeMap[i] = 0 end
	
	local enCnt = 0
	while true do
		local r = math.random(1, max)
		if encodeMap[r] == 0 then
			encodeMap[r] = 1
			encodeList[#encodeList+1] = r
			log("res:", r, #encodeList)
		end
		if #encodeList == max then
			break
		end
	end
	log("encodeList------------------------")
	for i=1, #encodeList, 25 do
		local line = ""
		for j=i, math.min(#encodeList, i+24) do
			line = line .. (encodeList[j]-1) .. ","
		end
		log(line)
	end
	
	log("decodeList------------------------")
	
	local decodeList = {}
	for i=1, max do decodeList[i] = 0 end
	for i=1, #encodeList do
		decodeList[encodeList[i]] = i
	end
	for i=1, #decodeList, 25 do
		local line = ""
		for j=i, math.min(#decodeList, i+24) do
			line = line .. (decodeList[j]-1) .. ","
		end
		log(line)
	end
	log("over------------------------")
end

function GameLayer:exitGameBtnClick(event)
	
	--[[
	local spr = cocosMake.newSprite("Buddhas/f_01test.png", 0, 0 , {anchor=cc.p(0,0)})
	spr:getTexture():setTexParameters(GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT)
	self:addChild(spr)
	
	local program = cc.GLProgram:create("Shaders/shadow.vsh", "Shaders/shadow.fsh")
	program:link()
	program:use()
	program:updateUniforms()
	
	
	local state = cc.GLProgramState:create(program)
	spr:setGLProgramState(state)
	
	local hval = 0.00
	schedule(spr, function()
		state:setUniformFloat("HValue", hval)
		hval = hval + 0.005
		if hval > 1.0 then hval = 0.0 end
	end, 0.03)	
	]]--
   ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.buttonClick, false), 70)
	
	if not self.musicPlayerCtrl:isPlaying() then
		LayerManager.showFloat(luaFile.exitGameBoardView, {modal=true, player=self.musicPlayerCtrl})
	else
		self:showExitSutraView()
	end
end

function GameLayer:continueSutraSong()
	self.continueBtn:setVisible(false)
	self.pauseBtn:setVisible(true)

	self:setTouchMaskPanelVisible(false)
	
	if self.musicPlayerCtrl:getState() == "pause" then
		self.musicPlayerCtrl:resume()
	end
	
    AdManager:loadAd()
	AdManager:hideAd()
end

function GameLayer:continueBtnClick()
	ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.buttonClick, false), 70)
	
	self:continueSutraSong()
end

function GameLayer:pauseSutraSong()
	self.continueBtn:setVisible(true)
	self.pauseBtn:setVisible(false)
	
	self:setTouchMaskPanelVisible(true)
	
	if self.musicPlayerCtrl:getState() ~= "pause" then
		self.musicPlayerCtrl:pause()
	end
	
	AdManager:showAd()
end

function GameLayer:pauseBtnClick()
	ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.buttonClick, false), 70)
	
	self:pauseSutraSong()
end

function GameLayer:setTouchMaskPanelVisible(b)
	self.touchMaskPanel:setSwallowTouches(b)
	self.touchMaskPanel:setVisible(b)
end

function GameLayer:showCenserFire()
	for i=1, 3 do
		self["censer_fire"..i]:removeAllChildren()
	end
	
	if not UserData.todayCanIncense then
		self.censerPanel:setTouchEnabled(false)
		
		local rotatelist = {0, 0, 0}
		local spriteFrame  = cc.SpriteFrameCache:getInstance() 
		local anim = {}
		spriteFrame:addSpriteFrames("censer/censer_firework.plist")
		for i=1, 3 do
			local animation =cc.Animation:create()
			local scnt = 12
			local sp = 0.1
            for j=1,scnt do
                local frameName =string.format("censer/censer_firework/%04d.png",j)
                local s = cocosMake.newSprite(frameName, 0, 0)
				s:setRotation(rotatelist[i])
				s:setVisible(false)
				s:setScale(0.5)
				
				local sequence = transition.sequence({
					cc.DelayTime:create((j-1)*sp),
                    cc.Show:create(),
					cc.DelayTime:create(sp),
					cc.Hide:create(),
					cc.DelayTime:create(math.max(0,(scnt-j))*sp),
                })
				s:runAction(cc.RepeatForever:create(sequence))
		
				self["censer_fire"..i]:addChild(s)
            end  
   
			anim[i] = self["censer_fire"..i]
		end
	end
	
end

function GameLayer:qiandao_btnClick(event)
	ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.buttonClick, false), 70)
	local function signCallback()
	
	end
	LayerManager.showFloat(luaFile.signBoardView, {modal=true, signCallback=signCallback})
end

function GameLayer:createWoodenFishAnim()
	
	local def = "0"
	if UserData.usedTool == "1" or UserData.usedTool == "2" then
		def = UserData.usedTool
	end
	def = UserData.usedTool--改成只有一种木鱼
	
	local animateNode = new_class(luaFile.AnimationSprite, {
		startFrameIndex = 1,                             -- 开始帧索引
		isReversed = false,                              -- 是否反转
		plistFileName = "woodenFish/"..def.."/woodenFish.plist", -- plist文件
		pngFileName = "woodenFish/"..def.."/woodenFish.png",     -- png文件
		pattern = "woodenFish/",                      -- 帧名称模式串
		frameNum = 4,                                   -- 帧数
		rate = 0.05,                                     -- 
		stay = true,                                    -- 是否停留（是否从cache中移除纹理）
		indexFormat = 4,                                 -- 整数位数
	})
	return animateNode
end


function GameLayer:startClickWoodenFish()
	self.woodenFishClickCount:setVisible(true)
	self.woodenFishClickCount:setString("0")
	self.woodenFishClickCount.cnt = 0

	
	local def = "0"
	if UserData.usedTool == "1" or UserData.usedTool == "2" then
		def = UserData.usedTool
	end
	def = UserData.usedTool--改成只有一种木鱼
	local btn_normal = cocosMake.newSprite("woodenFish/"..def.."/".."m_01.png")
	local btn_touch = cocosMake.newSprite("woodenFish/"..def.."/".."m_02.png")
	btn_normal:setVisible(true)
	btn_touch:setVisible(false)
	self.woodenFish_btn_normal = btn_normal
	self.woodenFish_btn_touch = btn_touch
	
	self.woodenFishTouchPanel:onTouch(function(event)
		if event.name == "began" then
			btn_normal:setVisible(false)
			btn_touch:setVisible(true)
			local soundfile = audioData.woodenFish
			--if songData[UserData.selectSongId].B then soundfile = audioData.woodenFishB end
            
			local res=self.musicPlayerCtrl:clickEvent()
			if res ~= 0 then
				--ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(soundfile, false), 70)
			end
			
			
		elseif event.name == "ended" then
			btn_normal:setVisible(true)
			btn_touch:setVisible(false)
		end
	end)
	self.woodenFishTouchPanel:setTouchEnabled(true)
	
	
	self.woodenFishNode:addChild(btn_normal)
	self.woodenFishNode:addChild(btn_touch)
	
    ccexp.AudioEngine:stop(self.audio_background_handle)
	
	local function clickCallback()
		self.woodenFishClickCount.cnt = self.woodenFishClickCount.cnt + 1
		self.woodenFishClickCount:setString(self.woodenFishClickCount.cnt)
		self.woodenFishClickCount:setScale(0)
		self.woodenFishClickCount:runAction(cc.EaseExponentialOut:create(cc.ScaleTo:create(0.3, 0.7)))		
		self:playClickCountNumberEff()
	end
	
	--播放经文
	--startPos, endPos, speed, containWidget
	self.musicPlayerCtrl:setParam(cc.p(730.0, 350.0), cc.p(-10.0, 350.0), 130.0, self.musicPlayerPanel)
	self.musicPlayerCtrl:setClickValidCallback(clickCallback)
	local musicData = UserData:getSelectSongInfo()
	self.musicPlayerCtrl:playMusic(musicData.id, musicData.songId, musicData.songTime, 
		musicData.rhythm, musicData.foju)
		
	--更换佛祖图像
	UserData:setBuddhas(musicData.buddhaId)
	self:setBuddhasImage(UserData:getBuddhas())
	
		
	--[[audioCtrl:playMusic(songData[UserData.selectSongId].file, false)
	if songData[UserData.selectSongId].count > 1 then
		local songCount = 1
		local sch = schedule(self, function()
			audioCtrl:playMusic(songData[UserData.selectSongId].file, false)
			songCount = songCount + 1
			if songCount >= songData[UserData.selectSongId].count then
				self:stopAction(sch)
			end
		end, songData[UserData.selectSongId].time)
	end
	
	
	local function songFinishCallback()
		self.woodenFishTouchPanel:removeAllChildren()
		self.woodenFishTouchPanel:setTouchEnabled(false)
		self.woodenFishTouchPanel:setVisible(false)		
		self.woodenFishClickCount:setVisible(false)
		
		local res = 0
		local clickCnt = tonumber(self.woodenFishClickCount:getString())
		if clickCnt > songData[UserData.selectSongId].touchMax then res = 1 end
		if clickCnt < songData[UserData.selectSongId].touchMin then res = -1 end
		if res == 0 then 
			UserData:songToday() self:huiwenAnim(8, function() 
				self.bottomMenuPanel:setVisible(true)
				LayerManager.showFloat(luaFile.sutraOverBoardView, {modal=true,result=res})
			end)
		else
			self.bottomMenuPanel:setVisible(true)
			LayerManager.showFloat(luaFile.sutraOverBoardView, {modal=true,result=res})
		end
		audioCtrl:playMusic(audioData.background, true)
		
		self.continueBtn:setVisible(false)
		self.pauseBtn:setVisible(false)
	end
	performWithDelay(self, songFinishCallback, songData[UserData.selectSongId].time * songData[UserData.selectSongId].count)--]]
end



function GameLayer:jingwen_btnClick(event)
	ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.buttonClick, false), 70)
	
	
	local function callback()
		local musicData = UserData:getSelectSongInfo()
		--更换佛祖图像
		if musicData then
			UserData:setBuddhas(musicData.buddhaId)
			self:setBuddhasImage(UserData:getBuddhas())
		end
	end
	LayerManager.showFloat(luaFile.sutraBoardView, {modal=true, selectCallback=callback})
end

local zanfojieNumMap = {}
zanfojieNumMap.dzz=8
zanfojieNumMap.gyj=8
zanfojieNumMap.kqj=6
zanfojieNumMap.sjj=10
zanfojieNumMap.ysz=8
zanfojieNumMap.zfj=8
zanfojieNumMap.mtz=10

local zanfojieDelayOff = {}
zanfojieDelayOff.kqj = 10
setmetatable(zanfojieDelayOff, { __index = function(mytable, key) return 0 end })

function GameLayer:jingwenAnim(overTime)
	local selectSongInfo = UserData:getSelectSongInfo()
	local txtNum = zanfojieNumMap[selectSongInfo.zanfojie]
	local moveX = -10
	local degeX = stage_width/(txtNum)
	local movetime = 1.3
	local moveDelayInFront = 0
	if txtNum*movetime <= overTime then
		moveDelayInFront = overTime - (txtNum*movetime)
		moveDelayInFront = moveDelayInFront/txtNum
	else
		movetime = overTime/txtNum
	end
	for i=1, txtNum do
		local sprpath = string.format("res/sanboyiwen/" .. selectSongInfo.zanfojie .. "/%02d.png", i)
		local txt = cocosMake.newSprite(sprpath)
		txt:setPosition(degeX*(txtNum-i)-moveX+degeX/2, 800)
		txt:setOpacity(0)
		self:addChild(txt)
		
		local function callBackFunc()
			local actionMove = cc.MoveBy:create(movetime, cc.p(moveX, 0))
			local actionFade = cc.FadeOut:create(movetime)
			local actionSpawn = cc.Spawn:create(actionMove, actionFade)
			txt:runAction(cc.Sequence:create(actionSpawn, cc.RemoveSelf:create()))
		end
		
		local actionMove = cc.MoveBy:create(movetime, cc.p(moveX, 0))
		local actionFade = cc.FadeIn:create(movetime)
		local actionSpawn = cc.Spawn:create(actionMove, actionFade)
		local delay1 = cc.DelayTime:create((i-1)*movetime + (i-1)*moveDelayInFront)
		txt:runAction(cc.Sequence:create(delay1,   actionSpawn))
		
		
		local delay2 = cc.DelayTime:create(overTime + zanfojieDelayOff[selectSongInfo.zanfojie])
		txt:runAction(cc.Sequence:create(delay2, cc.CallFunc:create(callBackFunc)))
	end
	
	
	
	performWithDelay(self, function()
		self:startClickWoodenFish()
		self.continueBtn:setVisible(false)
		self.pauseBtn:setVisible(true)
		self.woodenFishNode:setVisible(true)
		--ccexp.AudioEngine:stop(startSongHandle or 0)
	end, overTime + zanfojieDelayOff[selectSongInfo.zanfojie])
end

function GameLayer:clickWoodenFinishSuccessEvent()
	self.clickSuccessIcon:setVisible(true)
end

function GameLayer:huiwenAnim(overTime, animCallback)
	local mtime = 1.3
	for i=1, 4 do
		local sprpath = string.format("res/songOver/%02d.png", i)
		local txt = cocosMake.newSprite(sprpath)
		txt:setPosition(522-(i*(68)), 697)
		txt:setOpacity(0)
		txt:setGlobalZOrder(1)
		self:addChild(txt)
				
		local function callBackFunc()
			local actionMove = cc.MoveBy:create(mtime, cc.p(10, 0))
			local actionFade = cc.FadeOut:create(mtime)
			local actionSpawn = cc.Spawn:create(actionMove, actionFade)
			txt:runAction(cc.Sequence:create(actionSpawn, cc.RemoveSelf:create()))
		end
		
		local actionMove = cc.MoveBy:create(mtime, cc.p(10, 0))
		local actionFade = cc.FadeIn:create(mtime)
		local actionSpawn = cc.Spawn:create(actionMove, actionFade)
		local delay1 = cc.DelayTime:create((i-1)*mtime*1.6)
		txt:runAction(cc.Sequence:create(delay1, actionSpawn))
		
		local delay2 = cc.DelayTime:create(overTime)
		txt:runAction(cc.Sequence:create(delay2, cc.CallFunc:create(callBackFunc)))
	end
	self:runAction(cc.Sequence:create(cc.DelayTime:create(overTime + mtime), cc.CallFunc:create(animCallback)))
end

function GameLayer:songjing_btnClick(event)
	local songInfo = UserData:getSelectSongInfo()
	if UserData:getSelectSongId() > 0 and songInfo then
		self.bottomMenuPanel:setVisible(false)		
		self.woodenFishTouchPanel:removeAllChildren()
		self.woodenFishTouchPanel:setVisible(true)
		
		local zfj = string.split(songInfo.zanfojieAudio, "_")
		local zfjTime = tonumber(zfj[2])
		
		self:jingwenAnim(zfjTime)
		
		local startSongHandle = ccexp.AudioEngine:play2d("sanboyiwen/audio/"..songInfo.zanfojieAudio..".mp3", false)
		ccexp.AudioEngine:setVolume(startSongHandle, 100)
		ccexp.AudioEngine:stop(self.audio_background_handle)
		
	else
        ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.error, false), 70)
		TipViewEx:showTip(TipViewEx.tipType.songTip)
	end
end

function GameLayer:playClickWoodenFishEffect()
	local musicData = UserData:loadMusicRhythmData()
	local eff = musicData[UserData.selectSongId].clickEffect
	
	if eff == "hb" then
		local moveTime = math.random(3, 4)
		local rate = 0.06
		local animNode = cocosMake.newNode()
		self:addChild(animNode)
		local animateNode = new_class(luaFile.AnimationSprite, {
			startFrameIndex = 1,                             -- 开始帧索引
			isReversed = false,                              -- 是否反转
			plistFileName = "res/woodenFish/hb.plist", -- plist文件
			pngFileName = "res/woodenFish/hb.png",     -- png文件
			pattern = "hb/",                      -- 帧名称模式串
			frameNum = 8,                                   -- 帧数
			rate = rate,                                     -- 
			stay = true,                                    -- 是否停留（是否从cache中移除纹理）
			indexFormat = 4,                                 -- 整数位数
		})		
		animateNode:playOnce(false, 0)
		animNode:addChild(animateNode)
		animNode:setPosition(math.random(0, stage_width), math.random(stage_height-300, stage_height))			
		animNode:runAction(cc.MoveTo:create(moveTime, cc.p(math.random(10, stage_width-10), math.random(10, 100))))
		
		
		local action_list = {}
		action_list[#action_list + 1] = cc.DelayTime:create(moveTime-3*rate)
		action_list[#action_list + 1] = cc.CallFunc:create(function () 
			animateNode:removeFromParent()
			local animateNodeB = new_class(luaFile.AnimationSprite, {
				startFrameIndex = 9,                             -- 开始帧索引
				isReversed = false,                              -- 是否反转
				plistFileName = "res/woodenFish/hb.plist", -- plist文件
				pngFileName = "res/woodenFish/hb.png",     -- png文件
				pattern = "hb/",                      -- 帧名称模式串
				frameNum = 3,                                   -- 帧数
				rate = rate,                                     -- 
				stay = true,                                    -- 是否停留（是否从cache中移除纹理）
				indexFormat = 4,                                 -- 整数位数
			})		
			animateNodeB:playOnce(true, 0)
			animNode:addChild(animateNodeB)
		end)
		action_list[#action_list + 1] = cc.DelayTime:create(0.5)
		action_list[#action_list + 1] = cc.RemoveSelf:create()
		animNode:runAction(cc.Sequence:create(unpack(action_list)))
		animNode:runAction(cc.RepeatForever:create(cc.RotateBy:create(4, 360)))
		
	elseif eff == "ym" then
		local ymSpr = cocosMake.newSprite("res/woodenFish/ym.png")
		self:addChild(ymSpr)
		ymSpr:setPosition(math.random(0, stage_width), math.random(stage_height-300, stage_height))
			
		local moveTime = math.random(3.5, 4)
		ymSpr:runAction(cc.MoveTo:create(moveTime, cc.p(math.random(10, stage_width-10), math.random(10, 100))))
		
		local action_list2 = {}
		action_list2[#action_list2 + 1] = cc.FadeIn:create(0.3)
		action_list2[#action_list2 + 1] = cc.DelayTime:create(moveTime-0.5-0.3)
		action_list2[#action_list2 + 1] = cc.FadeOut:create(0.5)
		action_list2[#action_list2 + 1] = cc.RemoveSelf:create()
		ymSpr:setOpacity(0)
		ymSpr:runAction(cc.Sequence:create(unpack(action_list2)))		
		ymSpr:runAction(cc.RepeatForever:create(cc.RotateBy:create(4, 360)))
	end
end

function GameLayer:return_key()
	self.floatView = nil
    --回调方法
    local function onrelease(code, event)
        if code == cc.KeyCode.KEY_BACK then
            if self.floatView then 
				LayerManager.closeFloat(self.floatView) 
				self.floatView = nil
			else				
				if not self.musicPlayerCtrl:isPlaying() then
					LayerManager.showFloat(luaFile.exitGameBoardView, {modal=true, player=self.musicPlayerCtrl})
				else
					if self.musicPlayerCtrl:getState() ~= "pause" then
						self:showExitSutraView()
					end
				end
			end
        elseif code == cc.KeyCode.KEY_HOME then
        end
    end
    --监听手机返回键
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onrelease, cc.Handler.EVENT_KEYBOARD_RELEASED)
    --lua中得回调，分清谁绑定，监听谁，事件类型是什么
    local eventDispatcher =self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener,self)
	
	
	GameController:addEventListener(GlobalEvent.SIGN_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.SUTRA_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.SUTRAOVER_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.EXITGAME_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.RANK_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.TASK_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.TOOL_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.JINGTU_VIEW_SHOW,function(event)
		self.floatView = event.data and event.data.view or nil
    end)
	GameController:addEventListener(GlobalEvent.UPDATE_NOTE_NOTIFY,function(event)
		local noteStr = event.data and event.data.note or ""
		self:showNote(noteStr)
    end)
	
	GameController:addEventListener(GlobalEvent.EXITSUTRA_NOTIFY,function(event)
		if self.woodenFish_btn_normal then
			self.woodenFish_btn_normal:removeFromParent()
			self.woodenFish_btn_normal = nil
		end
		if self.woodenFish_btn_touch then
			self.woodenFish_btn_touch:removeFromParent()
			self.woodenFish_btn_touch = nil
		end
		
		self.bottomMenuPanel:setVisible(true)
		
		self.woodenFishTouchPanel:setTouchEnabled(false)
		self.woodenFishNode:setVisible(false)
		self.clickSuccessIcon:setVisible(false)
		self.clickCountEffNode:removeAllChildren()
		self.woodenFishClickCount:setVisible(false)
		self.woodenFishClickCount.cnt = 0
		self.pauseBtn:setVisible(false)
		self.continueBtn:setVisible(false)
				
		self:setTouchMaskPanelVisible(false)
		
        self.audio_background_handle = ccexp.AudioEngine:play2d(audioData.background, true)
        ccexp.AudioEngine:setVolume(self.audio_background_handle, 100)
    end)
	
	
	GameController:addEventListener(GlobalEvent.CLICK_WOODENFINISH_SUCCESS, handler(self, self.clickWoodenFinishSuccessEvent))

    GameController:addEventListener(GlobalEvent.ENTER_FOREGROUND, handler(self, self.appEnterForeground))

    GameController:addEventListener(GlobalEvent.ENTER_BACKGROUND, handler(self, self.appEnterBackground))
end

function GameLayer:updateCenserState()
	self.censer_on:setVisible(not UserData.todayCanIncense)
	self.censer_off:setVisible(UserData.todayCanIncense)
	self:showCenserFire()
end

function GameLayer:appEnterBackground()
	if self.audio_background_handle then
		ccexp.AudioEngine:pause(self.audio_background_handle)
	end
	if self.musicPlayerCtrl:isPlaying() then
		self.musicPlayerCtrl:pause()
	end
end

function GameLayer:appEnterForeground()
	if self.audio_background_handle then
		ccexp.AudioEngine:resume(self.audio_background_handle)
	end
	if not self.exitSutraView and self.musicPlayerCtrl:isPlaying() then
		self:continueSutraSong()
	end
end

function GameLayer:showNote(noteStr)
	if not self.noteStrWidget then
		local beginPos = cc.p(2*stage_width, stage_height-30)
		self.noteStrWidget = cocosMake.newLabel(noteStr, beginPos.x, beginPos.y, {size=30})
		self.noteStrWidget:setTextColor(cc.c4b(255, 33, 33, 255))
		LayerManager.showTipsLayer(self.noteStrWidget)
		local action_list = {}
		action_list[#action_list + 1] = cc.MoveBy:create(24, cc.p(-stage_width*4, 0))
		action_list[#action_list + 1] = cc.MoveTo:create(0, beginPos)
		local action = cc.RepeatForever:create(cc.Sequence:create(unpack(action_list)))
		self.noteStrWidget:runAction(action)
	end
	self.noteStrWidget:setString(noteStr)	
end

function GameLayer:showExitSutraView()
	if not self.exitSutraView then
		self.exitSutraView = LayerManager.showFloat(luaFile.exitSutraView, 
				{modal=true, onClickCallback=function (cn)
					self:continueSutraSong()
					self.exitSutraView = nil
					
					if "yes" == cn then
						self:continueSutraSong()
						
						self:dispatchEvent({name = GlobalEvent.EXITSUTRA_NOTIFY, data={}})
						
						LayerManager.showFloat(luaFile.sutraOverBoardView, {modal=true,
							id=self.musicPlayerCtrl:getMusicId(), result=self.musicPlayerCtrl:isSuccessed(), 
							fojuScore = self.musicPlayerCtrl:getFojuScore(), clickCount=self.musicPlayerCtrl:getClickCount()})
						self.musicPlayerCtrl:stop()
						self.musicPlayerCtrl:clear()
					end
				end})
		
		self:pauseSutraSong()
	end
end



function GameLayer:setSignButtonTipsVisible(b)
	if b and not self.signTipsAnimNode then		
		self.signTipsAnimNode = WidgetHelp:createButtonEffSprite({scale=2.3, x=60, y=80})
		self.qiandao_btn:addChild(self.signTipsAnimNode)
	end
	if self.signTipsAnimNode then self.signTipsAnimNode:setVisible(b) end
end



--cocosMake.Director:setDisplayStats(TARGET_PLATFORM == cc.PLATFORM_OS_WINDOWS)

return GameLayer
