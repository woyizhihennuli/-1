-- @Author: baidwwy
-- @Date:   2023-03-10 11:49:10
-- @Last Modified by:   baidwwy
-- @Last Modified time: 2024-01-30 21:35:52


localmp = require("ForYourOwnUse/MessagePack")
__S服务 = require("ForYourOwnUse/PackServer")('服务','-->内网连接')
__S服务.发送_ = __S服务.发送

function __S服务:发送(id,...)   self:发送_(id,localmp.pack{...})

end
function __S服务:gm发送(id,...) self:发送_(id,localmp.pack{...})
end


--else
 -- __S服务 = require("Script/ggeserver")()
--end

__S服务:置工作线程数量(500)
__S服务:置预投递数量(5000)
-- __S服务:置心跳检查次数(5000)
-- __S服务:置心跳检查间隔(1000)
随机序列=0
错误日志={}
__N连接数  = 0
__C客户信息   = {}
fgf="123229*-*123229"
fgc="123229@+@123229"
NB开关 = false
服务端参数={}
服务端参数.运行时间=0
服务端参数.启动时间=os.time()
服务端参数.分钟=os.date("%M", os.time())
服务端参数.小时=os.date("%H", os.time())
--加载类
require("lfs")
程序目录=lfs.currentdir()..[[\]]
初始目录=程序目录
format = string.format
星期=  os.date("%w")
f函数=require("ffi函数2")
ffi = require("ffi")
无双西游=false
盒子账号="5571696"
盒子名称="泰迪"
版本 = 13.65
服务端参数.端口=7089

管理账号=f函数.读配置(程序目录.."配置文件.ini","主要配置","管理账号")




function 信息框(msg,title,type)
  ffi.C.MessageBoxA(nil, msg, title or '信息', mtype or 0)
end

机器码= f函数.读配置(程序目录.."配置文件.ini","主要配置","机器码")
服务器名称 =  f函数.读配置(程序目录.."配置文件.ini","主要配置","服务器名称")
-- 有网关了，内网IP固定为127.0.0.2
调试模式=false
服务端参数.ip="127.0.0.2"

跨服限制等级 =  f函数.读配置(程序目录.."配置文件.ini","主要配置","跨服限制等级")+0
-----
池定制=true ---不要神树 抽奖什么的
-----
-- 服务器名称 = f函数.读配置(程序目录.."配置文件.ini","主要配置","服务器名称")

武神坛活动=false
微变爆率=false
GM工具=true
吊游定制=true
神树抽奖=true
助战消费=true
七七定制=true  ---称号加成
追忆年华=true
神兽定制=true --跑商有关
烹饪三药定制=false
五虎上将定制=true
定制八卦炉=false
钟灵石定制=true
刻晴定制=false --经验*3
强化技能=true  --false
二级药品定制=false
新手召唤兽定制=false
定制装备融合=true
侠义任务定制=false --嘎嘎 无用
福利宝箱=true
魔化沙僧=false--嘎嘎 无用
魔化取经=false--嘎嘎 无用
七十二地煞星=false--嘎嘎 无用
结婚定制=true
文韵墨香开启=false

-- 年兽定制=true
-- 房屋开关=true
VIP定制=true
if 服务端参数.ip== "127.0.0.2" then
假人系统=true
else
   假人系统=true
end
帮战开关=false
帮战进入=false
-- 时间限制 = {计时 = 20,开关 = true,起始 = os.time()}

服务器关闭 = {计时 = 300,开关 = false,起始 = os.time()}
跑镖遇怪时间 = {计时 = 120,开关 = false,起始 = os.time()}

require("Script/角色处理类/符石组合类")
require("Script/数据中心/宝宝")
require("Script/数据中心/宝图")
require("Script/数据中心/变身卡")
require("Script/数据中心/场景NPC")
require("Script/数据中心/场景等级")
require("Script/数据中心/场景名称")
require("Script/数据中心/传送圈位置")
require("Script/数据中心/传送位置")
require("Script/数据中心/法术技能特效")
require("Script/数据中心/活动")
require("Script/数据中心/角色")
require("Script/数据中心/明暗雷怪")
require("Script/数据中心/取经验")
require("Script/数据中心/取师门")
require("Script/数据中心/染色")
require("Script/数据中心/物品")
require("Script/数据中心/野怪")
require("Script/数据中心/装备特技")
require("Script/系统处理类/共用")
require("Script/数据中心/符石组合")
require("Script/数据中心/场景NPC1")
require("Script/角色处理类/仿官打造属性")



物品类=require("Script/角色处理类/内存类_物品")
宝宝类=require("Script/角色处理类/宝宝")
地图坐标类=require("Script/地图处理类/地图坐标类")
路径类=require("Script/地图处理类/路径类")
地图处理类=require("Script/地图处理类/地图处理类")()


-----下面假人摆摊本来是没开启的
假人玩家处理类在线 =true
假人玩家处理类 = require("Script/Bot/CatBooth")()
if 假人玩家处理类==nil then 假人玩家处理类在线=false end
摆摊假人处理类 = require("Script/Bot/摆摊假人")()

假人代码 = loadstring(读入文件([[摆摊假人.txt]]))
摆摊假人处理类:addBoothNpc(假人代码())
摆摊假人处理类:功能开关(false)--默认开启



if 假人系统 then
  json = require("Script/Bot/json")
  BBTableBiz = require("Script/Bot/BBTableBiz")
  BoothBotBiz = require("Script/Bot/BoothBotBiz")
  ItemTableBiz = require("Script/Bot/ItemTableBiz")
  BoothDb = require("Script/Bot/BoothDb").创建()
  假人初始化=require("Script/Bot/BoothDb")
  BoothCtrl = require("Script/Bot/BoothCtrl").创建()
  BotBiz = require("Script/Bot/BotBiz")
  TeamBotBiz = require("Script/Bot/TeamBotBiz")
  BotDb = require("Script/Bot/BotDb").创建()
  BotCtrl = require("Script/Bot/BotCtrl").创建()
 --ChatDb = require("Script/Bot/ChatDb").创建()
 -- ChatCtrl = require("Script/Bot/ChatCtrl").创建()
  BotManager = require("Script/Bot/BotManager").创建()

  end
账号记录={}
房屋数据={}


网络处理类=require("Script/系统处理类/网络处理类")()
系统处理类=require("Script/系统处理类/系统处理类")()
聊天处理类=require("Script/系统处理类/聊天处理类")()
任务处理类=require("Script/系统处理类/任务处理类")()




管理工具类=require("Script/系统处理类/管理工具类")()
游戏活动类=require("Script/系统处理类/游戏活动类")()
角色处理类=require("Script/角色处理类/角色处理类")
道具处理类=require("Script/角色处理类/道具处理类")
装备处理类=require("Script/角色处理类/装备处理类")
礼包奖励类=require("Script/角色处理类/礼包奖励类")()
通用道具=require("Script/角色处理类/道具处理类")()
帮派处理类=require("Script/角色处理类/帮派处理类")()
数据库类 = require("Script/数据库处理/数据库处理类")()
自动任务类 = require("Script/数据库处理/自动任务类")()
自动挂机类 = require("Script/数据库处理/自动挂机类")()
对话处理类=require("Script/对话处理类/初始")()
商店处理类=require("Script/商店处理类/商店处理类")()
商城处理类 = require("Script/商店处理类/商城处理类")()
队伍处理类=require("Script/角色处理类/队伍处理类")()
战斗准备类=require("Script/战斗处理类/战斗准备类")()
战斗处理类=require("Script/战斗处理类/战斗处理类")
召唤兽处理类=require("Script/角色处理类/召唤兽处理类")

助战处理类=require("Script/角色处理类/助战系统")
孩子处理类=require("Script/角色处理类/孩子处理类")    --新增文件
商城神兽=require("Script/数据中心/商城神兽")
召唤兽仓库类=require("Script/角色处理类/召唤兽仓库类")
商店处理类:刷新珍品()
商店处理类:刷新跑商商品买入价格()
商城处理类:加载商品()
管理工具类2=require("Script/系统处理类/管理工具类2")()
管理工具类3=require("Script/系统处理类/管理工具类3")()
幻化处理类=require("Script/角色处理类/幻化处理类")()
打造处理类=require("Script/角色处理类/打造处理类")()
刷怪处理=require("Script/系统处理类/刷怪处理")()
全局坐骑资料=require("script/数据中心/坐骑库")()
拍卖系统类=require("Script/系统处理类/拍卖系统类")()
帮战活动类=require("Script/系统处理类/帮战活动类")()
--家园系统类=require("Script/系统处理类/家园系统类")()
--副本脚本加载
副本处理类=require("Script/副本处理类/副本处理类")()
多开系统类=require("Script/角色处理类/多开系统")()

武神坛系统类=require("Script/武神坛系统/武神坛系统类")()
充值礼包类 = require("Script/商店处理类/充值礼包类")()



老猫附体=false

临时题库 = 读入文件("sjtk.txt")
临时题库 = 分割文本(临时题库, "*")
三界题库 = {}
铃铛记录 = {}
for n = 1, #临时题库 do
  临时题库[n] = 分割文本(临时题库[n], "？")
  三界题库[n] = {
    问题 = 临时题库[n][1],
    答案 = 临时题库[n][2]
  }
end
三界书院 = {答案 = "",开关 = false,结束 = 60,起始 = os.time(),间隔 = 取随机数(60, 90) * 60,名单 = {}}






function 获取IP限制数()
  return f函数.读配置(程序目录 .. "配置文件.ini", "主要配置", "多开限制")+0
end
IP限制数 = 获取IP限制数()
function 加载排行榜()
  排行榜数据=table.loadstring(读入文件([[tysj/排行榜.txt]]))
 -- __S服务:输出("-----------------------------------------------加载排行榜完成")
