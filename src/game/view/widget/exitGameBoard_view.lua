
local exitGameBoardView = class("exitGameBoardView", cocosMake.DialogBase)

--cocos studio生成的csb
exitGameBoardView.ui_resource_file = {"exitGameBoardNode"}


					
exitGameBoardView.ui_binding_file = {
	closeBtn        = {event = "click", method = "closeBtnClick"},
	noBtn			= {event = "click", method = "noBtnClick"},
	yesBtn	        = {event = "click", method = "yesBtnClick"},
}


function exitGameBoardView:onCreate(param)
	
	local tiplist = {}
	if UserData:getTodayCanSong() then
		tiplist[#tiplist+1] = cocosMake.newSprite("signBoard/T_02.png")
	end
	if UserData.todayCanIncense then
		tiplist[#tiplist+1] = cocosMake.newSprite("signBoard/T_03.png")
	end
	if UserData.todayCanSign then
		tiplist[#tiplist+1] = cocosMake.newSprite("signBoard/T_04.png")
	end
	tiplist[#tiplist+1] = cocosMake.newSprite("signBoard/T_01.png")
	
	local offsetlist = {40, 55, 90, 115}
	local y = offsetlist[#tiplist]
	local offsety = -60
	for i=1, #tiplist-1 do
		local spr = tiplist[i]
		spr:setPositionY(y)
		self.tipsNode:addChild(spr)
		y=y+offsety
	end	
	y=y+offsety*0.5
	tiplist[#tiplist]:setPositionY(y)
	self.tipsNode:addChild(tiplist[#tiplist])
	
	self:dispatchEvent({name = GlobalEvent.EXITGAME_VIEW_SHOW, data={view=self}})
	
	AdManager:showAd()
	
	self.player = param.player
	self.player:pause()
end


function exitGameBoardView:onClose( ... )
	AdManager:loadAd()
	AdManager:hideAd()
	self:dispatchEvent({name = GlobalEvent.EXITGAME_VIEW_SHOW, data={view=nil}})
	
	self.player:resume()
end

function exitGameBoardView:bgTouch()
end

function exitGameBoardView:closeBtnClick(event)
	ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.buttonClick, false), 70)

	LayerManager.closeFloat(self)
end

function exitGameBoardView:noBtnClick(event)
	ccexp.AudioEngine:setVolume(ccexp.AudioEngine:play2d(audioData.buttonClick, false), 70)
	
	LayerManager.closeFloat(self)
end

function exitGameBoardView:yesBtnClick(event)
	
	cocosMake.endToLua()
end




return exitGameBoardView
