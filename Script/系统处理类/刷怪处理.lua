-- @Author: baidwwy
-- @Date:   2023-03-10 11:49:53
-- @Last Modified by:   baidwwy
-- @Last Modified time: 2023-05-11 18:18:22
local 刷怪处理 = class()
local 星期=  os.date("%w")

function 刷怪处理:初始化(id)
  -- self.数据={}
end

function 刷怪处理:星期一活动()
 local 星期=  os.date("%w")
    if 星期=="1"  then
     任务处理类:开启宝藏山()
  end
end

function 刷怪处理:关闭宝藏山活动()
 local 星期=  os.date("%w")
    if 星期=="1"  then
    宝藏山数据.开关=false
    广播消息({内容="#G/宝藏山活动已经结束，处于场景内的玩家将被自动传送出场景。",频道="xt"})
    地图处理类:清除地图玩家(5001,1226,115,15)
  end
end

function 刷怪处理:星期二活动()
 local 星期=  os.date("%w")
    if 星期=="2"  then
     任务处理类:刷出叛军()
     广播消息({内容="#G/星期二活动已开启,几个天庭下来的叛军带着100-140的制造指南书来人间闹事,大家快去消灭他吧",频道="xt"})
     发送公告("#G星期二活动已开启,几个天庭下来的叛军带着100-140的制造指南书来人间闹事,大家快去消灭他吧")
  end
end

function 刷怪处理:星期三十二辰星活动()

 local 星期=  os.date("%w")
    --if 星期=="3"  then
     任务处理类:开启十二生肖任务()
 -- end
end

function 刷怪处理:关闭星期三十二辰星活动()

   local 星期=  os.date("%w")
    --if 星期=="3"  then
    十二辰星={开关=false,起始=0,记录={}}
    广播消息({内容="#G/十二辰星活动已经结束，已处战斗中的玩家在战斗结束后依然可以获得奖励。",频道="xt"})
    --end
    for n, v in pairs(战斗准备类.战斗盒子) do
      if 战斗准备类.战斗盒子[n].战斗类型==110040 then
        战斗准备类.战斗盒子[n]:结束战斗(0,0,1)
      end
    end
    for n, v in pairs(玩家数据) do
      if 玩家数据[n].管理==nil and 玩家数据[n].角色:取任务(413)~=0 then
        玩家数据[n].角色:取消任务(玩家数据[n].角色:取任务(413))
        常规提示(n,"你的十二辰星任务已经被自动取消")
      end
    end
    for n, v in pairs(任务数据) do
      if 任务数据[n]~=nil and 任务数据[n].类型 == 413 then
        任务数据[n]=nil
      end
    end
end

function 刷怪处理:剑会活动()
 local 星期=  os.date("%w")
    if 星期=="6"  then
      游戏活动类:开启剑会天下()
  end
end
function 刷怪处理:结束剑会活动()
 local 星期=  os.date("%w")
    if 星期=="6"  then
      游戏活动类:关闭剑会天下()
  end
end


function 刷怪处理:剑会活动7()
 local 星期=  os.date("%w")
    if 星期=="0"  then
      游戏活动类:开启剑会天下()
  end
end
function 刷怪处理:结束剑会活动7()
 local 星期=  os.date("%w")
    if 星期=="0"  then
      游戏活动类:关闭剑会天下()
  end
end

function 刷怪处理:星期三活动()
 local 星期=  os.date("%w")
    if 星期=="3"  then
      游戏活动类:开启剑会天下()
  end
end
function 刷怪处理:结束星期三活动()
 local 星期=  os.date("%w")
    if 星期=="3"  then
      游戏活动类:关闭剑会天下()
  end
end

function 刷怪处理:星期五活动()
 local 星期=  os.date("%w")
    if 星期=="5"  then
      任务处理类:开启宝藏山()
  end
end

function 刷怪处理:星期六活动()
  local 星期=  os.date("%w")
  if 星期=="6"  or 星期=="7" or  星期=="0" then
    发送公告("#Y/英雄比武大会活动已经开放入场，请参加比武大会的玩家前往长安城比武大会主持人处进行入场。")
    游戏活动类:开启比武大会入场()
 end
end

function 刷怪处理:结束星期六活动()
  local 星期=  os.date("%w")
  if 星期=="6"  or 星期=="7" or  星期=="0"  then
     游戏活动类:结束比武大会比赛()
 end
end

function 刷怪处理:星期日活动()
 local 星期=  os.date("%w")
    if 星期=="7" or  星期=="0" then
       任务处理类:开启门派闯关()
  end
end

function 刷怪处理:结束门派闯关活动()

	 local 星期=  os.date("%w")
    --if 星期=="7" or  星期=="0" then
    闯关参数={开关=false,起始=0,记录={}}
    广播消息({内容="#G/十五门派闯关活动已经结束，已处战斗中的玩家在战斗结束后依然可以获得奖励。",频道="xt"})
    --end
    for n, v in pairs(战斗准备类.战斗盒子) do
      if 战斗准备类.战斗盒子[n].战斗类型==100011 then
        战斗准备类.战斗盒子[n]:结束战斗(0,0,1)
      end
    end
    for n, v in pairs(玩家数据) do
      if 玩家数据[n].管理==nil and 玩家数据[n].角色:取任务(107)~=0 then
        玩家数据[n].角色:取消任务(玩家数据[n].角色:取任务(107))
        常规提示(n,"你的闯关任务已经被自动取消")
      end
    end
    for n, v in pairs(任务数据) do
      if 任务数据[n]~=nil and 任务数据[n].类型 == 107 then
        任务数据[n]=nil
      end
    end
end

return 刷怪处理