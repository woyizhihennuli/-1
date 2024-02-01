--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2020-09-22 02:09:50
--======================================================================--
local BotCtrl = class()
function BotCtrl:初始化( ... )
	self.time_fight_begin_min = 0
	self.time_fight_begin_max = 0
	self.time_fight_end_min = 0
	self.time_fight_end_max = 0
	self.time_run_min = 0
	self.time_run_max = 0

	self.time_create = 0
	self.create_num = 0

	self.timeCnt = 0

	self.minCnt = 0
end

function BotCtrl:getTime_fight_begin()
	return self.timeCnt+math.random(self.time_fight_begin_min,self.time_fight_begin_max)
end
function BotCtrl:getTime_fight_end()
	return self.timeCnt+math.random(self.time_fight_end_min,self.time_fight_end_max)
end
function BotCtrl:getTime_run()
	return self.timeCnt+math.random(self.time_run_min,self.time_run_max)
end

function BotCtrl:minLoop( )
	self.minCnt = self.minCnt + 1
	if self.minCnt % self.time_create == 0 then
		BotDb:botAdd(self.create_num)
		BotDb:teamBotAdd(self.create_num)
	end
end

function BotCtrl:timeLoop()
	self.timeCnt = self.timeCnt + 1
	if self.timeCnt %2 == 0 then
		self:minLoop()
	end
	BotDb:timeLoop(self.timeCnt)
end


function BotCtrl:initShowNumberCtrl(arr)
	self.time_create = arr[1]
	self.create_num = arr[2]
end

function BotCtrl:initFightTime(fightTime)
	self.time_fight_begin_min = fightTime[1]
	self.time_fight_begin_max = fightTime[2]
	self.time_fight_end_min = fightTime[3]
	self.time_fight_end_max = fightTime[4]
end

function BotCtrl:initRunTime(runTime)
	self.time_run_min = runTime[1]
	self.time_run_max = runTime[2]
end

function BotCtrl:sendMsg2Map( 序号, 内容, 地图)
	for n, v in pairs(地图处理类.地图玩家[地图]) do
		发送数据(玩家数据[n].连接id,序号,内容)
	end
end
function BotCtrl:sendBotList2User( botArr ,id)
	for i=1,#botArr do
		botArr[i].x = botArr[i].地图数据.x
		botArr[i].y = botArr[i].地图数据.y
		发送数据(id,1006,botArr[i])
	end
end

--
function BotCtrl:sendBot(map,cid)
	BotDb:sendBotList2User(map,cid)
	BotDb:sendTeamBotList2User(map,cid)
end



return BotCtrl