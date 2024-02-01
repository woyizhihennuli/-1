--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2020-09-22 02:09:47
--======================================================================--
local BotBiz = class()

function BotBiz:初始化(bot)
	self.bot = bot

	self.target_run = 0
	self.target_fight_begin = 0
	self.target_fight_end = 0

	self.timeCnt = 0
end

function BotBiz:getMapId()
	return self.bot.地图数据.编号
end

function BotBiz:isCaptain()
	return  self.bot.队长
end

function BotBiz:isFight()
	return self.bot.战斗 == 1
end

function BotBiz:isOpenFight( ... )
	return self.bot.开启战斗 or false
end

function BotBiz:logic_noFight( ... )
	local state = {}
	if self.timeCnt == self.target_run then
		state.type = "run"
		local pos = self:getRandomPos()
		state.x = pos.x
		state.y = pos.y
		self.target_run = BotCtrl:getTime_run()
		self:run(pos.x,pos.y)
	else
		state.type = "wait"
		if self.target_run == 0 then
			self.target_run = BotCtrl:getTime_run()
		end
	end
	return state
end

function BotBiz:logic_fight()
	local state = {}
	if self:isFight() then
		if self.target_fight_end == 0 then
			state.type = "wait"
			self.target_fight_end = BotCtrl:getTime_fight_end()
		elseif self.target_fight_end == self.timeCnt then
		    state.type = "fightEnd"
		    self:fightEnd()
		    self.target_run = BotCtrl:getTime_run()
		else
		    state.type = "wait"
		end
	else
		if self.target_run == 0 and self.target_fight_begin==0 then
			state.type = "wait"
			self.target_run = BotCtrl:getTime_run()
		elseif self.target_run==self.timeCnt then
		    state.type = "run"
		    local pos = self:getRandomPos()
			state.x = pos.x
			state.y = pos.y
			self:run(pos.x,pos.y)
			self.target_run = 0
			self.target_fight_begin = BotCtrl:getTime_fight_begin()
		elseif self.target_fight_begin==self.timeCnt then
		    state.type = "fightBegin"
		    self.target_fight_begin = 0
		    self:fightBegin()
		    self.target_fight_end = BotCtrl:getTime_fight_end()
		else
		    state.type = "wait"
		end
	end
	return state
end

function BotBiz:timeLoop(time)
	self.timeCnt = time
	local state = {}

	if not self:isOpenFight() then
		return self:logic_noFight()
	else
		return self:logic_fight()
	end
end

function BotBiz:fightBegin()
	self.bot.战斗开关 = true
	BotCtrl:sendMsg2Map(4014,{id=self.bot.id,逻辑=true},self.bot.地图数据.编号)
end

function BotBiz:fightEnd()
	self.bot.战斗开关 = false
	BotCtrl:sendMsg2Map(4014,{id=self.bot.id,逻辑=false},self.bot.地图数据.编号)
end

function BotBiz:run(t_x,t_y)
	if t_x==nil then t_x = math.random(self.bot.地图数据.x-500,self.bot.地图数据.x+500) end
	if t_y==nil then t_y = math.random(self.bot.地图数据.y-500,self.bot.地图数据.y+500) end
	local x = t_x
	local y = t_y
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end

	local ctx = {
		路径 = {
			x = math.floor(x/20),
			y = math.floor(y/20),
		序号 = 1002,
		距离= 0,
		数字id = self.bot.id
		},
		数字id= self.bot.id
	}
	BotCtrl:sendMsg2Map(1008,ctx,self.bot.地图数据.编号)
end

function BotBiz:getRandomPos()
	local pos = {}
	pos.x = math.random(self.bot.地图数据.x-500,self.bot.地图数据.x+500)
	pos.y = math.random(self.bot.地图数据.y-500,self.bot.地图数据.y+500)
	return pos
end

function BotBiz:stopRun()
	local ctx = {
		id = self.bot.id,
		文本 = self.bot.id
	}
end

return BotBiz