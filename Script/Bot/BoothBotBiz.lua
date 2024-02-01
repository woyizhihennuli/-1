--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2022-09-16 01:10:06
--======================================================================--
local BoothBotBiz = class()


function BoothBotBiz:初始化(bot)
	self.bot = bot
	self.bot.x = bot.地图数据.x
	self.bot.y = bot.地图数据.y
	self.itemTable = {}
	self.bbTable = {}
	self:initTable(bot)

end

function BoothBotBiz:initTable(bot)

	self:setItemTable(BoothDb:getItemBoothById(bot.itemTable))
	self:setBBTable(BoothDb:getBBBoothById(bot.BBTable))
end

function BoothBotBiz:setItemTable(source)


	self.itemTable = ItemTableBiz.创建(table.loadstring(table.tostring(source)))

end

function BoothBotBiz:setBBTable(source)
	self.bbTable = BBTableBiz.创建(table.loadstring(table.tostring(source)))
end

function BoothBotBiz:getMapId( )
	return self.bot.地图数据.编号
end

function BoothBotBiz:getItemTable()

	return self.itemTable.item
end

function BoothBotBiz:getBBTable()
	return self.bbTable.bb
end

return BoothBotBiz