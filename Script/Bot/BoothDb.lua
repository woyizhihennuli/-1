--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2022-11-28 14:53:37
--======================================================================--
local BoothDb = class()

function BoothDb:初始化()
	self.itemDb = {}
	self.bbDb = {}

	self.mapTable = {}

	self.boothIdTable = {}

	self.list_booth = {}

	self.temp_list_booth = {}

	self.boothNum = 0

end

function BoothDb:addBoothBot(srcArr)

	for i=1,#srcArr do
		local biz = BoothBotBiz.创建(srcArr[i])
		self.temp_list_booth[i] = biz
		self.boothIdTable[biz.bot.id] = true
	end

	syslog("刻晴假人:添加了["..#self.temp_list_booth.."]个假人摊位")
end

function BoothDb:boothAdd(num)
	if (#self.temp_list_booth) == 0 then
		return
	end
	local arr = {}
	for i=1,num do
		self.boothNum = self.boothNum+1
		arr[i] = self.temp_list_booth[1]
		local biz = self.temp_list_booth[1]
		self.list_booth[biz.bot.id] = arr[i]
		table.remove(self.temp_list_booth,1)

		local mapId =biz:getMapId()
		if self.mapTable[mapId] == nil then self.mapTable[mapId] = {} end
		local mapt = self.mapTable[mapId]
		mapt[#mapt+1] = biz

		BoothCtrl:sendMsg2Map( 1006, arr[i].bot, arr[i].bot.地图数据.编号)
		if (#self.temp_list_booth) == 0 then
			break
		end
	end

	__S服务:输出("线性加载了["..#arr.."]个摆摊假人,当前摆摊假人总数为["..self.boothNum.."]")
end

function BoothDb:initItemTable(srcArr) --加载道具

   self.itemDb={}
	for i=1,#srcArr do
	   local 随机物品={}
	   for n=1,#srcArr[i] do
         if 取随机数()<=70 and #随机物品<20 then --最多取20个
         	随机物品[#随机物品+1]=srcArr[i][n]
         end
	   end
		self.itemDb[i] = 随机物品--srcArr[i]
	end

	syslog("刻晴假人:初始化了["..#self.itemDb.."]个道具橱窗")
end

function BoothDb:initBBTable(srcArr)
	self.bbDb={}
	for i=1,#srcArr do
	   local 随机宝宝={}
	   for n=1,#srcArr[i] do
         if 取随机数()<=70 and #随机宝宝<8 then --最多取20个
         	随机宝宝[#随机宝宝+1]=srcArr[i][n]
         end
	   end
	   		self.bbDb[i] = 随机宝宝--srcArr[i]
	end
	syslog("刻晴假人:初始化了["..#self.bbDb.."]个宠物橱窗")
end

function BoothDb:getItemBoothById(id)
	if self.itemDb[id] == nil then
		return {}
	end
	return self.itemDb[id]
end

function BoothDb:getBBBoothById(id)
	if self.bbDb[id] == nil then
	    return {}
	end
	return self.bbDb[id]
end

function BoothDb:sendBoothBot(mapid,cid)
	local botArr = self.mapTable[mapid]
	if botArr ~= nil then
		self:sendBotList2User(botArr,cid)
	end
end

function BoothDb:getBotById(id)
	return self.list_booth[id]
end

function BoothDb:sendMsg2Map( 序号, 内容, 地图)
	for n, v in pairs(地图处理类.地图玩家[地图]) do
		发送数据(玩家数据[n].连接id,序号,内容)
	end
end

function BoothDb:sendBotList2User( botArr ,id)
	for i=1,#botArr do
		发送数据(id,1006,botArr[i].bot)
	end
end

function BoothDb:isBot(id)
	return self.boothIdTable[id] == true
end


return BoothDb