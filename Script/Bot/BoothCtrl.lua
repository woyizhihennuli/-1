--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2022-10-02 02:55:22
--======================================================================--
local BoothCtrl = class()

function BoothCtrl:初始化( ... )
	self.minCnt = 0
	self.timeCnt = 0
	self.time_create = 0
	self.create_num = 0
end

function BoothCtrl:minLoop( ... )
	self.minCnt = self.minCnt+1
	BoothDb:boothAdd(self.create_num)
end
function BoothCtrl:timeLoop( ... )
	self.timeCnt = self.timeCnt+1
	if self.timeCnt%2==0 then
		self:minLoop()
	end
end

function BoothCtrl:MsgCtrl(id, msgIdx, arg, ctx)
       --print(ctx.id)
	if msgIdx == 3725 then
		if not BoothDb:isBot(ctx.id) then return false end
		local bot = BoothDb:getBotById(ctx.id)
        --table.print(bot:getItemTable())
		发送数据(玩家数据[arg].连接id,3520,玩家数据[arg].角色.数据.银子)
 		发送数据(玩家数据[arg].连接id,3521,{
 			bb=bot:getBBTable(),  --获取摆摊道具
 			物品=bot:getItemTable(),
 			id=arg,
 			摊主名称=bot.bot.摊位名称,
 			名称=bot.bot.名称
 		})
 		玩家数据[arg].摊位查看=os.time()
 		玩家数据[arg].摊位id=ctx.id
 		return true
	elseif msgIdx == 3726 then
		if not BoothDb:isBot(玩家数据[arg].摊位id) then return false end
		local bot = BoothDb:getBotById(玩家数据[arg].摊位id)
		if ctx.bb == nil then
			self:buyItem(id,arg,ctx.道具,ctx.数量)
		elseif ctx.道具==nil then
			self:buyBB(arg,ctx.bb)
		end
		玩家数据[arg].摊位查看 = os.time() + 1

		玩家数据[arg].摊位id = bot.bot.id

		发送数据(玩家数据[arg].连接id,3520,玩家数据[arg].角色.数据.银子)
		发送数据(玩家数据[arg].连接id,3522,{
			bb=bot:getBBTable(),
			物品=bot:getItemTable(),
			id=bot.bot.id,
			摊主名称=bot.bot.摊位名称,
			名称=bot.bot.名称
		})
	    return true
	end

	return false
end

function BoothCtrl:buyItem(id,userid,idx,num)

	local bot = BoothDb:getBotById(玩家数据[userid].摊位id)
	local lastTime = 玩家数据[userid].摊位查看

	if not bot.itemTable:isNew(lastTime) then
		发送数据(id, 7,"#y/这个摊位的数据已经发生了变化，请重新打开该摊位")
		bot.itemTable:refresh()
		return
	end

	local item = bot:getItemTable()[idx]

	if item == nil then
		发送数据(id, 7,"#Y/这个商品并不存在")
		bot.itemTable:refresh()
		return
	end

	local 临时格子=玩家数据[userid].角色:取道具格子()
	if 临时格子==0 then
		发送数据(id, 7,"#Y/请先整理下包裹吧！")
		return
	end

	if item.数量 == nil then
		item.数量 = 1
	end
	if num <= 0 or num > 99 or item.数量 < num then
		发送数据(id, 7, "#y/请输入正确的购买数量")
		return
	end

	local price = item.价格 * num
	local userMoney = 玩家数据[userid].角色.数据.银子
	if userMoney < price then
		发送数据(id, 7, "#y/你没有那么多的银子")
		return
	end

	玩家数据[userid].角色:扣除银子(price,0,0,"摊位购买",1)
	local 临时格子=玩家数据[userid].角色:取道具格子()
	local 道具id=玩家数据[userid].道具:取新编号()
	local 道具名称=item.名称
	local 道具识别码=item.识别码
	更改道具归属(道具识别码,"bot"..bot.bot.id,bot.bot.id,bot.bot.名称)
	玩家数据[userid].角色:日志记录(format("[摊位系统-购买]购买道具[%s][%s]，花费%s两银子,出售者信息：[%s][%s][%s]",道具名称,道具识别码,price,"bot"..bot.bot.id,bot.bot.id,bot.bot.名称))
	玩家数据[userid].道具.数据[道具id]=table.loadstring(table.tostring(item))
	玩家数据[userid].角色.数据.道具[临时格子]=道具id

	发送数据(id, 7, "#W/购买#R/"..道具名称.."#W/成功！")
	if item.数量 == nil then
		bot:getItemTable()[idx] = nil
	else
	    bot:getItemTable()[idx].数量 = bot:getItemTable()[idx].数量 - num
	    if bot:getItemTable()[idx].数量 <=0 then
	    	bot:getItemTable()[idx] = nil
	    end
	end
	玩家数据[userid].摊位查看 = os.time() + 1
	bot.bbTable:refresh()
	道具刷新(userid)
end

-- 购买宝宝
function BoothCtrl:buyBB(id,idx)
	local bot = BoothDb:getBotById(玩家数据[id].摊位id)
	local lastTime = 玩家数据[id].摊位查看
	if not bot.bbTable:isNew(lastTime) then
		发送数据(玩家数据[id].连接id, 7, "#y/该摊位商品发生了变化，请稍后再试")
		bot.bbTable:refresh()
		return
	end

	local bbTable = bot:getBBTable()[idx]
	if bbTable == nil  then
		发送数据(玩家数据[id].连接id, 7, "#Y/这只召唤兽不存在")
		return
	end

	local price=bbTable.价格

	if #玩家数据[id].召唤兽.数据 >= 14 then
		发送数据(玩家数据[id].连接id, 7, "#y/您当前无法携带更多的召唤兽了")
		return 0
	end

	if 玩家数据[id].角色.数据.银子<price then
		发送数据(玩家数据[id].连接id, 7, "#y/您没有那么多的银子")
		return 0
	end

	local 道具名称=bbTable.名称
	local 道具等级=bbTable.等级
	local 道具模型=bbTable.模型
	local 道具技能=#bbTable.技能

	local 道具识别码=bbTable.认证码
	玩家数据[id].角色:扣除银子(price,0,0,"摊位购买",1)
	玩家数据[id].角色:日志记录(format("[摊位系统-购买]购买道具[%s][%s]，花费%s两银子,出售者信息：[%s][%s][%s]",道具名称,道具识别码,price,"bot"..bot.bot.id,bot.bot.id,bot.bot.名称))
	发送数据(玩家数据[id].连接id,7, "#W/购买#R/"..道具名称.."#W/成功！")
	玩家数据[id].召唤兽.数据[#玩家数据[id].召唤兽.数据+1]=table.loadstring(table.tostring(bbTable))
	bot:getBBTable()[idx]=nil
	发送数据(玩家数据[id].连接id,3512,玩家数据[id].召唤兽.数据)
	bot.bbTable:refresh()
end

function BoothCtrl:initAddTime(arr)
	self.time_create = arr[1]
	self.create_num = arr[2]
end

function BoothCtrl:sendBoothBot(mapId,cid)
	BoothDb:sendBoothBot(mapId,cid)
end

function BoothCtrl:sendMsg2Map( 序号, 内容, 地图)
	for n, v in pairs(地图处理类.地图玩家[地图]) do
		发送数据(玩家数据[n].连接id,序号,内容)
	end
end

return BoothCtrl