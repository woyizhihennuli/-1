--======================================================================--
-- @作者: GGE研究群: 342119466
-- @创建时间:   2018-03-03 02:34:19
-- @Last Modified time: 2022-09-22 17:11:53
-- 梦幻西游游戏资源破解 baidwwy@vip.qq.com(313738139) 老毕   和 C++PrimerPlus 717535046 这俩位大神破解所以资源
--======================================================================--
local 对话处理类 = class()
local format = string.format
local insert = table.insert
local ceil = math.ceil
local floor = math.floor
local wps = 取物品数据
local typ = type
local 五行_ = {"金","木","水","火","土"}
local 对话内容 = require("script/对话处理类/对话内容")()
local 对话处理 = require("script/对话处理类/对话处理")()
local NPC商业栏 = require("script/对话处理类/商业对话")()
local NPC帮派商业栏 = require("script/对话处理类/帮派商业对话")()
local 召唤兽处理类=require("Script/角色处理类/召唤兽处理类")()
function 对话处理类:初始化()end

function 对话处理类:数据处理(id,序号,数字id,内容)
  数字id=数字id+0
  id=id+0
  if 序号==1501 then
    对话内容:索取对话内容(id,数字id,序号,内容)
  elseif 序号==1502 then
    对话处理:选项解析(id,数字id,序号,内容)
  elseif 序号==1503 then --摩托修改商店返回来的数据
    NPC商业栏:购买商品(id,数字id,序号,内容)
  elseif 序号==1503.1 then --摩托修改钓鱼积分商店返回来的数据
    NPC商业栏:购买商品1(id,数字id,序号,内容)
  elseif 序号==1504 then --
    NPC帮派商业栏:购买商品(id,数字id,序号,内容)
  elseif 序号==1505 then --
    NPC帮派商业栏:出售商品(id,数字id,序号,内容)
  elseif 序号==1506 then
    for i=1,#房屋数据 do
      if 房屋数据[i].ID == tonumber(内容.房屋ID) then
        发送数据(玩家数据[数字id].连接id,1026,{房屋数据[i]})
        地图处理类:跳转地图(数字id,房屋数据[i].庭院ID,21,27)
        房屋数据[i].访问ID[#房屋数据[i].访问ID+1]=数字id
        return
      end
    end
    常规提示(数字id,"#Y您查找的ID还没有房子！")
    elseif 序号 ==1507 then
      for n =1,100 do
        if 玩家数据[数字id].角色.数据.道具[n]~=nil then
          local 道具id =玩家数据[数字id].角色.数据.道具[n]
          if 玩家数据[数字id].道具.数据[道具id].名称 =="鱼竿" then
            local ss = n
            if 玩家数据[数字id].道具.数据[道具id].数量 >=1 then
              local 物品 = {"青龙石","白虎石","朱雀石","玄武石","彩果","超级金柳露","海马","魔兽要诀","高级魔兽要诀","点化石","附魔宝珠","神兜兜","金柳露"}  --额外的物品
              local xx=物品[取随机数(1,#物品)]
              if 取随机数()<=30 then        ----鱼的几率
              玩家数据[数字id].道具:给予道具(数字id,内容.物品,1)
                if 取随机数()<=10 then    ---物品的几率   100=100%
                玩家数据[数字id].道具:给予道具(数字id,xx,1)
                常规提示(数字id,"#Y钓鱼人品大发，额外获得一块#R"..xx)
                广播消息({内容=format("#S(钓鱼提示)#R/#G%s#Y钓鱼时，人品大发，钓到了一件[#G/%s#Y]#80",玩家数据[数字id].角色.数据.名称,xx),频道="xt"})
                end
                玩家数据[数字id].角色.数据.钓鱼积分=玩家数据[数字id].角色.数据.钓鱼积分+1
              常规提示(数字id,"#Y你钓到了一条#R"..内容.物品)
              常规提示(数字id,"#Y获得钓鱼积分一点#72")
              else
               常规提示(数字id,"#Y你钓到了一条#R"..内容.物品.."#Y可惜被它溜走了")
              end
              玩家数据[数字id].道具:删除道具(玩家数据[数字id].连接id,数字id,"道具",道具id,道具id,删除数量)
              道具刷新(数字id)
              return
            end
          end

 end
      end
  elseif 序号==1506 then
    for i=1,#房屋数据 do
      if 房屋数据[i].ID == tonumber(内容.房屋ID) then
        发送数据(玩家数据[数字id].连接id,1026,{房屋数据[i]})
        地图处理类:跳转地图(数字id,房屋数据[i].庭院地图,21,27)
        房屋数据[i].访问ID[#房屋数据[i].访问ID+1]=数字id
        return
      end
    end
    常规提示(数字id,"#Y您查找的ID还没有房子！")
  end
end

function 对话处理类:获取任务对话(x,y)end
function 对话处理类:更新(dt)end
function 对话处理类:显示(x,y)end
return 对话处理类