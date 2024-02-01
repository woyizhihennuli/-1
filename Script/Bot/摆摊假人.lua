--======================================================================--
-- @作者: GGE研究群: 34211 9466
-- @创建时间:   2018-03-03 02:34:19
-- @Last Modified time: 2023-05-04 23:13:27
-- 梦幻西游游戏资源破解 baidwwy@vip.qq.com(313738139) 老毕   和 C++PrimerPlus 717535046 这俩位大神破解所有资源
--======================================================================--
local 摆摊假人处理类 = class()

function 摆摊假人处理类:初始化()
    self.open = false
    self.maplist = {
        [1001] = {},
        [1501] = {},
        [1092] = {},
        [1070] = {},
        [1040] = {},
        [1226] = {},
        [1208] = {}
    }
    self.npcUserList = {}
end

function 摆摊假人处理类:addBoothNpc(数据源)
    count = 0
    for i = 1, #数据源 do
        count = count + 1
        假人 = 数据源[i]
        table.insert(self.maplist[假人[1]], 假人)-- 这里将假人放到地图数据中
        key = "" .. 假人[4]
        self.npcUserList[key] = 假人
        if 假人玩家处理类在线 then
            假人玩家处理类:mmmmwq(假人[4],假人[6])
        end
    end
   __S服务:输出("一共增加了[" .. count .. "]个摆摊假人")
end

function 摆摊假人处理类:Refresh()

    for k,v in pairs(self.npcUserList) do
        if v[4] and v[6] then
            local x=假人玩家处理类:mmmmwq(v[4],v[6],1)
             local key = "" .. v[4]
            self.npcUserList[key][8]=x
        end
    end
end

function 摆摊假人处理类:getAllBoothNpcinMap(mapId)-- 获取所有地图上的摆摊NPC数据
    if (self.maplist[mapId] == nil) then
        return {}
    end
    return self.maplist[mapId]
end

function 摆摊假人处理类:假人信息(id)
    return self.npcUserList["" .. id]
end

function 摆摊假人处理类:功能开关(open)
    self.open = open
end

function 摆摊假人处理类:摊位列表(id, mapid,sendFunc)
    if self.open ~= true then
        return
    end
    mapBoothNpcs = self:getAllBoothNpcinMap(mapid)
    if 假人玩家处理类在线 then
        假人玩家处理类:ltop(id, mapid,sendFunc,mapBoothNpcs)
    else
        for i = 1, #mapBoothNpcs do
            ndata = mapBoothNpcs[i]
            local ctx = {
                x = ndata[2] * 20,
                y = ndata[3] * 20,
                id = ndata[4],
                名称 = ndata[5],
                摊位名称 = ndata[6],
                模型 = ndata[7],
            }
            发送数据(id,1006,ctx)
        end
    end
end

function 摆摊假人处理类:索要摊位(id,botId)
	local bot = self:假人信息(botId)
	if bot ~= nil then
        if 假人玩家处理类在线 then
            假人玩家处理类:mall(bot[5],bot[6],botId,id,bot[1])
        else
            local ctx = {
                bb={},
                摊主名称=bot[5],
                物品 = {},
                名称= bot[6],
                id = botId
            }
            发送数据(id,3521,ctx)
        end
	end
end

return 摆摊假人处理类