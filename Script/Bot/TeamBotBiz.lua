--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2020-09-22 02:10:12
--======================================================================--
local TeamBotBiz = class()


function TeamBotBiz:初始化(botList)
	self.captainBot = nil
	self.teamList = {}

	for i=1,#botList do
		local t_b = BotBiz.创建(botList[i])
		if t_b:isCaptain() then
			self.captainBot = t_b
		else
		    self.teamList[#self.teamList+1] = t_b
		end
	end

	self.timeCnt = 0
end

function TeamBotBiz:timeLoop(time)
	self.timeCnt = time
	local state = self.captainBot:timeLoop(time)
	if state.type == "run" then
		for i=1,#self.teamList do
			self.teamList[i]:run(math.random(state.x-100,state.x+100),math.random(state.y-100,state.y+100))
		end
	elseif state.type == "fightBegin" then
	    for i=1,#self.teamList do
			self.teamList[i]:fightBegin()
		end
	elseif state.type == "fightEnd" then
	    for i=1,#self.teamList do
			self.teamList[i]:fightEnd()
		end
	end
end

function TeamBotBiz:getMapId()
	return self.captainBot.bot.地图数据.编号
end

function TeamBotBiz:getAllBot()
	local arr = {}
	arr[#arr+1] = self.captainBot.bot
	for i=1,#self.teamList do
	 	arr[#arr+1] = self.teamList[i].bot
	end
	return arr
end

return TeamBotBiz