end
加载排行榜()
function 刷新排行榜(id)
  local 符合=true
  符合=true

  for k=1,#排行榜数据.玩家伤害排行 do
    if 排行榜数据.玩家伤害排行[k].id==id then
      if 排行榜数据.玩家伤害排行[k].分数==玩家数据[id].角色.数据.伤害 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家伤害排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家伤害排行[#排行榜数据.玩家伤害排行+1]={id=id,分数=玩家数据[id].角色.数据.伤害,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家伤害排行>=1 then

    table.sort(排行榜数据.玩家伤害排行,function(a,b) return a.分数>b.分数 end )
    -- for i=1,#排行榜数据.玩家伤害排行 do
    -- end
  end
  if #排行榜数据.玩家伤害排行>10 then --长度大于10则删除10以后的元素
    for m=11,#排行榜数据.玩家伤害排行 do
      table.remove(排行榜数据.玩家伤害排行)
    end
  end

  --刷新玩家灵力排行
  符合=true
  for k=1,#排行榜数据.玩家灵力排行 do
    if 排行榜数据.玩家灵力排行[k].id==id then
      if 排行榜数据.玩家灵力排行[k].分数==玩家数据[id].角色.数据.灵力 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家灵力排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家灵力排行[#排行榜数据.玩家灵力排行+1]={id=id,分数=玩家数据[id].角色.数据.灵力,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家灵力排行>=1 then
    table.sort(排行榜数据.玩家灵力排行,function(a,b) return a.分数>b.分数 end )
    -- for i=1,#排行榜数据.玩家灵力排行 do
      --print("灵力",排行榜数据.玩家灵力排行[i].id,排行榜数据.玩家灵力排行[i].名称,排行榜数据.玩家灵力排行[i].分数)
    -- end
  end
  if #排行榜数据.玩家灵力排行>10 then --长度大于10则删除10以后的元素
    for m=11,#排行榜数据.玩家灵力排行 do
      table.remove(排行榜数据.玩家灵力排行)
    end
  end

  --刷新玩家防御排行
  符合=true
  for k=1,#排行榜数据.玩家防御排行 do
    if 排行榜数据.玩家防御排行[k].id==id then
      if 排行榜数据.玩家防御排行[k].分数==玩家数据[id].角色.数据.防御 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家防御排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家防御排行[#排行榜数据.玩家防御排行+1]={id=id,分数=玩家数据[id].角色.数据.防御,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家防御排行>=1 then
    table.sort(排行榜数据.玩家防御排行,function(a,b) return a.分数>b.分数 end )
    -- for i=1,#排行榜数据.玩家防御排行 do
      --print("防御",排行榜数据.玩家防御排行[i].id,排行榜数据.玩家防御排行[i].名称,排行榜数据.玩家防御排行[i].分数)
    -- end
  end
  if #排行榜数据.玩家防御排行>10 then --长度大于10则删除10以后的元素
    for m=11,#排行榜数据.玩家防御排行 do
      table.remove(排行榜数据.玩家防御排行)
    end
  end

 --刷新玩家仙玉排行
  符合=true
  local 仙玉=f函数.读配置(程序目录..[[data\]]..玩家数据[id].账号..[[\账号信息.txt]],"账号配置","仙玉")+0
  for k=1,#排行榜数据.玩家仙玉排行 do
    if 排行榜数据.玩家仙玉排行[k].id==id then
      if 排行榜数据.玩家仙玉排行[k].分数==仙玉 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家仙玉排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家仙玉排行[#排行榜数据.玩家仙玉排行+1]={id=id,分数=仙玉,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家仙玉排行>1 then
    table.sort(排行榜数据.玩家仙玉排行,function(a,b) return a.分数>b.分数 end )
  end
  if #排行榜数据.玩家仙玉排行>10 then --长度大于10则删除10以后的元素
    for m=11,#排行榜数据.玩家仙玉排行 do
      table.remove(排行榜数据.玩家仙玉排行)
    end
  end

----------------------------------------------------------------------------------------------------

  符合=true
  local 等级=玩家数据[id].角色.数据.等级
  for k=1,#排行榜数据.玩家等级排行 do
    if 排行榜数据.玩家等级排行[k].id==id then
      if 排行榜数据.玩家等级排行[k].分数==等级 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家等级排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家等级排行[#排行榜数据.玩家等级排行+1]={id=id,分数=等级,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家等级排行>1 then
    table.sort(排行榜数据.玩家等级排行,function(a,b) return a.分数>b.分数 end )
  end
  if #排行榜数据.玩家等级排行>10 then --长度大于10则删除10以后的元素
    for m=11,#排行榜数据.玩家等级排行 do
      table.remove(排行榜数据.玩家等级排行)
    end
  end

 --刷新玩家财富排行
  符合=true
  for k=1,#排行榜数据.玩家财富排行 do
    if 排行榜数据.玩家财富排行[k].id==id then
      if 排行榜数据.玩家财富排行[k].分数==玩家数据[id].角色.数据.银子 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家财富排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家财富排行[#排行榜数据.玩家财富排行+1]={id=id,分数=玩家数据[id].角色.数据.银子,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家财富排行>=1 then
   table.sort(排行榜数据.玩家财富排行,function(a,b) return a.分数>b.分数 end )
  end
  if #排行榜数据.玩家财富排行>10 then
    for m=11,#排行榜数据.玩家财富排行 do
      table.remove(排行榜数据.玩家财富排行)
    end
  end

 --刷新玩家气血排行
  符合=true
  for k=1,#排行榜数据.玩家气血排行 do
    if 排行榜数据.玩家气血排行[k].id==id then
      if 排行榜数据.玩家气血排行[k].分数==玩家数据[id].角色.数据.最大气血 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家气血排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家气血排行[#排行榜数据.玩家气血排行+1]={id=id,分数=玩家数据[id].角色.数据.最大气血,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家气血排行>=1 then
    --if a==nil or b==0 then return end
    table.sort(排行榜数据.玩家气血排行,function(a,b) return a.分数>b.分数 end )
    for i=1,#排行榜数据.玩家气血排行 do
      --print("防御",排行榜数据.玩家防御排行[i].id,排行榜数据.玩家防御排行[i].名称,排行榜数据.玩家防御排行[i].分数)
    end
  end
  if #排行榜数据.玩家气血排行>10 then --长度大于10则删除10以后的元素
    for m=11,#排行榜数据.玩家气血排行 do
      table.remove(排行榜数据.玩家气血排行)
    end
  end

  --刷新玩家速度排行
  符合=true
  for k=1,#排行榜数据.玩家速度排行 do
    if 排行榜数据.玩家速度排行[k].id==id then
      if 排行榜数据.玩家速度排行[k].分数==玩家数据[id].角色.数据.速度 then --id一样,数据一样,则不符合
        符合=false
      else
        table.remove(排行榜数据.玩家速度排行,k)
      end
      break
    end
  end
  if 符合 then
    排行榜数据.玩家速度排行[#排行榜数据.玩家速度排行+1]={id=id,分数=玩家数据[id].角色.数据.速度,名称=玩家数据[id].角色.数据.名称}
  end
  if #排行榜数据.玩家速度排行>=1 then
    table.sort(排行榜数据.玩家速度排行,function(a,b) return a.分数>b.分数 end )
    for i=1,#排行榜数据.玩家速度排行 do
      --print("速度",排行榜数据.玩家速度排行[i].id,排行榜数据.玩家速度排行[i].名称,排行榜数据.玩家速度排行[i].分数)
    end
  end

  if #排行榜数据.玩家速度排行>10 then --长度大于10则删除10以后的元素
    for m=11,#排行榜数据.玩家速度排行 do
      table.remove(排行榜数据.玩家速度排行)
    end
  end
  写出文件([[tysj/排行榜.txt]],table.tostring(排行榜数据))
end

数据存档 = {}

function 循环函数()
  -- if 神兽开服时间~=nil and os.time()-神兽开服时间>=0 then
  --   os.exit()
  -- end

  服务端参数.运行时间=服务端参数.运行时间+1
  if 战斗准备类 ~= nil then
    战斗准备类:更新(dt)
  end

  -- for n,v in pairs(__C客户信息) do
  --   if __C客户信息[n]~=nil  then
  --       发送数据(n,76541,os.time())  --每秒给客户端发送一个时间做为认证使用
  --   end
  -- end
  if 任务处理类 ~= nil then
    任务处理类:更新()
  end

  if os.time()-塔怪刷新>=600 then
    任务处理类:设置大雁塔怪(id)
    塔怪刷新=os.time()
  elseif os.time()-剑会匹配>=5 then
     系统处理类:剑会天下单人匹配处理()
     系统处理类:剑会天下三人匹配处理()
     系统处理类:剑会天下五人匹配处理()
     剑会匹配=os.time()
  elseif os.time()-年兽>=7200 then
  商店bb={}
  变异商店bb={}
    --任务处理类:捣乱的年兽()
  年兽=os.time()
  elseif os.time()-水果刷新>=1200 then
  任务处理类:捣乱的水果(id)
  水果刷新=os.time()
  elseif os.time()-天庭叛逆刷新>=1500 then
  任务处理类:设置天庭叛逆(id)
  天庭叛逆刷新=os.time()
  elseif os.time()-建邺东海刷新>=900 then
    任务处理类:设置建邺东海小活动(id)
    建邺东海刷新=os.time()
  elseif os.time()-保存数据>=600 then
    保存系统数据()
    保存数据=os.time()
  elseif os.time()-异步保存数据>=15 then
    保存玩家数据()
    异步保存数据=os.time()
  end
  时辰函数()
  if os.time()-服务端参数.启动时间>=1 then
    整秒处理(os.date("%S", os.time()))
    服务端参数.启动时间=os.time()
  end
  if os.date("%X", os.time())==os.date("%H", os.time())..":00:00" then
    整点处理(os.date("%H", os.time()))
  elseif 服务端参数.分钟~=os.date("%M", os.time()) and os.date("%S", os.time())=="00" then
    整分处理(os.date("%M", os.time()))
  end

  if os.time()-副本更新>=1 then
    if 副本处理类 ~= nil then
      副本处理类:更新()
    end
    副本更新=os.time()
  end
end


function 藏宝阁更新()
  local 改变 = false
  for i,v in pairs(藏宝阁数据) do
    for n=1,#藏宝阁数据[i] do
      if 藏宝阁数据[i][n] ~= nil and os.time() > 藏宝阁数据[i][n].结束时间 then
        local id = 藏宝阁数据[i][n].所有者
        if i ~= "银两" and i ~= "召唤兽" and i ~= "角色" then
          if 寄存数据[id] == nil then
            寄存数据[id] = {[1]={类型="物品",物品=藏宝阁数据[i][n].物品}}
          else
            寄存数据[id][#寄存数据[id]+1] = {类型="物品",物品=藏宝阁数据[i][n].物品}
          end
        elseif i == "银两" then
          if 寄存数据[id] == nil then
            寄存数据[id] = {[1]={类型="银子",数额=藏宝阁数据[i][n].数额}}
          else
            寄存数据[id][#寄存数据[id]+1] = {类型="银子",数额=藏宝阁数据[i][n].数额}
          end
        elseif i == "召唤兽" then
          if 寄存数据[id] == nil then
            寄存数据[id] = {[1]={类型="召唤兽",召唤兽=藏宝阁数据[i][n].召唤兽}}
          else
            寄存数据[id][#寄存数据[id]+1] = {类型="召唤兽",召唤兽=藏宝阁数据[i][n].召唤兽}
          end
        elseif i == "角色" then
          local 角色信息 = table.loadstring(读入文件([[data/]]..藏宝阁数据.角色[n].角色信息.账号..[[/]]..藏宝阁数据.角色[n].所有者..[[/角色.txt]]))
          角色信息.藏宝阁出售 = nil
          写出文件([[data/]]..藏宝阁数据.角色[n].角色信息.账号..[[/]]..藏宝阁数据.角色[n].所有者..[[/角色.txt]],table.tostring(角色信息))
          角色信息 = nil
        end
        table.remove(藏宝阁数据[i],n)
        改变 = true
      end
    end
  end
  if 改变 then
    for i,v in pairs(观察藏宝阁数据) do
      if 玩家数据[i] ~= nil then
        发送数据(玩家数据[i].连接did,12205 , 藏宝阁数据)
      else
          玩家数据[i] = nil
      end
    end
  end
end



function 整秒处理(时间)
  -- if 时间%10 == 0 then
  --   print("清理掉线用户")
  --   __S服务:断开超时连接(10000)
  -- end
  if 三界书院.开关 and 三界书院.结束 <= os.time() - 三界书院.起始 then
    三界书院.开关 = false
    for n = 1, #三界书院.名单 do
      if 玩家数据[三界书院.名单[n].id] ~= nil then
        玩家数据[三界书院.名单[n].id].道具:给予道具(三界书院.名单[n].id,"金银锦盒",5)
        玩家数据[三界书院.名单[n].id].角色:添加银子(1000,"答题",1)
        添加仙玉(5,玩家数据[三界书院.名单[n].id].账号,三界书院.名单[n].id,"答题")
      end
    end
    广播消息({内容="#Y/正确答案：#R/" .. 三界书院.答案,频道="xt"})
    if #三界书院.名单 == 0 then
      广播消息({内容="#Y/真是遗憾，竟然无人可以回答正确。",频道="xt"})
    else
      local 卡片等级=取随机数(1,3)
      广播消息({内容="#Y/知识就是金钱，每一位作答正确的玩家均获得1000银子，5仙玉以作奖励#G".. 三界书院.名单[1].名称 .. "#Y/以#R/" .. 三界书院.名单[1].用时 .. "#Y/秒惊人的飞速抢先作答正确，获得了额外的#G/10#Y/个金银锦盒和一张#G/"..卡片等级.."#Y/级怪物卡片的奖励和2000银子，10点仙玉",频道="xt"})
      if 玩家数据[三界书院.名单[1].id] ~= nil then
        玩家数据[三界书院.名单[1].id].角色:添加银子(2000,"答题",1)
        添加仙玉(10,玩家数据[三界书院.名单[1].id].账号,三界书院.名单[1].id,"答题")
        玩家数据[三界书院.名单[1].id].道具:给予道具(三界书院.名单[1].id, "金银锦盒",10)
        玩家数据[三界书院.名单[1].id].道具:给予道具(三界书院.名单[1].id, "怪物卡片", 卡片等级)
        常规提示(三界书院.名单[1].id,"你获得了一张"..卡片等级.."级怪物卡片和10个金银锦盒！")
      end
    end
  end

  if 假人系统 then
    BotManager:secondLoop()
  end

  for n, v in pairs(玩家数据) do
    if 玩家数据[n].角色:取任务(300)~=0 then
      if 玩家数据[n].角色.数据.跑镖遇怪时间 ~= nil and 玩家数据[n].角色.数据.跑镖遇怪时间<= os.time() then
        任务处理类:跑镖遇怪()
      end
    end
  end

  for n, v in pairs(玩家数据) do
    if 玩家数据[n].角色.数据.帮派限时属性 == nil then
       玩家数据[n].角色.数据.帮派限时属性 = os.time()
    end
    if  玩家数据[n].角色.数据.帮派限时属性开关  == nil then
       玩家数据[n].角色.数据.帮派限时属性开关 = 1
    end
    if 玩家数据[n].角色.数据.帮派限时属性 ~= nil and 玩家数据[n].角色.数据.帮派限时属性开关 == true and 玩家数据[n].角色.数据.帮派限时属性 < os.time() then
      玩家数据[n].角色.数据.帮派限时属性开关 = false
    end
    if 玩家数据[n].角色.数据.帮派限时属性开关 == false then
      玩家数据[n].角色.数据.最大气血=玩家数据[n].角色.数据.最大气血-500
      玩家数据[n].角色.数据.伤害=玩家数据[n].角色.数据.伤害-150
      玩家数据[n].角色.数据.防御=玩家数据[n].角色.数据.防御-50
      玩家数据[n].角色.数据.帮派限时属性开关 = 1
    end
  end
  if 服务器关闭 ~= nil and 服务器关闭.开关 then
    服务器关闭.计时=服务器关闭.计时-1
    __S服务:输出("服务器关闭倒计时："..服务器关闭.计时)
    if 服务器关闭.计时<=60 and 服务器关闭.计时>0 then
      广播消息({内容="#Y/服务器将在#R/"..服务器关闭.计时.."#Y/秒后关闭,请所有玩家立即下线。",频道="xt"})
    elseif 服务器关闭.计时<=0 then
      玩家全部下线()
    end
  end

  for n, v in pairs(玩家数据) do
    if 玩家数据[n]~=nil and 玩家数据[n].角色~=nil and 玩家数据[n].管理 == nil then
      玩家数据[n].角色:增加在线时间()
      -- 发送数据(玩家数据[n].连接id,76541,os.time())  --每秒给客户端发送一个时间做为认证使用
    end
  end

 for n, v in pairs(玩家数据) do
    if 玩家数据[n]~=nil and 玩家数据[n].角色~=nil and 玩家数据[n].角色.数据.武神坛 == true then
       if 玩家数据[n].角色.数据.地图数据.编号 ~= 1994 then
        常规提示(n,"#Y你往哪跑呢,武神坛模式不可离开！")
        地图处理类:跳转地图(n,1994,440,183)
      end
    end
end

  for n, v in pairs(玩家数据) do
    if 玩家数据[n]~=nil and 玩家数据[n].角色~=nil and 玩家数据[n].角色.数据.自动开关~=nil and 玩家数据[n].角色.数据.自动开关.是否挂机==false and 玩家数据[n].角色.数据.自动开关.自动类型~="空"  and 玩家数据[n].角色.数据.自动开关.高级飞行棋>0 and 玩家数据[n].角色.数据.自动开关.执行==true then
       if 玩家数据[n].角色.数据.自动开关.执行时间>=玩家数据[n].角色.数据.自动开关.间隔时间 then
          玩家数据[n].角色.数据.自动开关.执行时间=0
          自动任务类:判断任务类型(n)
       else
        玩家数据[n].角色.数据.自动开关.执行时间=玩家数据[n].角色.数据.自动开关.执行时间+1
       end
    end
  end
    -----挂机
  for n, v in pairs(玩家数据) do
    if 玩家数据[n]~=nil and 玩家数据[n].角色~=nil and 玩家数据[n].角色.数据.自动开关~=nil  and 玩家数据[n].角色.数据.自动开关.是否挂机 and 玩家数据[n].角色.数据.自动开关.自动类型~="空" and 玩家数据[n].角色.数据.自动开关.高级飞行棋>0 and 玩家数据[n].角色.数据.自动开关.执行==true then
       if 玩家数据[n].角色.数据.自动开关.执行时间>=玩家数据[n].角色.数据.自动开关.间隔时间 then
          玩家数据[n].角色.数据.自动开关.执行时间=0
          自动挂机类:判断任务类型(n)
       else
        玩家数据[n].角色.数据.自动开关.执行时间=玩家数据[n].角色.数据.自动开关.执行时间+1
       end
    end
  end


  藏宝阁更新()
  if 时间=="59" and 服务端参数.小时=="23" and 服务端参数.分钟=="59" then
    师门数据={}
    押镖数据={}
    心魔宝珠={}
    十二生肖={}
    科举数据={}
    双倍数据={}
    三倍数据={}
    在线时间={}
    新手活动={}
    快捷抓鬼次数={}
    月卡数据={}
    一键师门={}
    一键抓鬼={}
    一键封妖={}
    一键官职={}
    抓鬼仙玉=0
    雪人限制={}
	  副本数据.一斛珠.完成={}
    副本数据.乌鸡国.完成={}
    副本数据.车迟斗法.完成={}
    副本数据.水陆大会.完成={}
    副本数据.通天河.完成={}
    副本数据.大闹天宫.完成={}
    副本数据.齐天大圣.完成={}
    生死劫数据.次数={}
    比武奖励={}
    剑会天下={}
    --剑会天下每日清空
    剑会天下单人匹配={}
    剑会天下三人匹配={}
    剑会天下五人匹配={}
    剑会天下次数统计={}
    --剑会天下每日清空
    活动次数={}  --12点清空次数
    通天塔数据={}
    新手活动={}
    副本奖励={}
    活跃数据={}
    for n,v in pairs(玩家数据) do
    副本奖励[n]={}
    活跃数据[n]={活跃度=0,领取100活跃=false,领取200活跃=false,领取300活跃=false,领取400活跃=false,领取500活跃=false}
    end
    for n,v in pairs(自动抓鬼数据) do
      if 自动抓鬼数据[n].天数 and not 自动抓鬼数据[n].永久 then
       自动抓鬼数据[n].天数=自动抓鬼数据[n].天数-1
       if 自动抓鬼数据[n].天数<0 or 自动抓鬼数据[n].天数==nil then
        自动抓鬼数据[n]=nil
       end
      end
    end
    发送公告("#G美好的一天从这一秒开始，游戏对应的活动任务数据已经刷新，大家可以前去领取任务或参加活动了")
    for n, v in pairs(任务数据) do
      if 任务数据[n].类型==7 then
        local id=任务数据[n].玩家id
        if 玩家数据[id]~=nil then
          玩家数据[id].角色:取消任务(n)
          常规提示(id,"由于科举数据已经刷新，您本次的活动资格已经被强制取消，请重新参加此活动！")
        end
        任务数据[n]=nil
      end
    end
    更新交易中心涨跌幅()
  end
  -- if 首席争霸开启~=nil and os.time()-首席争霸开启>=600 then
  --     开启首席争霸()
  --     首席争霸开启=nil
  -- end
  -- if 比武开启~=nil and os.time()-比武开启>=600 then
  --     游戏活动类:开启比武大会比赛()
  --     比武开启=nil
  -- end

  if 迷宫数据.开关 then
    if os.time()-迷宫数据.事件>=300 then
      迷宫数据.事件=os.time()
      任务处理类:刷新迷宫小怪()
    end
  end
  if 宝藏山数据.开关 then
      宝藏山数据.间隔=宝藏山数据.间隔-1
    if 宝藏山数据.间隔==60 then
      地图处理类:当前消息广播1(5001,"#Y各位玩家请注意，宝藏山将在#R1#Y分钟后刷出宝箱。")
    elseif 宝藏山数据.间隔==30 then
      地图处理类:当前消息广播1(5001,"#Y各位玩家请注意，宝藏山将在#R30#Y秒后刷出宝箱。")
    elseif 宝藏山数据.间隔<=0 then
      任务处理类:宝藏山刷出宝箱()
      宝藏山数据.间隔=180
    end
    if os.time()-宝藏山数据.起始>=999999 then
      宝藏山数据.开关=false
      广播消息({内容="#G/宝藏山活动已经结束，处于场景内的玩家将被自动传送出场景。",频道="xt"})
      地图处理类:清除地图玩家(5001,1226,115,15)
    end
  end
  for n, v in pairs(自动遇怪) do
    if 自动遇怪[n]~=0 then
      if os.time()-(自动遇怪[n]+1)>=5 then  --自动遇怪 固定秒数 的
        if 玩家数据[n].战斗==0 and 取队长权限(n) and 取场景等级(玩家数据[n].角色.数据.地图数据.编号)~=nil then
          自动遇怪[n]=0
          -- if 一键抓鬼[n]==true then
          --   if 活动次数查询月卡(n,"抓鬼任务")==false then
          --     return
          --   end
          --   战斗准备类:创建战斗(n,100239,0)
          --   常规提示(n,"#Y你正在自动挂机抓鬼中...")
          --   return
          -- end

          -- if 一键师门[n]==true then
          --   if 活动次数查询月卡(n,"自动师门")==false or 活动次数查询月卡(n,"师门任务")==false then
          --     return
          --   end
          --   战斗准备类:创建战斗(n,100240,0)
          --   常规提示(n,"#Y你正在自动挂机师门中...")
          --   return
          -- end
          if 取随机数(1,500)<=1 then
            战斗准备类:创建战斗(n,100225,0)
            常规提示(n,"#Y你遇到神兽啦!!!")
          else
          战斗准备类:创建战斗(n,100001,0)
          常规提示(n,"#Y你正在使用自动遇怪功能\n在野外场景下#R每隔5秒#W会自动触发暗雷战斗\n如需关闭此功能#G再次ALT+Z#Y自动遇怪即可关闭此功能")
          end
        else
          自动遇怪[n]=os.time()
        end
      end
    end
  end
end
function 整点处理(时刻)
  if 服务端参数.小时==时刻 then
    return 0
  else
    服务端参数.小时=时刻
    服务端参数.分钟="0"
    保存系统数据()
    for n, v in pairs(玩家数据) do
    if 玩家数据[n]~=nil then
    发送数据(v.连接id,3521.1)
    end
    end
    广播消息({内容=format("#G假人摆摊#物品已经#Y刷新\n快去找找有啥好东西吧#1"),频道="xt"})--重开
    摆摊假人处理类:Refresh()--重开
  end
  if 帮派数据 ~= nil then
    for i=1,#帮派数据 do
      if 帮派数据[i] ~= nil then
        if 帮派数据[i].帮派资金.当前 <= 帮派数据[i].帮派资金.上限*0.1 then
          广播帮派消息({内容="[整点维护]#R/本次维护由于帮派资金不足未获得国家相应补助,并且导致帮派繁荣度、安定度、人气度各下降1点",频道="bp"},帮派数据[i].帮派编号)
          帮派数据[i].繁荣度 = 帮派数据[i].繁荣度 -1
          帮派数据[i].安定度 = 帮派数据[i].安定度 -1
          帮派数据[i].人气度 = 帮派数据[i].人气度 -1
          if 帮派数据[i].繁荣度 <= 100 then
            帮派数据[i].繁荣度 = 100
          end
          if 帮派数据[i].安定度 <= 50 then
            帮派数据[i].安定度 = 50
          end
          if 帮派数据[i].人气度 <= 50 then
            帮派数据[i].人气度 = 50
          end
        else
          帮派处理类:维护处理(i)
        end
      end
    end
  end

  if 时刻=="0" then
    任务处理类:刷出征战神州(1)--跨服怪
  elseif 时刻=="9" then
  elseif 时刻=="11" then
  elseif 时刻=="12" then
    任务处理类:开启宝藏山()
    --刷怪处理:星期三十二辰星活动()
    任务处理类:开启皇宫飞贼()
    任务处理类:开启游戏比赛()
    任务处理类:开启门派闯关()
  elseif 时刻=="13" then
    刷怪处理:关闭宝藏山活动()

  elseif 时刻=="17" then

  elseif 时刻=="18" then

  elseif 时刻=="19" then

    刷怪处理:星期六活动()---星期6和7 比武大会
 elseif 时刻=="20" then

  刷怪处理:结束星期六活动()--剑会 星期6和7结束比武大会
  游戏活动类:开启剑会天下()
  文韵墨香开启=true
  发送公告("文韵墨香活动已开启,大家可以到长安城节日兔子旁参加！")

    --刷怪处理:开启首席争霸报名()
    刷怪处理:剑会活动()
    刷怪处理:剑会活动7()
    任务处理类:开启宝藏山()

  elseif 时刻=="21" then
    刷怪处理:结束门派闯关活动()
   游戏活动类:关闭剑会天下()--剑会

    --刷怪处理:结束首席争霸()
    刷怪处理:结束剑会活动()
    刷怪处理:结束剑会活动7()
    刷怪处理:关闭宝藏山活动()
  elseif 时刻=="22" then
    --开启比武大会进场()--重开
    任务处理类:结束皇宫飞贼()
    --刷怪处理:关闭星期三十二辰星活动()
    文韵墨香开启=false
    发送公告("文韵墨香活动已关闭")
  elseif 时刻=="23" then
  --刷怪处理:关闭宝藏山活动()--重开
   end
end

function 整分处理(时间)
  服务端参数.分钟=时间
  if 时间=="00" or 时间=="10" or 时间=="20" or 时间=="30" or 时间=="40" or 时间=="50" then
    商店处理类:刷新跑商商品买入价格()
    for i,v in pairs(跑商) do
      跑商[i] = 取商品卖出价格(i)
    end
    if 时间 == "10" or 时间 == "30" or 时间 =="50" then
      保存系统数据()
    elseif 时间 == "20" or 时间 == "40" or 时间 == "00" then
      collectgarbage("collect")
    end
  end

    if 服务端参数.小时 + 0 >= 12 and 服务端参数.小时 + 0 <= 17 and 三界书院.间隔 <= os.time() - 三界书院.起始 then
    三界书院.起始 = os.time()
    任务处理类:开启三界书院()
  end

---帮战
  if 服务端参数.小时+0 ==19 and 时间=="30" then
     广播消息({内容=format("帮战即将开始，报名帮战的帮派成员记得准时参加哟（20点开战）"),频道="xt"})
     发送公告("帮战即将开始，报名帮战的帮派成员记得准时参加哟（20点开战）")
  end
  if 服务端参数.小时+0 ==22 and 时间=="01" then
    if #帮派数据 > 0 then
      广播消息({内容=format("#G/帮战已经结束，快去帮派领取福利吧#80"),频道="xt"})
      发送公告("帮战已经结束，快去帮派领取福利吧")
      for i=1,#帮派数据 do
        帮派数据[i].帮战开关 = false
      end
      for n, v in pairs(战斗准备类.战斗盒子) do
        if 战斗准备类.战斗盒子[n].战斗类型==200006 then
          战斗准备类.战斗盒子[n]:结束战斗(0,0,1)
        end
      end
    end
  end



  if 时间=="01" then

    任务处理类:刷出星宿()
    任务处理类:开启地煞星任务()

  elseif 时间=="10"then
     任务处理类:刷出妖魔鬼怪()
    -- 任务处理类:刷出知了王()--重开
     任务处理类:开启地煞星任务()
     任务处理类:开启天罡星任务()
  elseif 时间=="15"then
     任务处理类:刷出新服福利BOSS()

  elseif 时间=="20" then
      任务处理类:刷新世界BOSS()
       任务处理类:刷新世界BOSS()--重开
       任务处理类:刷新世界BOSS()--重开
       任务处理类:福利宝箱()--重开
       任务处理类:开启地煞星任务()--重开
       任务处理类:开启天罡星任务()--重开
  elseif 时间=="28" then
    商店处理类:刷新珍品()

  elseif 时间=="30" then
    任务处理类:刷出散财童子()
    任务处理类:刷出妖魔鬼怪()



   elseif 时间=="35" then
      任务处理类:开启地煞星任务()--重开

  elseif 时间=="40" then
      任务处理类:刷新世界BOSS()--重开
      任务处理类:刷出新服福利BOSS()
  elseif 时间=="45"then

      任务处理类:刷出知了王()


  elseif 时间=="50" then
    任务处理类:刷出知了王()
    任务处理类:刷出星宿()
    任务处理类:刷出星宿()
    任务处理类:刷出星宿()
    任务处理类:刷出星宿()
    任务处理类:刷出星宿()
    任务处理类:刷出星宿()
    任务处理类:刷出散财童子()



end

end
名称数据={}
队伍数据={}
道具记录={}
交易数据={}
捉鬼数据={}
妖魔积分={}
游戏数据={}
师门数据={}
新手活动={}
活跃数据={}
押镖数据={}
心魔宝珠={}
十二生肖={}
科举数据={}
自动遇怪={}
帮派数据={}
帮派竞赛={}
神秘宝箱={}
炼丹炉={}
炼丹查看={}
商品存放={}
比武大会={}
自动抓鬼数据={}
首席争霸={}
充值数据={}
银子数据={}
签到数据={}
成就数据={}
交易中心={}
VIP数据={}
帮派缴纳情况 = {}
商店bb={}
变异商店bb={}
抓鬼仙玉=0
通天塔数据={}
房屋数据={}
师徒数据={}
新手活动={}
观察藏宝阁数据 = {}
活动次数={}   --自定义战斗名称
--==========================
皇宫飞贼={开关=false}
迷宫数据={开关=false}
镖王活动={开关=false}
降妖伏魔={开关=false}

国庆活动={保卫战={开关=false,地图=1110,积分=0,玩家={},起始=os.time(),次数=0}}
副本数据={乌鸡国={进行={},完成={}},车迟斗法={进行={},完成={}},水陆大会={进行={},完成={}},通天河={进行={},完成={}},大闹天宫={进行={},完成={}},齐天大圣={进行={},完成={}},一斛珠={进行={},完成={}}}
宝藏山数据={开关=false,起始=os.time(),刷新=0,间隔=600}
剧情数据={渡劫={进行={}}}
年兽数据={}
十二辰星={开关=false,起始=0,记录={}}
闯关参数={开关=false,起始=0,记录={}}
飞升开关=true
时辰信息={当前=1,刷新=60,起始=os.time()}
昼夜参数=1
聊天监控={}
比武排行={}
qz=math.floor
cbg费率=0
异步保存次数=0
-- 服务端参数.ip=连接ip--f函数.读配置(程序目录.."配置文件.ini","主要配置","ip")
--f函数.读配置(程序目录.."配置文件.ini","主要配置","端口")
服务端参数.时间=os.time()
服务端参数.连接限制=f函数.读配置(程序目录.."配置文件.ini","主要配置","连接数")+0
服务端参数.角色id=f函数.读配置(程序目录.."配置文件.ini","主要配置","id")+0
服务端参数.经验获得率=f函数.读配置(程序目录.."配置文件.ini","主要配置","经验")+0
服务端参数.难度=f函数.读配置(程序目录.."配置文件.ini","主要配置","难度")+0
服务端参数.服务器上限=f函数.读配置(程序目录.."配置文件.ini","主要配置","服务器上限")+0
武神坛使者=f函数.读配置(程序目录.."配置文件.ini","主要配置","武神坛使者")+0
充值比例=f函数.读配置(程序目录.."配置文件.ini","主要配置","充值比例")+0
兑换比例=f函数.读配置(程序目录.."配置文件.ini","主要配置","点卡比仙玉")+0
打造熟练度开关=f函数.读配置(程序目录.."配置文件.ini","主要配置","打造熟练度开关")+0
节日开关=false
首席争霸报名开关=false
首席争霸进场=false
首席争霸开关=false
宝箱开关=false
服务端参数.连接数=0
游泳开关=false
网关认证=false
比武大会报名开关=false
在线数据={}
玩家数据={}
双倍数据={}
三倍数据={}
在线时间={}
剑会记录={}
快捷抓鬼次数={}
月卡数据={}
一键师门={}
一键抓鬼={}
一键封妖={}
一键官职={}
雪人限制={}
藏宝阁记录=""
水果刷新=os.time()
剑会匹配=os.time()
年兽=os.time()
塔怪刷新=os.time()
天庭叛逆刷新=os.time()
建邺东海刷新=os.time()
可以抓捕=os.time()
王者荣耀=os.time()
保存数据=os.time()
异步保存数据=os.time()
副本更新=os.time()

__S服务:启动(服务端参数.ip,服务端参数.端口)
__S服务:置标题("梦幻武神坛服务端    当前版本号："..版本.."    当前在线人数："..__N连接数)
 随机序列=0
__S服务:输出("开始加载科举题库")
__S服务:输出("开始加载科举题库")
local 临时题库=读入文件("tk.txt")
local 题库=分割文本(临时题库,"#-#")
科举题库={}
for n=1,#题库 do
  科举题库[n]=分割文本(题库[n],"=-=")
end
__S服务:输出(format("加载题库结束，总共加载了%s道科举题目",#科举题库))




三界书院 = {答案 = "",开关 = false,结束 = 60,起始 = os.time(),间隔 = 取随机数(30, 90) ,名单 = {}}

__S服务:输出(format("加载题库结束，总共加载了%s道科举题目",#科举题库))
临时数据=table.loadstring(读入文件([[tysj/任务数据.txt]]))
帮派数据=table.loadstring(读入文件([[tysj/帮派数据.txt]]))
神秘宝箱=table.loadstring(读入文件([[tysj/神秘宝箱.txt]]))
比武大会=table.loadstring(读入文件([[tysj/比武大会.txt]]))
首席争霸=table.loadstring(读入文件([[tysj/首席争霸.txt]]))
帮派竞赛=table.loadstring(读入文件([[tysj/帮派竞赛.txt]]))
经验数据=table.loadstring(读入文件([[tysj/经验数据.txt]]))
押镖数据=table.loadstring(读入文件([[tysj/押镖数据.txt]]))
银子数据=table.loadstring(读入文件([[tysj/银子数据.txt]]))
充值数据=table.loadstring(读入文件([[tysj/充值数据.txt]]))
名称数据=table.loadstring(读入文件([[tysj/名称数据.txt]]))
妖魔积分=table.loadstring(读入文件([[tysj/妖魔数据.txt]]))
消息数据=table.loadstring(读入文件([[tysj/消息数据.txt]]))
生死劫数据=table.loadstring(读入文件([[tysj/生死劫数据.txt]]))
好友黑名单=table.loadstring(读入文件([[tysj/好友黑名单.txt]]))
活跃数据=table.loadstring(读入文件([[tysj/活跃数据.txt]]))
活动次数=table.loadstring(读入文件([[tysj/活动次数.txt]]))
副本奖励=table.loadstring(读入文件([[tysj/副本奖励.txt]]))
支线奖励=table.loadstring(读入文件([[tysj/支线奖励.txt]]))
首杀记录=table.loadstring(读入文件([[tysj/首杀记录.txt]]))
签到数据=table.loadstring(读入文件([[tysj/签到数据.txt]]))
通天塔数据=table.loadstring(读入文件([[tysj/通天塔数据.txt]]))
房屋数据=table.loadstring(读入文件([[tysj/房屋数据.txt]]))
藏宝阁数据=table.loadstring(读入文件([[tysj/藏宝阁数据.txt]]))
寄存数据=table.loadstring(读入文件([[tysj/寄存数据.txt]]))
师徒数据=table.loadstring(读入文件([[tysj/师徒数据.txt]]))
国庆数据=table.loadstring(读入文件([[tysj/国庆数据.txt]]))
比武奖励=table.loadstring(读入文件([[tysj/比武奖励.txt]]))
拍卖系统数据=table.loadstring(读入文件([[tysj/拍卖系统.txt]]))
成就数据=table.loadstring(读入文件([[tysj/成就数据.txt]]))
交易中心=table.loadstring(读入文件([[tysj/交易中心.txt]]))
雪人活动=table.loadstring(读入文件([[tysj/雪人活动.txt]]))
图鉴系统=table.loadstring(读入文件([[tysj/图鉴系统.txt]]))
自动抓鬼数据=table.loadstring(读入文件([[tysj/自动抓鬼数据.txt]]))
文韵墨香=table.loadstring(读入文件([[tysj/文韵墨香.txt]]))




if __gge.isdebug == nil then
    if 初始化充值() == "1" then
      内充开启 = true
      __S服务:输出("-------------------初始化内充成功------------------------------")
    else
      内充开启 = false
      __S服务:输出("-------------------初始化内充失败------------------------------")
    end
  end









if 雪人活动.雪人鼻子 == nil then
  雪人活动.雪人鼻子 = 0
  雪人活动.雪人帽子 = 0
  雪人活动.雪人眼睛 = 0
  雪人活动.上限 = 1000
end

if 首杀记录.商人的鬼魂 == nil then
  首杀记录.商人的鬼魂 = 0
  首杀记录.妖风 = 0
  首杀记录.白鹿精 = 0
  首杀记录.酒肉和尚 = 0
  首杀记录.守门天兵 = 0
end
if 首杀记录.幽冥鬼 == nil then
  首杀记录.幽冥鬼 = 0
end


--剑会天下初始化
剑会天下开关=false
剑会天下单人匹配开关 = true
剑会天下三人匹配开关 = true
剑会天下五人匹配开关 = true
剑会天下单人匹配={}
剑会天下三人匹配={}
剑会天下五人匹配={}
剑会天下次数统计={}
if f函数.文件是否存在([[tysj/剑会天下.txt]])==false then
  剑会天下={}
  写出文件([[tysj/剑会天下.txt]],table.tostring(剑会天下))
else
  剑会天下=table.loadstring(读入文件([[tysj/剑会天下.txt]]))
end

--比武大会初始化
if f函数.文件是否存在([[tysj/比武大会.txt]])==false then
  比武大会={报名={},积分={}}
  写出文件([[tysj/比武大会.txt]],table.tostring(比武大会))
else
  比武大会=table.loadstring(读入文件([[tysj/比武大会.txt]]))
end

if 定制八卦炉 then
  炼丹炉=table.loadstring(读入文件([[tysj/炼丹炉.txt]]))
  炼丹炉.时间 = 120
end

任务数据={}
if 经验数据.排行 == nil then
  经验数据.排行={}
  经验数据.百亿={}
  经验数据.千亿={}
end
for n, v in pairs(临时数据) do
  任务数据[临时数据[n].存储id]=table.loadstring(table.tostring(临时数据[n]))
end
地图处理类:加载房屋()

function __S服务:启动成功()
  return 0
end

function __S服务:GetIPLimit()
  return f函数.读配置(程序目录 .. "配置文件.ini", "主要配置", "多开限制")+0
end

function __S服务:连接进入(ID,IP,PORT)
  if f函数.读配置(程序目录 .. "ip封禁.ini", "ip", IP)=="1" or f函数.读配置(程序目录 .. "ip封禁.ini", "ip", IP)==1 then
    __S服务:输出(string.format("封禁ip的客户进入试图进入(%s):%s:%s", ID, IP, PORT))
    发送数据(ID,997,"")
    return 0
  end
  if __N连接数 < 10000 and IP~=nil then
    if IP=="127.0.0.1" and 网关认证==false then
      __S服务:输出(string.format('网关进入(%s):%s:%s',ID, IP,PORT))
    else
      __S服务:输出(string.format('GM工具进入(%s):%s:%s',ID, IP,PORT))
    end
    __N连接数 = __N连接数+1
    if 神兽开服时间 ~= nil then
      __S服务:置标题("武神坛·服务端    当前版本号："..版本.."    当前在线人数："..__N连接数.."     ["..os.date("%Y", 神兽开服时间).."年"..os.date("%m", 神兽开服时间).."月"..os.date("%d", 神兽开服时间).."日 "..os.date("%X", 神兽开服时间).."]")
    else
      __S服务:置标题("武神坛·服务端    当前版本号："..版本.."    当前在线人数："..__N连接数)
    end
    __C客户信息[ID] = {
      IP = IP,
      认证=os.time(),
      PORT = PORT
    }
    if IP=="127.0.0.1" and 网关认证==false then
      网关认证=true
      __C客户信息[ID].网关=true
      服务端参数.网关id=ID
    end
  else
    发送数据(ID,998,"你已经登录了游戏,请勿多开")
    __S服务:断开连接(ID)
    --  信息框("玩家限制人数为10人,请勿开启外网进行盈利,本游戏为单机游戏","验证失败")
    -- 发送数据(ID,997,"玩家限制人数为10人,请勿开启外网进行盈利,本游戏为单机游戏")
  end
end



function __S服务:连接退出(ID)
  if __C客户信息[ID] then
    __N连接数 = __N连接数 - 1
    if __C客户信息[ID].网关 then
      网关认证=false
      __S服务:输出(string.format('网关客户退出(%s):%s:%s', ID,__C客户信息[ID].IP,__C客户信息[ID].PORT))
    end
  else
    __S服务:输出("连接不存在(连接退出)。")
  end
  collectgarbage("collect")
end

function jm(数据)
  数据=encodeBase641(数据)
  local jg=""
  for n=1,#数据 do
    local z=string.sub(数据,n,n)
    if z~="" then
      if key[z]==nil then
        jg=jg..z
      else
        jg=jg..key[z]
      end
    end
  end
  return jg
end

function jm1(数据)
  local jg=数据
  for n=1,#mab do
    local z=string.sub(mab,n,n)
    if key[z]~=nil then
       jg=string.gsub(jg,key[z],z)
    end
  end
  return 网络处理类:decodeBase641(jg)
end


function __S服务:数据到达(ID,...)
  if ID == nil then
    print("接收空链接数据，异常抛出")
    return
  end
  if localmp~=nil then
    if __C客户信息[ID]  then
      if __C客户信息[ID].网关 then
        local arg = localmp.unpack(...)
        --table.print(arg)

        网络处理类:数据处理(arg[1],arg[2])

      else
        arg = localmp.unpack(...)
        --print(jm1(arg[1]))
        --local arg = {}
        --arg[2] = ...
        --arg[3]=ID
        --嘎嘎工具走的这里
        --print(arg[2])
        网络处理类:数据处理(arg[1],arg[2])
        --管理工具类2:数据处理(ID,arg[1])
      end
    else
      arg = localmp.unpack(...)
      gm数据=table.loadstring(arg[2])
      if gm数据.序号==1.22 then
        __C客户信息[ID] = {IP = IP,认证=os.time(),PORT = PORT}
        网络处理类:数据处理(arg[1],arg[2])
      else
      __S服务:输出("连接不存在(数据到达1)。")
      end
    end
  else
    local arg = {...}
    if __C客户信息[ID]  then
      if __C客户信息[ID].网关 then
        网络处理类:数据处理(...)
      else
        arg[3]=ID
        管理工具类2:数据处理(arg)
      end
    else
      __S服务:输出("连接不存在(数据到达)。")
    end
  end
end

function __S服务:错误事件(ID,EO,IE)
  if __C客户信息[ID] then
    __S服务:输出(string.format('错误事件(%s):%s,%s:%s', ID,__错误[EO] or EO,__C客户信息[ID].IP,__C客户信息[ID].PORT))
  else
    __S服务:输出("连接不存在(错误事件)。")
  end
end

function 输入函数(t,数字id)
  if t=="@gxdm" then
    代码函数=loadstring(读入文件([[代码.txt]]))
    代码函数()
    __S服务:输出("更新代码成功")
   elseif t=="@sxbt" then
    for n, v in pairs(玩家数据) do
      if 玩家数据[n]~=nil then
        发送数据(v.连接id,3521.1)
      end
    end
     广播消息({内容=format("#G假人摆摊#物品已经#Y刷新\n快去找找有啥好东西吧#1"),频道="xt"})
   摆摊假人处理类:Refresh()

  elseif t=="@嘎嘎" then
 floor = math.floor
 ceil = math.ceil
 insert = table.insert
 remove = table.remove
 jnzb = require("script/角色处理类/技能类")
 属性类型={"体质","魔力","力量","耐力","敏捷"}
 可入门派={
  仙={天宫=1,龙宫=1,女={普陀山=1,},男={五庄观=1},凌波城=1,花果山=1}
  ,魔={魔王寨=1,阴曹地府=1,女={盘丝洞=1,},男={狮驼岭=1},无底洞=1,女魃墓=1}
  ,人={大唐官府=1,方寸山=1,女={女儿村=1,},男={化生寺=1},神木林=1,天机城=1}
}


    战斗准备代码=loadstring(读入文件([[自定义源码/自定义战斗准备类.txt]]))
    战斗准备代码()
    __S服务:输出("-------------更新战斗准备代码成功-------------")

    任务代码=loadstring(读入文件([[自定义源码/自定义任务处理类.txt]]))
    任务代码()
    __S服务:输出("-------------更新任务处理代码成功-------------")

    战斗处理代码=loadstring(读入文件([[自定义源码/自定义战斗处理类.txt]]))
    战斗处理代码()
    __S服务:输出("-------------更新战斗处理代码成功-------------")

    打造处理代码=loadstring(读入文件([[自定义源码/自定义打造处理类.txt]]))
    打造处理代码()
    __S服务:输出("-------------更新打造处理代码成功-------------")

    角色处理代码=loadstring(读入文件([[自定义源码/自定义角色处理类.txt]]))
    角色处理代码()
    __S服务:输出("-------------更新角色处理代码成功-------------")

    道具处理代码=loadstring(读入文件([[自定义源码/自定义道具处理类.txt]]))
    道具处理代码()
    __S服务:输出("-------------更新道具处理代码成功-------------")












  elseif t=="@wst" then
    if 武神坛活动 then
       武神坛活动=false
       --发送公告("#Y/武神坛活动已经关闭了")
    else
      武神坛活动=true
      发送公告("#Y/武神坛活动已经开启了，请前往长安城皇宫门口武神坛使者进入。")
    end
      elseif t=="@gbwst" then
    if 武神坛活动 then
      武神坛活动=false
      发送公告("#Y/武神坛活动已经关闭。")
    end
  elseif t=="@ceshi" then

    任务处理类:刷出征战神州(1)

  elseif t=="@bcrz" then

    local 保存语句=""
    for n=1,#错误日志 do
      保存语句=保存语句..时间转换(错误日志[n].时间)..'：#换行符'..错误日志[n].记录..'#换行符'..'#换行符'
    end
    
    写出文件("错误日志.txt",保存语句)
    错误日志={}
    __S服务:输出("保存错误日志成功")
  elseif t=="lmft" then
    老猫附体=not 老猫附体
    local word="开启"
    if not 老猫附体 then
      word="关闭"
    end
    __S服务:输出("序号侦查当前状态为："..word)
  elseif t=="zxlb" then
    查看在线列表()
  elseif t=="@qzxx" then
    for n,v in pairs(玩家数据) do
      发送数据(玩家数据[n].连接id,998,"您的账号已被强制下线，请重新登陆！")
    end
  elseif t=="@cshjyzx" then
    交易中心={}
    初始化交易中心()
  elseif t=="@gxjyzx" then
    更新交易中心涨跌幅()
  elseif t=="@bcsj" then
    保存所有玩家数据()
    保存系统数据()
  elseif t=="@ckfb" then
    local 总数 = 0
    for i,v in pairs(任务数据) do
      if 任务数据[i].类型 == 131 then
        总数 = 总数 +1
        -- print("以下为泡泡数据")
        -- print(任务数据[i].单位编号)
        -- print(任务数据[i].地图编号)
        -- print(任务数据[i].副本id)
        -- table.print(任务数据[i].队伍组)
      end
    end
    总数=0
    for n, v in pairs(地图处理类.地图单位[6021]) do
      总数 = 总数 +1
    end
  elseif t=="@sxwzry" then
    任务处理类:刷出王者荣耀()
  elseif t=="@sxmhfs" then
    任务处理类:刷新吊游定制()
  elseif t == "@bbw" then
    任务处理类:设置幼儿园()
  elseif t == "@gxsc" then
    商城处理类:加载商品()
  elseif t == "@csrw" then
    table.print(地图处理类.地图单位[6024])
  elseif t == "kqyy" then
    任务处理类:开启游戏比赛()
  elseif t == "xxxx" then
    玩家全部下线()
  elseif t == "@kqgm" then
      GM工具=false
  elseif t == "@gbgm" then
      GM工具=true
  elseif t == "开启爆率" then
      微变爆率=true
  发送公告("#S各位玩家请注意，六倍爆率已开启,玩家的天堂正式起航,所有爆率提高,物品奖励翻倍！。")
  elseif t == "关闭爆率" then
      微变爆率=false
  发送公告("#S各位玩家请注意，六倍爆率已关闭,地狱模式来临了！。")
 elseif t == "@hysx" then
      活跃数据={}
  elseif t == "@scpj" then
    刷怪处理:星期二活动()


  elseif t == "@sxzd" then
    师门数据={}
    押镖数据={}
    心魔宝珠={}
    十二生肖={}
    科举数据={}
    双倍数据={}
    三倍数据={}
    在线时间={}
    新手活动={}
    快捷抓鬼次数={}
    月卡数据={}
    一键师门={}
    一键抓鬼={}
    一键封妖={}
    一键官职={}
    抓鬼仙玉=0
    雪人限制={}
	  副本数据.一斛珠.完成={}
    副本数据.乌鸡国.完成={}
    副本数据.车迟斗法.完成={}
    副本数据.水陆大会.完成={}
    副本数据.通天河.完成={}
    副本数据.大闹天宫.完成={}
    副本数据.齐天大圣.完成={}
    生死劫数据.次数={}
    比武奖励={}
    剑会天下={}
    --剑会天下每日清空
    剑会天下单人匹配={}
    剑会天下三人匹配={}
    剑会天下五人匹配={}
    剑会天下次数统计={}
    --剑会天下每日清空
    活动次数={}  --12点清空次数
    通天塔数据={}
    新手活动={}
    副本奖励={}
    for n,v in pairs(玩家数据) do
    副本奖励[n]={}
    end
    活跃数据={}
    for n,v in pairs(玩家数据) do
    活跃数据[n]={活跃度=0,领取100活跃=false,领取200活跃=false,领取300活跃=false,领取400活跃=false,领取500活跃=false}
    end
    发送公告("#G美好的一天从这一秒开始，游戏对应的活动任务数据已经刷新，大家可以前去领取任务或参加活动了")
 elseif t == "@sjtk" then
    三界书院.起始 = os.time()
    任务处理类:开启三界书院()
 elseif t == "@bcjl" then
    补偿奖励=true
    发送公告("#R各位玩家请注意，因为本次更新修改了大量数据，因此开启节日活动进行补偿大家！谢谢大家的支持与理解！。")
    广播消息({内容=format("各位玩家请注意，因为本次更新修改了大量数据，因此开启节日活动进行补偿大家！谢谢大家的支持与理解！。"),频道="xt"})
 elseif t == "@gbbcjl" then
    补偿奖励=false
    发送公告("#R各位玩家请注意，补偿奖励已关闭！。")
    广播消息({内容=format("各位玩家请注意，补偿奖励已关闭！！"),频道="xt"})
	elseif t=="@bwbm" then
    比武大会报名开关=true
	  比武大会.报名={}
    发送公告("#Y/英雄比武大会活动已经进入报名阶段，请打算参加活动的玩家在19点前前往长安城比武大会主持人处进行报名。")
    广播消息({内容=format("英雄比武大会活动已经进入报名阶段，请打算参加活动的玩家在19点前前往长安城比武大会主持人处进行报名。"),频道="xt"})
  elseif t=="@bwrc" then
    发送公告("#Y/英雄比武大会活动已经开放入场，请参加比武大会的玩家前往长安城比武大会主持人处进行入场。")
    游戏活动类:开启比武大会入场()
  elseif t=="@kqbw" then
    比武大会报名开关=false
    游戏活动类:开启比武大会比赛()
  elseif t=="@jsbw" then
    游戏活动类:结束比武大会比赛()
  elseif t=="@bwqc" then
    比武大会报名开关=false
    比武大会.入场=false
    比武大会.比赛=false
    比武大会.精锐组={青龙={},白虎={}}
    比武大会.神威组={青龙={},白虎={}}
    比武大会.天科组={青龙={},白虎={}}
    比武大会.天元组={青龙={},白虎={}}
    比武大会.玩家表={}
    比武大会.本次积分={}
    游戏活动类:强制清除玩家(6003,true)
    游戏活动类:强制清除玩家(6004,true)
    游戏活动类:强制清除玩家(6005,true)
    游戏活动类:强制清除玩家(6006,true)
 elseif t == "@bpwh" then
        if 帮派数据 ~= nil then
    for i=1,#帮派数据 do
      if 帮派数据[i] ~= nil then
        if 帮派数据[i].帮派资金.当前 <= 帮派数据[i].帮派资金.上限*0.2 then
          广播帮派消息({内容="[整点维护]#R/本次维护由于帮派资金不足未获得国家相应补助,并且导致帮派繁荣度、安定度、人气度各下降50点",频道="bp"},帮派数据[i].帮派编号)
          帮派数据[i].繁荣度 = 帮派数据[i].繁荣度 -50
          帮派数据[i].安定度 = 帮派数据[i].安定度 -50
          帮派数据[i].人气度 = 帮派数据[i].人气度 -50
          if 帮派数据[i].繁荣度 <= 100 then
            帮派数据[i].繁荣度 = 100
          end
          if 帮派数据[i].安定度 <= 50 then
            帮派数据[i].安定度 = 50
          end
          if 帮派数据[i].人气度 <= 50 then
            帮派数据[i].人气度 = 50
          end
        else
          帮派处理类:维护处理(i)
        end
      end
    end
  end
elseif t == "下线更新" then
    服务器关闭={开关=true,计时=300,起始=os.time()}
    发送公告("#R各位玩家请注意，服务器将在5分钟后进行更新,届时服务器将临时关闭，请所有玩家注意提前下线。")
    广播消息({内容=format("#R各位玩家请注意，服务器将在5分钟后进行更新,届时服务器将临时关闭,，请所有玩家提前下线。"),频道="xt"})
    保存所有玩家数据()
    保存系统数据()

end
end
function 取帮派建筑数量(等级)
  if 等级 == 1 then
    return 2
  elseif 等级 == 2 then
    return 4
  elseif 等级 == 3 then
    return 8
  elseif 等级 == 4 then
    return 12
  elseif 等级 == 5 then
    return 16
  end
end

function xsjc(id,进程)--刷新任务
 if 玩家数据[id]==nil then return  end
 local 任务id=玩家数据[id].角色:取任务(999)
 if 任务数据[任务id]~=nil then
   任务数据[任务id].进程=进程
   常规提示(id,"#Y您的剧情任务已经更新，请注意及时查看！")
   玩家数据[id].角色:刷新任务跟踪()
   end
 end
function xsjc1(id,进程)
 if 玩家数据[id]==nil then return  end
 local 任务id=玩家数据[id].角色:取任务(998)
 if 任务数据[任务id]~=nil then
   任务数据[任务id].进程=进程
   常规提示(id,"#Y您的剧情任务已经更新，请注意及时查看！")
   玩家数据[id].角色:刷新任务跟踪()
   end
 end
 function xsjc2(id,进程)
 if 玩家数据[id]==nil then return  end
 local 任务id=玩家数据[id].角色:取任务(997)
 if 任务数据[任务id]~=nil then
   任务数据[任务id].进程=进程
   常规提示(id,"#Y您的剧情任务已经更新，请注意及时查看！")
   玩家数据[id].角色:刷新任务跟踪()
   end
 end
  function xsjc3(id,进程)
 if 玩家数据[id]==nil then return  end
 local 任务id=玩家数据[id].角色:取任务(996)
 if 任务数据[任务id]~=nil then
   任务数据[任务id].进程=进程
   常规提示(id,"#Y您的剧情任务已经更新，请注意及时查看！")
   玩家数据[id].角色:刷新任务跟踪()
   end
 end
 function xsjc11(id,进程)
 if 玩家数据[id]==nil then return  end
 local 任务id=玩家数据[id].角色:取任务(898)
 if 任务数据[任务id]~=nil then
   任务数据[任务id].进程=进程
   常规提示(id,"#Y您的剧情任务已经更新，请注意及时查看！")
   玩家数据[id].角色:刷新任务跟踪()
   end
 end

function 银子检查(id,数额)
 if 玩家数据[id].角色.数据.银子 >= 数额 then
    玩家数据[id].角色.数据.银子 = 玩家数据[id].角色.数据.银子-数额
    return true
 end
 return false
end

function 退出函数()
  保存所有玩家数据()
  保存系统数据()
  -- for n,v in pairs(玩家数据) do
  --   发送数据(玩家数据[n].连接id,998,"游戏更新,您已被强制下线,请关注群内通告！")
  --   __S服务:连接退出(玩家数据[n].连接id)
  -- end
end

任务处理类:加载首席单位()
if VIP定制 ~= nil and VIP定制 then
  帮派缴纳情况=table.loadstring(读入文件([[tysj/帮派缴纳情况.txt]]))
  月卡数据=table.loadstring(读入文件([[tysj/月卡数据.txt]]))
  一键师门=table.loadstring(读入文件([[tysj/一键师门.txt]]))
  一键抓鬼=table.loadstring(读入文件([[tysj/一键抓鬼.txt]]))
  一键封妖=table.loadstring(读入文件([[tysj/一键封妖.txt]]))
  一键官职=table.loadstring(读入文件([[tysj/一键官职.txt]]))
  成就数据=table.loadstring(读入文件([[tysj/成就数据.txt]]))
  比武奖励=table.loadstring(读入文件([[tysj/比武奖励.txt]]))
  交易中心=table.loadstring(读入文件([[tysj/交易中心.txt]]))
  VIP数据=table.loadstring(读入文件([[tysj/VIP数据.txt]]))
  --代码函数=loadstring(读入文件([[VIP召唤兽.txt]]))
  --代码函数()
end

-- if 服务器名称 == "梦幻吊游" then
--    if 初始化充值() == "1" then
--       内充开启 = true
--     __S服务:输出("初始化内充成功")
--    else
--      内充开启 = false
--      __S服务:输出("初始化内充失败")
--    end
-- end


function 玩家全部下线()
  保存所有玩家数据()
  保存系统数据()
  for n, v in pairs(玩家数据) do
    if 玩家数据[n]~=nil then
      发送数据(玩家数据[n].连接id,998,"您的账号已被强制下线，更新完毕时间咨询群管理~！")
    end
  end
  --os.exit()
 end

潜能果经验={[1]=10000000,[2]=10150000,[3]=10300000,[4]=10450000,[5]=10600000,[6]=10750000,[7]=10900000,[8]=11050000,[9]=11200000,[10]=11350000,[11]=11500000,[12]=11650000,[13]=11800000,
[14]=11950000,[15]=12100000,[16]=12250000,[17]=12400000,[18]=12550000,[19]=12700000,[20]=12850000,[21]=13000000,[22]=13150000,[23]=13300000,[24]=13450000,[25]=13600000,[26]=13750000,
[27]=13900000,[28]=14050000,[29]=14200000,[30]=14350000,[31]=14500000,[32]=14650000,[33]=14800000,[34]=14950000,[35]=15100000,[36]=15250000,[37]=15400000,[38]=15550000,[39]=15700000,
[40]=15850000,[41]=16000000,[42]=16150000,[43]=16300000,[44]=16450000,[45]=16600000,[46]=16750000,[47]=16900000,[48]=17050000,[49]=17200000,[50]=17350000,[51]=17500000,[52]=17650000,
[53]=17800000,[54]=17950000,[55]=18100000,[56]=18250000,[57]=18400000,[58]=18550000,[59]=18700000,[60]=18850000,[61]=19000000,[62]=19150000,[63]=19300000,[64]=19450000,[65]=19600000,
[66]=19750000,[67]=19900000,[68]=20050000,[69]=20200000,[70]=20350000,[71]=20500000,[72]=20650000,[73]=20800000,[74]=20950000,[75]=21100000,[76]=21250000,[77]=21400000,[78]=21550000,
[79]=21700000,[80]=21850000,[81]=22000000,[82]=22150000,[83]=22300000,[84]=22450000,[85]=22600000,[86]=22750000,[87]=22900000,[88]=23050000,[89]=23200000,[90]=23350000,[91]=23500000,
[92]=23650000,[93]=23800000,[94]=23950000,[95]=24100000,[96]=24250000,[97]=24400000,[98]=24550000,[99]=24700000,[100]=24850000,[101]=25000000,[102]=25150000,[103]=25300000,[104]=25450000,
[105]=25600000,[106]=25750000,[107]=25900000,[108]=26050000,[109]=26200000,[110]=26350000,[111]=26500000,[112]=26650000,[113]=26800000,[114]=26950000,[115]=27100000,[116]=27250000,
[117]=27400000,[118]=27550000,[119]=27700000,[120]=27850000,[121]=28000000,[122]=28150000,[123]=28300000,[124]=28450000,[125]=28600000,[126]=28750000,[127]=28900000,[128]=29050000,
[129]=29200000,[130]=29350000,[131]=29500000,[132]=29650000,[133]=29800000,[134]=29950000,[135]=30100000,[136]=30250000,[137]=30400000,[138]=30550000,[139]=30700000,[140]=30850000,
[141]=31000000,[142]=31150000,[143]=31300000,[144]=31450000,[145]=31600000,[146]=31750000,[147]=31900000,[148]=32050000,[149]=32200000,[150]=32350000,[151]=32500000,[152]=32650000,
[153]=32800000,[154]=32950000,[155]=33100000,[156]=33250000,[157]=33400000,[158]=33550000,[159]=33700000,[160]=33850000,[161]=34000000,[162]=34150000,[163]=34300000,[164]=34450000,
[165]=34600000,[166]=34750000,[167]=34900000,[168]=35050000,[169]=35200000,[170]=35350000,[171]=35500000,[172]=35650000,[173]=35800000,[174]=35950000,[175]=36100000,[176]=36250000,
[177]=36400000,[178]=36550000,[179]=36700000,[180]=36850000,[181]=37000000,[182]=37150000,[183]=37300000,[184]=37450000,[185]=37600000,[186]=37750000,[187]=37900000,[188]=38050000,
[189]=38200000,[190]=38350000,[191]=38500000,[192]=38650000,[193]=38800000,[194]=38950000,[195]=39100000,[196]=39250000,[197]=39400000,[198]=39550000,[199]=39700000,
[200]=39850000,[201]=0}
道具排序表={}
function 读取背包排序表()
道具排序表["红色合成旗"] = 10 道具排序表["黄色合成旗"] = 11 道具排序表["蓝色合成旗"] = 12 道具排序表["绿色合成旗"] = 13 道具排序表["白色合成旗"] = 14 道具排序表["红色导标旗"] = 15
道具排序表["绿色导标旗"] = 16 道具排序表["蓝色导标旗"] = 17 道具排序表["白色导标旗"] = 18 道具排序表["黄色导标旗"] = 19 道具排序表["飞行符"] = 20   道具排序表["秘制红罗羹"] = 21 道具排序表["秘制绿罗羹"] = 22 道具排序表["摄妖香"] = 25 道具排序表["洞冥草"] = 26
道具排序表["2倍经验丹"] = 30 道具排序表["3倍经验丹"] = 31 道具排序表["变身卡"] = 35 道具排序表["空白强化符"] = 33 道具排序表["点化石"] = 150 道具排序表["宠物饰品通用丹"] = 37 道具排序表["附魔宝珠"] = 138 道具排序表["青龙石"] = 39
道具排序表["白虎石"] = 40 道具排序表["朱雀石"] = 41 道具排序表["玄武石"] = 42
道具排序表["百炼精铁"] = 100 道具排序表["制造指南书"] = 101 道具排序表["灵饰指南书"] = 102 道具排序表["元灵晶石"] = 103 道具排序表["炼妖石"] = 104 道具排序表["上古锻造图策"] = 105
道具排序表["魔兽要诀"] = 106 道具排序表["高级魔兽要诀"] = 107 道具排序表["召唤兽内丹"] = 108 道具排序表["高级召唤兽内丹"] = 109 道具排序表["藏宝图"] = 110 道具排序表["高级藏宝图"] = 111
道具排序表["金银锦盒"] = 112 道具排序表["特赦令牌"] = 113 道具排序表["金柳露"] = 114 道具排序表["超级金柳露"] = 115 道具排序表["元宵"] = 116 道具排序表["炼兽真经"] = 117
道具排序表["天眼通符"] = 34    道具排序表["海马"] = 134 道具排序表["吸附石"] = 135
道具排序表["圣兽丹"] = 136 道具排序表["月华露"] = 137 道具排序表["易经丹"] = 138 道具排序表["玉葫灵髓"] = 139 道具排序表["清灵净瓶"] = 140 道具排序表["神兵图鉴"] = 97
道具排序表["强化符"] = 143 道具排序表["分解符"] = 144 道具排序表["灵箓"] = 145 道具排序表["碎星锤"] = 146 道具排序表["超级碎星锤"] = 147
道具排序表["天眼珠"] = 154 道具排序表["珍珠"] = 155 道具排序表["初级清灵仙露"] = 156 道具排序表["中级清灵仙露"] = 157 道具排序表["高级清灵仙露"] = 158  道具排序表["星辉石"] = 163 道具排序表["光芒石"] = 164 道具排序表["月亮石"] = 165
道具排序表["太阳石"] = 166 道具排序表["舍利子"] = 167 道具排序表["红玛瑙"] = 168 道具排序表["黑宝石"] = 169 道具排序表["神秘石"] = 170 道具排序表["未激活的符石1级"] = 171
道具排序表["未激活的符石2级"] = 172 道具排序表["未激活的符石3级"] = 173 道具排序表["未激活的星石"] = 174 道具排序表["符石卷轴"] = 175 道具排序表["神兜兜"] = 176 道具排序表["彩果"] = 177
道具排序表["坐骑内丹"] = 180 道具排序表["钟灵石"] = 182
道具排序表["钨金"] = 185 道具排序表["顺逆神针"] = 186  道具排序表["三界悬赏令"] = 189 道具排序表["怪物卡片"] = 190
end
初始化交易中心()
读取背包排序表()
保存所有玩家数据()
保存系统数据()
任务处理类:开启宝藏山()
任务处理类:开启游戏比赛()
任务处理类:开启门派闯关()
任务处理类:开启皇宫飞贼()
任务处理类:开启镖王活动()
任务处理类:开启迷宫()
任务处理类:刷出星宿()--重开
任务处理类:刷出星宿()--重开
任务处理类:刷出星宿()--重开
任务处理类:刷出星宿()--重开
任务处理类:刷出星宿()--重开
任务处理类:刷出星宿()--重开
任务处理类:刷出妖魔鬼怪()--重开
任务处理类:刷出知了王()
任务处理类:开启地煞星任务()
任务处理类:捣乱的水果(id)
任务处理类:设置天庭叛逆(id)
任务处理类:设置建邺东海小活动(id)
任务处理类:设置大雁塔怪(id)
任务处理类:刷新世界BOSS()--重开
任务处理类:刷新世界BOSS()--重开
任务处理类:刷新世界BOSS()--重开
任务处理类:刷出新服福利BOSS()--重开
任务处理类:刷出散财童子()--重开
任务处理类:福利宝箱()--重开
 任务处理类:开启天罡星任务()
 任务处理类:刷出征战神州(1)
