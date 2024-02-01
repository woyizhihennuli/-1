-- @Author: baidwwy
-- @Date:   2023-03-10 11:49:53
-- @Last Modified by:   baidwwy
-- @Last Modified time: 2024-01-30 17:36:18
local 战斗处理类 = class()
local jhf = string.format
local qz=math.floor
function 战斗处理类:初始化()end

function 战斗处理类:设置断线玩家(id)
  for n=1,#self.参战玩家 do
    if self.参战玩家[n].id==id then
      self.参战玩家[n].断线=true
    end
  end
end


--------------------摩托修改重连-------------
function 战斗处理类:设置重连玩家(id)
  local 编号=0
  for n=1,#self.参战玩家 do
    if self.参战玩家[n].id==id then
      self.参战玩家[n].断线=false
      self.参战玩家[n].断线等待=true
      self.参战玩家[n].连接id=玩家数据[id].连接id
      编号=n
    end
  end
  if 编号==0 then
    玩家数据[id].战斗=0
    return
  end
  local 战斗单位编号=self:取参战编号(self.参战玩家[编号].id,"角色")
  发送数据(self.参战玩家[编号].连接id,5501,{id=self.参战玩家[编号].队伍,音乐=50,总数=#self.参战单位})
  local x待发送数据 = {}
  for i=1,#self.参战单位 do
    x待发送数据[i]=self:取加载信息(i)
  end
  发送数据(self.参战玩家[编号].连接id,5515,x待发送数据)--5502
  -- 给重连玩家同步TP血量
  local 血量={}
  for n=1,#self.参战单位 do
    血量[n]={气血=self.参战单位[n].气血,气血上限=self.参战单位[n].气血上限 or self.参战单位[n].最大气血,最大气血=self.参战单位[n].最大气血,魔法=self.参战单位[n].魔法,最大魔法=self.参战单位[n].最大魔法,愤怒=self.参战单位[n].愤怒}
  end
  发送数据(self.参战玩家[编号].连接id,5520,血量)
  x待发送数据={}
  self.参战玩家[编号].重连加载=true
  if self.回合进程=="命令回合" then
    local 剩余命令时间=60-(os.time()-self.等待起始)
    local 目标={战斗单位编号}
    -- 此处判断玩家操作单位有哪些
    if self.参战单位[战斗单位编号].召唤兽~=nil then
      目标[2]=self.参战单位[战斗单位编号].召唤兽
    end
    if self.参战单位[战斗单位编号].助战明细 ~= nil then
      for i=1,#self.参战单位[战斗单位编号].助战明细 do
          目标[#目标+1] = self.参战单位[战斗单位编号].助战明细[i]
      end
    end
    发送数据(self.参战玩家[编号].连接id,5503.1,{目标,self.回合数,math.floor(剩余命令时间/10),剩余命令时间%10})
  end
  if self.回合进程=="执行回合" then
    if #self.参战玩家==1 then
       self.执行等待=0
    end
  end
  if self.执行等待==0 then
    self.执行等待=self.执行等待+5
    发送数据(self.参战玩家[编号].连接id,38,{内容=format("#G你已经重新加入战斗，预计将在#Y%s#G秒后同步战斗操作。",5),频道="xt"})
  else
    发送数据(self.参战玩家[编号].连接id,38,{内容=format("#G你已经重新加入战斗，预计将在#Y%s#G秒后可以下达战斗指令。当其他玩家进入下达命令回合时，您将提前结束等待。",self.执行等待-os.time()),频道="xt"})
  end
end

function 战斗处理类:设置断线重连(id)
  local 编号 = 0
  for n=1,#self.参战玩家 do
    if self.参战玩家[n].id==id then
      self.参战玩家[n].断线=false
      self.参战玩家[n].断线等待=true
      self.参战玩家[n].连接id=玩家数据[id].连接id
    end
    编号 = n
  end

  local 死亡计算={0,0}
  for n=1,#self.参战单位 do
    self.参战单位[n].磐石=nil
    if self.参战单位[n].气血<=0 or self.参战单位[n].捕捉 or self.参战单位[n].逃跑 then
      if self.参战单位[n].队伍==self.队伍区分[1] then
        死亡计算[1]=死亡计算[1]+1
      else
        死亡计算[2]=死亡计算[2]+1
      end
    end
  end

  if 死亡计算[1]==self.队伍数量[1] then
    self.回合进程="结束回合"
    self:结束战斗(self.队伍区分[2],self.队伍区分[1])
     return
  elseif 死亡计算[2]==self.队伍数量[2] then
    self.回合进程="结束回合"
    self:结束战斗(self.队伍区分[1],self.队伍区分[2])
    return
  end
  self.参战玩家[编号].重连加载=true
  if self.执行等待==0 then
    self.执行等待=self.执行等待+5
    发送数据(self.参战玩家[编号].连接id,38,{内容=format("#G你已经重新加入战斗，预计将在#Y%s#G秒后同步战斗操作。",self.执行等待-os.time()),频道="xt"})
  else
    发送数据(self.参战玩家[编号].连接id,38,{内容=format("#G你已经重新加入战斗，预计将在#Y%s#G秒后可以下达战斗指令。当其他玩家进入下达命令回合时，您将提前结束等待。",self.执行等待-os.time()),频道="xt"})
  end
end

function 战斗处理类:设置观战玩家(观战id,id)
  local 编号=0
  for n=1,#self.参战玩家 do
    if self.参战玩家[n].id==观战id then
      编号=n
    end
  end
  发送数据(玩家数据[id].连接id,5501,{id=self.参战玩家[编号].队伍,音乐=self.战斗类型,总数=#self.参战单位})
  local x待发送数据 = {}
  for i=1,#self.参战单位 do
    x待发送数据[i]=self:取加载信息(i)
  end
  发送数据(玩家数据[id].连接id,5516,x待发送数据)--5502
  self.观战玩家[id]={数字id=id,连接id=玩家数据[id].连接id}
  if self.执行等待==0 then
    self.执行等待=os.time()+5
    发送数据(玩家数据[id].连接id,38,{内容=format("#G你已经进入观战，预计将在#Y%s#G秒后同步观战方战斗操作。",self.执行等待-os.time()),频道="xt"})
  else
    发送数据(玩家数据[id].连接id,38,{内容=format("#G你已经进入观战，预计将在#Y%s#G秒后同步观战方战斗操作。",self.执行等待-os.time()),频道="xt"})
  end
end

function 战斗处理类:删除观战玩家(观战id)
  self.观战玩家[观战id] = nil
end


function 战斗处理类:进入战斗(玩家id,序号,任务id,地图)
  self.战斗类型=序号
  self.任务id=任务id
  self.玩家胜利=true
  self.战斗发言数据={}
  self.战斗失败=false
  self.观战玩家={}
  self.中断计算=false
  self.参战单位={}
  self.参战玩家={}
  self.进入战斗玩家id=玩家id
  self.飞升序号=0
  self.战斗计时=os.time()
  self.加载等待=7
  self.回合进程="加载回合"
  self.等待时间={初始=60,延迟=2}
  self.队伍数量={[1]=0,[2]=0}
  self.观战方=玩家id
  self.对战方=任务id
  self.防卡战斗={回合=0,时间=os.time(),执行=false}
  self.pk战斗=false
  self.阵法使用=true
  self.结束等待=0
  self.战斗地图=玩家数据[玩家id].角色.数据.地图数据.编号
  self.加载数量=0
  self.等待起始=0
  self.战斗类型=序号
  self.执行等待=0
  self.最低执行时间=0
  self.回合数=0
  self.同门死亡=false
  self.是否执行行动={}
  self.执行中复活单位={}
  self.回合中复活=false
  self.无人操作=0
  if 玩家数据[玩家id].队伍==0 then
    self.发起id=玩家id
  else
    self.发起id=玩家数据[玩家id].队伍
  end
  self.队伍区分={[1]=self.发起id,[2]=0}
  --加载战斗脚本
  self.战斗脚本 = nil
  local 战斗脚本名 = "BattleScripts/battle_"..序号
  if 文件是否存在(战斗脚本名..".lua") then
    self.战斗脚本=require(战斗脚本名)(玩家数据[玩家id].战斗)
  end
  --加载队伍数量
  self.玩家数据={}
    if 玩家数据[玩家id].队伍==0 then
      self.玩家数据[1]={id=玩家id,队伍=玩家id,位置=1}
    else
      local 临时队伍=玩家数据[玩家id].队伍
      for n=1,#队伍数据[临时队伍].成员数据 do
        if 队伍处理类:取是否助战(玩家数据[玩家id].队伍,n) == 0 then
          self.玩家数据[#self.玩家数据+1]={id=队伍数据[临时队伍].成员数据[n],队伍=临时队伍,位置=n}
          local 我的id=队伍数据[临时队伍].成员数据[n]
          for i=n,#队伍数据[临时队伍].成员数据 do
            local 你的id=队伍数据[临时队伍].成员数据[i]
            if 我的id~=你的id then
              for a=1,#玩家数据[我的id].角色.数据.好友数据.好友 do
                if 玩家数据[我的id].角色.数据.好友数据.好友[a].id==你的id then
                  for w=1,#玩家数据[你的id].角色.数据.好友数据.好友 do
                    if 玩家数据[你的id].角色.数据.好友数据.好友[w].id==我的id then
                      if 玩家数据[你的id].角色.数据.好友数据.好友[w].好友度==nil then
                        玩家数据[你的id].角色.数据.好友数据.好友[w].好友度=1
                      else
                        玩家数据[你的id].角色.数据.好友数据.好友[w].好友度=玩家数据[你的id].角色.数据.好友数据.好友[w].好友度+1
                      end
                      if 玩家数据[我的id].角色.数据.好友数据.好友[a].好友度==nil then
                        玩家数据[我的id].角色.数据.好友数据.好友[a].好友度=1
                      else
                        玩家数据[我的id].角色.数据.好友数据.好友[a].好友度=玩家数据[我的id].角色.数据.好友数据.好友[a].好友度+1
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if 序号>=200000 then --PK
      self.挑战id=任务id--4000130
      self.队伍区分[2] = self.挑战id
      if 玩家数据[self.挑战id].队伍==0 then
        self.玩家数据[#self.玩家数据+1]={id=self.挑战id,队伍=self.挑战id,位置=1}
      else
        for n=1,#队伍数据[玩家数据[self.挑战id].队伍].成员数据 do
          if 队伍处理类:取是否助战(玩家数据[self.挑战id].队伍,n) == 0 then
            self.玩家数据[#self.玩家数据+1]={id=队伍数据[玩家数据[self.挑战id].队伍].成员数据[n],队伍=self.挑战id,位置=n}
            local 我的id=队伍数据[玩家数据[self.挑战id].队伍].成员数据[n]
            for i=n,#队伍数据[玩家数据[self.挑战id].队伍].成员数据 do
                local 你的id=队伍数据[玩家数据[self.挑战id].队伍].成员数据[i]
                if 我的id~=你的id then
                  for a=1,#玩家数据[我的id].角色.数据.好友数据.好友 do
                    if 玩家数据[我的id].角色.数据.好友数据.好友[a].id==你的id then
                      for w=1,#玩家数据[你的id].角色.数据.好友数据.好友 do
                        if 玩家数据[你的id].角色.数据.好友数据.好友[w].id==我的id then
                          if 玩家数据[你的id].角色.数据.好友数据.好友[w].好友度==nil then
                            玩家数据[你的id].角色.数据.好友数据.好友[w].好友度=1
                          else
                            玩家数据[你的id].角色.数据.好友数据.好友[w].好友度=玩家数据[你的id].角色.数据.好友数据.好友[w].好友度+1
                          end
                          if 玩家数据[我的id].角色.数据.好友数据.好友[a].好友度==nil then
                            玩家数据[我的id].角色.数据.好友数据.好友[a].好友度=1
                          else
                            玩家数据[我的id].角色.数据.好友数据.好友[a].好友度=玩家数据[我的id].角色.数据.好友数据.好友[a].好友度+1
                          end
                        end
                      end
                    end
                  end
                end
              end
          end
        end
      end
    end
  --设定发起方单位
  self.加载数量=#self.玩家数据
    if 序号<200000 then
    if 序号==100001 then --野外单位
      self:加载野外单位()
    elseif 序号==100007 then
      self:加载野外单位1()
    else
      self:加载指定单位(地图,任务id)
    end
  end

  for n,v in pairs(self.玩家数据) do
    self.参战玩家[#self.参战玩家+1]={队伍=self.玩家数据[n].队伍,id=self.玩家数据[n].id,连接id=玩家数据[self.玩家数据[n].id].连接id,断线=false,退出=false}
    self:加载单个玩家(self.玩家数据[n].id,self.玩家数据[n].位置)
     if  玩家数据[self.参战玩家[n].id].子角色操作~=nil then
        self.加载数量=self.加载数量-1
        self.无人操作=self.无人操作+1
      end
  end


  self:重置单位属性()
  for n=1,#self.参战玩家 do
    发送数据(self.参战玩家[n].连接id,5501,{id=self.参战玩家[n].队伍,音乐=self.战斗类型,总数=#self.参战单位})
    for i=1,#self.参战单位 do
      发送数据(self.参战玩家[n].连接id,5502,self:取加载信息(i))
    end
  end

  local 队伍御兽={}
  for i=1,#self.参战单位 do
    if self:取奇经八脉是否有(i,"驭兽") then
      队伍御兽[self.参战单位[i].队伍]=self.参战单位[i].等级+10
    end
  end
  for i=1,#self.参战单位 do
    if self.参战单位[i].类型=="bb" then
      if 队伍御兽[self.参战单位[i].队伍]~=nil then
        self.参战单位[i].伤害=qz(self.参战单位[i].伤害+队伍御兽[self.参战单位[i].队伍]*0.4)
        self.参战单位[i].防御=qz(self.参战单位[i].防御+队伍御兽[self.参战单位[i].队伍]*0.4)
        self.参战单位[i].灵力=qz(self.参战单位[i].灵力+队伍御兽[self.参战单位[i].队伍]*0.2)
        self.参战单位[i].法防=qz(self.参战单位[i].法防+队伍御兽[self.参战单位[i].队伍]*0.2)
      end
    end
  end

for i=1,#self.参战单位 do
    if self:取玩家战斗()==true  then
    if self.参战单位[i].类型=="bb" then
        self.参战单位[i].伤害=qz(self.参战单位[i].伤害*0.5)
        self.参战单位[i].防御=qz(self.参战单位[i].防御*0.5)
        self.参战单位[i].速度=qz(self.参战单位[i].速度*0.5)
        self.参战单位[i].灵力=qz(self.参战单位[i].灵力*0.5)
        self.参战单位[i].法防=qz(self.参战单位[i].法防*0.5)
        else
        self.参战单位[i].伤害=qz(self.参战单位[i].伤害*0.7)
        self.参战单位[i].防御=qz(self.参战单位[i].防御*0.7)
        self.参战单位[i].速度=qz(self.参战单位[i].速度*0.7)
        self.参战单位[i].灵力=qz(self.参战单位[i].灵力*0.7)
        self.参战单位[i].法防=qz(self.参战单位[i].法防*0.7)
    end
  end
end



  if self.战斗脚本 and self.战斗脚本.战斗准备后 then
    --self.战斗脚本:OnTurnReady(1)
    __gge.safecall(self.战斗脚本.战斗准备后,self)
  end
end

function 战斗处理类:添加bb法宝属性(编号,id)
  local 主人=self:取参战编号(id,"角色")
  if 主人==nil then
    return
  end
  for n=1,#self.参战单位[主人].法宝佩戴 do
    local 名称=self.参战单位[主人].法宝佩戴[n].名称
    local 境界=self.参战单位[主人].法宝佩戴[n].境界
    if 主人~=nil and n~=nil then
      if 名称=="九黎战鼓" and  self:扣除法宝灵气(主人,n,1) then
        self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*5)
      elseif 名称=="盘龙壁" and  self:扣除法宝灵气(主人,n,1) then
        self.参战单位[编号].防御=self.参战单位[编号].防御+qz(境界*5)
      elseif 名称=="神行飞剑" and  self:扣除法宝灵气(主人,n,1) then
        self.参战单位[编号].速度=self.参战单位[编号].速度+qz(境界*2)
      elseif 名称=="汇灵盏" and  self:扣除法宝灵气(主人,n,1) then
        self.参战单位[编号].灵力=self.参战单位[编号].灵力+qz(境界*3)
        self.参战单位[编号].法防=self.参战单位[编号].法防+qz(境界*3)
      elseif 名称=="兽王令" and self.参战单位[编号].门派 == "狮驼岭" and  self:扣除法宝灵气(主人,n,1) then
        self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*5)
        self.参战单位[编号].防御=self.参战单位[编号].防御+qz(境界*3)
        self.参战单位[编号].速度=self.参战单位[编号].速度+qz(境界*2)
        self.参战单位[编号].灵力=self.参战单位[编号].灵力+qz(境界*3)
        self.参战单位[编号].法防=self.参战单位[编号].法防+qz(境界*3)
      end
    end
  end
end

function 战斗处理类:取指定法宝(编号,法宝,数额,扣除)
  if self.参战单位[编号]==nil or self.参战单位[编号].类型~="角色" then
    return false
  end
  local 是否有 = false
  local id=self.参战单位[编号].玩家id
  for n=1,#self.参战单位[编号].法宝佩戴 do
      if self.参战单位[编号].法宝佩戴[n].名称==法宝 and not 是否有 then
        if 扣除~=nil then
          return true
        else
          if 名称=="金甲仙衣" and self.参战单位[编号].法宝佩戴[n].境界*5<取随机数() then
            是否有=true
            return false
          elseif 名称=="降魔斗篷" and self.参战单位[编号].法宝佩戴[n].境界*4<取随机数() then
            是否有=true
            return false
          elseif 名称=="嗜血幡" and self.参战单位[编号].法宝佩戴[n].境界*5<取随机数()  then
            是否有=true
            return false
          end
          local 扣除id=self.参战单位[编号].法宝佩戴[n].序列
          if 玩家数据[id].道具.数据[扣除id]==nil then
            return false
          elseif 玩家数据[id].道具.数据[扣除id].魔法<数额 then
            return false
          elseif self.参战单位[编号].法宝已扣 ~= nil and self.参战单位[编号].法宝已扣[法宝] ~= nil then
            return true
          else
            玩家数据[id].道具.数据[扣除id].魔法=玩家数据[id].道具.数据[扣除id].魔法-数额
            发送数据(玩家数据[id].连接id,38,{内容="你的法宝["..玩家数据[id].道具.数据[扣除id].名称.."]灵气减少了"..数额.."点"})
            if self.参战单位[编号].法宝已扣 == nil then
              self.参战单位[编号].法宝已扣 = {}
            end
            self.参战单位[编号].法宝已扣[法宝] = true
            return true
          end
        end
      end
    end
  return false
end

function 战斗处理类:取奇经八脉是否有(编号,名称)
  if self.参战单位[编号].奇经八脉~=nil and self.参战单位[编号].奇经八脉[名称] ~= nil and self.参战单位[编号].奇经八脉[名称] == 1 then
    return true
  end
  return false
end

function 战斗处理类:直接取角色取奇经八脉是否有(编号,名称)
  if 玩家数据[编号].角色.数据.奇经八脉~=nil and 玩家数据[编号].角色.数据.奇经八脉[名称] ~= nil and 玩家数据[编号].角色.数据.奇经八脉[名称] == 1 then
    return true
  end
  return false
end
function 战斗处理类:加载法宝1(编号,id,助战编号)
  for n=1,3 do
    local 符合=false
  if 玩家数据[id].助战.数据[助战编号].法宝佩戴 ==nil then
  return
  end
    if 玩家数据[id].助战.数据[助战编号].法宝佩戴[n]~=nil then
      local 道具id=玩家数据[id].助战.数据[助战编号].法宝佩戴[n]
      if 玩家数据[id].道具.数据[道具id]~=nil then
        local 名称=玩家数据[id].道具.数据[道具id].名称
        local 境界=玩家数据[id].道具.数据[道具id].气血
        local 灵气=玩家数据[id].道具.数据[道具id].魔法
        local 五行=玩家数据[id].道具.数据[道具id].五行
        local 特技=玩家数据[id].道具.数据[道具id].特技
        local 临时数据=取物品数据(名称)
        self.参战单位[编号].法宝佩戴[#self.参战单位[编号].法宝佩戴+1]={名称=名称,境界=境界,玩家id=id,序列=玩家数据[id].助战.数据[助战编号].法宝佩戴[n]}
        local 法宝序列=#self.参战单位[编号].法宝佩戴

        if 编号~=nil and 法宝序列~= nil then
            if 名称=="飞剑" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].命中=self.参战单位[编号].命中+qz(境界*10)
            elseif 名称=="拭剑石" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*10)
              self.参战单位[编号].固定伤害=self.参战单位[编号].固定伤害+qz(境界*10)
            elseif 名称=="七杀" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*5+50)
            elseif 名称=="风袋" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].速度=self.参战单位[编号].速度+qz(境界*3)+10
            elseif 名称=="五火神焰印" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].法暴=self.参战单位[编号].法暴+qz(境界*0.5+1)
            elseif 名称=="附灵玉" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].灵力=self.参战单位[编号].灵力+qz(境界*3+10)
              self.参战单位[编号].法防=self.参战单位[编号].法防+qz(境界*3+10)
            elseif 名称=="月影" and self:扣除法宝灵气(编号,法宝序列,1) and self.参战单位[编号].门派 =="神木林"  then
              if self.参战单位[编号].法连==nil then
                self.参战单位[编号].法连=0
              end
              self.参战单位[编号].法连=self.参战单位[编号].法连+qz(境界*0.5+1)
            elseif 名称=="流影云笛" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].法术伤害==nil then
                self.参战单位[编号].法术伤害=0
              end
              self.参战单位[编号].法术伤害=self.参战单位[编号].法术伤害+qz(境界*2+10)
            elseif 名称=="宿幕星河" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].法暴==nil then
                self.参战单位[编号].法暴=0
              end
              self.参战单位[编号].法暴=self.参战单位[编号].法暴+qz(境界*0.5+1)
            elseif 名称=="蟠龙玉璧" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].防御=self.参战单位[编号].防御+qz(境界*5+100)
              self.参战单位[编号].法防=self.参战单位[编号].法防+qz(境界*5+100)
            elseif 名称=="落星飞鸿" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*5+100)
            elseif 名称=="千斗金樽" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].必杀==nil then
                self.参战单位[编号].必杀=0
              end
              self.参战单位[编号].必杀=self.参战单位[编号].必杀+qz(境界*0.5+1)
            elseif 名称=="归元圣印" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].治疗能力==nil then
                self.参战单位[编号].治疗能力=0
              end
              self.参战单位[编号].治疗能力=self.参战单位[编号].治疗能力+(境界*6+100)
            elseif 名称=="碧玉葫芦" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].治疗能力==nil then
                self.参战单位[编号].治疗能力=0
              end
              self.参战单位[编号].治疗能力=self.参战单位[编号].治疗能力+(境界*6+10)
            elseif 名称=="嗜血幡" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].必杀==nil then
                self.参战单位[编号].必杀=0
              end
              self.参战单位[编号].必杀=self.参战单位[编号].必杀+qz(境界*0.5)
            elseif 名称=="定风珠" and self.参战单位[编号].门派 == "五庄观" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="天师符" and self.参战单位[编号].门派 == "方寸山" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="雷兽" and self.参战单位[编号].门派 == "天宫" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="幽灵珠" and self.参战单位[编号].门派 == "无底洞" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="迷魂灯" and self.参战单位[编号].门派 == "盘丝洞" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="织女扇" and self.参战单位[编号].门派 == "女儿村" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            end
          end
      end
    end
  end
end

function 战斗处理类:加载奇经八脉1(编号,id,助战编号)
  if 玩家数据[id].助战.数据[助战编号].奇经八脉~=nil then
    self.参战单位[编号].奇经八脉=玩家数据[id].助战.数据[助战编号].奇经八脉
  end
end

function 战斗处理类:取指定法宝境界(编号,法宝)
  if self.参战单位[编号].类型~="角色" then
    return false
  end
  local id=self.参战单位[编号].玩家id
  for n=1,#self.参战单位[编号].法宝佩戴 do
    if self.参战单位[编号].法宝佩戴[n].名称==法宝 then
      return self.参战单位[编号].法宝佩戴[n].境界
    end
  end
  return false
end

function 战斗处理类:扣除法宝灵气(编号,序列,数额,类型)
  local 扣除id=self.参战单位[编号].法宝佩戴[序列].序列
  local id=self.参战单位[编号].玩家id

  if 类型==nil then
    if 玩家数据[id].道具.数据[扣除id].魔法<数额 then
      return false
    else
      玩家数据[id].道具.数据[扣除id].魔法=玩家数据[id].道具.数据[扣除id].魔法-数额
      发送数据(玩家数据[id].连接id,38,{内容="你的法宝["..玩家数据[id].道具.数据[扣除id].名称.."]灵气减少了"..数额.."点"})
      return true
    end
    else
    if 玩家数据[id].道具.数据[扣除id].魔法<取灵气上限(玩家数据[id].道具.数据[扣除id].分类) then
      玩家数据[id].道具.数据[扣除id].魔法=玩家数据[id].道具.数据[扣除id].魔法+数额
      发送数据(玩家数据[id].连接id,38,{内容="你的法宝["..玩家数据[id].道具.数据[扣除id].名称.."]灵气增加了"..数额.."点"})
    else
      发送数据(玩家数据[id].连接id,38,{内容="你的法宝["..玩家数据[id].道具.数据[扣除id].名称.."]灵气已经满了，无法再获得灵气"})
    end
  end
end

function 战斗处理类:加载奇经八脉(编号,id)
  if 玩家数据[id].角色.数据.奇经八脉~=nil then
    self.参战单位[编号].奇经八脉=玩家数据[id].角色.数据.奇经八脉
  end
end

function 战斗处理类:加载法宝(编号,id)
  for n=1,3 do
    local 符合=false
    if 玩家数据[id].角色.数据.法宝佩戴[n]~=nil then
      local 道具id=玩家数据[id].角色.数据.法宝佩戴[n]
      if 玩家数据[id].道具.数据[道具id]~=nil then
        local 名称=玩家数据[id].道具.数据[道具id].名称
        local 境界=玩家数据[id].道具.数据[道具id].气血
        local 灵气=玩家数据[id].道具.数据[道具id].魔法
        local 五行=玩家数据[id].道具.数据[道具id].五行
        local 特技=玩家数据[id].道具.数据[道具id].特技
        local 临时数据=取物品数据(名称)
        self.参战单位[编号].法宝佩戴[#self.参战单位[编号].法宝佩戴+1]={名称=名称,境界=境界,五行=五行,玩家id=id,序列=玩家数据[id].角色.数据.法宝佩戴[n]}
        local 法宝序列=#self.参战单位[编号].法宝佩戴
        if 编号~=nil and 法宝序列~= nil then
            if 名称=="飞剑" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].命中=self.参战单位[编号].命中+qz(境界*10)
            elseif 名称=="拭剑石" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*10)
              self.参战单位[编号].固定伤害=self.参战单位[编号].固定伤害+qz(境界*10)
    -- 0914 法宝数值平衡  七杀、流影云笛、盘龙玉璧、落星飞鸿
            elseif 名称=="七杀" and self.参战单位[编号].门派 == "大唐官府" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*10)
            elseif 名称=="风袋" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].速度=self.参战单位[编号].速度+qz(境界*3)+10
            elseif 名称=="五火神焰印" and self.参战单位[编号].门派 == "魔王寨" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].法暴=self.参战单位[编号].法暴+qz(境界*0.5+3)
            elseif 名称=="附灵玉" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].灵力=self.参战单位[编号].灵力+qz(境界*3+10)
              self.参战单位[编号].法防=self.参战单位[编号].法防+qz(境界*3+10)
            elseif 名称=="月影" and self.参战单位[编号].门派 == "神木林" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].法连==nil then
                self.参战单位[编号].法连=0
              end
              self.参战单位[编号].法连=self.参战单位[编号].法连+qz(境界*0.5+1)
            elseif 名称=="流影云笛" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].法术伤害==nil then
                self.参战单位[编号].法术伤害=0
              end
              self.参战单位[编号].法术伤害=self.参战单位[编号].法术伤害+qz(境界*8)
            elseif 名称=="宿幕星河" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].法暴==nil then
                self.参战单位[编号].法暴=0
              end
              self.参战单位[编号].法暴=self.参战单位[编号].法暴+qz(境界*0.5+3)
            elseif 名称=="蟠龙玉璧" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].防御=self.参战单位[编号].防御+qz(境界*12)
              self.参战单位[编号].法防=self.参战单位[编号].法防+qz(境界*12)
            elseif 名称=="落星飞鸿" and self:扣除法宝灵气(编号,法宝序列,1) then
              self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(境界*12)
            elseif 名称=="千斗金樽" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].必杀==nil then
                self.参战单位[编号].必杀=0
              end
              self.参战单位[编号].必杀=self.参战单位[编号].必杀+qz(境界+5)
              -----------------------摩托修改法宝归元圣印
            elseif 名称=="归元圣印" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].治疗能力==nil then
                self.参战单位[编号].治疗能力=0
              end
                self.参战单位[编号].治疗能力=self.参战单位[编号].治疗能力+(境界*10)
              -- self.参战单位[编号].治疗能力=self.参战单位[编号].治疗能力+(境界*10+100)
            elseif 名称=="碧玉葫芦" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].治疗能力==nil then
                self.参战单位[编号].治疗能力=0
              end
              self.参战单位[编号].治疗能力=self.参战单位[编号].治疗能力+(境界*6+10)
            elseif 名称=="嗜血幡" and self:扣除法宝灵气(编号,法宝序列,1) then
              if self.参战单位[编号].必杀==nil then
                self.参战单位[编号].必杀=0
              end
              self.参战单位[编号].必杀=self.参战单位[编号].必杀+qz(境界*0.5)
            elseif 名称=="定风珠" and self.参战单位[编号].门派 == "五庄观" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="天师符" and self.参战单位[编号].门派 == "方寸山" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="雷兽" and self.参战单位[编号].门派 == "天宫" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="幽灵珠" and self.参战单位[编号].门派 == "无底洞" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="迷魂灯" and self.参战单位[编号].门派 == "盘丝洞" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            elseif 名称=="织女扇" and self.参战单位[编号].门派 == "女儿村" and self:扣除法宝灵气(编号,法宝序列,1)  then
              if self.参战单位[编号].封印命中等级==nil then
                self.参战单位[编号].封印命中等级=0
              end
              self.参战单位[编号].封印命中等级=self.参战单位[编号].封印命中等级+(境界*10)
            end
          end
      end
    end
  end
end

function 战斗处理类:重置单位属性()
  self.战斗流程={}
  for n=1,#self.参战单位 do
    self.参战单位[n].法术状态={}
    if self.参战单位[n].奇经八脉==nil then
      self.参战单位[n].奇经八脉={}
    end
    if self.参战单位[n].追加法术==nil then
      self.参战单位[n].追加法术={}
    end
    if self.参战单位[n].附加状态==nil then
      self.参战单位[n].附加状态={}
    end
    if self.参战单位[n].主动技能==nil then
      self.参战单位[n].主动技能={}
    end
    if self.参战单位[n].武器伤害==nil then
      self.参战单位[n].武器伤害=0
    end
    self.参战单位[n].特技技能={}
    if self.参战单位[n].队伍==0 or self.参战单位[n].类型=="系统角色" then
    self.参战单位[n].战意=999
    else
    self.参战单位[n].战意=0
    end
    self.参战单位[n].法暴=0
    self.参战单位[n].必杀=1
    self.参战单位[n].溅射=0
    self.参战单位[n].溅射人数=0
    self.参战单位[n].驱怪=0
    --self.参战单位[n].夜战=0
    if self.参战单位[n].符石技能效果==nil then
      self.参战单位[n].符石技能效果={}
    end
    self.参战单位[n].高山流水=0
    self.参战单位[n].百无禁忌=0
    self.参战单位[n].天降大任=0
    self.参战单位[n].飞檐走壁=0
    self.参战单位[n].慈悲效果=0
    self.参战单位[n].攻击修炼=0
    self.参战单位[n].法术修炼=0
    self.参战单位[n].怒击效果=false
    self.参战单位[n].防御修炼=0
    self.参战单位[n].抗法修炼=0
    self.参战单位[n].猎术修炼=0
    self.参战单位[n].毫毛次数=0
    self.参战单位[n].法宝佩戴={}
    self.参战单位[n].攻击五行=""
    self.参战单位[n].防御五行=""
    self.参战单位[n].修炼数据={法修=0,抗法=0,攻击=0,猎术=0}
    if self.参战单位[n].怪物修炼 ~= nil then
      self.参战单位[n].攻击修炼 = self.参战单位[n].怪物修炼.攻击修炼 or 0
      self.参战单位[n].法术修炼 = self.参战单位[n].怪物修炼.法术修炼 or 0
      self.参战单位[n].防御修炼 = self.参战单位[n].怪物修炼.防御修炼 or 0
      self.参战单位[n].抗法修炼 = self.参战单位[n].怪物修炼.抗法修炼 or 0
    end
    if self.参战单位[n].命中==nil then
      self.参战单位[n].命中=self.参战单位[n].伤害
    end
    if self.参战单位[n].法术伤害结果==nil then
      self.参战单位[n].法术伤害结果=0
    end
    for i=1,#灵饰战斗属性 do
      self.参战单位[n][灵饰战斗属性[i]]=0
    end
    if self.参战单位[n].队伍~=0 and self.参战单位[n].系统队友==nil then
      if self.参战单位[n].类型=="角色" and  self.参战单位[n].助战编号 == nil then
        self.参战单位[n].攻击修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.修炼.攻击修炼[1]
        self.参战单位[n].法术修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.修炼.法术修炼[1]
        self.参战单位[n].防御修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.修炼.防御修炼[1]
        self.参战单位[n].抗法修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.修炼.抗法修炼[1]
        self.参战单位[n].猎术修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.修炼.猎术修炼[1]
        if self.参战单位[n].通真达灵 ~= nil then
          self.参战单位[n].法术防御 = self.参战单位[n].法术防御 * (1+self.参战单位[n].通真达灵/100)
        end

        local 特技=玩家数据[self.参战单位[n].玩家id].角色:取特技()
        for i=1,#特技 do
          self.参战单位[n].特技技能[i]={名称=特技[i],等级=0}
        end

        for i,v in pairs(玩家数据[self.参战单位[n].玩家id].角色.数据.装备) do
          if v ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v] ~= nil then
            if (玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 == "神佑") or (玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 == "神佑") then
              self.参战单位[n].神佑 = 10
            end
            if (玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 == "再生") or (玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 == "再生") then
            self.参战单位[n].再生 = qz(self.参战单位[n].等级/3)
            end
            if i == 5 then
              if (玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 == "愤怒") or (玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 == "愤怒") then
                self.参战单位[n].愤怒腰带 = 1
              end
              if (玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].特效 == "暴怒") or (玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].第二特效 == "暴怒") then
                self.参战单位[n].暴怒腰带 = 1
              end
            end
          end
          if v ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v] ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔 ~= nil then
            玩家数据[self.参战单位[n].玩家id].角色:附魔装备刷新(self.参战单位[n].玩家id,v)
            if i+0 == 5 and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.愤怒 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.愤怒.数值 > 0 then
              self.参战单位[n].愤怒=self.参战单位[n].愤怒+玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.愤怒.数值
              if self.参战单位[n].愤怒>=150 then
                self.参战单位[n].愤怒=150
              end
            elseif i+0 == 2 and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术防御 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术防御.数值 > 0 then
              self.参战单位[n].法术防御=self.参战单位[n].法术防御+玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术防御.数值
            elseif i+0 == 2 and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术伤害 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术伤害.数值 > 0 then
              self.参战单位[n].法术伤害=self.参战单位[n].法术伤害+玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术伤害.数值
            end
          end
        end
              --检查套装效果
        if self:取符石组合效果(n,"无心插柳") then
          self.参战单位[n].溅射 = self.参战单位[n].溅射 + self:取符石组合效果(n,"无心插柳")
          self.参战单位[n].溅射人数 = self.参战单位[n].溅射人数 + 2
        end
        local 临时套装={}
        local 临时人物装备 = 玩家数据[self.参战单位[n].玩家id].角色:取装备数据()
        for w, v in pairs(临时人物装备) do
          if w~=3 and 临时人物装备[w]~=nil and 临时人物装备[w].套装效果~=nil then
            if 判断是否为空表(临时套装) then
              临时套装[#临时套装+1]={临时人物装备[w].套装效果[1],临时人物装备[w].套装效果[2],数量=1}
            else
              local 新套装效果 = true
              for i=1,#临时套装 do
                if 临时套装[i][2] == 临时人物装备[w].套装效果[2] then
                  临时套装[i].数量=临时套装[i].数量+1
                  新套装效果=false
                end
              end
              if 新套装效果 then
                临时套装[#临时套装+1]={临时人物装备[w].套装效果[1],临时人物装备[w].套装效果[2],数量=1}
              end
            end
          end
        end
        if 判断是否为空表(临时套装)~=nil then
          for i=1,#临时套装 do
            if 临时套装[i].数量>=3 then
              self.参战单位[n].套装追加概率 = 0
              local 等级=self.参战单位[n].等级
                if 临时套装[i].数量>=5 then
                  self.参战单位[n].套装追加概率 = 20
                  等级=等级+10
                end
              if 临时套装[i][1]~="变身术之" then
                 self.参战单位[n][临时套装[i][1]][#self.参战单位[n][临时套装[i][1]]+1]={名称=临时套装[i][2],等级=等级}
              end
            end
          end
        end
        self.参战单位[n].变身数据=玩家数据[self.参战单位[n].玩家id].角色.数据.变身数据
        if self.参战单位[n].变身数据~=nil and 变身卡数据[self.参战单位[n].变身数据]~=nil and 变身卡数据[self.参战单位[n].变身数据].技能~="" then
          self:添加技能属性(self.参战单位[n],{变身卡数据[self.参战单位[n].变身数据].技能})
        end
        for i=1,#灵饰战斗属性 do
          self.参战单位[n][灵饰战斗属性[i]]=玩家数据[self.参战单位[n].玩家id].角色.数据[灵饰战斗属性[i]]
        end
          self:加载法宝(n,self.参战单位[n].玩家id)
          self:加载奇经八脉(n,self.参战单位[n].玩家id)
        if self.参战单位[n].经脉有无 ~= nil and self.参战单位[n].经脉有无 then
          self:经脉属性处理(n)
        end
        for i=1,#玩家数据[self.参战单位[n].玩家id].角色.数据.剧情技能 do
          if 玩家数据[self.参战单位[n].玩家id].角色.数据.剧情技能[i].名称=="妙手空空" then
            if self.战斗类型~=100001 or self.战斗类型~=100007  then
              self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称=玩家数据[self.参战单位[n].玩家id].角色.数据.剧情技能[i].名称,等级=玩家数据[self.参战单位[n].玩家id].角色.数据.剧情技能[i].等级}
            end
          end
        end
        if 玩家数据[self.参战单位[n].玩家id].角色.数据.门派~=nil then------------------------摩托哥修改凌波城开局战意
          if 玩家数据[self.参战单位[n].玩家id].角色.数据.门派=="凌波城" then
            self.参战单位[n].战意=2
          end
          for i=1,#玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能 do
            local jnname=玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i]
            if self.参战单位[n].额外技能等级[jnname.名称]== nil then
                self.参战单位[n].额外技能等级[jnname.名称] = 0
            end
            local lvjn = self.参战单位[n].额外技能等级[jnname.名称] + jnname.等级
            for s=1,#玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].包含技能 do
              self.参战单位[n].师门技能[i]={名称=self.参战单位[n].师门技能[i],等级=lvjn}
              if self.参战单位[n].师门技能[i].名称=="破浪诀" and self.参战单位[n].师门技能[i].等级>=self.参战单位[n].等级 then
                self.参战单位[n].灵力= self.参战单位[n].灵力+60
              end
              if 玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].包含技能[s].学会 then
                local 名称=玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].包含技能[s].名称
                if self:取飞升技能(名称) == false or self:取飞升技能(名称) then
                  if 名称 == "舍生取义" then
                    名称 = "舍身取义"
                    玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].包含技能[s].名称 = "舍身取义"
                    for i=1,#玩家数据[self.参战单位[n].玩家id].角色.数据.人物技能 do
                      if 玩家数据[self.参战单位[n].玩家id].角色.数据.人物技能[i].名称 == "舍生取义" then
                        玩家数据[self.参战单位[n].玩家id].角色.数据.人物技能[i].名称 = "舍身取义"
                      end
                    end
                  end
                  if (self:恢复技能(名称) or self:法攻技能(名称) or self:物攻技能(名称) or self:封印技能(名称) or self:群体封印技能(名称) or self:减益技能(名称) or self:增益技能(名称)) or 名称=="兵解符" and 玩家数据[self.参战单位[n].玩家id].角色.数据.门派~="花果山" then
                    self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称=名称,等级=玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].等级}
                  end
                end
              end
            end
          end
        end

        if 玩家数据[self.参战单位[n].玩家id].角色.数据.等级<19 then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="牛刀小试",等级=玩家数据[self.参战单位[n].玩家id].角色.数据.等级+10}
        end

       if 玩家数据[self.参战单位[n].玩家id].角色.数据.数字id==1087 then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="毁灭之光",等级=玩家数据[self.参战单位[n].玩家id].角色.数据.等级+10}
        end
        if 玩家数据[self.参战单位[n].玩家id].角色.数据.门派=="大唐官府" then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="翩鸿一击",等级=玩家数据[self.参战单位[n].玩家id].角色.数据.等级+10}
        end
        -- if 玩家数据[self.参战单位[n].玩家id].角色.数据.门派=="狮驼岭" then
        --   self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="狂怒",等级=self.参战单位[n].等级+10}
        -- end
        if self:取奇经八脉是否有(n,"长驱直入") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="长驱直入",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"妙悟") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="妙悟",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"诸天看护") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="诸天看护",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"渡劫金身") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="渡劫金身",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"碎玉弄影") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="碎玉弄影",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"鸿渐于陆") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="鸿渐于陆",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"飞符炼魂") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="飞符炼魂",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"顺势而为") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="顺势而为",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"钟馗论道") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="钟馗论道",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"莲花心音") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="莲花心音",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"波澜不惊") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="波澜不惊",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"五行制化") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="五行制化",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"莲心剑意") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="莲心剑意",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"亢龙归海") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="亢龙归海",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"雷浪穿云") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="雷浪穿云",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"画地为牢") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="画地为牢",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"风雷韵动") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="风雷韵动",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"天命剑法") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="天命剑法",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"清风望月") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="清风望月",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"背水") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="背水",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"魔焰滔天") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="魔焰滔天",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"烈焰真诀") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="烈焰真诀",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"百爪狂杀") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="百爪狂杀",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"六道无量") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="六道无量",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"魑魅缠身") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="魑魅缠身",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"落花成泥") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="落花成泥",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"偷龙转凤") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="偷龙转凤",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"利刃") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="利刃",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"风卷残云") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="风卷残云",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"凋零之歌") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="凋零之歌",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"真君显灵") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="真君显灵",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"由己渡人") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="由己渡人",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"同舟共济") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="同舟共济",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"妖风四起") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="妖风四起",等级=self.参战单位[n].等级}
        end
      elseif self.参战单位[n].类型=="角色" and  self.参战单位[n].助战编号 ~= nil then
        self.参战单位[n].攻击修炼=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].修炼.攻击修炼
        self.参战单位[n].法术修炼=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].修炼.法术修炼
        self.参战单位[n].防御修炼=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].修炼.防御修炼
        self.参战单位[n].抗法修炼=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].修炼.抗法修炼
        self.参战单位[n].猎术修炼=0
        self:加载法宝1(n,self.参战单位[n].玩家id,self.参战单位[n].助战编号)
        self:加载奇经八脉1(n,self.参战单位[n].玩家id,self.参战单位[n].助战编号)
        if 玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].奇经八脉.开启奇经八脉 then
          self.参战单位[n].经脉有无 = true
          self:经脉属性处理(n)
        end
        self.参战单位[n].变身数据=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].变身
        if self.参战单位[n].变身数据~=nil and 变身卡数据[self.参战单位[n].变身数据]~=nil and 变身卡数据[self.参战单位[n].变身数据].技能~="" then
          self:添加技能属性(self.参战单位[n],{变身卡数据[self.参战单位[n].变身数据].技能})
        end
        local 特技=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].特殊技能
        for k,v in pairs(特技) do
          self.参战单位[n].特技技能[#self.参战单位[n].特技技能+1]={名称=v.名称,等级=0}
        end
        for i,v in pairs(玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].装备) do
          if v ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v] ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔 ~= nil then
            玩家数据[self.参战单位[n].玩家id].助战:附魔装备刷新(self.参战单位[n].助战编号,v)
            if v+0 == 5 and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.愤怒 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.愤怒.数值 > 0 then
              self.参战单位[n].愤怒=self.参战单位[n].愤怒+玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.愤怒.数值
              if self.参战单位[n].愤怒>=150 then
                self.参战单位[n].愤怒=150
              end
            elseif v+0 == 2 and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术防御 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术防御.数值 > 0 then
              self.参战单位[n].法术防御=self.参战单位[n].法术防御+玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术防御.数值
            elseif v+0 == 2 and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术伤害 ~= nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术伤害.数值 > 0 then
              self.参战单位[n].法术伤害=self.参战单位[n].法术伤害+玩家数据[self.参战单位[n].玩家id].道具.数据[v].临时附魔.法术伤害.数值
            end
          end
        end
        local 临时套装={}
        for i,v in pairs(玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].装备) do

          if v~=nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v]~=nil and 玩家数据[self.参战单位[n].玩家id].道具.数据[v].套装效果~=nil then
             临时套装[#临时套装+1]={玩家数据[self.参战单位[n].玩家id].道具.数据[v].套装效果[1],玩家数据[self.参战单位[n].玩家id].道具.数据[v].套装效果[2]}
          end
          local bbb=3
          if #临时套装>0 then
            for i=1,#临时套装 do
              local 重复=false
              local 数量=1
              self.参战单位[n][临时套装[i][1]]=self.参战单位[n][临时套装[i][1]] or {}
              for a=1,#self.参战单位[n][临时套装[i][1]] do
                if self.参战单位[n][临时套装[i][1]][a].名称==临时套装[i][2] then
                  重复=true
                end
              end
              if 重复==false then
                for a=1,#临时套装 do
                  if a~=i then
                    if 临时套装[a][1]==临时套装[i][1] and 临时套装[a][2]==临时套装[i][2] then
                     数量=数量+1
                    end
                  end
                end
                if 数量>=bbb then
                  self.参战单位[n].套装追加概率 = 10
                  local 等级=self.参战单位[n].等级
                  if 数量>=bbb+2 then
                    等级=等级+10
                    self.参战单位[n].套装追加概率 = 30
                  end
                  if 临时套装[i][1]~="变身术之" then
                     self.参战单位[n][临时套装[i][1]][#self.参战单位[n][临时套装[i][1]]+1]={名称=临时套装[i][2],等级=等级}
                  end
                end
              end
            end
          end
        end


        if self:取符石组合效果(n,"无心插柳") then
          self.参战单位[n].溅射 = self.参战单位[n].溅射 + self:取符石组合效果(n,"无心插柳")
          self.参战单位[n].溅射人数 = self.参战单位[n].溅射人数 + 2
        end
        self.参战单位[n].变身数据=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].变身数据
        if self.参战单位[n].变身数据~=nil and 变身卡数据[self.参战单位[n].变身数据]~=nil and 变身卡数据[self.参战单位[n].变身数据].技能~="" then
          self:添加技能属性(self.参战单位[n],{变身卡数据[self.参战单位[n].变身数据].技能})
        end
        for i=1,#灵饰战斗属性 do
          self.参战单位[n][灵饰战斗属性[i]]=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号][灵饰战斗属性[i]]
        end
        if 玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].门派~=nil then
          if 玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].门派=="凌波城" then
            self.参战单位[n].战意=2
          end
          for i=1,#玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].技能 do
            local 名称=玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].技能[i]
            if self:恢复技能(名称) or self:法攻技能(名称) or self:物攻技能(名称) or self:封印技能(名称) or self:群体封印技能(名称) or self:减益技能(名称) or self:增益技能(名称)  then
              self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称=名称,等级=self.参战单位[n].等级+10}
            end
          end
        end
        if 玩家数据[self.参战单位[n].玩家id].助战.数据[self.参战单位[n].助战编号].门派 ~= nil  then
        if self:取奇经八脉是否有(n,"长驱直入") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="长驱直入",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"妙悟") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="妙悟",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"诸天看护") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="诸天看护",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"渡劫金身") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="渡劫金身",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"碎玉弄影") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="碎玉弄影",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"鸿渐于陆") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="鸿渐于陆",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"飞符炼魂") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="飞符炼魂",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"顺势而为") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="顺势而为",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"钟馗论道") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="钟馗论道",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"莲花心音") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="莲花心音",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"波澜不惊") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="波澜不惊",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"五行制化") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="五行制化",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"莲心剑意") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="莲心剑意",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"亢龙归海") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="亢龙归海",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"雷浪穿云") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="雷浪穿云",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"画地为牢") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="画地为牢",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"风雷韵动") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="风雷韵动",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"天命剑法") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="天命剑法",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"清风望月") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="清风望月",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"背水") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="背水",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"魔焰滔天") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="魔焰滔天",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"烈焰真诀") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="烈焰真诀",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"百爪狂杀") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="百爪狂杀",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"六道无量") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="六道无量",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"魑魅缠身") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="魑魅缠身",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"落花成泥") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="落花成泥",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"偷龙转凤") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="偷龙转凤",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"利刃") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="利刃",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"风卷残云") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="风卷残云",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"凋零之歌") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="凋零之歌",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"真君显灵") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="真君显灵",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"由己渡人") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="由己渡人",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"同舟共济") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="同舟共济",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"妖风四起") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="妖风四起",等级=self.参战单位[n].等级}
        end
        if self:取奇经八脉是否有(n,"翩鸿一击") then
          self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称="翩鸿一击",等级=self.参战单位[n].等级}
        end
        end
        if 玩家数据[self.参战单位[n].玩家id].角色.数据.等级<175 then
          self:添加技能属性(self.参战单位[n],self.参战单位[n].技能)
        end
      end
    end
    if self.参战单位[n].类型~="角色" and self.参战单位[n].类型~="系统角色" and self.参战单位[n].类型 == "bb"  then
      self:添加技能属性(self.参战单位[n],self.参战单位[n].技能)
      if self.参战单位[n].法术认证~=nil then
        self:添加认证法术属性(self.参战单位[n],self.参战单位[n].法术认证)
      end
      if 玩家数据 then
      if 玩家数据[self.参战单位[n].玩家id]and 玩家数据[self.参战单位[n].玩家id].召唤兽 and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据 and 玩家数据[self.参战单位[n].玩家id] ~= nil and 玩家数据[self.参战单位[n].玩家id].召唤兽~= nil and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据~= nil then
        for i=1,#玩家数据[self.参战单位[n].玩家id].召唤兽.数据 do
          if 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].认证码~=nil and self.参战单位[n].认证码~=nil and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].认证码 == self.参战单位[n].认证码 then
            if 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[1] ~= nil  and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[2] ~= nil and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[3] ~= nil then
              if 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[1].套装效果 ~= nil and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[2].套装效果 ~= nil and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[3].套装效果 ~= nil then
                if 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[1].套装效果[2] == 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[2].套装效果[2] and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[1].套装效果[2] == 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[3].套装效果[2] and 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[2].套装效果[2] == 玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[3].套装效果[2] then
                  local 套装效果=玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[1].套装效果
                  if 套装效果[1] == "追加法术" then
                    self.参战单位[n].追加法术={[1]={名称=玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].装备[1].套装效果[2],等级=玩家数据[self.参战单位[n].玩家id].召唤兽.数据[i].等级}}
                    self.参战单位[n].套装追加概率= 15
                  elseif 套装效果[1] == "附加状态" then
                    self:添加技能属性(self.参战单位[n],{套装效果[2]})
                  end
                end
              end
            end
          end
        end
      end
      end

      if self.参战单位[n].队伍~=0 then
        self.参战单位[n].攻击修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.攻击控制力[1]
        self.参战单位[n].法术修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.法术控制力[1]
        self.参战单位[n].防御修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.防御控制力[1]
        self.参战单位[n].抗法修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.抗法控制力[1]
      end
      if self.参战单位[n].内丹 ~= nil then
          self:添加内丹属性(self.参战单位[n],self.参战单位[n].内丹)
      end
      self:添加bb法宝属性(n,self.参战单位[n].玩家id)
      if self.参战单位[n].特性 ~= nil and  self.参战单位[n].特性=="御风" then
        self:添加状态特性(n)
      end
      if self.参战单位[n].统御 ~= nil then
        local 坐骑编号 = self.参战单位[n].统御
        local 玩家id = self.参战单位[n].玩家id
        if 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号] ~= nil then
          if 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 <= 50 and 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 > 2 then
            玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 = 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 - 2
            发送数据(玩家数据[玩家id].连接id,38,{内容="你的坐骑#R"..玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].名称.."#W减少了2点饱食度"})
          elseif 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 > 50 then
            玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 = 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 - 1
            发送数据(玩家数据[玩家id].连接id,38,{内容="你的坐骑#R"..玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].名称.."#W减少了1点饱食度"})
          end
          if 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 <= 0 then
            玩家数据[玩家id].角色:坐骑刷新(坐骑编号)
            发送数据(玩家数据[玩家id].连接id,38,{内容="你的坐骑#R"..玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].名称.."#W已经饥饿难耐无法给予统御召唤兽加成了"})
          else
            self:添加技能属性(self.参战单位[n],玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].技能)
          end
        end
      end
    end
    if self.参战单位[n].动物套属性~=nil and self.参战单位[n].动物套属性.名称~="无" then
      local 取概率 = 取动物套概率(self.参战单位[n].动物套属性.名称,self.参战单位[n].动物套属性.件数)
      if self.参战单位[n].变身数据==nil and 取随机数()<=取概率 then
        self.执行等待=self.执行等待 + 3
        if 变身卡数据[self.参战单位[n].动物套属性.名称]~=nil and 变身卡数据[self.参战单位[n].动物套属性.名称].技能~="" then
            self:添加技能属性(self.参战单位[n],{变身卡数据[self.参战单位[n].动物套属性.名称].技能})
        end
        self.战斗流程[#self.战斗流程+1]={流程=707,攻击方=n,参数=self.参战单位[n].动物套属性.名称}
      end
    end
    if #self.参战单位[n].附加状态>0 then
      for i=1,#self.参战单位[n].附加状态 do
        self.参战单位[n].指令={}
        self.参战单位[n].指令.参数=self.参战单位[n].附加状态[i].名称
        self.参战单位[n].指令.目标=n
        self:法术计算(n)
      end
    end
----------------------摩托修改狮驼岭战斗开始前自动变身----------
    if n~=nil and self:取奇经八脉是否有(n,"翼展") and self:取玩家战斗()==false  then
        self.参战单位[n].指令={}
        self.参战单位[n].指令.参数="变身"
        self.参战单位[n].指令.目标=n
        self:法术计算(n)
      if self.参战单位[n].法术状态.变身~=nil then
        self.参战单位[n].法术状态.变身.回合=3
      end
    end

    if self.参战单位[n].隐身~=nil then
      self.参战单位[n].指令={目标=n}
      self:增益技能计算(n,"修罗隐身",self.参战单位[n].等级)
      if self.参战单位[n].法术状态.修罗隐身~=nil then
        self.参战单位[n].法术状态.修罗隐身.回合=self.参战单位[n].隐身

      end
    end
          if self.参战单位[n].盾气~=nil then
      self.参战单位[n].指令={目标=n}
      self:增益技能计算(n,"盾气",self.参战单位[n].等级,nil,nil,nil,self.参战单位[n].盾气)
      if self.参战单位[n].法术状态.盾气~=nil then
        self.参战单位[n].法术状态.盾气.回合=6
      end
    end
    end
  end


function 战斗处理类:取飞升技能(技能)
  local n = {"破釜沉舟","安神诀","分身术","碎甲符","舍身取义","佛法无边","一笑倾城","飞花摘叶","还阳术","黄泉之息","火甲术","摇头摆尾","天魔解体","魔息术","幻镜术","瘴气","雷霆万钧","金刚镯"
,"天地同寿","乾坤妙法","二龙戏珠","神龙摆尾","灵动九天","颠倒五行","血雨","镇魂诀","腾雷","金身舍利","摧心术"}
  for i=1,#n do
      if n[i] == 技能 then
        return true
      end
  end
  return false
end

function 战斗处理类:取加载信息(id) ----战斗加载
  local 临时数据={
    气血=self.参战单位[id].气血,
	  气血上限=self.参战单位[id].气血上限 or self.参战单位[id].最大气血,
    最大气血=self.参战单位[id].最大气血,
    魔法=self.参战单位[id].魔法,
    最大魔法=self.参战单位[id].最大魔法,
    愤怒=self.参战单位[id].愤怒,
    名称=self.参战单位[id].名称,
    模型=self.参战单位[id].模型,
    队伍=self.参战单位[id].队伍,
    位置=self.参战单位[id].位置,
    染色方案=self.参战单位[id].染色方案,
    染色组=self.参战单位[id].染色组,
    饰品染色方案=self.参战单位[id].饰品染色方案,
    饰品染色组=self.参战单位[id].饰品染色组,
    武器染色方案=self.参战单位[id].武器染色方案,
    武器染色组=self.参战单位[id].武器染色组,
    武器=self.参战单位[id].武器,
    变异=self.参战单位[id].变异,
    变身=self.参战单位[id].变身,
    类型=self.参战单位[id].类型,
    附加阵法=self.参战单位[id].附加阵法,
    主动技能=self.参战单位[id].主动技能,
    特技技能=self.参战单位[id].特技技能,
    战意=self.参战单位[id].战意,
    自动指令=self.参战单位[id].自动指令,
    自动战斗=self.参战单位[id].自动战斗,
    id=self.参战单位[id].玩家id,
    变身数据=self.参战单位[id].变身数据,
    显示饰品=self.参战单位[id].饰品,
    锦衣数据=self.参战单位[id].锦衣,
    战斗类型 = self.战斗类型,
    助战编号 = self.参战单位[id].助战编号,
    等级=self.参战单位[id].等级,
    门派 = self.参战单位[id].门派 or "无"
  }

  if self.参战单位[id].类型~="角色" and self.参战单位[id].认证码~=nil then
    临时数据.认证码=self.参战单位[id].认证码
  end


  if self.参战单位[id].类型=="角色" then
    local 玩家id=self.参战单位[id].玩家id
    if self.参战单位[id].队伍~=0 and self.参战单位[id].助战编号 == nil then
      if self.参战单位[id].装备[3]~=nil and 玩家数据[玩家id] ~= nil and  玩家数据[玩家id].角色 ~= nil and 玩家数据[玩家id].角色.数据.装备 ~= nil and 玩家数据[玩家id].角色.数据.装备[3] ~= nil then
        local 装备id=玩家数据[玩家id].角色.数据.装备[3]
        临时数据.武器={名称=玩家数据[玩家id].道具.数据[装备id].名称,子类=玩家数据[玩家id].道具.数据[装备id].子类,级别限制=玩家数据[玩家id].道具.数据[装备id].级别限制,染色方案=玩家数据[玩家id].道具.数据[装备id].染色方案,染色组=玩家数据[玩家id].道具.数据[装备id].染色组}
      end
    elseif self.参战单位[id].队伍~=0 and self.参战单位[id].助战编号 ~= nil then
      if self.参战单位[id].装备[3]~=nil then
        临时数据.武器={名称=self.参战单位[id].装备[3].名称,子类=self.参战单位[id].装备[3].子类,级别限制=self.参战单位[id].装备[3].级别限制,染色方案=self.参战单位[id].装备[3].染色方案,染色组=self.参战单位[id].装备[3].染色组}
      end
      if self.参战单位[id].变身 then
        临时数据.变身数据=self.参战单位[id].变身
        self.参战单位[id].变身=nil
      end
    end
  elseif self.参战单位[id].类型=="系统角色" then
    临时数据.武器=self.参战单位[id].武器
   elseif self.参战单位[id].类型=="系统PK角色" then
    临时数据.武器=self.参战单位[id].武器
  end
  --table.print(临时数据)
  return 临时数据
end

function 战斗处理类:增加阵法属性(编号,名称,位置,阵法加成)
  local 临时队伍id = self.参战单位[编号].队伍
  if 队伍数据[临时队伍id]~=nil and #队伍数据[临时队伍id].成员数据>=1 then
    local x阵法加成 = 1
    if 阵法加成~=nil then
      x阵法加成=1+阵法加成
    end
    if 名称=="天覆阵" then
      self.参战单位[编号].速度=qz(self.参战单位[编号].速度*0.9*x阵法加成)
      self.参战单位[编号].物理加成=1.2*x阵法加成
      self.参战单位[编号].法伤加成=1.2*x阵法加成
    elseif 名称=="风扬阵" then
      if 位置==1 then
        self.参战单位[编号].物理加成=1.2*x阵法加成
        self.参战单位[编号].法伤加成=1.2*x阵法加成
        self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.05*x阵法加成)
      elseif 位置==2 or 位置==3 then
        self.参战单位[编号].物理加成=1.1*x阵法加成
        self.参战单位[编号].法伤加成=1.1*x阵法加成
      else
       self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.1*x阵法加成)
      end
    elseif 名称=="虎翼阵" then
      if 位置==1 then
        self.参战单位[编号].物理加成=1.25*x阵法加成
        self.参战单位[编号].法伤加成=1.25*x阵法加成
      elseif 位置==2 or 位置==3 then
        self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.2*x阵法加成)
        self.参战单位[编号].法防=qz(self.参战单位[编号].法防*1.2*x阵法加成)
      else
       self.参战单位[编号].物理加成=1.2*x阵法加成
      end
    elseif 名称=="云垂阵" then
     if 位置==1 then
        self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.25*x阵法加成)
        self.参战单位[编号].法防=qz(self.参战单位[编号].法防*1.25*x阵法加成)
        self.参战单位[编号].速度=qz(self.参战单位[编号].速度*0.85*x阵法加成)
      elseif 位置==2 then
        self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.1*x阵法加成)
      elseif 位置==3 then
        self.参战单位[编号].物理加成=1.2*x阵法加成
        self.参战单位[编号].法伤加成=1.2*x阵法加成
     else
       self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.1*x阵法加成)
       end
    elseif 名称=="鸟翔阵" then
     if 位置==1 then
        self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.2*x阵法加成)
      elseif 位置==2 or 位置==3 then
        self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.1*x阵法加成)
     else
       self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.15*x阵法加成)
       end
    elseif 名称=="地载阵" then
     if 位置==1 or 位置==3 or 位置==4 then
        self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.15*x阵法加成)
        self.参战单位[编号].法防=qz(self.参战单位[编号].法防*1.15*x阵法加成)
      elseif 位置==2 then
        self.参战单位[编号].物理加成=1.15*x阵法加成
        self.参战单位[编号].法伤加成=1.15*x阵法加成
     else
       self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.1*x阵法加成)
       end
    elseif 名称=="龙飞阵" then
     if 位置==1 then
        self.参战单位[编号].法防=qz(self.参战单位[编号].法防*1.2*x阵法加成)
      elseif 位置==2 then
        self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.2*x阵法加成)
      elseif 位置==3 then
        self.参战单位[编号].法伤加成=1.3*x阵法加成
		    self.参战单位[编号].速度=qz(self.参战单位[编号].速度*0.7*x阵法加成)
      elseif 位置==4 then
		    self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.15*x阵法加成)
     elseif 位置==5 then
        self.参战单位[编号].物理加成=1.25*x阵法加成
        self.参战单位[编号].法伤加成=1.25*x阵法加成
     end
    elseif 名称=="鹰啸阵" then
      if 位置==1 then
        self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.1*x阵法加成)
      elseif 位置==2 then
        self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.15*x阵法加成)
      elseif 位置==3 then
        self.参战单位[编号].速度=qz(self.参战单位[编号].速度*1.15*x阵法加成)
      elseif 位置==4 then
        self.参战单位[编号].物理加成=1.15*x阵法加成
        self.参战单位[编号].法伤加成=1.15*x阵法加成
      else
        self.参战单位[编号].物理加成=1.1*x阵法加成
        self.参战单位[编号].法伤加成=1.1*x阵法加成
      end
    elseif 名称=="雷绝阵" then
      if 位置==1 then
        self.参战单位[编号].固伤加成=1.2
        self.参战单位[编号].bb伤害加成=1.1
        self.参战单位[编号].bb灵力加成=1.1
      elseif 位置==2 then
        self.参战单位[编号].固伤加成=1.2
        self.参战单位[编号].bb伤害加成=1.1
        self.参战单位[编号].bb灵力加成=1.1
      elseif 位置==3 then
        self.参战单位[编号].固伤加成=1.2
        self.参战单位[编号].bb伤害加成=1.1
        self.参战单位[编号].bb灵力加成=1.1
      elseif 位置==4 then
        self.参战单位[编号].固伤加成=1.1
        self.参战单位[编号].bb伤害加成=1.1
        self.参战单位[编号].bb灵力加成=1.1
      else
        self.参战单位[编号].固伤加成=1.1
        self.参战单位[编号].bb伤害加成=1.1
        self.参战单位[编号].bb灵力加成=1.1
      end
    end
  end
end

function 战斗处理类:加载单个玩家(id,位置)
  系统处理类:进入战斗检测(id)
  self.参战单位[#self.参战单位+1]={}
  self.参战单位[#self.参战单位]=table.loadstring(table.tostring(玩家数据[id].角色:取总数据()))
  if self.参战单位[#self.参战单位].符石技能效果==nil then
    self.参战单位[#self.参战单位].符石技能效果={}
  end
  local 队伍id=玩家数据[id].队伍
  self.参战单位[#self.参战单位].附加阵法="普通"
  if 队伍数据[队伍id]~=nil and #队伍数据[队伍id].成员数据==5 then
    self.参战单位[#self.参战单位].附加阵法=队伍数据[队伍id].阵型
  end
  if 队伍id==0 then
      队伍id=id
  else
      self.参战单位[#self.参战单位].附加阵法=队伍数据[队伍id].阵型
  end
  self.参战玩家[#self.参战玩家].队伍=队伍id
  self.参战单位[#self.参战单位].队伍=队伍id
  self.参战单位[#self.参战单位].位置=位置
  self.参战单位[#self.参战单位].类型="角色"
  self.参战单位[#self.参战单位].玩家id=id
  self.参战单位[#self.参战单位].召唤兽=nil
  self.参战单位[#self.参战单位].法防=self.参战单位[#self.参战单位].法防
  self.参战单位[#self.参战单位].法伤=self.参战单位[#self.参战单位].法伤
  self.参战单位[#self.参战单位].躲闪=0
  self.参战单位[#self.参战单位].已加技能={}
  self.参战单位[#self.参战单位].主动技能={}
  self.参战单位[#self.参战单位].召唤数量={}
  if 玩家数据[id].角色.数据.自动战斗 then
    self.参战单位[#self.参战单位].自动战斗=true
  end
  self:设置队伍区分(队伍id)

   if 玩家数据[id].角色.数据.装备[3]~=nil then
   local 临时武器=table.loadstring(table.tostring(玩家数据[id].道具.数据[玩家数据[id].角色.数据.装备[3]]))
   self.参战单位[#self.参战单位].武器伤害=qz(临时武器.伤害+临时武器.命中*0.35)
   end

--     if self.参战单位[#self.参战单位].类型 == "角色" and  self.参战单位[#self.参战单位].助战编号 == nil then
--      for i,v in pairs(玩家数据[self.参战单位[#self.参战单位].玩家id].角色.数据.装备) do
--      if v ~= nil and 玩家数据[self.参战单位[#self.参战单位].玩家id].道具.数据[v] ~= nil and 玩家数据[self.参战单位[#self.参战单位].玩家id].道具.数据[v].级别限制>=90 and 玩家数据[self.参战单位[#self.参战单位].玩家id].道具.数据[v].制造者=="商城购买" then
--     self.参战单位[#self.参战单位].防御=self.参战单位[#self.参战单位].防御-99999
--     local 账号 = 玩家数据[id].账号
--     local 封禁机器码 = f函数.读配置(程序目录..[[data\]]..账号..[[\账号信息.txt]],"账号配置","机器码")
--     f函数.写配置(程序目录..[[机器码封禁.ini]],"机器码",封禁机器码,"1")
--     __S服务:输出("玩家"..id.." 非法使用外挂警告！！！")
--     写配置("./ip封禁.ini","ip",玩家数据[id].ip,1)
--     写配置("./ip封禁.ini","ip",玩家数据[id].ip.." 非法使用外挂,玩家ID:"..id,1)
--     发送数据(玩家数据[id].连接id,998,"请注意你的角色异常！已经对你进行封IP")
--     __S服务:连接退出(玩家数据[id].连接id)
--      end
--    end
--  end

--    if self.参战单位[#self.参战单位].类型=="角色" and  self.参战单位[#self.参战单位].助战编号 ~= nil then
--   for i,v in pairs(玩家数据[self.参战单位[#self.参战单位].玩家id].助战.数据[self.参战单位[#self.参战单位].助战编号].装备) do
--     if v~=nil and 玩家数据[self.参战单位[#self.参战单位].玩家id].道具.数据[v]~=nil and 玩家数据[self.参战单位[#self.参战单位].玩家id].道具.数据[v].级别限制>= 90 and  玩家数据[self.参战单位[#self.参战单位].玩家id].道具.数据[v].制造者 == "商城购买" then
--     self.参战单位[#self.参战单位].防御=self.参战单位[#self.参战单位].防御-99999
--     local 账号 = 玩家数据[id].账号
--     local 封禁机器码 = f函数.读配置(程序目录..[[data\]]..账号..[[\账号信息.txt]],"账号配置","机器码")
--     f函数.写配置(程序目录..[[机器码封禁.ini]],"机器码",封禁机器码,"1")
--     __S服务:输出("玩家"..id.." 非法使用外挂警告！！！")
--     写配置("./ip封禁.ini","ip",玩家数据[id].ip,1)
--     写配置("./ip封禁.ini","ip",玩家数据[id].ip.." 非法使用外挂,玩家ID:"..id,1)
--     发送数据(玩家数据[id].连接id,998,"请注意你的角色异常！已经对你进行封IP")
--     __S服务:连接退出(玩家数据[id].连接id)
--     end
--   end
-- end


  if 玩家数据[id].角色.数据.奇经八脉.开启奇经八脉~=nil and 玩家数据[id].角色.数据.奇经八脉.开启奇经八脉 then
      self.参战单位[#self.参战单位].经脉有无=玩家数据[id].角色.数据.奇经八脉.开启奇经八脉
  end

  if self.参战单位[#self.参战单位].附加阵法~="普通" then
    if 玩家数据[id].队伍~=nil and self:直接取角色取奇经八脉是否有(玩家数据[id].队伍,"扶阵") then
      self:增加阵法属性(#self.参战单位,self.参战单位[#self.参战单位].附加阵法,位置,0.03)
    else
      self:增加阵法属性(#self.参战单位,self.参战单位[#self.参战单位].附加阵法,位置)
    end
  end
  if self.参战单位[#self.参战单位].参战信息~=nil and 玩家数据[id].召唤兽.数据[玩家数据[id].召唤兽:取编号(玩家数据[id].角色.数据.参战宝宝.认证码)]~=nil then
    --计算召唤兽参战条件
    local 临时bb=玩家数据[id].召唤兽.数据[玩家数据[id].召唤兽:取编号(玩家数据[id].角色.数据.参战宝宝.认证码)]
    if 临时bb~=nil and 临时bb.忠诚<=80 and 取随机数()>=50 then
      常规提示(id,"你的召唤兽由于忠诚过低，不愿意参战")
      return
    end
    if 临时bb~=nil and 临时bb.种类~="神兽" and 临时bb.寿命<=50 then
      常规提示(id,"你的召唤兽由于寿命过低，不愿意参战")
      return
    end
    if 临时bb~=nil and 临时bb.成长>=3.01 then
    常规提示(id,"目前阶段成长>=3的宠物无法参战")
    return
    end
    -- if 玩家数据[id].角色.数据.装备属性.乾元丹>=3 then
    -- 常规提示(id,"#Y你的乾元丹大于3颗,请清空经脉只点2丹!\n(#Z如果不照做你的宠物将无法战斗#)")
    -- return
    -- end

    if 临时bb~=nil and 临时bb.种类~="神兽" and 临时bb.种类~="孩子" then
        玩家数据[id].召唤兽.数据[玩家数据[id].召唤兽:取编号(玩家数据[id].角色.数据.参战宝宝.认证码)].寿命=玩家数据[id].召唤兽.数据[玩家数据[id].召唤兽:取编号(玩家数据[id].角色.数据.参战宝宝.认证码)].寿命-1
    end
    self.参战单位[#self.参战单位+1]={}
    self.参战单位[#self.参战单位]=table.loadstring(玩家数据[id].召唤兽:获取指定数据(玩家数据[id].召唤兽:取编号(玩家数据[id].角色.数据.参战宝宝.认证码)))
    self.参战单位[#self.参战单位].队伍=队伍id
    self.参战单位[#self.参战单位].位置=位置+5
    self.参战单位[#self.参战单位].主人=#self.参战单位-1
    self.参战单位[#self.参战单位].类型="bb"
    self.参战单位[#self.参战单位].玩家id=id
    self.参战单位[#self.参战单位].附加阵法=self.参战单位[#self.参战单位-1].附加阵法
    self.参战单位[#self.参战单位].法防=qz(self.参战单位[#self.参战单位].灵力)
    self.参战单位[#self.参战单位].命中=self.参战单位[#self.参战单位].伤害
    self.参战单位[#self.参战单位].躲闪=0
    self.参战单位[#self.参战单位].法暴=0
    --self.参战单位[#self.参战单位].夜战=0
    self.参战单位[#self.参战单位-1].召唤兽=#self.参战单位
    self.参战单位[#self.参战单位].自动战斗=self.参战单位[#self.参战单位-1].自动战斗
    self.参战单位[#self.参战单位].已加技能={}
    self.参战单位[#self.参战单位].主动技能={}
    self.参战单位[#self.参战单位-1].召唤数量[1]=玩家数据[id].召唤兽:取编号(玩家数据[id].角色.数据.参战宝宝.认证码)

    if self.参战单位[#self.参战单位-1].bb伤害加成~=nil then
      self.参战单位[#self.参战单位].伤害=qz(self.参战单位[#self.参战单位].伤害*self.参战单位[#self.参战单位-1].bb伤害加成)
    end
    if self.参战单位[#self.参战单位-1].bb灵力加成~=nil then
      self.参战单位[#self.参战单位].灵力=qz(self.参战单位[#self.参战单位].灵力*self.参战单位[#self.参战单位-1].bb灵力加成)
    end
    --0419   内丹双倍效果
    --if self.参战单位[#self.参战单位].内丹 ~= nil then
      --  self:添加内丹属性(self.参战单位[#self.参战单位],self.参战单位[#self.参战单位].内丹)
   -- end

    if  self:取奇经八脉是否有(#self.参战单位-1,"御兽") and self.参战单位[#self.参战单位].速度>=self.参战单位[#self.参战单位].等级*3 then
        self.参战单位[#self.参战单位-1].速度=self.参战单位[#self.参战单位-1].速度+qz(self.参战单位[#self.参战单位].等级*1.6)
    end
    if  self:取奇经八脉是否有(#self.参战单位-1,"国色") then
        self.参战单位[#self.参战单位].伤害=self.参战单位[#self.参战单位].伤害*1.2
        self.参战单位[#self.参战单位].灵力=self.参战单位[#self.参战单位].灵力*1.2
        self.参战单位[#self.参战单位].速度=self.参战单位[#self.参战单位].速度*1.2
    end

        if  self:取奇经八脉是否有(#self.参战单位-1,"机巧") then
        self.参战单位[#self.参战单位].防御=self.参战单位[#self.参战单位].防御*1.2
        self.参战单位[#self.参战单位].法防=self.参战单位[#self.参战单位].法防*1.2
    end

    if  self:取奇经八脉是否有(#self.参战单位-1,"龙慑") then
        self.参战单位[#self.参战单位].灵力 =self.参战单位[#self.参战单位].灵力+self.参战单位[#self.参战单位].等级*3.5
        self.参战单位[#self.参战单位].法防 =self.参战单位[#self.参战单位].法防+self.参战单位[#self.参战单位].等级*3.5
    end

    if  self:取奇经八脉是否有(#self.参战单位-1,"悲恸") and 取随机数()<=10 then
        self.参战单位[#self.参战单位].伤害 =self.参战单位[#self.参战单位].伤害*2
    end
    if  self:取奇经八脉是否有(#self.参战单位-1,"羁绊") then
        self.参战单位[#self.参战单位].伤害 =self.参战单位[#self.参战单位].伤害*1.3
    end
    if  self:取奇经八脉是否有(#self.参战单位-1,"生克") then
        self.参战单位[#self.参战单位].灵力 =self.参战单位[#self.参战单位].灵力*1.3
        self.参战单位[#self.参战单位].法防 =self.参战单位[#self.参战单位].法防*1.3
        self.参战单位[#self.参战单位-1].灵力 =self.参战单位[#self.参战单位-1].灵力*1.3
        self.参战单位[#self.参战单位-1].法防 =self.参战单位[#self.参战单位-1].法防*1.3
        self.参战单位[#self.参战单位-1].法伤 =self.参战单位[#self.参战单位-1].法伤*1.3
    end
    if  self:取奇经八脉是否有(#self.参战单位-1,"肝胆") then
        self.参战单位[#self.参战单位].伤害 =self.参战单位[#self.参战单位].伤害+self.参战单位[#self.参战单位-1].伤害*0.05
        self.参战单位[#self.参战单位].防御 =self.参战单位[#self.参战单位].防御+self.参战单位[#self.参战单位-1].防御*0.05
        self.参战单位[#self.参战单位].灵力 =self.参战单位[#self.参战单位].灵力+self.参战单位[#self.参战单位-1].灵力*0.05
        self.参战单位[#self.参战单位].法防 =self.参战单位[#self.参战单位].法防+self.参战单位[#self.参战单位-1].法防*0.05
        self.参战单位[#self.参战单位-1].伤害 =self.参战单位[#self.参战单位-1].伤害+self.参战单位[#self.参战单位].伤害*0.05
        self.参战单位[#self.参战单位-1].防御 =self.参战单位[#self.参战单位-1].防御+self.参战单位[#self.参战单位].防御*0.05
        self.参战单位[#self.参战单位-1].灵力 =self.参战单位[#self.参战单位-1].灵力+self.参战单位[#self.参战单位].灵力*0.05
        self.参战单位[#self.参战单位-1].法防 =self.参战单位[#self.参战单位-1].法防+self.参战单位[#self.参战单位].法防*0.05

    end

	--if self.参战单位[#self.参战单位].气血上限==nil then
	--	self.参战单位[#self.参战单位].气血上限=self.参战单位[#self.参战单位].最大气血
	--end
	--if self.参战单位[#self.参战单位-1].气血上限==nil then
	--	self.参战单位[#self.参战单位-1].气血上限=self.参战单位[#self.参战单位-1].最大气血
	--end
    if self.参战单位[#self.参战单位].气血>self.参战单位[#self.参战单位].最大气血 or self.参战单位[#self.参战单位-1].气血>self.参战单位[#self.参战单位-1].最大气血 then
     self.参战单位[#self.参战单位].气血=self.参战单位[#self.参战单位].最大气血
     self.参战单位[#self.参战单位-1].气血=self.参战单位[#self.参战单位-1].最大气血
    end
    if self.参战单位[#self.参战单位].魔法>self.参战单位[#self.参战单位].最大魔法 or self.参战单位[#self.参战单位-1].魔法>self.参战单位[#self.参战单位-1].最大魔法 then
      self.参战单位[#self.参战单位].魔法=self.参战单位[#self.参战单位].最大魔法
     self.参战单位[#self.参战单位-1].魔法=self.参战单位[#self.参战单位-1].最大魔法
     end

     if self.参战单位[#self.参战单位-1].愤怒>150 then
     self.参战单位[#self.参战单位-1].愤怒=150
     end


    if self.战斗类型==110002 then
    self.参战单位[#self.参战单位-1].附加阵法="云垂阵"
    end
    if self.战斗类型==110002 then
       self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位-1,内容="#G/门派师傅们\n我#Y/已将神力\n全部灌注与你们\n你们上吧"}
     end
    local 临时技能={}
    self:设置队伍区分(队伍id)
  end
  self:添加召唤兽特性(#self.参战单位)
  --if self:取玩家战斗()==false then --助战可以PVP
  if self.战斗类型~=200004 then --比武大会助战没能参战
  if 玩家数据[id].队伍 ~= 0 and 玩家数据[id].队长 then
    local 父编号 = self:取参战编号(id,"角色")
    for i=1,#队伍数据[玩家数据[id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[id].队伍,i) ~= 0 then
        local 助战编号 = 队伍处理类:取助战编号(玩家数据[id].队伍,i)
        if self.参战单位[父编号].助战明细 == nil then
          self.参战单位[父编号].助战明细={}
        end
        self.参战单位[父编号].助战明细[#self.参战单位[父编号].助战明细+1] = #self.参战单位+1
        self.参战单位[#self.参战单位+1]={}
        self.参战单位[#self.参战单位]=table.loadstring(table.tostring(玩家数据[id].助战:取总数据(助战编号)))
        self.参战单位[#self.参战单位].附加阵法="普通"
        if #队伍数据[玩家数据[id].队伍].成员数据==5 then
          self.参战单位[#self.参战单位].附加阵法=队伍数据[玩家数据[id].队伍].阵型
        end
        self.参战单位[#self.参战单位].队伍=队伍id
        self.参战单位[#self.参战单位].位置=i
        self.参战单位[#self.参战单位].类型="角色"
        self.参战单位[#self.参战单位].玩家id=id
        self.参战单位[#self.参战单位].助战编号=助战编号
        self.参战单位[#self.参战单位].召唤兽=nil
        self.参战单位[#self.参战单位].主人 = 父编号
        self.参战单位[#self.参战单位].法防=qz(self.参战单位[#self.参战单位].灵力)
        self.参战单位[#self.参战单位].躲闪=0
        self.参战单位[#self.参战单位].已加技能={}
        self.参战单位[#self.参战单位].主动技能={}
        self.参战单位[#self.参战单位].自动战斗=self.参战单位[父编号].自动战斗
        self:设置队伍区分(队伍id)
        if self.参战单位[#self.参战单位].附加阵法~="普通" then
          if 玩家数据[id].队伍~=nil and self:直接取角色取奇经八脉是否有(玩家数据[id].队伍,"扶阵") then
            self:增加阵法属性(#self.参战单位,self.参战单位[#self.参战单位].附加阵法,i,0.03)
          else
            self:增加阵法属性(#self.参战单位,self.参战单位[#self.参战单位].附加阵法,i)
          end
        end
        if self.参战单位[#self.参战单位].宠物认证码 ~= nil then
          local 编号 = 玩家数据[id].召唤兽:取编号(self.参战单位[#self.参战单位].宠物认证码)
          if 编号 ~= 0 then
            self.参战单位[父编号].助战明细[#self.参战单位[父编号].助战明细+1] = #self.参战单位+1
            self.参战单位[#self.参战单位+1]={}
            self.参战单位[#self.参战单位]=table.loadstring(玩家数据[id].召唤兽:获取指定数据(编号))
            self.参战单位[#self.参战单位].队伍=队伍id
            self.参战单位[#self.参战单位].位置=i+5
            self.参战单位[#self.参战单位].类型="bb"
            self.参战单位[#self.参战单位].玩家id=id
            self.参战单位[#self.参战单位].分类="野怪"
            self.参战单位[#self.参战单位].助战编号=助战编号+5
            self.参战单位[#self.参战单位].主人 = 父编号
            self.参战单位[#self.参战单位].附加阵法=self.参战单位[#self.参战单位-1].附加阵法
            self.参战单位[#self.参战单位].法防=qz(self.参战单位[#self.参战单位].灵力)
            self.参战单位[#self.参战单位].命中=self.参战单位[#self.参战单位].伤害
            self.参战单位[#self.参战单位].躲闪=0
            self.参战单位[#self.参战单位].法暴=0
            --self.参战单位[#self.参战单位].夜战=0
            self.参战单位[#self.参战单位].已加技能={}
            self.参战单位[#self.参战单位].主动技能={}
            self.参战单位[#self.参战单位].自动战斗=self.参战单位[父编号].自动战斗
            self.参战单位[父编号].召唤数量[#self.参战单位[父编号].召唤数量+1]=编号
            if self.参战单位[#self.参战单位-1].bb伤害加成~=nil then
              self.参战单位[#self.参战单位].伤害=qz(self.参战单位[#self.参战单位].伤害*self.参战单位[#self.参战单位-1].bb伤害加成)
            end
            if self.参战单位[#self.参战单位-1].bb灵力加成~=nil then
              self.参战单位[#self.参战单位].灵力=qz(self.参战单位[#self.参战单位].灵力*self.参战单位[#self.参战单位-1].bb灵力加成)
            end
            if self.参战单位[#self.参战单位].内丹 ~= nil then
                self:添加内丹属性(self.参战单位[#self.参战单位],self.参战单位[#self.参战单位].内丹)
            end
           end
            local 临时技能={}
            self:设置队伍区分(队伍id)
          end
        end
      end
    end
 end


      if  self.战斗类型==110013 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="程咬金"
       self.参战单位[#self.参战单位].模型="程咬金"
       self.参战单位[#self.参战单位].等级=70
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=11
       self.参战单位[#self.参战单位].类型="系统角色"
       self.参战单位[#self.参战单位].法防=0
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=2000
       self.参战单位[#self.参战单位].命中=1000
       self.参战单位[#self.参战单位].防御=1000
       self.参战单位[#self.参战单位].速度=1000
       self.参战单位[#self.参战单位].灵力=1000
       self.参战单位[#self.参战单位].躲闪=1000
       self.参战单位[#self.参战单位].气血=100000
       self.参战单位[#self.参战单位].最大气血=100000
       self.参战单位[#self.参战单位].魔法=100000
       self.参战单位[#self.参战单位].最大魔法=100000
       self.参战单位[#self.参战单位].躲闪=1000
       self.参战单位[#self.参战单位].愤怒=9999
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].奇经八脉={风刃=1,杀意=1,干将=1,破军=1,无敌=1}
       self.参战单位[#self.参战单位].主动技能={"横扫千军","破釜沉舟","杀气诀"}
       self.参战单位[#self.参战单位].标记=100080
       self:设置队伍区分(队伍id)
       if self.参战单位[#self.参战单位].名称=="程咬金" then
       self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="#G/这些败类\n我要让你们\n#Y死无葬身之地#4"}
      end
  end

      if  self.战斗类型==110013 then
      local 装备id=玩家数据[id].角色.数据.装备[3]
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="大唐首席弟子"
       self.参战单位[#self.参战单位].模型="剑侠客"
       self.参战单位[#self.参战单位].等级=70
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=12
       self.参战单位[#self.参战单位].类型="系统角色"
       self.参战单位[#self.参战单位].法防=0
       self.参战单位[#self.参战单位].武器={名称="四法青云",子类=3,级别限制=140}
       self.参战单位[#self.参战单位].染色方案=2
       self.参战单位[#self.参战单位].染色组={[1]=1,[2]=3,[3]=3,序号=3710}
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=1000
       self.参战单位[#self.参战单位].命中=1000
       self.参战单位[#self.参战单位].防御=1000
       self.参战单位[#self.参战单位].速度=1000
       self.参战单位[#self.参战单位].灵力=1000
       self.参战单位[#self.参战单位].躲闪=1000
       self.参战单位[#self.参战单位].气血=100000
       self.参战单位[#self.参战单位].最大气血=100000
       self.参战单位[#self.参战单位].魔法=100000
       self.参战单位[#self.参战单位].最大魔法=100000
       self.参战单位[#self.参战单位].躲闪=1000
       self.参战单位[#self.参战单位].愤怒=9999
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].奇经八脉={风刃=1,杀意=1,干将=1,破军=1,无敌=1}
       self.参战单位[#self.参战单位].主动技能={"横扫千军","后发制人"}
       self.参战单位[#self.参战单位].标记=100080
       self:设置队伍区分(队伍id)
  end


  if self.战斗类型==100017 then
    self.参战单位[#self.参战单位+1]={}
    self.参战单位[#self.参战单位].名称="苦战中的同门"
    self.参战单位[#self.参战单位].模型=任务数据[self.任务id].模型
    self.参战单位[#self.参战单位].等级=100
    self.参战单位[#self.参战单位].变异=false
    self.参战单位[#self.参战单位].队伍=队伍id
    self.参战单位[#self.参战单位].位置=3
    self.参战单位[#self.参战单位].类型="系统角色"
    self.参战单位[#self.参战单位].法防=0
    self.参战单位[#self.参战单位].武器=nil
    self.参战单位[#self.参战单位].玩家id=0
    self.参战单位[#self.参战单位].分类="野怪"
    self.参战单位[#self.参战单位].附加阵法="普通"
    self.参战单位[#self.参战单位].伤害=1
    self.参战单位[#self.参战单位].命中=1
    self.参战单位[#self.参战单位].防御=1
    self.参战单位[#self.参战单位].速度=1
    self.参战单位[#self.参战单位].灵力=1
    self.参战单位[#self.参战单位].躲闪=1
    self.参战单位[#self.参战单位].气血=1500
    self.参战单位[#self.参战单位].最大气血=1500
    self.参战单位[#self.参战单位].魔法=1
    self.参战单位[#self.参战单位].最大魔法=1
    self.参战单位[#self.参战单位].躲闪=1
    self.参战单位[#self.参战单位].技能={}
    self.参战单位[#self.参战单位].同门单位=true
    self.参战单位[#self.参战单位].系统队友=true
    self.参战单位[#self.参战单位].主动技能={}
    self:设置队伍区分(队伍id)
  end

    if  self.战斗类型==110005 then
       for n=13,14 do
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="海难者亡魂"
       self.参战单位[#self.参战单位].模型="僵尸"
       self.参战单位[#self.参战单位].等级=10
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=n
       self.参战单位[#self.参战单位].类型="系统角色"
       self.参战单位[#self.参战单位].法防=0
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=100
       self.参战单位[#self.参战单位].命中=100
       self.参战单位[#self.参战单位].防御=100
       self.参战单位[#self.参战单位].速度=100
       self.参战单位[#self.参战单位].灵力=100
       self.参战单位[#self.参战单位].躲闪=100
       self.参战单位[#self.参战单位].气血=1000
       self.参战单位[#self.参战单位].最大气血=1000
       self.参战单位[#self.参战单位].魔法=1000
       self.参战单位[#self.参战单位].最大魔法=1000
       self.参战单位[#self.参战单位].躲闪=100
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"善恶有报","弱点击破"}
       self.参战单位[#self.参战单位].标记=100080
       self:设置队伍区分(队伍id)
     end
  end

      if  self.战斗类型==110005 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="雷黑子鬼魂"
       self.参战单位[#self.参战单位].模型="小毛头"
       self.参战单位[#self.参战单位].等级=10
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=11
       self.参战单位[#self.参战单位].类型="系统角色"
       self.参战单位[#self.参战单位].法防=0
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=200
       self.参战单位[#self.参战单位].命中=100
       self.参战单位[#self.参战单位].防御=100
       self.参战单位[#self.参战单位].速度=100
       self.参战单位[#self.参战单位].灵力=100
       self.参战单位[#self.参战单位].躲闪=100
       self.参战单位[#self.参战单位].气血=1000
       self.参战单位[#self.参战单位].最大气血=1000
       self.参战单位[#self.参战单位].魔法=1000
       self.参战单位[#self.参战单位].最大魔法=1000
       self.参战单位[#self.参战单位].躲闪=100
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"后发制人","横扫千军"}
       self.参战单位[#self.参战单位].标记=100080
       self:设置队伍区分(队伍id)
       if self.参战单位[#self.参战单位].名称=="雷黑子鬼魂" then
       self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="#G/妖风\n复仇的时候\n到了"}
      end
  end


        if  self.战斗类型==110005 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="商人的鬼魂"
       self.参战单位[#self.参战单位].模型="野鬼"
       self.参战单位[#self.参战单位].等级=10
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=12
       self.参战单位[#self.参战单位].类型="系统角色"
       self.参战单位[#self.参战单位].法防=0
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=100
       self.参战单位[#self.参战单位].命中=100
       self.参战单位[#self.参战单位].防御=100
       self.参战单位[#self.参战单位].速度=100
       self.参战单位[#self.参战单位].灵力=100
       self.参战单位[#self.参战单位].躲闪=100
       self.参战单位[#self.参战单位].气血=1000
       self.参战单位[#self.参战单位].最大气血=1000
       self.参战单位[#self.参战单位].魔法=1000
       self.参战单位[#self.参战单位].最大魔法=1000
       self.参战单位[#self.参战单位].躲闪=100
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"尸腐毒","判官令"}
       self.参战单位[#self.参战单位].标记=100080
       self:设置队伍区分(队伍id)
       if self.参战单位[#self.参战单位].名称=="商人的鬼魂" then
       self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="#G/少侠不用怕\n我们来助你\n干掉他吧#91"}
      end
  end

       if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="二郎神"
       self.参战单位[#self.参战单位].模型="二郎神"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=2
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=10000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1
       self.参战单位[#self.参战单位].速度=10000
       self.参战单位[#self.参战单位].灵力=11000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"破釜沉舟","横扫千军"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
     --   if self.参战单位[#self.参战单位].名称=="二郎神" then
     --   self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="#G/天命之子\n你#Y/躺好尸\n交给我吧#91"}
     -- end
   end
       if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="镇元大仙"
       self.参战单位[#self.参战单位].模型="镇元大仙"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=3
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=10000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1
       self.参战单位[#self.参战单位].速度=10000
       self.参战单位[#self.参战单位].灵力=11000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"烟雨剑法","飘渺式"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
   end
       if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="地涌夫人"
       self.参战单位[#self.参战单位].模型="地涌夫人"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=4
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=10000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1000
       self.参战单位[#self.参战单位].速度=20000
       self.参战单位[#self.参战单位].灵力=1000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].愤怒=9999
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"其徐如林","其疾如风","不动如山 ","侵掠如火","夺命咒"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
   end
   if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="巫奎虎"
       self.参战单位[#self.参战单位].模型="巫奎虎"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=5
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=10000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1
       self.参战单位[#self.参战单位].速度=10000
       self.参战单位[#self.参战单位].灵力=11000
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"落叶萧萧","破血狂攻"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].法连=99
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
   end
      if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="东海龙王"
       self.参战单位[#self.参战单位].模型="东海龙王"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=7
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=1000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1
       self.参战单位[#self.参战单位].速度=10000
       self.参战单位[#self.参战单位].灵力=11000
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"龙卷雨击","龙腾"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].法连=99
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
   end

      if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="空度禅师"
       self.参战单位[#self.参战单位].模型="空度禅师"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=8
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=1000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1
       self.参战单位[#self.参战单位].速度=10000
       self.参战单位[#self.参战单位].灵力=11000
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"唧唧歪歪","推气过宫"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].法连=99
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
   end


      if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="牛魔王"
       self.参战单位[#self.参战单位].模型="牛魔王"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=9
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=10000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1
       self.参战单位[#self.参战单位].速度=10000
       self.参战单位[#self.参战单位].灵力=11000
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"飞砂走石","剑荡四方"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].法连=99
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
   end

      if self.战斗类型==110002 then
       self.参战单位[#self.参战单位+1]={}
       self.参战单位[#self.参战单位].名称="大大王"
       self.参战单位[#self.参战单位].模型="大大王"
       self.参战单位[#self.参战单位].等级=175
       self.参战单位[#self.参战单位].变异=false
       self.参战单位[#self.参战单位].队伍=队伍id
       self.参战单位[#self.参战单位].位置=10
       self.参战单位[#self.参战单位].类型="召唤"
       self.参战单位[#self.参战单位].法防=5000
       self.参战单位[#self.参战单位].武器=nil
       self.参战单位[#self.参战单位].玩家id=0
       self.参战单位[#self.参战单位].分类="野怪"
       self.参战单位[#self.参战单位].附加阵法="普通"
       self.参战单位[#self.参战单位].伤害=10000
       self.参战单位[#self.参战单位].命中=10000
       self.参战单位[#self.参战单位].防御=1
       self.参战单位[#self.参战单位].速度=10000
       self.参战单位[#self.参战单位].灵力=11000
       self.参战单位[#self.参战单位].愤怒=999
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].气血=150000
       self.参战单位[#self.参战单位].最大气血=150000
       self.参战单位[#self.参战单位].魔法=10000
       self.参战单位[#self.参战单位].最大魔法=10000
       self.参战单位[#self.参战单位].躲闪=10000
       self.参战单位[#self.参战单位].技能={}
       self.参战单位[#self.参战单位].不可封印=true
       self.参战单位[#self.参战单位].同门单位=true
       self.参战单位[#self.参战单位].系统队友=true
       self.参战单位[#self.参战单位].主动技能={"鹰击","连环击"}
       self.参战单位[#self.参战单位].标记=100080
       self.参战单位[#self.参战单位].法连=99
       self.参战单位[#self.参战单位].鬼魂=3
       self:设置队伍区分(队伍id)
   end
end
function 战斗处理类:添加召唤兽特性(编号)
  if self.参战单位[编号].特性~=nil then
    local 特性=self.参战单位[编号].特性
    local 几率=self.参战单位[编号].特性几率
    if 特性=="预知" then --OOOOOOOK
      self.参战单位[编号].预知特性=几率
      self.参战单位[编号].预知次数=0
      self.参战单位[编号].伤害=qz(self.参战单位[编号].伤害*0.95)
      self.参战单位[编号].防御=qz(self.参战单位[编号].防御*0.95)
      self.参战单位[编号].灵力=qz(self.参战单位[编号].灵力*0.95)
      self.参战单位[编号].速度=qz(self.参战单位[编号].速度*0.95)
      self.参战单位[编号].法防=qz(self.参战单位[编号].法防*0.95)
    elseif 特性=="灵动" then --OOOOOOOK
      self.参战单位[编号].灵动特性=几率
      self.参战单位[编号].灵动次数=0
      self.参战单位[编号].伤害=qz(self.参战单位[编号].伤害*0.95)
      self.参战单位[编号].防御=qz(self.参战单位[编号].防御*0.95)
      self.参战单位[编号].灵力=qz(self.参战单位[编号].灵力*0.95)
      self.参战单位[编号].速度=qz(self.参战单位[编号].速度*0.95)
      self.参战单位[编号].法防=qz(self.参战单位[编号].法防*0.95)
    elseif 特性=="识物" then
      self.参战单位[编号].识物特性=几率
      self.参战单位[编号].伤害=qz(self.参战单位[编号].伤害*0.95)
      self.参战单位[编号].防御=qz(self.参战单位[编号].防御*0.95)
      self.参战单位[编号].灵力=qz(self.参战单位[编号].灵力*0.95)
      self.参战单位[编号].速度=qz(self.参战单位[编号].速度*0.95)
      self.参战单位[编号].法防=qz(self.参战单位[编号].法防*0.95)
    elseif 特性=="抗法" then --OOOOOOOK
      self.参战单位[编号].抗法特性=几率
    elseif 特性=="抗物" then --OOOOOOOK
      self.参战单位[编号].抗物特性=几率
    elseif 特性=="洞察" then --OOOOOOOK
      self.参战单位[编号].洞察特性=几率
      self.参战单位[编号].伤害=qz(self.参战单位[编号].伤害*0.95)
      self.参战单位[编号].防御=qz(self.参战单位[编号].防御*0.95)
      self.参战单位[编号].灵力=qz(self.参战单位[编号].灵力*0.95)
      self.参战单位[编号].速度=qz(self.参战单位[编号].速度*0.95)
      self.参战单位[编号].法防=qz(self.参战单位[编号].法防*0.95)
    elseif 特性=="弑神" then --OOOOOOOK
      self.参战单位[编号].弑神特性=几率
    elseif 特性=="顺势" then --OOOOOOOK
      self.参战单位[编号].顺势特性=几率
    elseif 特性=="复仇" then --OOOOOOOK
      self.参战单位[编号].复仇特性=几率
      self.参战单位[编号].复仇次数=0
    elseif 特性=="自恋" then --OOOOOOOK
      self.参战单位[编号].自恋特性=几率
    elseif 特性=="暗劲" then
      self.参战单位[编号].暗劲特性=几率
    elseif 特性=="识药" then --OOOOOOOK
      self.参战单位[编号].识药特性=几率
    elseif 特性=="吮魔" then
      self.参战单位[编号].吮魔特性=几率
    elseif 特性=="争锋" then --OOOOOOOK
      self.参战单位[编号].争锋特性=几率
    elseif 特性=="力破" then --OOOOOOOK
      self.参战单位[编号].力破特性=几率
    elseif 特性=="巧劲" then
      self.参战单位[编号].巧劲特性=几率
    end
  end
end

function 战斗处理类:添加状态特性(编号)
  local 特性=self.参战单位[编号].特性
  local 几率=self.参战单位[编号].特性几率
  if 特性=="御风" then --OOOOOOOK
    self:添加状态(特性,self.参战单位[self.参战单位[编号].主人],self.参战单位[编号],0,编号)
  elseif 特性=="灵刃" then
    local 触发=0
    if 几率==1 then
      触发=33
    elseif 几率==2 then
      触发=50
    elseif 几率==3 then
      触发=66
    elseif 几率==4 then
      触发=83
    elseif 几率==5 then
      触发=100
    end
    if 触发>=取随机数(1,100) then
      local 气血=qz(self.参战单位[编号].气血*0.3)
      self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=编号,气血=0,挨打方={},击退=1}
      self.战斗流程[#self.战斗流程].死亡=self:减少气血(编号,气血)
      self.战斗流程[#self.战斗流程].气血=气血
      self:添加状态("灵刃",self.参战单位[编号],self.参战单位[编号],0,编号)
    end
  elseif 特性=="灵法" then
    self:添加状态("灵法",self.参战单位[编号],self.参战单位[编号],几率,编号)
    self:添加状态("灵法1",self.参战单位[编号],self.参战单位[编号],几率,编号)
  elseif 特性=="阳护" then
    local 触发=0
    if 几率==1 then
      触发=33
    elseif 几率==2 then
      触发=50
    elseif 几率==3 then
      触发=66
    elseif 几率==4 then
      触发=83
    elseif 几率==5 then
      触发=100
    end
    if 触发>=取随机数() then
      for i=1,#self.参战单位 do
        if i ~= 编号 and  self.参战单位[i]~= nil and self.参战单位[i].队伍 == self.参战单位[编号].队伍 and self.参战单位[编号].法术状态.死亡召唤 then
          self.参战单位[编号].法术状态.死亡召唤.回合 = self.参战单位[编号].法术状态.死亡召唤.回合 - 2
          if self.参战单位[编号].法术状态.死亡召唤.回合 <= 0 then
            self.参战单位[编号].法术状态.死亡召唤.回合 = 1
          end
        end
      end
    end
  elseif 特性=="护佑" then
    if 取随机数(1,10) <几率 then
      self:添加状态(特性,self.参战单位[self:取我方气血最低(编号)],self.参战单位[编号],几率,编号)
    end
  elseif 特性=="怒吼" then
    if 取随机数(1,10) <几率 then
      self.参战单位[编号].防御=qz(self.参战单位[编号].防御*0.9)
      self:添加状态(特性,self.参战单位[self:取我方伤害最高(编号)],self.参战单位[编号],0,编号)
      self:添加状态("怒吼1",self.参战单位[self:取我方伤害最高(编号)],self.参战单位[编号],0,编号)
    end
  elseif 特性=="灵断" then
    local 触发=0
    if 几率==1 then
      触发=33
    elseif 几率==2 then
      触发=50
    elseif 几率==3 then
      触发=66
    elseif 几率==4 then
      触发=83
    elseif 几率==5 then
      触发=100
    end
    if 触发>=取随机数() then
      local 气血=qz(self.参战单位[编号].气血*0.3)
      self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=编号,气血=0,挨打方={},击退=1}
      self.战斗流程[#self.战斗流程].死亡=self:减少气血(编号,气血)
      self.战斗流程[#self.战斗流程].气血=气血
      self:添加状态("灵断",self.参战单位[编号],self.参战单位[编号],0,编号)
    end
  elseif 特性=="瞬击" then
    local 触发=0
    local 防御=10
    if 几率==1 then
      触发=33
    elseif 几率==2 then
      触发=50
    elseif 几率==3 then
      触发=66
      防御=5
    elseif 几率==4 then
      触发=83
      防御=5
    elseif 几率==5 then
      触发=100
      防御=5
    end
    if 触发>=取随机数() then
      self.参战单位[编号].防御=qz(self.参战单位[编号].防御*(1-防御/100))
      self.参战单位[编号].指令.目标=self:取单个敌方目标(编号)
      self:普通攻击计算(编号,1)
    end
  elseif 特性=="瞬法" then
    local 防御=10
    if 几率==1 then
      触发=33
    elseif 几率==2 then
      触发=50
    elseif 几率==3 then
      触发=66
      防御=5
    elseif 几率==4 then
      触发=83
      防御=5
    elseif 几率==5 then
      触发=100
      防御=5
    end
    local 名称=self:取召唤兽可用法术(编号)
    if 触发>=取随机数(1,100) and 名称~=nil then
      self.参战单位[编号].最大气血=qz(self.参战单位[编号].最大气血*(1-防御/100))
      if self.参战单位[编号].气血>self.参战单位[编号].最大气血 then
        self.参战单位[编号].气血=self.参战单位[编号].最大气血
      end
      self.参战单位[编号].指令.目标=self:取单个敌方目标(编号)
      self:法攻技能计算(编号,名称,self:取技能等级(编号,名称),1)
    end
  end

end
function 战斗处理类:取我方伤害最高(编号)
  local 目标组={}
  local 伤害={id=0,伤害=0}
  for n=1,#self.参战单位 do
    if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
      if self.参战单位[n].伤害>伤害.伤害 then
        伤害.伤害=self.参战单位[n].伤害
        伤害.id=n
      end
    end
  end
  if 伤害.id==0 then
     return 编号
  else
    return 伤害.id
  end
end
function 战斗处理类:取召唤兽可用法术(编号)
  local 法术名称={"水攻","烈火","雷击","落岩","奔雷咒","水漫金山","地狱烈火","泰山压顶","上古灵符","八凶法阵","月光","流沙轻音","食指大动","天降灵葫","叱咤风云"}
  local 技能组={}
  for n=1,#self.参战单位[编号].主动技能 do
    for i=1,#法术名称 do
      if 法术名称[i]==self.参战单位[编号].主动技能[n].名称 then
        技能组[#技能组+1]=法术名称[i]
      end
    end
  end
  if #技能组==0 then
    return
  else
    return 技能组[取随机数(1,#技能组)]
  end
end
function 战斗处理类:取我方气血最低(编号)

  local 目标组={}
  local 伤害={id=0,伤害=999999}
  for n=1,#self.参战单位 do
    if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
      if self.参战单位[n].气血<伤害.伤害 then
        伤害.伤害=self.参战单位[n].气血
        伤害.id=n
      end
    end
  end
  if 伤害.id==0 then
    return 编号
  else
    return 伤害.id
  end

end
function 战斗处理类:取难度系数(任务id)
  local 难度系数 = {}
  if self.战斗类型 == 100008 then --抓鬼难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","抓鬼难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","抓鬼难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","抓鬼难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","抓鬼难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","抓鬼难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","抓鬼难度法防")
  elseif self.战斗类型 == 100009 then --星宿难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","星宿难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","星宿难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","星宿难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","星宿难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","星宿难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","星宿难度法防")
  elseif self.战斗类型 == 100010 then --妖魔鬼怪难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔鬼怪难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔鬼怪难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔鬼怪难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔鬼怪难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔鬼怪难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔鬼怪难度法防")
  elseif self.战斗类型 == 100011 then --门派闯关难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","门派闯关难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","门派闯关难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","门派闯关难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","门派闯关难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","门派闯关难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","门派闯关难度法防")
  elseif self.战斗类型 == 100012 then --游泳难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","游泳难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","游泳难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","游泳难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","游泳难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","游泳难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","游泳难度法防")
  elseif self.战斗类型 == 100013 or self.战斗类型 == 100014 then --官职难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","官职难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","官职难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","官职难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","官职难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","官职难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","官职难度法防")
  elseif self.战斗类型 == 100015 or self.战斗类型 == 100016 or self.战斗类型 == 100017 or self.战斗类型 == 100018 then --师门难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","师门任务难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","师门任务难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","师门任务难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","师门任务难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","师门任务难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","师门任务难度法防")
  elseif self.战斗类型 == 100019 then --迷宫小怪难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","迷宫小怪难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","迷宫小怪难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","迷宫小怪难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","迷宫小怪难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","迷宫小怪难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","迷宫小怪难度法防")
  elseif self.战斗类型 == 100020 then --妖王难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖王难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖王难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖王难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖王难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖王难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖王难度法防")
  elseif self.战斗类型 == 100021 then --江湖大盗
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","江湖大盗难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","江湖大盗难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","江湖大盗难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","江湖大盗难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","江湖大盗难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","江湖大盗难度法防")
  elseif self.战斗类型 == 100022 then --皇宫飞贼难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫飞贼难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫飞贼难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫飞贼难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫飞贼难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫飞贼难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫飞贼难度法防")
  elseif self.战斗类型 == 100023 then --皇宫贼王难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫贼王难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫贼王难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫贼王难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫贼王难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫贼王难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","皇宫贼王难度法防")
  elseif self.战斗类型 == 100024 then --世界BOOS难度
    if 任务数据[任务id].等级==60 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","60BOOS难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","60BOOS难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","60BOOS难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","60BOOS难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","60BOOS难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","60BOOS难度法防")
    elseif 任务数据[任务id].等级==100 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","100BOOS难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","100BOOS难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","100BOOS难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","100BOOS难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","100BOOS难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","100BOOS难度法防")
    else
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","150BOOS难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","150BOOS难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","150BOOS难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","150BOOS难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","150BOOS难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","150BOOS难度法防")
    end
  elseif self.战斗类型 == 100025 then --镖王难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","镖王难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","镖王难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","镖王难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","镖王难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","镖王难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","镖王难度法防")
  elseif self.战斗类型 == 100026 then --三界悬赏令难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","三界悬赏令难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","三界悬赏令难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","三界悬赏令难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","三界悬赏令难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","三界悬赏令难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","三界悬赏令难度法防")
  elseif self.战斗类型 == 100027 then --知了王难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了王难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了王难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了王难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了王难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了王难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了王难度法防")
  elseif self.战斗类型 == 100028 then --副本芭蕉难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本芭蕉难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本芭蕉难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本芭蕉难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本芭蕉难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本芭蕉难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本芭蕉难度法防")
  elseif self.战斗类型 == 100029 then --副本三妖难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本三妖难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本三妖难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本三妖难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本三妖难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本三妖难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本三妖难度法防")
  elseif self.战斗类型 == 100030 then --鬼祟小怪难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","鬼祟小怪难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","鬼祟小怪难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","鬼祟小怪难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","鬼祟小怪难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","鬼祟小怪难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","鬼祟小怪难度法防")
  elseif self.战斗类型 == 100031 then --副本国王难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本国王难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本国王难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本国王难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本国王难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本国王难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","副本国王难度法防")
  elseif self.战斗类型 == 100032 then --天庭叛逆难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天庭叛逆难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天庭叛逆难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天庭叛逆难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天庭叛逆难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天庭叛逆难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天庭叛逆难度法防")
  elseif self.战斗类型 == 100033 then --捣乱的水果难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","捣乱的水果难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","捣乱的水果难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","捣乱的水果难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","捣乱的水果难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","捣乱的水果难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","捣乱的水果难度法防")
  elseif self.战斗类型 == 100034 then --青龙巡逻难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","青龙巡逻难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","青龙巡逻难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","青龙巡逻难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","青龙巡逻难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","青龙巡逻难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","青龙巡逻难度法防")
  elseif self.战斗类型 == 100035 then --玄武巡逻难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","玄武巡逻难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","玄武巡逻难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","玄武巡逻难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","玄武巡逻难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","玄武巡逻难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","玄武巡逻难度法防")
  elseif self.战斗类型 == 100037 then --地煞难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","地煞难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","地煞难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","地煞难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","地煞难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","地煞难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","地煞难度法防")
  elseif self.战斗类型 == 100039 then --知了小王难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了小王难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了小王难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了小王难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了小王难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了小王难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","知了小王难度法防")
  elseif self.战斗类型 == 100040 then --大力神灵难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","大力神灵难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","大力神灵难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","大力神灵难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","大力神灵难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","大力神灵难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","大力神灵难度法防")
  elseif self.战斗类型 == 100041 then --妖魔亲信难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔亲信难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔亲信难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔亲信难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔亲信难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔亲信难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妖魔亲信难度法防")
  elseif self.战斗类型 == 100042 then --蜃妖元神难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蜃妖元神难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蜃妖元神难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蜃妖元神难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蜃妖元神难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蜃妖元神难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蜃妖元神难度法防")
  elseif self.战斗类型 == 100043 then --周猎户难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","周猎户难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","周猎户难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","周猎户难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","周猎户难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","周猎户难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","周猎户难度法防")
  elseif self.战斗类型 == 100044 then --法宝战斗难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝战斗难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝战斗难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝战斗难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝战斗难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝战斗难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝战斗难度法防")
  elseif self.战斗类型 == 100045 then --法宝内丹难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝内丹难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝内丹难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝内丹难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝内丹难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝内丹难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","法宝内丹难度法防")
  elseif self.战斗类型 == 100046 then --霸道的土匪难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","霸道的土匪难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","霸道的土匪难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","霸道的土匪难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","霸道的土匪难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","霸道的土匪难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","霸道的土匪难度法防")
  elseif self.战斗类型 == 100047 then --飞升心魔难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升心魔难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升心魔难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升心魔难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升心魔难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升心魔难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升心魔难度法防")
  elseif self.战斗类型 == 100048 then --飞升小妖难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小妖难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小妖难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小妖难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小妖难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小妖难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小妖难度法防")
  elseif self.战斗类型 == 100049 then --飞升小宝箱难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小宝箱难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小宝箱难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小宝箱难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小宝箱难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小宝箱难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升小宝箱难度法防")
  elseif self.战斗类型 == 100050 then --飞升阵法1难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法1难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法1难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法1难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法1难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法1难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法1难度法防")
  elseif self.战斗类型 == 100051 then --飞升阵法2难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法2难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法2难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法2难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法2难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法2难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法2难度法防")
  elseif self.战斗类型 == 100052 then --飞升阵法3难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法3难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法3难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法3难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法3难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法3难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法3难度法防")
  elseif self.战斗类型 == 100053 then --飞升阵法4难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法4难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法4难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法4难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法4难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法4难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法4难度法防")
  elseif self.战斗类型 == 100054 then --飞升阵法5难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法5难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法5难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法5难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法5难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法5难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","飞升阵法5难度法防")
  elseif self.战斗类型 == 100055 then --生死劫难度
    if 生死劫数据[self.进入战斗玩家id] == 1 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫1难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫1难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫1难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫1难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫1难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫1难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 2 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫2难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫2难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫2难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫2难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫2难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫3难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 3 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫3难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫3难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫3难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫3难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫3难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫3难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 4 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫4难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫4难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫4难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫4难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫4难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫4难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 5 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫5难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫5难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫5难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫5难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫5难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫5难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 6 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫6难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫6难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫6难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫6难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫6难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫6难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 7 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫7难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫7难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫7难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫7难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫7难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫7难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 8 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫8难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫8难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫8难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫8难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫8难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫8难度法防")
    elseif 生死劫数据[self.进入战斗玩家id] == 9 then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫9难度气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫9难度伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫9难度防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫9难度灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫9难度速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","生死劫9难度法防")
    end
  elseif self.战斗类型 == 100056 then --天罡星信息难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天罡星难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天罡星难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天罡星难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天罡星难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天罡星难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","天罡星难度法防")
  elseif self.战斗类型 == 100060 then --福利BOOS难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利BOOS难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利BOOS难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利BOOS难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利BOOS难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利BOOS难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利BOOS难度法防")
  elseif self.战斗类型 == 100066 then --车迟贡品难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟贡品难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟贡品难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟贡品难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟贡品难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟贡品难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟贡品难度法防")
  elseif self.战斗类型 == 100067 then --车迟三清难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟三清难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟三清难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟三清难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟三清难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟三清难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟三清难度法防")
  elseif self.战斗类型 == 100068 then --车迟求雨难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟求雨难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟求雨难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟求雨难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟求雨难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟求雨难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟求雨难度法防")
  elseif self.战斗类型 == 100069 then --车迟不动难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟不动难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟不动难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟不动难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟不动难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟不动难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","车迟不动难度法防")
  elseif self.战斗类型 == 100084 then --散财童子难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","散财童子难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","散财童子难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","散财童子难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","散财童子难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","散财童子难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","散财童子难度法防")
  elseif self.战斗类型 == 100085 then --神秘妖怪难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","神秘妖怪难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","神秘妖怪难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","神秘妖怪难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","神秘妖怪难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","神秘妖怪难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","神秘妖怪难度法防")
  elseif self.战斗类型 == 100086 then --妄空曰天冷难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷难度法防")
  elseif self.战斗类型 == 100087 or self.战斗类型 == 100089 then --妄空曰天冷2难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷2难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷2难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷2难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷2难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷2难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","妄空曰天冷2难度法防")
  elseif self.战斗类型 == 100088 then --渡劫师傅难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","渡劫师傅难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","渡劫师傅难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","渡劫师傅难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","渡劫师傅难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","渡劫师傅难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","渡劫师傅难度法防")
  elseif self.战斗类型 == 100090 then --蚩尤幻影难度
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蚩尤幻影难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蚩尤幻影难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蚩尤幻影难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蚩尤幻影难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蚩尤幻影难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","蚩尤幻影难度法防")
  elseif self.战斗类型 == 100097 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","马超难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","马超难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","马超难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","马超难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","马超难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","马超难度法防")
  elseif self.战斗类型 == 100098 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","黄忠难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","黄忠难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","黄忠难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","黄忠难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","黄忠难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","黄忠难度法防")
  elseif self.战斗类型 == 100099 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","张飞难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","张飞难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","张飞难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","张飞难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","张飞难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","张飞难度法防")
  elseif self.战斗类型 == 100100 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","关羽难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","关羽难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","关羽难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","关羽难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","关羽难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","关羽难度法防")
  elseif self.战斗类型 == 100101 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","赵云难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","赵云难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","赵云难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","赵云难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","赵云难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","赵云难度法防")
  elseif self.战斗类型 == 100105 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利宝箱怪气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利宝箱怪伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利宝箱怪防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利宝箱怪灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利宝箱怪速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","福利宝箱怪法防")
  elseif self.战斗类型 == 100106 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","倾国倾城气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","倾国倾城伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","倾国倾城防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","倾国倾城灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","倾国倾城速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","倾国倾城法防")
  elseif self.战斗类型 == 100107 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","美食专家气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","美食专家伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","美食专家防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","美食专家灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","美食专家速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","美食专家法防")
  elseif self.战斗类型 == 100108 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","通天塔气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","通天塔伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","通天塔防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","通天塔灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","通天塔速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","通天塔法防")
  elseif self.战斗类型 == 100109 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","贼王的线索气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","贼王的线索伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","贼王的线索防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","贼王的线索灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","贼王的线索速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","贼王的线索法防")
  elseif self.战斗类型 == 100110 then
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","貔貅气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","貔貅伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","貔貅防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","貔貅灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","貔貅速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","貔貅法防")
  elseif self.战斗类型 == 100112 then --水陆桃木虫
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆桃木虫气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆桃木虫伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆桃木虫防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆桃木虫灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆桃木虫速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆桃木虫法防")
  elseif self.战斗类型 == 100113 then --水陆泼猴
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆泼猴气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆泼猴伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆泼猴防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆泼猴灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆泼猴速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆泼猴法防")
  elseif self.战斗类型 == 100116 then --水陆翼虎
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆翼虎气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆翼虎伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆翼虎防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆翼虎灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆翼虎速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆翼虎法防")
  elseif self.战斗类型 == 100117 then --水陆蝰蛇
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆蝰蛇气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆蝰蛇伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆蝰蛇防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆蝰蛇灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆蝰蛇速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆蝰蛇法防")
  elseif self.战斗类型 == 100118 then --水陆三怪
    if 任务数据[任务id].名称=="巡山小妖" then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆巡山小妖气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆巡山小妖伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆巡山小妖防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆巡山小妖灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆巡山小妖速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆巡山小妖法防")
    elseif 任务数据[任务id].名称=="上古妖兽头领" then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆上古妖兽头领气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆上古妖兽头领伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆上古妖兽头领防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆上古妖兽头领灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆上古妖兽头领速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆上古妖兽头领法防")
    elseif 任务数据[任务id].名称=="妖将军" then
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆妖将军气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆妖将军伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆妖将军防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆妖将军灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆妖将军速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆妖将军法防")
    else
      难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆魑魅魍魉气血")
      难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆魑魅魍魉伤害")
      难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆魑魅魍魉防御")
      难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆魑魅魍魉灵力")
      难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆魑魅魍魉速度")
      难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆魑魅魍魉法防")
    end
  elseif self.战斗类型 == 100119 then --水陆毒虫
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆毒虫气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆毒虫伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆毒虫防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆毒虫灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆毒虫速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","水陆毒虫法防")
  elseif self.战斗类型 == 100122 then --捣乱的年兽
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","捣乱的年兽气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","捣乱的年兽伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","捣乱的年兽防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","捣乱的年兽灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","捣乱的年兽速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","捣乱的年兽法防")
  elseif self.战斗类型 == 100123 then --年兽王
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","年兽王气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","年兽王伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","年兽王防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","年兽王灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","年兽王速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","年兽王法防")
  elseif self.战斗类型 == 100124 then --邪恶年兽
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","定制任务","邪恶年兽气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","定制任务","邪恶年兽伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","定制任务","邪恶年兽防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","定制任务","邪恶年兽灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","定制任务","邪恶年兽速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","定制任务","邪恶年兽法防")

  elseif self.战斗类型 == 199406 then --跨服征战神州
    难度系数[1] = f函数.读配置(程序目录.."定制难度.ini","常规任务","征战神州难度气血")
    难度系数[2] = f函数.读配置(程序目录.."定制难度.ini","常规任务","征战神州难度伤害")
    难度系数[3] = f函数.读配置(程序目录.."定制难度.ini","常规任务","征战神州难度防御")
    难度系数[4] = f函数.读配置(程序目录.."定制难度.ini","常规任务","征战神州难度灵力")
    难度系数[5] = f函数.读配置(程序目录.."定制难度.ini","常规任务","征战神州难度速度")
    难度系数[6] = f函数.读配置(程序目录.."定制难度.ini","常规任务","征战神州难度法防")




  end
  if 难度系数[1] == nil or 难度系数[1] == "空" or  tonumber(难度系数[1]) == nil or 难度系数[1] == "" then
    难度系数[1] = 1
  end
  if 难度系数[2] == nil or 难度系数[1] == "空" or  tonumber(难度系数[2]) == nil or 难度系数[1] == "" then
    难度系数[2] = 1
  end
  if 难度系数[3] == nil or 难度系数[1] == "空" or  tonumber(难度系数[3]) == nil or 难度系数[1] == "" then
    难度系数[3] = 1
  end
  if 难度系数[4] == nil or 难度系数[1] == "空" or  tonumber(难度系数[4]) == nil or 难度系数[1] == "" then
    难度系数[4] = 1
  end
  if 难度系数[5] == nil or 难度系数[1] == "空" or  tonumber(难度系数[5]) == nil or 难度系数[1] == "" then
    难度系数[5] = 1
  end
  if 难度系数[6] == nil or 难度系数[1] == "空" or  tonumber(难度系数[6]) == nil or 难度系数[1] == "" then
    难度系数[6] = 1
  end
  return 难度系数
end

function 战斗处理类:加载指定单位(单位组,任务id)
  local 难度系数 = self:取难度系数(任务id)
  local 临时气血 = 难度系数[1]
  local 临时伤害 = 难度系数[2]
  local 临时防御 = 难度系数[3]
  local 临时灵力 = 难度系数[4]
  local 临时速度 = 难度系数[5]
  local 临时法防 = 难度系数[6]
  for n=1,#单位组 do
    self.参战单位[#self.参战单位+1]={}
    self.参战单位[#self.参战单位].名称=单位组[n].名称
    self.参战单位[#self.参战单位].模型=单位组[n].模型
    self.参战单位[#self.参战单位].等级=单位组[n].等级
    self.参战单位[#self.参战单位].变异=单位组[n].变异
    self.参战单位[#self.参战单位].捉鬼变异=单位组[n].捉鬼变异
    self.参战单位[#self.参战单位].队伍=0
    self.参战单位[#self.参战单位].位置= 单位组[n].位置 or n
    self.参战单位[#self.参战单位].真实编号=#self.参战单位
    self.参战单位[#self.参战单位].类型="bb"
    self.参战单位[#self.参战单位].法防=单位组[n].法防*服务端参数.难度*临时法防
    self.参战单位[#self.参战单位].武器=单位组[n].武器
    self.参战单位[#self.参战单位].染色方案=单位组[n].染色方案
    self.参战单位[#self.参战单位].染色组=单位组[n].染色组
    self.参战单位[#self.参战单位].锦衣=单位组[n].锦衣
    self.参战单位[#self.参战单位].武器染色方案=单位组[n].武器染色方案
    self.参战单位[#self.参战单位].武器染色组=单位组[n].武器染色组
    self.参战单位[#self.参战单位].行走开关=单位组[n].行走开关
    self.参战单位[#self.参战单位].饰品=单位组[n].饰品 or nil
    self.参战单位[#self.参战单位].玩家id=0
    self.参战单位[#self.参战单位].分类="野怪"
    self.参战单位[#self.参战单位].附加阵法=单位组[1].附加阵法 or "普通"
    self.参战单位[#self.参战单位].伤害=单位组[n].伤害*服务端参数.难度*临时伤害
    self.参战单位[#self.参战单位].命中=单位组[n].伤害*服务端参数.难度
    self.参战单位[#self.参战单位].防御=单位组[n].防御*服务端参数.难度*临时防御
    self.参战单位[#self.参战单位].速度=单位组[n].速度*服务端参数.难度*临时速度
    self.参战单位[#self.参战单位].灵力=单位组[n].灵力*服务端参数.难度*临时灵力
    self.参战单位[#self.参战单位].躲闪=单位组[n].躲闪*服务端参数.难度
    self.参战单位[#self.参战单位].气血=math.floor(单位组[n].气血*服务端参数.难度*临时气血)
    self.参战单位[#self.参战单位].最大气血=math.floor(单位组[n].气血*服务端参数.难度*临时气血)
    self.参战单位[#self.参战单位].魔法=单位组[n].魔法
    self.参战单位[#self.参战单位].愤怒=单位组[n].愤怒
    self.参战单位[#self.参战单位].最大魔法=单位组[n].魔法
    self.参战单位[#self.参战单位].技能=单位组[n].技能
    self.参战单位[#self.参战单位].物伤减少=单位组[n].物伤减少
    self.参战单位[#self.参战单位].法伤减少=单位组[n].法伤减少
    self.参战单位[#self.参战单位].躲避减少=单位组[n].躲避减少
    self.参战单位[#self.参战单位].不可封印=单位组[n].不可封印
    self.参战单位[#self.参战单位].怪物修炼={攻击修炼=单位组[n].攻击修炼,防御修炼=单位组[n].防御修炼,法术修炼=单位组[n].法术修炼,抗法修炼=单位组[n].抗法修炼}
    if self.参战单位[#self.参战单位].捉鬼变异 then
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="其实我内心是很善良得，你们可千万不要错杀好鬼呀#52"}
    end
    if self.参战单位[#self.参战单位].名称=="灵感分身" then
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="别以为你们人多，看我分身大法"}
    end
    self.参战单位[#self.参战单位].主动技能={}
    if 单位组[n].角色 then
      self.参战单位[#self.参战单位].类型="系统角色"
    end
    if 单位组[n].角色分类=="角色" then
      self.参战单位[#self.参战单位].类型="系统PK角色"

      self.参战单位[#self.参战单位].愤怒=单位组[n].愤怒
    end
    self.参战单位[#self.参战单位].门派=单位组[n].门派 or "无门派"
    self.参战单位[#self.参战单位].奇经八脉 = 单位组[n].奇经八脉 or {}
    self.参战单位[#self.参战单位].附加状态=单位组[n].附加状态 or {}
    self.参战单位[#self.参战单位].追加法术=单位组[n].追加法术 or {}
    self.参战单位[#self.参战单位].武器伤害=单位组[n].武器伤害 or 0
    self.参战单位[#self.参战单位].法宝佩戴=单位组[n].法宝 or {}
    if 单位组[n].五维属性~=nil then
      self.参战单位[#self.参战单位].体质=单位组[n].五维属性.体质 or 0
      self.参战单位[#self.参战单位].魔力=单位组[n].五维属性.魔力 or 0
      self.参战单位[#self.参战单位].力量=单位组[n].五维属性.力量 or 0
      self.参战单位[#self.参战单位].耐力=单位组[n].五维属性.耐力 or 0
      self.参战单位[#self.参战单位].敏捷=单位组[n].五维属性.敏捷  or 0
    end


    self.参战单位[#self.参战单位].怪物修炼={攻击修炼=单位组[n].攻击修炼,防御修炼=单位组[n].防御修炼,法术修炼=单位组[n].法术修炼,抗法修炼=单位组[n].抗法修炼}
    self.参战单位[#self.参战单位].内丹数据=单位组[n].内丹数据
    if 单位组.阵法~=nil then
      self.参战单位[#self.参战单位].附加阵法=单位组.阵法
    else
      self.参战单位[#self.参战单位].附加阵法="普通"
    end
    if self.战斗类型==100005 then
      if 单位组[n].变异 then
        self.参战单位[#self.参战单位].分类="变异"
      else
        self.参战单位[#self.参战单位].分类="宝宝"
      end
    elseif self.战斗类型==100018 then
      self.参战单位[#self.参战单位].乾坤袋=true
    end
    for i=1,#单位组[n].主动技能 do
      self.参战单位[#self.参战单位].主动技能[i]={名称=单位组[n].主动技能[i],等级=单位组[n].等级+10}
    end
    self.参战单位[#self.参战单位].已加技能={}
    self:设置队伍区分(0)
    -- self.参战单位[#self.参战单位].伤害=1
  end
end

function 战斗处理类:取阵法克制(攻击方,挨打方)
  local 攻击阵法 = self.参战单位[攻击方].附加阵法
  local 挨打阵法 = self.参战单位[挨打方].附加阵法
  local 阵法克制 = 0
  if 挨打阵法 == "普通" then
    if 攻击阵法 == "普通" then
      阵法克制 = 0
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = -0.05
    end
  elseif 挨打阵法 == "天覆阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = 0.05
    end
  elseif 挨打阵法 == "地载阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = -0.1
    end
  elseif 挨打阵法 == "风扬阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = 0.1
    end
  elseif 挨打阵法 == "云垂阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = 0.1
    end
  elseif 挨打阵法 == "龙飞阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = -0.1
    end
  elseif 挨打阵法 == "虎翼阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = -0.05
    end
  elseif 挨打阵法 == "鸟翔阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = 0.05
    end
  elseif 挨打阵法 == "蛇蟠阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = -0.05
    end
  elseif 挨打阵法 == "鹰啸阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = 0
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = -0.05
    end
  elseif 挨打阵法 == "雷绝阵" then
    if 攻击阵法 == "普通" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "天覆阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "地载阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "风扬阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "云垂阵" then
      阵法克制 = -0.1
    elseif 攻击阵法 == "龙飞阵" then
      阵法克制 = 0.1
    elseif 攻击阵法 == "虎翼阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "鸟翔阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "蛇蟠阵" then
      阵法克制 = 0.05
    elseif 攻击阵法 == "鹰啸阵" then
      阵法克制 = -0.05
    elseif 攻击阵法 == "雷绝阵" then
      阵法克制 = 0
    end
  end
  return 阵法克制
  -- body
end

function 战斗处理类:加载野外单位()
  local 加载数量=0
  if 玩家数据[self.发起id].队伍==0 then
    加载数量=取随机数(2,3)
  else
    local 队伍数量=#队伍数据[玩家数据[self.发起id].队伍].成员数据
    加载数量=取随机数(队伍数量+1,队伍数量*2+1)
    if 加载数量>10 then
      加载数量=10
    end
  end
  --加载数量=10
--嘎嘎 跨服怪
local 角色地图=玩家数据[self.发起id].角色.数据.地图数据.编号
  if  角色地图>= 5145 and 角色地图 <= 5157 then
      加载数量=10
  end




  local 临时信息=取野怪(self.战斗地图)
  local 队伍id=0
  local 临时等级=0
  local 临时等级1=0
  临时等级,临时等级1=取场景等级(self.战斗地图)
  self.等级上限=临时等级1
  self.等级下限=临时等级
  self.地图等级=qz((self.等级下限+self.等级上限)/2)
  self.精灵数量=0
  self.头领数量=0
  self.敌人数量=加载数量
  --加载数量=10
  for n=1,加载数量 do
    local 临时野怪=取敌人信息(临时信息[取随机数(1,#临时信息)])
    self.地图等级=取随机数(self.等级上限-5,self.等级上限)--新加
    self.生成等级= self.地图等级
    self.临时等级=取随机数(self.等级下限,self.等级上限)
    local 变异=false
    if 取随机数(1,1000)<=5 then 变异=true end
    local 宝宝=false
    if 取随机数(1,1000)<=10 then 宝宝=true end
    if 变异 or 宝宝 then
      self.临时等级=1
      self.生成等级=0
    end
    self.参战单位[#self.参战单位+1]={}
    self.参战单位[#self.参战单位].名称=临时野怪[2]
    if 变异 then
      self.参战单位[#self.参战单位].名称="变异"..临时野怪[2]
    end
    self.参战单位[#self.参战单位].模型=临时野怪[2]
    self.参战单位[#self.参战单位].等级=self.临时等级
    self.参战单位[#self.参战单位].参战等级=临时野怪[3]
    self.参战单位[#self.参战单位].队伍=队伍id
    self.参战单位[#self.参战单位].位置=n
    self.参战单位[#self.参战单位].变异=变异
    self.参战单位[#self.参战单位].类型="bb"
    self.参战单位[#self.参战单位].法防=math.floor(self.生成等级 * 0.5)-- 0.5) --调用08伤害数据
    self.参战单位[#self.参战单位].玩家id=0
    self.参战单位[#self.参战单位].分类="野怪"
    self.参战单位[#self.参战单位].附加阵法="普通"
    self.参战单位[#self.参战单位].伤害=math.floor(self.生成等级* 6.8)--4.8)
    self.参战单位[#self.参战单位].命中=self.参战单位[#self.参战单位].伤害
    self.参战单位[#self.参战单位].防御=math.floor(self.生成等级*0.5)
    self.参战单位[#self.参战单位].速度=math.floor(self.生成等级*1.5)
    self.参战单位[#self.参战单位].灵力=math.floor(self.生成等级* 4.85)--0.8)
    self.参战单位[#self.参战单位].躲闪=math.floor(self.生成等级*1.5)
    self.参战单位[#self.参战单位].气血=math.floor(self.生成等级* 17.5) + 10--17.5)--08是12.5
    self.参战单位[#self.参战单位].最大气血=math.floor(self.生成等级* 17.5) + 10--17.5)
    self.参战单位[#self.参战单位].魔法=math.floor(self.生成等级*7.5)+10
    self.参战单位[#self.参战单位].最大魔法=math.floor(self.生成等级*7.5)+10
    self.参战单位[#self.参战单位].魔力=self.参战单位[#self.参战单位].参战等级*2
    self.参战单位[#self.参战单位].法防=self.参战单位[#self.参战单位].灵力/2
    self.参战单位[#self.参战单位].躲闪=0
    self.参战单位[#self.参战单位].技能={}
    self.参战单位[#self.参战单位].已加技能={}
    if 变异 then
      self.参战单位[#self.参战单位].分类="变异"
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="诶啊..我..我..我什么变态了,不对是换色了,你们别抓我呀!#52"}
    elseif 宝宝 then
      self.参战单位[#self.参战单位].分类="宝宝"
      self.参战单位[#self.参战单位].名称=self.参战单位[#self.参战单位].模型.."宝宝"
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="其实我一个小小的宝宝,你们别抓我呀!#52"}
    end
    --   local 测试技能={"弱点雷","弱点火","弱点水","弱点土","高级水属性吸收","高级火属性吸收","高级雷属性吸收","高级土属性吸收"}
    local 临时技能=临时野怪[14]
    for i=1,#临时技能 do
      if 取随机数()<=45 then
        self.参战单位[#self.参战单位].技能[#self.参战单位[#self.参战单位].技能+1]=临时技能[n]
        if 取随机数()<=30 then
        end
      end
    end
    if self.精灵数量==0 and 取随机数()<=3 then
      self.精灵数量=1
      self.参战单位[#self.参战单位].精灵=true
      self.参战单位[#self.参战单位].不可封印=true
      self.参战单位[#self.参战单位].技能={"自爆"}
      self.参战单位[#self.参战单位].气血= self.参战单位[#self.参战单位].气血*3
      self.参战单位[#self.参战单位].名称=self.参战单位[#self.参战单位].模型.."精灵"
      self.参战单位[#self.参战单位].速度=0
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="我是一只小精灵,小啊小精灵!#52"}
    elseif 变异==false and 宝宝==false and 取随机数()<=20 then
      self.参战单位[#self.参战单位].名称=self.参战单位[#self.参战单位].模型.."头领"
      self.头领数量=self.头领数量+1
      self.参战单位[#self.参战单位].气血=qz(self.参战单位[#self.参战单位].气血* 1.25)
      self.参战单位[#self.参战单位].防御=qz(self.参战单位[#self.参战单位].防御* 1.15)--1.2) --08伤害数据
      self.参战单位[#self.参战单位].伤害=qz(self.参战单位[#self.参战单位].伤害* 1.05)--1.25)
      self.参战单位[#self.参战单位].灵力=qz(self.参战单位[#self.参战单位].灵力* 1.15)--1.25)
    end
    -- self.参战单位[#self.参战单位].技能[#self.参战单位[#self.参战单位].技能+1]="高级神佑复生"
    --self:添加技能属性(self.参战单位[#self.参战单位],self.参战单位[#self.参战单位].技能)
    self:设置队伍区分(队伍id)
  end
end

function 战斗处理类:加载野外单位1()
  local 加载数量=0
  if 玩家数据[self.发起id].队伍==0 then
    加载数量=取随机数(2,3)
  else
    local 队伍数量=#队伍数据[玩家数据[self.发起id].队伍].成员数据
    加载数量=取随机数(队伍数量+1,队伍数量*2+1)
    if 加载数量>10 then
      加载数量=10
    end
  end
  local 临时信息=取野怪(self.战斗地图)
  local 队伍id=0
  local 临时等级=0
  local 临时等级1=0
  临时等级,临时等级1=取场景等级(self.战斗地图)
  self.等级上限=临时等级1
  self.等级下限=临时等级
  self.地图等级=qz((self.等级下限+self.等级上限)/2)
  self.精灵数量=0
  self.头领数量=0
  self.敌人数量=加载数量
  for n=1,加载数量 do
    local 临时野怪=取敌人信息(临时信息[取随机数(1,#临时信息)])
    if n==1 then
      for i=1,#临时信息 do
        local 序列数据=取敌人信息(临时信息[i])
        if 序列数据[2]==任务数据[self.任务id].模型 then
          临时野怪=取敌人信息(临时信息[i])
        end
      end
    end
    self.地图等级=取随机数(self.等级上限-5,self.等级上限)--新加
    self.生成等级= self.地图等级
    self.临时等级=取随机数(self.等级下限,self.等级上限)
    local 变异=false
    if 取随机数(1,1000)<=5 then 变异=true end
    local 宝宝=false
    if 取随机数(1,1000)<=10 then 宝宝=true end
    if 变异 or 宝宝 then
      self.临时等级=1
      self.生成等级=0
    end
    self.参战单位[#self.参战单位+1]={}
    self.参战单位[#self.参战单位].名称=临时野怪[2]
    if 变异 then
      self.参战单位[#self.参战单位].名称="变异"..临时野怪[2]
    end
    self.参战单位[#self.参战单位].模型=临时野怪[2]
    self.参战单位[#self.参战单位].等级=self.临时等级
    self.参战单位[#self.参战单位].队伍=队伍id
    self.参战单位[#self.参战单位].位置=n
    self.参战单位[#self.参战单位].变异=变异
    self.参战单位[#self.参战单位].类型="bb"
    self.参战单位[#self.参战单位].法防=math.floor(self.生成等级 * 0.5)-- 0.5) --调用08伤害数据
    self.参战单位[#self.参战单位].玩家id=0
    self.参战单位[#self.参战单位].分类="野怪"
    self.参战单位[#self.参战单位].附加阵法="普通"
    self.参战单位[#self.参战单位].伤害=math.floor(self.生成等级* 6.8)--4.8)
    self.参战单位[#self.参战单位].命中=self.参战单位[#self.参战单位].伤害
    self.参战单位[#self.参战单位].防御=math.floor(self.生成等级*0.5)
    self.参战单位[#self.参战单位].速度=math.floor(self.生成等级*1.5)
    self.参战单位[#self.参战单位].灵力=math.floor(self.生成等级* 4.85)--0.8)
    self.参战单位[#self.参战单位].躲闪=math.floor(self.生成等级*1.5)
    self.参战单位[#self.参战单位].气血=math.floor(self.生成等级* 17.5) + 10--17.5)--08是12.5
    self.参战单位[#self.参战单位].最大气血=math.floor(self.生成等级* 17.5) + 10--17.5)
    self.参战单位[#self.参战单位].魔法=math.floor(self.生成等级*7.5)+10
    self.参战单位[#self.参战单位].最大魔法=math.floor(self.生成等级*7.5)+10
    self.参战单位[#self.参战单位].躲闪=0
    self.参战单位[#self.参战单位].技能={}
    self.参战单位[#self.参战单位].魔力=self.临时等级*2
    self.参战单位[#self.参战单位].已加技能={}
    if 变异 then
      self.参战单位[#self.参战单位].分类="变异"
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="诶啊..我..我..我什么变态了,不对是换色了,你们别抓我呀!#52"}
    elseif 宝宝 then
      self.参战单位[#self.参战单位].分类="宝宝"
      self.参战单位[#self.参战单位].名称=self.参战单位[#self.参战单位].模型.."宝宝"
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="其实我一个小小的宝宝,你们别抓我呀!#52"}
    end
    --   local 测试技能={"弱点雷","弱点火","弱点水","弱点土","高级水属性吸收","高级火属性吸收","高级雷属性吸收","高级土属性吸收"}
    local 临时技能=临时野怪[14]
    for i=1,#临时技能 do
      if 取随机数()<=45 then
        self.参战单位[#self.参战单位].技能[#self.参战单位[#self.参战单位].技能+1]=临时技能[n]
        if 取随机数()<=30 then
        end
      end
    end
    if self.精灵数量==0 and 取随机数()<=3 then
      self.精灵数量=1
      self.参战单位[#self.参战单位].精灵=true
      self.参战单位[#self.参战单位].不可封印=true
      self.参战单位[#self.参战单位].技能={"自爆"}
      self.参战单位[#self.参战单位].气血= self.参战单位[#self.参战单位].气血*3
      self.参战单位[#self.参战单位].名称=self.参战单位[#self.参战单位].模型.."精灵"
      self.参战单位[#self.参战单位].速度=0
      self.战斗发言数据[#self.战斗发言数据+1]={id=#self.参战单位,内容="我是一只小精灵,小啊小精灵!#52"}
    elseif 变异==false and 宝宝==false and 取随机数()<=20 then
      self.参战单位[#self.参战单位].名称=self.参战单位[#self.参战单位].模型.."头领"
      self.头领数量=self.头领数量+1
      self.参战单位[#self.参战单位].气血=qz(self.参战单位[#self.参战单位].气血*1.25)
      self.参战单位[#self.参战单位].防御=qz(self.参战单位[#self.参战单位].防御* 1.15)--1.2) --08伤害数据
      self.参战单位[#self.参战单位].伤害=qz(self.参战单位[#self.参战单位].伤害* 1.05)--1.25)
      self.参战单位[#self.参战单位].灵力=qz(self.参战单位[#self.参战单位].灵力* 1.15)--1.25)
    end
    -- self.参战单位[#self.参战单位].技能[#self.参战单位[#self.参战单位].技能+1]="高级神佑复生"
    --self:添加技能属性(self.参战单位[#self.参战单位],self.参战单位[#self.参战单位].技能)
    self:设置队伍区分(队伍id)
  end
end

function 战斗处理类:添加内丹属性(单位,内丹1)
  local 内丹={}
  for n=1,#内丹1 do
     内丹[n]=内丹1[n]
  end
  for i=1,#内丹 do
      local 等级 = 内丹[i].等级
      local 技能 = 内丹[i].技能
      --0914神机
    -- if 技能=="神机步" then
    --   self:添加状态(技能,单位,nil,等级,nil,nil)
    --   end
      if 技能 == "深思" then
        if self:取技能重复(单位,"高级冥思")~=false or self:取技能重复(单位,"冥思")~=false then
          if 单位.冥思==nil then
          单位.冥思=0
          end
          单位.冥思 = 等级 *5 + 单位.冥思
        end
      end
      if 技能 == "淬毒" then
        if self:取技能重复(单位,"毒")~=false or self:取技能重复(单位,"高级毒")~=false then
          if 单位.毒==nil then
          单位.毒=0
          end
          单位.毒=单位.毒+5*等级
        end
      end

      if 技能 == "连环" then
        if self:取技能重复(单位,"连击")~=false or self:取技能重复(单位,"高级连击")~=false then

          if 单位.连击==nil then
            单位.连击=0
          end
         单位.连击=单位.连击+2*等级
        end
      end

      if 技能 == "圣洁" then
         if self:取技能重复(单位,"驱鬼")~=false  or self:取技能重复(单位,"高级驱鬼")~=false  then
          if 单位.驱鬼==nil then
            单位.驱鬼=0
          end
          单位.驱鬼= math.floor(等级 *10 /100)+单位.驱鬼
        end
      end

      if 技能 == "狂怒" then
          if 等级 == 1 then
            单位.狂怒=80
          elseif 等级 == 2 then
             单位.狂怒=100
                 elseif 等级 == 3 then
             单位.狂怒=120
                 elseif 等级 == 4 then
             单位.狂怒=140
                 elseif 等级 == 5 then
             单位.狂怒=160
          end

      end
      if 技能 == "阴伤" then
          if 等级 == 1 then
            单位.阴伤=50
          elseif 等级 == 2 then
             单位.阴伤=60
                 elseif 等级 == 3 then
             单位.阴伤=70
                 elseif 等级 == 4 then
             单位.阴伤=80
                 elseif 等级 == 5 then
             单位.阴伤=90
          end
        end
      if 技能 == "撞击" then
        if 单位.撞击==nil then
          单位.撞击=0
        end
        单位.撞击=等级
      end

      if 技能 == "钢化" then
        if 单位.钢化==nil then
          单位.钢化=0
        end
        if self:取技能重复(单位,"防御") or self:取技能重复(单位,"高级防御") then
          单位.防御=math.floor(单位.防御+单位.等级*0.2*等级)
        end
        单位.钢化=1
      end

      if 技能 == "玄武躯" then
          if 单位.玄武躯==nil then
            单位.玄武躯=0
          end
          单位.玄武躯=1
        end
      if 技能 == "龙胄铠" then
          if 单位.龙胄铠==nil then
            单位.龙胄铠=0
          end
          单位.龙胄铠=1
        end

      if 技能 == "擅咒" then
        if 单位.法术伤害结果==nil then
          单位.法术伤害结果=0
        end
        单位.法术伤害结果=(单位.法术伤害结果+math.floor(12*等级))
      end

      if 技能 == "狙刺" then
        if 单位.法术伤害==nil then
            单位.法术伤害=0
        end
        单位.法术伤害=(单位.法术伤害+math.floor(单位.等级*0.15)*等级)
      end

      if 技能 == "碎甲刃" then
         if 单位.碎甲刃==nil then
            单位.碎甲刃=0
          end
         单位.碎甲刃=等级
      end

      if 技能 == "舍身击" then
        if 单位.舍身击==nil then
          单位.舍身击=0
        end
        单位.舍身击=等级
      end

      if 技能 == "生死决" then
        if 单位.狂暴等级 == nil then
          单位.狂暴等级 = 0
        end
        单位.狂暴等级 = 单位.狂暴等级 + math.floor((0.03+0.0075*等级)*2000)
      end

      if 技能 == "催心浪" then
          if 单位.法波上 ~= nil and 单位.法波上 ~=0 then
              单位.法波下=单位.法波下 + 等级*3
          elseif 单位.高级法波下 ~= nil and 单位.高级法波下 ~=0 then
             单位.高级法波下=单位.高级法波下 + 等级*3
          end
      end

      if 技能 == "隐匿击" then
        if 单位.隐匿击==nil then
          单位.隐匿击=0
        end
        单位.隐匿击=等级
      end

      if 技能 == "灵身" then
            if 等级 == 1 then
            单位.灵身=1
            elseif 等级 == 2 then
            单位.灵身=2
            elseif 等级 == 3 then
            单位.灵身=3
            elseif 等级 == 4 then
            单位.灵身=4
            elseif 等级 == 5 then
            单位.灵身=5
            end
      end

      if 技能 == "血债偿" then
        单位.血债偿=(单位.魔力-单位.等级)*0.04*等级
      end

      if 技能 == "通灵法" then
            if 等级 == 1 then
            单位.通灵法=1
            elseif 等级 == 2 then
            单位.通灵法=2
            elseif 等级 == 3 then
            单位.通灵法=3
            elseif 等级 == 4 then
            单位.通灵法=4
            elseif 等级 == 5 then
            单位.通灵法=5
            end
      end

      if 技能 == "慧心" then
            if 等级 == 1 then
            单位.慧心=1
            elseif 等级 == 2 then
            单位.慧心=2
            elseif 等级 == 3 then
            单位.慧心=3
            elseif 等级 == 4 then
            单位.慧心=4
            elseif 等级 == 5 then
            单位.慧心=5
            end
      end

      if 技能 == "无畏" then
            if 等级 == 1 then
            单位.无畏=1.02
            elseif 等级 == 2 then
            单位.无畏=1.04
            elseif 等级 == 3 then
            单位.无畏=1.06
            elseif 等级 == 4 then
            单位.无畏=1.08
            elseif 等级 == 5 then
            单位.无畏=1.1
            end
      end

      if 技能 == "愤恨" then
            if 等级 == 1 then
            单位.愤恨=1.02
            elseif 等级 == 2 then
            单位.愤恨=1.04
            elseif 等级 == 3 then
            单位.愤恨=1.06
            elseif 等级 == 4 then
            单位.愤恨=1.08
            elseif 等级 == 5 then
            单位.愤恨=1.1
            end
      end
      if 技能 == "玉砥柱" then
            if 等级 == 1 then
            单位.玉砥柱=0.07
            elseif 等级 == 2 then
            单位.玉砥柱=0.14
            elseif 等级 == 3 then
            单位.玉砥柱=0.21
            elseif 等级 == 4 then
            单位.玉砥柱=0.28
            elseif 等级 == 5 then
            单位.玉砥柱=0.35
            end
      end

      if 技能 == "双星爆" then
            if 等级 == 1 then
            单位.双星爆=0.1
            elseif 等级 == 2 then
            单位.双星爆=0.2
            elseif 等级 == 3 then
            单位.双星爆=0.3
            elseif 等级 == 4 then
            单位.双星爆=0.4
            elseif 等级 == 5 then
            单位.双星爆=0.5
            end
      end

      if 技能 == "坚甲" then
         if self:取技能重复(单位,"高级反震")~=false or self:取技能重复(单位,"反震")~=false then
              单位.反震1=100*等级
         end
      end
   end
end


function 战斗处理类:添加认证法术属性(单位,技能组)
  for n=1,#技能组 do
    local 名称=技能组[n]
    if 名称=="上古灵符" or 名称=="月光" or 名称=="死亡召唤" or 名称=="水攻" or 名称=="落岩" or 名称=="雷击" or 名称=="烈火" or 名称=="地狱烈火" or 名称=="奔雷咒" or 名称=="水漫金山" or 名称=="泰山压顶" or 名称=="善恶有报" or 名称=="壁垒击破" or 名称=="惊心一剑" or 名称=="夜舞倾城" or 名称=="力劈华山" then
      单位.主动技能[#单位.主动技能+1]={名称=名称,等级=单位.等级}
    end
  end
end

function 战斗处理类:添加技能属性(单位,技能组)
  for n=1,#技能组 do
    local 名称=技能组[n]
    if (名称=="上古灵符" or 名称=="月光" or 名称=="死亡召唤" or 名称=="法术防御" or 名称=="天降灵葫" or 名称=="八凶法阵" or 名称=="观照万象" or 名称=="叱咤风云" or 名称=="自爆" or 名称=="水攻" or 名称=="落岩" or 名称=="雷击" or 名称=="烈火" or 名称=="地狱烈火" or 名称=="奔雷咒" or 名称=="水漫金山" or 名称=="泰山压顶" or 名称=="善恶有报" or 名称=="惊心一剑" or 名称=="夜舞倾城" or 名称=="力劈华山"
      or 名称=="龙卷雨击" or 名称=="扶摇万里" or 名称=="龙腾" or 名称=="百毒不侵" or 名称=="烟雨剑法" or 名称=="五雷轰顶" or 名称=="飞砂走石"
      or 名称=="修罗隐身" or 名称=="金刚护体" or 名称=="杨柳甘露" or 名称=="天雷斩" or 名称=="杀气诀" or 名称=="楚楚可怜"
      or 名称=="五雷咒" or 名称=="后发制人" or 名称=="三昧真火" or 名称=="炼气化神" or 名称=="姐妹同心" or 名称=="定身符"
      or 名称=="活血" or 名称=="极度疯狂" or 名称=="日光华" or 名称=="威慑" or 名称=="勾魂" or 名称=="裂石" or 名称=="不动如山"
      or 名称=="雾杀" or 名称=="蜜润" or 名称=="金身舍利" or 名称=="地涌金莲" or 名称=="流沙轻音"or 名称=="食指大动"
      or 名称=="还魂咒" or 名称=="治疗" or 名称=="蚩尤之搏" or 名称=="仙人指路" or 名称=="四面埋伏" or 名称=="横扫千军"
      or 名称=="普渡众生" or 名称=="唧唧歪歪" or 名称=="推气过宫" or 名称=="判官令" or 名称=="阎罗令" or 名称=="峰回路转" or 名称=="夺命咒" or 名称=="狮搏 ") and 单位.类型=="bb" then
      单位.主动技能[#单位.主动技能+1]={名称=名称,等级=单位.等级}
      elseif 名称=="剑荡四方" or 名称=="壁垒击破" then
      单位.主动技能[#单位.主动技能+1]={名称=名称,等级=单位.等级}
      if 名称 == "叱咤风云" then
        if 单位.法连 == nil then
          单位.法连=10
        else
          单位.法连=单位.法连+10
        end
      end
    elseif 名称=="浮云神马" then
      self:添加状态(名称,单位)
      self:添加状态(名称,self.参战单位[单位.主人])
    elseif 名称=="盾气" or 名称=="高级盾气" then
      if 名称=="盾气" then
        if self:取技能重复(单位,"高级盾气")==false then
          单位.盾气=1.2
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.盾气=2.0
        单位.已加技能[#单位.已加技能+1]="高级盾气"
      end
    elseif 名称=="神出鬼没" then
      单位.隐身=4
      单位.已加技能[#单位.已加技能+1]="神出鬼没"
      单位.伤害=qz(单位.伤害*1.1)
    elseif 名称=="昼伏夜出" then
      单位.夜战=2
      单位.伤害=qz(单位.伤害*1.1)
      单位.已加技能[#单位.已加技能+1]="昼伏夜出"
    elseif 名称=="进击必杀" or 名称=="高级进击必杀" then
      if 名称=="进击必杀" then
        if self:取技能重复(单位,"高级进击必杀")==false then
          单位.进击必杀=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.进击必杀=2
        单位.已加技能[#单位.已加技能+1]="高级进击必杀"
      end
    elseif 名称=="进击法爆" or 名称=="高级进击法爆" then
      if 名称=="进击法爆" then
        if self:取技能重复(单位,"高级进击法爆")==false then
          单位.进击法爆 = 1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.进击法爆 = 2
        单位.已加技能[#单位.已加技能+1]="高级进击法爆"
      end
    elseif 名称=="赴汤蹈火" then
      单位.法防=单位.法防+162
      单位.最大气血 = 单位.最大气血 + 540
      单位.气血 = 单位.最大气血
    elseif 名称=="开门见山" then
      单位.伤害=单位.伤害+100
      单位.最大气血 = 单位.最大气血 + 380
      单位.气血 = 单位.最大气血
    elseif 名称=="张弛有道" then
      单位.灵力 = 单位.灵力 + qz(单位.魔力*0.5)
    elseif 名称=="龙魂" then
      单位.龙魂=0
    elseif 名称=="千钧一怒" then
      单位.千钧一怒=1
    elseif 名称=="从天而降" then
      单位.从天而降=1
    elseif 名称=="大快朵颐" then
      if 单位.连击 == nil then
        单位.连击=10
      else
        单位.连击=单位.连击+10
      end
      if 单位.必杀 == nil then
        单位.必杀=10
      else
        单位.必杀=单位.必杀+10
      end
    elseif 名称=="合纵" or 名称=="高级合纵" then
      --计算与本单位不同模型的单位数量
      local diff_model_count = 0
      for n=1,#self.参战单位 do
        if self.参战单位[n].队伍==单位.队伍 then
          if self.参战单位[n].类型=="bb" and self.参战单位[n].模型~=单位.模型 then
            diff_model_count = diff_model_count + 1
          end
        end
      end
      if 名称=="合纵" then
        if self:取技能重复(单位,"高级合纵")==false then
          单位.伤害=qz(单位.伤害+单位.等级*0.2*diff_model_count)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.伤害=qz(单位.伤害+单位.等级*0.4*diff_model_count)
        单位.已加技能[#单位.已加技能+1]="高级合纵"
      end
    elseif 名称=="反击" or 名称=="高级反击" then
      if 名称=="反击" then
        if self:取技能重复(单位,"高级反击")==false then
          单位.反击=0.5
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.反击=1
        单位.已加技能[#单位.已加技能+1]="高级反击"
      end
    elseif 名称=="净台妙谛" then
      单位.最大气血 = 单位.最大气血 + 单位.体质*单位.成长*2
      单位.气血 = 单位.最大气血
      local 血量数据 = {}
      血量数据={气血=单位.气血,最大气血=单位.最大气血,魔法=单位.魔法,最大魔法=单位.最大魔法,愤怒=单位.愤怒}
      发送数据(玩家数据[单位.玩家id].连接id,5517,血量数据)
      单位.已加技能[#单位.已加技能+1]=名称
    elseif 名称=="理直气壮" then
      单位.理直气壮 = 1
      单位.已加技能[#单位.已加技能+1]=名称
    elseif 名称=="移花接木" then
      单位.移花接木 = 1
      单位.已加技能[#单位.已加技能+1]=名称
    elseif 名称=="灵能激发" then
      单位.法术伤害 = 单位.法术伤害 + 100
      单位.已加技能[#单位.已加技能+1]=名称
    elseif 名称=="灵山禅语" then
            if 单位.成长==nil then
         单位.成长=1
        end
            if 单位.魔力==nil then
         单位.魔力=1
        end
      单位.法术防御 = 单位.法术防御 + 单位.魔力*(单位.成长-0.3)
      单位.已加技能[#单位.已加技能+1]=名称
    elseif 名称=="高级法术抵抗" then
      if 单位.法伤减少==nil then
        单位.法伤减少 = 0.9
      else
          单位.法伤减少 = 单位.法伤减少-0.1
          if 单位.法伤减少 <= 0 then
            单位.法伤减少 = 0.7
          end
      end
      单位.已加技能[#单位.已加技能+1]=名称
    elseif 名称=="驱怪" then
      单位.驱怪=1
    elseif 名称=="苍鸾怒击" then
      单位.怒击效果=true
    elseif 名称=="反震" or 名称=="高级反震" then
      if 名称=="反震" then
        if self:取技能重复(单位,"高级反震")==false then
          单位.反震=0.25
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.反震=0.5
        单位.已加技能[#单位.已加技能+1]="高级反震"
      end
    elseif 名称=="吸血" or 名称=="高级吸血" then
      if 名称=="吸血" then
        if self:取技能重复(单位,"高级吸血")==false then
          单位.吸血=0.25
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.吸血=0.3
        单位.已加技能[#单位.已加技能+1]="高级吸血"
      end
    elseif 名称=="连击" or 名称=="高级连击" then
      if 名称=="连击" then
        if self:取技能重复(单位,"高级连击")==false then
          if 单位.连击 == nil then
            单位.连击=45
          else
            单位.连击 = 单位.连击 +45
          end
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.连击=55
        单位.已加技能[#单位.已加技能+1]="高级连击"
      end
    elseif 名称=="飞行" or 名称=="高级飞行" then
      if 名称=="飞行" then
        if self:取技能重复(单位,"高级飞行")==false then
          单位.伤害=qz(单位.伤害*1.05)
          单位.灵力=qz(单位.灵力*1.05)
          单位.防御=qz(单位.防御*0.8)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
          单位.伤害=qz(单位.伤害*1.05)
          单位.灵力=qz(单位.灵力*1.05)
          单位.防御=qz(单位.防御*0.9)
        单位.已加技能[#单位.已加技能+1]="高级飞行"
      end
    elseif 名称=="夜战" or 名称=="高级夜战" then
      if 名称=="夜战" then
        if self:取技能重复(单位,"高级夜战")==false then
          单位.夜战=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.夜战=2
        单位.已加技能[#单位.已加技能+1]="高级夜战"
      end
    elseif 名称=="隐身" or 名称=="高级隐身" then
      if 名称=="隐身" then
        if self:取技能重复(单位,"高级隐身")==false then
          单位.隐身=3
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.隐身=4
        单位.已加技能[#单位.已加技能+1]="高级隐身"
      end
    elseif 名称=="感知" or 名称=="高级感知" then
      if 名称=="感知" then
        if self:取技能重复(单位,"高级感知")==false then
          单位.感知=0.45
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.感知=0.55
        单位.躲闪=qz(单位.躲闪*1.1)
        单位.已加技能[#单位.已加技能+1]="高级感知"
      end
    elseif 名称=="再生" or 名称=="高级再生" then
      if 名称=="再生" then
        if self:取技能重复(单位,"高级再生")==false then
          单位.再生=qz(单位.等级*2)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.再生=qz(单位.等级*3)
        单位.已加技能[#单位.已加技能+1]="高级再生"
      end
    elseif 名称=="冥思" or 名称=="高级冥思" then
      if 名称=="冥思" then
        if self:取技能重复(单位,"高级冥思")==false then
          单位.冥思=qz(单位.等级*0.25)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.冥思=qz(单位.等级*0.5)
        单位.已加技能[#单位.已加技能+1]="高级冥思"
      end
    elseif 名称=="慧根" or 名称=="高级慧根" then
      if 名称=="慧根" then
        if self:取技能重复(单位,"高级慧根")==false then
          单位.慧根=0.75
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.慧根=0.5
        单位.已加技能[#单位.已加技能+1]="高级慧根"
      end
    elseif 名称=="必杀" or 名称=="高级必杀" then
      if 名称=="必杀" then
        if self:取技能重复(单位,"高级必杀")==false then
          单位.必杀=单位.必杀+10
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.必杀=单位.必杀+20
        单位.已加技能[#单位.已加技能+1]="高级必杀"
      end
    elseif 名称=="幸运" or 名称=="高级幸运" then
      if 名称=="幸运" then
        if self:取技能重复(单位,"高级幸运")==false then
          单位.幸运=0.75
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.幸运=0.5
        单位.已加技能[#单位.已加技能+1]="高级幸运"
      end
    elseif 名称=="永恒" or 名称=="高级永恒" then
      if 名称=="永恒" then
        if self:取技能重复(单位,"高级永恒")==false then
          单位.永恒=1.3
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.永恒=1.5
        单位.已加技能[#单位.已加技能+1]="高级永恒"
      end
    elseif 名称=="神迹" or 名称=="高级神迹" then
      if 名称=="神迹" then
        if self:取技能重复(单位,"高级神迹")==false then
          单位.神迹=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.神迹=2
        单位.已加技能[#单位.已加技能+1]="高级神迹"
      end
    elseif 名称=="招架" or 名称=="高级招架" then
      if 名称=="招架" then
        if self:取技能重复(单位,"高级招架")==false then
          单位.招架=10
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.招架=20
        单位.已加技能[#单位.已加技能+1]="高级招架"
      end
    elseif 名称=="偷袭" or 名称=="高级偷袭" then
      if 名称=="偷袭" then
        if self:取技能重复(单位,"高级偷袭")==false then
          单位.偷袭=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.偷袭=1
        单位.伤害=qz(单位.伤害*1.1)
        单位.已加技能[#单位.已加技能+1]="高级偷袭"
      end
    elseif 名称=="敏捷" or 名称=="高级敏捷" then
      if 名称=="敏捷" then
        if self:取技能重复(单位,"高级敏捷")==false then
          单位.速度=qz(单位.速度*1.1)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.速度=qz(单位.速度*1.2)
        单位.已加技能[#单位.已加技能+1]="高级敏捷"
      end
    elseif 名称=="迟钝" then
      单位.速度=qz(单位.速度*0.8)
      单位.已加技能[#单位.已加技能+1]="迟钝"
    elseif 名称=="防御" or 名称=="高级防御" then
      if 名称=="防御" then
        if self:取技能重复(单位,"高级防御")==false then
          单位.防御=qz(单位.防御+单位.等级*0.6)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.防御=qz(单位.防御+单位.等级*0.8)
        单位.已加技能[#单位.已加技能+1]="高级防御"
      end
    elseif 名称=="强力" or 名称=="高级强力" then
      if 名称=="强力" then
        if self:取技能重复(单位,"高级强力")==false then
          单位.伤害=qz(单位.伤害+单位.等级*0.4)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.伤害=qz(单位.伤害+单位.等级*0.8)
       -- print(单位.伤害)
        单位.已加技能[#单位.已加技能+1]="高级强力"
      end
    elseif 名称=="毒" or 名称=="高级毒" then
      if 名称=="毒" then
        if self:取技能重复(单位,"高级毒")==false then
          单位.毒=15
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.毒=20
        单位.已加技能[#单位.已加技能+1]="高级毒"
      end
    elseif 名称=="驱鬼" or 名称=="高级驱鬼" then
      if 名称=="驱鬼" then
        if self:取技能重复(单位,"高级驱鬼")==false then
          单位.驱鬼=1.5
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.驱鬼=2
        单位.已加技能[#单位.已加技能+1]="高级驱鬼"
      end
    elseif 名称=="鬼魂术" or 名称=="高级鬼魂术" then
      if 名称=="鬼魂术" then
        if self:取技能重复(单位,"高级鬼魂术")==false then
          单位.鬼魂=5
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.鬼魂=5
        单位.已加技能[#单位.已加技能+1]="高级鬼魂术"
      end
    elseif 名称=="魔之心" or 名称=="高级魔之心" then
      if 名称=="魔之心" then
        if self:取技能重复(单位,"高级魔之心")==false then
          单位.魔之心=1.1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.魔之心=1.2
        单位.已加技能[#单位.已加技能+1]="高级魔之心"
      end
    elseif 名称=="神佑复生" or 名称=="高级神佑复生" then
      if 名称=="神佑复生" then
        if self:取技能重复(单位,"高级神佑复生")==false then
          单位.神佑=15
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.神佑=30
        单位.已加技能[#单位.已加技能+1]="高级神佑复生"
      end
    elseif 名称=="精神集中" or 名称=="高级精神集中" then
      if 名称=="精神集中" then
        if self:取技能重复(单位,"高级精神集中")==false then
          单位.精神=0.75
          单位.伤害=qz(单位.伤害*0.8)
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.精神=0.5
        单位.已加技能[#单位.已加技能+1]="高级精神集中"
        单位.伤害=qz(单位.伤害*0.8)
        单位.躲闪=qz(单位.躲闪*1.1)
      end
    elseif 名称=="否定信仰" or 名称=="高级否定信仰" then
      if 名称=="否定信仰" then
        if self:取技能重复(单位,"高级否定信仰")==false then
          单位.信仰=2
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.信仰=2
        单位.已加技能[#单位.已加技能+1]="高级否定信仰"
      end
    elseif 名称=="法术暴击" or 名称=="高级法术暴击" then
      if 名称=="法术暴击" then
        if self:取技能重复(单位,"高级法术暴击")==false then
          单位.法暴=10
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.法暴=15
        单位.已加技能[#单位.已加技能+1]="高级法术暴击"
      end
    elseif 名称=="法术连击" or 名称=="高级法术连击" then
      if 名称=="法术连击" then
        if self:取技能重复(单位,"高级法术连击")==false then
          单位.法连=20
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.法连=30
        单位.已加技能[#单位.已加技能+1]="高级法术连击"
      end
    elseif 名称=="法术波动" or 名称=="高级法术波动" then
      if 名称=="法术波动" then
        if self:取技能重复(单位,"高级法术波动")==false then
          单位.法波=120
          单位.已加技能[#单位.已加技能+1]=名称
          单位.法波下=80
        end
      else
        单位.高级法波=150
        单位.高级法波下=50
        单位.已加技能[#单位.已加技能+1]="高级法术波动"
      end
    elseif 名称=="水属性吸收" or 名称=="高级水属性吸收" then
      if 名称=="水属性吸收" then
        if self:取技能重复(单位,"高级水属性吸收")==false then
          单位.水吸=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.水吸=2
        单位.已加技能[#单位.已加技能+1]="高级水属性吸收"
      end
    elseif 名称=="雷属性吸收" or 名称=="高级雷属性吸收" then
      if 名称=="雷属性吸收" then
        if self:取技能重复(单位,"高级雷属性吸收")==false then
          单位.雷吸=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.雷吸=2
        单位.已加技能[#单位.已加技能+1]="高级雷属性吸收"
      end
    elseif 名称=="火属性吸收" or 名称=="高级火属性吸收" then
      if 名称=="火属性吸收" then
        if self:取技能重复(单位,"高级火属性吸收")==false then
          单位.火吸=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.火吸=2
        单位.已加技能[#单位.已加技能+1]="高级火属性吸收"
      end
    elseif 名称=="土属性吸收" or 名称=="高级土属性吸收" then
      if 名称=="土属性吸收" then
        if self:取技能重复(单位,"高级土属性吸收")==false then
          单位.土吸=1
          单位.已加技能[#单位.已加技能+1]=名称
        end
      else
        单位.土吸=2
        单位.已加技能[#单位.已加技能+1]="高级土属性吸收"
      end
    elseif 名称=="凝光炼彩" then
      单位.凝光炼彩=1
      单位.已加技能[#单位.已加技能+1]="凝光炼彩"
    elseif 名称=="食指大动" then
      单位.凝光炼彩=1
      单位.已加技能[#单位.已加技能+1]="食指大动"
    elseif 名称=="弱点雷"  then
      单位.弱点雷=1
    elseif 名称=="弱点火"  then
      单位.弱点火=1
    elseif 名称=="弱点水"  then
      单位.弱点水=1
    elseif 名称=="弱点土"  then
      单位.弱点土=1
    elseif 名称=="嗜血追击"  then
      单位.嗜血追击=1
    elseif 名称 == "须弥真言" then
      单位.法术伤害 = 单位.法术伤害+qz(单位.魔力*0.4)
    end
  end
end

function 战斗处理类:取技能重复(单位,技能)
  for n=1,#单位.已加技能 do
    if 单位.已加技能[n]==技能 then return true end
  end
  return false
end

function 战斗处理类:设置队伍区分(id)
  if self.队伍区分[1]==id then
    self.队伍数量[1]=self.队伍数量[1]+1
  else
    self.队伍数量[2]=self.队伍数量[2]+1
    self.队伍区分[2]=id
  end
end

function 战斗处理类:结算处理()
  local 死亡计算={0,0}
  for n=1,#self.参战单位 do
    if self.参战单位[n].气血<=0 or self.参战单位[n].捕捉 or self.参战单位[n].逃跑 then
      if self.参战单位[n].队伍==self.队伍区分[1] then
        死亡计算[1]=死亡计算[1]+1
      else
        死亡计算[2]=死亡计算[2]+1
      end
    end
  end
  if 死亡计算[1]==self.队伍数量[1] then
    self.回合进程="结束回合"
    self:结束战斗(self.队伍区分[2],self.队伍区分[1])
    return
  elseif 死亡计算[2]==self.队伍数量[2] then
    self.回合进程="结束回合"
    self:结束战斗(self.队伍区分[1],self.队伍区分[2])
    return
  end
  --检查状态
  local 观战状态={}
  local 法术状态 ={}
  local 血量={}
  --循环设置删除超过气血上限的血量
  for n=1,#self.参战单位 do
    if self.参战单位[n].类型=="角色" and self.参战单位[n].助战编号 == nil then
      if self.参战单位[n].气血上限 > self.参战单位[n].最大气血 then
        self.参战单位[n].气血上限 = self.参战单位[n].最大气血
      end
      if self.参战单位[n].气血 > self.参战单位[n].气血上限 then
        self.参战单位[n].气血 = self.参战单位[n].气血上限
      end


      --经脉结束处理
          if self:取奇经八脉是否有(n,"云龙真身龙息") then
             self.参战单位[n].法术暴击等级 = self.参战单位[n].法术暴击等级 + 2 --这里是0.2％的意思
          end
    end
    if self.参战单位[n].法术状态 == nil then
      self.参战单位[n].法术状态 = {}
    end
    if self.参战单位[n].法宝已扣 ~= nil then
      self.参战单位[n].法宝已扣 = {}
    end
	  --神迹回合结束移除异常
	  if self.参战单位[n].神迹==1 then
      local 异常状态名称=self:取异常状态法术()
      for m=1,#异常状态名称 do
        if self.参战单位[n].法术状态[异常状态名称[m]]~=nil then
          for w=1,#self.参战玩家 do
              发送数据(self.参战玩家[w].连接id,5507,{id=n,名称=异常状态名称[m]})
              观战状态[#观战状态+1]={id=n,名称=异常状态名称[m],序号=5507}
          end
          self:取消状态(异常状态名称[m],self.参战单位[n])
        end
      end
	  end
    for i, v in pairs(self.参战单位[n].法术状态) do
      self.参战单位[n].法术状态[i].回合=self.参战单位[n].法术状态[i].回合-1
      if self.参战单位[n].法术状态[i].回合<=0 then
          if i~="复活" then
            for w=1,#self.参战玩家 do
                发送数据(self.参战玩家[w].连接id,5507,{id=n,名称=i})
                观战状态[#观战状态+1]={id=n,名称=i,序号=5507}
            end
            self:取消状态(i,self.参战单位[n])
          end
          if i=="渡劫金身" and self.参战单位[n].气血>0 then
            for w=1,#self.参战玩家 do
              发送数据(self.参战玩家[w].连接id,5508,{id=n,气血=self.参战单位[n].最大气血})
              end
              self.参战单位[n].气血=self.参战单位[n].最大气血
          end
          if i=="复活" then
            for w=1,#self.参战玩家 do
              发送数据(self.参战玩家[w].连接id,5508,{id=n,气血=self.参战单位[n].最大气血})
              self.参战单位[n].气血=self.参战单位[n].最大气血
              self.参战单位[n].法术状态[i]=nil
            end
          end
      elseif i=="分身术" then
        self.参战单位[n].法术状态[i].破解=nil
      elseif i=="无尘扇" and self.参战单位[n].愤怒~=nil then
           local 愤怒=qz(self.参战单位[n].愤怒*0.1)
           if self.参战单位[n].愤怒~=nil then self.参战单位[n].愤怒=self.参战单位[n].愤怒-愤怒 end
           if self.参战单位[n].愤怒<0 then self.参战单位[n].愤怒=0 end
      elseif i=="乾坤玄火塔" then
        local 愤怒=qz(150*(qz(self.参战单位[n].法术状态[i].境界/5)*0.02+0.02))
        if self.参战单位[n].愤怒~=nil then self.参战单位[n].愤怒=self.参战单位[n].愤怒+愤怒 end
        if self.参战单位[n].愤怒>150 then self.参战单位[n].愤怒=150 end
      end
      法术状态[n]=DeepCopy(self.参战单位[n].法术状态)
      if self.参战单位[n].门派=="凌波城" then
        法术状态[n]["战意"]=self.参战单位[n].战意
      end
    end
    血量[n]={气血=self.参战单位[n].气血,气血上限=self.参战单位[n].气血上限 or self.参战单位[n].最大气血,最大气血=self.参战单位[n].最大气血,魔法=self.参战单位[n].魔法,最大魔法=self.参战单位[n].最大魔法,愤怒=self.参战单位[n].愤怒}
  end
  for n=1,#self.参战玩家 do
    self.参战玩家[n].断线等待=nil
    发送数据(self.参战玩家[n].连接id,5519,法术状态)
    发送数据(self.参战玩家[n].连接id,5520,血量)
  end
  self:设置命令回合()
  --观战结算
  if #观战状态>=1 then
    for n=1,#观战状态 do
        for i,v in pairs(self.观战玩家) do
          if 玩家数据[i] ~= nil then
            发送数据(玩家数据[i].连接id,观战状态[n].序号,观战状态[n])
            发送数据(玩家数据[i].连接id,5519,法术状态)
          end
        end
      -- for i=1,#self.观战玩家 do
      --   发送数据(self.观战玩家[i].连接id,观战状态[n].序号,观战状态[n])
      -- end
    end
  end
end

function 战斗处理类:数据处理(玩家id,序号,内容,参数)
  if 序号==5506 then
    self:逃跑事件处理(玩家id)
    return
  end
  if 序号 == 5510 then
    if 玩家数据[玩家id].观战 ~= nil and self.观战玩家[玩家id] ~= nil then
      if 自动遇怪[玩家id]~=nil then
        自动遇怪[玩家id]=os.time()
      end
      发送数据(玩家数据[玩家id].连接id,5505)
      玩家数据[玩家id].战斗=0
      玩家数据[玩家id].观战=nil
      玩家数据[玩家id].遇怪时间=os.time()+取随机数(10,20)
    end
    self.观战玩家[玩家id] = nil
    return
  end


 if 序号==5511 then

    if self.观战玩家~= nil then
      for i=1,#self.观战玩家 do
        if 玩家id == self.观战玩家[i].id then
          return
        end
      end
    end
    local 修改 = 内容.修改
    local 指令内容 ={}
    local 更改内容 ={}

           if  玩家数据[修改.id].子角色操作~=nil or 修改.id==玩家id then
              local 自动指令命令 = {下达=true,类型="攻击",目标=0,敌我=0,参数="",附加=""}
                   if 修改.已改参数 == "攻击" then
                     自动指令命令.类型 = "攻击"
                    elseif 修改.已改参数 == "防御" then
                      自动指令命令.类型 = "防御"
                    else
                      if 修改.已改附加 ~= nil then
                        自动指令命令 = {附加=修改.已改附加+0,目标=0,类型="法术",下达=true,敌我=0,参数=修改.已改参数}
                      end
                    end
                if  玩家数据[修改.id].子角色操作~=nil or 修改.id==玩家id then
                  if 修改.类型 == "角色" then
                      玩家数据[修改.id].角色.数据.自动指令=自动指令命令
                      玩家数据[修改.id].角色.数据.自动战斗=true
                      玩家数据[修改.id].角色.数据.默认法术=修改.已改参数
                   else
                     local bb编号X=玩家数据[修改.id].召唤兽:取编号(修改.认证码)
                     --print(修改.id)
                     --print(修改.认证码)
                      玩家数据[修改.id].召唤兽.数据[bb编号X].自动指令=自动指令命令
                      玩家数据[修改.id].召唤兽.数据[bb编号X].自动战斗=true
                      玩家数据[修改.id].召唤兽.数据[bb编号X].默认法术=修改.已改参数
                  end
               end
              local 参战编号 = 0
              local 参战编号1 = 0
               for n=1,#self.参战单位 do
                if self.参战单位[n].玩家id== 修改.id then
                 if self.参战单位[n].类型 == "角色" then
                     参战编号 = n
                  else
                     参战编号1 = n
                  end

                end
              end
                  if 参战编号~=0 and 修改.类型 == "角色"  then
                     self.加载数量=self.加载数量-1
                     self.参战单位[参战编号].自动战斗=true
                       self.参战单位[参战编号].自动指令 =  玩家数据[修改.id].角色.数据.自动指令
                        if self.参战单位[参战编号].自动指令~=nil then
                         self.参战单位[参战编号].指令=table.loadstring(table.tostring(self.参战单位[参战编号].自动指令))
                      end
                       指令内容[#指令内容+1]={id=参战编号,自动=self.参战单位[参战编号].自动指令}
                       更改内容[#更改内容+1]={id=参战编号,自动=self.参战单位[参战编号].自动战斗}
                   end

                   if 参战编号1~=0 and 修改.认证码~=nil then
                       self.参战单位[参战编号1].自动战斗=true
                        local bb编号X=玩家数据[修改.id].召唤兽:取编号(修改.认证码)
                        self.参战单位[参战编号1].自动指令 = 玩家数据[修改.id].召唤兽.数据[bb编号X].自动指令
                        if self.参战单位[参战编号1].自动指令~=nil then
                         self.参战单位[参战编号1].指令=table.loadstring(table.tostring(self.参战单位[参战编号1].自动指令))
                        end
                       指令内容[#指令内容+1]={id=参战编号1,自动=self.参战单位[参战编号1].自动指令}
                       更改内容[#更改内容+1]={id=参战编号1,自动=self.参战单位[参战编号1].自动战斗}
                   end
          发送数据(玩家数据[玩家id].连接id,5514,更改内容)
          发送数据(玩家数据[玩家id].连接id,5513,指令内容)
          常规提示(玩家id,"#Y/自动技能已变更完成")
          return
      end
    end




  if self.回合进程=="加载回合" then
    if 序号==5501 then
      self.加载数量=self.加载数量-1
      if self.加载数量<=0 then
        if self.战斗流程~=nil and #self.战斗流程==0 then
          self:设置命令回合()
        else
          self:发送加载流程()
        end
      end
    end
  elseif self.回合进程=="命令回合" then
    if 序号==5502 then
      self.加载数量=self.加载数量-1
      local 编号=self:取参战编号(玩家id,"角色")
      local 目标={编号}
      if self.参战单位[编号].召唤兽~=nil then
        目标[2]=self.参战单位[编号].召唤兽
      end
      if self.参战单位[编号].助战明细 ~= nil then
        for i=1,#self.参战单位[编号].助战明细 do
            目标[#目标+1] = self.参战单位[编号].助战明细[i]
        end
      end
      for n=1,#内容 do
        self.参战单位[目标[n]].指令=内容[n]
        self.参战单位[目标[n]].指令.下达=true
        self.参战单位[目标[n]].自动指令=table.loadstring(table.tostring(内容[n]))
       if self.参战单位[目标[n]].类型=="角色" and self.参战单位[目标[n]].助战编号 == nil then
          玩家数据[self.参战单位[目标[n]].玩家id].角色.数据.自动指令=table.loadstring(table.tostring(内容[n]))
        elseif self.参战单位[目标[n]].类型=="角色" and self.参战单位[目标[n]].助战编号 ~= nil then
          玩家数据[self.参战单位[目标[n]].玩家id].助战.数据[self.参战单位[目标[n]].助战编号].自动指令 = table.loadstring(table.tostring(内容[n]))
        -- elseif self.参战单位[目标[n]].类型=="孩子" then
        --   local bb编号=玩家数据[self.参战单位[目标[n]].玩家id].孩子:取编号(self.参战单位[目标[n]].认证码)
        --   玩家数据[self.参战单位[目标[n]].玩家id].孩子.数据[bb编号].自动指令=table.loadstring(table.tostring(内容[n]))
        elseif self.参战单位[目标[n]].类型=="召唤" then

        else
          -- if self.参战单位[目标[n]].玩家id~=nil then
            local bb编号=玩家数据[self.参战单位[目标[n]].玩家id].召唤兽:取编号(self.参战单位[目标[n]].认证码)
            玩家数据[self.参战单位[目标[n]].玩家id].召唤兽.数据[bb编号].自动指令=table.loadstring(table.tostring(内容[n]))
          -- end
        end
        if self.参战单位[目标[n]].指令.类型=="攻击" and self.参战单位[目标[n]].指令.目标==0 then
          self.参战单位[目标[n]].指令.目标= self:取单个敌方目标(n)
        end
        --table.print(self.参战单位[n].指令)
      end
      if self.加载数量<=0 then  --走这里
        self.回合进程="计算回合"
        self:设置执行回合()
      end
      --0914
    elseif 序号==5599 then
      local 编号=self:取参战编号(玩家id,"角色")
      self.参战单位[编号].道具类型="道具"
      发送数据(玩家数据[玩家id].连接id,5509,玩家数据[玩家id].道具:索要道具2(玩家id))
   elseif 序号==5504 then
      -- print("1")
      -- local 编号=self:取参战编号(玩家id,"角色")
      -- local 目标={编号}
      -- if self.参战单位[编号].召唤兽~=nil then
      --   目标[2]=self.参战单位[编号].召唤兽
      -- end
      -- self.参战单位[目标[2]].道具类型="道具"
      -- 发送数据(玩家数据[玩家id].连接id,5509,玩家数据[玩家id].道具:索要道具2(玩家id))
       发送数据(玩家数据[玩家id].连接id,5509,玩家数据[玩家id].道具:索要道具2(玩家id))
  elseif 序号==5508 then
      local 编号=self:取参战编号(玩家id,"角色")

      if 内容~=nil and 内容.编号~=nil then
         编号=内容.编号+编号-1

      end

      self.参战单位[编号].道具类型="法宝"
      发送数据(玩家数据[玩家id].连接id,5509,玩家数据[玩家id].道具:索要法宝1(玩家id,self.回合数))
    elseif 序号==5505 then --取召唤数据
      local 编号=0
      for n=1,#self.参战单位 do
        if self.参战单位[n].类型=="角色" and self.参战单位[n].玩家id==玩家id and self.参战单位[n].助战编号 == nil then
          编号=n
        end
      end
      if 编号==0 then
        return
      end
      发送数据(玩家数据[玩家id].连接id,5510,{玩家数据[玩家id].召唤兽.数据,self.参战单位[编号].召唤数量})
    elseif 序号==5507 then --设置自动战斗
      local 更改内容={}
      local 指令内容={}
      if 玩家数据[玩家id].角色.数据.自动战斗 then
        for n=1,#self.参战单位 do
          if self.参战单位[n].玩家id==玩家id  then
            self.参战单位[n].自动战斗=nil
            更改内容[#更改内容+1]={id=n,自动=self.参战单位[n].自动战斗}
          end
        end
        常规提示(玩家id,"#Y/你取消了自动战斗")
        玩家数据[玩家id].角色.数据.自动战斗=nil
        发送数据(玩家数据[玩家id].连接id,5514,更改内容)
      else
        玩家数据[玩家id].角色.数据.自动战斗=true
        local 更改=false
        for n=1,#self.参战单位 do
          if self.参战单位[n].玩家id==玩家id  then
            self.参战单位[n].自动战斗=true
            if  self.参战单位[n].指令~=nil and self.参战单位[n].指令.下达==false then
              self.参战单位[n].指令.下达=true
              更改=true
              if self.参战单位[n].自动指令~=nil then
                self.参战单位[n].指令=table.loadstring(table.tostring(self.参战单位[n].自动指令))
              else
                self.参战单位[n].指令.类型="攻击"
                self.参战单位[n].指令.目标= self:取单个敌方目标(n)
              end
              更改内容[#更改内容+1]={id=n,自动=self.参战单位[n].自动战斗}
              指令内容[#指令内容+1]={id=n,自动=self.参战单位[n].自动指令}
            end
          end
        end
        常规提示(玩家id,"#Y/你开启了自动战斗")
        发送数据(玩家数据[玩家id].连接id,5511)
        发送数据(玩家数据[玩家id].连接id,5513,指令内容)
        发送数据(玩家数据[玩家id].连接id,5514,更改内容)
        if 更改 then
          self.加载数量=self.加载数量-1
          if self.加载数量<=0 then
            self.回合进程="计算回合"
            self:设置执行回合()
          end
        end
      end
    end
  elseif self.回合进程=="执行回合" then
    if 序号==5503 then
      self.加载数量=self.加载数量-1
      self.执行等待=os.time()+10
      local 断线数量=0
      for n=1,#self.参战玩家 do
        if self.参战玩家[n].断线等待 then
          断线数量=断线数量+1
        end
      end
      if self.加载数量<=0 and self.回合进程~="结束回合" then
        self.回合进程="结束回合"
        self:结算处理()
      elseif self.加载数量<=断线数量 and self.回合进程~="结束回合" then
        self.回合进程="结束回合"
        self:结算处理()
      end
      if os.time() < self.最低执行时间 - 1 then
        封禁账号(玩家id,"1")
        广播消息({内容="#Y玩家id"..玩家id.."疑似使用跳过战斗被封号",频道="xt"})
        print(玩家id,"因疑似跳过战斗封号。回合期望结束时间:",os.time(),"预期结束时间:",self.最低执行时间 - 1)
      end
    elseif 序号==5507 then --设置自动战斗
      local 更改内容={}
      local 指令内容={}
      if 玩家数据[玩家id].角色.数据.自动战斗 then
        for n=1,#self.参战单位 do
          if self.参战单位[n].玩家id==玩家id then
            self.参战单位[n].自动战斗=nil
            更改内容[#更改内容+1]={id=n,自动=self.参战单位[n].自动战斗}
          end
        end
        常规提示(玩家id,"#Y/你取消了自动战斗")
        玩家数据[玩家id].角色.数据.自动战斗=nil
        发送数据(玩家数据[玩家id].连接id,5514,更改内容)
      else
        玩家数据[玩家id].角色.数据.自动战斗=true
        for n=1,#self.参战单位 do
          if self.参战单位[n].玩家id==玩家id then
            self.参战单位[n].自动战斗=true
            更改内容[#更改内容+1]={id=n,自动=self.参战单位[n].自动战斗}
            指令内容[#指令内容+1]={id=n,自动=self.参战单位[n].自动指令}
          end
        end
        常规提示(玩家id,"#Y/你开启了自动战斗")
        发送数据(玩家数据[玩家id].连接id,5513,指令内容)
        发送数据(玩家数据[玩家id].连接id,5514,更改内容)
      end
    end
  end
end

function 战斗处理类:设置执行回合()  --走这里
  local 临时速度={}
  self.执行对象={}
  local 临时速度1={}   -----0914
    for n=1,#self.参战单位 do
     if self.参战单位[n].招架~=nil and  self.参战单位[n].招架<0 then
       if self.参战单位[n].招架==-1 then   self.参战单位[n].招架 =10  end
       if self.参战单位[n].招架==-2 then   self.参战单位[n].招架 =20  end
    end
  end
  for n=1,#self.参战单位 do
    if self.参战单位[n].经脉有无 ~= nil and self.参战单位[n].经脉有无 then
        self:经脉回合开始处理(n)
    end
    if self.参战单位[n].洞察特性 ~= nil and 取随机数() <= self.参战单位[n].洞察特性*5  and self:取玩家战斗() and self.参战单位[n].主人 ~= nil and self.参战单位[self.参战单位[n].主人]~=nil then
      local 临时敌人 = self:取单个敌方目标(n)
      local 关键字 = "气血"
      if 取随机数(1,2) == 1 then
        关键字 = "魔法"
      end
      常规提示(self.参战单位[self.参战单位[n].主人].玩家id,"#Y/你的召唤兽发现#G/"..self.参战单位[临时敌人].名称.."#Y/当前#G/"..关键字.."#Y/剩余#G/"..self.参战单位[临时敌人][关键字].."点")
    elseif self.参战单位[n].灵动特性 ~= nil and self.参战单位[n].灵动次数 <3 and 取随机数() <= self.参战单位[n].灵动特性*5 then
      self.参战单位[n].灵动次数=self.参战单位[n].灵动次数+1
      local 临时友方 = self:取单个友方目标(n)
      self.战斗发言数据[#self.战斗发言数据+1]={id=n,内容=self.参战单位[临时友方].名称.."大傻吊你睡觉了么#24"}
    end
    --print("-------------------执行回合 指令",1,self.参战单位[n].名称,self.参战单位[n].指令.类型)
    临时速度[n]={速度=self.参战单位[n].速度,编号=n}
    if self.参战单位[n].指令==nil  then
      self.参战单位[n].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
    end
    if self.参战单位[n].指令.下达==false then
      self.参战单位[n].指令.下达=true
      self.参战单位[n].指令.类型="攻击"
      self.参战单位[n].指令.目标= self:取单个敌方目标(n)
    end
    -------------新的施法判定
    if self.参战单位[n].队伍==0 then
      local 临时数据 = self:NPC智能施法(self.战斗类型,n,self.参战单位[n].主动技能)
      if self.战斗脚本 and self.战斗脚本.NPC智能施法 then
        --self.战斗脚本:OnTurnReady(1)
        local 脚本执行结果=__gge.safecall(self.战斗脚本.NPC智能施法,self,n,self.参战单位[n],self.回合数)
        if 脚本执行结果 and 脚本执行结果.下达==true then
          临时数据=脚本执行结果
        end
      end
      if 临时数据.下达 then
        self.参战单位[n].指令.类型 = 临时数据.类型
        self.参战单位[n].指令.参数 = 临时数据.参数
        self.参战单位[n].指令.目标 = 临时数据.目标
      end
    end
  end
  table.sort(临时速度,function(a,b) return a.速度>b.速度 end )
  for n=1,#临时速度 do
    self.执行对象[n]=临时速度[n].编号
  end
  self.战斗流程={}
  self.执行等待=0
  self:执行计算()
  ------0914机制修改
  if self.回合中复活 then
    self.回合中复活=false
    local 速度减少={}
    --执行中复活单位去重
    self.执行中复活单位=数组去重(self.执行中复活单位)
    if  #self.是否执行行动==0 then
      self.执行中复活单位={}
    else
      for i=1,#self.执行中复活单位 do
        for n=1,#self.是否执行行动 do
          if self.执行中复活单位[i]==self.是否执行行动[n] then
            速度减少[#速度减少+1]=self.是否执行行动[n]
            break
          end
        end
      end
      table.sort(速度减少,function(a,b) return self.参战单位[a].速度>self.参战单位[b].速度 end )
      self.执行对象 = {}
      for n=1,#速度减少 do
        for i=1,#临时速度 do
          if 速度减少[n]==临时速度[i].编号  then
            self.执行对象[n]=临时速度[i].编号
            -- print(临时速度[i].速度)
          end
        end
      end
      速度减少={}
      self:执行计算2()
    end
  end

  self.执行中复活单位={}
  self.是否执行行动={}

  self:执行计算3()
--------------------
  self.执行等待=self.执行等待+os.time()
  local 法术状态={}
  for i=1,#self.参战玩家 do
    local 血量数据={}
    for n=1,#self.参战单位 do
      if self.参战单位[n].气血<0 then self.参战单位[n].气血=0 end
      if self.参战单位[n].气血上限==nil then self.参战单位[n].气血上限=self.参战单位[n].最大气血 end
	    if self.参战单位[n].气血上限<0 then self.参战单位[n].气血上限=0 end
      if self.参战单位[n].气血上限 > self.参战单位[n].最大气血 then
        self.参战单位[n].气血上限 = self.参战单位[n].最大气血
      end
      if self.参战单位[n].气血 > self.参战单位[n].气血上限 then
        self.参战单位[n].气血 = self.参战单位[n].气血上限
      end
      if self.参战单位[n].魔法<0 then self.参战单位[n].魔法=0 end
      -- if self.参战单位[n].玩家id==self.参战玩家[i].id then
      --   if self.参战单位[n].类型=="角色" and self.参战单位[n].助战编号==nil then
      --     血量数据[1]={气血=self.参战单位[n].气血,最大气血=self.参战单位[n].最大气血,气血上限=self.参战单位[n].气血上限,魔法=self.参战单位[n].魔法,最大魔法=self.参战单位[n].最大魔法,愤怒=self.参战单位[n].愤怒}
      --   elseif self.参战单位[n].逃跑==nil and self.参战单位[n].类型=="bb" then
      --     血量数据[2]={气血=self.参战单位[n].气血,最大气血=self.参战单位[n].最大气血,魔法=self.参战单位[n].魔法,最大魔法=self.参战单位[n].最大魔法}
      --   end
      -- end
      法术状态[n]=DeepCopy(self.参战单位[n].法术状态)
      if self.参战单位[n].门派=="凌波城" then
        法术状态[n]["战意"]=self.参战单位[n].战意
      end
    end
    --血量结算不放在这里，去回合结束时同步
    --发送数据(self.参战玩家[i].连接id,5506,血量数据)
    发送数据(self.参战玩家[i].连接id,5504,self.战斗流程)
    发送数据(self.参战玩家[i].连接id,5519,法术状态)
  end
  for i,v in pairs(self.观战玩家) do
    if 玩家数据[i] ~= nil then
      发送数据(玩家数据[i].连接id,5504,self.战斗流程)
      发送数据(玩家数据[i].连接id,5519,法术状态)
    end
  end
  self.加载数量=#self.参战玩家  - self.无人操作
  --平均一个战斗流程为6s，不够的话在这里再加
  self.执行等待=os.time()+10+#self.战斗流程*6
  self.最低执行时间=os.time()+#self.战斗流程*1-5
  self.回合进程="执行回合"
end

function 战斗处理类:NPC智能施法(战斗类型,编号,怪物技能)
  local 返回数据 = {类型="",目标=0,参数="",下达=false}
  local 临时封印技能 = {}
  local 临时特技技能 = {}
  local 临时辅助技能 = {}
  local 临时伤害技能 = {}
  local 临时变身技能 = {}
  local 是否选择技能 = false
  if #怪物技能>0 then
    for i=1,#怪物技能 do
      if 装备特技[怪物技能[i].名称]~=nil and self:取特技状态(编号) then  --自定义数据:特技表():取特技是否可用(怪物技能[i].名称) and
        临时特技技能[#临时特技技能+1]=怪物技能[i].名称
      elseif self:封印技能(怪物技能[i].名称) and self:取法术状态(编号) then
        临时封印技能[#临时封印技能+1]=怪物技能[i].名称
      elseif self:变身技能(怪物技能[i].名称) and self:取法术状态(编号) then
        临时变身技能[#临时变身技能+1]=怪物技能[i].名称
      elseif (self:恢复技能(怪物技能[i].名称) or self:增益技能(怪物技能[i].名称) or self:减益技能(怪物技能[i].名称)) and self:取法术状态(编号) then
        临时辅助技能[#临时辅助技能+1]=怪物技能[i].名称
      else
        if self:取法术状态(编号) then
          临时伤害技能[#临时伤害技能+1]=怪物技能[i].名称
        end
      end
    end
  end
  if not 判断是否为空表(self.参战单位[编号].追加法术) and self:取攻击状态(编号) then --优先判断是否有追加法术 如果有的话 只会平A
    返回数据.类型 = "攻击"
    返回数据.参数 = ""
    返回数据.目标 = self:取单个敌方目标(编号)
    返回数据.下达 = true
  elseif #怪物技能>0 then  --判断是否有怪物技能
    if not 判断是否为空表(临时封印技能) and  not 返回数据.下达 then  --优先判断封印技能
      local 当前技能 = 临时封印技能[取随机数(1,#临时封印技能)]
      local 取目标 = self:NPC_AI取敌方可封印单位(编号)
      if 取目标~=0 then
        返回数据.类型="法术"
        返回数据.参数 = 当前技能
        返回数据.目标 = 取目标
        返回数据.下达 = true
      end
    end
    if not 判断是否为空表(临时变身技能) and self.参战单位[编号].法术状态.变身==nil and not 返回数据.下达 then  --如果存在变身技能且没有变身状态，优先变身
      local 当前技能 = 临时变身技能[取随机数(1,#临时变身技能)]
      local 技能类型 = 取法术技能(当前技能)
      local 取目标 = 0
      if 技能类型[3] == 4 then
        取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"敌方")
      else
        取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"友方")
      end
      if 取目标~=0 then
        返回数据.类型="法术"
        返回数据.参数 = 当前技能
        返回数据.目标 = 取目标
        返回数据.下达 = true
      end
    end
    if not 判断是否为空表(临时辅助技能) and not 返回数据.下达 then  --在判断是否有辅助或者加血技能
      local 当前技能 = 临时辅助技能[取随机数(1,#临时辅助技能)]
      local 技能类型 = 取法术技能(当前技能)
      local 取目标 = 0
      if 技能类型[3] == 4 then
        取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"敌方")
      else
        取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"友方")
      end
      if 取目标~=0 then
        返回数据.类型="法术"
        返回数据.参数 = 当前技能
        返回数据.目标 = 取目标
        返回数据.下达 = true
      end
    end
    if not 判断是否为空表(临时伤害技能) and not 返回数据.下达 or (返回数据.下达 and  not 判断是否为空表(临时伤害技能) and 30<=取随机数()) then  --最后判断伤害类型技能
      local 当前技能 = 临时伤害技能[取随机数(1,#临时伤害技能)]
      local 技能类型 = 取法术技能(当前技能)
      local 取目标 = 0
      if 技能类型[3] == 4 then
        取目标 = self:取单个敌方目标(编号)
      else
        取目标 = self:取单个友方目标(编号)
      end
      if 取目标~=0 then
        返回数据.类型="法术"
        返回数据.参数 = 当前技能
        返回数据.目标 = 取目标
        返回数据.下达 = true
      end
    end
    if not 返回数据.下达 then
      -- 如果被封了法术没被封攻击，则执行攻击
      -- 横扫等休息状态下，没有办法防御
      if self:取攻击状态(编号) or self:取休息状态(编号) then
        返回数据.类型 = "攻击"
        返回数据.参数 = ""
        返回数据.目标 = self:取单个敌方目标(编号)
        返回数据.下达 = true
      else
        返回数据.类型="防御"
        返回数据.参数=""
        返回数据.目标=0
        返回数据.下达 = true
      end
    end
  end

  --判定指定场 特殊要求  --这边 按照你自己端的进行修改
  if 战斗类型 == 100004 and  self.参战单位[编号].变异 and self.回合数>=3 then  --封妖活动 达到3回合 变异怪逃跑
    返回数据.类型="逃跑"
    返回数据.目标=0
    返回数据.参数=""
    返回数据.下达=true
  elseif self.战斗类型==110002 and self.参战单位[编号].名称=="蚩尤" and self.回合数==1 then
    self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="不要做无畏挣扎\n赶紧#R/受死吧!"}
  elseif self.战斗类型==110005 and self.参战单位[编号].名称=="妖风" and self.回合数==1 then
    self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="不不不\n这#R/不可能!"}
  elseif self.战斗类型==110009 and self.参战单位[编号].名称=="白琉璃" and self.回合数==9 then
    self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="小东西\n你#Y/完蛋了!"}
  elseif self.战斗类型==100225 and self.参战单位[编号].门派=="神兽" and self.回合数==1 then
    self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="小吊毛\n想抓我?#3"}
  elseif self.战斗类型==100225 and self.参战单位[编号].门派=="神兽" and self.回合数==3 then
    self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="拜拜了\n看我逃跑#4"}
  elseif self.参战单位[编号].门派=="神兽" and self.回合数>=4 then
    返回数据.类型="逃跑"
    返回数据.目标=0
    返回数据.参数=""
    返回数据.下达=true
  elseif self.参战单位[编号].捉鬼变异 and self.回合数>=2 then  --抓鬼变异逃跑
    返回数据.类型="逃跑"
    返回数据.目标=0
    返回数据.参数=""
    返回数据.下达=true
  elseif self.参战单位[编号].精灵 and self.回合数==2 then   --精灵自爆
    返回数据.类型="法术"
    返回数据.目标= self:取单个敌方目标(编号)
    返回数据.参数="自爆"
    返回数据.下达=true
  elseif self.战斗类型==110000 and self.参战单位[编号].名称=="谛听" and self.回合数==1 then
    返回数据.类型="法术"
    返回数据.目标= self:取单个敌方目标(编号)
    返回数据.参数="观照万象"
    返回数据.下达=true
  elseif self.战斗类型==100011 and self.参战单位[编号].法术状态.变身==nil and (self.参战单位[编号].名称=="狮驼岭弟子" or self.参战单位[编号].名称=="狮驼岭护法") then
    返回数据.类型="法术"
    返回数据.目标= self:取单个友方目标(编号)
    返回数据.参数="变身"
    返回数据.下达=true
  elseif self.战斗类型==110008 and self.参战单位[编号].法术状态.变身==nil and self.参战单位[编号].名称==" 守门天兵 "  then
    返回数据.类型="法术"
    返回数据.目标= self:取单个友方目标(编号)
    返回数据.参数="变身"
    返回数据.下达=true
  elseif self.战斗类型==110008 and self.参战单位[编号].门派=="龙宫" and self.参战单位[编号].名称=="守门天将"and(self.回合数==1 or self.回合数==5 or self.回合数==10) then
    返回数据.类型="法术"
    返回数据.目标= self:取单个友方目标(编号)
    返回数据.参数="一苇渡江"
    返回数据.下达=true
  elseif self.战斗类型==110008 and self.参战单位[编号].门派=="化生寺" and self.参战单位[编号].名称=="守门天将"and(self.回合数==1 or self.回合数==5 or self.回合数==10) then
    返回数据.类型="法术"
    返回数据.目标= self:取单个友方目标(编号)
    返回数据.参数="金刚护体"
    返回数据.下达=true
  elseif self.战斗类型==110009 and self.参战单位[编号].名称=="白琉璃"and(self.回合数==10 or self.回合数==11 or self.回合数==12) then
    返回数据.类型="法术"
    返回数据.目标= self:取单个敌方目标(编号)
    返回数据.参数="五行制化"
    返回数据.下达=true
  elseif self.战斗类型==100027 and self.参战单位[编号].名称=="知了王" and  self:取封印状态(编号) or self.参战单位[编号].名称=="长生不死" and  self:取封印状态(编号) then
    local 是否封印 = self:取封印状态(编号,1)
    if 是否封印 ~= false  then
      返回数据.类型="特技"
      返回数据.目标=self:取单个友方目标(编号)
      返回数据.参数="晶清诀"
      返回数据.下达=true
     self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="小东西\n呦\n你#Y/还敢封我#4\n当刻晴不知道吗\n看我的晶清大法!"}
      -- self.参战单位[编号].红颜发言=nil
    end
    elseif self.战斗类型 == 100223 or self.战斗类型==100055 or self.战斗类型==100056 or self.战斗类型==110034 then
    local 是否封印 = self:取封印状态(编号,1)
    if 是否封印 ~= false and self:取封印状态1(0)>=3 then
      返回数据.类型="特技"
      返回数据.目标=self:取单个友方目标(编号)
      返回数据.参数="晶清诀"
      返回数据.下达=true
     self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="小东西\n呦\n你#Y/还敢封我#4\n当刻晴不知道吗\n看我的晶清大法!"}
    end
  elseif self.战斗类型 == 100224 then
    local 是否封印 = self:取封印状态(编号,1)
    if 是否封印 ~= false and (self.参战单位[编号].名称=="守门天兵" or self.参战单位[编号].名称=="执法天兵") then
      返回数据.类型="特技"
      返回数据.目标=self:取单个友方目标(编号)
      返回数据.参数="晶清诀"
      返回数据.下达=true
     self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="小东西\n呦\n你#Y/还敢封我#4\n当刻晴不知道吗\n看我的晶清大法!"}
    end
  elseif self.战斗类型==110014 and self.参战单位[编号].名称=="李彪" and self.回合数==5 then
      返回数据.类型="法术"
      返回数据.目标= self:取单个友方目标(编号)
      返回数据.参数="尸腐毒 "
      返回数据.下达=true
  elseif self.战斗类型 == 110014 then
    local 是否封印 = self:取封印状态(编号,1)
    if 是否封印 ~= false and self:取封印状态1(0)>=2 then
      返回数据.类型="特技"
      返回数据.目标=self:取单个友方目标(编号)
      返回数据.参数="晶清诀"
      返回数据.下达=true
     self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="小东西\n呦\n你#Y/还敢封我#4\n当刻晴不知道吗\n看我的晶清大法!"}
    end
  elseif 战斗类型 == 100017 then   --门派救援
    local 同门编号=0
    for i=1,#self.参战单位 do
      if self.参战单位[i].同门单位 then
        同门编号=i
        self.参战单位[i].指令.类型=""
      end
    end
    if 同门编号==0 then
      同门编号=self:取单个敌方目标(编号)
    end
    返回数据.类型="同门飞镖"
    返回数据.目标=同门编号
    返回数据.下达=true
  elseif not 判断是否为空表(临时特技技能) and self.战斗类型 == 110036 and self.参战单位[编号].愤怒 ~= nil and self.参战单位[编号].愤怒 >= 150 and
  self.回合数 >= 3 and  30<=取随机数() and self:取特技状态(编号) then --假人NPC战斗特技释放
    local 当前技能 = 临时特技技能[取随机数(1,#临时特技技能)]
    local 技能类型 = 取法术技能(当前技能)
    local 取目标 = 0
    if 技能类型[3] == 4 then
      取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"敌方")
    else
      取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"友方")
    end
    if 取目标~=0 then
      返回数据.类型="法术"
      返回数据.参数 = 当前技能
      返回数据.目标 = 取目标
      返回数据.下达 = true
    end
  elseif not 判断是否为空表(临时特技技能) and self.战斗类型 ~= 981001 and 取随机数()<=15 and self:取特技状态(编号) then --其他类型的时候 NPC战斗特技释放规则
    local 当前技能 = 临时特技技能[取随机数(1,#临时特技技能)]
    local 技能类型 = 取法术技能(当前技能)
    local 取目标 = 0
    if 技能类型[3] == 4 then
      取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"敌方")
    else
      取目标 = self:NPC_AI取目标队伍无指定增益状态(编号,当前技能,"友方")
    end
    if 取目标~=0 then
      返回数据.类型="法术"
      返回数据.参数 = 当前技能
      返回数据.目标 = 取目标
      返回数据.下达 = true
    end
  end
  return 返回数据
end

function 战斗处理类:NPC_AI取敌方可封印单位(编号)
  local 目标组={}
  for n=1,#self.参战单位 do
    if  self.参战单位[n].队伍~=self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) and not self.参战单位[n].不可封印 and
      not self.参战单位[n].鬼魂 and not self.参战单位[n].精神 and not self.参战单位[n].信仰 then
      if not self:取封印状态(n) then
        目标组[#目标组+1]=n
      end
    end
  end
  return  目标组[取随机数(1,#目标组)] or 0
end

function 战斗处理类:NPC_AI取敌方随机召唤兽(编号)
  local 目标组={}
  for n=1,#self.参战单位 do
    if  self.参战单位[n].队伍~=self.参战单位[编号].队伍 and self.参战单位[n].类型=="bb" then
      目标组[#目标组+1]=n
    end
  end
  return  目标组[取随机数(1,#目标组)] or self:取单个敌方目标(编号)
end

function 战斗处理类:NPC_AI取目标队伍无指定增益状态(编号,状态名称,类型)
  local 目标组={}
  if 类型=="友方" then
    for n=1,#self.参战单位 do
      if  self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) and self.参战单位[n].法术状态[状态名称]==nil then
        目标组[#目标组+1]=n
      end
    end
  else
    for n=1,#self.参战单位 do
      if  self.参战单位[n].队伍~=self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) and self.参战单位[n].法术状态[状态名称]==nil then
        目标组[#目标组+1]=n
      end
    end
  end
  return  目标组[取随机数(1,#目标组)] or 0
end

function 战斗处理类:NPC_AI目标数量(攻击方,技能名称,等级,战斗类型)
  if 攻击方.队伍==0 then
    if 技能名称=="浪涌" and (攻击方.名称=="初出茅庐地煞星" or 攻击方.名称=="小有所成地煞星" or 攻击方.名称=="伏虎斩妖地煞星" or 攻击方.名称=="御风神行地煞星" or 攻击方.名称=="履水吐焰地煞星" or 攻击方.名称=="知了王" or 攻击方.名称=="知了先锋" or 攻击方.名称=="小知了王") then
        self.临时人数=3
    elseif 技能名称=="浪涌" and (攻击方.名称=="初出茅庐地煞星" or 攻击方.名称=="小有所成地煞星" or 攻击方.名称=="伏虎斩妖地煞星" or 攻击方.名称=="御风神行地煞星" or 攻击方.名称=="履水吐焰地煞星" or 攻击方.名称=="知了王" or 攻击方.名称=="知了先锋" or 攻击方.名称=="小知了王" or 攻击方.名称=="乾坤" or 攻击方.名称=="乾坤无行") then
        self.临时人数=3
    elseif 技能名称=="推气过宫" and (攻击方.名称=="泼法金刚 " or 攻击方.名称=="空慈方丈") then
        self.临时人数=10
    elseif 技能名称=="活血" and 攻击方.名称=="泼法金刚 " then
        self.临时人数=5
    elseif 技能名称=="翻江搅海" and 攻击方.名称=="海绵宝宝 " then
        self.临时人数=3
    elseif 战斗类型 == 100247 and 技能名称=="锢魂术" and 攻击方.名称=="洛川鬼" then
        self.临时人数=10
    elseif 战斗类型 == 100247 and 技能名称=="百爪狂杀" and 攻击方.名称=="洛川鬼" then
        self.临时人数=10
    elseif 战斗类型 == 100248 and 技能名称=="善恶有报" and 攻击方.名称=="妩媚狐仙" then
        self.临时人数=3
    elseif 战斗类型 == 100256 and 技能名称=="鹰击" and (攻击方.名称=="卷帘大将(心魔)" or 攻击方.名称=="王福来") then
       self.临时人数=10
    elseif 战斗类型 == 100263 and 技能名称=="鹰击" and 攻击方.名称=="王福来" then
       self.临时人数=10
    elseif 战斗类型 == 100261 and 技能名称=="推气过宫" and 攻击方.名称=="空度禅师" then
       self.临时人数=10
    elseif 战斗类型 == 100261 and 技能名称=="地涌金莲" and 攻击方.名称=="地涌夫人" then
       self.临时人数=10
    end
  end
end

function 战斗处理类:发送加载流程()
  local 法术状态 = {}
  for i=1,#self.参战玩家 do
    local 血量数据={}
    for n=1,#self.参战单位 do
      -- --print(n,self.参战单位[n].玩家id,self.参战玩家[i].id)
      if self.参战单位[n].玩家id==self.参战玩家[i].id then
        if self.参战单位[n].类型=="角色" and self.参战单位[n].助战编号==nil  then
          血量数据[1]={气血=self.参战单位[n].气血,最大气血=self.参战单位[n].最大气血,气血上限=self.参战单位[n].气血上限 or self.参战单位[n].最大气血,魔法=self.参战单位[n].魔法,最大魔法=self.参战单位[n].最大魔法,愤怒=self.参战单位[n].愤怒}
        elseif self.参战单位[n].类型=="bb" then
          血量数据[2]={气血=self.参战单位[n].气血,最大气血=self.参战单位[n].最大气血,魔法=self.参战单位[n].魔法,最大魔法=self.参战单位[n].最大魔法}
        end
      end
      法术状态[n]=DeepCopy(self.参战单位[n].法术状态)
      if self.参战单位[n].门派=="凌波城" then
        法术状态[n]["战意"]=self.参战单位[n].战意
      end
    end
    发送数据(self.参战玩家[i].连接id,5504,self.战斗流程)
    发送数据(self.参战玩家[i].连接id,5506,血量数据)
    发送数据(self.参战玩家[i].连接id,5519,法术状态)
  end
  self.执行等待=self.执行等待+os.time()
  self.加载数量=#self.参战玩家 - self.无人操作
  self.回合进程="执行回合"
end

function 战斗处理类:执行计算()

    -----------------七宝计算
  for n=1,#self.参战单位 do
      local 境界=self:取指定法宝境界(n,"七宝玲珑灯") or 0
      local 目标2=0
          目标2=self:取单个友方目标1(n)
              --目标2=self:取单个友方目标1(n)
       if  self.参战单位[n].类型=="角色"  and self.参战单位[n].气血>0  and 境界~=0 and 目标2~=0 then
         if    self:取指定法宝(n,"七宝玲珑灯",1) then
              --print(目标2)
              if  目标2~=0 then
              self:恢复技能计算(n,"七宝玲珑灯",境界)
            end
          end
      end
  end

--------------------------------------------------------------
  local 生命之泉回复 = {}
  local 再生回复 = {}
  local 普渡众生回复= {}
  local 宝烛回复={}
  local 毒扣血={}  --每回合清空记录
  for n=1,#self.参战单位 do
     if self.参战单位[n] ~= nil and self.参战单位[n].法术状态 ~= nil and self.参战单位[n].法术状态.汲魂~=nil then
         if self:取目标状态(n,n,2) then
            local 气血 = 0
            气血=self.参战单位[n].等级*2
             气血=self:取恢复气血(self.参战单位[n].法术状态.汲魂.编号,n,气血)
             self.战斗流程[#self.战斗流程+1]={流程=100,攻击方=n,气血=气血,挨打方={}}
             self:增加气血(n,气血)
           end
       end

     if self.参战单位[n].法术状态.分身术~=nil then
     local 编号=self.参战单位[n].法术状态.分身术.攻击编号
      if 编号~=nil and self:取奇经八脉是否有(编号,"调息") then
       if self:取目标状态(n,n,2) then
          气血=self:取恢复气血(n,n,self.参战单位[n].最大气血*0.1)
          self.战斗流程[#self.战斗流程+1]={流程=100,攻击方=n,气血=气血,挨打方={}}
          self:增加气血(n,气血)
          self:增加魔法(n,qz(self.参战单位[n].最大魔法*0.5))
         end
       end
       end
     if self.参战单位[n].法术状态.不灭1~=nil then
       if self:取目标状态(n,n,2) then
          气血=self:取恢复气血(n,n,self.参战单位[n].等级*4+10)
          self.战斗流程[#self.战斗流程+1]={流程=100,攻击方=n,气血=气血,挨打方={}}
          self:增加气血(n,气血)
       end
       end

      if self.参战单位[n] ~= nil and self.参战单位[n].法术状态 ~= nil and self.参战单位[n].法术状态.生命之泉~=nil then
        local 编号=self.参战单位[n].法术状态.生命之泉.攻击编号
         if self:取目标状态(n,n,2) then
            local 气血 = 0
            气血=self.参战单位[n].法术状态.生命之泉.等级*0.5+(self.参战单位[编号].灵力*0.1)
            气血=self:取恢复气血(self.参战单位[n].法术状态.生命之泉.编号,n,气血)
            self:增加气血(n,气血)
            生命之泉回复.攻击方=n
            生命之泉回复[#生命之泉回复+1]={挨打方=n,恢复气血=气血}
           end
       end
            if self.参战单位[n] ~= nil and self.参战单位[n].法术状态 ~= nil and self.参战单位[n].法术状态.煞气诀1~=nil then
         if self:取目标状态(n,n,2) then
            local 气血 = 0
            气血=self.参战单位[n].法术状态.煞气诀1.等级+15
             气血=self:取恢复气血(self.参战单位[n].法术状态.煞气诀1.编号,n,气血)
             self.战斗流程[#self.战斗流程+1]={流程=100,攻击方=n,气血=气血,挨打方={}}
             self:增加气血(n,气血)
           end
       end

      if self.参战单位[n] ~= nil and self.参战单位[n].法术状态 ~=nil and self.参战单位[n].法术状态.普渡众生~=nil then
        local 编号=self.参战单位[n].法术状态.普渡众生.攻击编号
        if self:取目标状态(n,n,2) then
          local 气血 = 0
          气血=self.参战单位[n].法术状态.普渡众生.等级*2+(self.参战单位[编号].灵力*0.1)
            气血=self:取恢复气血(self.参战单位[n].法术状态.普渡众生.编号,n,气血)
            self:增加气血(n,气血)
			      self:恢复伤势(n,气血)
            普渡众生回复.攻击方=n
            普渡众生回复[#普渡众生回复+1]={挨打方=n,恢复气血=气血,恢复伤势=气血}
         end
      end
        if self.参战单位[n].再生~=nil then
          if self:取目标状态(n,n,2) then
            local 气血=self.参战单位[n].再生
            --气血=self:取恢复气血(n,n,气血)
            -- self.战斗流程[#self.战斗流程+1]={流程=100,攻击方=n,气血=气血,挨打方={}}
            self:增加气血(n,气血)
            再生回复.攻击方=n
            再生回复[#再生回复+1]={挨打方=n,恢复气血=气血}
          end
        end
        if self.参战单位[n].法术状态.炼气化神~=nil then
          if self:取目标状态(n,n,2) then
            self:增加魔法(n,qz(self.参战单位[n].法术状态.炼气化神.等级/2))
          end
        end
                if self.参战单位[n].法术状态.魔息术~=nil then
          if self:取目标状态(n,n,2) then
            self:增加魔法(n,qz(self.参战单位[n].法术状态.魔息术.等级/2))
          end
        end

        if self.参战单位[n].冥思~=nil then
          if self:取目标状态(n,n,2) then
            self:增加魔法(n,qz(self.参战单位[n].冥思))
          end
        end

        if self.参战单位[n].法术状态.尸腐毒~=nil then
          local 编号=self.参战单位[n].法术状态.尸腐毒.攻击编号
          if self:取目标状态(n,n,2) then
            if 编号~=nil and self:取奇经八脉是否有(编号,"入骨") and self.参战单位[n].法术状态.尸腐毒.回合<=1 then
              local 气血=qz(self.参战单位[n].气血*0.05)
              self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=n,气血=0,挨打方={}}
              self.战斗流程[#self.战斗流程].死亡=self:减少气血(n,气血)
              self.战斗流程[#self.战斗流程].气血=气血
			        self.战斗流程[#self.战斗流程].伤势=气血
            end
            local 气血=self.参战单位[n].法术状态.尸腐毒.等级*4+self.参战单位[编号].伤害*0.1
            if self:取符石组合效果(n,"柳暗花明") then
                气血=qz(气血*(100-self:取符石组合效果(n,"柳暗花明"))/100)
            end
            self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=n,气血=0,挨打方={}}
            self.战斗流程[#self.战斗流程].死亡=self:减少气血(n,气血)
            self.战斗流程[#self.战斗流程].气血=气血
		        self:造成伤势(n,气血)
            self.战斗流程[#self.战斗流程].伤势=气血
            if self:取指定法宝(编号,"九幽",1) then
              if self:取指定法宝境界(编号,"九幽")>=0 then
                local 目标=self:取多个友方目标(编号,编号,10,"尸腐毒")
                if #目标 == 0 then
                  return
                end
                local 目标数 = #目标
                self.战斗流程[#self.战斗流程].受益方 = {}
                for i=1,目标数 do
                  local 气血=0
                  local 法宝层数 = self:取指定法宝境界(编号,"九幽") + 1
                  if 编号~=nil and self:取奇经八脉是否有(编号,"幽光") then
                  self.战斗流程[#self.战斗流程].受益方[i]={受益方=目标[i],伤害=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].气血*0.006*法宝层数+300)}
                  气血=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].气血*0.006*法宝层数+300)
                  else
                  self.战斗流程[#self.战斗流程].受益方[i]={受益方=目标[i],伤害=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].气血*0.006*法宝层数)}
                  气血=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].气血*0.006*法宝层数)
                  end
                  气血=self:取恢复气血(编号,目标[i],气血)
                  self:增加气血(目标[i],气血)
                end
            end
          end
        end
      end
          if self:取指定法宝(n,"宝烛",1,1) then
          local 境界= self:取指定法宝境界(n,"宝烛",1,1)
         if self:取目标状态(n,n,2) and self.参战单位[n].最大气血*0.7 > self.参战单位[n].气血 then
            气血=self:取恢复气血(n,n,境界*10+8)
            self:增加气血(n,气血)
            宝烛回复.攻击方=n
            宝烛回复[#宝烛回复+1]={挨打方=n,恢复气血=气血}
          -- end
        end
      end
      if self.参战单位[n].法术状态.紧箍咒~=nil then
        local 编号=self.参战单位[n].法术状态.紧箍咒.攻击编号
        if self:取目标状态(n,n,2) then
          local 气血=self.参战单位[n].法术状态.紧箍咒.等级+20+self.参战单位[编号].灵力*0.1
          if 编号~=nil and self:取奇经八脉是否有(编号,"默诵") then
			    气血=气血*2
          end
          self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=n,气血=0,挨打方={}}
		  self:造成伤势(n,气血)
          self.战斗流程[#self.战斗流程].死亡=self:减少气血(n,气血)
          self.战斗流程[#self.战斗流程].气血=气血
		  self.战斗流程[#self.战斗流程].伤势=气血
        end
      end

      if self.参战单位[n].法术状态.忘忧~=nil then
        if self:取目标状态(n,n,2) then
          local 气血=qz(self.参战单位[n].等级*3)
          self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=n,气血=0,挨打方={}}
          self.战斗流程[#self.战斗流程].死亡=self:减少气血(n,气血)
          self.战斗流程[#self.战斗流程].气血=气血
        end
      end

      if self.参战单位[n].法术状态.利刃~=nil then
        if self:取目标状态(n,n,2) then
          local 气血=30
          self.参战单位[n].魔法=self.参战单位[n].魔法-气血
          if self.参战单位[n].魔法<=0 then self.参战单位[n].魔法=0 end
          end
       end

      if self.参战单位[n].法术状态.雾杀~=nil then
        local 编号=self.参战单位[n].法术状态.雾杀.攻击编号
        if self:取目标状态(n,n,2) then
          local 气血=self.参战单位[n].法术状态.雾杀.等级*2+(self.参战单位[编号].灵力*0.2)
          self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=n,气血=0,挨打方={}}
          self.战斗流程[#self.战斗流程].死亡=self:减少气血(n,气血)
          self.战斗流程[#self.战斗流程].气血=气血
        end
        if self:取目标状态(n,n,2) and self.参战单位[n].法术状态.雾杀.回合<=1 and 编号~=nil and self:取奇经八脉是否有(编号,"破杀") then
        local 气血=qz(self.参战单位[n].法术状态.雾杀.等级*2*2.5)
          self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=n,气血=0,挨打方={}}
          self.战斗流程[#self.战斗流程].死亡=self:减少气血(n,气血)
          self.战斗流程[#self.战斗流程].气血=气血
       end
      end

        if self.参战单位[n].法术状态.夺魄令~=nil then
        local 编号=self.参战单位[n].法术状态.夺魄令.攻击编号
        if self:取目标状态(n,n,2) and self.参战单位[n].法术状态.夺魄令.回合<=1 and 编号~=nil and self:取奇经八脉是否有(编号,"陷阱") then
        local 气血=self.参战单位[编号].等级*2
        if self.参战单位[编号].气血<=qz(self.参战单位[编号].最大气血*0.5) then
            气血=气血*2
        end
            气血=self:取恢复气血(编号,编号,气血)
            self.战斗流程[#self.战斗流程+1]={流程=100,攻击方=编号,气血=气血,挨打方={}}
            self:增加气血(编号,气血)
       end
       end

        if self.参战单位[n].气血<=0 and  self.参战单位[n].类型=="角色" and self.参战单位[n].门派=="方寸山" and  self.参战单位[n].毫毛次数<3 and self:取指定法宝(n,"救命毫毛",1) and self:取指定法宝境界(n,"救命毫毛")>=取随机数(1,60) then
        气血=qz(self.参战单位[n].最大气血*0.2)
        self.战斗流程[#self.战斗流程+1]={流程=111,攻击方=n,名称=self.参战单位[n].名称,技能="救命毫毛"}
        self:增加气血(n,气血)
        self.战斗流程[#self.战斗流程+1]={流程=110,攻击方=n,气血=气血,挨打方={}}
        self.参战单位[n].毫毛次数=self.参战单位[n].毫毛次数+1
        end

        if self.参战单位[n].法术状态.摇头摆尾~=nil then
        if self:取目标状态(n,n,2) then
          -- self:增加魔法(n,qz(self.参战单位[n].法术状态.炼气化神.等级/2))
          local 气血=self.参战单位[n].法术状态.摇头摆尾.等级*5
          self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=n,气血=0,挨打方={}}
          self.战斗流程[#self.战斗流程].死亡=self:减少气血(n,气血)
          self.战斗流程[#self.战斗流程].气血=气血
          local 死亡状态=self:减少气血(n,气血)
        end
      end


      if self.参战单位[n].法术状态.毒~=nil then
        if self:取目标状态(n,n,2) then
          local 气血=qz(self.参战单位[n].气血*0.1)
          if 气血<1 then
            气血=1
          elseif 气血>self.参战单位[n].法术状态.毒.等级*20 then
            气血=self.参战单位[n].法术状态.毒.等级*20
          end
          local 魔法=qz(self.参战单位[n].魔法*0.05)
          if 魔法<1 then
            魔法=0
          end
          if self:取符石组合效果(n,"柳暗花明") then
            气血=qz(气血*(100-self:取符石组合效果(n,"柳暗花明"))/100)
            魔法=qz(魔法*(100-self:取符石组合效果(n,"柳暗花明"))/100)
          end
          self.参战单位[n].魔法=self.参战单位[n].魔法-魔法
          if self.参战单位[n].魔法<=0 then
            self.参战单位[n].魔法=0
          end
          local 死亡状态=self:减少气血(n,气血)
          毒扣血.攻击方=n
          毒扣血[#毒扣血+1]={挨打方=n,气血=气血,死亡=死亡状态}
        end
      end
    end
  --群体结算发送
    if 判断是否为空表(生命之泉回复)~=true then
       self.战斗流程[#self.战斗流程+1]={流程=1000,攻击方=生命之泉回复.攻击方,挨打方={}}
      for n=1,#生命之泉回复 do
        self.战斗流程[#self.战斗流程].挨打方[n]={气血=生命之泉回复[n].恢复气血,挨打方=生命之泉回复[n].挨打方}
      end
    end
    if 判断是否为空表(再生回复)~=true then
       self.战斗流程[#self.战斗流程+1]={流程=1000,攻击方=再生回复.攻击方,挨打方={}}
      for n=1,#再生回复 do
        self.战斗流程[#self.战斗流程].挨打方[n]={气血=再生回复[n].恢复气血,挨打方=再生回复[n].挨打方}
      end
    end
    if 判断是否为空表(普渡众生回复)~=true then
       self.战斗流程[#self.战斗流程+1]={流程=1000,攻击方=普渡众生回复.攻击方,挨打方={}}
      for n=1,#普渡众生回复 do
        self.战斗流程[#self.战斗流程].挨打方[n]={气血=普渡众生回复[n].恢复气血,伤势=普渡众生回复[n].恢复伤势,挨打方=普渡众生回复[n].挨打方}
      end
    end
   if 判断是否为空表(宝烛回复)~=true then
       self.战斗流程[#self.战斗流程+1]={流程=1000,攻击方=宝烛回复.攻击方,挨打方={}}
      for n=1,#宝烛回复 do
        self.战斗流程[#self.战斗流程].挨打方[n]={气血=宝烛回复[n].恢复气血,挨打方=宝烛回复[n].挨打方}
      end
    end
    if 判断是否为空表(毒扣血)~=true then
      self.战斗流程[#self.战斗流程+1]={流程=1020,攻击方=毒扣血.攻击方,气血=0,挨打方={}}
      for n=1,#毒扣血 do
        self.战斗流程[#self.战斗流程].挨打方[n]={气血=毒扣血[n].气血,挨打方=毒扣血[n].挨打方,死亡=毒扣血[n].死亡}
      end
    end
  --群体结算发送
  for n=1,#self.参战单位 do
    if self.参战单位[n].队伍==0 and self.参战单位[n].气血>=1 then
      if self.战斗类型==100009 then
        if self:取阵营数量(0)<=5 and self.参战单位[n].名称~="喽罗"  then
          self:执行怪物召唤(n,1,0,5-self:取阵营数量(0))
        end
      elseif self.战斗类型==100125 then
        if self:取阵营数量(0)<=5 and self.参战单位[n].名称~="灵感分身小弟"  then
          self:执行怪物召唤(n,5,0,5-self:取阵营数量(0))
        end
      elseif self.战斗类型==110014 and self.回合数==6 then
        if self:取阵营数量(0)<=5 then
          self:执行怪物召唤(n,8,0,5-self:取阵营数量(0))
        end
         elseif self.战斗类型==100001 then
          if self.参战单位[n].模型=="狂豹兽形" and  self.参战单位[n].最大气血*0.5<=self.参战单位[n].气血 and 取随机数()<=10   then
            self.参战单位[n].模型="狂豹人形"
            self.参战单位[n].名称="狂豹人形"
            self.战斗流程[#self.战斗流程+1]={流程=623,攻击方=n,参数="狂豹人形"}
           elseif self.参战单位[n].模型=="猫灵兽形" and self.参战单位[n].最大气血*0.5<=self.参战单位[n].气血 and 取随机数()<=10 then
            self.参战单位[n].模型="猫灵人形"
            self.参战单位[n].名称="猫灵人形"
            self.战斗流程[#self.战斗流程+1]={流程=623,攻击方=n,参数="猫灵人形"}
           elseif self.参战单位[n].模型=="犀牛将军兽形" and self.参战单位[n].最大气血*0.5<=self.参战单位[n].气血 and 取随机数()<=10 then
            self.参战单位[n].模型="犀牛将军人形"
            self.参战单位[n].名称="犀牛将军人形"
            self.战斗流程[#self.战斗流程+1]={流程=623,攻击方=n,参数="犀牛将军人形"}
            end
            elseif self.战斗类型==110014 then
            if self.参战单位[n].名称=="李彪" and self.回合数==5 then
            self.参战单位[n].模型="骷髅怪"
            self.参战单位[n].名称="李彪"
            self.战斗流程[#self.战斗流程+1]={流程=623,攻击方=n,参数="骷髅怪"}
          end
      end
    end
  end
  self:执行计算1()
end

function 战斗处理类:取阵营数量(队伍)
  local 数量=0
  for n=1,#self.参战单位 do
    if self.参战单位[n].队伍==队伍 and self.参战单位[n].气血>=1 and self.参战单位[n].捕捉==nil and self.参战单位[n].逃跑==nil then
      数量=数量+1
    end
  end
  return 数量
end


function 战斗处理类:加载召唤单位1(单位组,id,队伍)
local 位置记录1=0
local 位置记录2=0
local 位置=0
local 数量=0
for n=1,#self.参战单位 do
  if self.参战单位[n].队伍==队伍 then
    for i=12,20 do
      if self.参战单位[n].位置==i and self.参战单位[n].气血<=0 then
          位置记录1=i
          break
      elseif self.参战单位[n].位置==i and self.参战单位[n].气血>=1 then
          位置记录2=i
      end
    end
  end
end
if 位置记录1~=0 then
  位置=位置记录1
elseif 位置记录2~=0 then
  位置=位置记录2
else
   位置=12
end
self.参战单位[id]={}
self.参战单位[id].名称=单位组.名称
self.参战单位[id].模型=单位组.模型
self.参战单位[id].等级=单位组.等级
self.参战单位[id].变异=单位组.变异
self.参战单位[id].队伍=队伍
self.参战单位[id].位置=位置
self.参战单位[id].类型="召唤"
self.参战单位[id].法防=单位组.法防
self.参战单位[id].玩家id=0
self.参战单位[id].分类="野怪"
self.参战单位[id].附加阵法="普通"
self.参战单位[id].伤害=单位组.伤害
self.参战单位[id].命中=单位组.伤害
self.参战单位[id].防御=单位组.防御
self.参战单位[id].速度=单位组.速度
self.参战单位[id].灵力=单位组.灵力
self.参战单位[id].躲闪=单位组.躲闪
self.参战单位[id].气血=单位组.气血
self.参战单位[id].最大气血=单位组.气血
self.参战单位[id].魔法=单位组.魔法
self.参战单位[id].最大魔法=单位组.魔法
self.参战单位[id].躲闪=单位组.躲闪
self.参战单位[id].技能=单位组.技能
self.参战单位[id].物伤减少=单位组.物伤减少
self.参战单位[id].法伤减少=单位组.法伤减少
self.参战单位[id].躲避减少=单位组.躲避减少
self.参战单位[id].主动技能={}
for i=1,#单位组.主动技能 do
self.参战单位[id].主动技能[i]={名称=单位组.主动技能[i],等级=单位组.等级+10}
end
self.参战单位[id].已加技能={}
self.参战单位[id].法术状态={}
self.参战单位[id].奇经八脉={}
self.参战单位[id].追加法术={}
self.参战单位[id].附加状态={}
if self.参战单位[id].主动技能==nil then
self.参战单位[id].主动技能={}
end
if self.参战单位[id].符石技能效果==nil then
self.参战单位[id].符石技能效果={}
end
self.参战单位[id].特技技能={}
self.参战单位[id].战意=0
self.参战单位[id].法暴=0
self.参战单位[id].法防=0
self.参战单位[id].特技技能={}
self.参战单位[id].法暴=0
self.参战单位[id].法防=0
self.参战单位[id].必杀=1
self.参战单位[id].驱怪=0
self.参战单位[id].慈悲效果=0
self.参战单位[id].攻击修炼=0
self.参战单位[id].法术修炼=0
self.参战单位[id].武器伤害=0
self.参战单位[id].符石组合={}
self.参战单位[id].怒击效果=false
self.参战单位[id].防御修炼=0
self.参战单位[id].抗法修炼=0
self.参战单位[id].猎术修炼=0
self.参战单位[id].毫毛次数=0
self.参战单位[id].法宝佩戴={}
self.参战单位[id].攻击五行=""
self.参战单位[id].防御五行=""
self.参战单位[id].攻击五行=""
self.参战单位[id].防御五行=""
self.参战单位[id].修炼数据={法修=0,抗法=0,攻击=0,猎术=0}
if self.参战单位[id].命中==nil then self.参战单位[id].命中=self.参战单位[id].伤害 end
for i=1,#灵饰战斗属性 do
self.参战单位[id][灵饰战斗属性[i]]=0
end
self:添加技能属性(self.参战单位[id],self.参战单位[id].技能)
self.参战单位[id].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
end

function 战斗处理类:加载召唤单位2(单位组,id,队伍)
local 位置记录1=0
local 位置记录2=0
local 位置=0
local 数量=0
for n=1,#self.参战单位 do
  if self.参战单位[n].队伍==队伍 then
    for i=11,20 do
      if self.参战单位[n].位置==i and self.参战单位[n].气血<=0 then
          位置记录1=i
          break
      elseif self.参战单位[n].位置==i and self.参战单位[n].气血>=1 then
          位置记录2=i
      end
    end
  end
end
if 位置记录1~=0 then
  位置=位置记录1
elseif 位置记录2~=0 then
  位置=位置记录2
else
   位置=11
end
self.参战单位[id]={}
self.参战单位[id].名称=单位组.名称
self.参战单位[id].模型=单位组.模型
self.参战单位[id].等级=单位组.等级
self.参战单位[id].变异=单位组.变异
self.参战单位[id].队伍=队伍
self.参战单位[id].位置=位置
self.参战单位[id].类型="召唤"
self.参战单位[id].法防=单位组.法防
self.参战单位[id].玩家id=0
self.参战单位[id].分类="野怪"
self.参战单位[id].附加阵法="普通"
self.参战单位[id].伤害=单位组.伤害
self.参战单位[id].命中=单位组.伤害
self.参战单位[id].防御=单位组.防御
self.参战单位[id].速度=单位组.速度
self.参战单位[id].灵力=单位组.灵力
self.参战单位[id].躲闪=单位组.躲闪
self.参战单位[id].气血=单位组.气血
self.参战单位[id].最大气血=单位组.气血
self.参战单位[id].魔法=单位组.魔法
self.参战单位[id].最大魔法=单位组.魔法
self.参战单位[id].躲闪=单位组.躲闪
self.参战单位[id].技能=单位组.技能
self.参战单位[id].物伤减少=单位组.物伤减少
self.参战单位[id].法伤减少=单位组.法伤减少
self.参战单位[id].躲避减少=单位组.躲避减少
self.参战单位[id].主动技能={}
for i=1,#单位组.主动技能 do
self.参战单位[id].主动技能[i]={名称=单位组.主动技能[i],等级=单位组.等级+10}
end
self.参战单位[id].已加技能={}
self.参战单位[id].法术状态={}
self.参战单位[id].奇经八脉={}
self.参战单位[id].追加法术={}
self.参战单位[id].附加状态={}
if self.参战单位[id].主动技能==nil then
self.参战单位[id].主动技能={}
end
if self.参战单位[id].符石技能效果==nil then
self.参战单位[id].符石技能效果={}
end
if self.参战单位[id].名称=="牛幺" and self.参战单位[id].模型=="牛幺" then
self.参战单位[id].主动技能={"烈火"}
end
self.参战单位[id].特技技能={}
self.参战单位[id].战意=0
self.参战单位[id].法暴=0
self.参战单位[id].法防=0
self.参战单位[id].特技技能={}
self.参战单位[id].法暴=0
self.参战单位[id].法防=0
self.参战单位[id].必杀=1
self.参战单位[id].驱怪=0
self.参战单位[id].慈悲效果=0
self.参战单位[id].攻击修炼=0
self.参战单位[id].法术修炼=0
self.参战单位[id].武器伤害=0
self.参战单位[id].符石组合={}
self.参战单位[id].怒击效果=false
self.参战单位[id].防御修炼=0
self.参战单位[id].抗法修炼=0
self.参战单位[id].猎术修炼=0
self.参战单位[id].毫毛次数=0
self.参战单位[id].法宝佩戴={}
self.参战单位[id].攻击五行=""
self.参战单位[id].防御五行=""
self.参战单位[id].攻击五行=""
self.参战单位[id].防御五行=""
self.参战单位[id].修炼数据={法修=0,抗法=0,攻击=0,猎术=0}
if self.参战单位[id].命中==nil then self.参战单位[id].命中=self.参战单位[id].伤害 end
for i=1,#灵饰战斗属性 do
self.参战单位[id][灵饰战斗属性[i]]=0
end
self:添加技能属性(self.参战单位[id],self.参战单位[id].技能)
self.参战单位[id].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
end


function 战斗处理类:加载召唤单位(单位组,id,队伍)
  local 位置=0
  local 起始={}
  local 数量=0
  for n=1,#self.参战单位 do
    if self.参战单位[n].队伍==队伍 then
      起始[#起始+1]=n
    end
  end
  for n=1,#起始 do
    if 起始[n]==id then
       位置=n
    end
  end
  if 位置==0 then
    位置=#起始+1
  end
   self.参战单位[id]={}
   self.参战单位[id].名称=单位组.名称
   self.参战单位[id].模型=单位组.模型
   self.参战单位[id].等级=单位组.等级
   self.参战单位[id].变异=单位组.变异
   self.参战单位[id].队伍=队伍
   self.参战单位[id].位置=位置
   self.参战单位[id].参战等级=单位组.参战等级
   self.参战单位[id].类型="bb"
   self.参战单位[id].法防=单位组.法防
   self.参战单位[id].玩家id=0
   self.参战单位[id].分类="野怪"
   self.参战单位[id].附加阵法="普通"
   self.参战单位[id].伤害=单位组.伤害
   self.参战单位[id].命中=单位组.伤害
   self.参战单位[id].防御=单位组.防御
   self.参战单位[id].速度=单位组.速度
   self.参战单位[id].灵力=单位组.灵力
   self.参战单位[id].躲闪=单位组.躲闪
   self.参战单位[id].气血=单位组.气血
   self.参战单位[id].武器=单位组.武器
   self.参战单位[id].染色方案=单位组.染色方案
   self.参战单位[id].染色组=单位组.染色组
   self.参战单位[id].锦衣=单位组.锦衣
   self.参战单位[id].武器染色方案=单位组.武器染色方案
   self.参战单位[id].武器染色组=单位组.武器染色组
   self.参战单位[id].最大气血=单位组.气血
   self.参战单位[id].魔法=单位组.魔法
   self.参战单位[id].最大魔法=单位组.魔法
   self.参战单位[id].躲闪=单位组.躲闪
   self.参战单位[id].技能=单位组.技能
   self.参战单位[id].物伤减少=单位组.物伤减少
   self.参战单位[id].法伤减少=单位组.法伤减少
   self.参战单位[id].躲避减少=单位组.躲避减少
   self.参战单位[id].主动技能={}
   if 单位组.角色 then
      self.参战单位[id].类型="系统角色"
   end
   for i=1,#单位组.主动技能 do
      self.参战单位[id].主动技能[i]={名称=单位组.主动技能[i],等级=单位组.等级+10}
   end
     self.参战单位[id].已加技能={}
     self.参战单位[id].法术状态={}
     self.参战单位[id].奇经八脉={}
     self.参战单位[id].追加法术={}
     self.参战单位[id].附加状态={}
     if self.参战单位[id].主动技能==nil then
          self.参战单位[id].主动技能={}
     end
     self.参战单位[id].特技技能={}
     self.参战单位[id].战意=0
     self.参战单位[id].法暴=0
     self.参战单位[id].法防=0
     self.参战单位[id].必杀=1
     self.参战单位[id].特技技能={}
     self.参战单位[id].法防=0
     self.参战单位[id].驱怪=0
     self.参战单位[id].慈悲效果=0
     self.参战单位[id].攻击修炼=0
     self.参战单位[id].法术修炼=0
    if self.参战单位[id].符石技能效果==nil then
    self.参战单位[id].符石技能效果={}
    end
     self.参战单位[id].怒击效果=false
     self.参战单位[id].防御修炼=0
     self.参战单位[id].抗法修炼=0
     self.参战单位[id].猎术修炼=0
     self.参战单位[id].毫毛次数=0
     self.参战单位[id].法宝佩戴={}
     self.参战单位[id].攻击五行=""
     self.参战单位[id].防御五行=""
     self.参战单位[id].攻击五行=""
     self.参战单位[id].防御五行=""
     self.参战单位[id].修炼数据={法修=0,抗法=0,攻击=0,猎术=0}
     if self.参战单位[id].命中==nil then self.参战单位[id].命中=self.参战单位[id].伤害 end
     for i=1,#灵饰战斗属性 do
         self.参战单位[id][灵饰战斗属性[i]]=0
     end
  self:添加技能属性(self.参战单位[id],self.参战单位[id].技能)
  self.参战单位[id].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
end
function 战斗处理类:执行怪物召唤(编号,类型,队伍,次数)
  local id组=self:取阵亡id组(队伍)
  if 类型==1 then --星宿战斗召唤
    for n=1,次数 do
      local 临时id=id组[n]
      if 临时id==nil then --新增位置
        临时id=#self.参战单位+1
      end
      local 临时数据=self:召唤数据设置(1,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end
  elseif 类型==2 then
    for n=1,次数 do
      local 临时id=id组[n]
      if 临时id==nil then --新增位置
        临时id=#self.参战单位+1
      end
      local 临时数据=self:召唤数据设置(2,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end
  elseif 类型==3 then
    for n=1,次数 do
      local 临时id=id组[n]
      if 临时id==nil then --新增位置
        临时id=#self.参战单位+1
      end
      local 临时数据=self:召唤数据设置(3,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end
  elseif 类型==4 then
    for n=1,次数 do
      local 临时id=id组[n]
      if 临时id==nil then --新增位置
        临时id=#self.参战单位+1
      end
      local 临时数据=self:召唤数据设置(4,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end

      elseif 类型==6 then
    for n=1,次数 do
        临时id=#self.参战单位+1
      local 临时数据=self:召唤数据设置(6,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位1(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end

   elseif 类型==7 then
    for n=1,次数 do
      临时id=#self.参战单位+1
      local 临时数据=self:召唤数据设置(7,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位2(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end

    elseif 类型==8 then
    for n=1,次数 do
      local 临时id=id组[n]
      if 临时id==nil then --新增位置
        临时id=#self.参战单位+1
      end
      local 临时数据=self:召唤数据设置(8,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end

  elseif 类型==5 then
    for n=1,次数 do
      local 临时id=id组[n]
      if 临时id==nil then --新增位置
        临时id=#self.参战单位+1
      end
      local 临时数据=self:召唤数据设置(5,self.参战单位[编号].等级,编号)
      self.执行等待=self.执行等待+5
      self:加载召唤单位(临时数据,临时id,队伍)
      if id组[n]==nil then
        self:设置队伍区分(队伍)
      end
      self.战斗流程[#self.战斗流程+1]={流程=607,攻击方=编号,挨打方={{挨打方=临时id,队伍=队伍,数据=self:取加载信息(临时id)}}}
    end
  end
end

function 战斗处理类:取阵亡id组(队伍)
  local 队伍表={}
  for n=1,#self.参战单位 do
    if self.参战单位[n].队伍==队伍 and self.参战单位[n].法术状态.复活==nil and (self.参战单位[n].气血<=0 or self.参战单位[n].逃跑~=nil or self.参战单位[n].捕捉~=nil) then
      队伍表[#队伍表+1]=n
    end
  end
  return 队伍表
end

function 战斗处理类:召唤数据设置(类型,等级,编号)
  if 类型==1 then --星宿的天兵
    return self:取召唤类型1(等级,编号)
  elseif 类型==2 then
    return self:取召唤类型2(等级,编号)
  elseif 类型==3 then
    return self:取召唤类型3(等级,编号)
  elseif 类型==4 then
    return self:取召唤类型4(等级,编号)
  elseif 类型==5 then
    return self:取召唤类型5(等级,编号)
  elseif 类型==6 then
    return self:取召唤类型6(等级,编号)
  elseif 类型==7 then
    return self:取召唤类型7(等级,编号)
  elseif 类型==8 then
    return self:取召唤类型8(等级,编号)
  end
end

function 战斗处理类:取召唤类型1(等级,编号)
  等级=等级-5
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="喽罗"
    ,模型="天兵"
    ,伤害=等级*15
    ,气血=等级*300
    ,灵力=等级*8
    ,速度=等级*5
    ,防御=等级*2
    ,法防=等级*0.6
    ,躲闪=等级*2
    ,魔法=20000
    ,等级=等级
    ,技能={}
    ,主动技能=取随机法术(3)
  }
  return 召唤单位
end

function 战斗处理类:取召唤类型2(等级,编号)
  等级=等级-5
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="怨灵"
    ,模型="进阶幽灵"
    ,伤害=等级*5
    ,气血=等级*等级
    ,灵力=等级*5
    ,速度=等级*3
    ,防御=等级*2
    ,法防=等级*0.6
    ,躲闪=等级*2
    ,魔法=200
    ,等级=等级
    ,技能={}
    ,主动技能={}
  }
  if 编号~=nil and self:取奇经八脉是否有(编号,"腐蚀") then
    召唤单位.伤害=qz(召唤单位.伤害*1.1)
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"焕然") then
    召唤单位.气血=qz(召唤单位.气血*1.15)
  end
  return 召唤单位
end

function 战斗处理类:取召唤类型3(等级,编号)
  等级=等级-5
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="幻魔"
    ,模型="巴蛇"
    ,伤害=等级*10
    ,气血=等级*等级+500
    ,灵力=等级*5
    ,速度=等级*3
    ,防御=等级*2
    ,法防=等级*0.6
    ,躲闪=等级*2
    ,魔法=200
    ,等级=等级
    ,技能={}
    ,主动技能={}
  }
  if 编号~=nil and self:取奇经八脉是否有(编号,"腐蚀") then
    召唤单位.伤害=qz(召唤单位.伤害*1.1)
  end
  return 召唤单位
end

function 战斗处理类:取召唤类型4(等级,编号)
  等级=等级-5
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="猴子猴孙"
    ,模型="巨力神猿"
    ,伤害=1--等级*10
    ,气血=等级*等级+500
    ,灵力=等级*5
    ,速度=等级*3
    ,防御=等级*2
    ,法防=等级*0.6
    ,躲闪=等级*2
    ,魔法=200
    ,等级=等级
    ,技能={}
    ,主动技能={}
  }
  return 召唤单位
end

function 战斗处理类:取召唤类型5(等级,编号)
  等级=等级-5
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="灵感分身小弟"
  ,模型="神天兵"
  ,角色=true
  ,武器=取武器数据("雷神",100)
  ,伤害=等级*12+500
  ,气血=等级*30
  ,灵力=等级*8
  ,速度=等级*4.5
  ,防御=等级*4
  ,法防=等级*0.8
  ,躲闪=等级*4
  ,魔法=200
  ,等级=等级
  ,技能={"高级感知"}
  ,主动技能=取随机法术(5)
  }
  return 召唤单位
end

function 战斗处理类:取召唤类型6(等级,编号,id)
  local id = self.发起id
  等级=玩家数据[id].角色.数据.等级
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="牛虱"
    ,模型="牛虱"
    ,伤害=玩家数据[id].角色.数据.伤害
    ,气血=玩家数据[id].角色.数据.最大气血
    ,灵力=玩家数据[id].角色.数据.灵力
    ,速度=玩家数据[id].角色.数据.速度
    ,防御=玩家数据[id].角色.数据.防御
    ,法防=玩家数据[id].角色.数据.法防
    ,躲闪=等级*4
    ,魔法=玩家数据[id].角色.数据.最大魔法
    ,等级=等级
    ,技能={"高级必杀","高级连击","高级强力","高级感知","高级偷袭"}
    ,主动技能={}
  }
  -- if 编号~=nil and self:取奇经八脉是否有(编号,"腐蚀") then
  --   召唤单位.伤害=qz(召唤单位.伤害*1.1)
  -- end
  return 召唤单位
end

function 战斗处理类:取召唤类型7(等级,编号,id)
  local id = self.发起id
  等级=玩家数据[id].角色.数据.等级
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="牛幺"
    ,模型="牛幺"
    ,伤害=玩家数据[id].角色.数据.伤害
    ,气血=玩家数据[id].角色.数据.最大气血
    ,灵力=玩家数据[id].角色.数据.灵力
    ,速度=玩家数据[id].角色.数据.速度
    ,防御=玩家数据[id].角色.数据.防御
    ,法防=玩家数据[id].角色.数据.法防
    ,躲闪=等级*4
    ,魔法=玩家数据[id].角色.数据.最大魔法
    ,等级=等级
    ,技能={"法术连击","法术暴击"}
    ,主动技能={"烈火"}
  }
  -- if 编号~=nil and self:取奇经八脉是否有(编号,"腐蚀") then
  --   召唤单位.伤害=qz(召唤单位.伤害*1.1)
  -- end
  return 召唤单位
end

function 战斗处理类:取召唤类型8(等级,编号,id)
  if 等级<1 then 等级=1 end
  local 召唤单位={
    名称="野鬼喽罗"
    ,模型="野鬼"
    ,伤害=1000
    ,气血=50000
    ,灵力=650
    ,速度=400
    ,防御=500
    ,法防=500
    ,躲闪=500
    ,魔法=99999
    ,等级=65
    ,技能={}
    ,主动技能=取随机法术鬼(8)
  }
  return 召唤单位
end

function 战斗处理类:执行计算1()
  for n=1,#self.执行对象 do
    local 编号=self.执行对象[n]
    if self.参战单位[编号].法术状态.后发制人~=nil then
      self.参战单位[编号].指令.类型=""
      self:物攻技能计算(编号,"后发制人",self:取技能等级(编号,"后发制人"))
    end
    if self.参战单位[编号].观照万象 ~= nil then
    self.参战单位[编号].观照万象 = self.参战单位[编号].观照万象 -1
    if self.参战单位[编号].观照万象 <= 0 then
    self.参战单位[编号].观照万象 = nil
    end
    end

    if self.参战单位[编号].扶摇万里 ~= nil then
    self.参战单位[编号].扶摇万里 = self.参战单位[编号].扶摇万里 -1
    if self.参战单位[编号].扶摇万里 <= 0 then
    self.参战单位[编号].扶摇万里 = nil
    end
    end

    if self.参战单位[编号].碎玉弄影 ~= nil then
    self.参战单位[编号].碎玉弄影 = self.参战单位[编号].碎玉弄影 -1
    if self.参战单位[编号].碎玉弄影 <= 0 then
    self.参战单位[编号].碎玉弄影 = nil
    end
    end

    if self.参战单位[编号].顺势而为 ~= nil then
    self.参战单位[编号].顺势而为 = self.参战单位[编号].顺势而为 -1
    if self.参战单位[编号].顺势而为 <= 0 then
    self.参战单位[编号].顺势而为 = nil
    end
    end

    if self.参战单位[编号].波澜不惊 ~= nil then
    self.参战单位[编号].波澜不惊 = self.参战单位[编号].波澜不惊 -1
    if self.参战单位[编号].波澜不惊 <= 0 then
    self.参战单位[编号].波澜不惊 = nil
    end
    end

    if self.参战单位[编号].渡劫金身 ~= nil then
    self.参战单位[编号].渡劫金身 = self.参战单位[编号].渡劫金身 -1
    if self.参战单位[编号].渡劫金身 <= 0 then
    self.参战单位[编号].渡劫金身 = nil
    end
    end

        if self.参战单位[编号].其疾如风 ~= nil then
    self.参战单位[编号].其疾如风 = self.参战单位[编号].其疾如风 -1
    if self.参战单位[编号].其疾如风 <= 0 then
    self.参战单位[编号].其疾如风 = nil
    end
    end

        if self.参战单位[编号].其徐如林 ~= nil then
    self.参战单位[编号].其徐如林 = self.参战单位[编号].其徐如林 -1
    if self.参战单位[编号].其徐如林 <= 0 then
    self.参战单位[编号].其徐如林 = nil
    end
    end

        if self.参战单位[编号].不动如山  ~= nil then
    self.参战单位[编号].不动如山  = self.参战单位[编号].不动如山  -1
    if self.参战单位[编号].不动如山  <= 0 then
    self.参战单位[编号].不动如山  = nil
    end
    end

        if self.参战单位[编号].侵掠如火 ~= nil then
    self.参战单位[编号].侵掠如火 = self.参战单位[编号].侵掠如火 -1
    if self.参战单位[编号].侵掠如火 <= 0 then
    self.参战单位[编号].侵掠如火 = nil
    end
    end

    if self.参战单位[编号].魑魅缠身 ~= nil then
    self.参战单位[编号].魑魅缠身 = self.参战单位[编号].魑魅缠身 -1
    if self.参战单位[编号].魑魅缠身 <= 0 then
    self.参战单位[编号].魑魅缠身 = nil
    end
    end

    if self.参战单位[编号].清风望月 ~= nil then
    self.参战单位[编号].清风望月 = self.参战单位[编号].清风望月 -1
    if self.参战单位[编号].清风望月 <= 0 then
    self.参战单位[编号].清风望月 = nil
    end
    end

    if self.参战单位[编号].雷浪穿云 ~= nil then
    self.参战单位[编号].雷浪穿云 = self.参战单位[编号].雷浪穿云 -1
    if self.参战单位[编号].雷浪穿云 <= 0 then
    self.参战单位[编号].雷浪穿云 = nil
    end
    end

    if self.参战单位[编号].无敌牛妖 ~= nil then
    self.参战单位[编号].无敌牛妖 = self.参战单位[编号].无敌牛妖 -1
    if self.参战单位[编号].无敌牛妖 <= 0 then
    self.参战单位[编号].无敌牛妖 = nil
    end
    end

    if self.参战单位[编号].无敌牛虱 ~= nil then
    self.参战单位[编号].无敌牛虱 = self.参战单位[编号].无敌牛虱 -1
    if self.参战单位[编号].无敌牛虱 <= 0 then
    self.参战单位[编号].无敌牛虱 = nil
    end
    end

    if self.参战单位[编号].凋零之歌 ~= nil then
    self.参战单位[编号].凋零之歌 = self.参战单位[编号].凋零之歌 -1
    if self.参战单位[编号].凋零之歌 <= 0 then
    self.参战单位[编号].凋零之歌 = nil
    end
    end

    if self.参战单位[编号].煞气诀 ~= nil then
    self.参战单位[编号].煞气诀 = self.参战单位[编号].煞气诀 -1
    if self.参战单位[编号].煞气诀 <= 0 then
    self.参战单位[编号].煞气诀 = nil
    end
    end


  end

  for n=1,#self.执行对象 do

  ----------0914机制修改
    if self.全局结束==nil and self:取行动状态1(self.执行对象[n]) == false  then

          local 编号1=self.执行对象[n]
          self.是否执行行动[#self.是否执行行动+1]=编号1
      end
      --------------------------------
    if self.全局结束==nil and self:取行动状态(self.执行对象[n])  then
      local 编号=self.执行对象[n]
      if self.参战单位[编号].指令==nil then
      self.参战单位[编号].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
      end
      if self.参战单位[编号].指令.下达 then
      if self.参战单位[编号].模型 =="牛幺" or self.参战单位[编号].标记 == 100080 then
      if math.random(1,1) == 1 then
      if self.参战单位[编号].主动技能[1] ~= "" then
      self.参战单位[编号].指令.类型="法术"
      else
      self.参战单位[编号].指令.类型="攻击"
      end
      else
      self.参战单位[编号].指令.类型="攻击"
      end
      end

        -- if self.参战单位[编号].法术状态.疯狂 or self.参战单位[编号].法术状态.错乱 then
        --   if self.参战单位[编号].指令.类型~="防御" then
        --     self.参战单位[编号].指令.类型="攻击"
        --     self.参战单位[编号].指令.目标=self:取单个敌方目标(编号)
        --   end
        -- end
        if self.参战单位[编号].法术状态.反间之计~=nil and 取随机数()<=50 then
          local 临时友方 = self:取单个友方目标(编号)
          if 临时友方 ~= 0 then
            self.参战单位[编号].指令.类型="攻击"
            self.参战单位[编号].指令.目标=临时友方
          else
            self.参战单位[编号].指令.类型="防御"
            self.参战单位[编号].指令.目标=0
          end
        end
        if self.参战单位[编号].法术状态.发瘟匣~=nil then
          if self.参战单位[编号].指令.类型~="防御" then
            self.参战单位[编号].指令.类型="攻击"
            self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
          end
        end
        if self.参战单位[编号].法术状态.落魄符~=nil and 取随机数()<=50 then
          self.参战单位[编号].指令.类型="攻击"
          self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
        end
        if self.参战单位[编号].法术状态.错乱~=nil and 取随机数()<=50 then
          self.参战单位[编号].指令.类型="攻击"
          self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
        end
        if self.参战单位[编号].法术状态.锋芒毕露~=nil  then
          self.参战单位[编号].指令.目标=self.参战单位[编号].法术状态.目标id
        end
        if self.参战单位[编号].法术状态.诱袭~=nil  then
          self.参战单位[编号].指令.类型="攻击"
          self.参战单位[编号].指令.目标=self.参战单位[编号].法术状态.目标id
        end
        if self.参战单位[编号].法术状态.无魂傀儡~=nil and 取随机数()<=30 or self.参战单位[编号].法术状态.断线木偶~=nil and 取随机数()<=30 then
        -- if self.参战单位[编号].法术状态.攻击编号~=nil  then
        self.参战单位[编号].指令.类型="攻击"
        self.参战单位[编号].指令.目标=self.参战单位[编号].法术状态.攻击编号
        -- end
        end
        if self.参战单位[编号].法术状态.鬼泣~=nil and self.参战单位[编号].类型~="角色" and 35>=取随机数() then
        self.参战单位[编号].指令.类型="逃跑"


        elseif self.参战单位[编号].法术状态.惊魂铃~=nil and self.参战单位[编号].类型~="角色" and 取随机数()<=30 then
        self.参战单位[编号].指令.类型="逃跑"
        end

         if self.参战单位[编号].指令.类型=="攻击" and self.参战单位[self.执行对象[n]].指令.附加 == "友伤" then--普通攻击

          local 目标1=self.参战单位[self.执行对象[n]].指令.目标
          if self:取攻击状态(self.执行对象[n]) then
               self:普通攻击计算(self.执行对象[n],1,true)
             end
           end
           -- 0914 平A溅射特效流部分完善
        if self.参战单位[编号].指令.类型=="攻击" then--普通攻击
          local 怒击=false
          local 目标1=self.参战单位[self.执行对象[n]].指令.目标
          if self:取攻击状态(self.执行对象[n])  then
            if self.参战单位[self.参战单位[self.执行对象[n]].指令.目标]~=nil and self.参战单位[self.执行对象[n]].法术状态.反间之计==nil and self.参战单位[self.参战单位[self.执行对象[n]].指令.目标].队伍==self.参战单位[编号].队伍 then
              self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
              目标1=self.参战单位[self.执行对象[n]].指令.目标
            end
            if self:取目标状态(self.执行对象[n],目标1,1) == false then
              self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
            end
            if  self.参战单位[编号].理直气壮~=nil and 取随机数()<=40 then
              self.参战单位[编号].指令.参数="理直气壮"
              self:法术计算(self.执行对象[n],1)
              if self.参战单位[编号].怒击效果 and self:取攻击状态(self.执行对象[n]) then
                self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
                self:普通攻击计算(self.执行对象[n],1)
                self.参战单位[编号].怒击触发 = nil
              end
            elseif  self.参战单位[编号].连击~=nil and self.参战单位[编号].连击>=取随机数() then
              self.参战单位[编号].指令.参数="高级连击"
              self:法术计算(self.执行对象[n],1)
              if #self.参战单位[编号].追加法术>0 and 取随机数()<=10 and self:取攻击状态(self.执行对象[n]) and self:取奇经八脉是否有(编号,"逐胜") == false then
                  self.参战单位[编号].指令.类型="法术"
                  self.参战单位[编号].指令.参数=self.参战单位[编号].追加法术[取随机数(1,#self.参战单位[编号].追加法术)].名称
                  self:法术计算(self.执行对象[n],1)
              end
              if self.参战单位[编号].怒击效果 and self:取攻击状态(self.执行对象[n]) then
                self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
                self:普通攻击计算(self.执行对象[n],1)
                self.参战单位[编号].怒击触发 = nil
              end
            else
              怒击=self:普通攻击计算(self.执行对象[n],1)
              if self.参战单位[编号].怒击效果 and 怒击 and self:取攻击状态(self.执行对象[n]) then
                self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
                self:普通攻击计算(self.执行对象[n],1)
              end
            end
            if self.参战单位[编号].嗜血追击~=nil and self:取行动状态(self.执行对象[n]) and self:取目标状态(self.执行对象[n],self.参战单位[self.执行对象[n]].指令.目标,3)==false then
                目标=self:取单个敌方目标(编号)
                 if 目标~=0 then
                  self.参战单位[self.执行对象[n]].指令.目标=目标
                  self:普通攻击计算(self.执行对象[n],1)
                end
            end
            if self.参战单位[编号].溅射人数~=nil and self.参战单位[编号].溅射人数~=0 and self:取奇经八脉是否有(编号,"逐胜") == false  then
                目标=self.参战单位[self.执行对象[n]].指令.目标
                if 目标==0 or 目标==nil then
                  目标=self:取单个敌方目标(编号)
                end
                if 目标~=0 then
                  self.溅射伤害 = self:取基础物理伤害(编号,目标)
                  self.溅射最终伤害 = self:取最终物理伤害(编号,目标,self.溅射伤害)
                  self.溅射伤害值 =self:取伤害结果(编号,目标,self.溅射最终伤害.伤害,self.溅射最终伤害.暴击,保护)
                  if self:取玩家战斗() then
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射*0.5
                  else
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射
                  end
                  self:物理同时多个攻击(编号,目标,self.伤害输出,self.参战单位[编号].溅射人数,名称)--编号,伤害,数量,名称)
                end
            end
            if  ((self:取指定法宝境界(编号,"嗜血幡")~=false and (取随机数(1,30)<=self:取指定法宝境界(编号,"嗜血幡")*2) and self:取指定法宝(编号,"嗜血幡",1,1))) and self:取行动状态(self.执行对象[n]) and self:取目标状态(self.执行对象[n],目标1,1) and self:取奇经八脉是否有(编号,"逐胜")~=true then
              目标=self:取单个敌方目标(编号)
              if 目标~=0 then
                self.参战单位[self.执行对象[n]].指令.目标=目标
                if 编号~=nil and self.参战单位[编号].法宝佩戴~=nil and #self.参战单位[编号].法宝佩戴~=nil and self.参战单位[编号].类型=="角色" then
                    local 序列 = 0
                    for i=1,#self.参战单位[编号].法宝佩戴 do
                      if self.参战单位[编号].法宝佩戴[i].名称=="嗜血幡" then
                        序列=i
                      end
                    end
                    self:扣除法宝灵气(编号,序列,1)
                end

                怒击=self:普通攻击计算(self.执行对象[n],1)
                if 怒击 and self.参战单位[编号].怒击效果 then
                  目标=self:取单个敌方目标(编号)
                  self.参战单位[self.执行对象[n]].指令.目标=目标
                  if self:取目标状态(self.执行对象[n],目标,1) and self:取行动状态(self.执行对象[n])  then
                    self:普通攻击计算(self.执行对象[n],1)
                    self.参战单位[self.执行对象[n]].指令.目标=目标1
                  end
                end
              end

              if self.参战单位[编号].溅射~=nil and self.参战单位[编号].溅射~=0 and self:取奇经八脉是否有(编号,"逐胜") == false  then
                  目标=self.参战单位[self.执行对象[n]].指令.目标
                  if 目标==0 or 目标==nil then
                    目标=self:取单个敌方目标(编号)
                  end
                  if 目标~=0 then
                    self.溅射伤害 = self:取基础物理伤害(编号,目标)
                    self.溅射最终伤害 = self:取最终物理伤害(编号,目标,self.溅射伤害)
                    self.溅射伤害值 =self:取伤害结果(编号,目标,self.溅射最终伤害.伤害,self.溅射最终伤害.暴击,保护)
                  if self:取玩家战斗() then
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射*0.5
                  else
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射
                  end
                    self:物理同时多个攻击(编号,目标,self.伤害输出,self.参战单位[编号].溅射人数,名称)--编号,伤害,数量,名称)
                  end
              end
          end

            if 编号~=nil and self:取奇经八脉是否有(编号,"风刃妖风") then
              目标=self.参战单位[self.执行对象[n]].指令.目标
              self:物理同时多个攻击(编号,目标,1000,10,名称)--编号,伤害,数量,名称)
            end
            if 编号~=nil and self:取奇经八脉是否有(编号,"逐胜") then
              目标=self:取单个敌方目标(编号)
              if 目标~=0 then
                self.参战单位[self.执行对象[n]].指令.目标=目标
                if self:取目标状态(self.执行对象[n],目标,1) and self:取行动状态(self.执行对象[n])  then
                  self:普通攻击计算(self.执行对象[n],1)
                  self.参战单位[self.执行对象[n]].指令.目标=目标1
                end
              end
            end

            if self.参战单位[编号].套装追加概率 == nil then
              self.参战单位[编号].套装追加概率 = 0
            end
            if #self.参战单位[编号].追加法术>0 and 取随机数()<=self.参战单位[编号].套装追加概率 and self:取攻击状态(self.执行对象[n]) and self:取奇经八脉是否有(编号,"逐胜") == false then
              self.参战单位[编号].指令.类型="法术"
              self.参战单位[编号].指令.参数=self.参战单位[编号].追加法术[取随机数(1,#self.参战单位[编号].追加法术)].名称
              self:法术计算(self.执行对象[n],1)
            end
          end


                     elseif self.参战单位[编号].指令.类型=="法术" then--法术攻击
          local 允许执行 = true
            if self.参战单位[编号].模型 =="牛幺" or self.参战单位[编号].标记 == 100080 or 装备特技[self.参战单位[编号].指令.参数]==nil and self:取法术状态(self.执行对象[n],self.参战单位[编号].指令.参数) or (装备特技[self.参战单位[编号].指令.参数]~=nil and self:取特技状态(self.执行对象[n])) then
            local 名称=self.参战单位[编号].指令.参数
            if 名称=="狮搏" or 名称=="鹰击" or 名称=="连环击" or 名称=="象形" then
              if self.参战单位[编号].法术状态.变身==nil then
                  self.参战单位[编号].指令.参数="变身"
                  self:法术计算(self.执行对象[n],1)
                self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/没有变身效果，本回合自动变身")
                允许执行=false
              end
            else
              local 名称=self.参战单位[编号].指令.参数
            if 名称=="狮搏" or 名称=="鹰击" or 名称=="连环击" or 名称=="象形" then
             if self.参战单位[编号].法术状态.变身== true then
                self.参战单位[编号].指令.参数=self.参战单位[编号].主动技能[i].名称
                self:法术计算(self.执行对象[n],1)
              end
            end
          end

          if self.参战单位[编号].指令.参数=="兵解符" then
            self:逃跑计算(编号,0)
             -- self:兵解符计算(编号)
             -- self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
          end

          if  self.参战单位[编号].模型 =="牛幺" or self.参战单位[编号].标记 == 100080 then
            if self.参战单位[编号].主动技能[1] ~= nil then
              self.参战单位[编号].指令.参数=self.参战单位[编号].主动技能[math.random(1,#self.参战单位[编号].主动技能)]
            end
             local 名称=self.参战单位[编号].指令.参数
             if 名称=="狮搏" or 名称=="鹰击" or 名称=="连环击" or 名称=="象形" then
                if self.参战单位[编号].法术状态.鹰击 ~= nil then
                  允许执行 = false
                else
                  if self.参战单位[编号].法术状态.变身==nil then
                    self.参战单位[编号].指令.参数="变身"
                  end
                end
              end
          end

            if 名称=="观照万象" then
              -- if self.参战单位[编号].观照万象==nil then
              --   self.参战单位[编号].观照万象 = 10
              -- end
              if self.参战单位[编号].观照万象 ~= nil then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].观照万象.."回合后才可使用")
              elseif #self.参战单位[编号].主动技能 <= 0 then
                常规提示(self.参战单位[编号].玩家id,"#Y/该召唤兽没有可以释放的主动技能")
              elseif self:取玩家战斗() then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能无法在玩家战斗之间使用")
              else
                for i=1,#self.参战单位[编号].主动技能 do
                  if self.参战单位[编号].主动技能[i].名称 ~= "观照万象" then --and self:法攻技能(self.参战单位[编号].主动技能[i].名称)
                    if self.参战单位[编号].主动技能[i].名称 == "法术防御" then
                      self.参战单位[编号].指令.目标=编号
                    end
                    self.参战单位[编号].指令.参数=self.参战单位[编号].主动技能[i].名称
                    self:法术计算(self.执行对象[n],1)
                  end
                end
                self.参战单位[编号].观照万象 = 10
              end
              elseif 名称=="渡劫金身" then
                if self.参战单位[编号].渡劫金身 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].渡劫金身.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].渡劫金身 = 6
                end

                elseif 名称=="碎玉弄影" then
                if self.参战单位[编号].碎玉弄影 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].碎玉弄影.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].碎玉弄影 = 8
                end

                elseif 名称=="扶摇万里" then
                if self.参战单位[编号].扶摇万里 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].扶摇万里.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].扶摇万里 = 5
                end

                elseif 名称=="顺势而为" then
                if self.参战单位[编号].顺势而为 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].顺势而为.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].顺势而为 = 6
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].其疾如风 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].其疾如风.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].其疾如风 = 16
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].其徐如林 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].其徐如林.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].其徐如林 = 16
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].不动如山  ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].不动如山 .."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].不动如山  = 16
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].侵掠如火 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].侵掠如火.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].侵掠如火 = 16
                end

                elseif 名称=="魑魅缠身" then
                if self.参战单位[编号].魑魅缠身 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].魑魅缠身.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].魑魅缠身 = 8
                end
                elseif 名称=="波澜不惊" then
                if self.参战单位[编号].波澜不惊 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].波澜不惊.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].波澜不惊 = 10
                end
              elseif 名称=="雷浪穿云" then
                if self.参战单位[编号].雷浪穿云 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].雷浪穿云.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].雷浪穿云 = 10
                end
              elseif 名称=="无敌牛妖" then
                if self.参战单位[编号].无敌牛妖 ~= nil and self:取玩家战斗() then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].无敌牛妖.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].无敌牛妖 = 999
                end
              elseif 名称=="无敌牛虱" then
                if self.参战单位[编号].无敌牛虱 ~= nil and self:取玩家战斗() then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].无敌牛虱.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].无敌牛虱 = 999
                end
               elseif 名称=="凋零之歌" then
                if self.参战单位[编号].凋零之歌 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].凋零之歌.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].凋零之歌 = 8
                end
              elseif 名称=="煞气诀" then
                if self.参战单位[编号].煞气诀 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].煞气诀.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].煞气诀 = 5
                end

                elseif 名称=="清风望月" then
                if self.参战单位[编号].清风望月 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].清风望月.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].清风望月 = 4
                end

            elseif 允许执行 then
              self:法术计算(self.执行对象[n],1)
              if self.参战单位[编号].指令.参数=="月光" then
                for i=1,取随机数(1,3) do
                  self:法攻技能计算(编号,self.参战单位[编号].指令.参数,self:取技能等级(编号,self.参战单位[编号].指令.参数),1,1)
                end
              end
              if self:取是否物攻技能(名称) and((名称=="破釜沉舟" and self:取奇经八脉是否有(编号,"干将") and 取随机数(1,100)<=20) or  (self:取指定法宝境界(编号,"嗜血幡")~=false and (取随机数(1,30)<=self:取指定法宝境界(编号,"嗜血幡")*2) and self:取指定法宝(编号,"嗜血幡",1))) and self:取行动状态(self.执行对象[n]) and self:取目标状态(self.执行对象[n],目标,1)==false then
                目标=self:取单个敌方目标(编号)
                if 目标~=0 then
                  self.参战单位[self.执行对象[n]].指令.目标=目标
                  怒击=self:普通攻击计算(self.执行对象[n],1)
                  if 怒击 and self.参战单位[编号].怒击效果 then
                    目标=self:取单个敌方目标(编号)
                    self.参战单位[self.执行对象[n]].指令.目标=目标
                    if self:取目标状态(self.执行对象[n],目标,1) and self:取行动状态(self.执行对象[n])  then
                      self:普通攻击计算(self.执行对象[n],1)
                      self.参战单位[self.执行对象[n]].指令.目标=目标1
                    end
                  end
                end
              end
            end
          end
        elseif self.参战单位[编号].指令.类型=="道具" and self.参战单位[编号].法术状态.煞气诀==nil and self.参战单位[编号].陌宝==nil  then
          self:道具计算(self.执行对象[n],1)
        elseif self.参战单位[编号].指令.类型=="同门飞镖" then
          local 目标=self.参战单位[编号].指令.目标
          if self:取目标状态(编号,目标,1) then
            self:飞镖计算(编号,{[1]={id=目标,伤害=500}})
          end
        elseif self.参战单位[编号].指令.类型=="特技" then
          if self:取特技状态(self.执行对象[n]) then
            self:法术计算(self.执行对象[n],1)
          end
        elseif self.参战单位[编号].指令.类型=="捕捉" and self.参战单位[编号].类型=="角色" then
          self:捕捉计算(self.执行对象[n])
        elseif self.参战单位[编号].指令.类型=="召唤" and self.参战单位[编号].类型=="角色" then
          self:召唤计算(self.执行对象[n])
        elseif self.参战单位[编号].指令.类型=="逃跑"  then
          if self.参战单位[编号].类型 == "角色" and self.参战单位[编号].助战明细 ~= nil and #self.参战单位[编号].助战明细 > 0 then
            for i=1,#self.参战单位[编号].助战明细 do
              self.参战单位[self.参战单位[编号].助战明细[i]].指令.类型="逃跑"
            end
          end
          self:逃跑计算(self.执行对象[n],50)
        end
      end
    end
  end
  for n=1,#self.执行对象 do
    local 编号=self.执行对象[n]
    if self.参战单位[编号].复仇标记 ~= nil and self:取目标状态(self.执行对象[n],self.参战单位[编号].复仇标记,1)  and self.参战单位[编号].气血>=10 then
        self.参战单位[self.执行对象[n]].指令.目标=self.参战单位[编号].复仇标记
       self:普通攻击计算(self.执行对象[n],1)
    end
  end
end

function 战斗处理类:执行计算3()
  -----------------------
  for n=1,#self.参战单位 do
   if  self.参战单位[n].气血>0  then
    if self.参战单位[n].法术状态.巨锋~=nil and self.参战单位[n].法术状态.巨锋.回合==5 then
      if self.参战单位[n].类型~="bb"  then
        self.执行等待=self.执行等待 + 3
       -- local 原模型={}
          --原模型[n]="老夫子"
           -- print("??",self.参战单位[n].模型)
        self.战斗流程[#self.战斗流程+1]={流程=707,攻击方=n,参数="老夫子"}
          -- print("??",self.参战单位[n].模型)
      end
    end
  end
end

   for n=1,#self.参战单位 do
   if  self.参战单位[n].气血>0  then
    if self.参战单位[n].法术状态.据守~=nil and self.参战单位[n].法术状态.据守.回合==5 then
      if self.参战单位[n].类型~="bb"  then
        self.执行等待=self.执行等待 + 3
       -- local 原模型={}
          --原模型[n]="老夫子"
           -- print("??",self.参战单位[n].模型)
        self.战斗流程[#self.战斗流程+1]={流程=707,攻击方=n,参数="老夫子"}
          -- print("??",self.参战单位[n].模型)
      end
    end
  end
end

   for n=1,#self.参战单位 do
   if  self.参战单位[n].气血>0  then
    if self.参战单位[n].法术状态.战复~=nil and self.参战单位[n].法术状态.战复.回合==5 then
      if self.参战单位[n].类型~="bb"  then
        self.执行等待=self.执行等待 + 3
       -- local 原模型={}
          --原模型[n]="老夫子"
           -- print("??",self.参战单位[n].模型)
        self.战斗流程[#self.战斗流程+1]={流程=707,攻击方=n,参数="老夫子"}
          -- print("??",self.参战单位[n].模型)
      end
    end
  end
end

for n=1,#self.参战单位 do
  if  self.参战单位[n].气血>0  then
       if self.参战单位[n].法术状态.巨锋~=nil and self.参战单位[n].法术状态.巨锋.回合==1 then
         if self.参战单位[n].类型~="bb"  then
          self.执行等待=self.执行等待 + 3
          self.战斗流程[#self.战斗流程+1]={流程=709,攻击方=n,参数=self.参战单位[n].模型}
         end
       end
     else
      if self.参战单位[n].法术状态.巨锋~=nil and self.参战单位[n].法术状态.巨锋.回合==1 then
         if self.参战单位[n].类型~="bb"  then
          self.执行等待=self.执行等待 + 3
          self.战斗流程[#self.战斗流程+1]={流程=711,攻击方=n,参数=self.参战单位[n].模型}
         end
       end
     end
    end

for n=1,#self.参战单位 do
  if  self.参战单位[n].气血>0  then
       if self.参战单位[n].法术状态.据守~=nil and self.参战单位[n].法术状态.据守.回合==1 then
         if self.参战单位[n].类型~="bb"  then
          self.执行等待=self.执行等待 + 3
          self.战斗流程[#self.战斗流程+1]={流程=709,攻击方=n,参数=self.参战单位[n].模型}
         end
       end
     else
      if self.参战单位[n].法术状态.据守~=nil and self.参战单位[n].法术状态.据守.回合==1 then
         if self.参战单位[n].类型~="bb"  then
          self.执行等待=self.执行等待 + 3
          self.战斗流程[#self.战斗流程+1]={流程=711,攻击方=n,参数=self.参战单位[n].模型}
         end
       end
     end
    end

for n=1,#self.参战单位 do
  if  self.参战单位[n].气血>0  then
       if self.参战单位[n].法术状态.战复~=nil and self.参战单位[n].法术状态.战复.回合==1 then
         if self.参战单位[n].类型~="bb"  then
          self.执行等待=self.执行等待 + 3
          self.战斗流程[#self.战斗流程+1]={流程=709,攻击方=n,参数=self.参战单位[n].模型}
         end
       end
     else
      if self.参战单位[n].法术状态.战复~=nil and self.参战单位[n].法术状态.战复.回合==1 then
         if self.参战单位[n].类型~="bb"  then
          self.执行等待=self.执行等待 + 3
          self.战斗流程[#self.战斗流程+1]={流程=711,攻击方=n,参数=self.参战单位[n].模型}
         end
       end
     end
    end
  ---------
end


function 战斗处理类:执行计算2()
  for n=1,#self.执行对象 do
    local 编号=self.执行对象[n]
    if self.参战单位[编号].法术状态.后发制人~=nil then
      self.参战单位[编号].指令.类型=""
      self:物攻技能计算(编号,"后发制人",self:取技能等级(编号,"后发制人"))
    end
    if self.参战单位[编号].观照万象 ~= nil then
    self.参战单位[编号].观照万象 = self.参战单位[编号].观照万象 -1
    if self.参战单位[编号].观照万象 <= 0 then
    self.参战单位[编号].观照万象 = nil
    end
    end

    if self.参战单位[编号].扶摇万里 ~= nil then
    self.参战单位[编号].扶摇万里 = self.参战单位[编号].扶摇万里 -1
    if self.参战单位[编号].扶摇万里 <= 0 then
    self.参战单位[编号].扶摇万里 = nil
    end
    end

    if self.参战单位[编号].碎玉弄影 ~= nil then
    self.参战单位[编号].碎玉弄影 = self.参战单位[编号].碎玉弄影 -1
    if self.参战单位[编号].碎玉弄影 <= 0 then
    self.参战单位[编号].碎玉弄影 = nil
    end
    end

    if self.参战单位[编号].顺势而为 ~= nil then
    self.参战单位[编号].顺势而为 = self.参战单位[编号].顺势而为 -1
    if self.参战单位[编号].顺势而为 <= 0 then
    self.参战单位[编号].顺势而为 = nil
    end
    end

    if self.参战单位[编号].波澜不惊 ~= nil then
    self.参战单位[编号].波澜不惊 = self.参战单位[编号].波澜不惊 -1
    if self.参战单位[编号].波澜不惊 <= 0 then
    self.参战单位[编号].波澜不惊 = nil
    end
    end

    if self.参战单位[编号].渡劫金身 ~= nil then
    self.参战单位[编号].渡劫金身 = self.参战单位[编号].渡劫金身 -1
    if self.参战单位[编号].渡劫金身 <= 0 then
    self.参战单位[编号].渡劫金身 = nil
    end
    end

        if self.参战单位[编号].其疾如风 ~= nil then
    self.参战单位[编号].其疾如风 = self.参战单位[编号].其疾如风 -1
    if self.参战单位[编号].其疾如风 <= 0 then
    self.参战单位[编号].其疾如风 = nil
    end
    end

        if self.参战单位[编号].其徐如林 ~= nil then
    self.参战单位[编号].其徐如林 = self.参战单位[编号].其徐如林 -1
    if self.参战单位[编号].其徐如林 <= 0 then
    self.参战单位[编号].其徐如林 = nil
    end
    end

        if self.参战单位[编号].不动如山  ~= nil then
    self.参战单位[编号].不动如山  = self.参战单位[编号].不动如山  -1
    if self.参战单位[编号].不动如山  <= 0 then
    self.参战单位[编号].不动如山  = nil
    end
    end

        if self.参战单位[编号].侵掠如火 ~= nil then
    self.参战单位[编号].侵掠如火 = self.参战单位[编号].侵掠如火 -1
    if self.参战单位[编号].侵掠如火 <= 0 then
    self.参战单位[编号].侵掠如火 = nil
    end
    end

    if self.参战单位[编号].魑魅缠身 ~= nil then
    self.参战单位[编号].魑魅缠身 = self.参战单位[编号].魑魅缠身 -1
    if self.参战单位[编号].魑魅缠身 <= 0 then
    self.参战单位[编号].魑魅缠身 = nil
    end
    end

    if self.参战单位[编号].清风望月 ~= nil then
    self.参战单位[编号].清风望月 = self.参战单位[编号].清风望月 -1
    if self.参战单位[编号].清风望月 <= 0 then
    self.参战单位[编号].清风望月 = nil
    end
    end

    if self.参战单位[编号].雷浪穿云 ~= nil then
    self.参战单位[编号].雷浪穿云 = self.参战单位[编号].雷浪穿云 -1
    if self.参战单位[编号].雷浪穿云 <= 0 then
    self.参战单位[编号].雷浪穿云 = nil
    end
    end

    if self.参战单位[编号].无敌牛妖 ~= nil then
    self.参战单位[编号].无敌牛妖 = self.参战单位[编号].无敌牛妖 -1
    if self.参战单位[编号].无敌牛妖 <= 0 then
    self.参战单位[编号].无敌牛妖 = nil
    end
    end

    if self.参战单位[编号].无敌牛虱 ~= nil then
    self.参战单位[编号].无敌牛虱 = self.参战单位[编号].无敌牛虱 -1
    if self.参战单位[编号].无敌牛虱 <= 0 then
    self.参战单位[编号].无敌牛虱 = nil
    end
    end

    if self.参战单位[编号].凋零之歌 ~= nil then
    self.参战单位[编号].凋零之歌 = self.参战单位[编号].凋零之歌 -1
    if self.参战单位[编号].凋零之歌 <= 0 then
    self.参战单位[编号].凋零之歌 = nil
    end
    end

    if self.参战单位[编号].煞气诀 ~= nil then
    self.参战单位[编号].煞气诀 = self.参战单位[编号].煞气诀 -1
    if self.参战单位[编号].煞气诀 <= 0 then
    self.参战单位[编号].煞气诀 = nil
    end
    end


  end

  for n=1,#self.执行对象 do

    if self.全局结束==nil and self:取行动状态(self.执行对象[n])  then
      local 编号=self.执行对象[n]
      if self.参战单位[编号].指令==nil then
      self.参战单位[编号].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
      end
      if self.参战单位[编号].指令.下达 then
      if self.参战单位[编号].模型 =="牛幺" or self.参战单位[编号].标记 == 100080 then
      if math.random(1,1) == 1 then
      if self.参战单位[编号].主动技能[1] ~= "" then
      self.参战单位[编号].指令.类型="法术"
      else
      self.参战单位[编号].指令.类型="攻击"
      end
      else
      self.参战单位[编号].指令.类型="攻击"
      end
      end

        -- if self.参战单位[编号].法术状态.疯狂 or self.参战单位[编号].法术状态.错乱 then
        --   if self.参战单位[编号].指令.类型~="防御" then
        --     self.参战单位[编号].指令.类型="攻击"
        --     self.参战单位[编号].指令.目标=self:取单个敌方目标(编号)
        --   end
        -- end
        if self.参战单位[编号].法术状态.反间之计~=nil and 取随机数()<=50 then
          local 临时友方 = self:取单个友方目标(编号)
          if 临时友方 ~= 0 then
            self.参战单位[编号].指令.类型="攻击"
            self.参战单位[编号].指令.目标=临时友方
          else
            self.参战单位[编号].指令.类型="防御"
            self.参战单位[编号].指令.目标=0
          end
        end
        if self.参战单位[编号].法术状态.发瘟匣~=nil  then
          if self.参战单位[编号].指令.类型~="防御" then
            self.参战单位[编号].指令.类型="攻击"
            self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
          end
        end
        if self.参战单位[编号].法术状态.落魄符~=nil and 取随机数()<=50 then
          self.参战单位[编号].指令.类型="攻击"
          self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
        end
        if self.参战单位[编号].法术状态.错乱~=nil and 取随机数()<=50 then
          self.参战单位[编号].指令.类型="攻击"
          self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
        end
        if self.参战单位[编号].法术状态.锋芒毕露~=nil  then
          self.参战单位[编号].指令.目标=self.参战单位[编号].法术状态.目标id
        end
        if self.参战单位[编号].法术状态.诱袭~=nil  then
          self.参战单位[编号].指令.类型="攻击"
          self.参战单位[编号].指令.目标=self.参战单位[编号].法术状态.目标id
        end
        if self.参战单位[编号].法术状态.无魂傀儡~=nil and 取随机数()<=30 or self.参战单位[编号].法术状态.断线木偶~=nil and 取随机数()<=30 then
        -- if self.参战单位[编号].法术状态.攻击编号~=nil  then
        self.参战单位[编号].指令.类型="攻击"
        self.参战单位[编号].指令.目标=self.参战单位[编号].法术状态.攻击编号
        -- end
        end
        if self.参战单位[编号].法术状态.鬼泣~=nil and self.参战单位[编号].类型~="角色" and 35>=取随机数() then
        self.参战单位[编号].指令.类型="逃跑"
        elseif self.参战单位[编号].法术状态.惊魂铃~=nil and self.参战单位[编号].类型~="角色" and 取随机数()<=30 then
        self.参战单位[编号].指令.类型="逃跑"
        end

         if self.参战单位[编号].指令.类型=="攻击" and self.参战单位[self.执行对象[n]].指令.附加 == "友伤" then--普通攻击

          local 目标1=self.参战单位[self.执行对象[n]].指令.目标
          if self:取攻击状态(self.执行对象[n]) then
               self:普通攻击计算(self.执行对象[n],1,true)
             end
           end
           -- 0914 平A溅射特效流部分完善
        if self.参战单位[编号].指令.类型=="攻击" then--普通攻击
          local 怒击=false
          local 目标1=self.参战单位[self.执行对象[n]].指令.目标
          if self:取攻击状态(self.执行对象[n])  then
            if self.参战单位[self.参战单位[self.执行对象[n]].指令.目标]~=nil and self.参战单位[self.执行对象[n]].法术状态.反间之计==nil and self.参战单位[self.参战单位[self.执行对象[n]].指令.目标].队伍==self.参战单位[编号].队伍 then
              self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
              目标1=self.参战单位[self.执行对象[n]].指令.目标
            end
            if self:取目标状态(self.执行对象[n],目标1,1) == false then
              self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
            end
            if  self.参战单位[编号].理直气壮~=nil and 取随机数()<=40 then
              self.参战单位[编号].指令.参数="理直气壮"
              self:法术计算(self.执行对象[n],1)
              if self.参战单位[编号].怒击效果 and self:取攻击状态(self.执行对象[n]) then
                self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
                self:普通攻击计算(self.执行对象[n],1)
                self.参战单位[编号].怒击触发 = nil
              end
            elseif  self.参战单位[编号].连击~=nil and self.参战单位[编号].连击>=取随机数() then
              self.参战单位[编号].指令.参数="高级连击"
              self:法术计算(self.执行对象[n],1)
              if #self.参战单位[编号].追加法术>0 and 取随机数()<=10 and self:取攻击状态(self.执行对象[n]) and self:取奇经八脉是否有(编号,"逐胜") == false then
                  self.参战单位[编号].指令.类型="法术"
                  self.参战单位[编号].指令.参数=self.参战单位[编号].追加法术[取随机数(1,#self.参战单位[编号].追加法术)].名称
                  self:法术计算(self.执行对象[n],1)
              end
              if self.参战单位[编号].怒击效果 and self:取攻击状态(self.执行对象[n]) then
                self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
                self:普通攻击计算(self.执行对象[n],1)
                self.参战单位[编号].怒击触发 = nil
              end
            else
              怒击=self:普通攻击计算(self.执行对象[n],1)
              if self.参战单位[编号].怒击效果 and 怒击 and self:取攻击状态(self.执行对象[n]) then
                self.参战单位[self.执行对象[n]].指令.目标= self:取单个敌方目标(编号)
                self:普通攻击计算(self.执行对象[n],1)
              end
            end
              if self.参战单位[编号].嗜血追击~=nil and self:取行动状态(self.执行对象[n]) and self:取目标状态(self.执行对象[n],self.参战单位[self.执行对象[n]].指令.目标,3)==false then
                目标=self:取单个敌方目标(编号)
                 if 目标~=0 then
                  self.参战单位[self.执行对象[n]].指令.目标=目标
                  self:普通攻击计算(self.执行对象[n],1)
                end
              end
            if self.参战单位[编号].溅射~=nil and self.参战单位[编号].溅射~=0 and self:取奇经八脉是否有(编号,"逐胜") == false  then
              目标=self.参战单位[self.执行对象[n]].指令.目标
              if 目标==0 or 目标==nil then
                目标=self:取单个敌方目标(编号)
              end
              if 目标~=0 then
                self.溅射伤害 = self:取基础物理伤害(编号,目标)
                self.溅射最终伤害 = self:取最终物理伤害(编号,目标,self.溅射伤害)
                self.溅射伤害值 =self:取伤害结果(编号,目标,self.溅射最终伤害.伤害,self.溅射最终伤害.暴击,保护)
                if self:取玩家战斗() then
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射*0.5
                  else
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射
                  end
                self:物理同时多个攻击(编号,目标,self.伤害输出,self.参战单位[编号].溅射人数,名称)--编号,伤害,数量,名称)
              end
            end
            if  ((self:取指定法宝境界(编号,"嗜血幡")~=false and (取随机数(1,30)<=self:取指定法宝境界(编号,"嗜血幡")*2) and self:取指定法宝(编号,"嗜血幡",1,1))) and self:取行动状态(self.执行对象[n]) and self:取目标状态(self.执行对象[n],目标1,1) and self:取奇经八脉是否有(编号,"逐胜")~=true then
              目标=self:取单个敌方目标(编号)
              if 目标~=0 then
                self.参战单位[self.执行对象[n]].指令.目标=目标
                if 编号~=nil and self.参战单位[编号].法宝佩戴~=nil and #self.参战单位[编号].法宝佩戴~=nil and self.参战单位[编号].类型=="角色" then
                    local 序列 = 0
                    for i=1,#self.参战单位[编号].法宝佩戴 do
                      if self.参战单位[编号].法宝佩戴[i].名称=="嗜血幡" then
                        序列=i
                      end
                    end
                    self:扣除法宝灵气(编号,序列,1)
                end

                怒击=self:普通攻击计算(self.执行对象[n],1)
                if 怒击 and self.参战单位[编号].怒击效果 then
                  目标=self:取单个敌方目标(编号)
                  self.参战单位[self.执行对象[n]].指令.目标=目标
                  if self:取目标状态(self.执行对象[n],目标,1) and self:取行动状态(self.执行对象[n])  then
                    self:普通攻击计算(self.执行对象[n],1)
                    self.参战单位[self.执行对象[n]].指令.目标=目标1
                  end
                end
              end
              if self.参战单位[编号].溅射~=nil and self.参战单位[编号].溅射~=0 and self:取奇经八脉是否有(编号,"逐胜") == false  then
                目标=self.参战单位[self.执行对象[n]].指令.目标
                if 目标==0 or 目标==nil then
                  目标=self:取单个敌方目标(编号)
                end
                if 目标~=0 then
                  self.溅射伤害 = self:取基础物理伤害(编号,目标)
                  self.溅射最终伤害 = self:取最终物理伤害(编号,目标,self.溅射伤害)
                  self.溅射伤害值 =self:取伤害结果(编号,目标,self.溅射最终伤害.伤害,self.溅射最终伤害.暴击,保护)
                  if self:取玩家战斗() then
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射*0.5
                  else
                  self.伤害输出 = self.溅射伤害值.伤害 * self.参战单位[编号].溅射
                  end
                  self:物理同时多个攻击(编号,目标,self.伤害输出,self.参战单位[编号].溅射人数,名称)--编号,伤害,数量,名称)
                end
              end
            end

            if 编号~=nil and self:取奇经八脉是否有(编号,"风刃妖风") then
              目标=self.参战单位[self.执行对象[n]].指令.目标
              self:物理同时多个攻击(编号,目标,1000,10,名称)--编号,伤害,数量,名称)
            end

            if 编号~=nil and self:取奇经八脉是否有(编号,"逐胜") then
              目标=self:取单个敌方目标(编号)
              if 目标~=0 then
                self.参战单位[self.执行对象[n]].指令.目标=目标
                if self:取目标状态(self.执行对象[n],目标,1) and self:取行动状态(self.执行对象[n])  then
                  self:普通攻击计算(self.执行对象[n],1)
                  self.参战单位[self.执行对象[n]].指令.目标=目标1
                end
              end
            end

            if self.参战单位[编号].套装追加概率 == nil then
              self.参战单位[编号].套装追加概率 = 0
            end
            if #self.参战单位[编号].追加法术>0 and 取随机数()<=self.参战单位[编号].套装追加概率 and self:取攻击状态(self.执行对象[n]) and self:取奇经八脉是否有(编号,"逐胜") == false then
              self.参战单位[编号].指令.类型="法术"
              self.参战单位[编号].指令.参数=self.参战单位[编号].追加法术[取随机数(1,#self.参战单位[编号].追加法术)].名称
              self:法术计算(self.执行对象[n],1)
            end
          end


         elseif self.参战单位[编号].指令.类型=="法术" then--法术攻击
          local 允许执行 = true
            if self.参战单位[编号].模型 =="牛幺" or self.参战单位[编号].标记 == 100080 or 装备特技[self.参战单位[编号].指令.参数]==nil and self:取法术状态(self.执行对象[n],self.参战单位[编号].指令.参数) or (装备特技[self.参战单位[编号].指令.参数]~=nil and self:取特技状态(self.执行对象[n])) then
            local 名称=self.参战单位[编号].指令.参数
            if 名称=="狮搏" or 名称=="鹰击" or 名称=="连环击" or 名称=="象形" then
              if self.参战单位[编号].法术状态.变身==nil then
                  self.参战单位[编号].指令.参数="变身"
                  self:法术计算(self.执行对象[n],1)
                self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/没有变身效果，本回合自动变身")
                允许执行=false
              end
            else
              local 名称=self.参战单位[编号].指令.参数
            if 名称=="狮搏" or 名称=="鹰击" or 名称=="连环击" or 名称=="象形" then
             if self.参战单位[编号].法术状态.变身== true then
                self.参战单位[编号].指令.参数=self.参战单位[编号].主动技能[i].名称
                self:法术计算(self.执行对象[n],1)
              end
            end
          end

          if self.参战单位[编号].指令.参数=="兵解符" then
            self:逃跑计算(编号,0)
                 -- self:兵解符计算(编号)
                 -- self.参战单位[编号].指令.目标=self:取单个友方目标(编号)
          end
          if  self.参战单位[编号].模型 =="牛幺" or self.参战单位[编号].标记 == 100080 then
            if self.参战单位[编号].主动技能[1] ~= nil then
              self.参战单位[编号].指令.参数=self.参战单位[编号].主动技能[math.random(1,#self.参战单位[编号].主动技能)]
            end
             local 名称=self.参战单位[编号].指令.参数
             if 名称=="狮搏" or 名称=="鹰击" or 名称=="连环击" or 名称=="象形" then
                if self.参战单位[编号].法术状态.鹰击 ~= nil then
                  允许执行 = false
                else
                  if self.参战单位[编号].法术状态.变身==nil then
                    self.参战单位[编号].指令.参数="变身"
                  end
                end
              end
          end

            if 名称=="观照万象" then
              -- if self.参战单位[编号].观照万象==nil then
              --   self.参战单位[编号].观照万象 = 10
              -- end
              if self.参战单位[编号].观照万象 ~= nil then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].观照万象.."回合后才可使用")
              elseif #self.参战单位[编号].主动技能 <= 0 then
                常规提示(self.参战单位[编号].玩家id,"#Y/该召唤兽没有可以释放的主动技能")
              elseif self:取玩家战斗() then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能无法在玩家战斗之间使用")
              else
                for i=1,#self.参战单位[编号].主动技能 do
                  if self.参战单位[编号].主动技能[i].名称 ~= "观照万象" then --and self:法攻技能(self.参战单位[编号].主动技能[i].名称)
                    if self.参战单位[编号].主动技能[i].名称 == "法术防御" then
                      self.参战单位[编号].指令.目标=编号
                    end
                    self.参战单位[编号].指令.参数=self.参战单位[编号].主动技能[i].名称
                    self:法术计算(self.执行对象[n],1)
                  end
                end
                self.参战单位[编号].观照万象 = 10
              end
              elseif 名称=="渡劫金身" then
                if self.参战单位[编号].渡劫金身 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].渡劫金身.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].渡劫金身 = 6
                end

                elseif 名称=="碎玉弄影" then
                if self.参战单位[编号].碎玉弄影 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].碎玉弄影.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].碎玉弄影 = 8
                end

                elseif 名称=="顺势而为" then
                if self.参战单位[编号].顺势而为 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].顺势而为.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].顺势而为 = 6
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].其疾如风 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].其疾如风.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].其疾如风 = 16
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].其徐如林 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].其徐如林.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].其徐如林 = 16
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].不动如山  ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].不动如山 .."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].不动如山  = 16
                end

                elseif 名称=="其疾如风" or 名称=="其徐如林" or 名称=="不动如山 " or 名称=="侵掠如火" then
                if self.参战单位[编号].侵掠如火 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].侵掠如火.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].侵掠如火 = 16
                end

                elseif 名称=="魑魅缠身" then
                if self.参战单位[编号].魑魅缠身 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].魑魅缠身.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].魑魅缠身 = 8
                end
                elseif 名称=="波澜不惊" then
                if self.参战单位[编号].波澜不惊 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].波澜不惊.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].波澜不惊 = 10
                end
              elseif 名称=="雷浪穿云" then
                if self.参战单位[编号].雷浪穿云 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].雷浪穿云.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].雷浪穿云 = 10
                end
              elseif 名称=="无敌牛妖" then
                if self.参战单位[编号].无敌牛妖 ~= nil and self:取玩家战斗() then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].无敌牛妖.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].无敌牛妖 = 999
                end
              elseif 名称=="无敌牛虱" then
                if self.参战单位[编号].无敌牛虱 ~= nil and self:取玩家战斗() then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].无敌牛虱.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].无敌牛虱 = 999
                end
               elseif 名称=="凋零之歌" then
                if self.参战单位[编号].凋零之歌 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].凋零之歌.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].凋零之歌 = 8
                end
               elseif 名称=="煞气诀" and  self:取玩家战斗()==true then
                self:添加提示(self.参战单位[编号].玩家id,编号,"煞气诀不能对人物使用哦")
              -- end
              elseif 名称=="煞气诀" and  self:取玩家战斗()==false then
                if self.参战单位[编号].煞气诀 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].煞气诀.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].煞气诀 = 5
                end

                elseif 名称=="清风望月" then
                if self.参战单位[编号].清风望月 ~= nil and self.参战单位[编号].类型=="角色" then
                常规提示(self.参战单位[编号].玩家id,"#Y/该技能当前处于冷却中还需："..self.参战单位[编号].清风望月.."回合后才可使用")
                else
                self:法术计算(self.执行对象[n],1)
                self.参战单位[编号].清风望月 = 4
                end

            elseif 允许执行 then
              self:法术计算(self.执行对象[n],1)
              if self.参战单位[编号].指令.参数=="月光" then
                for i=1,取随机数(1,3) do
                  self:法攻技能计算(编号,self.参战单位[编号].指令.参数,self:取技能等级(编号,self.参战单位[编号].指令.参数),1,1)
                end
              end
              if self:取是否物攻技能(名称) and((取随机数(1,100)<=20) or  (self:取指定法宝境界(编号,"嗜血幡")~=false and (取随机数(1,30)<=self:取指定法宝境界(编号,"嗜血幡")*2) and self:取指定法宝(编号,"嗜血幡",1))) and self:取行动状态(self.执行对象[n]) and self:取目标状态(self.执行对象[n],目标,1)==false then
                目标=self:取单个敌方目标(编号)
                if 目标~=0 then
                  self.参战单位[self.执行对象[n]].指令.目标=目标
                  怒击=self:普通攻击计算(self.执行对象[n],1)
                  if 怒击 and self.参战单位[编号].怒击效果 then
                    目标=self:取单个敌方目标(编号)
                    self.参战单位[self.执行对象[n]].指令.目标=目标
                    if self:取目标状态(self.执行对象[n],目标,1) and self:取行动状态(self.执行对象[n])  then
                      self:普通攻击计算(self.执行对象[n],1)
                      self.参战单位[self.执行对象[n]].指令.目标=目标1
                    end
                  end
                end
              end
            end
          end
        elseif self.参战单位[编号].指令.类型=="道具" and self.参战单位[编号].法术状态.煞气诀==nil and self.参战单位[编号].陌宝==nil  then
          self:道具计算(self.执行对象[n],1)
        elseif self.参战单位[编号].指令.类型=="同门飞镖" then
          local 目标=self.参战单位[编号].指令.目标
          if self:取目标状态(编号,目标,1) then
            self:飞镖计算(编号,{[1]={id=目标,伤害=500}})
          end
        elseif self.参战单位[编号].指令.类型=="特技" then
          if self:取特技状态(self.执行对象[n]) then
            self:法术计算(self.执行对象[n],1)
          end
        elseif self.参战单位[编号].指令.类型=="捕捉" and self.参战单位[编号].类型=="角色" then
          self:捕捉计算(self.执行对象[n])
        elseif self.参战单位[编号].指令.类型=="召唤" and self.参战单位[编号].类型=="角色" then
          self:召唤计算(self.执行对象[n])
        elseif self.参战单位[编号].指令.类型=="逃跑"  then
          if self.参战单位[编号].类型 == "角色" and self.参战单位[编号].助战明细 ~= nil and #self.参战单位[编号].助战明细 > 0 then
            for i=1,#self.参战单位[编号].助战明细 do
              self.参战单位[self.参战单位[编号].助战明细[i]].指令.类型="逃跑"
            end
          end
          self:逃跑计算(self.执行对象[n],50)
        end
      end
    end
  end
  for n=1,#self.执行对象 do
    local 编号=self.执行对象[n]
    if self.参战单位[编号].复仇标记 ~= nil and self:取目标状态(self.执行对象[n],self.参战单位[编号].复仇标记,1)  and self.参战单位[编号].气血>=10 then
        self.参战单位[self.执行对象[n]].指令.目标=self.参战单位[编号].复仇标记
       self:普通攻击计算(self.执行对象[n],1)
    end
  end
end

function 战斗处理类:物理同时多个攻击(编号,目标,伤害,数量,名称)
  if 数量==nil then 数量=1 end
  if 伤害==nil then 伤害=1 end
  self.战斗流程[#self.战斗流程+1]={流程=613,攻击方=编号,挨打方={}}
  self.执行等待=0
  local 目标组={}
  for n=1,#self.参战单位 do
     if  self.参战单位[n].队伍~=self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) and n~=目标 then
         目标组[#目标组+1]=n
     end
  end
  if #目标组==0 then
     return
  end

  if #目标组 > 数量 then
    随机排序(目标组)
    local 临时目标组 = 目标组
    目标组={}
    for i=1,数量 do
      目标组[i]=临时目标组[i]
    end
  end
  for i=1,#目标组 do
    local 溅射伤害=伤害
    if 编号~=nil and self:取奇经八脉是否有(编号,"风刃") and i<=2 then
      if self.参战单位[编号].法术状态.风魂~=nil then
        溅射伤害 = self.参战单位[编号].等级*3+1000
      else
        溅射伤害 = self.参战单位[编号].等级*3
      end
    end
    x挨打 = #self.战斗流程[#self.战斗流程].挨打方+1
    self.战斗流程[#self.战斗流程].挨打方[x挨打]={挨打方=目标组[i],伤害=溅射伤害}
    self.战斗流程[#self.战斗流程].挨打方[x挨打].死亡=self:减少气血(目标组[i],溅射伤害,编号,名称)
  end
end

function 战斗处理类:法宝计算(编号)
  local 目标=self.参战单位[编号].指令.目标
  local 道具=self.参战单位[编号].指令.参数
  local id=self.参战单位[编号].玩家id
  local 道具1=玩家数据[id].角色.数据.法宝[道具]
  local 名称=玩家数据[id].道具.数据[道具1].名称
  if 玩家数据[id].道具.数据[道具1].回合~=nil then
    if 玩家数据[id].道具.数据[道具1].回合>self.回合数 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该法宝在当前回合无法使用")
      return
    end
  elseif self.参战单位[目标].气血<0 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/目标已处于死亡状态，无法对其使用法宝")
    return
  elseif self.参战单位[目标].队伍==0 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你无法对这样的目标使用法宝")
    return
  end
  local 临时物品=取物品数据(玩家数据[id].道具.数据[道具1].名称)
  self.执行等待=self.执行等待+10
  玩家数据[id].道具.数据[道具1].回合=self.回合数+临时物品[7]
  玩家数据[id].道具.数据[道具1].魔法=玩家数据[id].道具.数据[道具1].魔法-1
  发送数据(玩家数据[id].连接id,38,{内容="你的法宝减少了1点灵气"})
  if 名称=="干将莫邪" or 名称=="苍白纸人" or 名称=="五彩娃娃" or 名称=="混元伞" or 名称=="乾坤玄火塔"  or 名称 == "聚妖铃" or 名称 == "万鬼幡"    then
    self:增益技能计算(编号,名称,0,nil,1,1,玩家数据[id].道具.数据[道具1].气血)
    --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/这些是2-3级法宝暂时无法使用")
  elseif 名称=="鬼泣" or 名称=="摄魂"  or 名称=="断线木偶" or 名称=="无魂傀儡" or 名称=="缚妖索" or 名称=="捆仙绳" then
    self:减益技能计算(编号,名称,0,nil,1,1,玩家数据[id].道具.数据[道具1].气血)
    --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/这些是2-3级法宝暂时无法使用")
  elseif 名称=="无字经" or 名称=="发瘟匣" or 名称=="七杀" or 名称=="无尘扇" then
    self:单体封印技能计算(编号,名称,玩家数据[id].道具.数据[道具1].气血,true)
    --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/这些是2-3级法宝暂时无法使用")
  elseif 名称=="惊魂铃" then
    self:减益技能计算(编号,名称,0,nil,1,1,玩家数据[id].道具.数据[道具1].气血)
  elseif 名称=="惊魂铃" then
    self:单体封印技能计算(编号,名称,玩家数据[id].道具.数据[道具1].气血,true)
  elseif 名称=="清心咒" then
    self:恢复技能计算(编号,名称,玩家数据[id].道具.数据[道具1].气血,true)
  end
end

function 战斗处理类:道具计算(编号)

  if self.参战单位[编号].道具类型=="法宝" then
     self:法宝计算(编号)
     --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/法宝暂时不能用")
    return
  end
  local 目标=self.参战单位[编号].指令.目标
  local 道具=self.参战单位[编号].指令.参数
  local id=self.参战单位[编号].玩家id
  local 道具1=玩家数据[id].角色.数据.道具[道具]
  if 道具1==nil or 玩家数据[id].道具.数据[道具1]==nil then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你没有这样的道具")
    return
  end
  local 道具数据=table.loadstring(table.tostring(玩家数据[id].道具.数据[道具1]))
  local 名称=道具数据.名称
  local 使用=false
  local 加血道具={"金创药","小还丹","千年保心丹","金香玉","五龙丹","天不老","紫石英","血色茶花","熊胆","鹿茸","六道轮回","凤凰尾","硫磺草","龙之心屑","火凤之睛","四叶花","天青地白","七叶莲"
                 ,"草果","九香虫","水黄莲","山药","八角莲叶","人参"}
  local 加魔道具={"翡翠豆腐","佛跳墙","蛇蝎美人","风水混元丹","定神香","十香返生丸","丁香水","月星子","仙狐涎","地狱灵芝","麝香","血珊瑚","餐风饮露","白露为霜","天龙水","孔雀红","紫丹罗","佛手","旋复花","龙须草","百色花","香叶","白玉骨头","鬼切草","灵脂","曼陀罗花"}
  local 复活道具={"佛光舍利子","九转回魂丹"}
  local 酒类道具={"珍露酒","虎骨酒","女儿红","蛇胆酒","醉生梦死","梅花酒","百味酒"}
  local 使用类型=nil
  for n=1,#加血道具 do
    if 加血道具[n]==名称 then
      使用类型=1
    end
  end
  for n=1,#加魔道具 do
    if 加魔道具[n]==名称 then
      使用类型=2
    end
  end
  for n=1,#复活道具 do
    if 复活道具[n]==名称 then
      使用类型=3
    end
  end
  for n=1,#酒类道具 do
    if 酒类道具[n]==名称 then
      使用类型=4
    end
  end
  if 名称=="乾坤袋" then
    使用类型=5
  end
  if 道具数据.总类==2000 then
    使用类型=6
  end
  if 使用类型==nil then self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/此类道具无法在战斗中使用")
    return
  end
  self.执行等待=self.执行等待+8
  if 使用类型==1 then
    local 临时数值=玩家数据[id].道具:取加血道具1(名称,道具1)
    if 编号~=nil and self:取奇经八脉是否有(编号,"安抚") then
      临时数值=qz(临时数值*1.5)
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"不坏") and self.参战单位[编号].气血<=qz(self.参战单位[编号].最大气血*0.3) then
      临时数值=qz(临时数值*1.3)
    end
    if self.参战单位[目标].法术状态.魔音摄魂 or self.参战单位[目标].气血<=0 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"当前状态无法使用物品")
      return
    else
      self.战斗流程[#self.战斗流程+1]={流程=60,攻击方=编号,挨打方={{挨打方=目标,解除状态={},特效={"加血"}}},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
      local 气血=self:取恢复气血(编号,目标,临时数值)
      if self.参战单位[目标].识药特性~=nil then
        气血=qz(气血*(1+self.参战单位[目标].识药特性*0.05))
      end
      local 药性 = 道具数据.药性
      local 阶品 = 道具数据.阶品
      if 药性 ~= nil and 药性=="倍愈" then
        气血=气血*2
      end
      self:增加气血(目标,气血)
      self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=气血
      使用=true
      if 药性 ~= nil and 药性=="藏神" then
        self:添加状态("护盾",self.参战单位[目标],self.参战单位[编号],阶品*8+75,编号)
        self.战斗流程[#self.战斗流程].挨打方[1].添加状态1="护盾"
      end
      if 名称=="五龙丹" then
          self.战斗流程[#self.战斗流程].挨打方[1].解除状态=self:解除状态结果(self.参战单位[目标],self:取异常状态法术())
        if #self.战斗流程[#self.战斗流程].挨打方[1].解除状态==0 then
          self:添加状态("催眠符",self.参战单位[目标],self.参战单位[编号],150,编号)
          self.参战单位[目标].法术状态.催眠符.回合=5
          self.战斗流程[#self.战斗流程].挨打方[1].添加状态="催眠符"
        end
  	  elseif 名称=="小还丹" or 名称=="千年保心丹" or 名称=="九转回魂丹" or 名称=="佛光舍利子" or 名称=="山药" or 名称=="八角莲叶" or 名称=="人参"
        or 名称=="草果" or 名称=="九香虫" or 名称=="水黄莲" then
        --只有人物角色才有伤势
  	    --战斗中恢复伤势在加血后应该没有问题 存在假血的概念
        if self.参战单位[目标].类型=="角色" and self.参战单位[目标].助战编号 == nil then
          local 临时数值=玩家数据[id].道具:取加伤道具1(名称,道具1)
      		self:恢复伤势(目标,临时数值)
      		self.战斗流程[#self.战斗流程].挨打方[1].恢复伤势=临时数值
      		self.战斗流程[#self.战斗流程].挨打方[1].伤势类型=2
          end
        end
      end
  elseif 使用类型==2 then
    local 临时数值=玩家数据[id].道具:取加魔道具1(名称,道具1)
    if self.参战单位[目标].识药特性~=nil then
      临时数值=qz(临时数值*(1+self.参战单位[目标].识药特性*0.05))
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"安抚") then
      临时数值=qz(临时数值*1.5)
    end
    if self.参战单位[目标].法术状态.魔音摄魂 or self.参战单位[目标].气血<=0 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"当前状态无法使用物品")
      return
    else
      self.战斗流程[#self.战斗流程+1]={流程=60,攻击方=编号,挨打方={{挨打方=目标,解除状态={},特效={"加蓝"}}},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
     local 药性 = 道具数据.药性
     local 阶品 = 道具数据.阶品
      if 药性 ~= nil and 药性=="倍愈" then
        临时数值=临时数值*2
      end
      self.参战单位[目标].魔法=self.参战单位[目标].魔法+临时数值
      if 道具数据.药性 ~= nil  and 药性=="藏神" then
        self:添加状态("护盾",self.参战单位[目标],self.参战单位[编号],阶品*8+75,编号)
        self.战斗流程[#self.战斗流程].挨打方[1].添加状态="护盾"
      end
    if self.参战单位[目标].魔法>self.参战单位[目标].最大魔法 then self.参战单位[目标].魔法=self.参战单位[目标].最大魔法 end
      使用=true
    end
  elseif 使用类型==3 then
    local 临时数值=玩家数据[id].道具:取加血道具1(名称,道具1)
    if 编号~=nil and self:取奇经八脉是否有(编号,"安抚") then
      临时数值=qz(临时数值*1.5)
    end
    if self.参战单位[目标].类型~="角色" or self.参战单位[目标].法术状态.魔音摄魂 or self.参战单位[目标].法术状态.死亡召唤 or self.参战单位[目标].法术状态.锢魂术 or self.参战单位[目标].气血>0 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"当前状态无法使用物品")
      return
    else
      self.战斗流程[#self.战斗流程+1]={流程=60,攻击方=编号,挨打方={{挨打方=目标,解除状态={},特效={"加血"}}},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
      local 气血=self:取恢复气血(编号,目标,临时数值)
    if self.参战单位[目标].识药特性~=nil then
      气血=qz(气血*(1+self.参战单位[目标].识药特性*0.05))
    end
    local 药性 = 道具数据.药性
    local 阶品 = 道具数据.阶品
      if 药性 ~= nil and 药性=="倍愈" then
        气血=气血*2
      end
      if 道具数据.药性 ~= nil  and 药性=="藏神" then
        self:添加状态("护盾",self.参战单位[目标],self.参战单位[编号],阶品*8+75,编号)
        self.战斗流程[#self.战斗流程].挨打方[1].添加状态="护盾"
      end
  	self:恢复伤势(目标,气血)
  	self.战斗流程[#self.战斗流程].挨打方[1].恢复伤势=气血
  	self.战斗流程[#self.战斗流程].挨打方[1].伤势类型=2
    self:增加气血(目标,气血)
    self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=气血
    self.战斗流程[#self.战斗流程].挨打方[1].复活=true

    使用=true

    ---0914机制修复
    self.执行中复活单位[#self.执行中复活单位+1]=目标
    self.回合中复活=true

    end
  elseif 使用类型==4 then
    临时数值=玩家数据[id].道具:取加魔道具1(名称,道具1)
    if 编号~=nil and self:取奇经八脉是否有(编号,"安抚") then
      临时数值=qz(临时数值*1.5)
    end
    if self.参战单位[目标].类型~="角色" or self.参战单位[目标].法术状态.魔音摄魂 or self.参战单位[目标].气血<=0 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"当前状态无法使用物品")
      return
    else
    self.战斗流程[#self.战斗流程+1]={流程=60,攻击方=编号,挨打方={{挨打方=目标,解除状态={},特效={"加蓝"}}},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
      self.参战单位[目标].愤怒=self.参战单位[目标].愤怒+临时数值
      if self.参战单位[目标].愤怒>150 then self.参战单位[目标].愤怒=150 end
      使用=true
      if 名称=="女儿红" or 名称=="梅花酒"  then
        self.战斗流程[#self.战斗流程+1]={流程=207,攻击方=编号,挨打方={{挨打方=目标,增加状态="催眠符",特效={"加血"}}}}
        self:添加状态("催眠符",self.参战单位[目标],self.参战单位[编号],150,编号)
        self.参战单位[目标].法术状态.催眠符.回合=取随机数(2,3)
        self.战斗流程[#self.战斗流程].挨打方[1].添加状态="催眠符"
      elseif 名称=="蛇胆酒" then
        self.参战单位[目标].防御=self.参战单位[目标].防御-qz(临时数值*1.5)
      elseif 名称=="百味酒" then
        if 取随机数()<=50 then
          self.战斗流程[#self.战斗流程+1]={流程=207,攻击方=编号,挨打方={{挨打方=目标,增加状态="催眠符",特效={"加血"}}}}
          self:添加状态("催眠符",self.参战单位[目标],self.参战单位[编号],150,编号)
          self.参战单位[目标].法术状态.催眠符.回合=取随机数(2,3)
          self.战斗流程[#self.战斗流程].挨打方[1].添加状态="催眠符"
        else
          self.战斗流程[#self.战斗流程+1]={流程=207,攻击方=编号,挨打方={{挨打方=目标,增加状态="毒",特效={"加血"}}}}
          self:添加状态("毒",self.参战单位[目标],self.参战单位[编号],150,编号)
          self.参战单位[目标].法术状态.毒.回合=5
          self.战斗流程[#self.战斗流程].挨打方[1].添加状态="毒"
        end
      elseif 名称=="醉生梦死" or 名称=="虎骨酒"  then
      self.战斗流程[#self.战斗流程+1]={流程=207,攻击方=编号,挨打方={{挨打方=目标,增加状态="疯狂",特效={"加血"}}}}
      self:添加状态("疯狂",self.参战单位[目标],self.参战单位[编号],150,编号)
      self.参战单位[目标].法术状态.疯狂.回合=取随机数(2,3)
      -- self.战斗流程[#self.战斗流程].挨打方[1].添加状态="疯狂"
      end
    end
  elseif 使用类型==5 then
    if self.参战单位[目标].乾坤袋==nil then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你无法对此类目标使用乾坤袋")
      return
    elseif self.参战单位[编号].类型~="角色" then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/只有角色才可以使用此道具")
      return
    else
      self.战斗流程[#self.战斗流程+1]={流程=56,攻击方=编号,挨打方={},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
      self.战斗流程[#self.战斗流程].挨打方[1]={挨打方=目标,特效={"水遁"}}
      local 百分比=qz(100-self.参战单位[编号].气血/self.参战单位[编号].最大气血*100)
      百分比=百分比+20
      if 百分比>=取随机数() then
        self.战斗流程[#self.战斗流程].挨打方[1].气血=self.参战单位[目标].气血
        self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,self.参战单位[目标].气血,编号)
        任务数据[self.任务id].乾坤袋=true
        玩家数据[self.参战单位[编号].玩家id].角色:刷新任务跟踪()
      end
    end
  elseif 使用类型==6 then
    local 等级=self:取技能等级(编号,"满天花雨")
    local 人数=1
    local 等级伤害=0
    local 伤害=道具数据.分类
    local 暗器伤害=0
    人数 = math.floor(等级/25)+1
    if 等级 == 0 then
      等级 = 30
    end
    等级伤害 = math.floor(等级/40)*伤害
    暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    if self.战斗类型 == 110009 and self.参战单位[目标].模型=="星灵仙子" then
      伤害=伤害*50
    end

    local 目标组=self:取多个敌方目标(编号,目标,人数)
    伤害=伤害*0.7+暗器伤害/2+等级伤害*0.5
    if self.参战单位[编号].固定伤害 ~= nil then
      伤害 = 伤害 + qz(self.参战单位[编号].固定伤害)
    end

    if #目标组>0 then
      self.战斗流程[#self.战斗流程+1]={流程=611,攻击方=编号,挨打方={},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
      for n=1,#目标组 do
        self.战斗流程[#self.战斗流程].挨打方[n]={挨打方=目标组[n],伤害=self:取固伤结果(编号,伤害,目标组[n])}
        self.战斗流程[#self.战斗流程].挨打方[n].死亡=self:减少气血(目标组[n],self.战斗流程[#self.战斗流程].挨打方[n].伤害,编号,名称)
      end
      玩家数据[id].道具.数据[道具1].耐久=玩家数据[id].道具.数据[道具1].耐久-1
      if 玩家数据[id].道具.数据[道具1].耐久<=0 then
        玩家数据[id].道具.数据[道具1]=nil
        玩家数据[id].角色.数据.道具[道具]=nil
      end
      return
    end
  end
  if 使用 then
    if 道具数据.数量~=nil then
      玩家数据[id].道具.数据[道具1].数量=玩家数据[id].道具.数据[道具1].数量-1
    end
      if 玩家数据[id].道具.数据[道具1].数量==nil or 玩家数据[id].道具.数据[道具1].数量<=0 then
        玩家数据[id].道具.数据[道具1]=nil
        玩家数据[id].角色.数据.道具[道具]=nil
      end
    end
  end

function 战斗处理类:兵解符计算(编号)
  local id=self.参战单位[编号].玩家id
  local 编号=0
  for n=1,#self.参战玩家 do
    if self.参战玩家[n].id==id then
      self.参战玩家[n].断线=false
      self.参战玩家[n].断线等待=true
      self.参战玩家[n].连接id=玩家数据[id].连接id
      编号=n
    end
  end
  if 玩家数据[id].角色.数据.地图数据.编号>=6010 and 玩家数据[id].角色.数据.地图数据.编号<=6019 then
        常规提示(id,"该地图无法传送")
        return
      end
    战斗准备类.战斗盒子[玩家数据[id].战斗]:结束战斗1(0,id)
    发送数据(玩家数据[id].连接id,1501,self.发送数据)
    地图处理类:跳转地图(id,1135,72,63)
end
function 战斗处理类:逃跑计算(编号,附加几率)
  if 附加几率 ~= nil then
    几率 = 附加几率 end
  local 成功=false
  local 几率=30
  if self.参战单位[编号].法术状态.捆仙绳~=nil and (self.战斗类型==410005 or self.战斗类型==200004 or self.战斗类型==200005 or self.战斗类型==200006 or self.战斗类型==300001) then
    几率=100
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/比武不能逃跑！")
  end
   if self.参战单位[编号].指令.类型=="逃跑"  and  self.参战单位[编号].法术状态.捆仙绳~=nil then
        几率=70
       end
  if self.参战单位[编号].指令.参数=="兵解符" then
    几率=0
  end
  if 取随机数(1,100)>=几率 then
    成功=true
  end
  self.执行等待=self.执行等待+10
  local 结束=false
  if 成功 and self.参战单位[编号].类型=="角色" then
    结束=true
    if #self.参战玩家==1 then
      self.全局结束=true
    end --不再执行动作
  end
  if 成功 then
    self.参战单位[编号].逃跑=true
  end
  if self.参战单位[编号].队伍==0  then
    self.战斗流程[#self.战斗流程+1]={流程=601,攻击方=编号,id=0,挨打方={{挨打方=1}},成功=成功,结束=结束}
    if self.参战单位[编号].捉鬼变异 then
      任务数据[self.任务id].变异奖励=true
    end
    return
  else
    self.战斗流程[#self.战斗流程+1]={流程=601,攻击方=编号,id=self.参战单位[编号].玩家id,挨打方={{挨打方=1}},成功=成功,结束=结束}
  end
  --计算召唤兽
  if 成功 then
    local id=self.参战单位[编号].玩家id
    local 临时编号=0
    if self.参战单位[编号].类型~="角色"  then
      for n=1,#玩家数据[id].召唤兽.数据 do
        if 玩家数据[id].召唤兽.数据[n].认证码==玩家数据[id].角色.数据.参战宝宝.认证码 then
          玩家数据[id].召唤兽.数据[n].参战信息=nil
          临时编号=n
        end
      end
      玩家数据[id].角色.数据.参战宝宝={}
      玩家数据[id].角色.数据.参战信息=nil
      发送数据(玩家数据[id].连接id,18,玩家数据[id].角色.数据.参战宝宝)
    else
      if self.参战单位[编号].召唤兽~=nil and self.参战单位[self.参战单位[编号].召唤兽]~=nil then
        self.战斗流程[#self.战斗流程].追加=self.参战单位[编号].召唤兽
        self.参战单位[self.参战单位[编号].召唤兽].逃跑=true
      end
    end
  end
end

function 战斗处理类:召唤计算(编号)
  local id=self.参战单位[编号].召唤兽
  local 目标=self.参战单位[编号].指令.目标
  local 玩家id=self.参战单位[编号].玩家id
  --  if self.参战单位[编号].指令.目标>#玩家数据[玩家id].召唤兽.数据  then
  --     self:召唤计算助战(编号)
  --    return
  -- end

  if 玩家数据[玩家id] == nil then
    print("玩家数据玩家ID为NIL,玩家ID为"..玩家id)
  elseif 玩家数据[玩家id].召唤兽.数据[目标] == nil then
    print("召唤兽为NIL,目标为"..目标)
  elseif 玩家数据[玩家id].召唤兽.数据[目标].等级 == nil then
    print("召唤时等级为NIL,召唤目标为"..目标)
  end
  self.参战单位[编号].召唤数量=self.参战单位[编号].召唤数量 or {}
  if id~=nil and self.参战单位[id].法术状态.复活~=nil then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你有召唤兽尚在复活中，暂时无法召唤新的召唤兽")
    return
    elseif #self.参战单位[编号].召唤数量>=7 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你在本次战斗中可召唤的数量已达上限")
    return
  elseif 玩家数据[玩家id].召唤兽.数据[目标].助战参战  then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/助战已经参战了该宝宝")
    return
  elseif 玩家数据[玩家id].召唤兽.数据[目标].参战信息 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/出战中")
    return
  -- elseif 玩家数据[玩家id].召唤兽.数据[目标].参战等级>玩家数据[玩家id].角色.数据.等级 then
  --   self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你不能召唤参战等级高于你的召唤兽")
  --   return
  elseif 玩家数据[玩家id].召唤兽.数据[目标].等级 > 玩家数据[玩家id].角色.数据.等级+10 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/以你目前的实力还无法驾驭该等级的召唤兽")
    return
  elseif 玩家数据[玩家id].召唤兽.数据[目标].成长>=3.01 then
    常规提示(self.参战单位[编号].玩家id,编号,"目前阶段成长大于3的宠物无法参战")
    return
  end
  for n=1,#self.参战单位[编号].召唤数量 do
    if self.参战单位[编号].召唤数量[n]==目标 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/这只召唤兽已经出战过了")
      return
    end
  end
  self.执行等待=self.执行等待+2
  if id==nil then
    self:设置队伍区分(self.参战单位[编号].队伍)
    id=#self.参战单位+1
  end
  if self.参战单位[编号].助战编号 then
    for k,v in pairs(self.参战单位) do
      if v.助战编号 and v.助战编号-5==self.参战单位[编号].助战编号 then
        id=k
        break
      end
    end
  end
  self.参战单位[id]={}
  local master
  for k,v in pairs(self.参战单位) do
    if v.玩家id and v.玩家id==self.参战单位[编号].玩家id and v.助战编号==nil then
      master=k
      break
    end
  end
  self.参战单位[id]=table.loadstring(玩家数据[玩家id].召唤兽:获取指定数据(目标))
  self.参战单位[id].队伍=self.参战单位[编号].队伍
  self.参战单位[id].位置=self.参战单位[编号].位置+5
  self.参战单位[id].类型="bb"
  self.参战单位[id].主人=master
  self.参战单位[id].玩家id=玩家id
  self.参战单位[id].附加阵法=self.参战单位[编号].附加阵法
  self.参战单位[id].法防=qz(self.参战单位[id].灵力)
  self.参战单位[id].命中=self.参战单位[id].伤害
  self.参战单位[id].躲闪=0
  self.参战单位[id].自动战斗=self.参战单位[master].自动战斗
  self.参战单位[编号].召唤兽=id
  self.参战单位[id].已加技能={}
  self.参战单位[id].主动技能={}
  self.参战单位[编号].召唤数量[#self.参战单位[编号].召唤数量+1]=目标
  self.参战单位[id].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
  self.参战单位[id].攻击修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.攻击控制力[1]
  self.参战单位[id].法术修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.法术控制力[1]
  self.参战单位[id].防御修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.防御控制力[1]
  self.参战单位[id].抗法修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.抗法控制力[1]
  self.参战单位[id].法术状态={}
  self.参战单位[id].奇经八脉={}
  self.参战单位[id].追加法术={}
  self.参战单位[id].附加状态={}
  self.参战单位[id].驱怪=0
  self.参战单位[id].慈悲效果=0
  self.参战单位[id].怒击效果=false
  self.参战单位[id].猎术修炼=0
  self.参战单位[id].毫毛次数=0
  self.参战单位[id].法宝佩戴={}
  self.参战单位[id].攻击五行=""
  self.参战单位[id].防御五行=""
  self.参战单位[id].攻击五行=""
  self.参战单位[id].防御五行=""
  if self.参战单位[id].符石技能效果==nil then
    self.参战单位[id].符石技能效果={}
  end
  self:添加bb法宝属性(id,玩家id)
  if self.参战单位[编号].助战编号 then
    self.参战单位[master].助战明细[#self.参战单位[master].助战明细+1] = id
  else
    local 临时技能={}
    for n=1,#玩家数据[玩家id].召唤兽.数据 do
      if 玩家数据[玩家id].召唤兽.数据[n].认证码==玩家数据[玩家id].角色.数据.参战宝宝.认证码 then
        玩家数据[玩家id].召唤兽.数据[n].参战信息=nil
      end
    end
    玩家数据[玩家id].角色.数据.参战宝宝={}
    玩家数据[玩家id].角色.数据.参战宝宝=table.loadstring(table.tostring(玩家数据[玩家id].召唤兽:取存档数据(目标)))
    玩家数据[玩家id].角色.参战信息=1
    玩家数据[玩家id].召唤兽.数据[目标].参战信息=1
  end
    发送数据(玩家数据[玩家id].连接id,18,玩家数据[玩家id].角色.数据.参战宝宝)
  self.战斗流程[#self.战斗流程+1]={流程=600,攻击方=编号,挨打方={{挨打方=id,队伍=self.参战单位[编号].队伍,数据=self:取加载信息(id)}}}
  self:单独重置属性(id)
  if self.参战单位[id].隐身~=nil then
    self.参战单位[id].指令={目标=id}
    self:增益技能计算(id,"修罗隐身",self.参战单位[id].等级)
    if self.参战单位[id].法术状态.修罗隐身~=nil then
      self.参战单位[id].法术状态.修罗隐身.回合=self.参战单位[id].隐身
    end
  end
  if self.参战单位[id].盾气~=nil then
      self.参战单位[id].指令={目标=id}
      self:增益技能计算(id,"盾气",self.参战单位[id].等级,nil,nil,nil,self.参战单位[id].盾气)
      if self.参战单位[id].法术状态.盾气~=nil then
        self.参战单位[id].法术状态.盾气.回合=6

      end
    end
  if self.参战单位[id].模型=="小精灵" or self.参战单位[id].模型=="进阶小精灵" then
     self:恢复技能计算(id,"峰回路转",self.参战单位[id].等级)
  end
    if self.参战单位[id].模型=="鲲鹏" or self.参战单位[id].模型=="进阶鲲鹏" or self.参战单位[id].模型=="海毛虫" then
     self:法攻技能计算(id,"扶摇万里",self.参战单位[id].等级,编号)
  end
    -- if self:取玩家战斗() then
    -- self.参战单位[id].最大气血=self.参战单位[id].最大气血+5000
    -- self.参战单位[id].气血=self.参战单位[id].气血+5000
    -- end
    -- if self.参战单位[id].气血>self.参战单位[id].最大气血 then
    --    self.参战单位[id].气血=self.参战单位[id].最大气血
    --  end

  if self.回合数>=2 then
    if self.参战单位[id].特性 ~= nil then
      self:添加状态特性(id)
    end
    if self.参战单位[id].进击必杀 ~= nil then
      self:添加状态("进击必杀",self.参战单位[id],self.参战单位[id],self.参战单位[id].进击必杀,id)
    end
    if self.参战单位[id].进击法爆 ~= nil then
      self:添加状态("进击法爆",self.参战单位[id],self.参战单位[id],self.参战单位[id].进击法爆,id)
    end
  end
end

function 战斗处理类:召唤孩子计算(编号)
  local id=self.参战单位[编号].召唤兽
  local 玩家id=self.参战单位[编号].玩家id
  local 目标=self.参战单位[编号].指令.目标-#玩家数据[玩家id].召唤兽.数据
  if 玩家数据[玩家id] == nil then
    print("玩家数据玩家ID为NIL,玩家ID为"..玩家id)
  elseif 玩家数据[玩家id].召唤兽.数据[目标] == nil then
    print("孩子为NIL,目标为"..目标)
  elseif 玩家数据[玩家id].召唤兽.数据[目标].等级 == nil then
    print("召唤时等级为NIL,召唤目标为"..目标)
  end
  if id~=nil and self.参战单位[id].法术状态.复活~=nil then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你有召唤兽尚在复活中，暂时无法召唤新的召唤兽")
    return
  elseif #self.参战单位[编号].召唤数量>=5 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你在本次战斗中可召唤的数量已达上限")
    return
  elseif 玩家数据[玩家id].召唤兽.数据[目标].等级 > 玩家数据[玩家id].角色.数据.等级+10 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/以你目前的实力还无法驾驭该等级的孩子")
    return
  end
  for n=1,#self.参战单位[编号].召唤数量 do
    if self.参战单位[编号].召唤数量[n]==目标 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/这只孩子已经出战过了")
      return
    end
  end
  self.执行等待=self.执行等待+2
  if id==nil then
    self:设置队伍区分(self.参战单位[编号].队伍)
    id=#self.参战单位+1
  end
  self.参战单位[id]={}
  self.参战单位[id]=table.loadstring(玩家数据[玩家id].召唤兽:获取指定数据(目标))
  self.参战单位[id].队伍=self.参战单位[编号].队伍
  self.参战单位[id].位置=self.参战单位[编号].位置+5
  self.参战单位[id].类型="孩子"
  self.参战单位[id].主人=编号
  self.参战单位[id].玩家id=玩家id
  self.参战单位[id].附加阵法=self.参战单位[编号].附加阵法
  self.参战单位[id].法防=qz(self.参战单位[id].灵力)
  self.参战单位[id].命中=self.参战单位[id].伤害
  self.参战单位[id].躲闪=0
  self.参战单位[id].自动战斗=self.参战单位[编号].自动战斗
  self.参战单位[编号].召唤兽=id
  self.参战单位[id].已加技能={}
  self.参战单位[id].主动技能={}
  self.参战单位[编号].召唤数量[#self.参战单位[编号].召唤数量+1]=目标-#玩家数据[玩家id].召唤兽.数据
  self.参战单位[id].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
  self.参战单位[id].攻击修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.攻击控制力[1]
  self.参战单位[id].法术修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.法术控制力[1]
  self.参战单位[id].防御修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.防御控制力[1]
  self.参战单位[id].抗法修炼=玩家数据[self.参战单位[id].玩家id].角色.数据.bb修炼.抗法控制力[1]
  self.参战单位[id].法术状态={}
  self.参战单位[id].奇经八脉={}
  self.参战单位[id].追加法术={}
  self.参战单位[id].附加状态={}
  self.参战单位[id].驱怪=0
  self.参战单位[id].慈悲效果=0
  self.参战单位[id].怒击效果=false
  self.参战单位[id].猎术修炼=0
  self.参战单位[id].毫毛次数=0
  self.参战单位[id].法宝佩戴={}
  self.参战单位[id].攻击五行=""
  self.参战单位[id].防御五行=""
  self.参战单位[id].攻击五行=""
  self.参战单位[id].防御五行=""
  self:添加bb法宝属性(id,玩家id)
  for n=1,#玩家数据[玩家id].召唤兽.数据 do
    if 玩家数据[玩家id].召唤兽.数据[n].认证码==玩家数据[玩家id].角色.数据.参战宝宝.认证码 then
      玩家数据[玩家id].召唤兽.数据[n].参战信息=nil
    end
  end
  玩家数据[玩家id].角色.数据.参战宝宝={}
  玩家数据[玩家id].角色.数据.参战信息=nil
  self.战斗流程[#self.战斗流程+1]={流程=600,攻击方=编号,挨打方={{挨打方=id,队伍=self.参战单位[编号].队伍,数据=self:取加载信息(id)}}}
  self:单独重置属性(id)
  if self.参战单位[id].隐身~=nil then
    self.参战单位[id].指令={目标=id}
    self:增益技能计算(id,"修罗隐身",self.参战单位[id].等级)
    if self.参战单位[id].法术状态.修罗隐身~=nil then
      self.参战单位[id].法术状态.修罗隐身.回合=self.参战单位[id].隐身
    end
  end
  if self.参战单位[id].盾气~=nil then
      self.参战单位[id].指令={目标=id}
      self:增益技能计算(id,"盾气",self.参战单位[id].等级,nil,nil,nil,self.参战单位[id].盾气)
      if self.参战单位[id].法术状态.盾气~=nil then
        self.参战单位[id].法术状态.盾气.回合=6

      end
    end
  if self:技能是否存在(id,"峰回路转") then
     self:恢复技能计算(id,"峰回路转",self.参战单位[id].等级)
  end
end

function 战斗处理类:单独重置属性(n)
  self.参战单位[n].法术状态={}
  self.参战单位[n].奇经八脉={}
  self.参战单位[n].追加法术={}
  self.参战单位[n].附加状态={}
  self.参战单位[n].攻击修炼=0
  self.参战单位[n].法术修炼=0
  self.参战单位[n].防御修炼=0
  self.参战单位[n].抗法修炼=0
  self.参战单位[n].猎术修炼=0
  if self.参战单位[n].主动技能==nil then
    self.参战单位[n].主动技能={}
  end
  self.参战单位[n].特技技能={}
  self.参战单位[n].战意=0
  self.参战单位[n].法暴=0
  --self.参战单位[n].法防=0
  self.参战单位[n].必杀=1
  self.参战单位[n].攻击五行=""
  self.参战单位[n].防御五行=""
  self.参战单位[n].修炼数据={法修=0,抗法=0,攻击=0,猎术=0}
  if self.参战单位[n].命中==nil then self.参战单位[n].命中=self.参战单位[n].伤害 end
  for i=1,#灵饰战斗属性 do
    self.参战单位[n][灵饰战斗属性[i]]=0
  end
  if self.参战单位[n].类型~="角色"  then
    self:添加技能属性(self.参战单位[n],self.参战单位[n].技能)
    if self.参战单位[n].法术认证~=nil then
      self:添加认证法术属性(self.参战单位[n],self.参战单位[n].法术认证)
    end
    if self.参战单位[n].装备[1] ~= nil  and self.参战单位[n].装备[2] ~= nil and self.参战单位[n].装备[3] ~= nil then
      if self.参战单位[n].装备[1].套装效果 ~= nil and self.参战单位[n].装备[2].套装效果 ~= nil and self.参战单位[n].装备[3].套装效果 ~= nil then
        if self.参战单位[n].装备[1].套装效果[2] == self.参战单位[n].装备[2].套装效果[2] and self.参战单位[n].装备[1].套装效果[2] == self.参战单位[n].装备[3].套装效果[2] and self.参战单位[n].装备[2].套装效果[2] == self.参战单位[n].装备[3].套装效果[2] then
          self.参战单位[n].追加法术={[1]={名称=self.参战单位[n].装备[1].套装效果[2],等级=self.参战单位[n].等级}}
          self.参战单位[n].套装追加概率=30
          self:添加技能属性(self.参战单位[n],self.参战单位[n].装备[1].套装效果[2])
        end
      end
    end

          if self.参战单位[n].统御 ~= nil then
        local 坐骑编号 = self.参战单位[n].统御
        local 玩家id = self.参战单位[n].玩家id
        if 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号] ~= nil then
          if 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 <= 50 and 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 > 2 then
            玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 = 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 - 2
            发送数据(玩家数据[玩家id].连接id,38,{内容="你的坐骑#R"..玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].名称.."#W减少了2点饱食度"})
          elseif 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 > 50 then
            玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 = 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 - 1
            发送数据(玩家数据[玩家id].连接id,38,{内容="你的坐骑#R"..玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].名称.."#W减少了1点饱食度"})
          end
          if 玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].忠诚 <= 0 then
            玩家数据[玩家id].角色:坐骑刷新(坐骑编号)
            发送数据(玩家数据[玩家id].连接id,38,{内容="你的坐骑#R"..玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].名称.."#W已经饥饿难耐无法给予统御召唤兽加成了"})
          else
            self:添加技能属性(self.参战单位[n],玩家数据[玩家id].角色.数据.坐骑列表[坐骑编号].技能)
          end
        end
      end

    if  self.参战单位[n].类型~="孩子 "  then
      self:添加内丹属性(self.参战单位[n],self.参战单位[n].内丹)
    end
    self.参战单位[n].攻击修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.攻击控制力[1]
    self.参战单位[n].法术修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.法术控制力[1]
    self.参战单位[n].防御修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.防御控制力[1]
    self.参战单位[n].抗法修炼=玩家数据[self.参战单位[n].玩家id].角色.数据.bb修炼.抗法控制力[1]
  end

end

function 战斗处理类:捕捉计算(编号)
  if self.战斗类型~=100001 and self.战斗类型~=100005 and self.战斗类型~=100007  and self.战斗类型~=100221 and self.战斗类型~=100225 then
    return
  end
  local 目标=self.参战单位[编号].指令.目标


  for i=1,#取随机神兽 do
      if 取随机神兽[i] == self.参战单位[目标].模型 then
         self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/神兽无法被捕获")
         return
      end
  end

  if self.参战单位[目标].模型=="谛听" then
         self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/谛听无法被捕获")
         return
  end


  if self:取目标状态(攻击,目标,1)==false then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/目标当前无法被捕获")
    return
  elseif self.参战单位[目标].类型=="角色" or self.参战单位[目标].类型=="召唤" then
  self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/目标当前无法被捕获!")
  return
  elseif self.参战单位[编号].自动战斗 then
  self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/自动状态无法抓宠")
  return
  elseif self.参战单位[目标].精灵 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你无法捕获这样的目标")
    return
      elseif self.参战单位[目标].队伍~=0 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你无法捕获这样的目标")
    return
  -- elseif self.参战单位[目标].参战等级~=nil and self.参战单位[目标].参战等级 > self.参战单位[编号].等级 then
  --   self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你目前等级无法捕获这样的目标")
  --   return
  elseif self.参战单位[编号].魔法<qz(self.参战单位[目标].等级*0.5+20) then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你没有足够的魔法")
    return
  elseif 玩家数据[self.参战单位[编号].玩家id].角色:取新增宝宝数量()==false then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前无法携带更多的召唤兽")
    return
  end
  self.执行等待=self.执行等待+15
  self.参战单位[编号].魔法=self.参战单位[编号].魔法-qz(self.参战单位[目标].等级*0.5+20)
  self.战斗流程[#self.战斗流程+1]={流程=300,攻击方=编号,挨打方={{挨打方=目标}}}
  local 初始几率=20
  初始几率=初始几率+qz(self.参战单位[目标].最大气血/self.参战单位[目标].气血)*10+qz(self.参战单位[目标].猎术修炼*5)
  if self:取符石组合效果(编号,"心灵手巧") then
    初始几率=初始几率+self:取符石组合效果(编号,"心灵手巧")
  end
  self.战斗流程[#self.战斗流程].宝宝=玩家数据[self.参战单位[编号].玩家id].角色.数据.宠物.模型
  self.战斗流程[#self.战斗流程].名称=玩家数据[self.参战单位[编号].玩家id].角色.数据.宠物.名称
  if 取随机数()<=初始几率 then
    self.战斗流程[#self.战斗流程].捕捉成功=true
    if self.战斗类型==100225 then
    local 物法 = "法系"
    if 取随机数(1,100)<=50 then
    物法 = nil
    end
    玩家数据[self.参战单位[编号].玩家id].召唤兽:添加召唤兽(self.参战单位[目标].模型,false,false,true,self.参战单位[目标].等级,物法)
    else
    玩家数据[self.参战单位[编号].玩家id].召唤兽:添加召唤兽(self.参战单位[目标].模型,self.参战单位[目标].分类,self.参战单位[目标].分类,false,self.参战单位[目标].等级)
    end
    self.参战单位[目标].气血=0
    self.参战单位[目标].捕捉=true
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你成功捕获了#R/"..self.参战单位[目标].名称)
  end
end

function 战斗处理类:法术计算(编号)
  local 名称=self.参战单位[编号].指令.参数
  local 目标=self.参战单位[编号].指令.目标
  local 等级=self:取技能等级(编号,名称)
  if 名称=="高级连击" or 名称 == "理直气壮" or 名称 == "牛刀小试" then
    等级=self.参战单位[编号].等级
    if 等级 == 0 then
      等级=10
    end
  end

  if 等级==0 and 装备特技[名称]==nil then
    return
  end
  if self:物攻技能(名称) then
     self:物攻技能计算(编号,名称,等级)
  elseif self:封印技能(名称) then
    self:单体封印技能计算(编号,名称,等级)
  elseif self:群体封印技能(名称) then
    self:群体封印技能计算(编号,名称,等级)
  elseif self:增益技能(名称) then
    self:增益技能计算(编号,名称,等级)
  elseif self:减益技能(名称) then
    self:减益技能计算(编号,名称,等级)
  elseif self:法攻技能(名称) then
    self:法攻技能计算(编号,名称,等级,1)
      if self.参战单位[编号].法连~=nil and self.参战单位[编号].法连>=取随机数() then
        if self.参战单位[编号].双星爆 ~= nil then
         self:法攻技能计算(编号,名称,等级,(0.5+self.参战单位[编号].双星爆))
        else
          self:法攻技能计算(编号,名称,等级,0.5)
        end
      end
  if 名称=="飞砂走石" then   --增加单技能属性
  self.参战单位[编号].法暴=self.参战单位[编号].法暴-5
  elseif 名称=="三昧真火" then
  self.参战单位[编号].法暴=self.参战单位[编号].法暴-10
  elseif 名称=="摇头摆尾" then
  self.参战单位[编号].法暴=self.参战单位[编号].法暴-10
  end
  if 名称=="落叶萧萧" and self.参战单位[编号].类型=="角色" then
  if self.参战单位[编号].法连==nil then
  self.参战单位[编号].法连=0
  end
  self.参战单位[编号].法连=self.参战单位[编号].法连-10
  end
  elseif self:恢复技能(名称) then
    self:恢复技能计算(编号,名称,等级)
  elseif 名称=="妙手空空" then
    self:妙手空空计算(编号,名称,等级)
  end
end

function 战斗处理类:添加提示(id,攻击方,内容)
  if self.参战单位[攻击方].队伍==0 then return  end
  self.战斗流程[#self.战斗流程+1]={流程=900,攻击方=攻击方,id=id,内容=内容}
end

function 战斗处理类:添加提示1(id,攻击方,内容)
  if self.参战单位[攻击方].队伍==0 then return  end
  self.战斗流程[#self.战斗流程+1]={流程=901,攻击方=攻击方,id=id,内容=内容}
end

function 战斗处理类:添加提示2(id,编号,内容)
  if self.参战单位[编号].队伍==0 then return  end
  发送数据(玩家数据[id].连接id,38,内容)
end

function 战斗处理类:飞镖计算(编号,id组)
  self.战斗流程[#self.战斗流程+1]={流程=611,攻击方=编号,挨打方={}}
  self.执行等待=self.执行等待+10
  --print(#id组)
  for n=1,#id组 do
    --print(self:取目标状态(编号,id组[n].id,1),id组[n].id)
    if self:取目标状态(编号,id组[n].id,1) then
      self.战斗流程[#self.战斗流程].挨打方[#self.战斗流程[#self.战斗流程].挨打方+1]={挨打方=id组[n].id,伤害=id组[n].伤害}
      self.战斗流程[#self.战斗流程].挨打方[#self.战斗流程[#self.战斗流程].挨打方].死亡=self:减少气血(id组[n].id,id组[n].伤害,编号,名称)
    end
  end
end

function 战斗处理类:妙手空空计算(编号,名称,等级)
  local 目标=self.参战单位[编号].指令.目标
  if 目标==nil or self.参战单位[目标].气血<=0 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/对方已经死了，你忍心从尸体上偷东西？")
    return
  elseif self.战斗类型~=100001 and self.战斗类型~=100007  then
    return
  elseif self.参战单位[目标].偷盗 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/对方身上已经没有宝物了")
    return
  elseif self:技能消耗(self.参战单位[编号],self.参战单位[目标].等级,名称,编号)==false then
    return
  end
  self.执行等待=self.执行等待+1
  local id=self.参战单位[编号].玩家id
  if  self.参战单位[目标].精灵==nil then
    if 等级*10>=取随机数() then
      local 随机金钱=取随机数(10,100)
      玩家数据[id].角色:添加银子(随机金钱,"[战斗]妙手空空从"..self.参战单位[目标].名称.."、"..self.参战单位[目标].模型.."身上盗取")
      self:添加提示1(self.参战单位[编号].玩家id,编号,"你得到了"..随机金钱.."金钱")
      self.参战单位[目标].偷盗=true
      return
    else
      self:添加提示1(self.参战单位[编号].玩家id,编号,"对方发觉了你这个行为，机灵地躲过去了！")
    end
  elseif self.参战单位[目标].精灵 then
    if 等级*10>=取随机数() then
      local 奖励参数=取随机数(1,100)
      if  奖励参数<=50 then
        if 变身卡数据[self.参战单位[目标].模型]~=nil then
          玩家数据[id].道具:给予道具(id,"怪物卡片",self.参战单位[目标].模型,1)
          self:添加提示1(self.参战单位[编号].玩家id,编号,"你得到了#R/怪物卡片")
        end
      elseif 奖励参数<=60 then
          self:添加提示1(self.参战单位[编号].玩家id,编号,"对方发觉了你这个行为，机灵地躲过去了！")
      elseif 奖励参数<=80 then
          self:添加提示1(self.参战单位[编号].玩家id,编号,"对方发觉了你这个行为，机灵地躲过去了！")
      else
          self:添加提示1(self.参战单位[编号].玩家id,编号,"对方发觉了你这个行为，机灵地躲过去了！")
      end
      self.参战单位[目标].偷盗=true
      return
    else
      self:添加提示1(self.参战单位[编号].玩家id,编号,"对方发觉了你这个行为，机灵地躲过去了！")
    end
  end
end

function 战斗处理类:恢复技能计算(编号,名称,等级)
  local 目标=self.参战单位[编号].指令.目标
  local 目标数=0
  local 法爆=0
  local 法爆几率=(self.参战单位[编号].法术暴击等级)*0.1
   if 名称=="七宝玲珑灯" then
     目标=self:取单个友方目标1(编号)
   end
  if  名称=="归元咒" or 名称=="乾天罡气" or 名称=="三花聚顶" or 名称=="气归术" or 名称=="命归术" or 名称=="凝神诀" or 名称=="凝气诀" then
      目标=编号
  end
  if 名称~="我佛慈悲" and 名称 ~= "慈航普渡"  and 名称~="还魂咒" and 名称~="杨柳甘露" and 名称~="起死回生" and 名称~="回魂咒" and 名称~="还阳术" and 名称~="莲花心音" and 名称~="由己渡人" then
      目标数=self:取目标数量(self.参战单位[编号],名称,等级,编号)
      目标=self:取多个友方目标(编号,目标,目标数,名称)
  elseif 名称 == "慈航普渡" then
      目标=self:取多个友方目标(编号,目标,5,名称)
      for i=1,#目标 do
        if self.参战单位[目标[i]].气血>0 or (self.参战单位[目标[i]].法术状态.死亡召唤~=nil and self.参战单位[目标[i]].法术状态.死亡召唤) or (self.参战单位[目标[i]].法术状态.锢魂术~=nil and self.参战单位[目标[i]].法术状态.锢魂术) or self.参战单位[目标[i]].类型 == "系统PK角色" then
          table.remove(目标,i)
        end
      end
  else
    if 名称~="杨柳甘露" and (self.参战单位[目标].法术状态.死亡召唤~=nil or self.参战单位[目标].法术状态.锢魂术~=nil) then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/友方存在不可复活BUFF,技能使用失败")
      return
    elseif 名称=="杨柳甘露" and ((self.参战单位[目标].法术状态.死亡召唤~=nil and self.参战单位[目标].法术状态.死亡召唤.回合>2) or (self.参战单位[目标].法术状态.锢魂术~=nil and self.参战单位[目标].法术状态.锢魂术.回合>2)) then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/友方存在不可复活BUFF,技能使用失败")
      return
    end
    --0914复活没有死亡单位无法复活
    if 名称=="杨柳甘露" or 名称=="莲花心音" or 名称=="我佛慈悲"or 名称=="由己渡人"or 名称=="还魂咒"or 名称=="起死回生"or 名称=="还阳术" then
     if self.参战单位[目标].气血>0 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/友方没有死亡，技能使用失败")
      return
    end
  end
    if 名称=="莲花心音" then
        if self.参战单位[目标].类型=="角色" or self.参战单位[目标].鬼魂==nil  then
          self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能只能对鬼魂生物生效")
          return
        end
    else
        if self.参战单位[目标].鬼魂~=nil then
          self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能对鬼魂生物无效")
          return
        elseif self.参战单位[目标].类型~="角色" then
          self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能只能对人物生效")
          return
        end
    end
      目标={目标}
  end
  if 名称=="妙悟" and self.参战单位[编号].妙悟回合~=nil and self.回合数-self.参战单位[编号].妙悟回合<5 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(5-(self.回合数-self.参战单位[编号].妙悟回合)).."#Y/回合后才可使用")
    return
  end

  for i=1,#目标 do
    if self.参战单位[目标[i]] == nil then
      table.remove(目标,i)
    end
  end
  if #目标==0 then return end
  目标数=#目标
  if 消耗==nil and self:技能消耗(self.参战单位[编号],目标数,名称,编号)==false then self:添加提示(self.参战单位[编号].玩家id,编号,"未到达技能消耗要求,技能使用失败") return  end
  self.战斗流程[#self.战斗流程+1]={流程=60,攻击方=编号,挨打方={},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
  self.执行等待=self.执行等待+10
  local 气血=0
  for n=1,目标数 do
      local 状态名称={}
      self.战斗流程[#self.战斗流程].挨打方[n]={挨打方=目标[n],特效={名称}}
      if 名称=="驱尸" or 名称=="解毒" or 名称=="清心" or 名称=="百毒不侵" then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],{"尸腐毒","毒","雾杀"})
         if 名称=="百毒不侵" then
             self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
             self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
           end
        elseif 名称=="无穷妙道" then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取门派封印法术("无底洞"))
         self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
          self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
        elseif 名称=="寡欲令" then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取门派封印法术("盘丝洞"))
         self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
         self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
        elseif 名称=="复苏" then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取门派封印法术("天宫"))
         self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
         self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
        elseif 名称=="解封" or 名称=="宁心" then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取门派封印法术("女儿村"))
          if 名称=="宁心" then
             self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
             self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
           end
        elseif 名称=="水清诀" or 名称=="玉清诀"  then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取异常状态法术())
        elseif 名称=="七宝玲珑灯" and  等级*2+20>取随机数() then
           状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取法宝异常法术())
        elseif 名称=="清心咒" then
           状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取法宝异常法术())
        elseif 名称=="冰清诀"  then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取异常状态法术())
          气血=qz(self.参战单位[目标[n]].最大气血*0.25)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="净世煌火"  then
          状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取异常状态法术())
         -- self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
          气血=qz(self.参战单位[目标[n]].最大气血*0.25)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="晶清诀"  then
          状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取异常状态法术())
          气血=qz(self.参战单位[目标[n]].最大气血*0.15)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="其徐如林"  then
          状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取异常状态法术())
           气血=qz(self.参战单位[目标[n]].最大气血*0.05)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].流程=160
        elseif 名称=="仙人指路"  then
          状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取异常状态法术())
          气血=qz(self.参战单位[目标[n]].最大气血*0.10)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="气疗术"  then
          气血=qz(self.参战单位[目标[n]].最大气血*0.03+200)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="心疗术"  then
          气血=qz(self.参战单位[目标[n]].最大气血*0.06+400)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
       elseif 名称=="命疗术"  then
          气血=qz(self.参战单位[目标[n]].最大气血*0.09+600)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="气归术" or 名称=="四海升平"  then
          气血=qz(self.参战单位[目标[n]].最大气血*0.25)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="命归术"  then
          气血=qz(self.参战单位[目标[n]].最大气血*0.5)
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="驱魔" then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取门派封印法术("方寸山"))
         self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
         self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
        elseif 名称=="清风望月" then
         状态名称=self:解除状态结果(self.参战单位[目标[n]],self:取异常状态法术())
         self:添加状态("反间之计",self.参战单位[目标[1]],self.参战单位[编号],等级,编号)
         self.战斗流程[#self.战斗流程].挨打方[1].添加状态="反间之计"
        elseif 名称=="推拿" then
          气血=等级*5+self.参战单位[编号].灵力*0.1
           if 编号~=nil and self:取奇经八脉是否有(编号,"心韧") then
            气血=气血*1.5
          end
          if self.参战单位[编号].法暴+法爆几率>=取随机数() then
            气血=气血*1.5
            self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
            self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
          end
          气血=self:取恢复气血(编号,编号,气血)
          self:增加气血(目标[n],气血)
          self:恢复伤势(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
          self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
        elseif 名称=="妙悟" then
          气血=等级*5+self.参战单位[编号].灵力*0.1
          if self.参战单位[编号].法暴+法爆几率>=取随机数() then
          气血=气血*1.5
          self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
          self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
          end
          气血=self:取恢复气血(编号,编号,气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.参战单位[目标[n]].速度=qz(self.参战单位[目标[n]].速度*1.05)
          self.参战单位[编号].妙悟回合=self.回合数
        elseif 名称=="活血" then
          气血=等级*5+self.参战单位[编号].速度*0.1
           if 编号~=nil and self:取奇经八脉是否有(编号,"心韧") then
          气血=气血*1.5
          end
          if self.参战单位[编号].法暴+法爆几率>=取随机数() then
          气血=气血*1.5
          self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
          self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
          end
          气血=self:取恢复气血(编号,编号,气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self:恢复伤势(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
          self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
        elseif 名称=="星月之惠" then
          气血=等级*4+self.参战单位[编号].灵力*0.1
          if self.参战单位[编号].法暴+法爆几率>=取随机数() then
          气血=气血*1.5
          self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
          self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
          end
          气血=self:取恢复气血(编号,编号,气血)
          self:增加气血(编号,气血)
          self.战斗流程[#self.战斗流程].挨打方[n].挨打方=编号
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self:恢复伤势(编号,气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
          self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
        elseif 名称=="推气过宫" then
          气血=(等级*8+self.参战单位[编号].灵力*0.1)*(1-目标数*0.05)
          if 编号~=nil and self:取奇经八脉是否有(编号,"佛显") then
          气血=气血*1.3
          end
          if self.参战单位[编号].法暴+法爆几率>=取随机数() then
          气血=气血*1.5
          self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
          self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
          end
          气血=self:取恢复气血(编号,编号,气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          --推气过宫正常不恢复伤势，少了救死扶伤和妙手回春2个技能，先把推伤给这里
          self:恢复伤势(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
          self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
        elseif 名称=="峰回路转" then
          气血=200
          气血=self:取恢复气血(编号,目标[n],气血,名称)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="地涌金莲" then
          气血=等级*4+(self.参战单位[编号].灵力*0.2)
          if 编号~=nil and self:取奇经八脉是否有(编号,"化莲") then
              气血=气血+qz(self.参战单位[编号].等级*3)
          end
          if 编号~=nil and self:取奇经八脉是否有(编号,"自愈") then
              气血=qz(气血*1.2)
          end
          if self.参战单位[编号].法术状态.同舟共济~=nil then
              气血=qz(气血*1.15)
          end
          if self.参战单位[编号].法暴+法爆几率>=取随机数() then
          气血=气血*1.5
          self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
          self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
          end
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self:恢复伤势(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
          self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="归元咒" then
          气血=等级*2+(self.参战单位[编号].灵力*0.1)
          if 编号~=nil and self:取奇经八脉是否有(编号,"吐纳") then
              气血=气血+qz(self.参战单位[编号].最大气血*0.2)
              self.参战单位[编号].魔法=self.参战单位[编号].魔法-qz(气血*0.25)
              if self.参战单位[编号].魔法<=0 then
                  self.参战单位[编号].魔法=0
              end
          end
          if self.参战单位[编号].法暴+法爆几率>=取随机数() then
          气血=气血*1.5
          self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
          self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
          end
          气血=self:取恢复气血(编号,目标[n],气血)
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="乾天罡气" then
          气血1=等级*2+(self.参战单位[编号].灵力*0.1)*0.5
          气血=等级*2+(self.参战单位[编号].灵力*0.1)
          self:增加魔法(编号,气血1)
          self.参战单位[编号].气血=self.参战单位[编号].气血-气血
          self.战斗流程[#self.战斗流程].扣除气血=气血
        elseif 名称=="三花聚顶" then
          气血1=等级*2+(self.参战单位[编号].灵力*0.1)*0.5
          气血=等级*2+(self.参战单位[编号].灵力*0.1)
          self:增加魔法(编号,气血1)
          self.参战单位[编号].气血=self.参战单位[编号].气血-气血
          self.战斗流程[#self.战斗流程].扣除气血=气血
        elseif 名称=="凝气诀" then
          气血=qz(self.参战单位[目标[n]].最大魔法*0.15+200)
          self:增加魔法(编号,气血)
        elseif 名称=="凝神诀" then
          气血=qz(self.参战单位[目标[n]].最大魔法*0.15+400)
          self:增加魔法(编号,气血)
        elseif 名称=="我佛慈悲" then
          气血=等级*3+self.参战单位[编号].灵力*0.1
           if 编号~=nil and self:取奇经八脉是否有(编号,"佛性") then
              气血=等级*6+self.参战单位[编号].灵力*0.1
          end
          气血=self:取恢复气血(编号,目标[n],气血,1)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          if 编号~=nil and self:取奇经八脉是否有(编号,"慈针") then
              self.参战单位[编号].愤怒=self.参战单位[编号].愤怒+80
              if self.参战单位[编号].愤怒>=150 then
                  self.参战单位[编号].愤怒=150
              end
          end
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
        elseif 名称=="由己渡人" then
          气血 = qz(等级*6)
          气血=self:取恢复气血(编号,目标[n],气血,1)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
        elseif 名称=="慈航普渡" then
          气血=self.参战单位[目标[n]].最大气血
          self:增加气血(目标[n],气血)
          气血=self:取恢复气血(编号,目标[n],气血,1)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2

          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          self.战斗流程[#self.战斗流程].扣除气血 = self.参战单位[编号].气血-1
          self.参战单位[编号].魔法=1
          self:减少气血(编号,self.战斗流程[#self.战斗流程].扣除气血)
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
        elseif 名称=="舍身取义" then
          气血=self.参战单位[目标[n]].最大气血
          if 编号~=nil and self:取奇经八脉是否有(编号,"天照") and 取随机数(1,100)<=50 then
            self:添加状态("达摩护体",self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
            self.战斗流程[#self.战斗流程].挨打方[n].添加状态="达摩护体"
          end
          if 编号~=nil and self:取奇经八脉是否有(编号,"感念") and 取随机数(1,100)<=50 then
            self:添加状态("金刚护体",self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
            self.战斗流程[#self.战斗流程].挨打方[n].添加状态="金刚护体"
          end
          self:增加气血(目标[n],气血)
          气血=self:取恢复气血(编号,目标[n],气血,1)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="杨柳甘露" then
          气血=等级*3+self.参战单位[编号].灵力*0.1
          if 编号~=nil and self:取奇经八脉是否有(编号,"玉帛") then
            气血=气血+qz(self.参战单位[编号].等级*2.5)
          end
          气血=self:取恢复气血(编号,目标[n],气血,1)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          if 编号~=nil and self:取奇经八脉是否有(编号,"甘露") and 取随机数() <=50 then
              self:添加状态("普渡众生",self.参战单位[目标[n]],self.参战单位[编号],90,编号)
              self.战斗流程[#self.战斗流程].挨打方[n].添加状态="普渡众生"
          end
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true

          elseif 名称=="还魂咒" then
          气血=qz(等级*2)
          气血=self:取恢复气血(编号,目标[n],气血,1)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
        elseif 名称=="起死回生" then
          气血=qz(self.参战单位[目标[n]].最大气血*0.5)
          if 气血>self.参战单位[目标[n]].等级*20 then
             气血=self.参战单位[目标[n]].等级*20+100
             end
          气血=self:取恢复气血(编号,目标[n],气血,1)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
        elseif 名称=="还阳术" then
             气血=qz(self.参战单位[目标[n]].最大气血*0.5)
          if 气血>self.参战单位[目标[n]].等级*20 then
             气血=self.参战单位[目标[n]].等级*20+100
             end
          气血=self:取恢复气血(编号,目标[n],气血,1)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          if self.参战单位[目标[n]].还阳术1==nil then
  			  self.参战单位[目标[n]].防御=qz(self.参战单位[目标[n]].防御*0.9)
  			  self.参战单位[目标[n]].伤害=qz(self.参战单位[目标[n]].伤害*1.1)
  			  self.参战单位[目标[n]].还阳术1=true
          end
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
         elseif 名称=="回魂咒" then
          气血=qz(self.参战单位[目标[n]].最大气血*0.1)
          气血=self:取恢复气血(编号,目标[n],气血,1)
		       --回魂拉起来满伤
    		  self:恢复伤势(目标[n],self.参战单位[目标[n]].最大气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=self.参战单位[目标[n]].最大气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
        elseif 名称=="自在心法" then
            if self.参战单位[目标[n]].法术状态.普渡众生~=nil then
              local 恢复量 = self.参战单位[目标[n]].法术状态.普渡众生.等级*2+(self.参战单位[编号].灵力*0.1)
              local 剩余回合 = self.参战单位[目标[n]].法术状态.普渡众生.回合
              if 剩余回合>4 then
                剩余回合=4
              end
              气血=self:取恢复气血(编号,目标[n],恢复量*剩余回合,名称)
              self:增加气血(目标[n],气血)
			        self:恢复伤势(目标[n],气血)
              self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
      			  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
      			  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
              self:取消状态("普渡众生",self.参战单位[目标[n]])
              状态名称={[1]="普渡众生"}
            end
        elseif 名称=="莲花心音" then
          气血=qz(self.参战单位[目标[n]].最大气血*0.6)
          气血=self:取恢复气血(编号,目标[n],气血,名称)
    		  self:恢复伤势(目标[n],气血)
    		  self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
    		  self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2

          self:增加气血(目标[n],气血)
          self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
          self.战斗流程[#self.战斗流程].挨打方[n].复活=true
          ---0914机制修复
          self.执行中复活单位[#self.执行中复活单位+1]=目标
          self.回合中复活=true
         end
      self.战斗流程[#self.战斗流程].挨打方[n].解除状态=状态名称
     end
end
function 战斗处理类:取异常状态法术()
  return {"象形","摧心","碎玉弄影","利刃","迷意","忘忧","瘴气","黄泉之息","轰鸣","破甲术","碎甲术","停陷术","凝滞术","河东狮吼","锢魂术","放下屠刀","腾雷","雾痕","冰川怒","日月乾坤","毒","尸腐毒 ","尸腐毒","雾杀","夺魄令1","威慑","夺魄令","煞气诀","锋芒毕露","诱袭","反间之计","失心","一笑倾城","百万神兵","错乱","镇妖","催眠符","失心符","落魄符","失忆符","追魂符","离魂符","失魂符","定身符","莲步轻舞","如花解语","似玉生香","含情脉脉","魔音摄魂","天罗地网"}
end


function 战斗处理类:取异常封印法术状态()
  return {"日月乾坤"}
end

function 战斗处理类:取门派封印法术(门派)
  if 门派=="方寸山" then
    return {"催眠符","失心符","落魄符","失忆符","追魂符","离魂符","失魂符","定身符"}
  elseif  门派=="女儿村" then
    return {"碎玉弄影","莲步轻舞","如花解语","似玉生香","一笑倾城"}
  elseif  门派=="盘丝洞" then
    return {"含情脉脉","魔音摄魂","天罗地网"}
  elseif  门派=="无底洞" then
    return {"夺魄令","夺魄令1","煞气诀","惊魂掌","摧心术"}
  elseif  门派=="龙宫" then
    return {"雷浪穿云"}
  elseif  门派=="天宫" then
    return {"错乱","百万神兵"}
  elseif  门派=="神木林" then
    return {"冰川怒"}
  end
end

function 战斗处理类:取法宝封印状态(编号)
  local 临时名称={"无字经","无尘扇","摄魂","无魂傀儡","断线木偶","鬼泣","惊魂铃","发瘟匣"}
  for i, v in pairs(self.参战单位[编号].法术状态) do
    for n=1,#临时名称 do
      if 临时名称[n]==i then return true end
    end
  end
  return false
end

function 战斗处理类:取法宝异常法术()
  return {"无字经","无尘扇","摄魂","无魂傀儡","断线木偶","鬼泣","惊魂铃","发瘟匣","鬼泣"}
end

function 战斗处理类:解除状态结果(单位,名称)
  local 解除={}
  for n=1,#名称 do
    if 单位.法术状态[名称[n]]~=nil then
      self:取消状态(名称[n],单位)
      解除[#解除+1]=名称[n]
    end
  end
  return 解除
end

function 战斗处理类:取符石组合效果(编号,名称)
  if type(编号)=="table" then
    if 编号.符石技能效果==nil and 编号.符石技能效果[名称]==nil then
      return false
    end
    return 编号.符石技能效果[名称]
  else
    if self.参战单位[编号].符石技能效果==nil and self.参战单位[编号].符石技能效果[名称]==nil then
      return false
    end
    return self.参战单位[编号].符石技能效果[名称]
  end
end


function 战斗处理类:法攻技能计算(编号,名称,等级,伤害系数,消耗)
  local 目标=self.参战单位[编号].指令.目标
  local 目标数=self:取目标数量(self.参战单位[编号],名称,等级,编号)
  local 目标=self:取多个敌方目标(编号,目标,目标数)
  local 名称1
  if 名称=="摇头摆尾" then
    名称1=名称
    if 取随机数(1,100)<=70 then
      名称="摇头摆尾"
    else
      名称="三昧真火"
    end
  elseif 名称=="上古灵符" then
    local 灵符随机={"上古灵符(怒雷)","上古灵符(流沙)","上古灵符(心火)"}
    名称=灵符随机[取随机数(1,#灵符随机)]
  end
  if 消耗==nil then
    if 名称=="亢龙归海" and self.参战单位[编号].亢龙回合~=nil and self.回合数-self.参战单位[编号].亢龙回合<6 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(6-(self.回合数-self.参战单位[编号].亢龙回合)).."#Y/回合后才可使用")
      return
    elseif 名称=="魔焰滔天" and self.参战单位[编号].魔焰回合~=nil and self.回合数-self.参战单位[编号].魔焰回合<5 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(5-(self.回合数-self.参战单位[编号].魔焰回合)).."#Y/回合后才可使用")
      return
    elseif 名称=="风卷残云" and self.参战单位[编号].风卷回合~=nil and self.回合数-self.参战单位[编号].风卷回合<5 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(5-(self.回合数-self.参战单位[编号].风卷回合)).."#Y/回合后才可使用")
      return
    elseif 名称=="五行制化" and self.参战单位[编号].五行回合~=nil and self.回合数-self.参战单位[编号].五行回合<8 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(8-(self.回合数-self.参战单位[编号].五行回合)).."#Y/回合后才可使用")
      return
    elseif 名称=="飞符炼魂" and self.参战单位[编号].飞符回合~=nil and self.回合数-self.参战单位[编号].飞符回合<5 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(5-(self.回合数-self.参战单位[编号].飞符回合)).."#Y/回合后才可使用")
      return
    end
  end
  if #目标==0 then return end
  for n=1,#目标 do
    if self.参战单位[目标[n]].法术状态.分身术~=nil and self.参战单位[目标[n]].法术状态.分身术.破解==nil then
      self.参战单位[目标[n]].法术状态.分身术.破解=1
      table.remove(目标,n)
  --    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/被目标分身术躲过去了！")
--      self:添加提示(self.参战单位[目标].玩家id,编号,"#Y/分身术躲避了一次攻击")
      return
    end
  end
  if #目标==0 then return end
  目标数=#目标
  if 消耗==nil and self:技能消耗(self.参战单位[编号],目标数,名称,编号)==false then  self:添加提示(self.参战单位[编号].玩家id,编号,"未到达技能消耗要求,技能使用失败") return  end
  local 返回=nil
  local 重复攻击=false
  local 起始伤害=1
  local 叠加伤害=0
  local 重复提示=false
  local 允许保护=true
  local 增加伤害=0
  local 伤害参数=0
  local 结尾气血=0
  local 防御减少=0
  if 名称=="匠心·破击"  then
    if self.参战单位[编号].零件==nil then  self.参战单位[编号].零件=0 end
    if self.参战单位[编号].守之械==nil then self.参战单位[编号].守之械=0 end
    if self.参战单位[编号].零件<3 and self.参战单位[编号].法术状态.据守==nil and self.参战单位[编号].法术状态.巨锋==nil and self.参战单位[编号].法术状态.战复==nil then
    self.参战单位[编号].零件=self.参战单位[编号].零件+1
    self.参战单位[编号].守之械=self.参战单位[编号].守之械+1
   end
   if self.参战单位[编号].守之械>1 then
    self:取消状态("守之械"..self.参战单位[编号].守之械-1,self.参战单位[编号])
   end
    self:添加状态("守之械"..self.参战单位[编号].守之械,self.参战单位[编号],self.参战单位[目标[1]],self.参战单位[编号].守之械,编号,nil)
    if self.参战单位[编号].守之械>=3 and self.参战单位[编号].零件>=3 then
      self:取消状态("守之械"..self.参战单位[编号].守之械,self.参战单位[编号])
      self.参战单位[编号].零件=0
      self.参战单位[编号].守之械=0
      self:添加状态("据守",self.参战单位[编号])
    end
    if self.参战单位[编号].守之械>=1 and self.参战单位[编号].零件>=3 and self.参战单位[编号].攻之械>=1 then
      self:取消状态("守之械"..self.参战单位[编号].守之械,self.参战单位[编号])
      self:取消状态("攻之械"..self.参战单位[编号].攻之械,self.参战单位[编号])
      self.参战单位[编号].零件=0
      self.参战单位[编号].攻之械=0
      self.参战单位[编号].守之械=0
      self:添加状态("战复",self.参战单位[编号])
    end
   end
  if 名称=="五行制化" then
    local 随机法术={"苍茫树","靛沧海","日光华","巨岩破","地裂火"}
    名称=随机法术[取随机数(1,#随机法术)]
    伤害系数=1.1
    self.参战单位[编号].五行回合=self.回合数
    if self.战斗类型==110009 and self.参战单位[编号].模型== "星灵仙子" then
    伤害系数=100.3
  end
end

  self.战斗流程[#self.战斗流程+1]={流程=200,攻击方=编号,挨打方={},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
  if 名称=="飞砂走石" then   --增加单技能属性
  self.参战单位[编号].法暴=self.参战单位[编号].法暴+5
  elseif 名称=="三昧真火" then
  self.参战单位[编号].法暴=self.参战单位[编号].法暴+10
  elseif 名称=="摇头摆尾" then
  self.参战单位[编号].法暴=self.参战单位[编号].法暴+10
  end
  if 名称=="落叶萧萧" and self.参战单位[编号].类型=="角色" then
  if self.参战单位[编号].法连==nil then
  self.参战单位[编号].法连=0
  end
  self.参战单位[编号].法连=self.参战单位[编号].法连+10
  end
  for n=1,目标数 do
    self:法攻技能计算1(编号,名称,等级,目标[n],目标数,n,伤害系数)
  end

  if 名称=="自爆" then
    self.战斗流程[#self.战斗流程].流程=500
    self.战斗流程[#self.战斗流程].伤害=self.参战单位[编号].气血
    self.参战单位[编号].气血=0
  end
  --法术多单位反弹
  local 上一次流程 = DeepCopy(self.战斗流程[#self.战斗流程])
  for n=1,目标数 do
    for i=1,#上一次流程.挨打方 do
      if 目标[n]==上一次流程.挨打方[i].挨打方 then
        if self.参战单位[编号].气血>0 and self.参战单位[目标[n]].法术状态.混元伞~=nil then
          local 反弹伤害=qz(上一次流程.挨打方[i].伤害*(self.参战单位[目标[n]].法术状态.混元伞.境界*0.03+0.1))
          self.战斗流程[#self.战斗流程+1]={流程=104,气血=反弹伤害,攻击方=目标[n],挨打方={挨打方=编号,特效={},死亡=self:减少气血(编号,反弹伤害,目标[n])},提示={允许=false}}
        end
        if self.参战单位[编号].气血>0 and self.参战单位[目标[n]].法术状态.幻镜术~=nil and 取随机数()<=40 then
          local 反弹伤害=qz(上一次流程.挨打方[i].伤害*1)
          self.战斗流程[#self.战斗流程+1]={流程=135,气血=反弹伤害,攻击方=目标[n],挨打方={挨打方=编号,特效={},死亡=self:减少气血(编号,反弹伤害,目标[n])},提示={允许=false}}
        end
        if self.参战单位[编号].气血>0 and self.参战单位[目标[n]].法术状态.天衣无缝~=nil then
          local 反弹伤害=qz(上一次流程.挨打方[i].伤害*0.5)
          self.战斗流程[#self.战斗流程+1]={流程=134,气血=反弹伤害,攻击方=目标[n],挨打方={挨打方=编号,特效={},死亡=self:减少气血(编号,反弹伤害,目标[n])},提示={允许=false}}
        end
		--火甲不反法术
        --if self.参战单位[编号].气血>0 and self.参战单位[目标[n]].法术状态.火甲术~=nil and self.参战单位[目标[n]].气血>0 then
        --  local 火甲反=math.floor(self:取灵力伤害(self.参战单位[目标[n]],self.参战单位[编号],编号)*1+qz(self:取技能等级(目标[n],"三昧真火")*1))
        --  self.战斗流程[#self.战斗流程+1]={流程=114,气血=火甲反,攻击方=目标[n],挨打方={挨打方=编号,特效={"三昧真火"},死亡=self:减少气血(编号,火甲反,目标[n])},提示={允许=false}}
        --end
      end
    end
  end
end

function 战斗处理类:取固伤结果(编号,伤害)
 -------------------------摩托修改固伤结果------------------------
  local 目标=self.参战单位[编号].指令.目标
  local 修炼差 = 1
  --local 修炼差 = 1+ ((self.参战单位[编号].法术修炼*0.02) - (self.参战单位[目标].抗法修炼*0.02))
    if self.参战单位[编号].法暴>=0 then
      self.参战单位[编号].法暴=0
    end
  if self.参战单位[编号].法术暴击等级>=0 then
    self.参战单位[编号].法术暴击等级=0
  end

  if self.参战单位[编号].固定伤害 ~=nil and self.参战单位[编号].敏捷 ~=nil and self.参战单位[编号].类型=="角色" and self.参战单位[编号].武器伤害~=nil then--+(self.参战单位[编号].武器伤害*0.46)
    伤害 =(伤害+(self.参战单位[编号].敏捷*0.3)+(self.参战单位[编号].武器伤害*0.46))*修炼差
    else
    伤害 =伤害+(self.参战单位[编号].速度*0.25*修炼差)
  end

  if self.参战单位[编号].固伤加成~=nil then
    伤害=伤害*self.参战单位[编号].固伤加成
  end
 ---新区改动

    if self.参战单位[编号].法术状态.莲心剑意~=nil then
  伤害=伤害*1.3
  end

      --   local 女儿数量 = 0
      -- for i=1,#self.参战玩家 do
      --   if 玩家数据[self.参战玩家[i].id].角色.数据.门派 == "女儿村" then
      --     女儿数量 = 女儿数量 +1
      --   end
      -- end
      -- if 女儿数量 ==2 then
      --   伤害 = math.floor(伤害*0.8)
      -- end
      -- if 女儿数量 ==3 then
      --   伤害 = math.floor(伤害*0.5)
      -- end
      -- if 女儿数量 ==4 then
      --   伤害 = math.floor(伤害*0.4)
      -- end
      -- if 女儿数量 ==5 then
      --   伤害 = math.floor(伤害*0.3)
      -- end
  return math.floor(伤害)
end

function 战斗处理类:法攻技能计算1(编号,名称,等级,目标,目标数,执行数,伤害系数)
  self.战斗流程[#self.战斗流程].挨打方[执行数]={特效={},挨打方=目标}
  if self.参战单位[编号].武器伤害 == nil then self.参战单位[编号].武器伤害 = 0 end
  local 基础伤害=qz(self:取灵力伤害(self.参战单位[编号],self.参战单位[目标],编号)+等级*1.5+self.参战单位[编号].武器伤害*0.3)
  local 法伤系数=1
  local 增加伤害=0
  local 结尾气血=0
  local 重复攻击=false
  local 附加状态=nil
  local 吸收=nil
  local 弱点=nil
  local 伤势=nil
  local 伤势类型=1
  local 法术伤害=true
  if 编号~=nil and self:取奇经八脉是否有(编号,"波澜不惊") then
    if self.参战单位[编号].法连==nil  then
        self.参战单位[编号].法连=0
    end
    self.参战单位[编号].法连=self.参战单位[编号].法连+20
  end

  self.执行等待=self.执行等待+10
    if 名称=="唧唧歪歪" then
    法伤系数=1.1-math.min(目标数*0.1,0.5)
    if self:取符石组合效果(编号,"福泽天下") then
      基础伤害=qz(基础伤害+self:取符石组合效果(编号,"福泽天下"))
    end
    elseif 名称=="笑里藏刀" then
    法伤系数=0
    elseif 名称=="风雷韵动" then
    基础伤害=基础伤害+qz(self.参战单位[编号].武器伤害*3.5)
    elseif 名称=="绝幻魔音" then
    法伤系数=0
    self.战斗流程[#self.战斗流程].流程=205
 elseif 名称=="紫气东来" then
    法伤系数=1
    if self.参战单位[目标].门派=="普陀山" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="天诛地灭" then
    法伤系数=1
    if self.参战单位[目标].门派=="阴曹地府" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="踏山裂石" then
    法伤系数=1
    if self.参战单位[目标].门派=="化生寺" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="蝼蚁蚀天" then
    法伤系数=1
    if self.参战单位[目标].门派=="凌波城" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="龙啸九天" then
    法伤系数=1
    if self.参战单位[目标].门派=="盘丝洞" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="三星灭魔" then
    法伤系数=1
    if self.参战单位[目标].门派=="魔王寨" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="夺命蛛丝" then
    法伤系数=1
    if self.参战单位[目标].门派=="方寸山" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="五行错位" then
    法伤系数=1
    if self.参战单位[目标].门派=="女儿村" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="冤魂不散" then
    法伤系数=1
    if self.参战单位[目标].门派=="大唐官府" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="太极生化" then
    法伤系数=1
    if self.参战单位[目标].门派=="狮驼岭" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
    elseif 名称=="万木凋枯" then
    法伤系数=1
    if self.参战单位[目标].门派=="神木林" then
    基础伤害=等级*5+qz(self.参战单位[目标].最大气血*2.4)
    基础伤害=self:取固伤结果(编号,基础伤害)
    法术伤害=false
    end
  elseif 名称=="妖风四起" then
      if self:取封印成功(名称,等级,self.参战单位[编号],self.参战单位[目标]) then
          附加状态="妖风四起"
          self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
         end
  elseif 名称=="摧心术" then
    if self:取封印成功(名称,等级,self.参战单位[编号],self.参战单位[目标]) then
        附加状态="摧心术"
        self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
    end
  elseif 名称=="摇头摆尾" then
    基础伤害=基础伤害+等级*1
    法伤系数=1.2-math.min(目标数*0.1,0.5)
    if 编号~=nil and 取随机数() <= 20 then
    附加状态="摇头摆尾"
    self:添加状态("摇头摆尾",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
    end
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="五雷咒" then
    基础伤害=基础伤害+等级*0.8
    法伤系数=1.3-math.min(目标数*0.1,0.5)
    if self.参战单位[目标].鬼魂~=nil then
    法伤系数=法伤系数+0.3
    end
  elseif 名称=="落雷符" then
	  基础伤害=基础伤害+等级*0.5
    法伤系数=1.15-math.min(目标数*0.1,0.5)
    if self.参战单位[目标].鬼魂~=nil then
      法伤系数=法伤系数+0.2
    end
    if self:取符石组合效果(编号,"石破天惊") then
      基础伤害 = qz(基础伤害 + self:取符石组合效果(编号,"石破天惊"))
    end
  elseif 名称=="黄泉之息" then
    基础伤害=基础伤害+qz(self.参战单位[编号].武器伤害*0.4)+等级*1.5
    if 编号~=nil and self:取奇经八脉是否有(编号,"泉爆") and self.参战单位[编号].黄泉触发==nil then
    基础伤害=基础伤害*5
    end
    附加状态="黄泉之息"
    self:添加状态("黄泉之息",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
    self.参战单位[编号].黄泉触发=1
  elseif 名称=="飞符炼魂" then
    法伤系数=1.25
    self.参战单位[编号].飞符回合=self.回合数
    if 编号~=nil and self:取奇经八脉是否有(编号,"飞符炼魂") then
    附加状态="落魄符"
    self:添加状态("落魄符",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
    end
  elseif 名称=="雨落寒沙" then
    if self.参战单位[编号].门派 == "女儿村" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*2+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].伤害*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*2+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].伤害*0.2))
    end
    法术伤害=false
    if self:取符石组合效果(编号,"凤舞九天") then
    基础伤害 = qz(基础伤害 + self:取符石组合效果(编号,"凤舞九天"))
    end
    local 中毒概率=10
    if 编号~=nil and self:取奇经八脉是否有(编号,"杏花") then
      中毒概率 = 14
    end
    if 取随机数()<=中毒概率 then
    附加状态="毒"
    self:添加状态("毒",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
    end
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="五雷轰顶" then
    if 取随机数(1,100)<=30  then
    基础伤害=self.参战单位[目标].气血*0.25
    self.威赫=true
    else
    基础伤害=self.参战单位[目标].气血*0.05
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"威赫") and self.威赫==true then
      基础伤害=基础伤害+self.参战单位[目标].气血*0.08
      self.威赫=false
    end
    if 基础伤害>=等级*50 then
    基础伤害=等级*50
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"轰鸣") and self.威赫==true then
    附加状态="轰鸣"
    self:添加状态("轰鸣",self.参战单位[目标],self.参战单位[编号],等级,编号)
    self.威赫=false
    end
  elseif 名称=="雷霆万钧" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.15-目标数*0.1
  if self:取符石组合效果(编号,"天雷地火") then
    基础伤害=qz(基础伤害+self:取符石组合效果(编号,"天雷地火"))
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"电芒") then
    附加状态="电芒"
    self:添加状态("电芒",self.参战单位[目标],self.参战单位[编号],等级,编号)
  end
  elseif 名称=="龙腾" then
    基础伤害=基础伤害+等级
    法伤系数=1.3
  elseif 名称=="荆棘舞" then
    法伤系数=1.25
    基础伤害=基础伤害+等级*1.5
  elseif 名称=="尘土刃" then
    if self.参战单位[编号].门派 == "神木林" and  self.参战单位[编号].类型=="角色" then
      local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
      基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].法伤*0.1))
      else
        基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.2))
      end
    if 编号~=nil and self:取奇经八脉是否有(编号,"不侵") and self.参战单位[目标].法术状态.雾杀~=nil then
      基础伤害=基础伤害+self.参战单位[编号].等级*10
    end
    法术伤害=false
    伤势=基础伤害/2
    伤势类型=1
  elseif 名称=="冰川怒" then
    法伤系数=0.65
    if 编号~=nil and self:取奇经八脉是否有(编号,"冰锥") then
      基础伤害=基础伤害*2
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"冰锥") and self.参战单位[目标].神佑~=nil then
      基础伤害=基础伤害*4
    end
    if 编号~=nil and 取随机数() <= 20 then
      附加状态="冰川怒"
      self:添加状态("冰川怒",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
    else
      附加状态="冰川怒伤"
      self:添加状态("冰川怒伤",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
    end
  elseif 名称=="月光" then
    法伤系数=0.8-目标数*0.1
  elseif 名称=="龙卷雨击" then
    if __gge.isdebug == nil then
    基础伤害=基础伤害+等级*1.5
    else
      if self.参战单位[编号].类型=="角色" then
          基础伤害=999999999999
      end
    end
    法伤系数=1.1-math.min(目标数*0.1,0.5)
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="刀光剑影" then
    法伤系数=10
    self.战斗流程[#self.战斗流程].流程=205
    elseif 名称=="毁灭之光" then
    法伤系数=10
    self.战斗流程[#self.战斗流程].流程=205
    elseif 名称=="雷浪穿云" then
    法伤系数=2-math.min(目标数*0.1,0.5)
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="落叶萧萧" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.1-math.min(目标数*0.1,0.5)
    self.战斗流程[#self.战斗流程].流程=205
    if self:取奇经八脉是否有(编号,"风灵") and 取随机数(1,100)<=48 then
      local 风灵层数 = 1
      if self.参战单位[编号].法术状态.风灵~=nil and self.参战单位[编号].法术状态.风灵.风灵层数~=nil then
        风灵层数=self.参战单位[编号].法术状态.风灵.风灵层数+1
      end
      self:取消状态("风灵",self.参战单位[编号])
      self:添加状态("风灵",self.参战单位[编号],self.参战单位[编号],风灵层数,编号)
    end
    if self:取奇经八脉是否有(编号,"咒术") and 取随机数(1,100)<=25 then
      附加状态="雾杀"
      self:添加状态("雾杀",self.参战单位[目标],self.参战单位[编号],等级,编号)
      if self.参战单位[目标].法术状态.雾杀 ~= nil then
        self.参战单位[目标].法术状态.雾杀.咒术=编号
      end
    end
  elseif 名称=="凋零之歌" then
    法伤系数=1.3-math.min(目标数*0.1,0.5)
  if self.参战单位[目标].法术状态.雾杀~=nil then
  基础伤害=基础伤害+qz(20*self.参战单位[编号].等级)
  end
  if 取随机数()<=50 then
  附加状态="雾杀"
  self:添加状态("雾杀",self.参战单位[目标],self.参战单位[编号],等级,编号)
  end
  elseif 名称=="龙吟" then
  基础伤害=等级+15
  --基础伤害=self:取固伤结果(编号,基础伤害)
  self.参战单位[目标].魔法=self.参战单位[目标].魔法-qz(基础伤害*1)
  if 编号~=nil and self:取奇经八脉是否有(编号,"清吟") and 取随机数(1,100)<=10 then
  基础伤害=基础伤害+取随机数(300,500)
  end
  self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="腾雷" then
    法伤系数=1.2
    if 编号~=nil and self:取奇经八脉是否有(编号,"雷附") then
    法伤系数=法伤系数+1.2
    end
    if self:取封印成功(名称,等级,self.参战单位[编号],self.参战单位[目标],编号) then
    附加状态="腾雷"
    self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
    end
  elseif 名称=="亢龙归海" then
    法伤系数=1.5
    self.参战单位[编号].亢龙回合=self.回合数
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="二龙戏珠" then
    基础伤害=基础伤害+等级*1
    法伤系数=1.2-math.min(目标数*0.1,0.5)
  elseif 名称=="风卷残云" then
    基础伤害=基础伤害+等级*1
    法伤系数=1.35-math.min(目标数*0.1,0.5)
    self.参战单位[编号].风卷回合=self.回合数
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="自爆" then
    基础伤害=等级*5+self.参战单位[目标].气血*0.1
  elseif 名称=="冥王爆杀" then
    基础伤害=等级*5+self.参战单位[目标].气血*0.1
    if 基础伤害>=等级*50 then
    基础伤害=等级*50
    end
  elseif 名称=="靛沧海" then
  法术伤害=false
  if self.参战单位[编号].门派 == "普陀山" and  self.参战单位[编号].类型=="角色" then
  local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
  基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].灵力*0.2))
  else
  基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
  end
  if self:取五行克制("水",self.参战单位[目标].防御五行)  then
  基础伤害=基础伤害*1.5
  end
  if self:取符石组合效果(编号,"行云流水") then
  基础伤害=qz(基础伤害+self:取符石组合效果(编号,"行云流水"))
  end

    if 编号~=nil and self:取奇经八脉是否有(编号,"秘术") then
        基础伤害=基础伤害+300
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"法咒") and 取随机数()<=20 then
        基础伤害=qz(基础伤害*1.5)
    end
    self.战斗流程[#self.战斗流程].流程=200
  elseif 名称=="日光华" then
    法术伤害=false
    if self.参战单位[编号].门派 == "普陀山" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].灵力*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if self:取五行克制("金",self.参战单位[目标].防御五行)  then
       基础伤害=基础伤害*1.5
    end
    if self:取符石组合效果(编号,"行云流水") then
    基础伤害=qz(基础伤害+self:取符石组合效果(编号,"行云流水"))
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"秘术") then
        基础伤害=基础伤害+150
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"法咒") and 取随机数()<=5 then
        基础伤害=qz(基础伤害*1.5)
    end
    self.战斗流程[#self.战斗流程].流程=200
  elseif 名称=="地裂火" then
    法术伤害=false
    if self.参战单位[编号].门派 == "普陀山" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].灵力*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if self:取五行克制("火",self.参战单位[目标].防御五行)  then
       基础伤害=基础伤害*1.5
    end
    if self:取符石组合效果(编号,"行云流水") then
    基础伤害=qz(基础伤害+self:取符石组合效果(编号,"行云流水"))
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"秘术") then
        基础伤害=基础伤害+150
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"法咒") and 取随机数()<=20 then
        基础伤害=qz(基础伤害*1.5)
    end
    self.战斗流程[#self.战斗流程].流程=200
  elseif 名称=="苍茫树" then
    法术伤害=false
    if self.参战单位[编号].门派 == "普陀山" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].灵力*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if self:取五行克制("火",self.参战单位[目标].防御五行)  then
       基础伤害=基础伤害*1.5
    end
    if self:取符石组合效果(编号,"行云流水") then
    基础伤害=qz(基础伤害+self:取符石组合效果(编号,"行云流水"))
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"秘术") then
        基础伤害=基础伤害+150
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"法咒") and 取随机数()<=20 then
        基础伤害=qz(基础伤害*1.5)
    end
    self.战斗流程[#self.战斗流程].流程=200
  elseif 名称=="巨岩破" then
    法术伤害=false
    if self.参战单位[编号].门派 == "普陀山" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].灵力*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if self:取五行克制("土",self.参战单位[目标].防御五行)  then
       基础伤害=基础伤害*1.5
    end
    if self:取符石组合效果(编号,"行云流水") then
    基础伤害=qz(基础伤害+self:取符石组合效果(编号,"行云流水"))
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"秘术") then
        基础伤害=基础伤害+150
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"法咒") and 取随机数()<=20 then
        基础伤害=qz(基础伤害*1.5)
    end
    self.战斗流程[#self.战斗流程].流程=200
  elseif 名称=="三昧真火" then
    基础伤害=基础伤害+等级*1
    法伤系数=1.3
    if 编号~=nil and self:取奇经八脉是否有(编号,"赤暖") then
    local 恢复气血=基础伤害*0.2
    if 恢复气血<0 then 恢复气血=0 end
    self:增加气血(编号,恢复气血)
    self.战斗流程[#self.战斗流程].气血恢复=恢复气血
    end
  elseif 名称=="飞砂走石" then
    基础伤害=基础伤害+等级*1
    法伤系数=1.1-math.min(目标数*0.1,0.5)
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="魔焰滔天" then
    基础伤害=基础伤害+等级*1
    if 取随机数(1,100)<=70 then
    法伤系数=2
    else
    法伤系数=2.6
    end
    self.参战单位[编号].魔焰回合=self.回合数
  elseif 名称=="血雨" then
    法伤系数=1.5
    if self:取奇经八脉是否有(编号,"血契") and 取随机数(1,100)<=30 then
    法伤系数=法伤系数+1.5
    end
  elseif 名称=="天罗地网" then
    法术伤害=false
    if self.参战单位[编号].门派 == "盘丝洞" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].敏捷*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if 编号~=nil and self:取符石组合效果(编号,"网罗乾坤") then
       基础伤害=qz(基础伤害+self:取符石组合效果(编号,"网罗乾坤"))
    end
    if self:取封印成功(名称,等级,self.参战单位[编号],self.参战单位[目标],编号) then
        附加状态="天罗地网"
        self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
    end
  elseif 名称=="阎罗令" then
    法术伤害=false
    if self.参战单位[编号].门派 == "阴曹地府" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*3+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].力量*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*3+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if 昼夜参数==1 then -- 1代表天黑 2代表天亮
      基础伤害=基础伤害+等级*1.5
    end
    if self:取符石组合效果(编号,"索命无常") then
      基础伤害=qz(基础伤害+self:取符石组合效果(编号,"索命无常"))
    end
		伤势=基础伤害/2
		伤势类型=1
   elseif 名称=="夺命咒" then
    法术伤害=false
    if self.参战单位[编号].门派 == "无底洞" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].灵力*0.2))
    else
    基础伤害=self:取固伤结果(编号,等级*4+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if self:取符石组合效果(编号,"销魂噬骨") then
    基础伤害=qz(基础伤害+self:取符石组合效果(编号,"销魂噬骨"))
    end

  elseif 名称=="判官令" then
    法术伤害=false
    if self.参战单位[编号].门派 == "阴曹地府" and  self.参战单位[编号].类型=="角色" then
    local 暗器伤害=math.floor(玩家数据[self.参战单位[编号].玩家id].角色:取生活技能等级("暗器技巧")*2)
    基础伤害=self:取固伤结果(编号,等级*5+qz(self.参战单位[编号].固定伤害)+暗器伤害+qz(self.参战单位[编号].力量*0.1))
    else
    基础伤害=self:取固伤结果(编号,等级*5+qz(self.参战单位[编号].固定伤害)+qz(self.参战单位[编号].灵力*0.1))
    end
    if 昼夜参数==1 then -- 1代表天黑 2代表天亮
    基础伤害=基础伤害+等级*1.5
    end
  elseif 名称=="夜舞倾城" then
    法术伤害=false
    基础伤害=self.参战单位[编号].速度*6+qz(self.参战单位[编号].固定伤害)
    基础伤害=self:取固伤结果(编号,基础伤害)
    if 基础伤害>=等级*40 then
    基础伤害=等级*40
    end
  elseif 名称=="天降灵葫" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1-目标数*0.1
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="八凶法阵" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1-目标数*0.1
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="叱咤风云" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1-目标数*0.1
    self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="流沙轻音" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=0.8-math.min(目标数*0.1,0.5)
  elseif 名称=="食指大动" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=0.9-math.min(目标数*0.1,0.5)
  elseif 名称=="泰山压顶" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=0.9-目标数*0.1
    self.战斗流程[#self.战斗流程].流程=205
    吸收="土"
    弱点="土"
  elseif 名称=="奔雷咒" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=0.9-目标数*0.1
    self.战斗流程[#self.战斗流程].流程=205
    吸收="雷"
    弱点="雷"
  elseif 名称=="水漫金山" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=0.9-目标数*0.1
    self.战斗流程[#self.战斗流程].流程=205
    吸收="水"
    弱点="水"
  elseif 名称=="扶摇万里" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=0.9-目标数*0.1
    self.战斗流程[#self.战斗流程].流程=205
    吸收="水"
    弱点="水"
  elseif 名称=="地狱烈火" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=0.9-目标数*0.1
    吸收="火"
    弱点="火"
   self.战斗流程[#self.战斗流程].流程=205
  elseif 名称=="烈火" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.3
    吸收="火"
    弱点="火"
    --0914电魂闪
    local 几率=0
      if self.参战单位[编号].内丹~=nil then
        for i=1,#self.参战单位[编号].内丹 do
          if  self.参战单位[编号].内丹[i].技能=="电魂闪" then
            几率=几率+math.ceil(self.参战单位[编号].内丹[i].等级*15*3/5)
          end
        end
     end
   if 取随机数()<=几率 then
    local 可取消状态=self:取对方可偷取增益技能1(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end
  elseif 名称=="雷击" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.3
    吸收="雷"
    弱点="雷"
    local 几率=0
      if self.参战单位[编号].内丹~=nil then
        for i=1,#self.参战单位[编号].内丹 do
          if  self.参战单位[编号].内丹[i].技能=="电魂闪" then
            几率=几率+math.ceil(self.参战单位[编号].内丹[i].等级*15*3/5)
          end
        end
     end
   if 取随机数()<=几率 then
    local 可取消状态=self:取对方可偷取增益技能1(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end
  elseif 名称=="水攻" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.3
    吸收="水"
    弱点="水"
    local 几率=0
      if self.参战单位[编号].内丹~=nil then
        for i=1,#self.参战单位[编号].内丹 do
          if  self.参战单位[编号].内丹[i].技能=="电魂闪" then
            几率=几率+math.ceil(self.参战单位[编号].内丹[i].等级*15*3/5)
          end
        end
     end
   if 取随机数()<=几率 then
    local 可取消状态=self:取对方可偷取增益技能1(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end
  elseif 名称=="落岩" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.3
    吸收="土"
    弱点="土"
    local 几率=0
      if self.参战单位[编号].内丹~=nil then
        for i=1,#self.参战单位[编号].内丹 do
          if  self.参战单位[编号].内丹[i].技能=="电魂闪" then
            几率=几率+math.ceil(self.参战单位[编号].内丹[i].等级*15*3/5)
          end
        end
     end
   if 取随机数()<=几率 then
    local 可取消状态=self:取对方可偷取增益技能1(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end
  elseif 名称=="上古灵符(怒雷)" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.5
    吸收="雷"
    弱点="雷"
    local 几率=0
      if self.参战单位[编号].内丹~=nil then
        for i=1,#self.参战单位[编号].内丹 do
          if  self.参战单位[编号].内丹[i].技能=="电魂闪" then
            几率=几率+math.ceil(self.参战单位[编号].内丹[i].等级*15*3/5)
          end
        end
     end
   if 取随机数()<=几率 then
    local 可取消状态=self:取对方可偷取增益技能1(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end
  elseif 名称=="上古灵符(流沙)" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.5
    吸收="土"
    弱点="土"
    local 几率=0
      if self.参战单位[编号].内丹~=nil then
        for i=1,#self.参战单位[编号].内丹 do
          if  self.参战单位[编号].内丹[i].技能=="电魂闪" then
            几率=几率+math.ceil(self.参战单位[编号].内丹[i].等级*15*3/5)
          end
        end
     end
   if 取随机数()<=几率 then
    local 可取消状态=self:取对方可偷取增益技能1(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end
  elseif 名称=="上古灵符(心火)" then
    基础伤害=基础伤害+等级*0.5
    法伤系数=1.5
    吸收="火"
    弱点="火"
    local 几率=0
      if self.参战单位[编号].内丹~=nil then
        for i=1,#self.参战单位[编号].内丹 do
          if  self.参战单位[编号].内丹[i].技能=="电魂闪" then
            几率=几率+math.ceil(self.参战单位[编号].内丹[i].等级*15*3/5)
          end
        end
     end
   if 取随机数()<=几率 then
    local 可取消状态=self:取对方可偷取增益技能1(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end
  end
  if 重复攻击 then
    local 临时目标=目标[1]
    for n=1,目标数 do
      目标[n]=临时目标
    end
  end

  if self:取指定法宝(编号,"金刚杵",1) and self.参战单位[编号].门派 == "普陀山" and  self.参战单位[编号].类型=="角色" then
      基础伤害=qz((1+self:取指定法宝境界(编号,"金刚杵")*0.03)*基础伤害)
  end
  if self:取指定法宝(编号,"伏魔天书",1) and self.参战单位[编号].门派 == "天宫" and  self.参战单位[编号].类型=="角色" then
     基础伤害=qz((1+self:取指定法宝境界(编号,"伏魔天书")*0.03)*基础伤害)
   end
  if self:取指定法宝(编号,"镇海珠",1) and self.参战单位[编号].门派 == "龙宫" and  self.参战单位[编号].类型=="角色" then
     基础伤害=qz((1+self:取指定法宝境界(编号,"镇海珠")*0.03)*基础伤害)
     if self:取奇经八脉是否有(编号,"云龙真身龙珠") then
        基础伤害=基础伤害*1.033
     end
   end

  if 编号~=nil and self:取奇经八脉是否有(编号,"魔冥") then
      self:增加魔法(编号,qz(self.参战单位[编号].最大魔法*0.05))
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"聚气") then
  基础伤害=基础伤害+qz(self.参战单位[目标].速度*0.8)
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"渡劫金身") then
  基础伤害=基础伤害+qz(self.参战单位[编号].法伤*0.3)
  end

  伤害=qz(基础伤害*法伤系数*伤害系数)
  -- print(基础伤害,法伤系数,伤害系数)

  if self.参战单位[编号].法术状态.谜毒之缚~=nil then
    伤害=qz(伤害*0.65*0.8)
  end
  if self.参战单位[编号].法伤 == nil then
    self.参战单位[编号].法伤=self.参战单位[编号].灵力
  end
  if 伤害<1 then
    伤害=取随机数(self.参战单位[编号].法伤*0.1,self.参战单位[编号].法伤*0.15)
  end
  local 法爆=0
  local 法爆成功=nil
  local 法爆几率=(self.参战单位[编号].法术暴击等级-self.参战单位[目标].抗法术暴击等级)*0.1
  if self.参战单位[目标].幸运~=nil then
      法爆几率=法爆几率*self.参战单位[目标].幸运
  end
  if self.参战单位[编号].法暴+法爆几率>=取随机数() then
      法爆成功=true
      伤害=伤害*2---(1.5-1.6)
   if self.参战单位[编号].灵身~=nil then
    法爆成功=true
    伤害 = 伤害+qz(伤害*(0.07*self.参战单位[编号].灵身))
    end
  end
  if self.参战单位[编号].法波~=nil then
    伤害=qz(伤害*取随机数(self.参战单位[编号].法波下,self.参战单位[编号].法波))/100
  end
 if self.参战单位[编号].高级法波~=nil then
    伤害=qz(伤害*取随机数(self.参战单位[编号].高级法波下,self.参战单位[编号].高级法波))/100
  end
  local 伤害类型=1
  if 弱点~=nil then
    if 弱点=="土" and self.参战单位[目标].弱点土~=nil then
      伤害=qz(伤害*1.5)
    elseif 弱点=="雷" and self.参战单位[目标].弱点雷~=nil then
      伤害=qz(伤害*1.5)
    elseif 弱点=="火" and self.参战单位[目标].弱点火~=nil then
      伤害=qz(伤害*1.5)
    elseif 弱点=="水" and self.参战单位[目标].弱点水~=nil then
      伤害=qz(伤害*1.5)
    end
  end
  if 吸收~=nil then
    local 触发=nil
    if 吸收=="土" and self.参战单位[目标].土吸~=nil then
      触发=self.参战单位[目标].土吸
    elseif 吸收=="水" and self.参战单位[目标].水吸~=nil then
      触发=self.参战单位[目标].水吸
    elseif 吸收=="火" and self.参战单位[目标].火吸~=nil then
      触发=self.参战单位[目标].火吸
    elseif 吸收=="雷" and self.参战单位[目标].雷吸~=nil then
      触发=self.参战单位[目标].雷吸
    end
    if 触发~=nil or self.参战单位[目标].法术状态.颠倒五行~=nil then
           local  基础几率=50
           if 编号~=nil and self:取奇经八脉是否有(编号,"法印") then
             基础几率=基础几率+15
             end
         if 取随机数(1,100)<=基础几率 then
               伤害=qz(伤害*0.5)
               if 伤害<=1 then 伤害=1 end
               伤害类型=2
            else
               伤害=qz(伤害*0.7)
               if 伤害<=1 then 伤害=1 end
           end
         end
     end
  if 名称=="天外飞剑" then
    if 取随机数()<=30 then
      伤害=1
    else
      伤害=math.floor(self.参战单位[目标].气血*0.1)
    end
  end
  if 伤害类型==1 then
    伤害=self:取伤害结果(编号,目标,伤害,法爆成功,nil,名称)
    伤害类型=伤害.类型
    伤害=伤害.伤害
  if self.参战单位[编号].法伤 == nil then
    self.参战单位[编号].法伤=self.参战单位[编号].灵力
  end
  if 伤害<1 then
    伤害=取随机数(self.参战单位[编号].法伤 *0.1,self.参战单位[编号].法伤 *0.15)
    end
  else
    伤害类型=2
  end
  if  目标~=nil and self:取奇经八脉是否有(目标,"飞龙") and 取随机数()<=30 then
    self:添加状态("神龙摆尾",self.参战单位[目标],self.参战单位[目标],等级,目标)
    附加状态="神龙摆尾"
  end
  -- 计算法术伤害结果
  if 伤害类型 == 1 and 法术伤害 then
     伤害 = 伤害+self.参战单位[编号].法术伤害结果
  end

  if self.参战单位[目标].鬼魂~=nil and self.参战单位[编号].驱鬼 then
     伤害=伤害*self.参战单位[编号].驱鬼
  end

  if 取随机数(1,100)<33 and 编号~=nil and self:取奇经八脉是否有(编号,"破浪") then
    伤害=伤害*1.06
    elseif 目标~=nil and self:取奇经八脉是否有(目标,"破浪") then
    伤害=伤害*0.91
    elseif 目标~=nil and self:取奇经八脉是否有(目标,"回旋") then
    伤害=伤害-60
  end
  if 取随机数(1,100)<33 and 编号~=nil and self:取奇经八脉是否有(编号,"云龙真身破浪") then
    伤害=伤害*1.06
    elseif 目标~=nil and self:取奇经八脉是否有(目标,"云龙真身破浪") then
    伤害=伤害*0.91
    -- elseif 目标~=nil and self:取奇经八脉是否有(目标,"回旋") then
    -- 伤害=伤害-60
  end
  if 名称=="龙卷雨击" and 编号~=nil and self:取奇经八脉是否有(编号,"云霄") then
  伤害=伤害+100
  elseif 名称=="龙腾" and 编号~=nil and self:取奇经八脉是否有(编号,"波涛") then
  伤害=伤害+等级*2
  elseif 名称=="龙腾" and 编号~=nil and self:取奇经八脉是否有(编号,"云龙真身波涛") and self:取目标类型(目标) == "玩家" then
  伤害=伤害*1.1
  elseif 名称=="龙腾" and 编号~=nil and self:取奇经八脉是否有(编号,"云龙真身清吟") and (self.参战单位[目标].魔法<self.参战单位[目标].最大魔法*0.3) then
  伤害=伤害*1.15
  elseif 名称=="三昧真火" and 编号~=nil and self:取奇经八脉是否有(编号,"炙烤") then
  伤害=伤害+等级*2
  elseif (名称=="荆棘舞" or 名称=="血雨") and 编号~=nil and self:取奇经八脉是否有(编号,"鞭挞") then
  伤害=伤害+self.参战单位[编号].等级*5
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"借灵") then
  伤害=伤害+self.参战单位[编号].伤害*0.24
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"火神") then
  伤害=伤害+self.参战单位[编号].等级*3
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"震天") then
  伤害=伤害+((self.参战单位[目标].防御*0.05)+(self.参战单位[目标].灵力*0.05))
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"神焰") and 取随机数(1,100)<=5 then
  伤害=伤害+self.参战单位[编号].等级*10
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"暗伤") then
  伤害=伤害+self.参战单位[编号].伤害*0.18
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"销武") then
  伤害=伤害+self.参战单位[编号].等级
  elseif 名称=="落雷符" and 编号~=nil and self:取奇经八脉是否有(编号,"雷动") then
  伤害=伤害+100
  elseif 名称=="判官令" and 编号~=nil and self:取奇经八脉是否有(编号,"判官") then
  伤害=伤害*1.1
  elseif 名称=="落叶萧萧" and 编号~=nil and self:取奇经八脉是否有(编号,"灵压") and
  self.参战单位[编号].法术状态.风灵~=nil and self.参战单位[编号].法术状态.风灵.风灵层数~=nil then
  伤害=伤害*1.3
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"咒法") then
  伤害=伤害+200
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"天龙") and 取随机数(1,100)<=5 then
  伤害 = 伤害+self.参战单位[编号].等级*10
  elseif 名称=="落叶萧萧" and 编号~=nil and self:取奇经八脉是否有(编号,"蔓延") then
  伤害=伤害+250
  elseif 名称=="五雷咒" and 编号~=nil and self:取奇经八脉是否有(编号,"鬼惧") then
  if self.参战单位[目标].类型=="bb" then
  伤害=伤害*1.6
  else
  伤害=伤害*1.3
  end
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"蚀天") then
  伤害 = 伤害 + (self.参战单位[编号].体质/2)
  elseif 名称=="龙腾" and 编号~=nil and self:取奇经八脉是否有(编号,"逐浪") then
  伤害=伤害+(self.参战单位[编号].灵力/5)
  elseif 编号~=nil and self:取奇经八脉是否有(编号,"踏涛") then
  伤害=伤害+150
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"云龙真身踏涛") then
  伤害=伤害+60
  end
  if 名称=="阎罗令" and 编号~=nil and self:取奇经八脉是否有(编号,"判官") then
  if self.参战单位[编号].装备属性 ~= nil then
    伤害=伤害+self.参战单位[编号].装备属性.伤害*0.15
  end
end

  if 编号~=nil and self:取奇经八脉是否有(编号,"月魂") then
    if self.参战单位[编号].装备属性 ~= nil then
  伤害=伤害+self.参战单位[编号].装备属性.伤害*0.16
  end
end

  if 编号~=nil and self:取奇经八脉是否有(编号,"不倦") then
    if self.参战单位[编号].装备属性 ~= nil then
  伤害=伤害+self.参战单位[编号].装备属性.伤害*0.5
  end
end

  if 编号~=nil and self:取奇经八脉是否有(编号,"斗法") then
       伤害=伤害+qz(self.参战单位[编号].灵力/5)
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"灵能") and 取随机数(1,100)<=5 then
  伤害=伤害+self.参战单位[编号].等级*10
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"汹涌") then
  伤害=伤害+self.参战单位[目标].防御*0.15
  end

  if 名称=="夺命咒" and 编号~=nil and self:取奇经八脉是否有(编号,"内伤") then
  if self.参战单位[编号].装备属性 ~= nil then
    伤害=伤害+self.参战单位[编号].装备属性.伤害*0.15
  end
end

  if 名称=="唧唧歪歪" and 编号~=nil and self:取奇经八脉是否有(编号,"仁心") then
  if self.参战单位[编号].装备属性 ~= nil then
    伤害=伤害+self.参战单位[编号].装备属性.伤害*0.15
  end
end

  if 名称=="天罗地网" and 编号~=nil and self:取奇经八脉是否有(编号,"鼓乐")   then
    local 人物敏捷=self.参战单位[编号].敏捷
    local 人物力量=self.参战单位[编号].力量
    if self.参战单位[编号].装备属性 ~= nil then
      人物敏捷 = 人物敏捷+self.参战单位[编号].装备属性.敏捷 or 0
      人物力量 = 人物力量+self.参战单位[编号].装备属性.力量 or 0
    if 人物敏捷 or 人物力量 >=qz(self.参战单位[编号].等级*3) then
     伤害=伤害+self.参战单位[编号].装备属性.伤害*0.18
    end
  end
end

  if 名称=="天罗地网" and 编号~=nil and self:取奇经八脉是否有(编号,"媚态")   then
        伤害=伤害+qz(self.参战单位[编号].等级*3)
end

  if 编号~=nil and (self:取奇经八脉是否有(编号,"推衍") or self:取奇经八脉是否有(编号,"雷动")) then
    local 人物敏捷=self.参战单位[编号].敏捷
    if self.参战单位[编号].装备属性 ~= nil then
      人物敏捷 = 人物敏捷+self.参战单位[编号].装备属性.敏捷 or 0
    end
    if 人物敏捷 >=qz(self.参战单位[编号].等级*2.2) then
     伤害=伤害*1.21
    end
  end

  if 名称=="夺命咒" and 编号~=nil and self:取奇经八脉是否有(编号,"追魂") then
    local 人物敏捷=self.参战单位[编号].敏捷
    if self.参战单位[编号].装备属性 ~= nil then
      人物敏捷 = 人物敏捷+self.参战单位[编号].装备属性.敏捷 or 0
    end
    if 人物敏捷 >=qz(self.参战单位[编号].等级*2.2) then
     伤害=伤害+等级
    end
  end

  if 法术伤害 and self.参战单位[目标].法术状态.罗汉金钟 ~= nil or self.参战单位[目标].法术状态.太极护法 ~= nil or self.参战单位[目标].法术状态.法术防御 ~= nil then
    伤害=伤害*0.5
  elseif self.参战单位[目标].法术状态.电芒 ~= nil then
    伤害=伤害*1.02
  end

  --计算天阵法伤加成
  if 法术伤害 and self.参战单位[编号].法伤加成~=nil then
    伤害=伤害*self.参战单位[编号].法伤加成
  end
  --print(伤害)

----法术伤害计算护盾
  self.战斗流程[#self.战斗流程].挨打方[执行数].护盾掉血值=nil
  if  伤害类型==1 or 伤害类型==3 or 伤害类型==4 then
    if self.参战单位[目标].法术状态.护盾~=nil and self.参战单位[目标].法术状态.护盾.护盾值~=nil  then
      if 伤害<self.参战单位[目标].法术状态.护盾.护盾值 then
        self.参战单位[目标].法术状态.护盾.护盾值=self.参战单位[目标].法术状态.护盾.护盾值-伤害
        self.战斗流程[#self.战斗流程].挨打方[执行数].护盾掉血值=伤害
        伤害=0
      else
        self.战斗流程[#self.战斗流程].挨打方[执行数].护盾掉血值=self.参战单位[目标].法术状态.护盾.护盾值
        伤害=伤害-self.参战单位[目标].法术状态.护盾.护盾值
        self:取消状态("护盾",self.参战单位[目标])
        --取消状态="护盾"
        self.战斗流程[#self.战斗流程].挨打方[执行数].取消状态="护盾"
      end
    elseif (self.参战单位[目标].凝光炼彩~=nil or self.参战单位[目标].食指大动~=nil) and 取随机数()<=25 then
      self:添加状态("护盾",self.参战单位[目标],self.参战单位[目标],math.floor(伤害/2),目标)
      附加状态="护盾"
      self.参战单位[目标].法术状态.护盾.回合=3
    end
  end

  self.战斗流程[#self.战斗流程].挨打方[执行数].伤害=伤害

  if 伤势 ~= nil then
    if self.参战单位[目标].类型=="角色" and self.参战单位[目标].助战编号 == nil then
  	  self.战斗流程[#self.战斗流程].挨打方[执行数].伤势=伤势
  	  -- 伤势类型 1:造成伤势 2:治疗伤势
  	  self.战斗流程[#self.战斗流程].挨打方[执行数].伤势类型=伤势类型
    else
      伤势=nil
    end
  end
  self.战斗流程[#self.战斗流程].挨打方[执行数].类型=伤害类型
  self.战斗流程[#self.战斗流程].挨打方[执行数].特效[1]=名称
  self.战斗流程[#self.战斗流程].挨打方[执行数].状态=附加状态
  self.战斗流程[#self.战斗流程].挨打方[执行数].取消状态=取消状态
  self.战斗流程[#self.战斗流程].结尾气血=结尾气血
  if 法爆成功 and 伤害类型~=2 then
    self.战斗流程[#self.战斗流程].挨打方[执行数].特效[2]="法暴"
    self.战斗流程[#self.战斗流程].挨打方[执行数].类型=3
  end
    local 境界=self:取指定法宝境界(目标,"降魔斗篷") or 0
    if 境界 then
      local 触发几率=境界*2+10 --9层:28%
      if 取随机数(1,100) <= 触发几率 then
      if self:取指定法宝(目标,"降魔斗篷",1) then
    伤害=qz(伤害*0.45)
    self.战斗流程[#self.战斗流程].挨打方[执行数].伤害=伤害
    self.战斗流程[#self.战斗流程].挨打方[执行数].特效[#self.战斗流程[#self.战斗流程].挨打方[执行数].特效+1]="降魔斗篷"
  end
      end
    end


    local 境界=self:取指定法宝境界(目标,"蟠龙玉璧") or 0
    if 境界 then
      local 触发几率=境界*1+10 --9层:28%
      if 取随机数(1,100) <= 触发几率 then
      if self:取指定法宝(目标,"蟠龙玉璧",1) then
         local 境界=self:取指定法宝境界(目标,"蟠龙玉璧")
          local 减伤效果=1.0-境界*0.025
          伤害=qz(伤害*减伤效果)
    self.战斗流程[#self.战斗流程].挨打方[执行数].伤害=伤害
    self.战斗流程[#self.战斗流程].挨打方[执行数].特效[#self.战斗流程[#self.战斗流程].挨打方[执行数].特效+1]="降魔斗篷"
  end
      end
    end
  if 伤势 ~= nil then
  	if 伤势类型==1 then
  		self:造成伤势(目标,伤势)
  	elseif 伤势类型==2 then
  		self:恢复伤势(目标,伤势)
  	end
  end
  if 伤害类型==2 then --恢复状态
    self:增加气血(目标,伤害)
  else
    self.战斗流程[#self.战斗流程].挨打方[执行数].死亡=self:减少气血(目标,伤害,编号,名称)
    if self.参战单位[目标].法术状态.催眠符 then
      self:取消状态("催眠符",self.参战单位[目标])
      self.战斗流程[#self.战斗流程].挨打方[执行数].取消状态="催眠符"
    end
  end
  -- if self.参战单位[目标].法术状态.炎护~=nil and 目标~=nil and self:取奇经八脉是否有(目标,"不侵") and 取随机数()<=50 then
  -- self:添加状态("雾杀",self.参战单位[编号],self.参战单位[编号],等级,编号)
  -- self.战斗流程[#self.战斗流程].添加状态="雾杀"
  -- end
      if  self:取指定法宝(编号,"月影",1) and 编号~=nil and self:取奇经八脉是否有(编号,"月影") then
              if self.参战单位[编号].法连==nil then
              self.参战单位[编号].法连=0
              end
              self.参战单位[编号].法连=self.参战单位[编号].法连+6

   end

  if 目标~=nil and self:取奇经八脉是否有(目标,"养生") and self.参战单位[目标].气血<=qz(self.参战单位[目标].最大气血*0.5) and self.参战单位[目标].法术状态.生命之泉==nil then
  self:添加状态("生命之泉",self.参战单位[目标],self.参战单位[目标],self.参战单位[目标].等级,目标)
  self.战斗流程[#self.战斗流程].挨打方[1].状态="生命之泉"
  end

  if 名称=="笑里藏刀" then
  if self.参战单位[目标].愤怒==nil then
  else
  self.参战单位[目标].愤怒=self.参战单位[目标].愤怒-70
  if self.参战单位[目标].愤怒<=0 then
  self.参战单位[目标].愤怒=0
  end
  end
  elseif 名称=="绝幻魔音" then
  if self.参战单位[目标].愤怒==nil then
  else
  self.参战单位[目标].愤怒=self.参战单位[目标].愤怒-20
  if self.参战单位[目标].愤怒<=0 then
  self.参战单位[目标].愤怒=0
  end
  end
  elseif 名称=="风雷韵动" then
  if self.参战单位[目标].愤怒==nil then
  else
  self.参战单位[目标].愤怒=self.参战单位[目标].愤怒-100
  if self.参战单位[目标].愤怒<=0 then
  self.参战单位[目标].愤怒=0
  end
  end
  end

  if self.参战单位[目标].法术状态.天地同寿~=nil then
  local 血量=qz(伤害*1)
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[执行数].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[执行数].特效[#self.战斗流程[#self.战斗流程].挨打方[执行数].特效+1]="天地同寿"
  end

  if self.参战单位[目标].法术状态.波澜不惊~=nil and 伤害>1 and self.参战单位[目标].气血>0 then
  local 血量=qz(伤害*1)
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[执行数].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[执行数].特效[#self.战斗流程[#self.战斗流程].挨打方[执行数].特效+1]="波澜不惊"
  end

  if self.参战单位[编号].法术状态.诡蝠之刑~=nil then
    if self:取目标状态(编号,编号,2) then
      local 气血=qz(伤害值.伤害*0.1)
      if 气血<=1 then
        气血=1
      end
      self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=编号,气血=0,挨打方={}}
      self.战斗流程[#self.战斗流程].死亡=self:减少气血(编号,气血)
      self.战斗流程[#self.战斗流程].气血=气血
    end
  end

end

function 战斗处理类:取五行克制(攻击,挨打)
 if 挨打=="木" and 攻击=="金" then
      return true
   elseif 挨打=="土" and 攻击=="木" then
      return true
    elseif 挨打=="水" and 攻击=="土" then
      return true
    elseif 挨打=="火" and 攻击=="水" then
      return true
    elseif 挨打=="金" and 攻击=="火" then
      return true
   end
  return false
end

function 战斗处理类:增益技能计算(编号,名称,等级,附加,消耗,指定,境界)
  local 目标=self.参战单位[编号].指令.目标
  local 后发目标=nil
  local 法爆=0
  local 法爆几率=(self.参战单位[编号].法术暴击等级)*0.1
  if 指定~=nil or 名称=="变身" or 名称=="狂怒" or 名称=="楚楚可怜" or 名称=="顺势而为" or 名称=="凝神术" or 名称=="幻镜术" or 名称=="灵刃" or 名称=="混元伞" or 名称=="干将莫邪" or 名称=="五彩娃娃" or 名称=="烈焰真诀" or 名称=="炎护"  or 名称=="分身术" or 名称=="不动如山"  or 名称=="魔王回首" or 名称=="极度疯狂" or 名称=="天魔解体" or 名称=="神龙摆尾" or 名称=="牛劲" or 名称=="法术防御" then
    目标=编号
  end

  if 名称=="后发制人" then
      后发目标=目标
  end
  local 目标数=self:取目标数量(self.参战单位[编号],名称,等级,编号)
  if self.回合进程=="加载回合" then
    目标数=1
  end
  -- 目标=self:取多个友方目标(编号,目标,目标数,名称)
  if 名称=="河东狮吼" or 名称=="放下屠刀" or 名称=="破甲术" or 名称=="碎甲术" or 名称=="知己知彼" or 名称=="凝滞术" or 名称=="停陷术" or 名称=="魂飞魄散" or 名称=="瘴气" or 名称=="利刃" then
    目标=self:取多个敌方目标(编号,目标,目标数)
  else
    目标=self:取多个友方目标(编号,目标,目标数,名称)
  end
  if #目标==0 then return end
  目标数=#目标
  if 名称=="同舟共济" then
    if self.参战单位[编号].同舟限制~=nil and self.回合数-self.参战单位[编号].同舟限制<8 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(8-(self.回合数-self.参战单位[编号].同舟限制)).."#Y/回合后才可使用")
      return
    end
  end

   if 名称=="诸天看护" then
   if self.参战单位[编号].诸天看护限制~=nil and self.回合数-self.参战单位[编号].诸天看护限制<10 then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(10-(self.回合数-self.参战单位[编号].诸天看护限制)).."#Y/回合后才可使用")
     return
     end
   end

		if 名称=="真君显灵" then
		if self.参战单位[编号].真君限制~=nil and self.回合数-self.参战单位[编号].真君限制<6 then
		self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(6-(self.回合数-self.参战单位[编号].真君限制)).."#Y/回合后才可使用")
		return
		end
		end

    if self.参战单位[编号].战意>=0 and 编号~=nil and self:取奇经八脉是否有(编号,"战诀") and (名称=="碎星诀" or 名称=="镇魂诀") then
    self.参战单位[编号].战意=self.参战单位[编号].战意+1
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前可使用的战意为#R/"..self.参战单位[编号].战意.."#Y/点")
    end

    if 名称=="天魔解体" then
      if self.参战单位[编号].气血<=self.参战单位[编号].最大气血*0.1 then
      return
    else
    结尾气血=qz(self.参战单位[编号].最大气血*0.1)
    self:减少气血(编号,结尾气血)
    end
  end

  if 名称=="烈焰真诀" then
  if self.参战单位[编号].烈焰真诀限制~=nil and self.回合数-self.参战单位[编号].烈焰真诀限制<8 then
  self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(8-(self.回合数-self.参战单位[编号].烈焰真诀限制)).."#Y/回合后才可使用")
  return
  end
  end
 if 昼夜参数== 1 and 名称=="修罗隐身" and self.参战单位[编号].类型~="bb" then
    常规提示(self.参战单位[编号].玩家id,"#Y/修罗隐身只能白天使用！")
    return
 end
  if 消耗==nil and self:技能消耗(self.参战单位[编号],目标数,名称,编号)==false then self:添加提示(self.参战单位[编号].玩家id,编号,"未到达技能消耗要求,技能使用失败") return  end

  self.战斗流程[#self.战斗流程+1]={流程=53,攻击方=编号,挨打方={},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
  self.执行等待=self.执行等待+10

  for n=1,目标数 do
      self.战斗流程[#self.战斗流程].挨打方[n]={挨打方=目标[n],特效={名称}}
      if 名称=="后发制人" then
          self:添加状态(名称,self.参战单位[编号],self.参战单位[编号],等级,编号)
          self.参战单位[编号].法术状态.后发制人.目标=后发目标
          self.战斗流程[#self.战斗流程].挨打方[n].挨打方=编号
      elseif 名称=="炎护" then
      self:添加状态(名称,self.参战单位[编号],self.参战单位[编号],等级,编号)
      self.战斗流程[#self.战斗流程].挨打方[n].挨打方=编号
      elseif 名称=="杀气诀" then
      if 编号~=nil and self:取奇经八脉是否有(编号,"风刃") then
      local 状态 = "风魂"
      if self.参战单位[编号].门派=="大唐官府" then
      self:添加状态(状态,self.参战单位[目标[n]],self.参战单位[编号],等级+10,编号)
      self:添加状态("杀气诀",self.参战单位[目标[n]],self.参战单位[编号],等级+10,编号)
      end
      end
      self:添加状态("杀气诀",self.参战单位[目标[n]],self.参战单位[编号],等级+10,编号)
      elseif 名称=="天魔解体" then
      self:添加状态(名称,self.参战单位[编号],self.参战单位[编号],等级,编号)
      self.战斗流程[#self.战斗流程].结尾气血=结尾气血
      elseif 名称=="其疾如风" then
      self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号,境界)
      self.战斗流程[#self.战斗流程].流程=153
      elseif 名称=="不动如山 " then
      self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号,境界)
      self.战斗流程[#self.战斗流程].流程=153
      elseif 名称=="侵掠如火" then
      self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号,境界)
      self.战斗流程[#self.战斗流程].流程=153
      elseif 名称=="知己知彼" then
        if 编号~=nil and self:取奇经八脉是否有(编号,"洞察") then
        local 状态 = self:取对方可偷取增益技能(目标[n])
        if 状态~=nil then
          self:添加状态(状态,self.参战单位[编号],self.参战单位[编号],等级,编号)
          self.战斗流程[#self.战斗流程].挨打方[n].特效={状态}
          self.战斗流程[#self.战斗流程].挨打方[n].挨打方=编号
          --取消对面状态
          self.战斗流程[#self.战斗流程].挨打方[n].取消状态={挨打方=目标[n],状态名称=状态}
          self:取消状态(状态,self.参战单位[目标[n]])
          end
        local 获取名称 = self.参战单位[目标[n]].名称
        local 获取气血值 = self.参战单位[目标[n]].气血 or 0
        local 获取最大气血值 = self.参战单位[目标[n]].最大气血 or 0
        local 获取魔法值 = self.参战单位[目标[n]].魔法 or 0
        local 获取最大魔法值 = self.参战单位[目标[n]].最大魔法 or 0
        local 获取目标愤怒 = self.参战单位[目标[n]].愤怒 or 0
        self:添加提示2(self.参战单位[编号].玩家id,编号,{内容=format("#Y/使用技能#R/[知己知彼]#Y/获取到对方信息如下\n #Y/名称:[%s] \n #Y/气血值:[%s/%s] \n #Y/魔法值:[%s/%s] \n #Y/愤怒:[%s]",获取名称,获取气血值,获取最大气血值,获取魔法值,获取最大魔法值,获取目标愤怒)})
        else
        local 获取名称 = self.参战单位[目标[n]].名称
        local 获取气血值 = self.参战单位[目标[n]].气血 or 0
        local 获取最大气血值 = self.参战单位[目标[n]].最大气血 or 0
        local 获取魔法值 = self.参战单位[目标[n]].魔法 or 0
        local 获取最大魔法值 = self.参战单位[目标[n]].最大魔法 or 0
        local 获取目标愤怒 = self.参战单位[目标[n]].愤怒 or 0
        self:添加提示2(self.参战单位[编号].玩家id,编号,{内容=format("#Y/使用技能#R/[知己知彼]#Y/获取到对方信息如下\n #Y/名称:[%s] \n #Y/气血值:[%s/%s] \n #Y/魔法值:[%s/%s] \n #Y/愤怒:[%s]",获取名称,获取气血值,获取最大气血值,获取魔法值,获取最大魔法值,获取目标愤怒)})
        end
        elseif 名称=="魂飞魄散" then
        local 状态 = self:取对方可偷取增益技能(目标[n])
        if 编号~=nil and self:取奇经八脉是否有(编号,"魂飞") and self.参战单位[目标[n]].气血<=qz(self.参战单位[目标[n]].最大气血*0.5) then
           self.战斗流程[#self.战斗流程].挨打方[n].特效={"锢魂术"}
           self:添加状态("锢魂术",self.参战单位[目标[n]],self.参战单位[目标[n]],等级,目标[n])
        end
        if 状态~=nil then
          --取消对面状态
          self.战斗流程[#self.战斗流程].挨打方[n].取消状态={挨打方=目标[n],状态名称=状态}
          self:取消状态(状态,self.参战单位[目标[n]])
        end
      elseif 名称=="同舟共济" then
        self.参战单位[编号].同舟限制=self.回合数
        self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号,境界)
      elseif 名称=="诸天看护" then
        self.参战单位[编号].诸天看护限制=self.回合数
        self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号,境界)
      elseif 名称=="烈焰真诀" then
        self.参战单位[编号].烈焰真诀限制=self.回合数
        self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号,境界)
      else
          self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号,境界)

      end

      if 名称=="生命之泉" then
        local 气血=0
        气血=等级*0.5+(self.参战单位[编号].灵力*0.1)
        if 编号~=nil and self:取奇经八脉是否有(编号,"体恤") and self.参战单位[目标[n]].气血<=qz(self.参战单位[目标[n]].最大气血*0.3) then
        气血=气血+150
        end
        气血=self:取恢复气血(编号,目标[n],气血)
        self:增加气血(目标[n],气血)
        self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
        elseif 名称=="盾气" then
          self:添加状态(名称,self.参战单位[编号],self.参战单位[目标],等级,编号,境界)
        elseif 名称=="煞气诀1" then
        local 气血=0
        气血=等级+15
        气血=self:取恢复气血(编号,目标[n],气血)
        self:增加气血(目标[n],气血)
        self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血

        elseif 名称=="煞气诀1" then
        local 气血=0
        气血=等级+15
        气血=self:取恢复气血(编号,目标[n],气血)
        self:增加气血(目标[n],气血)
        self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血

        elseif 名称=="汲魂" then
        local 气血=0
        气血=等级+15
        气血=self:取恢复气血(编号,目标[n],气血)
        self:增加气血(目标[n],气血)
        self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
      elseif 名称=="普渡众生" then
        local 气血=0
        气血=等级*4+self.参战单位[编号].灵力*0.1
        if 编号~=nil and self:取奇经八脉是否有(编号,"普渡") then
          气血=气血*1.2
        end
        if self.参战单位[编号].法暴+法爆几率>=取随机数() then
          气血=气血*1.5
          self.战斗流程[#self.战斗流程].挨打方[n].特效[2]="法暴"
          self.战斗流程[#self.战斗流程].挨打方[n].伤害类型=5
        end
        气血=self:取恢复气血(编号,目标[n],气血,名称)
        self:增加气血(目标[n],气血)
		self:恢复伤势(目标[n],气血)
        self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
		self.战斗流程[#self.战斗流程].挨打方[n].恢复伤势=气血
		self.战斗流程[#self.战斗流程].挨打方[n].伤势类型=2
      elseif 名称=="炼气化神" then
          气血=qz(等级/2)
          self.参战单位[编号].气血=self.参战单位[编号].气血-气血
          self.战斗流程[#self.战斗流程].扣除气血=气血
          self:增加魔法(目标[n],qz(等级/2))
      elseif 名称=="达摩护体" then
        气血=self.参战单位[目标[n]].等级*2.5+self.参战单位[目标[n]].灵力*0.2
		self:恢复伤势(目标[n],气血)
        self:增加气血(目标[n],气血)
        self.战斗流程[#self.战斗流程].挨打方[n].恢复气血=气血
      elseif 名称=="魔息术" then
      	if 编号~=nil and self:取奇经八脉是否有(编号,"魔息") then
      		self:增加魔法(目标[n],qz(等级/2)*1.5)
      		else
          self:增加魔法(目标[n],qz(等级/2))
        end
      elseif 名称=="灵动九天" then
          self.参战单位[目标[n]].灵力=self.参战单位[目标[n]].灵力+self.参战单位[编号].等级
          if 编号~=nil and self:取奇经八脉是否有(编号,"灵动") and self.参战单位[目标[n]].灵动~=nil then
              if self.参战单位[目标[n]].灵动==nil then
                  self.参战单位[目标[n]].灵力=self.参战单位[目标[n]].灵力+30
                  self.参战单位[目标[n]].法防=self.参战单位[目标[n]].法防+30
                  self.参战单位[目标[n]].灵动=true
              end
          end
      elseif 名称=="神龙摆尾" then
        if self.参战单位[目标[n]].傲翔1==nil then
          self.参战单位[目标[n]].法防=self.参战单位[目标[n]].法防*1.3
          self.参战单位[目标[n]].防御=self.参战单位[目标[n]].防御*1.3
          self.参战单位[目标[n]].傲翔1=true
        end
          if 编号~=nil and self:取奇经八脉是否有(编号,"傲翔") then
              if self.参战单位[目标[n]].傲翔==nil then
              self.参战单位[目标[n]].法防=self.参战单位[目标[n]].法防*1.5
              self.参战单位[目标[n]].防御=self.参战单位[目标[n]].防御*1.5
              self.参战单位[目标[n]].傲翔=true
            end
          end
      elseif 名称=="幽冥鬼眼" then
          if self.参战单位[编号].抵抗封印等级==nil then
             self.参战单位[编号].抵抗封印等级 = 0
             end
        self.参战单位[编号].抵抗封印等级 = self.参战单位[编号].抵抗封印等级 + 100
      elseif 名称=="真君显灵" then
        self.参战单位[编号].真君限制=self.回合数
      elseif 名称=="牛劲" then
          if 编号~=nil and self:取奇经八脉是否有(编号,"充沛") then
            if self.参战单位[目标[n]].感知==nil then
                self.参战单位[目标[n]].感知=0.3
            else
                self.参战单位[目标[n]].感知=self.参战单位[目标[n]].感知*1.3
            end
          end
        if 编号~=nil and self:取奇经八脉是否有(编号,"威吓") then
            if self.参战单位[目标[n]].威吓==nil then
            self.参战单位[目标[n]].灵力=self.参战单位[目标[n]].灵力+qz(self.参战单位[编号].灵力*0.5)
            self.参战单位[目标[n]].威吓=true
           end
          end
        if 编号~=nil and self:取奇经八脉是否有(编号,"连营") then
            self.参战单位[目标[n]].法术状态.牛劲.回合=self.参战单位[目标[n]].法术状态.牛劲.回合+99
          end
      end
    end
end

function 战斗处理类:减益技能计算(编号,名称,等级,类型,消耗,境界)
 local 目标=self.参战单位[编号].指令.目标
  if 目标==0  then
     目标=self:取单个敌方目标(编号)
  elseif self:取目标状态(编号,目标,1)==false then
     目标=self:取单个敌方目标(编号)
  elseif self.参战单位[编号].指令.取消 then
     return
  end
 if 目标==0 then
     return
   end
 if 名称=="尸腐毒" or 名称=="紧箍咒" then
      if self.参战单位[目标].法术状态[名称]~=nil then
          return
       elseif self.参战单位[目标].鬼魂~=nil or self.参战单位[目标].精神~=nil or self.参战单位[目标].信仰~=nil then
        self:添加提示(self.参战单位[编号].玩家id,编号,"对方可能有鬼魂.精神.信仰,免疫负面状态,技能使用失败")
         return
         end
   end
  if self.参战单位[目标].法术状态.分身术~=nil and self.参战单位[目标].法术状态.分身术.破解==nil then
      self.参战单位[目标].法术状态.分身术.破解=1
      --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/被目标分身术躲过去了！")
      --self:添加提示(self.参战单位[目标].玩家id,编号,"#Y/分身术躲避了一次攻击")
      return
   end
 if 消耗==nil and self:技能消耗(self.参战单位[编号],1,名称,编号)==false then self:添加提示(self.参战单位[编号].玩家id,编号,"未到达技能消耗要求,技能使用失败") return  end
  self.执行等待=self.执行等待+10
   self.战斗流程[#self.战斗流程+1]={流程=56,攻击方=编号,挨打方={},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
     self.战斗流程[#self.战斗流程].挨打方[1]={挨打方=目标,特效={名称}}
      if 名称=="尸腐毒" then
        local 气血=等级*4+self.参战单位[编号].伤害*0.1
		self:造成伤势(目标,气血)
        self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,气血,编号)
        self.战斗流程[#self.战斗流程].挨打方[1].气血=气血
		self.战斗流程[#self.战斗流程].挨打方[1].伤势=气血
        self.战斗流程[#self.战斗流程].挨打方[1].状态=名称
        self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
        if self:取指定法宝(编号,"九幽",1) then
          if self:取指定法宝境界(编号,"九幽")>=0 then
            local 目标=self:取多个友方目标(编号,编号,10,"尸腐毒")
            if #目标 == 0 then
              return
            end
            local 目标数 = #目标
            self.战斗流程[#self.战斗流程].受益方 = {}
            for i=1,目标数 do
              local 气血 = 0
              local 法宝层数 = self:取指定法宝境界(编号,"九幽")
              if 编号~=nil and self:取奇经八脉是否有(编号,"幽光") then
              self.战斗流程[#self.战斗流程].受益方[i]={受益方=目标[i],伤害=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].挨打方[1].气血*0.006*法宝层数+300)}
              气血=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].挨打方[1].气血*0.006*法宝层数+300)
              else
              self.战斗流程[#self.战斗流程].受益方[i]={受益方=目标[i],伤害=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].挨打方[1].气血*0.006*法宝层数)}
              气血=qz(self.参战单位[目标[i]].气血*0.006+self.战斗流程[#self.战斗流程].挨打方[1].气血*0.006*法宝层数)
              end
              气血=self:取恢复气血(编号,目标[i],气血)
              self:增加气血(目标[i],气血)
            end
          end
        end

  elseif 名称=="断线木偶" or 名称=="无魂傀儡" then
  --  if 取随机数(1,100) <= 50 then
    self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号,境界)

    self.战斗流程[#self.战斗流程].挨打方[1].状态=名称
--end

  elseif 名称=="惊魂铃" or 名称=="鬼泣" then
    if self.参战单位[目标].类型 =="角色" then
 self:添加提示(self.参战单位[编号].玩家id,编号,"你是没脑子吗?")
 return
end

    self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号,境界)

  elseif 名称=="缚妖索" or 名称=="捆仙绳" then
    if self.参战单位[目标].类型 =="角色" then
    if 取随机数() <= 60   then
    self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号,境界)

    self.战斗流程[#self.战斗流程].挨打方[1].状态=名称

    end
end

  elseif 名称=="摄魂" then

  --     local 道具id=玩家数据[self.参战单位[编号].玩家id].角色.数据.法宝[编号]
  -- local 境界=玩家数据[self.参战单位[编号].玩家id].道具.数据[道具id].气血
    --if self.参战单位[目标].类型 =="角色" then
      -- self.参战单位[编号].法术状态.捆仙绳.回合=0
       -- self:添加提示(self.参战单位[编号].玩家id,编号,"你是没脑子吗?"..境界)
  --  if 取随机数() <= 30  then
    self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号,境界)

    self.战斗流程[#self.战斗流程].挨打方[1].状态=名称

   -- end
--end

      elseif 名称=="紧箍咒" then
         local 气血=等级+20+(self.参战单位[编号].灵力*0.1)
         if 编号~=nil and self:取奇经八脉是否有(编号,"默诵") then
             气血=气血*2
         end
		     self:造成伤势(目标,气血)
         self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,气血,编号)
         self.战斗流程[#self.战斗流程].挨打方[1].气血=气血
		     self.战斗流程[#self.战斗流程].挨打方[1].伤势=气血
         self.战斗流程[#self.战斗流程].挨打方[1].状态=名称
         self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
      elseif 名称=="尸腐毒 " then
         local 气血=qz(等级*10000)
		     self:造成伤势(目标,气血)
         self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,气血,编号)
         self.战斗流程[#self.战斗流程].挨打方[1].气血=气血
		     self.战斗流程[#self.战斗流程].挨打方[1].伤势=气血
         self.战斗流程[#self.战斗流程].挨打方[1].状态=名称
      elseif 名称=="雾杀" then
         local 气血=等级*2+(self.参战单位[编号].灵力*0.2)
         self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,气血,编号)
         self.战斗流程[#self.战斗流程].挨打方[1].气血=气血
         self.战斗流程[#self.战斗流程].挨打方[1].状态=名称
         self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
      elseif 名称=="勾魂"  then
         local 气血=等级*4+(self.参战单位[编号].速度*0.1)
         self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,气血,编号)
         self.战斗流程[#self.战斗流程].挨打方[1].气血=气血
         self.战斗流程[#self.战斗流程].挨打方[1].击退=true
         local 恢复气血=qz(气血)
         self:增加气血(编号,恢复气血)
         self.战斗流程[#self.战斗流程].增加气血=恢复气血
      elseif 名称=="偷龙转凤" then
         local 气血减=qz(self.参战单位[目标].气血*0.2)
         local 气血偷=qz(self.参战单位[目标].最大气血*2)
         local 魔法减=qz(self.参战单位[目标].魔法*0.2)
         local 魔法偷=qz(self.参战单位[目标].最大魔法*2)
         self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,气血减,编号)
         self.战斗流程[#self.战斗流程].挨打方[1].气血=气血减
         local 恢复气血=qz(气血偷)
         self:增加气血(编号,恢复气血)
         self.战斗流程[#self.战斗流程].增加气血=恢复气血
         self.参战单位[目标].魔法=self.参战单位[目标].魔法-魔法减
         if self.参战单位[目标].魔法<=0 then self.参战单位[目标].魔法=0 end
         local 恢复气血=qz(魔法偷)
         self:增加魔法(编号,恢复气血)
      elseif 名称=="姐妹同心" and self.参战单位[目标].魔法>=1 then
        local 气血=等级*3+(self.参战单位[编号].敏捷*0.1)
         self.参战单位[目标].魔法=self.参战单位[目标].魔法-气血
         self.战斗流程[#self.战斗流程].挨打方[1].击退=true
         if self.参战单位[目标].魔法<=0 then self.参战单位[目标].魔法=0 end
      elseif 名称=="姐妹同心" and self.参战单位[目标].魔法<=0 then
      if 编号~=nil and self:取奇经八脉是否有(编号,"倾情") then
        self.战斗流程[#self.战斗流程].挨打方[1].状态="含情脉脉"
        self:添加状态("含情脉脉",self.参战单位[目标],self.参战单位[编号],等级,编号)
        end
      elseif 名称=="谜毒之缚" then
        self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
      elseif 名称=="诡蝠之刑" then
        self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
      elseif 名称=="摄魄" and self.参战单位[目标].魔法>=1 then
          if 编号~=nil and self:取奇经八脉是否有(编号,"倾情") and self.参战单位[目标].魔法<=0 then
          self.战斗流程[#self.战斗流程].挨打方[1].状态="含情脉脉"
          self:添加状态("含情脉脉",self.参战单位[目标],self.参战单位[编号],等级,编号)
          end
          local 气血=等级*2+(self.参战单位[编号].速度*0.1)
          self.参战单位[目标].魔法=self.参战单位[目标].魔法-气血
          if self.参战单位[目标].魔法<=0 then self.参战单位[目标].魔法=0 end
          self.战斗流程[#self.战斗流程].挨打方[1].击退=true
          local 恢复气血=qz(气血)
          self:增加魔法(编号,恢复气血)
      end
end

function 战斗处理类:取恢复气血(编号,目标,气血,名称)
  local 法修=1
  法修=1+self.参战单位[编号].法术修炼*0.02
  if self.参战单位[编号].治疗能力==nil then
    self.参战单位[编号].治疗能力=0
  end
  if self.参战单位[目标].气血回复效果==nil then
    self.参战单位[目标].气血回复效果=0
  end

  local 效果=qz((self.参战单位[编号].治疗能力+self.参战单位[目标].气血回复效果+气血)*法修)
  if self:取指定法宝(编号,"慈悲",1) then
   效果=qz(self:取指定法宝境界(编号,"慈悲",1,1)*15+效果)
    if self:取指定法宝境界(编号,"慈悲")>=取随机数(1,60) then
      效果=效果*2
    end
  end

  if 编号~=nil and self:取符石组合效果(编号,"万丈霞光") then
  效果=qz(效果+self:取符石组合效果(编号,"万丈霞光"))
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"化戈") then
      效果=效果+self.参战单位[编号].伤害*0.18
      elseif 编号~=nil and self:取奇经八脉是否有(编号,"止戈") then
      效果=效果+self.参战单位[编号].伤害*0.18
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"劳心") and self.参战单位[编号].气血<=qz(self.参战单位[编号].最大气血*0.3) then
      效果=效果*2
  end
  if self.参战单位[编号].法术状态.莲心剑意~=nil then
   效果=qz(效果*0.5)
   end

  if self.参战单位[目标].永恒~=nil then
   效果=qz(效果*self.参战单位[目标].永恒)
   end
   if self.参战单位[目标].法术状态.重创~=nil then
   效果=效果*0.5
   end

  if self.参战单位[编号].队伍==0 then
    if self.参战单位[编号].名称=="酒肉和尚帮凶" and (self.战斗类型==100223 or self.战斗类型==110010) then
      效果=效果*3
      elseif self.参战单位[编号].名称=="守门天将" and (self.战斗类型==100224 or self.战斗类型==110008) then
      效果=效果*10
      elseif self.参战单位[编号].名称=="飞升守护者" and (self.战斗类型==100050 or self.战斗类型==100051 or self.战斗类型==100052 or self.战斗类型==100053 or self.战斗类型==100054) then
      效果=效果*10
      elseif self.战斗类型==100055 and (self.参战单位[编号].名称=="护驾亲兵 " or self.参战单位[编号].名称=="云霄仙子 " or self.参战单位[编号].名称=="勾魂使者 " or self.参战单位[编号].名称=="泼法金刚 " or self.参战单位[编号].名称=="护法枷蓝 ") then
      效果=效果*10
      elseif self.战斗类型==100056 and self.参战单位[编号].类型~="角色" then
      效果=效果*10
      elseif self.战斗类型==110007 and self.参战单位[编号].名称=="赌徒喽罗" then
      效果=效果*5
      elseif self.战斗类型==100237 and self.参战单位[编号].名称=="派大星" then
      效果=效果*5
      elseif self.战斗类型==100257 and self.参战单位[编号].名称=="花妖喽罗" then
      效果=效果*10
      elseif self.战斗类型==100258 and self.参战单位[编号].名称=="天兵喽罗" then
      效果=效果*10
      elseif self.战斗类型==100259 and self.参战单位[编号].名称=="虾兵喽啰" then
      效果=效果*10
      elseif self.战斗类型==100261 and (self.参战单位[编号].名称=="空度禅师" or self.参战单位[编号].名称=="地涌夫人") then
      效果=效果*15
      elseif self.战斗类型==100262 and self.参战单位[编号].名称=="空慈方丈" then
      效果=效果*15
    end
  end

  if self.参战单位[目标].法术状态.谜毒之缚~=nil then
    效果=math.floor(效果*0.8)
  end

  if 取随机数(1,100)<=15 and (名称=="我佛慈悲" or 名称=="推气过宫" or 名称=="推拿" or 名称=="妙悟" or 名称=="舍身取义" or 名称=="活血") then
  效果=qz(效果*2)
  end

   if self.参战单位[目标].法术状态.腾雷~=nil then
   效果=qz(效果*0.5)
   end
   if self.参战单位[目标].法术状态.瘴气~=nil then
    效果=qz(效果*0.5)
    end
   if self.参战单位[目标].法术状态.迷意~=nil then
    效果=qz(效果*0.7)
    end
    if self.参战单位[目标].法术状态.魔音摄魂~=nil then
   效果=qz(效果*0)
   end
  return 效果
end

function 战斗处理类:单体封印技能计算(编号,名称,等级)
 local 目标=self.参战单位[编号].指令.目标
  if self:取目标状态(编号,目标,1)==false then
    目标=self:取单个敌方目标(编号)
  end
  if 目标==0 then
    return
  end
  if 法宝~=nil and self:取法宝封印状态(目标) then
    return
  elseif self:取封印状态(目标) then
    return
  end
  if self.参战单位[目标].法术状态.分身术~=nil and self.参战单位[目标].法术状态.分身术.破解==nil then
    self.参战单位[目标].法术状态.分身术.破解=1
    --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/被目标分身术躲过去了！")
      --self:添加提示(self.参战单位[目标].玩家id,编号,"#Y/分身术躲避了一次攻击")
    return
  end
  if 消耗==nil and self:技能消耗(self.参战单位[编号],1,名称,编号)==false then self:添加提示(self.参战单位[编号].玩家id,编号,"未到达技能消耗要求,技能使用失败") return  end
  self.战斗流程[#self.战斗流程+1]={流程=50,攻击方=编号,挨打方={[1]={挨打方=目标,特效={名称},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}}}
  self.执行等待=self.执行等待+10
  if self:取封印成功(名称,等级,self.参战单位[编号],self.参战单位[目标],编号) then
    self:添加状态(名称,self.参战单位[目标],self.参战单位[编号],等级,编号)
    self.战斗流程[#self.战斗流程].挨打方[1].添加状态=名称
    if 编号~=nil and self:取奇经八脉是否有(编号,"不灭") and (名称=="离魂符" or 名称=="失魂符" or 名称=="定身符" or 名称=="碎甲符" or 名称=="催眠符" or 名称=="失心符" or 名称=="落魄符" or 名称=="失忆符" or 名称=="追魂符") then
            self:添加状态("不灭",self.参战单位[编号],self.参战单位[编号],self.参战单位[编号].等级,编号)
            self:添加状态("不灭1",self.参战单位[编号],self.参战单位[编号],self.参战单位[编号].等级,编号)
            self.战斗流程[#self.战斗流程].添加状态="不灭"
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"毒雾") and (名称=="似玉生香"  or 名称=="莲步轻舞" or 名称=="如花解语" or 名称=="娉婷袅娜") then
        附加状态="毒"
        self:添加状态("毒",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
        self.参战单位[目标].法术状态.毒.回合=8
    end
    if 名称=="含情脉脉" and 编号~=nil and self:取奇经八脉是否有(编号,"迷瘴") then
            self:添加状态("迷瘴",self.参战单位[编号],self.参战单位[编号],self.参战单位[编号].等级,编号)
            self.战斗流程[#self.战斗流程].添加状态="迷瘴"
            end
    if 编号~=nil and self:取奇经八脉是否有(编号,"忘忧") and (名称=="含情脉脉" or 名称=="魔音摄魂")  then
            self:添加状态("忘忧",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
            self.战斗流程[#self.战斗流程].挨打方[1].添加状态="忘忧"
            end
    if 名称=="含情脉脉" and 编号~=nil and self:取奇经八脉是否有(编号,"绝殇") then
            self:添加状态("绝殇",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
            end
    if 名称=="夺魄令" and 编号~=nil and self:取奇经八脉是否有(编号,"追魂") then
        self:添加状态("夺魄令1",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
        self.战斗流程[#self.战斗流程].挨打方[1].添加状态="夺魄令1"
        end

        if 名称=="煞气诀" and 编号~=nil and self:取奇经八脉是否有(编号,"救人") then
        self:添加状态("煞气诀1",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
        self.战斗流程[#self.战斗流程].挨打方[1].添加状态="煞气诀1"
    end

    if 名称=="锋芒毕露" then
      self:添加状态("锋芒毕露",self.参战单位[目标],self.参战单位[编号],self:取技能等级(编号,"锋芒毕露"),编号)
    end
    if 名称=="诱袭" then
      self:添加状态("诱袭",self.参战单位[目标],self.参战单位[编号],self:取技能等级(编号,"诱袭"),编号)
    end
      ----0914 自矜
  end
end

function 战斗处理类:群体封印技能计算(编号,名称,等级,法宝)
  local 目标=self.参战单位[编号].指令.目标
  if 额外目标~=nil then 目标=额外目标 end
    local 目标数=self:取目标数量(self.参战单位[编号],名称,等级,编号)
    local 目标=self:取多个敌方目标(编号,目标,目标数)
  if #目标==0 then return end
    local 目标重置={}
    for n=1,#目标 do
      if self.参战单位[目标[n]].法术状态.分身术~=nil and self.参战单位[目标[n]].法术状态.分身术.破解==nil then
        self.参战单位[目标[n]].法术状态.分身术.破解=1
        --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/被目标分身术躲过去了！")
      --self:添加提示(self.参战单位[目标].玩家id,编号,"#Y/分身术躲避了一次攻击")
      else
        目标重置[#目标重置+1]=目标[n]
      end
    end
    目标=目标重置
  if #目标==0 then return end
  目标数=#目标
  if 消耗==nil and self:技能消耗(self.参战单位[编号],目标数,名称,编号)==false then  self:添加提示(self.参战单位[编号].玩家id,编号,"未到达技能消耗要求,技能使用失败") return  end
    self.战斗流程[#self.战斗流程+1]={流程=209,攻击方=编号,挨打方={},提示={允许=true,类型="法术",名称=self.参战单位[编号].名称.."使用了"..名称}}
    self.执行等待=self.执行等待+10
  for n=1,目标数 do
    self.战斗流程[#self.战斗流程].挨打方[n]={挨打方=目标[n],特效={名称}}
    if 名称=="河东狮吼" or 名称=="停陷术" or 名称=="碎甲术" then  --师门技能?  --  这个为什么这么写 上次你写的
        self.战斗流程[#self.战斗流程].流程=213
    end
    if 名称=="凝滞术" or 名称=="破甲术" or 名称=="放下屠刀" then  --师门技能?  --你看看行不行
        self.战斗流程[#self.战斗流程].流程=215
    end
    if 名称=="飞花摘叶" then
    local 魔法=等级*2
    if  self.参战单位[目标[n]].魔法<等级*2 then 魔法=self.参战单位[目标[n]].魔法 end
    self.参战单位[目标[n]].魔法=self.参战单位[目标[n]].魔法-等级*2
    if self.参战单位[目标[n]].魔法<0 then self.参战单位[目标[n]].魔法=0 end
    local 恢复目标=self:取多个友方目标(编号,编号,3,名称)
    for w=1,#恢复目标 do
    self.参战单位[恢复目标[w]].魔法=self.参战单位[恢复目标[w]].魔法+qz(魔法/#恢复目标)
    if self.参战单位[恢复目标[w]].魔法>self.参战单位[恢复目标[w]].最大魔法 then self.参战单位[恢复目标[w]].魔法=self.参战单位[恢复目标[w]].最大魔法 end
    end
    end
    if 法宝~=nil and self:取法宝封印状态(目标[n]) then
      return
    elseif self:取封印状态(目标[n]) then
      return
    end
    local 成功=false
    if self:取封印成功(名称,等级,self.参战单位[编号],self.参战单位[目标[n]]) then
      成功=true
      self:添加状态(名称,self.参战单位[目标[n]],self.参战单位[编号],等级,编号)
      self.战斗流程[#self.战斗流程].挨打方[n].添加状态=名称
    if 编号~=nil and self:取奇经八脉是否有(编号,"毒雾") and (名称=="碎玉弄影"  or 名称=="一笑倾城")  then
    self:添加状态("毒",self.参战单位[目标[n]],self.参战单位[编号],self.参战单位[编号].等级,编号)
    self.参战单位[目标[n]].法术状态.毒.回合=8
    end
    end
  end
end

function 战斗处理类:取封印成功(名称,等级,攻击方,挨打方,编号)
  if 名称=="画地为牢" or 名称=="河东狮吼" or 名称=="碎甲符" or 名称=="碎玉弄影" or 名称=="锢魂术" or 名称=="飞花摘叶" or 名称=="放下屠刀" or 名称=="凝滞术" or 名称=="停陷术" or 名称=="破甲术" or 名称=="碎甲术" or 名称=="魑魅缠身" or 名称=="利刃" then return true end
  if 名称=="瘴气" then return true end
  if 名称=="摧心术" then return true end
  if 名称=="镇妖" then return true end
  if 名称=="煞气诀" and 编号~=nil and self:取奇经八脉是否有(编号,"救人") then
  return true
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"索魂") and 名称=="锢魂术" then
  return true
  end

  if 挨打方.法术状态.乾坤妙法~=nil then return false end
  if 挨打方.不可封印 or 挨打方.鬼魂 or 挨打方.精神 or 挨打方.信仰 then
    return false
  end
    if 名称=="摄魂" or 名称=="无尘扇" or 名称=="断线木偶" or 名称=="无魂傀儡" then return true end
  if  名称=="发瘟匣" then
    --print(等级)
    if (18+15)>=取随机数() then return true
     else
       return false end
  end

  if 名称=="尸腐毒" and 挨打方.法术状态.百毒不侵 then
      return false
     end
   if 名称=="毒" and 挨打方.法术状态.百毒不侵 then
      return false
     end
    if 名称=="雾杀" and 挨打方.法术状态.百毒不侵 then
      return false
     end
    if 攻击方.法术状态.顺势而为 and (名称=="离魂符" or 名称=="失魂符" or 名称=="定身符" or 名称=="催眠符" or 名称=="失心符" or 名称=="失忆符" or 名称=="追魂符")then
    return true
    end
  if 名称=="雷浪穿云" or 名称=="落花成泥" or 名称=="凋零之歌" then return true end
  if 名称=="似玉生香" or 名称=="莲步轻舞" or 名称=="如花解语" or 名称=="碎玉弄影" then
     if 挨打方.法术状态.宁心 then
         return false
      end
    end
   if 名称=="含情脉脉"  or 名称=="魔音摄魂" or 名称=="天罗地网" then
     if 挨打方.法术状态.寡欲令 then
         return false
       end
     end
   if 名称=="含情脉脉" or 名称=="魔音摄魂" or 名称=="天罗地网" or 名称=="似玉生香" or 名称=="莲步轻舞" or 名称=="如花解语" or 名称=="碎玉弄影" or 名称=="催眠符" or 名称=="失心符" or 名称=="落魄符" or 名称=="失忆符" or 名称=="追魂符" or 名称=="离魂符" or 名称=="定身符"
     or 名称=="雷浪穿云" or 名称=="落花成泥" or 名称=="凋零之歌" or 名称=="日月乾坤" or 名称=="威慑" or 名称=="反间之计" or 名称=="错乱" or 名称=="夺魄令" then
     if 挨打方.法术状态.花护 then
         return false
       end
     end
   if 名称=="催眠符" or 名称=="失心符" or 名称=="落魄符" or 名称=="失忆符" or 名称=="追魂符" or 名称=="离魂符" or 名称=="定身符"   then
     if 挨打方.法术状态.驱魔 then
         return false
       end
     end
  if 名称~="日月乾坤" and 挨打方.神迹==2 then
     return false
  elseif 名称=="威慑" and 挨打方.类型=="角色" then
     return false
  elseif 名称=="反间之计" and 挨打方.类型=="角色" and (self.战斗类型==200003 or self.战斗类型==200004 or self.战斗类型==200005 or self.战斗类型==200006 or self.战斗类型==200007 or self.战斗类型==200008 or self.战斗类型==300001) then
     return false
  end
  --0914
    local 等级影响=等级-挨打方.等级
  if 挨打方.百无禁忌==nil then
    挨打方.百无禁忌=0 end
  local 基础几率=50+等级影响+攻击方.法术修炼-挨打方.抗法修炼
  基础几率 = 基础几率+qz((攻击方.封印命中等级/(攻击方.等级+25)*10)-(挨打方.抵抗封印等级+挨打方.百无禁忌/(挨打方.等级+25)*10))
  if self:取符石组合效果(挨打方,"百无禁忌")  then
      基础几率=基础几率-self:取符石组合效果(挨打方,"百无禁忌")
    end
  if 名称=="一笑倾城" or 名称=="妖风四起" then 基础几率=基础几率*0.5 end
  if 编号~=nil and self:取奇经八脉是否有(编号,"嫣然") and (名称=="似玉生香" or 名称=="一笑倾城") then
      基础几率=基础几率+20
  end

    if 攻击方.法术状态.凝神术~=nil then
    基础几率=基础几率+15
    end
  if 编号~=nil and self:取奇经八脉是否有(编号,"陌宝") and 名称=="日月乾坤" then
      if 挨打方.陌宝==nil then
          挨打方.陌宝=true
      end
      基础几率=基础几率+2
      攻击方.伤害=qz(攻击方.伤害*0.85)
  end
  if 攻击方.法术状态~=nil and 攻击方.法术状态.四面埋伏~=nil and  攻击方.气血>= 攻击方.最大气血*0.4 then
  基础几率=math.floor(基础几率*1.11)
  end
  if 挨打方.法术状态 ~=nil and 挨打方.法术状态.画地为牢~=nil then
  基础几率=0
  end
  if 攻击方.名称=="章鱼哥 " and self.战斗类型==100237 then
  基础几率=100
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"回敬") and 攻击方.气血<=qz(攻击方.最大气血*0.5) then
  基础几率=math.floor(基础几率*1.15)
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"不倦") and 名称=="催眠符" then
  基础几率=math.floor(基础几率*1.2)
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"忘川") and 名称=="含情脉脉" then
  基础几率=math.floor(基础几率*1.15)
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"鼓乐") and 名称=="魔音摄魂" then
  基础几率=math.floor(基础几率*1.2)
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"乾坤") and 名称=="日月乾坤"  then
  基础几率=基础几率+12
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"趁虚")  then
  基础几率=基础几率+10
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"淬芒") then
    if 挨打方.法术状态.毒~=nil then
     基础几率=基础几率+10
    end
  end
  if 挨打方.慧心~=nil then
    基础几率=基础几率-6*挨打方.慧心
  end
  if 基础几率>=70 then
    基础几率=70
  end
  if 攻击方.法术状态~=nil and 攻击方.法术状态.自矜~=nil then
    基础几率=基础几率+30
  end
  if 基础几率>=取随机数() then
    if 攻击方.法术状态~=nil and 攻击方.法术状态.自矜~=nil then
        self:取消状态("自矜",self.参战单位[编号])
    end
    return true
  else
    if 编号~=nil and self:取奇经八脉是否有(编号,"自矜") then
       self:添加状态("自矜",self.参战单位[编号],nil,nil,编号)
    end
    return false
  end
end
function 战斗处理类:取是否物攻技能(名称)
  if 名称=="断岳势"  then
    return true
  elseif 名称=="天崩地裂"  then
    return true
  elseif 名称=="惊涛怒"  then
    return true
  elseif 名称=="翻江搅海" then
    return true
  elseif 名称=="裂石" then
    return true
  elseif 名称=="浪涌" then
    return true
  elseif 名称=="烟雨剑法" then
    return true
  elseif 名称=="牛刀小试" then
    return true
  elseif 名称=="连环击" then
    return true
  elseif 名称=="剑荡四方" then
    return true
  elseif 名称=="横扫千军" or 名称=="高级连击" or 名称=="理直气壮" or "武神怒击" then
    return true
  elseif 名称=="狮搏" then
    return true
  elseif 名称=="鹰击" then
    return true
  elseif 名称=="破血狂攻" then
    return true
  elseif 名称=="象形" then
    return true
  elseif 名称=="后发制人" then
    return true
  elseif 名称=="壁垒击破" or 名称=="弱点击破" then
    return true
  elseif 名称=="满天花雨" then
    return true
  elseif 名称=="威震凌霄" or 名称=="当头一棒" or 名称=="神针撼海" or 名称=="杀威铁棒" or 名称=="泼天乱棒" then
    return true
  end
  return false
end

function 战斗处理类:物攻技能计算(编号,名称,等级)
  if 名称=="后发制人" then
    if self:取行动状态(编号)==false or self:取目标状态(编号,self.参战单位[编号].法术状态.后发制人.目标,1)==false then
      self:取消状态(名称,self.参战单位[编号])
      self.战斗流程[#self.战斗流程+1]={流程=610,攻击方=编号,状态="后发制人",挨打方={{挨打方=1}}}
      return
    else
      self.参战单位[编号].指令.目标=self.参战单位[编号].法术状态.后发制人.目标
    end
  end
  local 目标=self.参战单位[编号].指令.目标
  local 目标数=self:取目标数量(self.参战单位[编号],名称,等级,编号)
  local 目标=self:取多个敌方目标(编号,目标,目标数)
  local 战意提示=false
  for n=1,#目标 do
    if self.参战单位[目标[n]].法术状态.分身术~=nil and self.参战单位[目标[n]].法术状态.分身术.破解==nil then
      self.参战单位[目标[n]].法术状态.分身术.破解=1
      table.remove(目标,n)
      --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/被目标分身术躲过去了！")
      --self:添加提示(self.参战单位[目标].玩家id,编号,"#Y/分身术躲避了一次攻击")
      return
    end
  end
  if #目标==0 then return end
  目标数=#目标
  if 名称=="断岳势" and self.参战单位[编号].战意<1 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前可使用的战意为#R/"..self.参战单位[编号].战意.."#Y/点，无法使用"..名称)
    return
  elseif 名称=="天崩地裂" and self.参战单位[编号].战意<3 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前可使用的战意为#R/"..self.参战单位[编号].战意.."#Y/点，无法使用"..名称)
    return
  elseif 名称=="惊涛怒" and self.参战单位[编号].战意<1 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前可使用的战意为#R/"..self.参战单位[编号].战意.."#Y/点，无法使用"..名称)
    return
  elseif 名称=="翻江搅海" and self.参战单位[编号].战意<3 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前可使用的战意为#R/"..self.参战单位[编号].战意.."#Y/点，无法使用"..名称)
    return
  elseif 名称=="翩鸿一击" and self.参战单位[编号].翩鸿回合~=nil and self.回合数-self.参战单位[编号].翩鸿回合<6 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(6-(self.回合数-self.参战单位[编号].翩鸿回合)).."#Y/回合后才可使用")
    return
  elseif 名称=="长驱直入" and self.参战单位[编号].长驱回合~=nil and self.回合数-self.参战单位[编号].长驱回合<4 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(4-(self.回合数-self.参战单位[编号].长驱回合)).."#Y/回合后才可使用")
    return
  elseif 名称=="鸿渐于陆" and self.参战单位[编号].鸿渐回合~=nil and self.回合数-self.参战单位[编号].鸿渐回合<4 then
     self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(4-(self.回合数-self.参战单位[编号].鸿渐回合)).."#Y/回合后才可使用")
     return
  elseif 名称=="天命剑法" and self.参战单位[编号].天命回合~=nil and self.回合数-self.参战单位[编号].天命回合<5 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(5-(self.回合数-self.参战单位[编号].天命回合)).."#Y/回合后才可使用")
    return
  elseif 名称=="背水" and self.参战单位[编号].背水回合~=nil and self.回合数-self.参战单位[编号].背水回合<8 then
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/该技能必须等待#R/"..(8-(self.回合数-self.参战单位[编号].背水回合)).."#Y/回合后才可使用")
    return
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"魂聚") then
      self.参战单位[编号].愤怒=self.参战单位[编号].愤怒+6
      if self.参战单位[编号].愤怒 > 150 then
        self.参战单位[编号].愤怒 = 150
      end
  end



  if 消耗==nil and self:技能消耗(self.参战单位[编号],目标数,名称,编号)==false then self:添加提示(self.参战单位[编号].玩家id,编号,"未到达技能消耗要求,技能使用失败") return  end
    if 名称=="断岳势" and self.参战单位[编号].战意>=1 then
       self.参战单位[编号].战意=self.参战单位[编号].战意-1
       战意提示=true
    elseif 名称=="天崩地裂" and self.参战单位[编号].战意>=3 then
        self.参战单位[编号].战意=self.参战单位[编号].战意-3
        if 编号~=nil and self:取奇经八脉是否有(编号,"山破") and 取随机数(1,100)<=64 and self.参战单位[编号].战意<6 then
          self.参战单位[编号].战意=self.参战单位[编号].战意+1
        end
        战意提示=true
    elseif 名称=="惊涛怒" and self.参战单位[编号].战意>=1 then
        self.参战单位[编号].战意=self.参战单位[编号].战意-1
        战意提示=true
    elseif 名称=="翻江搅海" and self.参战单位[编号].战意>=3 then
        self.参战单位[编号].战意=self.参战单位[编号].战意-3
        if 编号~=nil and self:取奇经八脉是否有(编号,"山破") and 取随机数(1,100)<=64 and self.参战单位[编号].战意<6 then
          self.参战单位[编号].战意=self.参战单位[编号].战意+1
        end
        战意提示=true
    elseif 名称=="裂石" then
      if self.参战单位[编号].战意<6 then
        self.参战单位[编号].战意=self.参战单位[编号].战意+1
      end
        战意提示=true
    elseif 名称=="浪涌" then
      if self.参战单位[编号].战意<6 then
        self.参战单位[编号].战意=self.参战单位[编号].战意+1
      end
        战意提示=true
    end
    if 战意提示 then
        self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前可使用的战意为#R/"..self.参战单位[编号].战意.."#Y/点")
    end
    local 返回=nil
    local 重复攻击=false
    local 起始伤害=1
    local 叠加伤害=0
    local 重复提示=false
    local 允许保护=true
    local 增加伤害=0
    local 伤害参数=0
    local 结尾气血=0
    local 防御减少=0
    if 名称=="烟雨剑法" then
    目标数=2
    重复攻击=true
    伤害参数=2
    起始伤害=0.9
      if self:取符石组合效果(编号,"烟雨飘摇") then
      增加伤害=qz(增加伤害+self:取符石组合效果(编号,"烟雨飘摇"))
      end
    if 编号~=nil and self:取奇经八脉是否有(编号,"修心") then
    目标数=目标数+1
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"心随意动") then
    目标数=目标数+取随机数(0,3)
    end
    elseif 名称=="飘渺式" then
    起始伤害=0.9
    伤害参数=2
    if self:取符石组合效果(编号,"烟雨飘摇") then
    增加伤害=qz(增加伤害+self:取符石组合效果(编号,"烟雨飘摇"))
    end
    elseif 名称=="连环击" then
    目标数=math.floor(等级/35)+2
    重复攻击=true
    伤害参数=1
    起始伤害=0.8
    叠加伤害=-0.15
    if 编号~=nil and self:取奇经八脉是否有(编号,"乱击") then
    目标数=目标数+1
    end
    elseif 名称=="猛击" then
      目标数=2
      重复攻击=true
      伤害参数=3
      起始伤害=1.25
    elseif 名称=="斩龙诀" then
    起始伤害=1.35
    if self.参战单位[目标[1]].门派=="龙宫" then
    起始伤害=10
    end
    elseif 名称=="情天恨海" then
    起始伤害=1.35
    if self.参战单位[目标[1]].门派=="五庄观" then
    起始伤害=10
    end
    elseif 名称=="指地成钢" then
    起始伤害=1.35
    if self.参战单位[目标[1]].门派=="无底洞" then
    起始伤害=10
    end
    elseif 名称=="魔兽啸天" then
    起始伤害=1.35
    if self.参战单位[目标[1]].门派=="天宫" then
    起始伤害=10
    end
    elseif 名称=="鸿渐于陆" then
      起始伤害=2.5
      self.参战单位[编号].鸿渐回合=self.回合数
    elseif 名称=="剑荡四方" then
       --温水煮青蛙，晚点再砍
      起始伤害=0.9
      if self.参战单位[编号].类型=="bb" then
        叠加伤害=-0.2
      else
        起始伤害=0.8
        叠加伤害=-0.2
      end
      结尾气血=qz(self.参战单位[编号].气血*0.01)
      self:减少气血(编号,结尾气血)
    elseif 名称=="横扫千军" then
      起始伤害=0.7
      叠加伤害=0.12
      重复攻击=true
      伤害参数=1.5
      目标数=3
      if self.参战单位[编号].类型=="角色" then
        结尾气血=qz(self.参战单位[编号].最大气血*0.1)
        self:减少气血(编号,结尾气血)
      else
      end
      if 编号~=nil and self:取奇经八脉是否有(编号,"无敌") then
      目标数=目标数+1
      end
      if 编号~=nil and self:取奇经八脉是否有(编号,"破军") and 取随机数(1,100)<=30  then
      目标数=目标数+3
      end
    elseif 名称=="武神怒击" then
    起始伤害=1
    叠加伤害=1
    重复攻击=true
    伤害参数=1.5
    目标数=10
    elseif 名称=="破釜沉舟" then
    起始伤害=1.8
    if self.参战单位[编号].类型=="角色" then
    结尾气血=qz(self.参战单位[编号].最大气血*0.1)
    self:减少气血(编号,结尾气血)
    else
    end
    elseif 名称=="天命剑法" then
      起始伤害=1.6
      目标数=取随机数(3,7)
      重复攻击=true
      伤害参数=1.5
      self.参战单位[编号].天命回合=self.回合数
    elseif 名称=="背水" then
      if  取随机数(1,100)<=1 then
          起始伤害=999
      else
          起始伤害=3
      end
      if self.参战单位[编号].类型=="角色" then
      结尾气血=qz(self.参战单位[编号].气血*0.5)
      self:减少气血(编号,结尾气血)
      self.参战单位[编号].背水回合=self.回合数
      else
      end
    elseif 名称=="天雷斩" then
      起始伤害=0.8
      if self:取玩家战斗()==false then
        起始伤害=1.1
      end
      增加伤害=增加伤害+qz(self.参战单位[编号].灵力*0.1)
      if self:取符石组合效果(编号,"天雷地火") then
      伤害=qz(伤害+self:取符石组合效果(编号,"天雷地火"))
      end
      if 编号~=nil and self:取奇经八脉是否有(编号,"疾雷") then
        local 人物敏捷=self.参战单位[编号].敏捷+self.参战单位[编号].装备属性.敏捷
          增加伤害=增加伤害+(人物敏捷-self.参战单位[编号].等级)*0.6
      end
    elseif 名称=="高级连击" or 名称=="连击" then
      for n=1,#目标 do
      if self.参战单位[目标[n]].反震==nil then
      起始伤害=0.8
      叠加伤害=-0.1
      目标数=2
      重复攻击=true
      else
      起始伤害=0.8
    end
    end
    elseif 名称=="理直气壮" then
      起始伤害=0.9
      叠加伤害=-0.1
      目标数=3
      重复攻击=true
    elseif 名称=="后发制人" then
    起始伤害=1.8
    if 编号~=nil and self:取奇经八脉是否有(编号,"目空") then
    防御减少=self.参战单位[目标[1]].防御*0.1
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御-防御减少
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"勇武") then
    增加伤害=增加伤害+self.参战单位[目标[1]].防御*0.5
    end
    结尾气血=qz(self.参战单位[编号].气血*0.05)
    self:减少气血(编号,结尾气血)
    elseif 名称=="浪涌" then
    起始伤害=0.9
    伤害参数=1
    self.参战单位[编号].必杀=self.参战单位[编号].必杀+5
    elseif 名称=="惊涛怒" then
    起始伤害=1.1
    伤害参数=1.5
    self.参战单位[编号].必杀=self.参战单位[编号].必杀+5
    if 编号~=nil and self:取奇经八脉是否有(编号,"再战") then
         增加伤害=增加伤害+self.参战单位[编号].等级*3
    end
    elseif 名称=="翻江搅海" then
    起始伤害=1.0
    伤害参数=1.5
    self.参战单位[编号].必杀=self.参战单位[编号].必杀+3
    elseif 名称=="裂石" then
    起始伤害=1.2
    伤害参数=1.5
    self.参战单位[编号].必杀=self.参战单位[编号].必杀+20
    if 编号~=nil and self:取奇经八脉是否有(编号,"再战") then
         增加伤害=增加伤害+self.参战单位[编号].等级*5
    end
    elseif 名称=="断岳势" then
    目标数=2
    重复攻击=true
    伤害参数=2
    起始伤害=1
    叠加伤害=-0.1
    self.参战单位[编号].必杀=self.参战单位[编号].必杀+10
    if 编号~=nil and self:取奇经八脉是否有(编号,"再战") then
         增加伤害=增加伤害+self.参战单位[编号].等级*3
     end
    elseif 名称=="天崩地裂" then
    目标数=3
    重复攻击=true
    伤害参数=2
    起始伤害=0.9
    叠加伤害=-0.05
    self.参战单位[编号].必杀=self.参战单位[编号].必杀+10
    if 编号~=nil and self:取奇经八脉是否有(编号,"天神怒斩") then
      if 取随机数(1,100)<=10 then
        目标数=目标数+2
        end
        目标数=目标数+1
     end
     -- 0914 满天花雨 机制完善
  elseif 名称=="满天花雨" then
  起始伤害=1.5
  if self.参战单位[编号].漫天层数==nil then
  self.参战单位[编号].漫天层数=0
  end
  self.参战单位[编号].漫天层数=self.参战单位[编号].漫天层数+1
  if self.参战单位[编号].漫天层数>3 then
  self.参战单位[编号].漫天层数=3
  end
  if self.参战单位[编号].漫天层数>1 then
  self:取消状态("满天花雨"..self.参战单位[编号].漫天层数-1,self.参战单位[编号])
  end
  self:添加状态("满天花雨"..self.参战单位[编号].漫天层数,self.参战单位[编号],self.参战单位[目标[1]],self.参战单位[编号].漫天层数,编号，nil)

  elseif 名称=="狮搏" then
  起始伤害=1.35
  伤害参数=1
  if 编号~=nil and self:取奇经八脉是否有(编号,"威震") then
  self.参战单位[编号].必杀=self.参战单位[编号].必杀+30
  end
  elseif 名称=="狮搏 " then
  起始伤害=1.2
  elseif 名称=="鹰击" then
  起始伤害=1.1
  伤害参数=1.5
  重复提示=true
  返回=true
  elseif 名称=="壁垒击破" then
    起始伤害=1.1 --温水煮青蛙，晚点再砍
    if self:取技能重复(self.参战单位[目标[1]],"防御") then
      防御减少=qz(self.参战单位[目标[1]].等级*0.6)
    end
    if self:取技能重复(self.参战单位[目标[1]],"高级防御") then
      防御减少=qz(self.参战单位[目标[1]].等级*0.8)
    end
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御-防御减少
    if self.参战单位[目标[1]].指令.类型=="防御" then
      增加伤害=qz(self.参战单位[编号].伤害*1.5)
    end
  elseif 名称=="翩鸿一击" then
    起始伤害=1.5
    if 编号~=nil and self:取奇经八脉是否有(编号,"目空") then
    防御减少=self.参战单位[目标[1]].防御*0.1
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御-防御减少
    end

    self.参战单位[编号].翩鸿回合=self.回合数
  elseif 名称=="长驱直入" then
    起始伤害=1.2
    self.参战单位[编号].长驱回合=self.回合数
 elseif 名称=="针锋相对" then
    起始伤害=1.5
    if 编号~=nil and self:取奇经八脉是否有(编号,"善工") then
      起始伤害=1.7
    end
    if self.参战单位[编号].零件==nil then  self.参战单位[编号].零件=0 end
      if self.参战单位[编号].攻之械==nil then self.参战单位[编号].攻之械=0 end
       if self.参战单位[编号].零件<3 and self.参战单位[编号].法术状态.据守==nil and self.参战单位[编号].法术状态.巨锋==nil and self.参战单位[编号].法术状态.战复==nil then
     self.参战单位[编号].零件=self.参战单位[编号].零件+1
      self.参战单位[编号].攻之械=self.参战单位[编号].攻之械+1
       end
     if self.参战单位[编号].攻之械>1 then
   self:取消状态("攻之械"..self.参战单位[编号].攻之械-1,self.参战单位[编号])
     end
    self:添加状态("攻之械"..self.参战单位[编号].攻之械,self.参战单位[编号],self.参战单位[目标[1]],self.参战单位[编号].攻之械,编号,nil)
    if self.参战单位[编号].攻之械>=3 and self.参战单位[编号].零件>=3 then
      self:取消状态("攻之械"..self.参战单位[编号].攻之械,self.参战单位[编号])
      self.参战单位[编号].零件=0
      self.参战单位[编号].攻之械=0
      self:添加状态("巨锋",self.参战单位[编号])
    end
    if self.参战单位[编号].攻之械>=1 and self.参战单位[编号].零件>=3 and self.参战单位[编号].守之械>=1 then
      self:取消状态("守之械"..self.参战单位[编号].守之械,self.参战单位[编号])
      self:取消状态("攻之械"..self.参战单位[编号].攻之械,self.参战单位[编号])
      self.参战单位[编号].零件=0
      self.参战单位[编号].攻之械=0
      self.参战单位[编号].守之械=0
      self:添加状态("战复",self.参战单位[编号])
    end
  elseif 名称=="百爪狂杀" then
    起始伤害=1.2
    伤害参数=1
    if 编号~=nil and self:取奇经八脉是否有(编号,"击破") and 取随机数(1,100) <=5  then
    增加伤害=增加伤害+self.参战单位[编号].等级*10
    end
  elseif 名称=="六道无量" then
    目标数=1
    重复攻击=true
    起始伤害=1.4
    if 编号~=nil and self:取奇经八脉是否有(编号,"百炼") then
      目标数=目标数+1
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"夜之王者") and 取随机数(1,100) <=50 then
      目标数=目标数+2
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"击破") and 取随机数(1,100) <=15  then
    增加伤害=增加伤害+self.参战单位[编号].等级*10
    end
  elseif 名称=="威震凌霄" then
    起始伤害=1.5
  elseif 名称=="当头一棒" then
    起始伤害=1.8
    if self:取玩家战斗()==false then
      起始伤害=2.5
    end
    if self.参战单位[目标[1]].气血>=qz(self.参战单位[目标[1]].最大气血*0.6) and self.参战单位[目标[1]].气血<=qz(self.参战单位[目标[1]].最大气血*0.7) then
      起始伤害=起始伤害*2
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"闹天") then
      起始伤害=qz(起始伤害*1.15)
    end
  elseif 名称=="神针撼海" then
    起始伤害=1.3
    if 编号~=nil and self:取奇经八脉是否有(编号,"搅海") and 取随机数()>=90 then
      起始伤害=qz(起始伤害*2)
    end
  elseif 名称=="杀威铁棒" then
    起始伤害=1.5
    self:添加状态("杀威铁棒",self.参战单位[目标[1]],self.参战单位[编号],self.参战单位[编号].等级,编号)
  elseif 名称=="泼天乱棒" then
    if self:取玩家战斗()==false then
    起始伤害=2
  else
    起始伤害=1.3
  end
  elseif 名称=="破血狂攻" then
    目标[2]=目标[1]
    目标数=#目标
    if 编号~=nil and self:取奇经八脉是否有(编号,"目空") then
    防御减少=self.参战单位[目标[1]].防御*0.1
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御-防御减少
    end
    起始伤害=1.2
  elseif 名称=="破碎无双" then
    if 编号~=nil and self:取奇经八脉是否有(编号,"目空") then
    防御减少=self.参战单位[目标[1]].防御*0.1
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御-防御减少
    end
    起始伤害=1.2
  elseif 名称=="死亡召唤" then
    起始伤害=0.9
  elseif 名称=="弱点击破" then
    if 编号~=nil and self:取奇经八脉是否有(编号,"目空") then
    防御减少=self.参战单位[目标[1]].防御*0.6
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御-防御减少
    else
    防御减少=self.参战单位[目标[1]].防御*0.5
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御-防御减少
    end
    起始伤害=1.2
  elseif 名称=="牛刀小试" then
    起始伤害=0.95
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"煞气") and 取随机数(1,100)<=5 then
      增加伤害=增加伤害+self.参战单位[编号].等级*10
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"强袭") and self.参战单位[编号].法术状态.不动如山~=nil then
  增加伤害=增加伤害+self.参战单位[编号].等级*1.5
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"六道无量") then
  增加伤害=增加伤害+self.参战单位[目标[1]].防御*0.15
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"怒涛") then
    for n=1,#目标 do
    增加伤害=增加伤害+self.参战单位[目标[n]].防御*0.3
    end
    end

  if 增加伤害==nil then
      增加伤害=0
  end
    增加伤害=增加伤害+伤害参数*等级
    -- 0914 满天花雨机制完善
    self.参战单位[编号].伤害=self.参战单位[编号].伤害+增加伤害
    if 重复攻击 == true then
      local 临时目标=目标[1]
      for n=1,目标数 do
        目标[n]=临时目标
      end
    end

    local 战斗终止=false
    for n=1,目标数 do
      if 战斗终止==false  then
        self:物攻技能计算1(编号,目标[n],起始伤害,叠加伤害,返回,允许保护,n,名称)--
        local 提示内容x = ""
        if 名称~= "高级连击" or 名称~="理直气壮" then
          提示内容x = self.参战单位[编号].名称.."使用了"..名称
        end
        self.战斗流程[#self.战斗流程].提示={类型="法术",名称=提示内容x,允许=true}
        if 名称=="破釜沉舟" and n==1 then
        self.战斗流程[#self.战斗流程].流程=400.1
        end
        if 名称=="翻江搅海" and n==1 then
        self.战斗流程[#self.战斗流程].流程=400.2
        end
        if 名称=="武神怒击" and n==1 then
        self.战斗流程[#self.战斗流程].流程=400
        end
        if 名称=="力劈华山" and n==1 then
        self.战斗流程[#self.战斗流程].流程=401
        end

        if n==1 and 编号~=nil and self:取奇经八脉是否有(编号,"爪印") then
          local 爪印层数 = 1
          if self.参战单位[目标[1]].法术状态.爪印~=nil and self.参战单位[目标[1]].法术状态.爪印.层数~=nil then
            爪印层数=self.参战单位[目标[1]].法术状态.爪印.层数+1
          end
          self:取消状态("爪印",self.参战单位[目标[1]])
          self:添加状态("爪印",self.参战单位[目标[1]],self.参战单位[目标[1]],爪印层数,目标[1])
          self.战斗流程[#self.战斗流程].挨打方[1].增加状态="爪印"
        end

        if n>1 and 重复提示==false then
          self.战斗流程[#self.战斗流程].提示.允许=false
        end
        if n==目标数 then
          self.战斗流程[#self.战斗流程].返回=true
        elseif self:取目标状态(编号,目标[n+1],1)==false or self:取行动状态(编号)==false then
          self.战斗流程[#self.战斗流程].返回=true
          战斗终止=true
        end
      end
    end
    self.参战单位[编号].伤害=self.参战单位[编号].伤害-增加伤害

    if 名称=="鹰击" then
      self:添加状态(名称,self.参战单位[编号],nil,nil,编号)
      self.战斗流程[#self.战斗流程].添加状态=名称
      elseif 名称=="横扫千军" then
      if self.参战单位[编号].类型~="角色" then
      self:添加状态("横扫千军",self.参战单位[编号],nil,nil,编号)
      self.战斗流程[#self.战斗流程].添加状态="横扫千军"
      else
      self:添加状态(名称,self.参战单位[编号],nil,nil,编号)
      self.战斗流程[#self.战斗流程].添加状态=名称
      self.战斗流程[#self.战斗流程].结尾气血=结尾气血
      end
      elseif 名称=="破釜沉舟" then
      if self.参战单位[编号].类型~="角色" then
      self:添加状态("横扫千军",self.参战单位[编号],nil,nil,编号)
      self.战斗流程[#self.战斗流程].添加状态="横扫千军"
      else
      self:添加状态(名称,self.参战单位[编号],nil,nil,编号)
      self.战斗流程[#self.战斗流程].添加状态=名称
      self.战斗流程[#self.战斗流程].结尾气血=结尾气血
      end
      -----------摩托修改打怪横扫和狮驼不用休息---------
      -- if 名称=="鹰击" and self:取玩家战斗()==false and self.参战单位[编号].类型~="bb" then
      --   self.战斗流程[#self.战斗流程].取消状态="鹰击"
      --   self:取消状态("鹰击",self.参战单位[编号])
      -- end

      -- if 名称=="横扫千军" and self:取玩家战斗()==false and self.参战单位[编号].类型~="bb" then
      --   self.战斗流程[#self.战斗流程].取消状态="横扫千军"
      --   self:取消状态("横扫千军",self.参战单位[编号])
      -- end
    elseif 名称=="天命剑法" then
      self:添加状态("横扫千军",self.参战单位[编号])
      self.战斗流程[#self.战斗流程].添加状态="横扫千军"
    elseif 名称=="翩鸿一击"then
      if 编号~=nil and self:取奇经八脉是否有(编号,"目空") then
      self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御+防御减少
      end
      self:添加状态("翩鸿一击",self.参战单位[编号])
      self.战斗流程[#self.战斗流程].添加状态="翩鸿一击"
    elseif 名称=="长驱直入"then
      self.战斗流程[#self.战斗流程].挨打方[1].添加状态="重创"
      self:添加状态("重创",self.参战单位[目标[1]])
    elseif 名称=="剑荡四方"then
      self.战斗流程[#self.战斗流程].结尾气血=结尾气血
    elseif 名称=="狮搏" or 名称=="狮搏 " then
    if 编号~=nil and self:取奇经八脉是否有(编号,"失心") and 取随机数()<=30 then
    self.战斗流程[#self.战斗流程].挨打方[1].添加状态="象形"
    self:添加状态("象形",self.参战单位[目标[1]])
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"威震") then
    self.参战单位[编号].必杀=self.参战单位[编号].必杀-30
    end
    elseif 名称=="裂石" then
      self.参战单位[编号].必杀=self.参战单位[编号].必杀-20
    elseif 名称=="威震凌霄" then
      self:添加状态("威震凌霄",self.参战单位[目标[1]],self.参战单位[编号],self:取技能等级(编号,"威震凌霄"),编号)
    elseif 名称=="断岳势" then
       self.参战单位[编号].必杀=self.参战单位[编号].必杀-10
    elseif 名称=="象形" then
    if 编号~=nil and self:取奇经八脉是否有(编号,"怒象") and 取随机数()<=70 then
       self.战斗流程[#self.战斗流程].挨打方[1].添加状态=名称
       self:添加状态(名称,self.参战单位[目标[1]])
       self:添加状态("鹰击",self.参战单位[编号],nil,nil,编号)
       self.战斗流程[#self.战斗流程].添加状态="鹰击"
     else
      self.战斗流程[#self.战斗流程].挨打方[1].添加状态=名称
      self.战斗流程[#self.战斗流程].取消状态="变身"
      self:添加状态(名称,self.参战单位[目标[1]])
      self:添加状态("鹰击",self.参战单位[编号],nil,nil,编号)
      self:取消状态("变身",self.参战单位[编号])
      self.战斗流程[#self.战斗流程].添加状态="鹰击"
    end
    elseif 名称=="天魔解体" then
      self.战斗流程[#self.战斗流程].结尾气血=结尾气血
    elseif 名称=="背水" then
      self.战斗流程[#self.战斗流程].结尾气血=结尾气血
      self.战斗流程[#self.战斗流程].取消状态="变身"
      self:添加状态("鹰击",self.参战单位[编号],nil,nil,编号)
      self:取消状态("变身",self.参战单位[编号])
      self.战斗流程[#self.战斗流程].添加状态="鹰击"
    elseif 名称=="连环击" then
      self.战斗流程[#self.战斗流程].取消状态="变身"
      self:添加状态("鹰击",self.参战单位[编号],nil,nil,编号)
      self:取消状态("变身",self.参战单位[编号])
      self.战斗流程[#self.战斗流程].添加状态="鹰击"
    elseif 名称=="死亡召唤" and 取随机数()<=50 then
      self.战斗流程[#self.战斗流程].挨打方[1].增加状态=名称
      self:添加状态(名称,self.参战单位[目标[1]])
    elseif 名称=="天崩地裂" then
    self.参战单位[编号].必杀=self.参战单位[编号].必杀-10
    if 编号~=nil and self:取奇经八脉是否有(编号,"暴气") and 取随机数(1,100)<=30 then
    self:添加状态("不动如山",self.参战单位[编号],self.参战单位[编号],self.参战单位[编号].等级,编号)
    self.战斗流程[#self.战斗流程].添加状态="不动如山"
    end
    elseif 名称=="翻江搅海" then
    self.参战单位[编号].必杀=self.参战单位[编号].必杀-3
    if 编号~=nil and self:取奇经八脉是否有(编号,"暴气") and 取随机数(1,100)<=30 then
    self:添加状态("不动如山",self.参战单位[编号],self.参战单位[编号],self.参战单位[编号].等级,编号)
    self.战斗流程[#self.战斗流程].添加状态="不动如山"
    end
    elseif 名称=="惊涛怒" or 名称=="浪涌" then
    self.参战单位[编号].必杀=self.参战单位[编号].必杀-5
    elseif 名称=="后发制人" then
    if 编号~=nil and self:取奇经八脉是否有(编号,"目空") then
    self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御+防御减少
    self.战斗流程[#self.战斗流程].取消状态="后发制人"
    self:取消状态("后发制人",self.参战单位[编号])
    self.战斗流程[#self.战斗流程].结尾气血=结尾气血
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"勇武") then
    self.战斗流程[#self.战斗流程].取消状态="后发制人"
    self:取消状态("后发制人",self.参战单位[编号])
    恢复气血=qz(self.参战单位[编号].最大气血*0.15)
    self:增加气血(编号,恢复气血)
    self.战斗流程[#self.战斗流程].气血恢复=恢复气血
    if self.参战单位[编号].愤怒~=nil then self.参战单位[编号].愤怒=self.参战单位[编号].愤怒+10 end
    if self.参战单位[编号].愤怒>150 then self.参战单位[编号].愤怒=150 end
    end
    if self.参战单位[编号].类型~="角色" then
    self.战斗流程[#self.战斗流程].取消状态="后发制人"
    self:取消状态("后发制人",self.参战单位[编号])
    else
    self.战斗流程[#self.战斗流程].取消状态="后发制人"
    self:取消状态("后发制人",self.参战单位[编号])
    self.战斗流程[#self.战斗流程].结尾气血=结尾气血
    end
    elseif 名称=="壁垒击破" or 名称=="弱点击破" then
      self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御+防御减少
    elseif 编号~=nil and self:取奇经八脉是否有(编号,"目空") and (名称=="破血狂攻" or 名称=="破碎无双") then
      self.参战单位[目标[1]].防御=self.参战单位[目标[1]].防御+防御减少
    elseif 名称=="鸿渐于陆" then
   for n=1,#目标 do
    self:添加状态("毒",self.参战单位[目标[n]],self.参战单位[编号],self.参战单位[编号].等级,编号)
    self.参战单位[目标[n]].法术状态.毒.回合=6
  end
    elseif 名称=="满天花雨" then
      for n=1,#目标 do
      if  取随机数(1,100)<=30 then
          self:添加状态("毒",self.参战单位[目标[n]],self.参战单位[编号],self.参战单位[编号].等级,编号)
          self.参战单位[目标[n]].法术状态.毒.回合=6
        end
      end
    end
end

function 战斗处理类:添加状态(名称,攻击方,挨打方,等级,攻击编号,境界)
  if 名称=="莲心剑意" and 攻击方.法术状态[名称]~=nil then
    攻击方.法术状态[名称]=nil
    return
  end
  if 攻击方.法术状态[名称]~=nil then
    return
  elseif 名称=="碎星诀" and 攻击方.法术状态["镇魂诀"]~=nil then
    return
  elseif 名称=="镇魂诀" and 攻击方.法术状态["碎星诀"]~=nil then
    return
  end
  攻击方.法术状态[名称]={攻击编号=攻击编号,境界=境界}
  if 攻击方.躲避减少==nil then 攻击方.躲避减少=0 end
  --0914神机步
  local 躲避减少1=攻击方.躲避减少
  local 伤害1=攻击方.伤害
  local 防御1=攻击方.防御
  local 速度1=攻击方.速度
  local 法防1=攻击方.灵力
  local 躲闪1=攻击方.躲闪
  local 命中1=攻击方.命中
  local 灵力1=攻击方.灵力
  local 回合=2
  local 伤害=0
  local 防御=0
  local 速度=0
  local 法防=0
  local 躲闪=0
  local 类型=1
  local 命中=0
  local 灵力=0
  local 法伤=0
  local 护盾值=0
  local 躲避减少=0
  local 必杀=0
  local 法暴=0
  local 编号=攻击编号
  if 名称=="横扫千军" then
  回合=2
  if 攻击方.门派=="大唐官府"  and 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"连破") and self:取玩家战斗() and 取随机数(1,100)<=30 then
  回合=回合-1
  end
  if 攻击方.门派=="大唐官府"  and 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"连破") then
  回合=回合-1
  end
  elseif 名称=="攻之械1" then
    回合=999
    类型=2
  elseif 名称=="攻之械2" then
     回合=999
    类型=2
  elseif 名称=="攻之械3" then
     回合=999
    类型=2
  elseif 名称=="据守" then
    回合=5
    防御=qz(防御1*0.5)
    法防=qz(法防1*0.5)
    类型=2
  elseif 名称=="巨锋" then
    回合=5
    伤害=qz(伤害1*0.5)
    类型=2
  elseif 名称=="战复" then
    回合=5
    伤害=qz(伤害1*0.25)
    防御=qz(防御1*0.25)
    法防=qz(法防1*0.25)
    类型=2
  elseif 名称=="守之械1" then
    回合=999
    类型=2
  elseif 名称=="守之械2" then
     回合=999
    类型=2
  elseif 名称=="守之械3" then
     回合=999
    类型=2
  elseif 名称=="满天花雨1" then
    回合=999
    伤害=qz(伤害1*0.1)
    类型=2
  elseif 名称=="满天花雨2" then
     回合=999
    伤害=qz(伤害1*0.15)
    类型=2
  elseif 名称=="满天花雨3" then
     回合=999
    伤害=qz(伤害1*0.2)
    类型=2
  elseif 名称=="护盾"  then
    回合=999
    护盾值=等级
  elseif 名称=="蚀天" then
    回合=3
  elseif 名称=="轰鸣" then
    回合=3
    防御=240
  elseif 名称=="黄泉之息" then
    回合=qz(等级/20)+2
    速度=速度1-速度1*0.9
  if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"黄泉")then
    速度=速度1-速度1*0.7
  end
  elseif 名称=="妖风四起" or 名称=="同舟共济" then
    回合=3
  elseif 名称=="电芒" then
    回合=3
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].攻击编号=攻击编号
  elseif 名称=="画地为牢" then
    回合=5
  elseif 名称=="一笑倾城" then
    回合=3
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"嫣然")  then
    回合=回合+3
    end
  elseif 名称=="飞花摘叶" then
    回合=3
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"花殇") then
    回合=回合+1
    end
  elseif 名称=="惊魂铃" or 名称=="鬼泣" then
    回合=2
    攻击方.法术状态[名称].等级=等级
  elseif 名称=="发瘟匣" or 名称=="断线木偶" or 名称=="摄魂" or 名称=="无魂傀儡" then
    回合=3
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].攻击编号=攻击编号
     elseif 名称=="捆仙绳" then
      回合=10
  elseif 名称=="七杀" then
    回合=3
    防御=qz(等级*20)
  elseif 名称=="雾杀1" or 名称=="失心" then
    回合=1
  elseif 名称=="莲心剑意"  then
    回合=999
  elseif 名称=="波澜不惊"  then
    回合=3
  elseif 名称=="魑魅缠身" then
    回合=3
  elseif 名称=="冰锥" then
    回合=1
  elseif 名称=="御风" then
    回合=3
    速度=qz(挨打方.特性几率*5)
    类型=2
  elseif 名称=="浮云神马" then
    回合=5
    速度=qz(速度1*0.1)
    类型=2
    --0914神机步
  elseif 名称=="神机步" then
    回合=3
    躲避减少=等级*20
    类型=2
      elseif 名称=="盾气" then
    防御=等级*境界
    类型=2
  elseif 名称=="龙魂" then
    回合=2
  elseif 名称=="灵刃" then
    回合=4
    防御=qz(防御1*0.2)
    法防=qz(法防1*0.2)
  elseif 名称=="灵断" then
    回合=4
  elseif 名称=="进击必杀" then
    必杀=10*等级
    回合=5
    类型=2
  elseif 名称=="进击法爆" then
    法暴=10*等级
    回合=5
    类型=2
  elseif 名称=="灵法1" then
    回合=4
    防御=qz(防御1*0.1)
  elseif 名称=="灵法" then
    回合=4
    灵力=qz(攻击方.气血*(攻击方.特性几率*5/100))
    类型=2
  elseif 名称=="怒吼" then
    回合=2
    伤害=qz(伤害1*0.2)
    类型=2
  elseif 名称=="怒吼1" then
    回合=2
    灵力=qz(灵力1*0.1)
  elseif 名称=="护佑" then
    回合=3
    灵力=qz(灵力1*0.1)
    境界=挨打方.特性几率
  elseif 名称=="后发制人" then
    回合=2
    防御=qz(等级*3.5)
    法防=qz(等级*0.4)
    类型=2
  elseif 名称=="龙骇龙腾" then
    回合=3
  elseif 名称=="龙骇龙卷" then
    回合=3
  elseif 名称=="被动龙魂" then
    回合=4
  elseif 名称=="变身" then
    回合=qz(等级/20)+4
    伤害=等级*2.5
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"宁息") then
    回合=回合+3
    end
  elseif 名称=="狂怒" then
    回合=qz(等级/20)+2
    伤害=等级*2
    类型=2
  elseif 名称=="反间之计"  then
    回合=qz(等级/20)+1
  elseif 名称=="移魂化骨"  then
    回合=qz(等级/20)+1
    攻击方.法术状态[名称].等级=等级
  elseif 名称=="催眠符" then
    --回合=qz(等级/50)+2
    回合=4
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"黄粱") then
        回合=回合+3
        攻击方.法术状态[名称].黄粱=true
    end
  elseif 名称=="失心符" then
    回合=qz(等级/20)+1
    法防=等级*2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"苦缠") then
    法防=(等级*2)+(等级*0.03)
    end
  elseif 名称=="碎甲符" then
      回合=qz(等级/20)+1
      防御=等级*4
      灵力=等级*4
      法防=等级*4
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"碎甲") then
    回合=回合+3
    end
  elseif 名称=="落魄符" then
    回合=qz(等级/20)+1
  elseif 名称=="失忆符" then
    回合=qz(等级/20)+1
   elseif 名称=="追魂符" then
    回合=qz(等级/20)+1
    防御=等级*2
   elseif 名称=="离魂符" then
    回合=qz(等级/20)+1
    速度=等级*2
  elseif 名称=="天罗地网" then
    回合=qz(等级/20)+1
    速度=速度1-速度1*0.8
  elseif 名称=="百毒不侵" or 名称=="宁心" or 名称=="驱魔" or 名称=="复苏" or 名称=="寡欲令" then
    回合=qz(等级/30)+2
  elseif 名称=="失魂符" then
    回合=qz(等级/20)+1
    防御=等级*2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"苦缠") then
    防御=(等级*2)+(等级*0.03)
    end
  elseif 名称=="定身符" then
    回合=qz(等级/20)+1
    法防=等级*2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"苦缠") then
    法防=(等级*2)+(等级*0.03)
    end
  elseif 名称=="莲步轻舞" then
    回合=qz(等级/20)+1
  elseif 名称=="如花解语" then
    回合=qz(等级/20)+1
  elseif 名称=="似玉生香" or 名称=="碎玉弄影" then
    回合=qz(等级/20)+1
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"嫣然")  then
    回合=回合+3
    end
  elseif 名称=="娉婷袅娜" then
    回合=qz(等级/20)+1
  elseif 名称=="自矜" then
    回合=999
  elseif 名称=="日月乾坤" then
    回合=qz(等级/20)+1
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"归本") then
      防御=防御1-防御1*0.6
    end
  elseif 名称=="镇妖" then
    回合=qz(等级/20)+1
    伤害=等级*3
  elseif 名称=="河东狮吼" then
    伤害=伤害1-伤害1*0.95
    回合=999
  elseif 名称=="瘴气" then
    回合=4
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"迷意") then
      回合=回合+4
    end
  elseif 名称=="摧心" then
    回合=5
    伤害=伤害1-伤害1*0.7
    灵力=灵力1-灵力1*0.7
    防御=防御1-防御1*0.7
  elseif 名称=="落花成泥" then
    回合=2
  elseif 名称=="放下屠刀" then
    伤害=伤害1-伤害1*0.8
    回合=999
  elseif 名称=="锢魂术" then
    回合=6
  elseif 名称=="凝滞术" then
    速度=速度1-速度1*0.8
    回合=999
  elseif 名称=="停陷术" then
    回合=999
    速度=速度1-速度1*0.9
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"余韵") then
    速度=速度1-速度1*0.95
    end
  elseif 名称=="破甲术" then
    防御=防御1-防御1*0.8
    回合=999
 elseif 名称=="河东狮吼" then
    回合=999
    伤害=伤害1-伤害1*0.9
   if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"余韵") then
    伤害=伤害1-伤害1*0.85
    end
  elseif 名称=="碎甲术" then
    回合=999
    防御=防御1-防御1*0.9
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"余韵") then
    防御=防御1-防御1*0.85
    end
  elseif 名称=="错乱" then
    回合=qz(等级/20)+1
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"震慑") then
    伤害=伤害1-伤害1*0.7
    end
  elseif 名称=="百万神兵" then
    回合=qz(等级/20)+1
  elseif 名称=="威慑" then
    回合=qz(等级/20)+1
  elseif 名称=="重创" then
    回合=3
  elseif 名称=="含情脉脉" then
    回合=qz(等级/20)+1
  elseif 名称=="忘忧" then
    回合=qz(等级/20)+2
  elseif 名称=="绝殇" then
    回合=5
  elseif 名称=="不灭" then
    回合=4
    防御=qz(防御*1.3)
    灵力=qz(灵力*1.3)
    防御=qz(法防*1.3)
  elseif 名称=="不灭1" then
    回合=2
  elseif 名称=="迷瘴" then
    回合=5
    防御=qz(防御*1.3)
    伤害=qz(伤害*1.3)
    灵力=qz(灵力*1.3)
    防御=qz(法防*1.3)
    法伤=qz(法伤*1.3)
    速度=qz(速度*1.3)
    类型=2
  elseif 名称=="魔音摄魂" then
    回合=4
  elseif 名称=="夺魄令" then
    回合=qz(等级/20)+1
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="夺魄令1" then
    回合=qz(等级/20)+1
  elseif 名称=="惊魂掌" then
    回合=qz(等级/20)+1
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"持戒") then
    防御=防御1+qz(等级*3)
    法防=法防1+qz(等级*3)
     end
     类型=2
  elseif 名称=="煞气诀" then
    -----摩托修改煞气诀
    -- 回合=qz(等级/20)+1
    回合=2
  elseif 名称=="煞气诀1" then
    回合=2
    -- 回合=qz(等级/20)+1
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="杀气诀" then
    回合=qz(等级/30)+3
    伤害=等级*2
    类型=2
  elseif 名称=="安神诀" then
    回合=qz(等级/30)+3
    法伤=法伤+等级*2.5
    灵力=灵力+等级*2.5
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"历战") then
    法防=法防+等级*5
    end
    类型=2
  elseif 名称=="披坚执锐" then
    回合=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"目空") then
    回合=回合+2
    end
  elseif 名称=="风魂" then
    回合=2
  elseif 名称=="牛劲" then
    回合=qz(等级/30)+3
    法伤=等级*3
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"充沛") then
    法伤=法伤+qz(法伤*0.2)
    end
    类型=2
  elseif 名称=="天神护体" then
    回合=qz(等级/30)+3
    法伤=等级*2.5
    类型=2
  elseif 名称=="烈焰真诀" then
    回合=4
    攻击方.法暴=攻击方.法暴+200
    类型=98
  elseif 名称=="真君显灵" then
    回合=4
    伤害=qz(伤害1*0.5)
    防御=防御1-防御1*1.5
    类型=2
  elseif 名称=="由己渡人" then
    回合=qz(等级/30)+3
    法防=等级*2
    防御=等级*2
    类型=2
  elseif 名称=="达摩护体" then
    攻击方.最大气血=攻击方.最大气血+攻击方.等级*3.5+攻击方.灵力*0.2
    回合=qz(等级/30)+3
    类型=99
  elseif 名称=="象形" then
    回合=1
  elseif 名称=="金刚护法" then
    回合=qz(等级/30)+3
    伤害=等级*2.5
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"佛屠") then
    伤害=伤害+伤害*0.09
    end
  elseif 名称=="金刚护体" then
    回合=qz(等级/30)+3
    防御=等级*2
    类型=2
  elseif 名称=="罗汉金钟" then
    回合=4
  elseif 名称=="顺势而为" then
    回合=4
  elseif 名称=="钟馗论道" then
    回合=5
  elseif 名称=="渡劫金身" then
    回合=2
  elseif 名称=="诸天看护" then
    回合=5
  elseif 名称=="摧心术" then
    回合=qz(等级/35)+1
    速度=速度1-速度1*1.3
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"反先") then
    灵力=灵力1-灵力1*1.3
    伤害=伤害1-伤害1*1.3
    法伤=灵力1-灵力1*1.3
    end
    类型=2
    elseif 名称=="金身舍利" then
    回合=qz(等级/30)+3
    法防=qz(等级*4)
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"精进") then
    回合=qz(等级/30)+1
    法防=qz(等级*8)
    end
    类型=2
  elseif 名称=="圣灵之甲" then
    回合=999
    防御=防御1*0.1
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"余韵") then
    防御=防御1*0.15
    end
  elseif 名称=="魔兽之印" then
    回合=999
    伤害=伤害1*0.1
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"余韵") then
    伤害=伤害1*0.15
    end
  elseif 名称=="光辉之甲" then
    回合=999
    防御=防御1*0.2
    类型=2
  elseif 名称=="法术防御" then
    回合=5
  elseif 名称=="太极护法" then
    回合=7
  elseif 名称=="死亡召唤" then
    回合=5
  elseif 名称=="野兽之力" then
    回合=999
    伤害=伤害1*0.2
    类型=2
  elseif 名称=="流云诀" then
    回合=999
    速度=速度1*0.2
    类型=2
  elseif 名称=="啸风诀" then
    回合=999
    速度=速度1*0.15
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"余韵") then
    速度=速度1*0.15
    end
  elseif 名称=="明光宝烛" then
    回合=qz(等级/30)+3
    防御=等级*2
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"精进") then
    回合=qz(等级/30)+1
    防御=qz(等级*8)
    类型=2
    end
  elseif 名称=="韦陀护法" then
    回合=qz(等级/30)+3
    法伤=等级*1.5
    类型=2
  elseif 名称=="翩鸿一击" then
    回合=2
    速度=qz(攻击方.速度*1.15)
    类型=2
  elseif 名称=="一苇渡江" then
    回合=qz(等级/30)+3
    速度=等级*2.5
    类型=2
  elseif 名称=="佛法无边" then
    回合=qz(等级/30)+3
    if 攻击方.法连==nil then
      攻击方.法连=0
    end
    攻击方.法连=攻击方.法连+50
    类型=97
   elseif 名称=="楚楚可怜" then
    回合=qz(等级/30)+3
  elseif 名称=="天神护法" then
    回合=qz(等级/30)+3
    防御=等级*2
    类型=2
  elseif 名称=="乘风破浪" then
    回合=qz(等级/30)+3
    速度=等级*2
    类型=2
  elseif 名称=="逆鳞" then
    回合=qz(等级/30)+3
    伤害=等级*2
    类型=2
  elseif 名称=="神龙摆尾" then
    回合=qz(等级/30)+3
  elseif 名称=="汲魂" then
    回合=2
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="生命之泉" then
    回合=qz(等级/30)+3
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="毒" then
    回合=5
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="炼气化神" then
    回合=qz(等级/30)+3
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="魔息术" then
    回合=qz(等级/30)+1
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="普渡众生" then
    回合=qz(等级/30)+3
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"雨润") then
    回合=回合+3
    end
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="天地同寿"  then
    回合=qz(等级/30)+1
    防御=qz(防御1*0.5)
  elseif 名称=="乾坤妙法" then
    回合=qz(等级/30)+1
  elseif 名称=="灵动九天" then
    回合=qz(等级/30)+3
    法伤=等级*4
    灵力=等级*4
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"灵动") then
    法伤=等级*5
    灵力=等级*5
    end
    类型=2
  elseif 名称=="颠倒五行" then
    回合=qz(等级/50)+1
  elseif 名称=="幽冥鬼眼" then
    回合=qz(等级/30)+3
  elseif 名称=="修罗隐身" then
    回合=qz(等级/30)+3
  elseif 名称=="火甲术" then
    回合=qz(等级/30)+1
  elseif 名称=="腾雷"  then
    回合=3
  elseif 名称=="凝神术"  then
    回合=10
  elseif 名称=="分身术"  then
    回合=3
  elseif 名称=="魔王回首" then
    回合=qz(等级/30)+3
  elseif 名称=="定心术" then
    回合=qz(等级/30)+3
    法伤=等级*2
    灵力=等级*2
    类型=2
  elseif 名称=="干将莫邪" then
    回合=4
    伤害=qz(境界*20)
    类型=2
  elseif 名称=="乾坤玄火塔" then
    回合=5
    local 愤怒=qz(150*(qz(境界/5)*0.02+0.02))
    if self.参战单位[攻击编号].愤怒~=nil then self.参战单位[攻击编号].愤怒=self.参战单位[攻击编号].愤怒+愤怒 end
    if self.参战单位[攻击编号].愤怒>150 then self.参战单位[攻击编号].愤怒=150 end
  elseif 名称=="混元伞" or 名称=="苍白纸人" then
    回合=3
  elseif 名称=="无尘扇" then
    回合=3
  elseif 名称=="修罗咒" or 名称=="天衣无缝" then
    回合=3
  elseif 名称=="无魂傀儡" then
    回合=2
  elseif 名称=="五彩娃娃" then
    回合=2
  elseif 名称=="极度疯狂" then
    回合=qz(等级/30)+1
   elseif 名称=="尸腐毒" then
    回合=qz(等级/20)+3
    攻击方.法术状态[名称].等级=等级
    elseif 名称=="紧箍咒" then
    回合=qz(等级/20)+3
    攻击方.法术状态[名称].等级=等级
    elseif 名称=="利刃" then
    回合=999
    攻击方.法术状态[名称].等级=等级
    elseif 名称=="摇头摆尾" then
    回合=qz(等级/20)+3
    攻击方.法术状态[名称].等级=等级
    elseif 名称=="冰川怒" then
    回合=qz(等级/20)+1
    攻击方.法术状态[名称].等级=等级
    elseif 名称=="冰川怒伤" then
    回合=qz(等级/20)+1
    攻击方.法术状态[名称].等级=等级
  elseif 名称=="雾杀" then
    回合=qz(等级/20)+3
    攻击方.法术状态[名称].等级=等级
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"寄生") then
    回合=回合+999
    end
  elseif 名称=="天魔解体" then
    回合=qz(等级/30)+2
   -- 类型=2
    攻击方.法术状态[名称].附加伤害=qz(伤害*0.15)
    攻击方.伤害=攻击方.伤害+攻击方.法术状态[名称].附加伤害
  elseif 名称=="盘丝阵" then
    回合=qz(等级/30)+3
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"结阵")  then
    防御=等级*4
    else
    防御=等级*2.5
    end
    类型=2
  elseif 名称=="金刚镯" then
    回合=qz(等级/25)+3
    伤害=等级*2.5
    类型=2
  elseif 名称=="幻镜术" then
    回合=qz(等级/30)+1
  elseif 名称=="不动如山" then
    回合=qz(等级/25)+3
    防御=等级*2
    法防=等级*1.5
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"不动")  then
    灵力=等级*10
    法伤=等级*10
    end
    类型=2
  elseif 名称=="四面埋伏" then
    回合=4
  elseif 名称=="碎星诀"  then
    回合=qz(等级/25)+3
    伤害=等级*2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"神诀") then
    法伤=等级*2
    灵力=等级*2
    end
    类型=2
  elseif 名称=="镇魂诀"  then
    回合=qz(等级/25)+3
    攻击方.法术状态[名称].必杀=qz(等级/10)*2+1
    攻击方.必杀=攻击方.必杀+攻击方.法术状态[名称].必杀
    伤害=等级*1.5
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"神诀") then
    法伤=等级*2
    灵力=等级*2
    end
    类型=2
  elseif 名称=="炎护"  then
    回合=qz(等级/50)+3
  elseif 名称=="蜜润"  then
    回合=qz(等级/25)+3
    灵力=等级*2.5
    法伤=等级*2.5
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"滋养") then
    灵力=等级*3.5
    法伤=等级*3.5
    end
    类型=2
  elseif 名称=="风灵"  then
    回合=999
    if 等级 >= 10 then
      等级=10
    end
    攻击方.法术状态[名称].风灵层数=等级
    法伤=等级*(攻击方.等级+10)*0.3
    类型=2
  elseif 名称=="雾痕" then
    回合=5
    if 等级 >= 6 then
      等级=6
    end
    攻击方.法术状态[名称].层数=等级
    法伤=等级*(攻击方.等级+10)*0.1
    类型=2
  elseif 名称=="爪印" then
    回合=5
    if 等级 >= 7 then
      等级=7
    end
    攻击方.法术状态[名称].层数=等级
  elseif 名称=="侵掠如火" then
    回合=6
    伤害=伤害1*0.3
    类型=2
  elseif 名称=="不动如山 " then
    回合=6
    防御=防御1*0.3
    类型=2
  elseif 名称=="其疾如风" then
    回合=6
    速度=速度1*0.3
    类型=2
  elseif 名称=="红袖添香" then
    回合=qz(等级/30)+3
    速度=等级*2
    类型=2
  elseif 名称=="谜毒之缚" then
    回合=qz(等级/40)+1
    攻击方.法术状态[名称].等级=等级
  elseif 名称=="诡蝠之刑" then
    回合=qz(等级/40)+1
    攻击方.法术状态[名称].等级=等级
    攻击方.法术状态[名称].编号=攻击编号
  elseif 名称=="唤灵·魂火" then
    local 次数=qz(self:取技能等级(攻击编号,"唤灵·魂火")/125)+2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"异兆") and 取随机数()>=50 then
      次数=次数+1
    end
    self:执行怪物召唤(攻击编号,2,攻击方.队伍,次数)
    回合=0
  elseif 名称=="唤魔·堕羽" then
    self:执行怪物召唤(攻击编号,3,攻击方.队伍,1)
    回合=0
  elseif 名称=="唤魔·毒魅" then
    self:执行怪物召唤(攻击编号,3,攻击方.队伍,1)
    回合=0
  elseif 名称=="无敌牛虱" then
    self:执行怪物召唤(攻击编号,6,攻击方.队伍,1)
    回合=0
  elseif 名称=="无敌牛妖" then
    self:执行怪物召唤(攻击编号,7,攻击方.队伍,1)
    回合=0
  elseif 名称=="唤灵·焚魂" then
    self:执行怪物召唤(攻击编号,2,攻击方.队伍,6)
    回合=0
  elseif 名称=="锋芒毕露" then
    回合=qz(等级/40)+1
    攻击方.法术状态[名称].目标id=攻击编号
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"断矶") then
      攻击方.伤害=qz(攻击方.伤害*0.8)
      攻击方.灵力=qz(攻击方.灵力*0.8)
    end
  elseif 名称=="诱袭" then
    攻击方.法术状态[名称].目标id=攻击编号
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"巧偃") then
      攻击方.防御=qz(攻击方.防御*0.9)
      攻击方.灵力=qz(攻击方.灵力*0.9)
    end
  elseif 名称=="匠心·削铁" then
    回合=1
    伤害=等级*2
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"催锋") then
      伤害=伤害+等级
    end
  elseif 名称=="匠心·固甲" then
    回合=1
    防御=等级
    类型=2
    if 攻击编号~=nil and self:取奇经八脉是否有(攻击编号,"催锋") then
      伤害=伤害+等级
    end
  elseif 名称=="碎甲刃" then
    local 力量=挨打方.力量 or 挨打方.等级*2.5
    类型=1
    防御=(5+(力量-挨打方.等级)*0.15)*(1+0.2*等级)
    回合=2
  elseif 名称=="威震凌霄" then
    攻击方.物理暴击等级=攻击方.物理暴击等级-150
    攻击方.法术暴击等级=攻击方.法术暴击等级-150
    if 攻击方.物理暴击等级<=0 then
      攻击方.物理暴击等级=0
    end
    if 攻击方.法术暴击等级<=0 then
      攻击方.法术暴击等级=0
    end
    回合=3
    elseif 名称=="杀威铁棒" then
    攻击方.伤害=qz(攻击方.伤害*0.8)
    攻击方.法伤=qz(攻击方.法伤*0.8)
    回合=3
    elseif 名称=="针锋相对" then
    攻击方.伤害=qz(攻击方.伤害*0.9)
    攻击方.法伤=qz(攻击方.法伤*0.9)
    回合=2
  elseif 名称=="气慑天军" then
    if 攻击方.抗物理暴击等级==nil then
      攻击方.抗物理暴击等级=0
    end
    if 攻击方.抗法术暴击等级==nil then
      攻击方.抗法术暴击等级=0
    end
    攻击方.抗物理暴击等级=攻击方.抗物理暴击等级+100
    攻击方.抗法术暴击等级=攻击方.抗法术暴击等级+100
  elseif 名称=="铜头铁臂" then
    回合=qz(等级/30)+1
    伤害=等级*1.5
    类型=2
  elseif 名称=="无所遁形" then
    回合=qz(等级/30)+1
    攻击方.必杀=qz(攻击方.必杀*1.2)
    挨打方.防御=qz(挨打方.防御*0.8)
    类型=2
  elseif 名称=="呼子唤孙" then
    self:执行怪物召唤(攻击编号,4,攻击方.队伍,1)
    if 攻击方.呼子唤孙==nil then
      攻击方.呼子唤孙=0
    end
    攻击方.呼子唤孙=攻击方.呼子唤孙+1
    回合=0
  end
  攻击方.法术状态[名称].伤害=伤害
  攻击方.法术状态[名称].防御=防御
  攻击方.法术状态[名称].速度=速度
  攻击方.法术状态[名称].法防=法防
  攻击方.法术状态[名称].躲闪=躲闪
  攻击方.法术状态[名称].回合=回合
  攻击方.法术状态[名称].命中=命中
  攻击方.法术状态[名称].类型=类型
  攻击方.法术状态[名称].灵力=灵力
  攻击方.法术状态[名称].法伤=法伤
  攻击方.法术状态[名称].护盾值=护盾值
  攻击方.法术状态[名称].躲避减少=躲避减少
  攻击方.法术状态[名称].必杀=必杀
  攻击方.法术状态[名称].法暴=法暴
  if 类型==1 then
    攻击方.伤害=攻击方.伤害-伤害
    攻击方.防御=攻击方.防御-防御
    攻击方.速度=攻击方.速度-速度
    攻击方.法防=攻击方.法防-法防
    攻击方.躲闪=攻击方.躲闪-躲闪
    攻击方.命中=攻击方.命中-命中
    攻击方.灵力=攻击方.灵力-灵力
    攻击方.必杀=攻击方.必杀-必杀
    if 攻击方.法伤~=nil then
      攻击方.法伤=攻击方.法伤-法伤
    end
    if 攻击方.法暴~=nil then
      攻击方.法暴=攻击方.法暴-法暴
    end
  else
    攻击方.伤害=攻击方.伤害+伤害
    攻击方.防御=攻击方.防御+防御
    攻击方.速度=攻击方.速度+速度
    攻击方.法防=攻击方.法防+法防
    攻击方.躲闪=攻击方.躲闪+躲闪
    攻击方.命中=攻击方.命中+命中
    攻击方.灵力=攻击方.灵力+灵力
    攻击方.必杀=攻击方.必杀+必杀
    if 攻击方.法暴~=nil then
      攻击方.法暴=攻击方.法暴+法暴
    end
    if 攻击方.法伤~=nil then
      攻击方.法伤=攻击方.法伤+法伤
    end
    攻击方.躲避减少=攻击方.躲避减少+躲避减少
  end
end

function 战斗处理类:取消状态(名称,攻击方,等级)
  if 攻击方.法术状态[名称]==nil then
     return
  end
  if 名称=="雾杀" then
    if 攻击方.法术状态[名称].咒术~=nil and 攻击方.法术状态[名称].等级~=nil then
      local 施法者=攻击方.法术状态[名称].咒术
      local 雾痕层数 = 1
      if self.参战单位[施法者].法术状态.雾痕~=nil then
        if self.参战单位[施法者].法术状态.雾痕.层数~=nil then
          雾痕层数=self.参战单位[施法者].法术状态.雾痕.层数+1
        end
      end
      self:取消状态("雾痕",self.参战单位[施法者])
      self:添加状态("雾痕",self.参战单位[施法者],self.参战单位[施法者],雾痕层数,施法者)
    end
  end
--0914神机步
  if 攻击方.法术状态[名称].类型==2 then
     攻击方.躲避减少=攻击方.躲避减少-攻击方.法术状态[名称].躲避减少
      攻击方.伤害=攻击方.伤害-攻击方.法术状态[名称].伤害
      攻击方.防御=攻击方.防御-攻击方.法术状态[名称].防御
      攻击方.速度=攻击方.速度-攻击方.法术状态[名称].速度
      攻击方.法防=攻击方.法防-攻击方.法术状态[名称].法防
      攻击方.躲闪=攻击方.躲闪-攻击方.法术状态[名称].躲闪
      攻击方.命中=攻击方.命中-攻击方.法术状态[名称].命中
      攻击方.灵力=攻击方.灵力-攻击方.法术状态[名称].灵力
      if 攻击方.法伤~=nil then
       攻击方.法伤=攻击方.法伤-攻击方.法术状态[名称].法伤
      end
    else
      攻击方.伤害=攻击方.伤害+攻击方.法术状态[名称].伤害
      攻击方.防御=攻击方.防御+攻击方.法术状态[名称].防御
      攻击方.速度=攻击方.速度+攻击方.法术状态[名称].速度
      攻击方.法防=攻击方.法防+攻击方.法术状态[名称].法防
      攻击方.躲闪=攻击方.躲闪+攻击方.法术状态[名称].躲闪
      攻击方.命中=攻击方.命中+攻击方.法术状态[名称].命中
      攻击方.灵力=攻击方.灵力+攻击方.法术状态[名称].灵力
       if 攻击方.法伤~=nil then
       攻击方.法伤=攻击方.法伤+攻击方.法术状态[名称].法伤
      end
      end

      if 攻击方.法术状态[名称].类型==99 then
      攻击方.最大气血=攻击方.最大气血-攻击方.等级*2.5-攻击方.灵力*0.2
      攻击方.气血=攻击方.气血
      else
      -- 攻击方.最大气血=攻击方.最大气血+qz(攻击方.等级*2)
      -- 攻击方.气血=攻击方.气血
      end

      if 攻击方.法术状态[名称].类型==98 then
      攻击方.法暴=攻击方.法暴-200
      -- else
      -- 攻击方.法暴=攻击方.法暴-攻击方.法暴+10
      end

            if 攻击方.法术状态[名称].类型==97 then
      攻击方.法连=攻击方.法连-50
      -- else
      -- 攻击方.法暴=攻击方.法暴-攻击方.法暴+10
      end

      if 攻击方.气血>=攻击方.最大气血 then
        攻击方.气血=攻击方.最大气血
      else
   end
  if 攻击方.法术状态[名称].附加伤害~=nil then
     攻击方.伤害=攻击方.伤害-攻击方.法术状态[名称].附加伤害
  elseif 攻击方.法术状态[名称].必杀~=nil then
     攻击方.必杀=攻击方.必杀-攻击方.法术状态[名称].必杀
  elseif 攻击方.法术状态[名称].法暴~=nil then
      攻击方.法暴=攻击方.法暴-攻击方.法术状态[名称].法暴
  elseif 攻击方.法术状态[名称].法连~=nil then
      攻击方.法连=攻击方.法连-攻击方.法术状态[名称].法连
  end
 攻击方.法术状态[名称]=nil
end

function 战斗处理类:物攻技能计算1(编号,目标,起始伤害,叠加伤害,返回,允许保护,次数,技能名称)
 self.战斗流程[#self.战斗流程+1]={流程=1,攻击方=编号,挨打方={[1]={挨打方=目标,特效={}}}}
 if 装备特技[技能名称]~=nil then
      self.战斗流程[#self.战斗流程].特技名称=技能名称
   end
 if 返回 then
    self.执行等待=self.执行等待+10
  else
    self.执行等待=self.执行等待+5
   end
  local  保护=false
  local  保护编号=0
  for n=1,#self.参战单位 do
    if 技能名称~="长驱直入" and 保护编号==0 and self:取行动状态(n) and self.参战单位[目标].法术状态.惊魂掌==nil and self.参战单位[n].指令.类型=="保护" and  self.参战单位[n].队伍==self.参战单位[目标].队伍 and  self.参战单位[n].指令.目标==目标 then
      保护编号=n
      保护=true
      self.参战单位[n].指令.类型=""
      self.执行等待=self.执行等待+5
    end
  end
  local  必杀=false
  local  躲避=false
  local  防御=false
  local  反震=false
  local  反击=false
  local  伤害=self:取基础物理伤害(编号,目标)*(起始伤害+叠加伤害*次数)

--  0914 力劈伤害差机制完善
  if 技能名称=="力劈华山" then
    local 力劈系数=1.5
    local 伤害差=self.参战单位[编号].伤害 - self.参战单位[目标].伤害
    if 伤害差 < 0 then
      伤害差 = 0
      力劈系数=0.5
    end
    伤害=qz((伤害+伤害差)*力劈系数)
  end

  local  最终伤害=self:取最终物理伤害(编号,目标,伤害)
  if (技能名称 == "高级连击" or 技能名称 == "理直气壮") and 最终伤害.暴击~=nil and self.参战单位[编号].怒击效果 then
    self.参战单位[编号].怒击触发 = 1
  elseif (技能名称 == "高级连击" or 技能名称 == "理直气壮") and not 最终伤害.暴击~=nil and self.参战单位[编号].怒击触发 ~= nil then
    self.参战单位[编号].怒击触发 = nil
  end
  local 伤害值=self:取伤害结果(编号,目标,最终伤害.伤害,最终伤害.暴击,保护)
  --0914  保护伤害
 if 保护 then
     local 保护伤害=math.floor(伤害值.伤害*0.7)
     if 保护伤害<1 then 保护伤害=1 end
     local 保护死亡=self:减少气血(保护编号,保护伤害)
      伤害值.伤害=math.floor(伤害值.伤害*0.3)
     if 保护伤害<1 then 保护伤害=1 end
      self.战斗流程[#self.战斗流程].保护数据={编号=保护编号,伤害=保护伤害,死亡=保护死亡}
      end

  if self.参战单位[编号].法术状态.谜毒之缚~=nil then
    伤害值.伤害=qz(伤害值.伤害*0.65*0.8)
  end
  if 伤害值.伤害<1 and 暴击==true then
    伤害值.伤害=取随机数(self.参战单位[编号].伤害*0.15,self.参战单位[编号].伤害*0.25)
    elseif 伤害值.伤害<1 then
    伤害值.伤害=取随机数(self.参战单位[编号].伤害*0.1,self.参战单位[编号].伤害*0.15)
  end
  if 技能名称=="善恶有报"  then
    if 取随机数(1,100)<=30 then
      伤害值.伤害=qz(伤害值.伤害*0.5)
      伤害值.类型=2
    elseif 伤害值.类型~=2 then
      伤害值.伤害=qz(伤害值.伤害*1.8)
    end
  end

  if 技能名称=="翩鸿一击"  then
  if 编号~=nil and self:取奇经八脉是否有(编号,"翩鸿一击") then
     伤害值.伤害=qz(伤害值.伤害*1.35)
  end
    local 可取消状态=self:取对方可偷取增益技能(目标)
    self:取消状态(可取消状态,self.参战单位[目标])
    self.战斗流程[#self.战斗流程].挨打方[1].取消状态=可取消状态
  end

  if 技能名称=="长驱直入" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"长驱直入") and 取随机数(1,100)<=30 then
     伤害值.伤害=qz(伤害值.伤害*2)
    end
  end

if 技能名称=="天崩地裂" then
      if 编号~=nil and self:取奇经八脉是否有(编号,"力战") then
     伤害值.伤害=伤害值.伤害+self.参战单位[编号].等级*2
     end
   end

  if 技能名称=="天雷斩" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"趁虚") then
     伤害值.伤害=qz(伤害值.伤害*1.15)
    end
  end

  if 技能名称=="天雷斩" then
    if 编号~=nil and self:取奇经八脉是否有(编号,"月桂") then
      if self.参战单位[编号].武器伤害==nil then
        self.参战单位[编号].武器伤害=1
      end
      伤害值.伤害=伤害值.伤害+self.参战单位[编号].武器伤害*0.5
    end
  end

if 技能名称=="飘渺式" or 技能名称=="烟雨剑法" or 技能名称=="天命剑法"then
  if 编号~=nil and self:取奇经八脉是否有(编号,"混元") then
      伤害值.伤害=伤害值.伤害+self.参战单位[编号].防御*0.5
    end
  end

  if 技能名称=="鹰击" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"化血") then
     伤害值.伤害=qz(伤害值.伤害*1.15)
    end
  end

if 技能名称=="连环击" then
      if 编号~=nil and self:取奇经八脉是否有(编号,"乱破") then
    伤害值.伤害=伤害值.伤害+qz(self.参战单位[编号].等级*5)
    end
  end

if 技能名称=="狮搏" then
    if 编号~=nil and self:取奇经八脉是否有(编号,"狮吼") then
  伤害值.伤害=qz(伤害值.伤害*1.15)
  end
end

  if 技能名称=="鹰击" or 技能名称=="狮搏" or 技能名称=="连环击" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"兽王") and self.参战单位[编号].法术状态.变身~=nil then
    伤害值.伤害=伤害值.伤害+self.参战单位[目标].防御*0.1
  end
end

if 技能名称=="鹰击" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"死地") and 取随机数(1,100)<=5 then
  伤害值.伤害=qz(伤害值.伤害*2)
  end
end

    if 技能名称=="横扫千军" then
      if 编号~=nil and self:取奇经八脉是否有(编号,"勇念") then
      伤害值.伤害=伤害值.伤害+qz(self.参战单位[目标].防御*0.2)
    end
  end

if 技能名称=="破釜沉舟" then
      if 编号~=nil and self:取奇经八脉是否有(编号,"破空") then
    伤害值.伤害=伤害值.伤害+qz(self.参战单位[目标].防御*0.3)
    end
  end

  if 技能名称=="破碎无双" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"驭意") then
     伤害值.伤害=qz(伤害值.伤害*1.8)
    end
  end

  if 技能名称=="天命剑法" or 技能名称=="飘渺式" or 技能名称=="烟雨剑法" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"强击") then
      伤害值.伤害=伤害值.伤害+((self.参战单位[目标].防御*0.15+self.参战单位[目标].灵力*0.15))
  end
end

  if 技能名称=="翻江搅海" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"抗击") then
     伤害值.伤害=qz(伤害值.伤害*1.12)
    end
  end

 if 技能名称=="浪涌"  then
  if 编号~=nil and self:取奇经八脉是否有(编号,"战诀") then
     伤害值.伤害=qz(伤害值.伤害*1.1)
    end
  end
  self.战斗流程[#self.战斗流程].挨打方[1].动作=最终伤害.动作
  self.战斗流程[#self.战斗流程].挨打方[1].特效=最终伤害.特效
  self.战斗流程[#self.战斗流程].伤害=最终伤害.攻击伤害
  if #最终伤害.特效==0 then
    --self.战斗流程[#self.战斗流程].挨打方[1].特效={"被击中"}
  end
  if 技能名称=="后发制人" then
    self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="横扫千军"
    else
    self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]=技能名称
  end
  local 吸血=self.参战单位[编号].吸血
  if 吸血==nil and self.参战单位[编号].法术状态.移魂化骨~=nil then
     吸血=self.参战单位[编号].法术状态.移魂化骨.等级/250
  if 编号~=nil and self:取奇经八脉是否有(编号,"暗潮") then
     吸血=吸血+吸血*0.3
     end
  end
  if 吸血~=nil and self.参战单位[目标].鬼魂==nil  then
    local 吸血伤害=math.floor(伤害值.伤害*吸血)
    if 吸血伤害<=0 then
      吸血伤害=1
    end

    self:增加气血(编号,吸血伤害)
    self.战斗流程[#self.战斗流程].吸血伤害=吸血伤害
  end

  if self.参战单位[编号].碎甲刃~=nil and self.参战单位[编号].碎甲刃>0 and 取随机数()<=30 then
   self:添加状态("碎甲刃",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].碎甲刃,编号)
   self.战斗流程[#self.战斗流程].挨打方[1].添加状态="碎甲刃"
  end

  if 技能名称=="横扫千军" then
  if 编号~=nil and self:取奇经八脉是否有(编号,"风刃") and 取随机数(1,100)<=100 then
      self:添加状态("风魂",self.参战单位[编号],nil,nil,编号)
      self.参战单位[编号].法术状态.风魂.回合=3
      end
    end

  if self.参战单位[编号].气血>0 and self.参战单位[目标].法术状态.混元伞~=nil then
    local 反弹伤害=qz(伤害值.伤害*(self.参战单位[目标].法术状态.混元伞.境界*0.03+0.1))
    if self.战斗流程[#self.战斗流程].反震伤害==nil then
      self.战斗流程[#self.战斗流程].反震伤害=反弹伤害
    else
      self.战斗流程[#self.战斗流程].反震伤害=self.战斗流程[#self.战斗流程].反震伤害+反弹伤害
    end
      self.战斗流程[#self.战斗流程].反震死亡=self:减少气血(编号,反弹伤害,目标)
      self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="混元伞"
  end

    if self.参战单位[编号].气血>0 and self.参战单位[目标].法术状态.修罗咒~=nil then
      local 反弹伤害=qz(伤害值.伤害*0.5)
      if self.战斗流程[#self.战斗流程].反震伤害==nil then
        self.战斗流程[#self.战斗流程].反震伤害=反弹伤害
      else
        self.战斗流程[#self.战斗流程].反震伤害=self.战斗流程[#self.战斗流程].反震伤害+反弹伤害
      end
        self.战斗流程[#self.战斗流程].反震死亡=self:减少气血(编号,反弹伤害,目标)
        self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="修罗咒"
    end
    self.战斗流程[#self.战斗流程].挨打方[1].护盾掉血值=nil
    if  伤害值.类型==1 or 伤害值.类型==3 or 伤害值.类型==4 then
      if self.参战单位[目标].法术状态.护盾~=nil and self.参战单位[目标].法术状态.护盾.护盾值~=nil then
        if 伤害值.伤害<self.参战单位[目标].法术状态.护盾.护盾值 then
          self.参战单位[目标].法术状态.护盾.护盾值=self.参战单位[目标].法术状态.护盾.护盾值-伤害值.伤害
          self.战斗流程[#self.战斗流程].挨打方[1].护盾掉血值=伤害值.伤害
          伤害值.伤害=0
        else
          self.战斗流程[#self.战斗流程].挨打方[1].护盾掉血值=self.参战单位[目标].法术状态.护盾.护盾值
          伤害值.伤害=伤害值.伤害-self.参战单位[目标].法术状态.护盾.护盾值
          self:取消状态("护盾",self.参战单位[目标])
          self.战斗流程[#self.战斗流程].挨打方[1].取消状态="护盾"
        end
      elseif self.参战单位[目标].凝光炼彩~=nil and 取随机数()<=25 then
        self:添加状态("护盾",self.参战单位[目标],self.参战单位[目标],math.floor(伤害值.伤害/2),目标)
        self.战斗流程[#self.战斗流程].挨打方[1].添加状态="护盾"
        self.参战单位[目标].法术状态.护盾.回合=3
      end
    end

    if 伤害值.类型==2 then --恢复状态
     self:增加气血(目标,伤害值.伤害)
    else
      self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,伤害值.伤害,编号)
       if self.参战单位[目标].法术状态.催眠符 then
         self:取消状态("催眠符",self.参战单位[目标])
         self.战斗流程[#self.战斗流程].挨打方[1].取消状态="催眠符"
         end
      if 技能名称=="惊心一剑" then
          self.参战单位[目标].魔法=self.参战单位[目标].魔法-qz(伤害值.伤害*0.2)
          if self.参战单位[目标].魔法<=0 then
             self.参战单位[目标].魔法=0
             end
       elseif 技能名称=="破碎无双" then
          self.参战单位[目标].魔法=self.参战单位[目标].魔法-qz(伤害值.伤害)
          if self.参战单位[目标].魔法<=0 then
             self.参战单位[目标].魔法=0
             end
         end
     end

  self.战斗流程[#self.战斗流程].挨打方[1].伤害=伤害值.伤害
  self.战斗流程[#self.战斗流程].挨打方[1].伤害类型=伤害值.类型
  self.战斗流程[#self.战斗流程].返回=返回

  if self.参战单位[目标].法术状态.移魂化骨~=nil and 目标~=nil and self:取奇经八脉是否有(目标,"噬魂") and 取随机数()<=50 then
  local 血量=math.floor(伤害值.伤害*0.5)
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="地涌金莲"
  end

if 目标~=nil and self:取奇经八脉是否有(目标,"不舍") and 伤害值.伤害>qz(self.参战单位[目标].最大气血*0.2) and self.参战单位[目标].气血>=1 then
  local 血量=qz(self.参战单位[目标].等级+10)*2
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="归元咒"
  end

  if 目标~=nil and self:取奇经八脉是否有(目标,"养生") and self.参战单位[目标].气血<=qz(self.参战单位[目标].最大气血*0.5) and self.参战单位[目标].法术状态.生命之泉==nil then
  self:添加状态("生命之泉",self.参战单位[目标],self.参战单位[目标],self.参战单位[目标].等级,目标)
  self.战斗流程[#self.战斗流程].挨打方[1].添加状态="生命之泉"
  end

  if self.参战单位[目标].法术状态.波澜不惊~=nil and 伤害>1 and self.参战单位[目标].气血>0 then
  local 血量=qz(伤害*1)
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="波澜不惊"
  end

  local 反震=self.参战单位[目标].反震
  local 反击=self:取是否反击(编号,目标)
  --local 反击=1
  --local 反震=0.25
  if self.参战单位[编号].偷袭==nil and 反震~=nil and 取随机数()<=30 and 保护==false then --触发反震 有保护的情况下不会触发反震、反击
    local 反震伤害=math.floor(伤害值.伤害*反震)
    if 反震伤害<=0 then
      反震伤害=1
    end
    if self.参战单位[目标].反震1 ==nil then
      self.参战单位[目标].反震1=0
    end
    local 反震伤害1=self.参战单位[目标].反震1
    self.战斗流程[#self.战斗流程].反震伤害=反震伤害 + 反震伤害1
    -- self.战斗流程[#self.战斗流程].反震伤害=反震伤害 + self.参战单位[编号].反震1
    self.战斗流程[#self.战斗流程].反震死亡=self:减少气血(编号,反震伤害,目标)
    self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="反震"
    self.执行等待=self.执行等待+3
  elseif 反击~=nil and 反击~=false and self:取行动状态(目标) and self.参战单位[编号].偷袭==nil and  保护==false then
    local 反击伤害=math.floor(self:取基础物理伤害(目标,编号)*反击)
    if 反击伤害<=0 then 反击伤害=1 end
    self.战斗流程[#self.战斗流程].反击伤害=反击伤害
    self.战斗流程[#self.战斗流程].反击死亡=self:减少气血(编号,反击伤害,目标)
  end

  if self.参战单位[编号].法术状态.诡蝠之刑~=nil then
    if self:取目标状态(编号,编号,2) then
      local 气血=qz(伤害值.伤害*0.1)
      if 气血<=1 then
        气血=1
      end
      self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=编号,气血=0,挨打方={}}
      self.战斗流程[#self.战斗流程].死亡=self:减少气血(编号,气血)
      self.战斗流程[#self.战斗流程].气血=气血
    end
  end
end

function 战斗处理类:魔法消耗(攻击方,数值,数量)
 local 临时消耗=math.floor(数值*数量)
  if 攻击方.慧根~=nil then
      临时消耗=qz(临时消耗*攻击方.慧根)
     end
  if self:取符石组合效果(攻击方,"飞檐走壁") then
      临时消耗=qz(临时消耗*(1-self:取符石组合效果(攻击方,"飞檐走壁")/100))
  end
  if 攻击方.魔法<临时消耗 then
    return false
   else
    攻击方.魔法=攻击方.魔法-临时消耗
    return true
    end
end


function 战斗处理类:愤怒消耗(数值,攻击方,编号,名称)
  -- print(数值,攻击方,编号,名称)
  local 消耗=数值
  if 攻击方.愤怒腰带~=nil then
    消耗=qz(消耗*0.8)
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"慈心") and 名称=="慈航普渡" then
    消耗=消耗-40
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"傲娇") then
    消耗=消耗-10
    if 名称=="笑里藏刀" or 名称=="绝幻魔音" then
        消耗=消耗-15
    end
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"花护") then
      if 名称=="水清诀" or 名称=="冰清诀" or 名称=="晶清诀" or 名称=="玉清诀" then
          消耗=消耗-20
     end
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"显圣") then
    if 名称=="晶清诀" or 名称=="罗汉金钟" then
        消耗=消耗-8
    end
  end
  if 攻击方.愤怒 == nil then
    攻击方.愤怒 =9999999999
  end
  if 攻击方.愤怒<消耗 then
    return false
  else
    攻击方.愤怒=攻击方.愤怒-消耗
    return true
  end
    if  攻击方.愤怒<=0 then 攻击方.愤怒=0 end
   if  攻击方.愤怒>=150 then 攻击方.愤怒=150 end
end

function 战斗处理类:技能消耗(攻击方,数量,名称,编号)
  if 装备特技[名称]~=nil then
    return self:愤怒消耗(装备特技[名称].消耗,攻击方,编号,名称)
  end
  if 数量==nil then 数量=1 end
  self.技能名称=名称
  if self.技能名称=="自爆" then
    return true
  end
     if self.技能名称=="盾气" then
    return true
  end

    if self.技能名称=="无敌牛妖" then
    local 牛妖存在=0
    for n=1,#self.参战单位 do
    if self.参战单位[n].模型=="牛幺" and self.参战单位[n].名称=="牛幺" then
    牛妖存在=牛妖存在+2
    end
    end
    if  牛妖存在<=1 or self:取玩家战斗() then
    return self:魔法消耗(攻击方,150,1)
    else
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/只能存在一个相同的#G/宠物")
    return false
    end

    elseif self.技能名称=="无敌牛虱" then
    local 牛虱存在=0
    for n=1,#self.参战单位 do
    if self.参战单位[n].模型=="牛虱" and self.参战单位[n].名称=="牛虱" then
    牛虱存在=牛虱存在+2
    end
    end
    if  牛虱存在<=1 or self:取玩家战斗() then
    return self:魔法消耗(攻击方,150,1)
      else
    self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/只能存在一个相同的#G/宠物")
    return false
    end
  end

    if self.技能名称=="横扫千军" and 攻击方.气血>=攻击方.最大气血*0.5 then
    return true
    elseif self.技能名称=="横扫千军" and 攻击方.类型=="bb" then
    return true
    elseif self.技能名称=="破釜沉舟" and 攻击方.气血>=攻击方.最大气血*0.5 then
    return true
    elseif self.技能名称=="破釜沉舟" and 攻击方.类型=="bb" then
    return true
    elseif self.技能名称=="乾坤妙法" and 攻击方.气血>=攻击方.最大气血*0.5 then
    return true
    elseif self.技能名称=="乾坤妙法" and 攻击方.类型=="bb" then
    return true
    elseif self.技能名称=="背水" and 攻击方.气血>=攻击方.最大气血*0.5 then
    return true
    elseif self.技能名称=="背水" and 攻击方.类型=="bb" then
    return true
    elseif self.技能名称=="剑荡四方" and 攻击方.气血>=1 then
    return true
    elseif self.技能名称=="移魂化骨" and 攻击方.气血>=攻击方.最大气血*0.3 then
    return true
    elseif self.技能名称=="移魂化骨" and 攻击方.类型=="bb" then
    return true
    end

  if self.技能名称=="清心咒"  then
    return true
    elseif self.技能名称=="七宝玲珑灯"  then
    return true
  elseif self.技能名称=="碎玉弄影" or self.技能名称=="魑魅缠身" then
    return self:愤怒消耗(40,攻击方,编号,self.技能名称)
  elseif self.技能名称=="飞符炼魂" or self.技能名称=="顺势而为" or self.技能名称=="画地为牢" then
    return self:愤怒消耗(60,攻击方,编号,self.技能名称)
  elseif self.技能名称=="偷龙转凤" or  self.技能名称=="落花成泥" then
    return self:愤怒消耗(80,攻击方,编号,self.技能名称)
   elseif self.技能名称=="万木凋枯" or self.技能名称=="三星灭魔" or self.技能名称=="情天恨海" or self.技能名称=="夺命蛛丝" or self.技能名称=="五行错位" or self.技能名称=="天诛地灭" or self.技能名称=="冤魂不散" or self.技能名称=="紫气东来" or self.技能名称=="太极生化" or self.技能名称=="龙啸九天" or self.技能名称=="斩龙诀" or self.技能名称=="指地成钢" or self.技能名称=="魔兽啸天" or self.技能名称=="踏山裂石" or self.技能名称=="蝼蚁蚀天" then
    return self:愤怒消耗(150,攻击方,编号,self.技能名称)
  elseif self.技能名称=="惊魂铃" or self.技能名称=="发瘟匣" or self.技能名称=="摄魂" or self.技能名称=="无尘扇"  then
    return self:魔法消耗(攻击方,1,1)
  elseif self.技能名称=="烟雨剑法" or self.技能名称=="天命剑法" then
    return self:魔法消耗(攻击方,50,1)
  elseif self.技能名称=="妙手空空" then
   return self:魔法消耗(攻击方,1,1)
  elseif self.技能名称=="长驱直入" or self.技能名称=="翩鸿一击" or self.技能名称=="妙悟" or self.技能名称=="烈焰真诀" or self.技能名称=="渡劫金身" or self.技能名称=="诸天看护"  then
    return self:魔法消耗(攻击方,50,1)
  elseif self.技能名称=="后发制人" then
    return true
  elseif self.技能名称=="高级连击" or self.技能名称=="理直气壮" then
    return true
  elseif self.技能名称=="杀气诀" or self.技能名称=="推拿" or self.技能名称=="落魄符" then
    return self:魔法消耗(攻击方,40,1)
  elseif self.技能名称=="活血" then
 return self:魔法消耗(攻击方,70,1)
  elseif self.技能名称=="莲心剑意" or self.技能名称=="利刃" or self.技能名称=="夺魄令" or self.技能名称=="夺魄令1" or self.技能名称=="瘴气" or  self.技能名称=="安神诀" or self.技能名称=="反间之计" or self.技能名称=="龙吟" or self.技能名称=="连环击" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="推气过宫" then
    return self:魔法消耗(攻击方,100,1)
  elseif self.技能名称=="武神怒击" then
    return self:魔法消耗(攻击方,10,数量)
  elseif self.技能名称=="牛刀小试" then
    return self:魔法消耗(攻击方,5,数量)
  elseif self.技能名称=="夺命蛛丝" or self.技能名称=="血雨" then
    return self:魔法消耗(攻击方,150,数量)
  elseif self.技能名称=="月光" or self.技能名称=="披坚执锐" then
    return self:魔法消耗(攻击方,100,数量)
  elseif self.技能名称=="鸿渐于陆" then
    return self:魔法消耗(攻击方,100,数量)
  elseif self.技能名称=="天魔解体" then
    return self:魔法消耗(攻击方,100,数量)
  elseif self.技能名称=="夺命咒" then
    return self:魔法消耗(攻击方,20,数量)
  elseif self.技能名称=="金刚护法" then
    return self:魔法消耗(攻击方,40,1)
  elseif self.技能名称=="炼气化神" then
    if 攻击方.气血>=攻击方.最大气血*0.1 then return true else return false end
  elseif self.技能名称=="魔息术" and 攻击方.气血>=50 then
    攻击方.气血=攻击方.气血-50
    return true
  elseif   self.技能名称=="气慑天军" or self.技能名称=="匠心·削铁" or self.技能名称=="匠心·固甲" or self.技能名称=="威震凌霄" then
    return self:魔法消耗(攻击方,100,1)
  elseif   self.技能名称=="天崩地裂" or  self.技能名称=="断岳势" or self.技能名称=="裂石" or  self.技能名称=="地涌金莲" then
    return self:魔法消耗(攻击方,50,1)
  elseif self.技能名称=="翻江搅海" or self.技能名称=="惊涛怒" or self.技能名称=="浪涌" or self.技能名称=="阎罗令" or self.技能名称=="雨落寒沙" then
    return self:魔法消耗(攻击方,20,数量)
  elseif self.技能名称=="生命之泉" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="二龙戏珠" then
    return self:魔法消耗(攻击方,70,数量)
  elseif self.技能名称=="摧心术" or self.技能名称=="神龙摆尾" then
    return self:魔法消耗(攻击方,100,数量)
  elseif self.技能名称=="一笑倾城" or self.技能名称=="分身术" or self.技能名称=="颠倒五行"  then
    return self:魔法消耗(攻击方,80,数量)
  elseif self.技能名称=="一苇渡江" or self.技能名称=="扶摇万里" or self.技能名称=="匠心·破击" or self.技能名称=="达摩护体" or self.技能名称=="灵动九天" or self.技能名称=="飞花摘叶" or self.技能名称=="韦陀护法" or self.技能名称=="唤灵·魂火" or self.技能名称=="金刚护体" or self.技能名称=="唧唧歪歪" or self.技能名称=="天雷斩" or self.技能名称=="八凶法阵" or self.技能名称=="鹰击" or self.技能名称=="连环击" or self.技能名称=="泰山压顶" or self.技能名称=="奔雷咒" or self.技能名称=="地狱烈火" or self.技能名称=="水漫金山" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="娉婷袅娜" or self.技能名称=="勾魂" or self.技能名称=="乘风破浪" or self.技能名称=="逆鳞" or self.技能名称=="判官令" then
    return self:魔法消耗(攻击方,40,数量)
  elseif self.技能名称=="如花解语" or self.技能名称=="雷霆万钧" or  self.技能名称=="摄魄" or self.技能名称=="日月乾坤" then
    return self:魔法消耗(攻击方,35,数量)
  elseif self.技能名称=="锋芒毕露" or self.技能名称=="流沙轻音" or self.技能名称=="食指大动" or self.技能名称=="五雷轰顶" or self.技能名称=="似玉生香" or self.技能名称=="姐妹同心" or self.技能名称=="幻镜术" or self.技能名称=="失忆符" or self.技能名称=="摇头摆尾" or self.技能名称=="天地同寿" or self.技能名称=="乾坤妙法" or self.技能名称=="金刚镯" or self.技能名称=="碎甲符" or self.技能名称=="我佛慈悲"  or self.技能名称=="水攻" or self.技能名称=="落岩" or self.技能名称=="烈火" or self.技能名称=="雷击" then
    return self:魔法消耗(攻击方,50,数量)
  elseif self.技能名称=="炎护" or self.技能名称=="冰川怒" or self.技能名称=="尘土刃" or self.技能名称=="荆棘舞" or self.技能名称=="落叶萧萧" or self.技能名称=="莲步轻舞" or self.技能名称=="变身" or self.技能名称=="狂怒" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="满天花雨" or self.技能名称=="镇妖" then
    return self:魔法消耗(攻击方,45,数量)
  elseif self.技能名称=="楚楚可怜" or self.技能名称=="百毒不侵" or self.技能名称=="天罗地网" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="星月之惠" or self.技能名称=="誓血之祭" or self.技能名称=="紧箍咒" or self.技能名称=="普渡众生" or self.技能名称=="凝神术" or self.技能名称=="雾杀" or self.技能名称=="黄泉之息" or self.技能名称=="尸腐毒" or self.技能名称=="尸腐毒 " or self.技能名称=="五雷咒" or self.技能名称=="龙腾" or self.技能名称=="百万神兵" or self.技能名称=="狮搏" or self.技能名称=="狮搏 " or self.技能名称=="含情脉脉" then
    return self:魔法消耗(攻击方,50,数量)
  elseif self.技能名称=="谜毒之缚" or self.技能名称=="诡蝠之刑" or self.技能名称=="怨怖之泣" then
    return self:魔法消耗(攻击方,30,10*数量)
  elseif self.技能名称=="火甲术" or self.技能名称=="失心符" or self.技能名称=="失魂符" or self.技能名称=="定身符" or self.技能名称=="错乱" or self.技能名称=="三昧真火"  then
    return self:魔法消耗(攻击方,60,数量)
  elseif self.技能名称=="碎星诀" or self.技能名称=="天神护法" or self.技能名称=="红袖添香" or self.技能名称=="宁心" or self.技能名称=="落雷符" then
    return self:魔法消耗(攻击方,30,数量)
  elseif   self.技能名称=="金身舍利" or self.技能名称=="明光宝烛" or  self.技能名称=="善恶有报" or  self.技能名称=="死亡召唤" or  self.技能名称=="夜舞倾城" or    self.技能名称=="惊心一剑" or  self.技能名称=="壁垒击破"  then
    return self:魔法消耗(攻击方,100,1)
  elseif self.技能名称=="催眠符" or self.技能名称=="九天玄火" then
    return self:魔法消耗(攻击方,45,数量)
  elseif self.技能名称=="大闹天宫" or self.技能名称=="天神护体" or self.技能名称=="锢魂术" or self.技能名称=="失忆符" or self.技能名称=="离魂符" or self.技能名称=="定心术" then
    return self:魔法消耗(攻击方,50,数量)
  elseif self.技能名称=="蜜润" or self.技能名称=="龙卷雨击" or self.技能名称=="刀光剑影" or self.技能名称=="毁灭之光" then
    return self:魔法消耗(攻击方,25,数量)
  elseif self.技能名称=="飞砂走石" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="还阳术" or self.技能名称=="我佛慈悲" or self.技能名称=="佛法无边" then
    return self:魔法消耗(攻击方,150,数量)
  elseif self.技能名称=="舍身取义" or self.技能名称=="风雷韵动" then
    return self:魔法消耗(攻击方,500,数量)
  elseif self.技能名称=="侵掠如火" or  self.技能名称=="不动如山 " or self.技能名称=="其徐如林" or self.技能名称=="其疾如风" then
    return self:魔法消耗(攻击方,200,1)
  elseif self.技能名称=="杨柳甘露" then
    return self:魔法消耗(攻击方,150,数量)
  elseif self.技能名称=="乾天罡气" or self.技能名称=="三花聚顶" then
    if 攻击方.气血>=攻击方.最大气血*0.2 then return true else return false end
  elseif self.技能名称=="力劈华山" then
    return self:魔法消耗(攻击方,150,数量)
  elseif self.技能名称=="归元咒" then
    魔法=攻击方.等级*2+(攻击方.灵力*0.1)
    return self:魔法消耗(攻击方,魔法,数量)
  elseif self.技能名称=="寡欲令" or self.技能名称=="针锋相对" or self.技能名称=="煞气诀" or self.技能名称=="惊魂掌" or self.技能名称=="追魂符" or self.技能名称=="裂石" or self.技能名称=="断岳势"  or self.技能名称=="天崩地裂"  then
    return self:魔法消耗(攻击方,50,数量)
  elseif self.技能名称=="解毒" then
    return self:魔法消耗(攻击方,40,数量)
  elseif self.技能名称=="解封" or self.技能名称=="无穷妙道" or self.技能名称=="腾雷"  or self.技能名称=="波澜不惊" then
    return self:魔法消耗(攻击方,60,数量)
  elseif self.技能名称=="清心" or self.技能名称=="炽火流离" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="镇魂诀" then
    return true
  elseif self.技能名称=="飘渺式" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="驱魔" then
    return self:魔法消耗(攻击方,45,数量)
  elseif self.技能名称=="驱尸" then
    return self:魔法消耗(攻击方,40,数量)
  elseif self.技能名称=="修罗隐身" then
    return self:魔法消耗(攻击方,150,1)
  elseif self.技能名称=="不动如山" then
    return self:魔法消耗(攻击方,150,数量)
  elseif self.技能名称=="幽冥鬼眼" then
    return self:魔法消耗(攻击方,20,数量)
  elseif self.技能名称=="牛劲" then
    return self:魔法消耗(攻击方,20,数量)
  elseif self.技能名称=="魔王回首" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="极度疯狂" then
    return self:魔法消耗(攻击方,30,数量)
  elseif self.技能名称=="威慑" then
    return self:魔法消耗(攻击方,20,数量)
  elseif self.技能名称=="定心术" then
    return self:魔法消耗(攻击方,40,数量)
  elseif self.技能名称=="象形" then
    return self:魔法消耗(攻击方,80,数量)
  elseif self.技能名称=="魂飞魄散" then
    return self:魔法消耗(攻击方,40,数量)
  elseif self.技能名称=="魔音摄魂" then
    return self:魔法消耗(攻击方,500,数量)
  elseif self.技能名称=="复苏" then
    return self:魔法消耗(攻击方,60,数量)
  elseif self.技能名称=="盘丝阵" then
    return self:魔法消耗(攻击方,40,数量)
  elseif self.技能名称=="凋零之歌" or self.技能名称=="真君显灵" or self.技能名称=="由己渡人"  then
    return self:魔法消耗(攻击方,100,数量)
  elseif self.技能名称=="百爪狂杀" or self.技能名称=="六道无量" then
    return self:魔法消耗(攻击方,35,数量)
  elseif self.技能名称=="五行制化" or self.技能名称=="诱袭" then
    return self:魔法消耗(攻击方,70,数量)
  elseif self.技能名称=="上古灵符" or self.技能名称=="上古灵符(怒雷)" or self.技能名称=="上古灵符(流沙)" or self.技能名称=="上古灵符(心火)"  then
    return self:魔法消耗(攻击方,100,数量)
  elseif self.技能名称=="观照万象" then
    return self:魔法消耗(攻击方,200,数量)
  elseif self.技能名称=="天降灵葫" or self.技能名称=="叱咤风云" or self.技能名称=="法术防御" then
    return self:魔法消耗(攻击方,50,数量)
  elseif self.技能名称=="风卷残云" then
    return self:魔法消耗(攻击方,150,数量)
  elseif self.技能名称=="魔焰滔天" then
    return self:魔法消耗(攻击方,60,数量)
  elseif self.技能名称=="亢龙归海" or self.技能名称=="雷浪穿云" then
    return self:魔法消耗(攻击方,200,数量)
  elseif self.技能名称=="钟馗论道" then
    return self:魔法消耗(攻击方,80,数量)
  elseif self.技能名称=="匠心·蓄锐" then
    return self:魔法消耗(攻击方,80,1)
  elseif self.技能名称=="当头一棒" or self.技能名称=="神针撼海" or self.技能名称=="杀威铁棒" or self.技能名称=="泼天乱棒" or self.技能名称=="九幽除名" or self.技能名称=="云暗天昏" or self.技能名称=="铜头铁臂" or self.技能名称=="无所遁形" then
    return self:魔法消耗(攻击方,75,1)
  elseif self.技能名称=="九幽除名" or self.技能名称=="云暗天昏" or self.技能名称=="铜头铁臂" or self.技能名称=="无所遁形" then
    return self:魔法消耗(攻击方,75,1)
  elseif self.技能名称=="还魂咒" then
  return self:魔法消耗(攻击方,150,1)
  elseif self.技能名称=="仙人指路" then
  return self:魔法消耗(攻击方,20,1)
  elseif self.技能名称=="四面埋伏" then
  return self:魔法消耗(攻击方,20,1)
  elseif self.技能名称=="峰回路转" or self.技能名称=="苍茫树" or self.技能名称=="地裂火" or self.技能名称=="日光华" or self.技能名称=="靛沧海" or self.技能名称=="巨岩破" then
  return self:魔法消耗(攻击方,50,1)
  elseif self.技能名称=="知己知彼" then
  return self:魔法消耗(攻击方,80,1)
  elseif self.技能名称=="自在心法" then
  return self:魔法消耗(攻击方,30,1)
  elseif self.技能名称=="莲花心音" then
  return self:魔法消耗(攻击方,60,1)
  elseif self.技能名称=="清风望月" or self.技能名称=="同舟共济" or  self.技能名称=="妖风四起" then
  return self:魔法消耗(攻击方,1000,1)
  else
    --常规提示(攻击方.玩家id,"#W/你的#Y/气血#W/不够#G/不能施法该技能!")
    return false
  end
end

function 战斗处理类:取多个友方目标(编号,目标,数量,名称)
  if self.参战单位[目标] == nil or self.参战单位[目标].队伍 ~= self.参战单位[编号].队伍 then
    目标 = self:取单个友方目标(编号)
  end
  local 目标组={目标}
  if self:取目标状态(编号,目标,2)==false then
     目标组={}
  end
  if 名称 == "慈航普渡" or 名称 == "推气过宫" or 名称 == "地涌金莲" or 名称 == "峰回路转" then
    目标组={}
  end
  if #目标组>=数量 then
     return 目标组
  end
  if 名称~="推气过宫" and 名称~="地涌金莲" and 名称 ~= "慈航普渡" and 名称 ~= "峰回路转" then
    for n=1,#self.参战单位 do
      if  #目标组<数量 and self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) and self.参战单位[n].法术状态[名称]==nil   then
        local 添加=true
        for i=1,#目标组 do
          if 目标组[i]==n then
            添加=false
          end
        end
        if 添加 then
          目标组[#目标组+1]=n
        end
      end
    end
  elseif 名称 == "慈航普渡" then
    for n=1,#self.参战单位 do
      if  #目标组<数量 and n ~= 编号 and self.参战单位[n].类型=="角色" and self.参战单位[n].队伍==self.参战单位[编号].队伍 and not self:取目标状态(编号,n,1) then
        local 添加=true
        for i=1,#目标组 do
          if 目标组[i]==n then
            添加=false
          end
        end
        if 添加 then
          目标组[#目标组+1]=n
        end
      end
    end
  else
    for n=1,#self.参战单位 do
      if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) and self.参战单位[n].法术状态[名称]==nil then
        local 添加=true
        for i=1,#目标组 do
          if 目标组[i]==n then 添加=false end
        end
        if 添加 then
          目标组[#目标组+1]=n
        end
      end
    end
    local 排序组={}
    for n=1,#目标组 do
      排序组[n]={气血=self.参战单位[目标组[n]].气血/self.参战单位[目标组[n]].最大气血*100,id=目标组[n]}
    end
    table.sort(排序组,function(a,b) return a.气血<b.气血 end )
    目标组={}
    for n=1,#排序组 do
      if #目标组<数量 then
        目标组[n]=排序组[n].id
      end
    end
    local 重复 = false
    for n=1,#目标组 do
      if 目标组[n] == 目标 then
        重复 = true
      end
    end
    if 重复 == false and  self.参战单位[目标] ~= nil and self.参战单位[目标].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,目标,1) and self.参战单位[目标].法术状态[名称]==nil then
      目标组[#目标组]=目标
    end
 end
 return 目标组
end

function 战斗处理类:取多个敌方目标(编号,目标,数量,不包括自己本身)
  local 目标组={目标}
  if self:取目标状态(编号,目标,1)==false then
    目标组={}
  elseif self.参战单位[目标].队伍==self.参战单位[编号].队伍 then
    目标组={}
  end
  if #目标组>=数量 then
    return 目标组
  end
  --获取敌人目标
  local 临时目标组 = {}
  for n=1,#self.参战单位 do
    if self.参战单位[n].队伍 ~= self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
      local 添加=true
      for j=1,#目标组 do
        if 目标组[j]==n then
          添加=false
        end
      end
      -- if 添加 then
      --   临时目标组[#临时目标组 + 1] = {a=n,b=取随机数(1,10000)}
      -- end
      if 添加 then
        临时目标组[#临时目标组 + 1] = {a=n,b=self.参战单位[n].速度}
      end
    end
  end
  --随机排序
  table.sort(临时目标组,function(a,b) return a.b > b.b end)

  if 不包括自己本身 then
    目标组={}
  end
  for n=1,#临时目标组 do
    if #目标组 < 数量 then
      if 不包括自己本身 and 临时目标组[n].a~=目标 then
        目标组[#目标组+1] = 临时目标组[n].a
      else
        目标组[#目标组+1] = 临时目标组[n].a
      end
    end
  end
  return 目标组
  -- for n=1,#self.参战单位 do
  --    if  #目标组<数量 and self.参战单位[n].队伍~=self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
  --         --目标组[#目标组+1]=n
  --          local 添加=true
  --          for i=1,#目标组 do
  --             if 目标组[i]==n then 添加=false end
  --             end
  --         if 添加 then
  --            目标组[#目标组+1]=n
  --            end
  --        end
  --    end
 -- return 临时目标组
end

function 战斗处理类:取玩家战斗()
    if self.战斗类型==200001 or self.战斗类型==200002 or self.战斗类型==200003 or self.战斗类型==200004 or self.战斗类型==200005 or self.战斗类型==200006 or self.战斗类型==200003 or
     self.战斗类型==200007 or self.战斗类型==200008 or self.战斗类型==110001 or self.战斗类型==410005 or self.战斗类型==300001  then
        return true
    else
        return false
    end
end
function 战斗处理类:取目标数量(攻击方,技能名称,等级,编号)
  if 技能名称=="金刚护法" and (self.战斗开始==false or self.回合进程=="加载回合") then return 3 end --附加状态的人数
  self.临时等级=等级
  self.临时人数=1
  if 技能名称=="推气过宫" or 技能名称=="幽冥鬼眼"  then
    self.临时人数=math.floor(self.临时等级/30)+1
    if (攻击方.名称=="天罡星" or 攻击方.名称=="蜘蛛女王" or 攻击方.名称=="沙僧的心魔") and 攻击方.队伍==0 then
      self.临时人数=10
    end
  elseif 技能名称=="鹰击" then
    self.临时人数=math.floor(self.临时等级/35)+2
   if 攻击方.等级>=69 then
      self.临时人数=self.临时人数+1
    end
  elseif 技能名称=="落雷符" then
    self.临时人数=math.floor(self.临时等级/30)+1
  elseif 技能名称=="五雷咒" then
    self.临时人数=1
    if 编号~=nil and self:取奇经八脉是否有(编号,"奔雷") then
    self.临时人数=self.临时人数+1
    end
  elseif 技能名称=="月光" then
    self.临时人数=取随机数(2,4)
  elseif 技能名称=="夺命咒" then
    self.临时人数=math.floor(self.临时等级/35)+1
    if 编号~=nil and self:取奇经八脉是否有(编号,"灵身") then
        self.临时人数=self.临时人数+2
    end
    if 编号~=nil and self.参战单位[编号].法术状态.同舟共济~=nil and 取随机数(1,100)<=50 then
    self.临时人数=10
    end
		if self:取玩家战斗() then
		self.临时人数=1
		end
  elseif 技能名称=="普渡众生" then
    self.临时人数=1
    if self:取指定法宝(编号,"普渡",1) then
      if self:取指定法宝境界(编号,"普渡") and 取随机数()<=80 then
        self.临时人数=self.临时人数+1
      end
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"道衍") then
        self.临时人数=self.临时人数+2
    end
  elseif 技能名称=="灵动九天" or 技能名称=="神龙摆尾" then
     self.临时人数=math.floor(self.临时等级/35)+1
  elseif 技能名称=="尸腐毒" then
   self.临时人数=1
    if self:取指定法宝(编号,"九幽",1) then
     if self:取指定法宝境界(编号,"九幽")and 取随机数()<=50 then
       self.临时人数=2
       end
      end
  elseif 技能名称=="尸腐毒 " then
   self.临时人数=1
  elseif 技能名称=="天外飞剑" then
     self.临时人数=5
  elseif 技能名称=="金身舍利" or 技能名称=="明光宝烛" then
     self.临时人数=math.floor(self.临时等级/35)+1
  elseif 技能名称=="浪涌" then
   self.临时人数=math.floor(self.临时等级/35)+1
    if self.临时人数>3 then self.临时人数=3 end
  elseif 技能名称=="惊涛怒" then
    self.临时人数=4
    if self.临时人数>3 then self.临时人数=3 end
  elseif 技能名称=="金刚护法" or 技能名称=="金刚护体" or 技能名称=="一苇渡江" or 技能名称=="韦陀护法" then
   self.临时人数=math.floor(self.临时等级/25)+1
   if 编号~=nil and self:取奇经八脉是否有(编号,"映法") and 取随机数() <=50 then
       self.临时人数=10
   end
  elseif 技能名称=="雨落寒沙" or 技能名称=="唧唧歪歪" or 技能名称=="龙卷雨击" or 技能名称=="阎罗令" or 技能名称=="生命之泉" or 技能名称=="炼气化神" then
  self.临时人数=math.floor(self.临时等级/25)+1
  if 技能名称=="雨落寒沙" and 编号~=nil and self:取奇经八脉是否有(编号,"倩影") then
  self.临时人数=self.临时人数+1
  end
  if 技能名称=="雨落寒沙" and 编号~=nil and self:取奇经八脉是否有(编号,"磐石") and 取随机数(1,100)<=5 then
  self.临时人数=10
  end
  if 技能名称=="龙卷雨击" and 编号~=nil and self:取奇经八脉是否有(编号,"戏珠") then
  self.临时人数=self.临时人数+1
  end
  if 技能名称=="龙卷雨击" and 编号~=nil and self:取奇经八脉是否有(编号,"龙魄") and 取随机数(1,100)<=10 then
  self.临时人数=self.临时人数+3
  end
  if 技能名称=="唧唧歪歪" and 编号~=nil and self:取奇经八脉是否有(编号,"聚气") then
  self.临时人数=self.临时人数+1
  end
  if 技能名称=="生命之泉" and 编号~=nil and self:取奇经八脉是否有(编号,"同辉") then
  self.临时人数=self.临时人数+1
  end
  if 技能名称=="阎罗令" and 编号~=nil and self:取奇经八脉是否有(编号,"伤魂") then
  self.临时人数=self.临时人数+1
  end
  if self:取玩家战斗() and (技能名称=="阎罗令" or 技能名称=="雨落寒沙") then self.临时人数=2 end
  elseif 技能名称=="亢龙归海" then
    self.临时人数=7
  elseif 技能名称=="雷浪穿云" then
    self.临时人数=10
  elseif 技能名称=="飞砂走石" then
  self.临时人数=math.floor(self.临时等级/35)+1
  if  编号~=nil and self:取奇经八脉是否有(编号,"震怒")then
  self.临时人数=self.临时人数+1
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"魔心") and 取随机数(1,100)<=10 then
  self.临时人数=self.临时人数+2
  end
  elseif 技能名称=="摇头摆尾" then
  self.临时人数=math.floor(self.临时等级/35)+1
  if  编号~=nil and self:取奇经八脉是否有(编号,"震怒")then
  self.临时人数=self.临时人数+1
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"魔心") and 取随机数(1,100)<=10 then
  self.临时人数=self.临时人数+2
  end
  elseif 技能名称=="炽火流离" then
    self.临时人数=1
  elseif 技能名称=="飞花摘叶" then
    self.临时人数=4
    if 编号~=nil and self:取奇经八脉是否有(编号,"花殇") then
    self.临时人数=self.临时人数+3
    end
  elseif 技能名称=="龙腾" then
    self.临时人数=1
    if 编号~=nil and self:取奇经八脉是否有(编号,"摧意") and 取随机数()<=20 then
    self.临时人数=self.临时人数+2
    end
  elseif 技能名称=="冥王爆杀" or 技能名称=="笑里藏刀" then
    self.临时人数=1
 elseif 技能名称=="幻镜术" then
  self.临时人数=1
  if 编号~=nil and self:取奇经八脉是否有(编号,"迷梦") then
  self.临时人数=self.临时人数+1
  end
  elseif 技能名称=="同舟共济" then
    self.临时人数=2
  elseif 技能名称=="焚魔烈焰" or 技能名称=="凋零之歌" then
    self.临时人数=3
    if 编号~=nil and self:取奇经八脉是否有(编号,"怒火") then
      self.临时人数=4
    end
  elseif 技能名称=="碎星诀" or 技能名称=="镇魂诀" or 技能名称=="杀气诀" or 技能名称=="安神诀" or 技能名称=="逆鳞" or 技能名称=="盘丝阵"
    or 技能名称=="天神护体" or 技能名称=="天神护法" or 技能名称=="定心术" or 技能名称=="乘风破浪"or 技能名称=="红袖添香"then
   self.临时人数=math.floor(self.临时等级/35)+1
  elseif 技能名称=="九天玄火"  then
   self.临时人数=math.floor(self.临时等级/30)+1
   if self.临时人数>4 then self.临时人数=4 end
  elseif  技能名称=="苍茫树" or 技能名称=="地裂火" or 技能名称=="靛沧海" or 技能名称=="日光华" or 技能名称=="巨岩破"  then
   self.临时人数=math.floor(self.临时等级/40)+2
   if self:取玩家战斗() or (self.战斗类型==100011 and 攻击方.类型 == "bb") then self.临时人数=1 end
   elseif 技能名称=="五行制化"then
    self.临时人数=10
    if self:取玩家战斗() then self.临时人数=5 end
  elseif 技能名称=="云暗天昏" or 技能名称=="匠心·破击" then
    self.临时人数=math.floor(self.临时等级/35)+2
    if self.临时人数>6 then self.临时人数=6 end
  elseif 技能名称=="天雷斩" then
    if 攻击方.类型 == "bb" then
    self.临时人数=3
    else
    self.临时人数=math.floor(self.临时等级/30)+1
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"画地为牢")then
  self.临时人数=self.临时人数+2
  end
    if self:取玩家战斗() then self.临时人数=1 end
  elseif 技能名称=="天罗地网" then
    self.临时人数=math.floor(self.临时等级/30)+1
  if 编号~=nil and self:取奇经八脉是否有(编号,"粘附") then
  self.临时人数=self.临时人数+1
  end
  if self:取玩家战斗() then self.临时人数=2 end
  elseif 技能名称=="落叶萧萧" then
  self.临时人数=math.floor(self.临时等级/35)+1
  if 编号~=nil and self:取奇经八脉是否有(编号,"法身") then
  self.临时人数=self.临时人数+1
  end
  elseif 技能名称=="风卷残云" then
  self.临时人数=7
  elseif 技能名称=="尘土刃" or 技能名称=="荆棘舞" or 技能名称=="血雨" then
  self.临时人数=1
  if 编号~=nil and self:取奇经八脉是否有(编号,"追击")then
  self.临时人数=self.临时人数+1
  end

  elseif 技能名称=="剑荡四方" then
    self.临时人数=3
  elseif 技能名称=="雷霆万钧"   then
    self.临时人数=3
  if 编号~=nil and self:取奇经八脉是否有(编号,"怒气") and 取随机数(1,100)<=20 then
  self.临时人数=self.临时人数+2
  end
  elseif 技能名称=="破釜沉舟"then
    if 编号~=nil and self:取奇经八脉是否有(编号,"干将")then
    self.临时人数=6
    else
    self.临时人数=4
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"无敌") and 取随机数(1,100)<=10 then
    self.临时人数=self.临时人数+6
    end
    if self.临时人数>10 then self.临时人数=10 end
   elseif 技能名称=="狮搏" or 技能名称=="狮搏 " then
    if 编号~=nil and self:取奇经八脉是否有(编号,"狮吼") and 取随机数(1,100)<=35 then
    self.临时人数=2
    else
    self.临时人数=1
    end
  elseif 技能名称=="二龙戏珠" or 技能名称=="摧心术"  then
    self.临时人数=2
    if 编号~=nil and self:取奇经八脉是否有(编号,"龙珠") and 取随机数(1,100)<=50 then
      self.临时人数=self.临时人数+1
    end
  elseif 技能名称=="地涌金莲" then
    self.临时人数=math.floor(self.临时等级/30)+1
    if 编号~=nil and self:取奇经八脉是否有(编号,"金莲")   then
      self.临时人数=self.临时人数+1
    end
  elseif 技能名称=="百爪狂杀" then
    self.临时人数=4
    if 编号~=nil and self:取奇经八脉是否有(编号,"百炼") then
    self.临时人数=self.临时人数+1
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"夜之王者") and 取随机数(1,100)<=60 then
    self.临时人数=self.临时人数+2
    end
  elseif 技能名称=="满天花雨" or 技能名称=="鸿渐于陆" then
    self.临时人数=1
    if 编号~=nil and self:取奇经八脉是否有(编号,"毒引") then
    self.临时人数=self.临时人数+2
    end
  elseif 技能名称=="判官令" then
    self.临时人数=1
    if 编号~=nil and self:取奇经八脉是否有(编号,"毒印") then
    self.临时人数=self.临时人数+1
    end
  elseif 技能名称=="飘渺式" then
    self.临时人数=math.floor(self.临时等级/30)+1
    if 编号~=nil and self:取奇经八脉是否有(编号,"修心") then
    self.临时人数=self.临时人数+1
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"心随意动") and 取随机数(1,100)<=5 then
    self.临时人数=10
    end
    if self:取玩家战斗() then self.临时人数=1 end
  elseif 技能名称=="针锋相对" then
    self.临时人数=1
    if  self.参战单位[编号].法术状态.巨锋 then
   self.临时人数=3
    end
    if  self.参战单位[编号].法术状态.战复  then
   self.临时人数=2
    end
  elseif  技能名称=="匠心·削铁" or 技能名称=="匠心·固甲" or 技能名称=="匠心·蓄锐" then
   self.临时人数=1
  if  self.参战单位[编号].法术状态.战复  then
   self.临时人数=取随机数(2,3)
    end
  if  self.参战单位[编号].法术状态.据守  then
   self.临时人数=取随机数(3,5)
    end
  elseif  技能名称=="锋芒毕露"  then
    self.临时人数=1
    if  self.参战单位[编号].法术状态.战复  then
   self.临时人数=取随机数(1,3)
    end
    if  self.参战单位[编号].法术状态.据守 then
   self.临时人数=取随机数(2,5)
    end
  elseif 技能名称=="牛刀小试" then
    self.临时人数=2
  elseif 技能名称=="妙悟" then
    self.临时人数=2
  elseif 技能名称=="翻江搅海" then
  self.临时人数=math.floor(self.临时等级/35)+2
  if 攻击方~=nil and 攻击方.等级>=69 then
  self.临时人数=self.临时人数+1
  end
  if self.临时人数>6 and 编号~=nil and self:取奇经八脉是否有(编号,"真君显灵") and 取随机数(1,100)<=1 then
      self.临时人数=10
  end
  elseif 技能名称=="蜜润" then
   self.临时人数=math.floor(self.临时等级/35)+1
  elseif 技能名称=="一笑倾城" then
    self.临时人数=3
  elseif 技能名称=="瘴气" then
    self.临时人数=3
    if 编号~=nil and self:取奇经八脉是否有(编号,"情劫") then
    self.临时人数=self.临时人数+2
    end
  elseif 技能名称=="碎甲符" then
    self.临时人数=3
    if 编号~=nil and self:取奇经八脉是否有(编号,"碎甲") then
    self.临时人数=self.临时人数+3
    end
  elseif 技能名称=="碎玉弄影" then
    self.临时人数=2
  elseif 技能名称=="啸风诀" or 技能名称=="扶摇万里" or 技能名称=="利刃" or 技能名称=="钟馗论道" or 技能名称=="其疾如风" or 技能名称=="其徐如林" or 技能名称=="不动如山 " or 技能名称=="侵掠如火" or 技能名称=="河东狮吼" or 技能名称=="碎甲术" or 技能名称=="停陷术" or 技能名称=="绝幻魔音" or 技能名称=="清风望月" or 技能名称=="自爆" or 技能名称=="龙吟" or 技能名称=="刀光剑影" or 技能名称=="毁灭之光" or 技能名称=="四海升平" or 技能名称== "罗汉金钟" or 技能名称 == "魔兽之印" or 技能名称=="玉清诀" or 技能名称=="晶清诀" or 技能名称=="圣灵之甲" then
   self.临时人数=10
  elseif 技能名称=="八凶法阵" or 技能名称=="妖风四起" then
    self.临时人数=math.floor(self.临时等级/30)+2
    if self.临时人数>4 then self.临时人数=4 end
  elseif 技能名称=="天降灵葫" then
    self.临时人数=取随机数(1,5)
  elseif 技能名称=="叱咤风云" or 技能名称=="食指大动" then
    self.临时人数=3
  elseif 技能名称=="三昧真火" then
    self.临时人数=1
  if 编号~=nil and self:取奇经八脉是否有(编号,"神炎") then
    self.临时人数=self.临时人数+1
    end
  elseif 技能名称=="腾雷" then
    self.临时人数=1
    if 编号~=nil and self:取奇经八脉是否有(编号,"斩魔") then
    self.临时人数=self.临时人数+2
    end
  elseif 技能名称=="峰回路转" then
    self.临时人数=10
  elseif 技能名称=="流沙轻音" then
    self.临时人数=3
  elseif 技能名称=="泰山压顶" or 技能名称=="水漫金山" or 技能名称=="地狱烈火" or 技能名称=="奔雷咒" then
   self.临时人数=math.floor(self.临时等级/30)+1
    if self.临时人数>3 then self.临时人数=3 end
  elseif 技能名称=="谜毒之缚" or 技能名称=="诡蝠之刑" or 技能名称=="怨怖之泣" then
    self.临时人数=math.floor(self.临时等级/40)+1
    if self.临时人数>=5 then self.临时人数=5 end
    if 编号~=nil and self:取奇经八脉是否有(编号,"灵诅") then
      self.临时人数=self.临时人数+1
    end
  elseif 技能名称=="神针撼海" then
    self.临时人数=math.floor(self.临时等级/35)+1
    if self.临时人数>=5 then self.临时人数=5 end
  else
   self.临时人数=1
  end
 return self:NPC_AI目标数量(攻击方,技能名称,等级,self.战斗类型) or self.临时人数
end

function 战斗处理类:恢复技能(名称)
  local 临时名称={"峰回路转","其徐如林","仙人指路","自在心法","清风望月","还魂咒","三花聚顶","渡劫金身","起死回生","回魂咒","无穷妙道","还阳术","舍身取义","活血","慈航普渡","地涌金莲","莲花心音","妙悟","星月之惠","玉清诀","净世煌火","晶清诀","冰清诀","水清诀","四海升平","命归术","气归术","凝神诀","凝气诀","命疗术","心疗术","气疗术","归元咒","乾天罡气","我佛慈悲","杨柳甘露","推拿","匠心·蓄锐","推气过宫","解毒","百毒不侵","宁心","解封","清心","驱魔","驱尸","寡欲令","复苏","由己渡人"}
 for n=1,#临时名称 do
     if 临时名称[n]==名称 then return true end
   end
 return false
end

function 战斗处理类:法攻技能(名称)
  local 临时名称={"三星灭魔","夜舞倾城","扶摇万里","夺命蛛丝","五行错位","冤魂不散","风雷韵动","绝幻魔音","笑里藏刀","天诛地灭","太极生化","妖风四起","万木凋枯","摧心术","凋零之歌","蝼蚁蚀天","毁灭之光","刀光剑影","踏山裂石","摇头摆尾","龙啸九天","雷浪穿云","紫气东来","天外飞剑","上古灵符","叱咤风云","天降灵葫","月光","八凶法阵","飞符炼魂","五行制化","孔雀明王经","黄泉之息","焚魔烈焰","腾雷","风卷残云","魔焰滔天","亢龙归海","天罗地网","夺命咒","血雨","落叶萧萧","荆棘舞","尘土刃","冰川怒","誓血之祭","自爆","唧唧歪歪","五雷咒","落雷符","雨落寒沙","五雷轰顶","雷霆万钧","龙卷雨击","炽火流离","龙吟","二龙戏珠","龙腾","云暗天昏","匠心·破击","苍茫树","靛沧海","日光华","地裂火","巨岩破","三昧真火","飞砂走石","判官令","阎罗令","水攻","烈火","落岩","雷击","食指大动","流沙轻音","泰山压顶","水漫金山","地狱烈火","奔雷咒","冥王爆杀"}
 for n=1,#临时名称 do
     if 临时名称[n]==名称 then return true end
   end
 return false
end

function 战斗处理类:物攻技能(名称)
  local 临时名称={"情天恨海","死亡召唤","六道无量","指地成钢","背水","魔兽啸天","武神怒击","斩龙诀","剑荡四方","翻江搅海","破釜沉舟","猛击","百爪狂杀","鸿渐于陆","翩鸿一击","天命剑法","长驱直入","牛刀小试","天崩地裂","断岳势","裂石","满天花雨","破血狂攻","破碎无双","弱点击破","善恶有报","惊心一剑","壁垒击破","威震凌霄","横扫千军","狮搏","狮搏 ","象形","连环击","鹰击","烟雨剑法","飘渺式","针锋相对","天雷斩","裂石","断岳势","天崩地裂","浪涌","惊涛怒","力劈华山","高级连击","理直气壮"}
  for n=1,#临时名称 do
    if 临时名称[n]==名称 then return true end
  end
  return false
end

function 战斗处理类:封印技能(名称)
 local 临时名称={"魑魅缠身","锋芒毕露","诱袭","反间之计","催眠符","画地为牢","失心符","落魄符","失忆符","追魂符","离魂符","失魂符","定身符","莲步轻舞","如花解语","似玉生香","娉婷袅娜","镇妖","错乱","百万神兵","日月乾坤","威慑","含情脉脉","魔音摄魂","夺魄令1","夺魄令","惊魂掌","煞气诀","象形"}
 for n=1,#临时名称 do
     if 临时名称[n]==名称 then return true end
   end
 return false
end

function 战斗处理类:群体封印技能(名称)
 local 临时名称={"碎甲符","瘴气","一笑倾城","河东狮吼","放下屠刀","凝滞术","停陷术","破甲术","碎甲术","利刃","飞花摘叶","碎玉弄影","锢魂术","落花成泥"}
 for n=1,#临时名称 do
     if 临时名称[n]==名称 then return true end
   end
 return false
end

function 战斗处理类:减益技能(名称)
local 临时名称={"尸腐毒 ","尸腐毒","紧箍咒","勾魂","姐妹同心","摄魄","雾杀","谜毒之缚","诡蝠之刑","怨怖之泣","偷龙转凤"}
 for n=1,#临时名称 do
     if 临时名称[n]==名称 then return true end
   end
 return false
end

function 战斗处理类:取对方可偷取增益技能(目标)
  local 临时名称 = {"凝神术","顺势而为","红袖添香","金刚镯","其疾如风","不动如山 ","侵掠如火","修罗咒","天衣无缝","流云诀","啸风诀","四面埋伏","魂飞魄散","知己知彼","天地同寿","煞气诀1","无敌牛妖","无敌牛虱","逆鳞","御风","幻镜术","颠倒五行","碎星诀","不动如山","气慑天军","匠心·固甲","匠心·削铁","明光宝烛","法术防御","罗汉金钟","光辉之甲","同舟共济","真君显灵","偷龙转凤","魑魅缠身","烈焰真诀","莲心剑意","波澜不惊","钟馗论道","诸天看护","渡劫金身","太极护法","野兽之力","圣灵之甲","魔兽之印","天神护体","移魂化骨","蜜润","后发制人","杀气诀","安神诀","分身术","达摩护体","呼子唤孙","唤灵·焚魂","唤魔·毒魅","唤魔·堕羽","唤灵·魂火","铜头铁臂","无所遁形","金刚护法","金刚护体","韦陀护法","一苇渡江","佛法无边","楚楚可怜","天神护法","乘风破浪","神龙摆尾","生命之泉","炼气化神","乾坤妙法","普渡众生","灵动九天","幽冥鬼眼","修罗隐身","火甲术","魔王回首","牛劲","定心术","极度疯狂","魔息术","天魔解体","盘丝阵","不动如山","镇魂诀","金身舍利","炎护"}
  local 技能组 = {}
  local 返回数据
  if not 判断是否为空表(self.参战单位[目标].法术状态) then
    for k,v in pairs(self.参战单位[目标].法术状态) do
      for i=1,#临时名称 do
        if k==临时名称[i] then
          技能组[#技能组+1]=k
        end
      end
    end
  end
  if #技能组>0 then
    返回数据=技能组[取随机数(1,#技能组)]
  end
  return 返回数据
end
--0914电魂闪
function 战斗处理类:取对方可偷取增益技能1(目标)
  local 临时名称 = {"红袖添香","修罗咒","天衣无缝","金刚镯","魂飞魄散","知己知彼","无敌牛妖","无敌牛虱","逆鳞","御风","颠倒五行","碎星诀","不动如山","明光宝烛","法术防御","光辉之甲","同舟共济","偷龙转凤","魑魅缠身","天神护体","移魂化骨","蜜润","杀气诀","安神诀","达摩护体","呼子唤孙","铜头铁臂","无所遁形","金刚护法","金刚护体","韦陀护法","一苇渡江","佛法无边","天神护法","乘风破浪","神龙摆尾","生命之泉","炼气化神","乾坤妙法","普渡众生","灵动九天","幽冥鬼眼","火甲术","魔王回首","牛劲","定心术","魔息术","天魔解体","盘丝阵","不动如山","镇魂诀","金身舍利","炎护"}
  local 技能组 = {}
  local 返回数据
  if not 判断是否为空表(self.参战单位[目标].法术状态) then
    for k,v in pairs(self.参战单位[目标].法术状态) do
      for i=1,#临时名称 do
        if k==临时名称[i] then
          技能组[#技能组+1]=k
        end
      end
    end
  end
  if #技能组>0 then
    返回数据=技能组[取随机数(1,#技能组)]
  end
  return 返回数据
end

function 战斗处理类:增益技能(名称)
 local 临时名称={"顺势而为","凝神术","红袖添香","其疾如风","不动如山 ",
 "侵掠如火","修罗咒","天衣无缝","流云诀","啸风诀","四面埋伏","魂飞魄散",
 "知己知彼","天地同寿","煞气诀1","无敌牛妖","无敌牛虱","变身","逆鳞","御风",
 "幻镜术","颠倒五行","碎星诀","不动如山","气慑天军","匠心·固甲","匠心·削铁",
 "明光宝烛","法术防御","罗汉金钟","光辉之甲","同舟共济","真君显灵","魑魅缠身",
 "烈焰真诀","莲心剑意","波澜不惊","钟馗论道","诸天看护","渡劫金身","太极护法",
 "野兽之力","圣灵之甲","魔兽之印","天神护体","移魂化骨","蜜润","后发制人","杀气诀",
 "安神诀","分身术","达摩护体","呼子唤孙","唤灵·焚魂","唤魔·毒魅","唤魔·堕羽","唤灵·魂火",
 "铜头铁臂","无所遁形","金刚护法","金刚护体","韦陀护法","一苇渡江","佛法无边","楚楚可怜","天神护法",
 "乘风破浪","神龙摆尾","生命之泉","炼气化神","乾坤妙法","普渡众生","灵动九天","幽冥鬼眼","修罗隐身",
 "火甲术","魔王回首","牛劲","定心术","极度疯狂","魔息术","天魔解体","盘丝阵","金刚镯","镇魂诀","金身舍利","炎护",
 "披坚执锐","狂怒","龙骇龙腾","龙骇龙卷","被动龙魂"}
 for n=1,#临时名称 do
     if 临时名称[n]==名称 then return true end
   end
 return false
end

function 战斗处理类:变身技能(名称)
 local 临时名称={"变身"}
 for n=1,#临时名称 do
     if 临时名称[n]==名称 then return true end
   end
 return false
end

function 战斗处理类:取封印状态(编号,是否)
 local 临时名称={"妖风四起","一笑倾城","落魄符","楚楚可怜","誓血之祭","象形","天罗地网","碎玉弄影","冰川怒","反间之计","诱袭","锋芒毕露","催眠符","失心符","落魄符","失忆符","追魂符","离魂符","失魂符","定身符","莲步轻舞","如花解语","似玉生香","娉婷袅娜","镇妖","错乱","百万神兵","日月乾坤","威慑","含情脉脉","魔音摄魂","夺魄令1","夺魄令","惊魂掌","煞气诀"}
 for i, v in pairs(self.参战单位[编号].法术状态) do
    for n=1,#临时名称 do
          if 临时名称[n]==i then
            if 是否 ~= nil then
              return i
            end
            return true
          end
        end
   end
 return false
end

function 战斗处理类:取封印状态1(数量)
  local 数量=0
  for n=1,#self.参战单位 do
    if  self.参战单位[n].气血>=1 and self.参战单位[n].队伍==self.队伍区分[2] and self:取封印状态(n,是否) then
      数量=数量+1
    end
  end
  return 数量
end

function 战斗处理类:取技能等级(编号,名称)
  -- if self.参战单位[编号].队伍==0 then
  --   return self.参战单位[编号].等级+10
  -- end

   if self.参战单位[编号].队伍==0 or self.参战单位[编号].名称 =="牛幺" or self.参战单位[编号].标记 == 100080 then
      return self.参战单位[编号].等级+10
   end

  for n=1,#self.参战单位[编号].主动技能 do
    if self.参战单位[编号].主动技能[n].名称==名称 then
      return self.参战单位[编号].主动技能[n].等级
    end
  end
  for n=1,#self.参战单位[编号].附加状态 do
    if self.参战单位[编号].附加状态[n].名称==名称 then
      return self.参战单位[编号].附加状态[n].等级
    end
  end
  for n=1,#self.参战单位[编号].追加法术 do
    if self.参战单位[编号].追加法术[n].名称==名称 then
      return self.参战单位[编号].追加法术[n].等级
    end
  end
  if  self:取孩子技能等级(名称) then
      return self.参战单位[编号].等级
  end

  return 0
end
function 战斗处理类:取孩子技能等级(名称)
     local 临时名称={"四面埋伏"}
     for n=1,#临时名称 do
         if 临时名称[n]==名称 then
          return true
          end
     end
    return false
end

function 战斗处理类:取行动状态(编号)
  if self.参战单位[编号].气血<=0 or self.参战单位[编号].捕捉 or self.参战单位[编号].逃跑 then
    return false
  elseif self.参战单位[编号].法术状态.横扫千军~=nil then
    return false
  elseif self.参战单位[编号].法术状态.誓血之祭~=nil then
    return false
  elseif self.参战单位[编号].法术状态.破釜沉舟~=nil then
    return false
  elseif self.参战单位[编号].法术状态.乾坤妙法~=nil then
    return false
  elseif self.参战单位[编号].法术状态.失心~=nil then
    return false
  elseif self.参战单位[编号].法术状态.落花成泥~=nil then
    return false
  elseif self.参战单位[编号].法术状态.亢龙归海~=nil then
    return false
  elseif self.参战单位[编号].法术状态.血雨~=nil then
    return false
  elseif self.参战单位[编号].法术状态.催眠符~=nil and self.参战单位[编号].指令.类型~="召唤" then
    return false
  elseif self.参战单位[编号].精灵 and self.回合数==1 then
    return false
  end
 return true
end
------0914
function 战斗处理类:取行动状态1(编号)
  if self.参战单位[编号].气血<=0  then
    return false
  end
    return true
  end

function 战斗处理类:取攻击状态(编号)
  --print(编号.."号可执行攻击动作")
  local 技能名称={"碎玉弄影","妖风四起","冰川怒","象形","横扫千军","誓血之祭","连环击","鹰击","楚楚可怜","催眠符","追魂符","定身符","如花解语","似玉生香","百万神兵","日月乾坤","威慑","含情脉脉","夺魄令1","煞气诀"}
  for n=1,#技能名称 do
     if self.参战单位[编号].法术状态[技能名称[n]]~=nil then
         return false
       end
     end
 return true
end

function 战斗处理类:取法术状态(编号,名称)
  local 技能名称={"碎玉弄影","冰川怒","反间之计","落魄符","诱袭","锋芒毕露","修罗隐身","象形","血雨","楚楚可怜","一笑倾城","妖风四起","誓血之祭","横扫千军","连环击","鹰击","催眠符","失心符","离魂符","失魂符","莲步轻舞","似玉生香","错乱","日月乾坤","威慑","含情脉脉","夺魄令1","夺魄令","煞气诀"}
  if 编号~=nil and self:取奇经八脉是否有(编号,"鸿影") and 名称=="雨落寒沙" then
    return  true
end
  for n=1,#技能名称 do
     if self.参战单位[编号].法术状态[技能名称[n]]~=nil then
         return false
       end
     end
 return true
end

function 战斗处理类:取特技状态(编号)
   local 技能名称={"娉婷袅娜","妖风四起","冰川怒","反间之计","诱袭","锋芒毕露","煞气诀","象形","楚楚可怜","血雨","横扫千军","鹰击","连环击","催眠符","失忆符","日月乾坤","誓血之祭"}
  for n=1,#技能名称 do
     if self.参战单位[编号].法术状态[技能名称[n]]~=nil then
         return false
       end
     end
 return true
end

function 战斗处理类:取休息状态(编号)
  local 技能名称={"横扫千军"}
  for n=1,#技能名称 do
     if self.参战单位[编号].法术状态[技能名称[n]]~=nil then
         return true
       end
     end
 return false
end

function 战斗处理类:普通攻击计算(编号,伤害比,友伤)
  local 目标=self.参战单位[编号].指令.目标
  local 目标数=self:取目标数量(self.参战单位[编号],名称,等级,编号)
  local 重复攻击=false
  if 目标==0 or 目标==nil then
    目标=self:取单个敌方目标(编号)
  elseif self:取目标状态(编号,目标,1)==false then
    目标=self:取单个敌方目标(编号)
  elseif self.参战单位[编号].指令.取消 then
    return
  end
  if 目标==0 then
    return
  end


  if self.参战单位[目标].法术状态.分身术~=nil and self.参战单位[目标].法术状态.分身术.破解==nil then
    self.参战单位[目标].法术状态.分身术.破解=1
    --self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/被目标分身术躲过去了！")
    --self:添加提示(self.参战单位[目标].玩家id,编号,"#Y/分身术躲避了一次攻击")
    return
  end
  self.战斗流程[#self.战斗流程+1]={流程=1,攻击方=编号,挨打方={[1]={挨打方=目标,特效={}}}}
  local  躲避=false
  if self.参战单位[目标].躲避减少==nil then self.参战单位[目标].躲避减少=0 end
  if self.参战单位[目标].躲避减少>0 and 取随机数(1,100)<=self.参战单位[目标].躲避减少 then
     躲避=true
  else
    if 躲避==false and self.参战单位[目标].气血>=1 and 取随机数(1,100)<=1 then
     躲避=true
   end
 end

    if self.参战单位[编号].类型 == "角色" then
     for i,v in pairs(玩家数据[self.参战单位[编号].玩家id].角色.数据.装备) do
     if v ~= nil and 玩家数据[self.参战单位[编号].玩家id].道具.数据[v] ~= nil then
      if (玩家数据[self.参战单位[编号].玩家id].道具.数据[v].特效 ~= nil and 玩家数据[self.参战单位[编号].玩家id].道具.数据[v].特效 == "必中") or (玩家数据[self.参战单位[编号].玩家id].道具.数据[v].第二特效 ~= nil and 玩家数据[self.参战单位[编号].玩家id].道具.数据[v].第二特效 == "必中") then
         躲避=false
     end
   end
 end
  end
  if 躲避 then
     self.战斗流程[#self.战斗流程].躲避=true
     self.战斗流程[#self.战斗流程].返回=true
     return
     end
 self.执行等待=self.执行等待+10
  local  保护=false
  local  保护编号=0
  for n=1,#self.参战单位 do
     if 保护编号==0 and self:取行动状态(n) and self.参战单位[目标].法术状态.惊魂掌==nil and self.参战单位[n].指令.类型=="保护" and  self.参战单位[n].队伍==self.参战单位[目标].队伍 and  self.参战单位[n].指令.目标==目标 then
          保护编号=n
          保护=true
          self.参战单位[n].指令.类型=""
           self.执行等待=self.执行等待+3
       end
     end
  local  必杀=false
  local  躲避=false
  local  防御=false
  local  反震=false
  local  反击=false
  local  伤害=self:取基础物理伤害(编号,目标)
  local  最终伤害=self:取最终物理伤害(编号,目标,伤害)

  local  伤害值=self:取伤害结果(编号,目标,最终伤害.伤害,最终伤害.暴击,保护)
  if 保护 then
     local 保护伤害=math.floor(伤害值.伤害*0.7)
     if 保护伤害<1 then 保护伤害=1 end
     local 保护死亡=self:减少气血(保护编号,保护伤害)
      伤害值.伤害=math.floor(伤害值.伤害*0.3)
     if 保护伤害<1 then 保护伤害=1 end
      self.战斗流程[#self.战斗流程].保护数据={编号=保护编号,伤害=保护伤害,死亡=保护死亡}
      end
  -- if 服务器名称 ~=nil then
  --     伤害值.伤害=伤害值.伤害*0.7
  -- end
          if 友伤 ~= nil then
    -- self.参战单位[编号].伤害 = 1
     伤害值.伤害=伤害值.伤害*0.11111
        self.参战单位[编号].指令.类型=""
        self.参战单位[编号].指令.参数=""
        -- self.参战单位[n].指令.目标=n
        -- self:法术计算(n)
      self.参战单位[编号].指令.下达=true
      友伤=nil
    -- end
  end
   if self.参战单位[编号].法术状态.无魂傀儡~=nil then
  伤害值.伤害=1
  end
  if self.参战单位[编号].法术状态.谜毒之缚~=nil then
    伤害值.伤害=qz(伤害值.伤害*0.7*0.8)
  end
  if 伤害值.伤害<qz(self.参战单位[编号].伤害*0.1) then
    伤害值.伤害=取随机数(self.参战单位[编号].伤害*0.1,self.参战单位[编号].伤害*0.15)
  end

  if 伤害值.伤害 >= self.参战单位[目标].最大气血*0.1 and self.参战单位[编号].千钧一怒 ~= nil and self.参战单位[编号].类型 == "bb" and self.参战单位[编号].主人 ~= nil and self.参战单位[self.参战单位[编号].主人] ~= nil then
    self.参战单位[self.参战单位[编号].主人].愤怒 = self.参战单位[self.参战单位[编号].主人].愤怒+10
    if self.参战单位[self.参战单位[编号].主人].愤怒 > 150 then
      self.参战单位[self.参战单位[编号].主人].愤怒 = 150
    end
  end
  self.战斗流程[#self.战斗流程].挨打方[1].动作=最终伤害.动作
  self.战斗流程[#self.战斗流程].挨打方[1].特效=最终伤害.特效
  self.战斗流程[#self.战斗流程].伤害=最终伤害.伤害
  if #最终伤害.特效==0 then
    self.战斗流程[#self.战斗流程].挨打方[1].特效={"被击中"}
  end
  local 吸血=self.参战单位[编号].吸血
  if 吸血==nil and self.参战单位[编号].法术状态.移魂化骨~=nil then
     吸血=self.参战单位[编号].法术状态.移魂化骨.等级/250
     if 编号~=nil and self:取奇经八脉是否有(编号,"暗潮") then
         吸血=吸血+吸血*0.3
     end
  end
 if 吸血~=nil and self.参战单位[目标].鬼魂==nil  then
      local 吸血伤害=math.floor(伤害值.伤害*吸血)
      if 吸血伤害<=0 then
         吸血伤害=1
         end
      self:增加气血(编号,吸血伤害)
      self.战斗流程[#self.战斗流程].吸血伤害=吸血伤害
   end

  if self.战斗流程[#self.战斗流程].伤害==nil then --计算反震 如果出现法爆减伤 则不触发反震和反击
  end
  ---新区改动 修复碎甲刃
  if self.参战单位[编号].碎甲刃~=nil and self.参战单位[编号].碎甲刃>0 and 取随机数()<=30 then
   self:添加状态("碎甲刃",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].碎甲刃,编号)
   self.战斗流程[#self.战斗流程].挨打方[1].增加状态="碎甲刃"
  end
  --计算是否触发毒
  if self.参战单位[编号].毒~=nil and self.参战单位[编号].毒 >=取随机数() then
     self:添加状态("毒",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
     self.战斗流程[#self.战斗流程].挨打方[1].增加状态="毒"
  end
  if 编号~=nil and self:取奇经八脉是否有(编号,"摧心") then
         self:添加状态("摧心",self.参战单位[目标],self.参战单位[编号],self.参战单位[编号].等级,编号)
         self.战斗流程[#self.战斗流程].挨打方[1].增加状态="摧心"
  end

  if 编号~=nil and self:取奇经八脉是否有(编号,"爪印") then
    local 爪印层数 = 1
    if self.参战单位[目标].法术状态.爪印~=nil and self.参战单位[目标].法术状态.爪印.层数~=nil then
      爪印层数=self.参战单位[目标].法术状态.爪印.层数+1
    end
    self:取消状态("爪印",self.参战单位[目标])
    self:添加状态("爪印",self.参战单位[目标],self.参战单位[目标],爪印层数,目标)
    self.战斗流程[#self.战斗流程].挨打方[1].增加状态="爪印"
  end

  --护盾计算
  self.战斗流程[#self.战斗流程].挨打方[1].护盾掉血值=nil
  if  伤害值.类型==1 or 伤害值.类型==3 or 伤害值.类型==4 then
    if self.参战单位[目标].法术状态.护盾~=nil and self.参战单位[目标].法术状态.护盾.护盾值~=nil then
      if 伤害值.伤害<self.参战单位[目标].法术状态.护盾.护盾值 then
        self.参战单位[目标].法术状态.护盾.护盾值=self.参战单位[目标].法术状态.护盾.护盾值-伤害值.伤害
        self.战斗流程[#self.战斗流程].挨打方[1].护盾掉血值=伤害值.伤害
        伤害值.伤害=0
      else
        self.战斗流程[#self.战斗流程].挨打方[1].护盾掉血值=self.参战单位[目标].法术状态.护盾.护盾值
        伤害值.伤害=伤害值.伤害-self.参战单位[目标].法术状态.护盾.护盾值
        self:取消状态("护盾",self.参战单位[目标])
        self.战斗流程[#self.战斗流程].挨打方[1].取消状态="护盾"
      end
    elseif self.参战单位[目标].凝光炼彩~=nil and 取随机数()<=25 then
      self:添加状态("护盾",self.参战单位[目标],self.参战单位[目标],math.floor(伤害值.伤害/2),目标)
      self.战斗流程[#self.战斗流程].挨打方[1].添加状态="护盾"
      self.参战单位[目标].法术状态.护盾.回合=3
    end
  end

  self.战斗流程[#self.战斗流程].挨打方[1].伤害=伤害值.伤害
  self.战斗流程[#self.战斗流程].挨打方[1].伤害类型=伤害值.类型
  self.战斗流程[#self.战斗流程].返回=true
  if 伤害值.类型==2 then --恢复状态
    self:增加气血(目标,伤害值.伤害)
  else
    self.战斗流程[#self.战斗流程].挨打方[1].死亡=self:减少气血(目标,伤害值.伤害,编号)
    if self.参战单位[目标].气血<=0 then
      if self.参战单位[编号].自恋特性~=nil and self.参战单位[编号].自恋次数==nil and self.参战单位[编号].自恋特性*20>=取随机数(1,20) then
        self.参战单位[编号].自恋次数=1
        self.战斗发言数据[#self.战斗发言数据+1]={id=编号,内容="我这一顿乱打下去，神仙都扛不住#24"}
      end
    end
    if self.参战单位[目标].法术状态.催眠符 then
      self:取消状态("催眠符",self.参战单位[目标])
      self.战斗流程[#self.战斗流程].挨打方[1].取消状态="催眠符"
    end
  end

  if self.参战单位[编号].气血>0 and self.参战单位[目标].法术状态.混元伞~=nil then
  local 反弹伤害=qz(self.战斗流程[#self.战斗流程].挨打方[1].伤害*(self.参战单位[目标].法术状态.混元伞.境界*0.03+0.1))
  self.战斗流程[#self.战斗流程+1]={流程=104,气血=反弹伤害,攻击方=目标,挨打方={挨打方=编号,特效={},死亡=self:减少气血(编号,反弹伤害,目标)},提示={允许=false}}
  end

  if self.参战单位[编号].气血>0 and self.参战单位[目标].法术状态.修罗咒~=nil then
  local 反弹伤害=qz(self.战斗流程[#self.战斗流程].挨打方[1].伤害*0.5)
  self.战斗流程[#self.战斗流程+1]={流程=124,气血=反弹伤害,攻击方=目标,挨打方={挨打方=编号,特效={},死亡=self:减少气血(编号,反弹伤害,目标)},提示={允许=false}}
  end

  if self.参战单位[目标].法术状态.火甲术~=nil and self.参战单位[目标].气血>0 then
    local 火甲反=math.floor(self:取灵力伤害(self.参战单位[目标],self.参战单位[编号],编号)*1+qz(self:取技能等级(目标,"三昧真火")*1))
    self.战斗流程[#self.战斗流程+1]={流程=114,气血=火甲反,攻击方=目标,挨打方={挨打方=编号,特效={"三昧真火"},死亡=self:减少气血(编号,火甲反,目标)},提示={允许=false}}
    if 目标~=nil and self:取奇经八脉是否有(目标,"返火") then
      local 火甲反=math.floor(self:取灵力伤害(self.参战单位[目标],self.参战单位[编号],编号)*2+qz(self:取技能等级(目标,"三昧真火")*1))
      self.战斗流程[#self.战斗流程+1]={流程=114,气血=火甲反,攻击方=目标,挨打方={挨打方=编号,特效={"三昧真火"},死亡=self:减少气血(编号,火甲反,目标)},提示={允许=false}}
    end
  end

  if 目标~=nil and self:取奇经八脉是否有(目标,"养生") and self.参战单位[目标].气血<=qz(self.参战单位[目标].最大气血*0.5) and self.参战单位[目标].法术状态.生命之泉==nil then
  self:添加状态("生命之泉",self.参战单位[目标],self.参战单位[目标],self.参战单位[目标].等级,目标)
  self.战斗流程[#self.战斗流程].挨打方[1].添加状态="生命之泉"
  end

  if self.参战单位[目标].法术状态.波澜不惊~=nil and 伤害>1 and self.参战单位[目标].气血>0 then
  local 血量=qz(伤害*1)
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="波澜不惊"
  end

  if 目标~=nil and self:取奇经八脉是否有(目标,"不舍") and 伤害值.伤害>qz(self.参战单位[目标].最大气血*0.2) and self.参战单位[目标].气血>=1 then
  local 血量=qz(self.参战单位[目标].等级+10)*2
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="归元咒"
  end

  if self.参战单位[目标].法术状态.移魂化骨~=nil and 目标~=nil and self:取奇经八脉是否有(目标,"噬魂") and 取随机数()<=40 then
  local 血量=math.floor(伤害值.伤害*0.5)
  self:增加气血(目标,血量)
  self.战斗流程[#self.战斗流程].挨打方[1].恢复气血=血量
  self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="地涌金莲"
  end

  local 反震=self.参战单位[目标].反震
  local 反击=self:取是否反击(编号,目标)
 --local 反击=1
 --local 反震=0.25
  if self.参战单位[编号].偷袭==nil and 反震~=nil and 取随机数()<=30 and 保护==false then --触发反震 有保护的情况下不会触发反震、反击
      local 反震伤害=math.floor(伤害值.伤害*反震)
      if 反震伤害<=0 then
         反震伤害=1
         end
    if self.参战单位[目标].反震1 ==nil then
      self.参战单位[目标].反震1=0
    end
    local 反震伤害1=self.参战单位[目标].反震1
       self.战斗流程[#self.战斗流程].反震伤害=反震伤害 + 反震伤害1
       -- self.战斗流程[#self.战斗流程].反震伤害=反震伤害
       self.战斗流程[#self.战斗流程].反震死亡=self:减少气血(编号,反震伤害,目标)
       self.战斗流程[#self.战斗流程].挨打方[1].特效[#self.战斗流程[#self.战斗流程].挨打方[1].特效+1]="反震"
       self.执行等待=self.执行等待+2
  elseif 反击~=nil and self:取行动状态(目标) and self.参战单位[编号].偷袭==nil and 保护==false then
    local 反击伤害=math.floor(self:取基础物理伤害(目标,编号)*反击)
    if 反击伤害<=0 then 反击伤害=1 end
    self.战斗流程[#self.战斗流程].反击伤害=反击伤害
    self.战斗流程[#self.战斗流程].反击死亡=self:减少气血(编号,反击伤害,目标)
    self.执行等待=self.执行等待+2
  end

  if 最终伤害.暴击 ~= nil then
    必杀 = true
  end
  if 必杀 and self.参战单位[编号].怒击效果 then
    return true
  end
  if self.参战单位[编号].法术状态.诡蝠之刑~=nil then
    if self:取目标状态(编号,编号,2) then
      local 气血=qz(伤害值.伤害*0.1)
      if 气血<=1 then
        气血=1
      end
      self.战斗流程[#self.战斗流程+1]={流程=102,攻击方=编号,气血=0,挨打方={}}
      self.战斗流程[#self.战斗流程].死亡=self:减少气血(编号,气血)
      self.战斗流程[#self.战斗流程].气血=气血
    end
  end
end

function 战斗处理类:取是否反击(编号,目标)
  if self.参战单位[目标].法术状态.魔王回首~=nil or self.参战单位[编号].法术状态.诱袭~=nil or  self.参战单位[目标].法术状态.极度疯狂~=nil or (self.参战单位[目标].反击 ~= nil and 取随机数()<=30) then
  	if self.参战单位[目标].气血 > 0 then
  		return 1
    end
  end
  return nil
end

function 战斗处理类:增加魔法(编号,数额)
  if self.参战单位[编号].法术状态.魔音摄魂~=nil then
      self:添加提示(self.参战单位[编号].玩家id,编号,"#Y/你当前状态无法恢复魔法!")
      return
  end
  self.参战单位[编号].魔法=self.参战单位[编号].魔法+数额
  if self.参战单位[编号].魔法>self.参战单位[编号].最大魔法 then
     self.参战单位[编号].魔法=self.参战单位[编号].最大魔法
  end
end

function 战斗处理类:增加气血(编号,数额)
  self.参战单位[编号].气血=self.参战单位[编号].气血+数额
  if self.参战单位[编号].气血>self.参战单位[编号].最大气血 then
    self.参战单位[编号].气血=self.参战单位[编号].最大气血
  end
end

function 战斗处理类:恢复伤势(编号,数额)
  if self.参战单位[编号].类型~="角色" then
    return
  end
  if self.参战单位[编号].助战编号 ~= nil then
    return
  end
  self.参战单位[编号].气血上限=self.参战单位[编号].气血上限+数额
  if self.参战单位[编号].气血上限>self.参战单位[编号].最大气血 then
    self.参战单位[编号].气血上限=self.参战单位[编号].最大气血
  end
end

function 战斗处理类:添加即时发言(编号,文本)
  for n=1,#self.参战玩家 do
    发送数据(self.参战玩家[n].连接id,5512,{id=编号,文本=文本})
  end
end

function 战斗处理类:添加危险发言(编号,类型)
  if self.参战单位[编号].队伍~=0 then
    local 已发言=false
    for n=1,#self.参战单位 do
      if 已发言==false and self.参战单位[n].队伍==self.参战单位[编号].队伍 then
        if self.参战单位[n].预知特性~=nil  then
          if self.参战单位[n].预知次数<3 and self.参战单位[n].预知特性*7>=取随机数() then
            self.参战单位[n].预知次数=self.参战单位[n].预知次数+1
            self.战斗发言数据[#self.战斗发言数据+1]={id=n,内容=self:取危险发言内容(self.参战单位[编号].名称,类型)}
            已发言=true
          end
        end
      end
    end
    for n=1,#self.参战玩家 do
      for i=1,#self.战斗发言数据 do
        发送数据(self.参战玩家[n].连接id,5512,{id=self.战斗发言数据[i].id,文本=self.战斗发言数据[i].内容})
      end
    end
    self.战斗发言数据 = {}
  end

end

function 战斗处理类:取危险发言内容(名称,类型)
  local 发言内容={}
  if 类型==1 then --死亡
    发言内容={format("#G/%s#W我的直觉告诉我你活不过本回合#74",名称),format("让我们高歌欢舞恭送#G/%s#83",名称),format("唢呐吹起来，锣鼓敲起来，我们的#G/%s#W/倒下来#42",名称)}
  elseif 类型==2 then --重伤
    发言内容={format("#G/%s#W看起来伤势很重啊#52",名称),format("#G/%s#W你再不注意加血，当心我在你坟头上蹦迪哈#24",名称),format("#G/%s#W/你是长相有问题还是内心太黑暗呢#55",名称)}
  end
  return 发言内容[取随机数(1,#发言内容)]
end

function 战斗处理类:造成伤势(编号,数额)
  if self.参战单位[编号].类型~="角色" then
    return
  end
  if self.参战单位[编号].助战编号 ~= nil then
    return
  end
	self.参战单位[编号].气血上限=self.参战单位[编号].气血上限-数额
	if self.参战单位[编号].气血上限 <= 0 then
		self.参战单位[编号].气血上限 = 0
	end
end
function 战斗处理类:减少气血(编号,数额,攻击,名称)
    self.参战单位[编号].气血=self.参战单位[编号].气血-数额
    if self.参战单位[编号].气血<=self.参战单位[编号].最大气血*0.2 then
      self:添加危险发言(编号,2)
    end
    if self.参战单位[编号].类型=="角色" or self.参战单位[编号].类型=="系统PK角色" then
      local 临时愤怒=qz(数额/self.参战单位[编号].最大气血*0.5*100)
      if self.参战单位[编号].暴怒腰带 ~= nil then
        临时愤怒=临时愤怒 + math.floor(临时愤怒*0.25)
      end
      self.参战单位[编号].愤怒=self.参战单位[编号].愤怒+临时愤怒
      if self.参战单位[编号].愤怒>150 then
        self.参战单位[编号].愤怒=150
      end
    end
      if 编号~=nil and self:取奇经八脉是否有(编号,"忍辱") then
      self.参战单位[编号].愤怒=self.参战单位[编号].愤怒+6
      if self.参战单位[编号].愤怒 > 150 then
        self.参战单位[编号].愤怒 = 150
      end
  end
    if 编号~=nil and self:取奇经八脉是否有(编号,"心浪") and self.参战单位[编号].愤怒 ~= nil then
      self.参战单位[编号].愤怒 = self.参战单位[编号].愤怒 + 取随机数(5,15)
      if self.参战单位[编号].愤怒 >= 150 then
        self.参战单位[编号].愤怒 = 150
      end
    end
    if self.参战单位[编号].气血<=0 then
      self:添加危险发言(编号,1)
      self.执行等待=self.执行等待+5
      self.参战单位[编号].气血=0
	    self:造成伤势(编号,99999999)
      if self.战斗脚本 and self.战斗脚本.单位死亡 then
        __gge.safecall(self.战斗脚本.单位死亡,self,编号)
      end
      if  self.参战单位[编号].同门单位 then
        self.同门死亡=true
      end
      if self.参战单位[编号].类型=="角色" or self.参战单位[编号].类型=="系统PK角色" then
        self:设置复仇对象(编号,攻击)
        self.参战单位[编号].愤怒=0
        return 2
      else
        if self.参战单位[编号].鬼魂==nil then
          -- 修复血债偿
          for n=1,#self.参战单位 do
            if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self.参战单位[编号].血债偿==nil and self.参战单位[n].血债偿~=nil then
              if self.参战单位[n].血债偿 > 0 then
                self.参战单位[n].法术伤害结果 = self.参战单位[n].法术伤害结果 + self.参战单位[n].血债偿
              end
            end
          end
          return 1
        else
          if 攻击==nil and 名称==nil then
            self.参战单位[编号].法术状态.复活={回合=self.参战单位[编号].鬼魂}
            return 2
          elseif self.参战单位[攻击].法术状态.灵断~=nil then
            return 1
          elseif 名称=="五雷咒" or 名称=="落雷符" then
            return 1
          elseif self:取符石组合效果(攻击,"风卷残云") and 取随机数()<=self:取符石组合效果(攻击,"风卷残云") then
                return 1
          elseif 攻击==nil then
            self.参战单位[编号].法术状态.复活={回合=self.参战单位[编号].鬼魂}
            return 2
          elseif self.参战单位[攻击].驱鬼~=nil or self.参战单位[攻击].法术状态.钟馗论道~=nil then
            return 1
          else
            self.参战单位[编号].法术状态.复活={回合=self.参战单位[编号].鬼魂}
            return 2
          end
        end
    end
  else
    return
  end
end
function 战斗处理类:设置复仇对象(编号,攻击)
  local id=self.参战单位[编号].召唤兽
  if id==nil or id==0 or self.参战单位[id]==nil then
    return
  elseif self.参战单位[id].复仇特性~=nil and  self.参战单位[id].复仇特性*20>=取随机数(1,10) then
    self.参战单位[id].复仇标记=攻击
  end

end

function 战斗处理类:取可否防御(挨打方)
 if self.参战单位[挨打方].法术状态.横扫千军~=nil or self.参战单位[挨打方].法术状态.催眠符~=nil or self.参战单位[挨打方].法术状态.楚楚可怜~=nil or self.参战单位[挨打方].法术状态.破釜沉舟~=nil then
     return false
    else
     return true
   end
end

function 战斗处理类:取最终物理伤害(攻击方,挨打方,伤害)
 local 特效={}
 local 动作="挨打"
 local 暴击 = nil

  if self.参战单位[挨打方].指令.类型=="防御" and self:取行动状态(挨打方) and self:取可否防御(挨打方) then
      伤害=伤害*0.5
      动作="防御"
      特效[#特效+1]="防御"
  end
  if self.参战单位[挨打方].指令.类型~="防御" and self:取行动状态(挨打方)  and self.参战单位[挨打方].招架~=nil and self.参战单位[挨打方].招架>0 then

      伤害=qz((100-self.参战单位[挨打方].招架)/100*伤害)

    if  self.参战单位[挨打方].招架==10 then
      self.参战单位[挨打方].招架=-1
    else
      self.参战单位[挨打方].招架=-2
    end
  end

  local 必杀几率=1
  必杀几率=必杀几率+(self.参战单位[攻击方].物理暴击等级-self.参战单位[挨打方].抗物理暴击等级)*0.1

  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"轻霜") and self.参战单位[挨打方].法术状态.毒 then
       必杀几率=必杀几率+50
     end
  if self.参战单位[攻击方].必杀~=nil then
      必杀几率=必杀几率+self.参战单位[攻击方].必杀
  end
  if self.参战单位[挨打方].幸运~=nil then
      必杀几率=必杀几率*self.参战单位[挨打方].幸运
  end
  if 必杀几率>=取随机数() then
    if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"杀意") then
        伤害=伤害*1.03
    end
    伤害=伤害*2
    特效[#特效+1]="暴击"
    暴击=true
    if self.参战单位[攻击方].狂怒~=nil then
      伤害 = 伤害 +self.参战单位[攻击方].狂怒
    end
    特效[#特效+1]="暴击"
    暴击=true
  end

  if 暴击==nil and self.参战单位[攻击方].狂暴等级>=取随机数(1,2000) then
    伤害=qz(伤害*1.5)
  end

  if  self.参战单位[攻击方].指令.参数=="高级连击" and self.参战单位[攻击方].阴伤~=nil then
    伤害=伤害+self.参战单位[攻击方].阴伤
  end
   if self.参战单位[攻击方].无畏 ~= nil and self.参战单位[挨打方].反震 ~= nil then
    伤害 = 伤害*self.参战单位[攻击方].无畏
  end
 if self.参战单位[攻击方].愤恨 ~= nil and self.参战单位[挨打方].幸运 ~= nil then
    伤害 = 伤害*self.参战单位[攻击方].愤恨
  end

  if self:取符石组合效果(挨打方,"点石成金") and 取随机数(1,100)<=5 then
     伤害=qz(伤害*(100-self:取符石组合效果(挨打方,"点石成金"))/100)
      动作="防御"
      特效[#特效+1]="点石成金"
     end

 if self.参战单位[挨打方].鬼魂~=nil and self.参战单位[攻击方].驱鬼 then
       伤害=伤害*self.参战单位[攻击方].驱鬼
   end

 if self.参战单位[挨打方].法术状态.天地同寿~=nil then
   伤害=伤害*1.5
   end
 if self.参战单位[挨打方].玉砥柱 ~= nil and (self.参战单位[攻击方].指令.参数 == "壁垒击破" or self.参战单位[攻击方].指令.参数 == "力劈华山"
  or self.参战单位[攻击方].指令.参数 == "善恶有报" or self.参战单位[攻击方].指令.参数 == "剑荡四方" or self.参战单位[攻击方].指令.参数 == "惊心一剑") then
    伤害 = 伤害*(1-self.参战单位[挨打方].玉砥柱)
  end

  伤害=伤害-self.参战单位[挨打方].格挡值
  if self.参战单位[挨打方].物伤减少~=nil then
      伤害=伤害*self.参战单位[挨打方].物伤减少
     end
  local 境界=self:取指定法宝境界(挨打方,"金甲仙衣") or 0
    if 境界 then
      local 触发几率=境界*2 --9层:18%
      if 取随机数(1,100) <= 触发几率 then
        if self:取指定法宝(挨打方,"金甲仙衣",1) then
          local 境界=self:取指定法宝境界(挨打方,"金甲仙衣")
          local 减伤效果=0.9-境界*0.05
          伤害=qz(伤害*减伤效果)
          特效[#特效+1]="金甲仙衣"
        end
      end
    end
  ------------
  local 境界=self:取指定法宝境界(挨打方,"蟠龙玉璧") or 0
    if 境界 then
      local 触发几率=境界*2+17 --9层:28%
      if 取随机数(1,100) <= 触发几率 then
        if self:取指定法宝(挨打方,"蟠龙玉璧",1) then
          local 境界=self:取指定法宝境界(挨打方,"蟠龙玉璧")
          local 减伤效果=1.0-境界*0.025
          伤害=qz(伤害*减伤效果)
          特效[#特效+1]="金甲仙衣"
        end
      end
    end
    ---------
    if self:取符石组合效果(挨打方,"暗渡陈仓") then
      伤害=伤害*(1-self:取符石组合效果(挨打方,"暗渡陈仓")/100)
    end
    if self.参战单位[挨打方].类型=="bb" and self.参战单位[挨打方].内丹~=nil then
   local 内丹1={}
   for n=1,#self.参战单位[挨打方].内丹 do
     内丹1[n]=self.参战单位[挨打方].内丹[n]
   end
  for i=1,#内丹1 do
    local 等级 = 内丹1[i].等级
    local 技能 = 内丹1[i].技能
    if 技能=="腾挪劲" then
        local 触发几率=等级*4
        if 取随机数(1,100) <= 触发几率 then
          伤害=qz(伤害*0.5)
          特效[#特效+1]="腾挪劲"
          end
      elseif 技能=="灵身" then
          伤害=qz(伤害*1.5)
      end
    end
  end
  if self.参战单位[攻击方].撞击~=nil and self.参战单位[攻击方].撞击>0 then
    伤害=qz(伤害+5*self.参战单位[攻击方].撞击)
  end

  if self.参战单位[攻击方].舍身击~=nil and self.参战单位[攻击方].舍身击>0 then
    伤害=qz(伤害+(self.参战单位[攻击方].力量-self.参战单位[攻击方].等级)*0.05*self.参战单位[攻击方].舍身击)
  end

  if self.参战单位[挨打方].法术状态.爪印~=nil and self.参战单位[挨打方].法术状态.爪印.层数~=nil then
    伤害=qz(伤害+0.7*self.参战单位[攻击方].等级*self.参战单位[挨打方].法术状态.爪印.层数)
  end

  if self:取指定法宝(攻击方,"天煞",1,1) and self.参战单位[攻击方].门派=="凌波城" then
    伤害=伤害+qz(self:取指定法宝境界(攻击方,"天煞")*30)
  end

  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"妖气") and self.参战单位[挨打方].法术状态.天罗地网 then
  伤害=伤害+qz(伤害*0.18)
  end

  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"意乱") and self.参战单位[挨打方].法术状态.魔音摄魂 then
  伤害=伤害+qz(伤害*0.28)
  end

  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"怜心") and 取随机数(1,100)<=50 then
  伤害=伤害*2
  end

  if self.参战单位[攻击方]~=nil and self.参战单位[攻击方].数字id~=nil and self.参战单位[攻击方].类型=="角色" then
      玩家数据[self.参战单位[攻击方].数字id].角色:耐久处理(self.参战单位[攻击方].数字id,1)
  end

  if self.参战单位[挨打方]~=nil and self.参战单位[挨打方].数字id~=nil and self.参战单位[挨打方].类型=="角色" then
      玩家数据[self.参战单位[挨打方].数字id].角色:耐久处理(self.参战单位[挨打方].数字id,2)
  end
  if self.参战单位[挨打方]~=nil and self.参战单位[挨打方].玩家id~=nil and self.参战单位[挨打方].玩家id~=0 and self.参战单位[挨打方].类型=="bb" and self.参战单位[挨打方].分类~="野怪" then
      玩家数据[self.参战单位[挨打方].玩家id].召唤兽:耐久处理(self.参战单位[挨打方].玩家id,self.参战单位[挨打方].认证码)
  end
 return {伤害=qz(伤害),动作=动作,特效=特效,暴击=暴击}
end

function 战斗处理类:取灵力伤害(攻击方,挨打方)
  local 防御基数=1
  local 修炼差 = 1+ ((1+攻击方.法术修炼*0.025) - (1+挨打方.抗法修炼*0.025))
  local ls = 0

  local lsll = 0
  if 攻击方.指令.参数=="魔火焚世" then
    lsll = 攻击方.灵力*0.2
  end

  if  攻击方.类型 == "角色" and 攻击方.法伤== nil then
    攻击方.法伤 = 攻击方.灵力
  end

  if 攻击方.类型 == "角色" then
   伤害=((攻击方.法伤+lsll+攻击方.法术伤害)-挨打方.法防*防御基数)*修炼差
  else
   伤害=((攻击方.灵力+lsll+攻击方.法术伤害)-挨打方.法防*防御基数)*修炼差
  end
  伤害=qz(伤害*self:取抗法特性(挨打方.队伍))

  if 挨打方.抗物特性~=nil then
    伤害=qz(伤害*(1+(挨打方.抗物特性*4+14)/100))
  end
  if 攻击方.弑神特性~=nil and 挨打方.神佑效果~=nil then
    伤害=qz(伤害*(1+(攻击方.弑神特性*4+5)/100))
  end
  if 攻击方.顺势特性~=nil  then
    if  挨打方.气血<=挨打方.最大气血*0.7 then
      伤害=qz(伤害*(1+(攻击方.顺势特性*30+60)/1000))
    else
      伤害=qz(伤害*0.9)
    end
  end

  if 攻击方.法术状态.灵法~=nil then
    if 攻击方.特性几率 ~= nil then
      伤害=伤害 + 伤害*(攻击方.特性几率*5/100)
    end
  end
    if 攻击方.魔之心~=nil then
    伤害=伤害*攻击方.魔之心
  end
  if 攻击方.法术状态.龙魂 ~= nil then
    伤害=伤害*1.02
  end
  if 挨打方.法伤减少~=nil then
    伤害=伤害*挨打方.法伤减少
  end
  if self:取符石组合效果(挨打方,"化敌为友") then
    伤害=伤害*(1-self:取符石组合效果(挨打方,"化敌为友")/100)
  end
  if 挨打方.狂怒 ~= nil and (攻击方.指令.参数=="水漫金山" or 攻击方.指令.参数=="泰山压顶" or 攻击方.指令.参数=="落岩" or 攻击方.指令.参数=="水攻" )then
    伤害 = 伤害+qz(伤害*0.15)
  elseif 挨打方.阴伤 ~= nil and (攻击方.指令.参数=="地狱烈火" or 攻击方.指令.参数=="奔雷咒" or 攻击方.指令.参数=="雷击" or 攻击方.指令.参数=="烈火" )then
    伤害 = 伤害+qz(伤害*0.15)
  elseif 挨打方.钢化 ~= nil then
    伤害 = 伤害+qz(伤害*0.1)
  end

  if 攻击方.名称 == "酒肉和尚帮凶 " and 攻击方.指令.参数=="唧唧歪歪" and self.战斗类型==100223 and self.回合数>=30 then
    伤害 = 伤害*10
  end

  if 攻击方.通灵法~=nil then
    伤害=伤害+qz(挨打方.灵力*0.04*攻击方.通灵法)
  end

  -- if self:取玩家战斗() then--减伤
  --   if 挨打方.类型~="角色" and 攻击方.类型~="角色" then--法系宠物打宠物
  --     伤害 = 伤害 * 0.6
  --     elseif 挨打方.类型=="角色" and 攻击方.类型~="角色" then--法系宠物打人物
  --     伤害 = 伤害 * 0.6
  --     elseif 挨打方.类型=="角色" and 攻击方.类型=="角色" then--法系人物打人物
  --     伤害 = 伤害 * 0.4
  --   end
  -- end


  if self:取符石组合效果(攻击方,"隔山打牛") and 取随机数()<= 20 then
      伤害 = 伤害 + self:取符石组合效果(攻击方,"隔山打牛")
  end

  if self:取符石组合效果(挨打方,"云随风舞") and 取随机数()<= 20 then
    伤害 = 伤害 - self:取符石组合效果(挨打方,"云随风舞")
  end

    if 伤害<=1 then
      伤害 = 1
    end

  伤害=伤害*取随机数(90,110)/100
  -- 伤害=伤害*0.4 ---这里是降低法术伤害20%  请随易
  return qz(伤害*取随机数(90,110)/100)
end

function 战斗处理类:取伤害结果(攻击方,挨打方,伤害,暴击,保护)
  local 类型=1
  if self.参战单位[攻击方].队伍==0 then
  end

  if self.参战单位[攻击方].玄武躯~=nil or self.参战单位[攻击方].龙胄铠~=nil then
     伤害=伤害*0.5
  end
  if self.参战单位[攻击方].玉砥柱~=nil then
     伤害=伤害*0.8
  end
  if 暴击~=nil then
      类型=3
  end
  -- if self:取符石组合效果(攻击方,"云随风舞") then
  --   print("有了")
  -- end
  if self:取符石组合效果(攻击方,"降妖伏魔") and  self.参战单位[挨打方].鬼魂~=nil then
      伤害 = qz(伤害 * ( 1 + self:取符石组合效果(攻击方,"降妖伏魔")/100))
  end

  if 保护~=true and self.参战单位[挨打方].鬼魂==nil and  self.参战单位[挨打方].神佑~=nil and self.参战单位[攻击方].法术状态.灵断==nil and 伤害>=self.参战单位[挨打方].气血 then
      if self.参战单位[挨打方].神佑>=取随机数() then
         伤害=self.参战单位[挨打方].最大气血-self.参战单位[挨打方].气血
         类型=2
         self.参战单位[挨打方].神佑效果=true
      end
  end
  if 类型~=2 then
    if self.参战单位[挨打方].法术状态.炎护~=nil then
      local 临时伤害=qz(伤害*0.5)
      if 临时伤害>1 then
        if self.参战单位[挨打方].魔法>临时伤害 then
          self.参战单位[挨打方].魔法=self.参战单位[挨打方].魔法-临时伤害
          临时伤害=0
        else
          临时伤害=临时伤害-self.参战单位[挨打方].魔法
          self.参战单位[挨打方].魔法=0
        end
        伤害=qz(伤害*0.5)+临时伤害
      end
    end
    if self.参战单位[挨打方].法术状态.苍白纸人~=nil then
      伤害=qz(伤害*(1-self.参战单位[挨打方].法术状态.苍白纸人.境界*0.04))
    elseif self.参战单位[挨打方].法术状态.五彩娃娃~=nil then
      伤害=qz(伤害*(1-self.参战单位[挨打方].法术状态.五彩娃娃.境界*0.025))
    end
    if self.参战单位[挨打方].法术状态.护佑 ~= nil then
      伤害=qz(伤害*0.5)
    end
    if self:取指定法宝(挨打方,"奇门五行令",1,1) then
      local 境界=self:取指定法宝境界(挨打方,"奇门五行令")
      local 伤害比=0.6+self.参战单位[挨打方].气血/self.参战单位[挨打方].最大气血
      伤害比=伤害比-(0.04*境界)
      伤害=qz(伤害*伤害比)
    elseif self:取指定法宝(挨打方,"失心钹",1,1) and self.参战单位[攻击方].队伍~=0 and self.参战单位[攻击方].类型~="角色" then
      local 境界=self:取指定法宝境界(挨打方,"失心钹")
      伤害=伤害-境界*15
    end
    if self.参战单位[挨打方].法术状态.诸天看护~=nil then
    伤害=qz(伤害*0.8)
    end
    if self.参战单位[挨打方].法术状态.同舟共济~=nil then
    伤害=qz(伤害*0.5)
    end
    if self.参战单位[攻击方].法术状态.冰川怒伤 ~= nil then
    伤害=qz(伤害*0.9)
    end
    if self.参战单位[挨打方].法术状态.魑魅缠身 ~= nil then
    伤害=qz(伤害*1.08)
    end
    if self.参战单位[挨打方].法术状态.绝殇 ~= nil then
    伤害=qz(伤害*1.02)
    end
    if self.参战单位[挨打方].法术状态.催眠符~=nil and self.参战单位[挨打方].法术状态.催眠符.黄粱 then
    伤害=qz(伤害*1.1)
    end
    if self.参战单位[挨打方].法术状态.摄魂~=nil then
    伤害=qz(伤害*(1+self.参战单位[挨打方].法术状态.摄魂.境界*0.02+0.1))
    end
    if 挨打方~=nil and self:取奇经八脉是否有(挨打方,"鬼念") and self.参战单位[攻击方].鬼魂~=nil then
    伤害=qz(伤害*0.5)
    end
    if 挨打方~=nil and self:取奇经八脉是否有(挨打方,"批亢") and self.参战单位[挨打方].分身术~=nil then
    伤害=qz(伤害*0.85)
    end
    if 挨打方~=nil and self:取奇经八脉是否有(挨打方,"脱壳") and 取随机数(1,100)<=10 then
    伤害=qz(伤害*0.1)
    end
    if 挨打方~=nil and self:取奇经八脉是否有(挨打方,"天香") then
    伤害=qz(伤害*0.8)
    end
    if self.参战单位[攻击方].法术状态.钟馗论道~=nil and self.参战单位[挨打方].鬼魂~=nil then
    伤害=qz(伤害*1.5)
    end

    if self.参战单位[攻击方].法术状态.灵刃~=nil then
      if self.参战单位[挨打方].鬼魂~=nil or self.参战单位[挨打方].神佑~=nil then
        伤害=qz(伤害*1.1)
      else
        伤害=qz(伤害*1.5)
      end
    end
  end
  -- if self.参战单位[挨打方].类型~=nil then
  --   伤害=1
  -- end


      if 挨打方~=nil and self:取奇经八脉是否有(挨打方,"化怨") and self.参战单位[挨打方].气血<=self.参战单位[挨打方].最大气血*0.3 then
        伤害=伤害*0.85
      elseif 挨打方~=nil and self:取奇经八脉是否有(挨打方,"风墙") then
      伤害=伤害*0.8
      elseif 攻击方~=nil and self:取奇经八脉是否有(攻击方,"伏魔") and self.参战单位[挨打方].类型=="bb" then
      伤害=伤害*1.02
    end

    if 挨打方~=nil and self:取符石组合效果(挨打方,"真元护体") then
       伤害=qz(伤害*(100-self:取符石组合效果(挨打方,"真元护体"))/100)
    end


  if self.参战单位[攻击方].法术状态.修罗隐身 ~= nil  then
    local 隐身伤害系数 = 0.6
    if self.参战单位[攻击方].隐匿击~=nil and self.参战单位[攻击方].隐匿击>0 then
      隐身伤害系数 = 隐身伤害系数 + 0.02 * self.参战单位[攻击方].隐匿击
    end
    伤害 = 伤害 * 隐身伤害系数
  end

  if self.参战单位[挨打方].移花接木 ~= nil  then
    伤害 = 伤害 * 0.7
  end

  if self:取玩家战斗()== false then
  if self.参战单位[攻击方].心源 ~= nil and 取随机数(1,200)<= self.参战单位[攻击方].心源 then
    伤害 = 伤害 * 2
  end
 end

    if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"突进") and 取随机数(1,100)<=20 then
        伤害=伤害*1.1
    end

  if 攻击方~=nil and self.参战单位[攻击方].气血>self.参战单位[挨打方].气血 and self:取奇经八脉是否有(攻击方,"纯青") then
    伤害 = 伤害*1.1
  end

  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"攻云")  then
    伤害=qz(伤害*1.4)
  end

  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"愈勇") then
    伤害=qz(伤害*1.02)
    self.参战单位[攻击方].防御=qz(self.参战单位[攻击方].防御*1.02)
  end
  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"斗志") then
    伤害=qz(伤害*1.06)
  end
  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"伏妖") then
    伤害=qz(伤害+self.参战单位[攻击方].力量*0.1+40)
  end
  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"战神") then
    伤害=qz(伤害*1.08)
  end

  伤害 = 伤害*(1+self:取阵法克制(攻击方,挨打方))
  if self.参战单位[挨打方].气血<=self.参战单位[挨打方].最大气血*0.3 and 攻击方~=nil and self:取奇经八脉是否有(攻击方,"汲魂") then
  self:添加状态("汲魂",self.参战单位[攻击方],self.参战单位[攻击方],self.参战单位[攻击方].等级,攻击方)
  self.战斗流程[#self.战斗流程].添加状态="汲魂"
  end

    -- if 挨打方~=nil and self:取奇经八脉是否有(挨打方,"抗击") and 伤害>=math.floor(self.参战单位[挨打方].最大气血*0.1) and 取随机数(1,100)<=12 and self.参战单位[挨打方].战意<6 then
    --   self.参战单位[挨打方].战意=self.参战单位[挨打方].战意+1
    -- end

  if 挨打方~=nil and self:取奇经八脉是否有(挨打方,"苏醒") and 伤害>=math.floor(self.参战单位[挨打方].最大气血*0.4) then  --math.floor(self.参战单位[挨打方].最大气血*0.4)
    local 异常封印法术 = self:解除状态结果(self.参战单位[挨打方],self:取异常封印法术状态())
    if not 判断是否为空表(异常封印法术) then
      self:取消状态(异常封印法术[1],self.参战单位[挨打方])
      for k=1,#self.战斗流程[#self.战斗流程].挨打方 do
        if self.战斗流程[#self.战斗流程].挨打方[k].挨打方==挨打方 then
          self.战斗流程[#self.战斗流程].挨打方[k].取消状态=异常封印法术[1]
          self.战斗流程[#self.战斗流程].挨打方[k].额外特效="宁心"
        end
      end
    end
  end

  return {伤害=math.floor(伤害),类型=类型}
end


function 战斗处理类:取基础物理伤害(攻击方,挨打方)
  local 修炼差 = 1+ ((1+self.参战单位[攻击方].攻击修炼*0.025) - (1+self.参战单位[挨打方].防御修炼*0.025))
  local 防御=(self.参战单位[挨打方].防御)+(self.参战单位[挨打方].防御修炼*5)
  -- 防御 = 防御-(防御*(self.参战单位[攻击方].穿刺等级*0.005))
  -- 0914 七杀无视防御修改
  if self:取指定法宝(攻击方,"七杀",1,1) then
    防御=防御-qz(self:取指定法宝境界(攻击方,"七杀",1,1)*0.02*防御)
  end
   local 伤害=self.参战单位[攻击方].伤害 +(self.参战单位[攻击方].攻击修炼*5)
  if 修炼差>=1.5 then
    修炼差=1.5
  end
  if self:取符石组合效果(攻击方,"天降大任") and  self.参战单位[挨打方].类型=="bb" then
      防御 = qz(防御 * ( 1 - self:取符石组合效果(攻击方,"天降大任") / 100))
    end
  local 伤害补偿 = 0
  if self:取符石组合效果(攻击方,"百步穿杨") and 取随机数()<=20 then
    伤害 = qz(伤害 + self:取符石组合效果(攻击方,"百步穿杨"))
  end
  if self:取符石组合效果(挨打方,"心随我动") and 取随机数()<=20 then
    伤害 = qz(伤害 - self:取符石组合效果(挨打方,"心随我动"))
    if 伤害<=1 then
      伤害 =1
    end
  end
  if self.参战单位[攻击方].力破特性~=nil  then
    if self.参战单位[挨打方].类型=="角色" then
      防御=防御-(self.参战单位[攻击方].力破特性*40+40)
      if 防御 <= 0 then
        防御 = 0
      end
    else
        防御 = qz(防御*1.05)
    end
  end
  local 伤害力=math.max(伤害-防御,伤害*0.1)
  local 攻击力=伤害力+(伤害力*伤害力/3000)*取随机数(90,110)/100
  local 结果=攻击力*修炼差
  if self.参战单位[攻击方].争锋特性~=nil  then
    if self.参战单位[挨打方].类型~="角色" then
      结果=qz(结果*(self.参战单位[攻击方].争锋特性*0.08+1))
    else
      结果=qz(结果*0.9)
    end
  end
  if 昼夜参数==1 and self.参战单位[攻击方].夜战~=2 and self.参战单位[攻击方].夜战~=1 and self.参战单位[攻击方].门派~="阴曹地府" then
    结果=结果*0.8
  end

  if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"致命") and 取随机数(1,100) <= 1 then
    结果 = 结果 * 3
  end

   if 攻击方~=nil and self:取奇经八脉是否有(攻击方,"锤炼") then
        结果=结果+self.参战单位[攻击方].伤害*0.04
    elseif 攻击方~=nil and self:取奇经八脉是否有(攻击方,"神附") then
        结果=结果+self.参战单位[攻击方].力量*0.08
    end

  --   if self:取玩家战斗() then
  --   if self.参战单位[挨打方].类型~="角色" and self.参战单位[攻击方].类型~="角色" then--攻宠打宠物
  --     结果 = 结果 * 0.3
  --     elseif self.参战单位[挨打方].类型=="角色" and self.参战单位[攻击方].类型~="角色" then--攻宠打人物
  --     结果 = 结果 * 0.6
  --     elseif self.参战单位[攻击方].门派=="凌波城" or (self.参战单位[挨打方].类型=="角色" and self.参战单位[攻击方].类型=="角色") then--降低凌波城伤害
  --     结果 = 结果 * 0.4
  --   end
  -- end
  if self.参战单位[攻击方].物理加成~=nil then
    结果=qz(结果*self.参战单位[攻击方].物理加成)
  end

  if self.参战单位[攻击方].从天而降 ~= nil and 取随机数() <= 50 then
    结果=qz(结果*1.3)
  end

  if self.参战单位[攻击方].驱怪~=0 and self.参战单位[挨打方].鬼魂 ~= nil then
    结果=结果*1.1
  end

  return math.floor(结果)
end

function 战斗处理类:取抗法特性(队伍)
  if 队伍==0 then
    return 1
  end
  local 基础抗性=1
  for n=1,#self.参战单位 do
    if self.参战单位[n].抗法特性~=nil then
      local 基础=3+self.参战单位[n].特性几率*5
      基础=1-基础/100
      if 基础<基础抗性 then 基础抗性=基础 end
    end
  end
  return 基础抗性
end

function 战斗处理类:取抗物特性(队伍)
  if 队伍==0 then
    return 1
  end
  local 基础抗性=1
  for n=1,#self.参战单位 do
    if self.参战单位[n].抗物特性~=nil then
      local 基础=3+self.参战单位[n].抗物特性*5
      基础=1-基础/100
      if 基础<基础抗性 then
        基础抗性=基础
      end
    end
  end
  return 基础抗性
end

function 战斗处理类:取单个敌方目标(编号)
  local 目标组={}
  for n=1,#self.参战单位 do
     if  self.参战单位[n].队伍~=self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
         目标组[#目标组+1]=n
     end
     end
  if #目标组==0 then
     return 0
    else
     return 目标组[取随机数(1,#目标组)]
  end
end

function 战斗处理类:取单个友方目标(编号,是否)
  local 目标组={}
  for n=1,#self.参战单位 do
    if 是否 ~= nil then
       if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
           目标组[#目标组+1]=n
       end
    else
       if n~=编号 and self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
           目标组[#目标组+1]=n
       end
    end
  end
  if #目标组==0 then
     return 0
  else
     return 目标组[取随机数(1,#目标组)]
  end
end
function 战斗处理类:取单个存活友方目标(编号,是否)
  local 目标组={}
  for n=1,#self.参战单位 do
    if 是否 ~= nil then
       if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
           目标组[#目标组+1]=n
       end
    else
       if n~=编号 and self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
           目标组[#目标组+1]=n
       end
    end
  end
  if #目标组==0 then
     return 0
  else
     return 目标组[取随机数(1,#目标组)]
  end
end
function 战斗处理类:取单个友方目标1(编号,是否)
  local 目标组={}
  for n=1,#self.参战单位 do
    if 是否 ~= nil then
       if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态(编号,n,1) then
           目标组[#目标组+1]=n
       end
    else
       if self.参战单位[n].队伍==self.参战单位[编号].队伍 and self:取目标状态1(编号,n,1) then
           目标组[#目标组+1]=n
       end
    end
  end
  if #目标组==0 then
     return 0
  else
     return 目标组[取随机数(1,#目标组)]
  end
end


function 战斗处理类:取目标类型(编号)
  local fhz = 0
  if self.参战单位[编号] and self.参战单位[编号].类型 == "bb" and self.参战单位[编号].队伍 ~= 0 then
    fhz = "召唤兽"
  elseif self.参战单位[编号] and self.参战单位[编号].类型 == "角色" and self.参战单位[编号].队伍 ~= 0 then
    fhz = "玩家"
  end
  return fhz
end

function 战斗处理类:取目标状态(攻击,挨打,类型)  --类型=1 为敌方正常 2为队友 3为复活队友
 --print(攻击,挨打,类型)
  if self.参战单位[挨打]==nil or self.参战单位[挨打].法术状态==nil then return false end
  if 类型==1 then
      if self.参战单位[挨打].气血<=0 or self.参战单位[挨打].捕捉 or self.参战单位[挨打].逃跑  then
        return false
      elseif self.参战单位[挨打].法术状态.修罗隐身~=nil and self.参战单位[攻击].法术状态.幽冥鬼眼==nil and self.参战单位[攻击].感知==nil then
        return false
      elseif self.参战单位[挨打].法术状态.煞气诀~=nil then
        return false
    else
      if self.参战单位[挨打].气血<=0 or self.参战单位[挨打].捕捉 or self.参战单位[挨打].逃跑  then
        return false
      elseif self.参战单位[挨打].法术状态.楚楚可怜~=nil and self.参战单位[攻击].感知==nil then
        return false
      elseif self.参战单位[挨打].法术状态.修罗隐身~=nil and self.参战单位[攻击].法术状态.幽冥鬼眼==nil and self.参战单位[攻击].感知==nil then
        return false
      elseif self.参战单位[挨打].法术状态.煞气诀~=nil then
        return false
      end
    end
  elseif 类型==2 then
    if self.参战单位[挨打].气血<=0 or self.参战单位[挨打].捕捉 or self.参战单位[挨打].逃跑 then
       return false
    end
      elseif 类型==3 then
    if self.参战单位[挨打].气血<=0 then
      return false
    end
  end
 return true
end
function 战斗处理类:取目标状态1(攻击,挨打,类型)  --类型=1 为敌方正常 2为队友 3为复活队友
 --print(攻击,挨打,类型)
  if self.参战单位[挨打]==nil or self.参战单位[挨打].法术状态==nil then return false end
  if 类型==1 then
      if self.参战单位[挨打].气血<=0 or self.参战单位[挨打].捕捉 or self.参战单位[挨打].逃跑  then
        return false   --尸腐毒
      elseif self.参战单位[挨打].法术状态.无魂傀儡~=nil or self.参战单位[挨打].法术状态.发瘟匣~=nil or self.参战单位[挨打].法术状态.断线木偶~=nil or self.参战单位[挨打].法术状态.摄魂~=nil or self.参战单位[挨打].法术状态.无尘扇~=nil or self.参战单位[挨打].法术状态.无字经~=nil or self.参战单位[挨打].法术状态.尸腐毒~=nil then
        return true
      end
  end
    return false
end



function 战斗处理类:设置命令回合()
  self.回合数=self.回合数+1
  if self.战斗脚本 and self.战斗脚本.命令回合前 then
    __gge.safecall(self.战斗脚本.命令回合前,self,self.回合数)
  end
  for n=1,#self.参战玩家 do
    for i=1,#self.战斗发言数据 do
      发送数据(self.参战玩家[n].连接id,5512,{id=self.战斗发言数据[i].id,文本=self.战斗发言数据[i].内容})
    end
    self.战斗发言数据={}
    local 编号=self:取参战编号(self.参战玩家[n].id,"角色")
    local 目标={编号}
    if self.参战单位[编号].召唤兽~=nil then
      目标[2]=self.参战单位[编号].召唤兽
    end
    for n=1,#self.参战单位 do
      if self.参战单位[n].名称=="大大王" and self.回合数==2 and self.战斗类型==110002 then
        self.战斗发言数据[#self.战斗发言数据+1]={id=n,内容="上古大神#G吊毛君\n你就放心躺好吧\n接下来交给我们#2"}
      elseif self.参战单位[n].名称=="地涌夫人" and self.回合数==3 and self.战斗类型==110002 then
        self.战斗发言数据[#self.战斗发言数据+1]={id=n,内容="大家坚持住\n#G蚩尤#W已经变弱了\n我来给大家加个#YBUFF#1"}
      elseif self.参战单位[n].名称=="牛魔王" and self.回合数==4 and self.战斗类型==110002 then
        self.战斗发言数据[#self.战斗发言数据+1]={id=n,内容="胜利就在眼前了\n#大家加油\n老牛我发威了#4"}
      elseif self.参战单位[n].名称=="李彪" and self.回合数==5 and self.战斗类型==110014 then
        self.战斗发言数据[#self.战斗发言数据+1]={id=n,内容="#Y刘洪#这废物\n留着何用?\n送你#R归西#吧"}
      end
    end
    if self.参战单位[编号].助战明细 ~= nil then
      for i=1,#self.参战单位[编号].助战明细 do
          目标[#目标+1] = self.参战单位[编号].助战明细[i]
      end
    end
    for i=1,#目标 do
      self.参战单位[目标[i]].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加="",编号=目标[i]}
    end
    if 玩家数据[self.参战玩家[n].id]~=nil and 玩家数据[self.参战玩家[n].id].角色.数据.自动战斗 then
      -- 常规提示(self.参战玩家[n].id,"#Y/您正在使用自动战斗功能，系统将自动执行上一次指令。您可以在每回合开始前的5秒内点击自动以取消自动战斗功能")
    end
    发送数据(self.参战玩家[n].连接id,5503,{目标,self.回合数})
  end
  --清空一次怪物单位
  for n=1,#self.参战单位 do
    if self.参战单位[n].门派=="花果山" then
      self.参战单位[n].主动技能={}
      self.随机神通={"当头一棒","神针撼海","杀威铁棒","泼天乱棒"}
      self.参战单位[n].随机神通=self.随机神通[取随机数(1,#self.随机神通)]
      for i=1,#玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能 do
        for s=1,#玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].包含技能 do
          if 玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].包含技能[s].学会 then
            self.参战单位[n].师门技能[i]={名称=self.参战单位[n].师门技能[i],等级=玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].等级}
            local 名称=玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].包含技能[s].名称
            if self:恢复技能(名称) or self:法攻技能(名称) or self:物攻技能(名称) or self:封印技能(名称) or self:群体封印技能(名称) or self:减益技能(名称) or self:增益技能(名称) or 名称==self.参战单位[n].随机神通 then
              self.参战单位[n].主动技能[#self.参战单位[n].主动技能+1]={名称=名称,等级=玩家数据[self.参战单位[n].玩家id].角色.数据.师门技能[i].等级}
            end
          end
        end
      end
      发送数据(玩家数据[self.参战单位[n].玩家id].连接id,5518,{id=n,主动技能=self.参战单位[n].主动技能})
    end
    if self.参战单位[n].队伍==0  then
      self.参战单位[n].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加=""}
    else
      if self.参战单位[n].指令~=nil then
        self.参战单位[n].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加="",编号=self.参战单位[n].指令.编号}
      else
        self.参战单位[n].指令={下达=false,类型="",目标=0,敌我=0,参数="",附加="",编号=n}
      end
    end
  end
  self.加载数量=#self.参战玩家
  self.等待起始=os.time()
  self.回合进程="命令回合"
end

function 战斗处理类:取参战编号(id,类型)
 for n=1,#self.参战单位 do
      if self.参战单位[n].类型==类型 and self.参战单位[n].玩家id==id and self.参战单位[n].助战编号 == nil then
        return n
      end
   end
end

function 战斗处理类:逃跑事件处理(id)
  ---------摩托修改增加押镖任务逃跑就会失败
  if 战斗准备类.战斗盒子[玩家数据[id].战斗].战斗类型 == 110038 then--普通攻击



  玩家数据[id].角色:取消任务(玩家数据[id].角色:取任务(300))
  玩家数据[id].角色.押镖间隔=os.time()+180
  玩家数据[id].角色.数据.跑镖遇怪时间=0
   添加最后对话(id,format("任务失败,押镖任务不能逃跑,您三分钟之内无法再次领取押镖任务"))
  end
  if #self.参战玩家==1 then --只有一个玩家时直接结束战斗
    self.回合进程="结束回合"
    if self.任务id~=nil and 任务数据[self.任务id] ~= nil then

      任务数据[self.任务id].战斗=nil
    end
    self:还原指定单位属性(id)
    self:失败处理(id,"逃跑")
    self:发送退出信息()
    self.参战玩家={}
    self.结束条件=true
    玩家数据[id].角色.数据.战斗开关=false
    return
  else
    local 编号=0
    for n=1,#self.参战玩家 do
      if self.参战玩家[n].id==id then
        地图处理类:设置战斗开关(self.参战玩家[n].id)
        table.remove(self.参战玩家,n)

        break
      end
    end
    if self:取玩家战斗() then
          self:发送退出信息()
        end
    self:还原指定单位属性(id)
    玩家数据[id].战斗=0
    玩家数据[id].角色.数据.战斗开关=nil
    玩家数据[id].道具:重置法宝回合(id)
    队伍处理类:退出队伍(id)
    玩家数据[id].遇怪时间=os.time()+取随机数(10,20)
    发送数据(玩家数据[id].连接id,5505)
  end
end

function 战斗处理类:结束战斗(胜利id,失败id,系统) --系统为不计算失败惩罚
  if 系统==nil then
     self:胜利处理(胜利id,失败id)
     self:失败处理(失败id,nil,胜利id)
  elseif self.战斗类型==200006 then
     self:胜利处理(胜利id,失败id)
     self:失败处理(失败id,nil,胜利id)
  end
  self:还原单位属性()
  self:发送退出信息()
end
function 战斗处理类:结束战斗1(胜利id,失败id,系统,id) --系统为不计算失败惩罚
  if 系统==nil then
     self:胜利处理(胜利id,失败id)
     self:失败处理(失败id,1,胜利id)
  end
  --self:还原指定单位属性(id)
  self:还原单位属性()
  self:发送退出信息()
end
function 战斗处理类:胜利处理(胜利id,失败id)
  local id组={}
  if self.战斗类型>= 110003 and self.战斗类型<= 110015 then
     for n=1,#self.参战玩家 do
      if self.参战玩家[n].队伍==胜利id and 玩家数据[self.参战玩家[n].id]~=nil then
          self:奖励事件(self.参战玩家[n].id)
          id组[#id组+1]=self.参战玩家[n].id
      end
     end
  elseif   self.战斗类型>= 100229 and self.战斗类型<= 100266 then
     for n=1,#self.参战玩家 do
      if self.参战玩家[n].队伍==胜利id and 玩家数据[self.参战玩家[n].id]~=nil then
          self:奖励事件(self.参战玩家[n].id)
          id组[#id组+1]=self.参战玩家[n].id
      end
     end
  else
     for n=1,#self.参战玩家 do
      if self.参战玩家[n].队伍==胜利id and 玩家数据[self.参战玩家[n].id]~=nil then
          self:奖励事件(self.参战玩家[n].id)
          id组[#id组+1]=self.参战玩家[n].id
      end
     end
  end
  if 胜利id~=0 or 失败id~=0 then
      --剑会天下PK结算
    if self.战斗类型==110001 then
      游戏活动类:剑会天下结算处理假人(胜利id,失败id)
    elseif self.战斗类型==410005 then
      游戏活动类:剑会天下结算处理真人(胜利id,失败id)
    end
  end
  if 胜利id~=0 then
     self.玩家胜利=true
     self.战斗胜利=true
      if self.战斗脚本 and self.战斗脚本.战斗胜利 then
        --self.战斗脚本:OnTurnReady(1)
        __gge.safecall(self.战斗脚本.战斗胜利,self,胜利id,失败id)
      end
      if self.战斗类型==100004 then
          任务处理类:完成封妖任务(self.任务id,id组)
      elseif self.战斗类型==100007 or self.战斗类型==100008 or self.战斗类型==100009 or self.战斗类型==100010 then
        地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
        任务数据[self.任务id]=nil
       elseif self.战斗类型==100006 then
         游戏活动类:科举回答题目(玩家数据[self.进入战斗玩家id].连接id,self.进入战斗玩家id,答案,4)
      elseif self.战斗类型==100239 then
        任务处理类:一键抓鬼(self.进入战斗玩家id)
      elseif self.战斗类型==100240 then
      任务处理类:一键师门(self.进入战斗玩家id)
      elseif self.战斗类型==100241 then
      任务处理类:一键官职(self.进入战斗玩家id)
       elseif self.战斗类型==100011 then
          local 任务id1=玩家数据[self.进入战斗玩家id].角色:取任务(107)
          local 对话门派=Q_门派编号[任务数据[任务id1].当前序列]
          self.对话数据={名称=任务数据[self.任务id].名称,模型=任务数据[self.任务id].模型}
          local 删除序列=0
          for n=1,#任务数据[任务id1].闯关序列 do
            if 任务数据[任务id1].闯关序列[n]==任务数据[任务id1].当前序列 then
              删除序列=n
            end
          end
         table.remove(任务数据[任务id1].闯关序列,删除序列)
         if #任务数据[任务id1].闯关序列==0 then
             self.对话数据.对话="恭喜你们完成了本轮门派闯关活动#1"
             local 队伍id=玩家数据[self.进入战斗玩家id].队伍
             for i=1,#队伍数据[队伍id].成员数据 do
              if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,i) == 0 then
                   玩家数据[队伍数据[队伍id].成员数据[i]].角色:取消任务(任务id1)
                   添加活动次数(队伍数据[队伍id].成员数据[i],"门派闯关")
             end
           end
          else
             任务数据[任务id1].当前序列=任务数据[任务id1].闯关序列[取随机数(1,#任务数据[任务id1].闯关序列)]
             self.对话数据.对话=format("你通过了本门派护法的考验，请继续前往下一关#Y/%s#W/接受考验。".."#"..取随机数(1,110),Q_门派编号[任务数据[任务id1].当前序列])
             local 队伍id=玩家数据[self.进入战斗玩家id].队伍
             for i=1,#队伍数据[队伍id].成员数据 do
              if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,i) == 0 then
                   玩家数据[队伍数据[队伍id].成员数据[i]].角色:刷新任务跟踪()
               end
             end
          end

        elseif self.战斗类型==100012 then
          任务数据[玩家数据[self.进入战斗玩家id].角色:取任务(109)].战斗=true
        elseif self.战斗类型==100013 then
          任务数据[self.任务id].战斗次数=任务数据[self.任务id].战斗次数+1
          地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
          if 任务数据[self.任务id].战斗次数>=2 then
           任务处理类:完成官职任务(self.进入战斗玩家id,1)
          else
            local 地图范围={1001,1501,1092,1070,1040,1226,1208}
            local 地图=地图范围[取随机数(1,#地图范围)]
            local xy=地图处理类.地图坐标[地图]:取随机点()
            任务数据[self.任务id].地图编号=地图
            任务数据[self.任务id].地图名称=取地图名称(地图)
            任务数据[self.任务id].x=xy.x
            任务数据[self.任务id].y=xy.y
            玩家数据[self.进入战斗玩家id].战斗对话={名称="流氓",模型="赌徒",对话="打不过我还躲不过嘛，换个地方继续惹事#4"}
            地图处理类:添加单位(self.任务id)
            玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
            end
       elseif self.战斗类型==100014 then
         if 玩家数据[self.进入战斗玩家id].角色:取道具格子()==0 then
           常规提示(self.进入战斗玩家id,"#Y/你的包裹已经满了，无法获得情报")
          elseif 取随机数()<=50 then
           玩家数据[self.进入战斗玩家id].道具:给予道具(self.进入战斗玩家id,"情报")
           常规提示(self.进入战斗玩家id,"#Y/你得到了#R/情报")
           任务数据[self.任务id].情报=true
           玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
           end
       elseif self.战斗类型==100015 then
          任务数据[self.任务id].巡逻=任务数据[self.任务id].巡逻+1
          if 任务数据[self.任务id].巡逻==2 then
            任务处理类:完成门派任务(self.进入战斗玩家id,2)
          else
            常规提示(self.进入战斗玩家id,"#Y/换个地方我继续捣乱，嘿嘿！")
          end
        elseif self.战斗类型==100016 then
           地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
           任务处理类:完成门派任务(self.进入战斗玩家id,5)
        elseif self.战斗类型==100017 then
          地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
          if self.同门死亡 then
            常规提示(self.进入战斗玩家id,"#Y/你的师门援助任务失败了")
            玩家数据[self.进入战斗玩家id].角色:取消任务(self.任务id)
            任务数据[self.任务id]=nil
            玩家数据[self.进入战斗玩家id].角色.数据.师门次数=0
          else
            任务处理类:完成门派任务(self.进入战斗玩家id,6)
          end
       elseif self.战斗类型==100018 then
         地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
         if 任务数据[self.任务id].乾坤袋 then
        else
            local xy=地图处理类.地图坐标[任务数据[self.任务id].地图编号]:取随机点()
            任务数据[self.任务id].x,任务数据[self.任务id].y=xy.x,xy.y
            玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
            地图处理类:添加单位(self.任务id)
          end
        elseif self.战斗类型==100019 or self.战斗类型==100020 or self.战斗类型==100021 or self.战斗类型==100022 or self.战斗类型==100024 or self.战斗类型==100026 or self.战斗类型==100027 then
          if self.战斗类型==100026 then
            玩家数据[self.进入战斗玩家id].角色:取消任务(self.任务id)
            玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
          end
         地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
         任务数据[self.任务id]=nil
        elseif self.战斗类型==100028 then
         local 副本id=任务数据[self.任务id].副本id
         副本数据.乌鸡国.进行[副本id].木妖数量=副本数据.乌鸡国.进行[副本id].木妖数量+1
          if 副本数据.乌鸡国.进行[副本id].木妖数量>14 then
            副本数据.乌鸡国.进行[副本id].进程=2
            任务处理类:设置乌鸡国副本(副本id)
          end
            for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
              if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
                常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
                玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
              end
          end
          地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
          任务数据[self.任务id]=nil
        elseif self.战斗类型==100029 then
          添加最后对话(胜利id,format("哎哟别打了，我不敢搞事了！"))
          local 副本id=任务数据[self.任务id].副本id
          副本数据.乌鸡国.进行[副本id].序列[任务数据[self.任务id].序列]=true
          local 通过=0
          for n=1,3 do
            if  副本数据.乌鸡国.进行[副本id].序列[n] then 通过=通过+1 end
          end
          for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
            玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
          end
          if 通过>=3 then
            副本数据.乌鸡国.进行[副本id].进程=4
            任务处理类:设置乌鸡国副本(副本id)
            for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
              if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
                常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
                玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
              end
            end
          end
          地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
          任务数据[self.任务id]=nil
        elseif self.战斗类型==100030 then
           local 副本id=任务数据[self.任务id].副本id
           副本数据.乌鸡国.进行[副本id].鬼祟数量=副本数据.乌鸡国.进行[副本id].鬼祟数量+1
           if 副本数据.乌鸡国.进行[副本id].鬼祟数量>4 then
              副本数据.乌鸡国.进行[副本id].进程=5
              任务处理类:设置乌鸡国副本(副本id)
            end
              for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
                if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
                  常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
                  玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
                end
              end
            地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
            任务数据[self.任务id]=nil

          elseif self.战斗类型==100031 then
          local 副本id=任务数据[self.任务id].副本id
          地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
          if 任务数据[self.任务id].真假 then
            for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
              if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
                if 副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]]==nil or 副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].乌鸡奖励==nil then
                副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].乌鸡奖励=true
                end
                玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].战斗=0
                玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:取消任务(玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:取任务(120))
                副本数据.乌鸡国.进行[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]]=nil
                地图处理类:跳转地图(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],1001,288,85)
                副本数据.乌鸡国.进行[副本id]=nil
                添加最后对话(胜利id,format("恭喜你一次性就猜对真国王了!"))
              end
            end
          else
          for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
          if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
          添加最后对话(胜利id,format("你没猜对,我是假国王,需要还战斗一次"))
        end
      end
    end
    elseif self.战斗类型==100025 then
      if 任务数据[self.任务id].序列==6 then
        任务处理类:完成镖王活动(self.任务id,self.进入战斗玩家id)
      else
        任务数据[self.任务id].序列=任务数据[self.任务id].序列+1
        任务数据[self.任务id].地图=镖王数据[任务数据[self.任务id].序列].地图
        任务数据[self.任务id].y=镖王数据[任务数据[self.任务id].序列].y
        任务数据[self.任务id].x=镖王数据[任务数据[self.任务id].序列].x
        任务数据[self.任务id].地图名称=取地图名称(镖王数据[任务数据[self.任务id].序列].地图)
        table.remove(任务数据[self.任务id].完成,任务数据[self.任务id].战斗序列)
        for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
          常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y恭喜你们通过了本镖师考验，请立即前往下一个镖师处")
          玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
        end
      end
    elseif self.战斗类型==100032 or self.战斗类型==100033 then
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      任务数据[self.任务id]=nil
    elseif self.战斗类型==100034 then
      任务数据[self.任务id].巡逻=任务数据[self.任务id].巡逻+1
      if 任务数据[self.任务id].巡逻==2 then
         任务处理类:完成青龙任务(self.任务id,self.进入战斗玩家id,4)
      else
         常规提示(self.进入战斗玩家id,"#Y/换个地方我继续捣乱，嘿嘿！")
      end
    elseif self.战斗类型==100035 then
      任务数据[self.任务id].巡逻=任务数据[self.任务id].巡逻+1
      if 任务数据[self.任务id].巡逻==2 then
         任务处理类:完成玄武任务(self.任务id,id组,4)
      else
         常规提示(self.进入战斗玩家id,"#Y/换个地方我继续捣乱，嘿嘿！")
      end

    elseif self.战斗类型==100037 then
      任务处理类:完成地煞星任务(self.任务id,id组)
    elseif self.战斗类型==100038 then
      任务处理类:完成知了先锋任务(self.任务id,id组)
    elseif self.战斗类型==100039 then
      任务处理类:完成小知了王任务(self.任务id,id组)
    elseif self.战斗类型==100040 then
      任务数据[self.任务id].分类=5
      发送数据(玩家数据[胜利id].连接id,1501,{名称="大力神灵",模型="风伯",对话=format("跟你开了个小小的玩笑，千里眼刚已经找到相关的消息了，少侠可以去找他问问"),选项={"我这就去"}})
    elseif self.战斗类型==100041 then
      任务数据[self.任务id].分类=8
      发送数据(玩家数据[胜利id].连接id,1501,{名称="妖魔亲信",模型="蝴蝶仙子",对话=format("少侠饶命！少侠饶命！我这就送少侠去找我们老大"),选项={"速速送我过去","待我准备准备"}})
    elseif self.战斗类型==100042 then
      任务数据[self.任务id].分类=9
      发送数据(玩家数据[胜利id].连接id,1501,{名称="蜃妖元神",模型="炎魔神",对话=format("少侠饶命！少侠饶命！其实天马早就跑了，具体跑哪去了，我也不知道"),选项={"再敢出来吓唬人，看我不收了你"}})
    elseif self.战斗类型==100043 then
      任务数据[self.任务id].分类=13
      发送数据(玩家数据[胜利id].连接id,1501,{名称="周猎户",模型="男人_兰虎",对话=format("少侠饶命！少侠饶命！我这就把马儿还回去"),选项={"终于找到马儿，可以去找百兽王复命了"}})
    elseif self.战斗类型==100044 then
      if 任务数据[self.任务id].分类==4 and self.任务id==玩家数据[胜利id].角色:取任务(308) then
        任务处理类:完成法宝任务(self.任务id,胜利id)
      end
    elseif self.战斗类型==100045 then
      任务处理类:完成法宝内丹任务(self.任务id,胜利id)
    elseif self.战斗类型==100046 then
      任务数据[self.任务id].进度=任务数据[self.任务id].进度+1
      添加最后对话(胜利id,format("少侠饶命！我再也不敢了"))
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
    elseif self.战斗类型==100047 then
      任务数据[self.任务id].进度=任务数据[self.任务id].进度+1
      添加最后对话(胜利id,format("少侠饶命！我再也不敢了,回去交任务吧"))
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
    elseif self.战斗类型==100048 then
      任务数据[self.任务id].征求意见.牛魔王=true
      常规提示(胜利id,"获得牛魔王的同意")
      发送数据(玩家数据[胜利id].连接id,1501,{名称="牛魔王",模型="牛魔王",对话=format("精彩精彩！（鼓蹄子）心情好多了，趁俺高兴，同意了。")})
      玩家数据[胜利id].角色:刷新任务跟踪()
    elseif self.战斗类型==100049 then
      任务数据[self.任务id].进程=12
      常规提示(胜利id,"获得了不死壤")
      添加最后对话(胜利id,format("少侠功夫了得，这里是不死壤，拿去吧！"))
      玩家数据[胜利id].角色:刷新任务跟踪()
    elseif self.战斗类型==100054 then
      if 玩家数据[胜利id].角色.数据.剧情.飞升~=nil and 任务数据[self.任务id]~=0 then
        --任务数据[self.任务id].进程=13
        玩家数据[胜利id].角色.数据.剧情.飞升.飞升=true
        玩家数据[胜利id].角色:刷新任务跟踪()
        添加最后对话(胜利id,format("不错，你已经有资格入于化境了，去找吴刚吧！"))
      end
    elseif self.战斗类型==200004 then
      游戏活动类:比武大会战斗处理(胜利id,失败id)
    elseif self.战斗类型==300001 then --嘎嘎 跨服
      --游戏活动类:比武大会战斗处理(胜利id,失败id)
    elseif self.战斗类型==200005 then
      游戏活动类:首席争霸战斗处理(胜利id,失败id)
     elseif self.战斗类型==200006 then ---帮战
       --帮战活动类:胜利处理(胜利id,失败id)
      -- for i,v in ipairs(帮派数据[tonumber(玩家数据[胜利id].角色.数据.帮派数据.编号)].成员数据) do
      -- if v.id == 玩家数据[胜利id].角色.数据.数字id then
       if 帮派数据[tonumber(玩家数据[胜利id].角色.数据.帮派数据.编号)].帮派积分==nil then
          帮派数据[tonumber(玩家数据[胜利id].角色.数据.帮派数据.编号)].帮派积分=0
       end
       if 玩家数据[胜利id].角色.数据.帮战次数==nil then
          玩家数据[胜利id].角色.数据.帮战次数=0
       end
       if 玩家数据[胜利id].角色.数据.帮战积分==nil then
          玩家数据[胜利id].角色.数据.帮战积分=0
       end
       帮派数据[tonumber(玩家数据[胜利id].角色.数据.帮派数据.编号)].帮派积分 = 帮派数据[tonumber(玩家数据[胜利id].角色.数据.帮派数据.编号)].帮派积分+10
       玩家数据[胜利id].角色.数据.帮战次数 = 玩家数据[胜利id].角色.数据.帮战次数+1
       玩家数据[胜利id].角色.数据.帮战积分 = 玩家数据[胜利id].角色.数据.帮战积分+5
       --添加帮贡(id,5)
       常规提示(胜利id,"#Y恭喜你胜利了，获得帮战积分#R5#Y分，帮派积分增加#R10#Y点#80")
    --    break
    --   end
    -- end



    elseif self.战斗类型==200008 then
      if 玩家数据[胜利id].队伍 == 0 or 玩家数据[胜利id].队长 then
        玩家数据[胜利id].角色.数据.强P开关 = nil
        发送数据(玩家数据[胜利id].连接id,94)
        地图处理类:更改强PK(胜利id)
        if 玩家数据[胜利id].角色.数据.PK开关 ~= nil then
          发送数据(玩家数据[胜利id].连接id,93,{开关=true})
          地图处理类:更改PK(胜利id,true)
        end
      end
    elseif self.战斗类型==100055 then
          任务处理类:完成生死劫挑战(任务id,id组)
    elseif self.战斗类型==100056 then
      任务处理类:完成天罡星任务(self.任务id,id组)
    elseif self.战斗类型==100060 then
      任务处理类:完成新服福利BOSS(self.任务id,id组)
    elseif self.战斗类型==100066 then
      local 副本id=任务数据[self.任务id].副本id
      副本数据.车迟斗法.进行[副本id].车迟贡品=副本数据.车迟斗法.进行[副本id].车迟贡品+1
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
        if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
          玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
    end
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      任务数据[self.任务id]=nil
      添加最后对话(胜利id,format("少侠饶命！我再也不敢了"))
    elseif self.战斗类型==100067 then
      添加最后对话(胜利id,format("哎哟别打了，我不敢搞事了！"))
      local 副本id=任务数据[self.任务id].副本id
      副本数据.车迟斗法.进行[副本id].序列[任务数据[self.任务id].序列]=true
      local 通过=0
      for n=1,3 do
        if  副本数据.车迟斗法.进行[副本id].序列[n] then 通过=通过+1 end
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
        玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      if 通过>=3 then
        副本数据.车迟斗法.进行[副本id].进程=5
        任务处理类:设置车迟斗法副本(副本id)
        for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
          if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
            常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
            玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
            end
          end
        end
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      任务数据[self.任务id]=nil
    elseif self.战斗类型==100068 then
      添加最后对话(胜利id,format("幸亏少侠帮忙，不然我们就促成大错了！！！"))
      local 副本id=任务数据[self.任务id].副本id
      副本数据.车迟斗法.进行[副本id].序列[任务数据[self.任务id].序列]=true
      local 通过=0
      for n=1,3 do
        if 副本数据.车迟斗法.进行[副本id].序列[n] then 通过=通过+1 end
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
        玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      if 通过>=3 then
        副本数据.车迟斗法.进行[副本id].进程=8
        任务处理类:设置车迟斗法副本(副本id)
        for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
          if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
            常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
            玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
            end
          end
      end
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      任务数据[self.任务id]=nil
    elseif self.战斗类型==100069 then
      添加最后对话(胜利id,format("你输了，你先动的，先动的是王八！！！"))
      local 副本id=任务数据[self.任务id].副本id
      副本数据.车迟斗法.进行[副本id].序列[任务数据[self.任务id].序列]=true
      local 通过=0
      for n=1,3 do
        if 副本数据.车迟斗法.进行[副本id].序列[n] then 通过=通过+1 end
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
        玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      if 通过>=3 then
        副本数据.车迟斗法.进行[副本id].进程=8
        任务处理类:设置车迟斗法副本(副本id)
        for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
          if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
            常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
            玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
            end
        end
      end
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      任务数据[self.任务id]=nil
    elseif self.战斗类型==100070 then
      local 副本id=任务数据[self.任务id].副本id
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
        if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
        if 副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]]==nil or 副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].车迟奖励==nil then
           副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].车迟奖励=true
        end
        玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].战斗=0
        玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:取消任务(玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:取任务(130))
        副本数据.车迟斗法.进行[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]]=nil
        地图处理类:跳转地图(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],1070,122,144)
      end
    end
    添加最后对话(胜利id,format("少侠饶命！我再也不敢了"))
    elseif self.战斗类型==100084 then
      任务处理类:完成散财童子(self.任务id,id组)
    elseif self.战斗类型==100085 then
      local 玩家id=任务数据[self.任务id].玩家id
      添加最后对话(玩家id,"#Y可恶，披着人皮的妖怪居然蒙骗勇士，少侠，小心那个带头人。")
      玩家数据[玩家id].战斗=0
      地图处理类:跳转地图(玩家id,1187,53,30)
      剧情数据.渡劫.进行[玩家id].进程=2
      任务处理类:取渡劫任务(玩家id)
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      玩家数据[玩家id].角色:刷新任务跟踪()
    elseif self.战斗类型==100086 then
      local 玩家id=任务数据[self.任务id].玩家id
      添加最后对话(玩家id,"#Y哈哈，大阵已经松动，我的任务也算完成了")
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号-1)
      剧情数据.渡劫.进行[玩家id].进程=4
      任务处理类:取渡劫任务(玩家id)
      玩家数据[玩家id].角色:刷新任务跟踪()
    elseif self.战斗类型==100087 then
      local 玩家id=任务数据[self.任务id].玩家id
      添加最后对话(玩家id,"妖怪逃跑了，大家快追！")
      for i=1,14 do
        地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号+(i-1))
      end
      剧情数据.渡劫.进行[玩家id].进程=7
      任务处理类:取渡劫任务(玩家id)
      玩家数据[玩家id].角色:刷新任务跟踪()
    elseif self.战斗类型==100088 then
      local 玩家id=任务数据[self.任务id].玩家id
      剧情数据.渡劫.进行[玩家id].进程=9
      任务处理类:取渡劫任务(玩家id)
      玩家数据[玩家id].角色:刷新任务跟踪()
    elseif self.战斗类型==100089 then
      local 玩家id=任务数据[self.任务id].玩家id
      添加最后对话(玩家id,"别再执迷不悟了")
      for i=1,15 do
        地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号+(i-1))
      end
      剧情数据.渡劫.进行[玩家id].进程=10
      任务处理类:取渡劫任务(玩家id)
      玩家数据[玩家id].角色:刷新任务跟踪()
    elseif self.战斗类型==100090 then
      local 玩家id=任务数据[self.任务id].玩家id
      local 任务id=玩家数据[玩家id].角色:取任务(8800)
      添加最后对话(玩家id,"不要高兴的太早，吾还会再回来的")
      for i=1,6 do
        地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号+(i-1))
      end
      for i=1,13 do
        地图处理类:删除单位(1042,1000+(i-1))
      end
      玩家数据[玩家id].角色:取消任务(任务id)
      玩家数据[玩家id].角色.数据.剧情.渡劫=true
      玩家数据[玩家id].角色.数据.剧情点=玩家数据[玩家id].角色.数据.剧情点+20
      玩家数据[玩家id].角色:添加称谓(玩家id,"超凡入圣")
      常规提示(玩家id,"#Y恭喜你完成飞升，获得了20点剧情点")
      玩家数据[玩家id].战斗=0
      地图处理类:跳转地图(玩家id,1001,380,50)
      广播消息({内容=format("#S(出神入化)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，成功步入化境，粉碎了蚩尤的阴谋，造福三界；让我们为英雄欢呼吧".."#"..取随机数(84,84),玩家数据[玩家id].角色.数据.名称,"蚩尤幻影"),频道="xt"})
      发送公告(format("#S(出神入化)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，成功步入化境，粉碎了蚩尤的阴谋，造福三界；让我们为英雄欢呼吧",玩家数据[玩家id].角色.数据.名称,"蚩尤幻影"))
    elseif self.战斗类型==100097 then
      玩家数据[胜利id].角色.数据.五虎上将 = 1
      玩家数据[胜利id].角色.数据.潜力 = 玩家数据[胜利id].角色.数据.潜力 + 10
      添加最后对话(胜利id,"你的实力真是令人惊叹！你的潜能增加了")
      广播消息({内容=format("#S(五虎上将)#R/%s#Y与#R马超#Y奋战数百回合，竟然意外激发自身潜能,实力得到了进一步的提升。".."#"..取随机数(1,110),玩家数据[胜利id].角色.数据.名称),频道="xt"})
    elseif self.战斗类型==100098 then
      玩家数据[胜利id].角色.数据.五虎上将 = 2
      玩家数据[胜利id].角色.数据.潜力 = 玩家数据[胜利id].角色.数据.潜力 + 20
      添加最后对话(胜利id,"你的实力真是令人惊叹！你的潜能增加了")
      广播消息({内容=format("#S(五虎上将)#R/%s#Y与#R黄忠#Y奋战数百回合，竟然意外激发自身潜能,实力得到了进一步的提升。".."#"..取随机数(1,110),玩家数据[胜利id].角色.数据.名称),频道="xt"})
    elseif self.战斗类型==100099 then
      玩家数据[胜利id].角色.数据.五虎上将 = 3
      玩家数据[胜利id].角色.数据.潜力 = 玩家数据[胜利id].角色.数据.潜力 + 30
      添加最后对话(胜利id,"你的实力真是令人惊叹！你的潜能增加了")
      广播消息({内容=format("#S(五虎上将)#R/%s#Y与#R张飞#Y奋战数百回合，竟然意外激发自身潜能,实力得到了进一步的提升。".."#"..取随机数(1,110),玩家数据[胜利id].角色.数据.名称),频道="xt"})
    elseif self.战斗类型==100100 then
      玩家数据[胜利id].角色.数据.五虎上将 = 4
      玩家数据[胜利id].角色.数据.潜力 = 玩家数据[胜利id].角色.数据.潜力 + 40
      添加最后对话(胜利id,"你的实力真是令人惊叹！你的潜能增加了")
      广播消息({内容=format("#S(五虎上将)#R/%s#Y与#R关羽#Y奋战数百回合，竟然意外激发自身潜能,实力得到了进一步的提升。".."#"..取随机数(1,110),玩家数据[胜利id].角色.数据.名称),频道="xt"})
    elseif self.战斗类型==100101 then
      玩家数据[胜利id].角色.数据.五虎上将 = 5
      玩家数据[胜利id].角色:刷新信息("1")
      添加最后对话(胜利id,"你的实力真是令人惊叹！你的潜能增加了)")
      广播消息({内容=format("#S(五虎上将)#R/%s#Y与#R赵云#Y奋战数百回合，竟然意外激发自身潜能,实力得到了进一步的提升。".."#"..取随机数(1,110),玩家数据[胜利id].角色.数据.名称),频道="xt"})
    elseif self.战斗类型==100105 then
      任务处理类:完成福利宝箱(self.任务id,id组)
    elseif self.战斗类型==100106 then
      任务处理类:完成倾国倾城(self.任务id,id组)
    elseif self.战斗类型==100107 then
      任务处理类:完成美食专家(self.任务id,id组)
    elseif self.战斗类型==100108 then
      任务处理类:完成通天塔(self.任务id,id组)
    elseif self.战斗类型==100109 then
      任务处理类:完成贼王的线索(self.任务id,id组)
    elseif self.战斗类型==100110 then
      任务处理类:完成貔貅的羁绊(self.任务id,id组)
    elseif self.战斗类型==100112 then
      local 任务id = 玩家数据[胜利id].角色:取任务(150)
      local 副本id = 任务数据[任务id].副本id
      任务数据[任务id].装潢=任务数据[任务id].装潢+2
      玩家数据[胜利id].采摘木材=nil
      副本数据.水陆大会.进行[副本id].装潢=副本数据.水陆大会.进行[副本id].装潢+2
      常规提示(胜利id,"#Y完成了采摘木材，装潢任务进度+2")
      if 副本数据.水陆大会.进行[副本id].装潢>=10 and 副本数据.水陆大会.进行[副本id].邀请>=10 then
        for i,v in pairs(地图处理类.地图单位[6024]) do
          if 地图处理类.地图单位[6024][i].名称 == "蟠桃树" and 任务数据[地图处理类.地图单位[6024][i].id].副本id == 副本id then
            地图处理类:删除单位(6024,i)
            break
          end
        end
        副本数据.水陆大会.进行[副本id].进程=2
        任务处理类:设置水陆大会副本(副本id)
        发送数据(玩家数据[胜利id].连接id,1501,{名称="道场督僧",模型="男人_方丈",对话="感谢少侠为水陆大会建设做出的贡献，道场已经建设完毕"})
      end
      玩家数据[胜利id].角色:刷新任务跟踪()
    elseif self.战斗类型==100113 then
      local 任务id = 玩家数据[胜利id].角色:取任务(150)
      local 副本id=任务数据[任务id].副本id
      任务数据[任务id].装潢=任务数据[任务id].装潢+2
      玩家数据[胜利id].驱逐泼猴=nil
      副本数据.水陆大会.进行[副本id].装潢=副本数据.水陆大会.进行[副本id].装潢+2
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      玩家数据[胜利id].角色:取消任务(玩家数据[胜利id].角色:取任务(352))
      常规提示(胜利id,"#Y完成了驱逐泼猴，装潢任务进度+2")
      if 副本数据.水陆大会.进行[副本id].装潢>=10 and 副本数据.水陆大会.进行[副本id].邀请>=10 then
        for i,v in pairs(地图处理类.地图单位[6024]) do
          if 地图处理类.地图单位[6024][i].名称 == "蟠桃树" and 任务数据[地图处理类.地图单位[6024][i].id].副本id == 副本id then
            地图处理类:删除单位(6024,i)
            break
          end
        end
        副本数据.水陆大会.进行[副本id].进程=2
        任务处理类:设置水陆大会副本(副本id)
        发送数据(玩家数据[胜利id].连接id,1501,{名称="道场督僧",模型="男人_方丈",对话="感谢少侠为水陆大会建设做出的贡献，道场已经建设完毕"})
      end
      玩家数据[胜利id].角色:刷新任务跟踪()
    elseif self.战斗类型==100116 then
      local 任务id = 玩家数据[胜利id].角色:取任务(150)
      local 副本id=任务数据[任务id].副本id
      副本数据.水陆大会.进行[副本id].击败翼虎=true
      任务数据[self.任务id].战斗=nil
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      if 副本数据.水陆大会.进行[副本id].击败翼虎 and 副本数据.水陆大会.进行[副本id].击败蝰蛇 then
        副本数据.水陆大会.进行[副本id].进程=6
        任务处理类:设置水陆大会副本(副本id)
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100117 then
      local 任务id = 玩家数据[胜利id].角色:取任务(150)
      local 副本id=任务数据[任务id].副本id
      副本数据.水陆大会.进行[副本id].击败蝰蛇=true
      任务数据[self.任务id].战斗=nil
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      if 副本数据.水陆大会.进行[副本id].击败翼虎 and 副本数据.水陆大会.进行[副本id].击败蝰蛇 then
        副本数据.水陆大会.进行[副本id].进程=6
        任务处理类:设置水陆大会副本(副本id)
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100118 then
      local 任务id = 玩家数据[胜利id].角色:取任务(150)
      local 副本id=任务数据[任务id].副本id
      if 任务数据[self.任务id].名称=="巡山小妖" then
        副本数据.水陆大会.进行[副本id].击败小妖=副本数据.水陆大会.进行[副本id].击败小妖+1
      elseif 任务数据[self.任务id].名称=="上古妖兽头领" then
        副本数据.水陆大会.进行[副本id].击败头领=副本数据.水陆大会.进行[副本id].击败头领+1
      elseif 任务数据[self.任务id].名称=="妖将军" then
        副本数据.水陆大会.进行[副本id].击败将军=副本数据.水陆大会.进行[副本id].击败将军+1
      else
        if 任务数据[self.任务id].名称=="魑魅" then
          副本数据.水陆大会.进行[副本id].击败魑魅=true
        else
          副本数据.水陆大会.进行[副本id].击败魍魉=true
        end
      end
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      if 副本数据.水陆大会.进行[副本id].击败魑魅 and 副本数据.水陆大会.进行[副本id].击败魍魉 then
        副本数据.水陆大会.进行[副本id].进程=8
        任务处理类:设置水陆大会副本(副本id)
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100122 then
      任务处理类:完成捣乱的年兽(self.任务id,id组)
    elseif self.战斗类型==100123 then
      任务处理类:完成年兽王(self.任务id,id组)
    elseif self.战斗类型==100124 then
      任务处理类:完成邪恶年兽(self.任务id,id组)
    elseif self.战斗类型==100125 then
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      local 任务id = 玩家数据[胜利id].角色:取任务(160)
      local 副本id=任务数据[任务id].副本id
      副本数据.通天河.进行[副本id].进程=4
      任务处理类:设置通天河副本(副本id)
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100126 then
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      local 副本id=任务数据[self.任务id].副本id
      副本数据.通天河.进行[副本id].河妖=副本数据.通天河.进行[副本id].河妖+1
      if 副本数据.通天河.进行[副本id].河妖>=5 then
        玩家数据[胜利id].战斗=0
        地图处理类:跳转地图(胜利id,6028,27,22)
        副本数据.通天河.进行[副本id].进程=6
        任务处理类:设置通天河副本(副本id)
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100127 then
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      local 副本id=任务数据[self.任务id].副本id
      副本数据.通天河.进行[副本id].散财童子=true
      if 副本数据.通天河.进行[副本id].散财童子 and 副本数据.通天河.进行[副本id].黑熊精 then
        副本数据.通天河.进行[副本id].进程=7
        任务处理类:设置通天河副本(副本id)
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100128 then
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      local 副本id=任务数据[self.任务id].副本id
      副本数据.通天河.进行[副本id].黑熊精=true
      if 副本数据.通天河.进行[副本id].散财童子 and 副本数据.通天河.进行[副本id].黑熊精 then
        副本数据.通天河.进行[副本id].进程=7
        任务处理类:设置通天河副本(副本id)
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100129 then
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      local 副本id=任务数据[self.任务id].副本id
      副本数据.通天河.进行[副本id].五色竹条=副本数据.通天河.进行[副本id].五色竹条+5
      if 副本数据.通天河.进行[副本id].五色竹条>=50 then
        玩家数据[胜利id].战斗=0
        地图处理类:跳转地图(胜利id,6029,103,59)
        副本数据.通天河.进行[副本id].进程=9
        任务处理类:设置通天河副本(副本id)
      end
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100134 then
      地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
      local 副本id=任务数据[self.任务id].副本id
      玩家数据[胜利id].战斗=0
      地图处理类:跳转地图(胜利id,6030,106,38)
      副本数据.通天河.进行[副本id].进程=10
      任务处理类:设置通天河副本(副本id)
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
      if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
      常规提示(队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n],"#Y您的副本进度已经更新")
      玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:刷新任务跟踪()
      end
      end
    elseif self.战斗类型==100135 then
      local 副本id=任务数据[self.任务id].副本id
      for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
        if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
        if 副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]]==nil or 副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].通天奖励==nil then
           副本奖励[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].通天奖励=true
        end
          玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].战斗=0
          玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:取消任务(玩家数据[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]].角色:取任务(160))
          地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
          副本数据.通天河.进行[队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]]=nil
    end
  end
      玩家数据[胜利id].战斗=0
      副本数据.通天河.进行[副本id]=nil
      地图处理类:跳转地图(胜利id,1070,52,74)
    elseif self.战斗类型==100147 then --大闹浇水
    elseif self.战斗类型==100148 then --大闹除虫
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(180)
      if 任务数据[rwid].三大力士.修桃力士 > 0 then
        任务数据[rwid].三大力士.修桃力士 = 任务数据[rwid].三大力士.修桃力士 - 1
        if 任务数据[rwid].完成三大力士 == nil then
          任务数据[rwid].完成三大力士 = 0
        end
        任务数据[rwid].完成三大力士 = 任务数据[rwid].完成三大力士 + 1
        if 任务数据[rwid].三大力士.修桃力士 <= 0 then
          取消队伍任务(rwid,183)
        else
          玩家数据[self.进入战斗玩家id].角色:取消任务(玩家数据[self.进入战斗玩家id].角色:取任务(183))
        end
        if 任务数据[rwid].完成三大力士 >= 15 then
          local fbid = 任务数据[rwid].副本id
          副本数据.大闹天宫.进行[fbid].进程 = 2
          任务处理类:设置大闹天宫副本(fbid)
        end
        玩家数据[self.进入战斗玩家id].角色:添加经验(100000,"大闹天宫除虫")
        玩家数据[self.进入战斗玩家id].角色:添加储备(500000,"大闹天宫除虫",1)
        刷新队伍任务跟踪(rwid)
      end
    elseif self.战斗类型==100149 then
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(180)
      local fbid = 任务数据[rwid].副本id
      任务处理类:完成大闹七仙女(self.任务id,id组)
      副本数据.大闹天宫.进行[fbid].进程 = 4
      任务处理类:设置大闹天宫副本(fbid)
      刷新队伍任务跟踪(rwid)
      for i=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
        if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,i) == 0 then
          local 数字id = 队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[i]
          玩家数据[数字id].战斗=0
          if 玩家数据[数字id].角色.数据.变身数据 == nil then
            玩家数据[数字id].角色.数据.变身数据="菩提老祖"
            玩家数据[数字id].角色.数据.变异=nil
            玩家数据[数字id].角色:刷新信息()
            发送数据(玩家数据[数字id].连接id,37,{变身数据=玩家数据[数字id].角色.数据.变身数据,变异=玩家数据[数字id].角色.数据.变异})
            任务处理类:添加变身(数字id,9)
            地图处理类:更改模型(数字id,{[1]=玩家数据[数字id].角色.数据.变身数据,[2]=玩家数据[数字id].角色.数据.变异},1)
            常规提示(数字id,"#Y/此处甚好,且让我变化一番！")
          end
        end
      end
      地图处理类:跳转地图(self.进入战斗玩家id,6032,103,59)
    elseif self.战斗类型>=100150 and self.战斗类型 <=100153 then
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(180)
      local fbid = 任务数据[rwid].副本id
      任务处理类:完成战诸神(self.任务id,id组)
      if self.战斗类型 == 100150 then
        任务数据[rwid].战诸神.造酒仙官 = true
      elseif self.战斗类型 == 100151 then
        任务数据[rwid].战诸神.运水道人 = true
      elseif self.战斗类型 == 100152 then
        任务数据[rwid].战诸神.烧火童子 = true
      elseif self.战斗类型 == 100153 then
        任务数据[rwid].战诸神.盘槽力士 = true
      end
      local 完成数据 = {"造酒仙官","运水道人","烧火童子","盘槽力士"}
      local 是否完成 = true
      for i=1,4 do
        if not 任务数据[rwid].战诸神[完成数据[i]] then
          是否完成 = false
        end
      end
      if 是否完成 then
        副本数据.大闹天宫.进行[fbid].进程 = 5
        任务处理类:设置大闹天宫副本(fbid)
        刷新队伍任务跟踪(rwid)
        玩家数据[self.进入战斗玩家id].战斗=0
        地图处理类:跳转地图(self.进入战斗玩家id,6033,103,59)
      end
    elseif self.战斗类型==100154 then
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(180)
      if rwid ~= 0 then
        任务处理类:完成大闹天兵(self.任务id,id组)
        任务数据[rwid].天兵天将.天兵=true
        if 任务数据[rwid].天兵天将.天将 then
          local fbid = 任务数据[rwid].副本id
          副本数据.大闹天宫.进行[fbid].进程 = 7
          任务处理类:设置大闹天宫副本(fbid)
          刷新队伍任务跟踪(rwid)
        end
      end
    elseif self.战斗类型==100155 then
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(180)
      if rwid ~= 0 then
        任务数据[rwid].天兵天将.天将=true
        任务处理类:完成大闹天将(self.任务id,id组)
        if 任务数据[rwid].天兵天将.天兵 then
          local fbid = 任务数据[rwid].副本id
          副本数据.大闹天宫.进行[fbid].进程 = 7
          任务处理类:设置大闹天宫副本(fbid)
          刷新队伍任务跟踪(rwid)
        end
      end
    elseif self.战斗类型==100156 then
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(180)
      if rwid ~= 0 then
        任务处理类:完成大闹二郎神(self.任务id,id组)
        local fbid = 任务数据[rwid].副本id
        玩家数据[self.进入战斗玩家id].战斗=0
        地图处理类:跳转地图(self.进入战斗玩家id,6035,193,130)
        副本数据.大闹天宫.进行[fbid].进程 = 8
        任务处理类:设置大闹天宫副本(fbid)
        刷新队伍任务跟踪(rwid)
      end
    elseif self.战斗类型==100157 then
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(180)
      if rwid ~= 0 then
        任务处理类:完成大闹雷神(self.任务id,id组)
        for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
          if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
            local id = 队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]
            if 玩家数据[id].角色.数据.副本积分==nil then
              玩家数据[id].角色.数据.副本积分=0
            end
            玩家数据[id].战斗=0
            玩家数据[id].角色.数据.副本积分=玩家数据[id].角色.数据.副本积分+60
            活跃数据[id].活跃度=活跃数据[id].活跃度+60
            玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+活跃数据[id].活跃度
            玩家数据[id].角色.数据.累积活跃.总积分=玩家数据[id].角色.数据.累积活跃.总积分+活跃数据[id].活跃度
            常规提示(id,"#Y恭喜你完成了大闹天宫副本获得50点活跃")
            常规提示(id,"#Y恭喜你完成了大闹天宫副本获得60点副本积分")
            玩家数据[id].角色:取消任务(rwid)
            副本数据.大闹天宫.完成[id]=true
          end
        end
        local fbid = 任务数据[rwid].副本id
        地图处理类:跳转地图(self.进入战斗玩家id,1070,53,196)
        副本数据.大闹天宫.进行[fbid]=nil
        任务数据[rwid]=nil
      end
    elseif self.战斗类型==100158 then
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(364)
      if rwid ~= 0 then
        if 任务数据[rwid].当前序列 >= 6 then
          任务处理类:完成十二星宫(self.任务id,id组)
          地图处理类:跳转地图(self.进入战斗玩家id,1001,360,32)
        else
          任务处理类:完成十二星宫(self.任务id,id组,"支线")
          任务数据[rwid].当前序列 = 任务数据[rwid].当前序列 +1
          发送数据(玩家数据[self.进入战斗玩家id].连接id,1501,{名称="星空使者",模型="蜃气妖",对话=format("你完成了此宫挑战，请立即前往寻找#Y/%s#W/接受考验。",任务数据[rwid].目标组[任务数据[rwid].当前序列])})
        end
      end
      刷新队伍任务跟踪(rwid)
    elseif self.战斗类型==100214 then --大闹黑白无常
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(191)
      if rwid ~= 0 then
        local 副本id=任务数据[rwid].副本id
        副本数据.齐天大圣.进行[副本id].进程=3
        任务处理类:设置齐天大圣副本(副本id)
        刷新队伍任务跟踪(rwid)
        任务处理类:完成齐天黑白无常(self.任务id,id组)
      end
    elseif self.战斗类型==100215 then --大闹阎王
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(191)
      if rwid ~= 0 then
        local 副本id=任务数据[rwid].副本id
        副本数据.齐天大圣.进行[副本id].进程=5
        任务处理类:设置齐天大圣副本(副本id)
        刷新队伍任务跟踪(rwid)
        任务处理类:完成齐天阎王(self.任务id,id组)
      end
    elseif self.战斗类型==100216 then --大闹天王
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(191)
      if rwid ~= 0 then
        local 副本id=任务数据[rwid].副本id
        副本数据.齐天大圣.进行[副本id].进程=7
        任务处理类:设置齐天大圣副本(副本id)
        刷新队伍任务跟踪(rwid)
        任务处理类:完成齐天天王(self.任务id,id组)
      end
    elseif self.战斗类型==100217 then --大闹盗马贼
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(191)
      if rwid ~= 0 then
        local 副本id=任务数据[rwid].副本id
        副本数据.齐天大圣.进行[副本id].盗马贼=副本数据.齐天大圣.进行[副本id].盗马贼-1
        if 副本数据.齐天大圣.进行[副本id].盗马贼 <= 0 then
          副本数据.齐天大圣.进行[副本id].进程=9
          任务处理类:设置齐天大圣副本(副本id)
        end
        任务处理类:完成齐天盗马贼(self.任务id,id组)
        刷新队伍任务跟踪(rwid)
      end
    elseif self.战斗类型==100218 then --大闹百万天兵
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(191)
      if rwid ~= 0 then
        local 副本id=任务数据[rwid].副本id
        副本数据.齐天大圣.进行[副本id].百万天兵.百万天兵=true
        任务处理类:完成齐天百万天兵(self.任务id,id组)
      end
    elseif self.战斗类型==100219 then --大闹巨灵神
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(191)
      if rwid ~= 0 then
        local 副本id=任务数据[rwid].副本id
        副本数据.齐天大圣.进行[副本id].百万天兵.巨灵神=true
        任务处理类:完成齐天巨灵神(self.任务id,id组)
      end

---嘎嘎完成战斗

    elseif self.战斗类型==199406 then
      任务处理类:完成征战神州(self.任务id,id组)

    elseif self.战斗类型==199407 then
      for n=1,#id组 do
      任务处理类:完成文韵墨香李世民(id组[n])
      end
    elseif self.战斗类型==199408 then
      for n=1,#id组 do
      任务处理类:完成文韵墨香砍木头(id组[n])
      end
    elseif self.战斗类型==199409 then
      for n=1,#id组 do
      任务处理类:完成文韵墨香巡逻(id组[n])
      end









    elseif self.战斗类型==100220 then  --大闹镇塔之神
      local rwid = 玩家数据[self.进入战斗玩家id].角色:取任务(191)
      if rwid ~= 0 then
        任务处理类:完成齐天镇塔之神(self.任务id,id组)
        for n=1,#队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据 do
          if 队伍处理类:取是否助战(玩家数据[self.进入战斗玩家id].队伍,n) == 0 then
            local id = 队伍数据[玩家数据[self.进入战斗玩家id].队伍].成员数据[n]
            if 玩家数据[id].角色.数据.副本积分==nil then
              玩家数据[id].角色.数据.副本积分=0
            end
            玩家数据[id].角色.数据.副本积分=玩家数据[id].角色.数据.副本积分+20
            常规提示(id,"#Y恭喜你完成了齐天大圣副本获得20点副本积分")
            玩家数据[id].角色:取消任务(玩家数据[id].角色:取任务(191))
            副本数据.齐天大圣.完成[id]=true
            活跃数据[id].活跃度=活跃数据[id].活跃度+50
            玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+活跃数据[id].活跃度
            玩家数据[id].角色.数据.累积活跃.总积分=玩家数据[id].角色.数据.累积活跃.总积分+活跃数据[id].活跃度
            if id == self.进入战斗玩家id then
              local 副本id=任务数据[rwid].副本id
              副本数据.齐天大圣.进行[副本id]=nil
              任务数据[rwid]=nil
              玩家数据[self.进入战斗玩家id].战斗=0
              地图处理类:跳转地图(self.进入战斗玩家id,1092,51,50,1)
            end
            玩家数据[id].角色:刷新任务跟踪()
          end
        end
      end
      刷新队伍任务跟踪(rwid)
    end
  end
end

function 战斗处理类:取野外等级差(地图等级,玩家等级)
  local 等级=math.abs(地图等级-玩家等级)
  if 等级<=5 then
    return 1
  elseif 等级<=10 then
    return 0.8
  elseif 等级<=20 then
    return 0.5
  else
    return 0.2
  end
end

function 战斗处理类:取编号目标气血(编号)
  return self.参战单位[目标].气血
end

function 战斗处理类:取名称目标气血(名称)
  --如果同名只能返回编号靠前的
  for n=1,#self.参战单位 do
    if self.参战单位[n].名称==名称 then
      return self.参战单位[n].气血
    end
  end
end

function 战斗处理类:奖励事件(id)
-- ---帮战
-- if self.战斗类型==200006 then
--     for i,v in ipairs(帮派数据[tonumber(玩家数据[id].角色.数据.帮派数据.编号)].成员数据) do
--       if v.id == 玩家数据[id].角色.数据.数字id then
--        帮派数据[tonumber(玩家数据[id].角色.数据.帮派数据.编号)].帮派积分 = 帮派数据[tonumber(玩家数据[id].角色.数据.帮派数据.编号)].帮派积分+10
--        玩家数据[id].角色.数据.帮战次数 = 玩家数据[id].角色.数据.帮战次数+1
--        玩家数据[id].角色.数据.帮战积分 = 玩家数据[id].角色.数据.帮战积分+5
--        --添加帮贡(id,5)
--        常规提示(id,"#Y恭喜你胜利了，获得帮战积分#R5#Y分，帮派积分增加#R10#Y点#80")
--        break
--       end
--     end

-- end


 if self.战斗类型==100001 or self.战斗类型==100007 then
     if self.地图等级<=3 then self.地图等级=3 end
     local 奖励经验=qz(self.地图等级*5*(self.敌人数量))
     local 奖励参数=self:取野外等级差(self.地图等级,玩家数据[id].角色.数据.等级)
     玩家数据[id].角色:添加经验(qz(奖励经验*奖励参数),"野外")
     玩家数据[id].角色:添加法宝灵气(id,1,self.等级下限,self.等级上限)
     print(玩家数据[id].队伍,"玩家数据[id]")


      for n=1,#玩家数据[id].召唤兽.数据 do
         玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,奖励经验,id,"野外",self.地图等级)
      end
    local 地图名称=取地图名称(玩家数据[id].角色.数据.地图数据.编号)
    if 地图名称=="东海湾"  then
    if 成就数据[id].大海龟==nil then
    成就数据[id].大海龟=0
    end
    if 成就数据[id].大海龟<101 then
    成就数据[id].大海龟=成就数据[id].大海龟+1
    end
    if 成就数据[id].大海龟 == 1 then
    local 成就提示 = "我不是李永生"
    local 成就提示1 = "完成1次了大海龟击杀"
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
    elseif 成就数据[id].大海龟==100 then
    local 成就提示 = "大海龟杀手-李永生"
    local 成就提示1 = "完成100次了大海龟击杀"
    成就数据[id].成就点 = 成就数据[id].成就点 + 1
    常规提示(id,"#Y/恭喜你获得了1点成就")
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
    玩家数据[id].角色:添加称谓(id,"大海龟杀手")
     end
    end

    if 地图名称=="江南野外"  then
    if 成就数据[id].野猪==nil then
    成就数据[id].野猪=0
    end
    if 成就数据[id].野猪<101 then
    成就数据[id].野猪=成就数据[id].野猪+1
    end
    if 成就数据[id].野猪 == 1 then
    local 成就提示 = "宰的就是你"
    local 成就提示1 = "完成1次了野猪击杀"
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
    elseif 成就数据[id].野猪==100 then
    local 成就提示 = "荒漠屠夫"
    local 成就提示1 = "完成100次了野猪击杀"
    成就数据[id].成就点 = 成就数据[id].成就点 + 1
    常规提示(id,"#Y/恭喜你获得了1点成就")
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
     end
     if 成就数据[id].野猪==101 then
      玩家数据[id].角色:添加称谓(id,"荒漠屠夫")
      成就数据[id].野猪=成就数据[id].野猪+1
     end
    end
--嘎嘎跨服 暗雷掉落

    if 地图名称 =="子鼠界"or 地图名称 =="丑牛界"or 地图名称 =="寅虎界"or 地图名称 =="卯兔界"or 地图名称 =="辰龙界"or 地图名称 =="巳蛇界"or 地图名称 =="午马界"or 地图名称 =="未羊界"or 地图名称 =="申猴界"or 地图名称 =="酉鸡界"or 地图名称 =="戌狗界"or 地图名称 =="亥猪界"or 地图名称 =="乾坤界" then
        local 经验=0
        local 银子=0
        经验=500000
        银子=500000
            玩家数据[id].角色:添加经验(经验,"跨服12生肖地图")
            --玩家数据[id].角色:添加银子(银子,"跨服12生肖地图",1)
            for n=1,#玩家数据[id].召唤兽.数据 do
            玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验),id,"跨服12生肖地图",self.地图等级)
            end
    local 获奖几率 = 取随机数(1,325)


    if 获奖几率<=20 then
      玩家数据[id].角色:添加经验(5000000,"跨服生肖活动",1)
    --  常规提示(id,"#Y你获得了#R"..名称)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G500万经验".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    elseif 获奖几率<=40 then
      玩家数据[id].角色:添加银子(500000,"跨服生肖活动",1)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G300万银子".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    elseif 获奖几率<=100 then
      local 名称="随机宝石一"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y你获得了#R"..名称)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    elseif 获奖几率<=130 then
      local 名称="随机宝石二"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y你获得了#R"..名称)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=140 then
    --   local 名称="星辉石"
    --   玩家数据[id].道具:给予道具(id,名称,取随机数(3,5))
    --   常规提示(id,"#Y你获得了#R"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=145 then
    --   local 名称="星辉石"
    --   玩家数据[id].道具:给予道具(id,名称,取随机数(4,7))
    --   常规提示(id,"#Y你获得了#R"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=155 then
      local 名称="九转金丹"
      玩家数据[id].道具:给予道具(id,名称,1,100)
      常规提示(id,"#Y你获得了#R"..名称)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    elseif 获奖几率<=170 then
      local 名称="高级兽决礼包"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y你获得了#R"..名称)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=200 then
    --   local 名称="特赦令牌"
    --   玩家数据[id].道具:给予道具(id,名称,1)
    --   常规提示(id,"#Y你获得了#R"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=230 then
    --   local 名称="新仙玉锦囊"
    --   玩家数据[id].道具:给予道具(id,名称,1)
    --   常规提示(id,"#Y你获得了#R"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
     elseif 获奖几率<=235 then
      local 名称="灵饰指南书"
      玩家数据[id].道具:给予道具(id,"灵饰指南书",{8,10})
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    elseif 获奖几率<=237 then
      local 名称="灵饰指南书"
      玩家数据[id].道具:给予道具(id,"灵饰指南书",{8,12})
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=242 then
    --   local 名称="元灵晶石"
    --   玩家数据[id].道具:给予道具(id,"元灵晶石",{8,10})
    --   常规提示(id,"#Y/你获得了"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=244 then
    --   local 名称="元灵晶石"
    --   玩家数据[id].道具:给予道具(id,"元灵晶石",{8,12})
    --   常规提示(id,"#Y/你获得了"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=270 then
    --   local 名称="神兜兜"
    --    玩家数据[id].道具:给予道具(id,名称,1)
    --   常规提示(id,"#Y你获得了#R"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=280 then
    -- local 名称="140级随机书铁"
    --   玩家数据[id].道具:给予书铁(id,{14,14})
    --   常规提示(id,"#Y/你获得了"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=295 then
    -- local 名称="130级随机书铁"
    --   玩家数据[id].道具:给予书铁(id,{13,13})
    --   常规提示(id,"#Y/你获得了"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=315 then
    -- local 名称="120级随机书铁"
    --   玩家数据[id].道具:给予书铁(id,{12,12})
    --   常规提示(id,"#Y/你获得了"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    --  elseif 获奖几率<=317 then
    -- local 名称="150级随机书铁"
    --   玩家数据[id].道具:给予书铁(id,{15,15})
    --   常规提示(id,"#Y/你获得了"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
    -- elseif 获奖几率<=327 then
    -- local 名称="点化石"
    --   玩家数据[id].道具:给予道具(id,名称,1)
    --   常规提示(id,"#Y/你获得了"..名称)
    --   广播消息({内容=format("#S(跨服生肖活动)#G/%s#Y参与#R%s#Y获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"跨服生肖活动",名称),频道="xt"})
     end
end



      --心魔宝珠
    if 取随机数(1,100)<=10 then
      if 玩家数据[id].角色.数据.等级>=15 then
           玩家数据[id].道具:给予道具(id,"心魔宝珠",1)
           常规提示(id,"#Y你获得了心魔宝珠")
      end
    end
      -- 野外装备掉落
        if 取随机数(1,100)<=1 then
          野外掉落装备(id,self.地图等级)
          常规提示(id,"#Y你获得了一件#R装备\n目前挂野能获取到最高的装备只有40级")
          end
        -- if 取随机数()<=1 then
        -- 礼包奖励类:取随机装备(id,取随机数(60,70),"无级别限制")
        -- 常规提示(id,"#Y你获得了一件#R无级别装备")
        -- end
        -- if 取随机数()<=3 then
        --     野外掉落二级药(id,self.地图等级)
        --     end
        -- if 取随机数()<=4 then
        --     玩家数据[id].道具:给予道具(id,"金柳露",1)
        --     常规提示(id,"#Y你获得了金柳露")
        -- end

      if 玩家数据[id].角色.数据.等级>=self.等级下限 and 玩家数据[id].角色.数据.等级<=self.等级上限 and 取随机数(1,1000)<=20 then
        系统处理类:设置传说物品(id)
      end
      if 玩家数据[id].角色:取任务("飞升剧情")~=0 and 任务数据[玩家数据[id].角色:取任务("飞升剧情")].四法宝~=nil and 任务数据[玩家数据[id].角色:取任务("飞升剧情")].四法宝.修篁斧==false and 任务数据[玩家数据[id].角色:取任务("飞升剧情")].触发 then
        local 地图名称=取地图名称(玩家数据[id].角色.数据.地图数据.编号)
        local 任务id=玩家数据[id].角色:取任务("飞升剧情")
        if 地图名称=="普陀山" and 取随机数()<100 then
          任务数据[任务id].四法宝.修篁斧=true
          玩家数据[id].道具:给予道具(id,"修篁斧",1,nil,nil,"专用")
          --广播消息({内容=format("你得到了修篁斧"),频道="xt"})
          常规提示(id,"#Y你获得了修篁斧")
          玩家数据[id].角色:刷新任务跟踪()
        end
      end
      -- 赵捕头的赏金任务
      if 玩家数据[id].角色:取任务(6)~=0 then
        local 地图名称=取地图名称(玩家数据[id].角色.数据.地图数据.编号)
        local 任务id=玩家数据[id].角色:取任务(6)
        if 地图名称=="大雁塔一层" or 地图名称=="大雁塔二层" or 地图名称=="大雁塔三层"
          or 地图名称=="大雁塔四层" or 地图名称=="大雁塔五层" or 地图名称=="大雁塔六层"
          or 地图名称=="花果山" or 地图名称=="长寿郊外" or 地图名称=="大唐国境" or 地图名称=="大唐境外" then
          任务数据[任务id].数量=任务数据[任务id].数量-1
        end
        if 任务数据[任务id].数量<=0 then
            任务数据[任务id]=nil
            玩家数据[id].角色:取消任务(任务id)
            local 经验=0
            local 银子=0
            local 储备=0
            local 等级=玩家数据[id].角色.数据.等级
            经验=等级*95*2
            银子=等级*30*2
            活跃数据[id].活跃度=活跃数据[id].活跃度+20
            玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+20
            常规提示(id,"#Y/你获得了20点活跃度和10个心魔宝珠")
            玩家数据[id].道具:给予道具(id,"心魔宝珠",10)
            玩家数据[id].角色:添加经验(经验,"建邺城赏金任务")
            玩家数据[id].角色:添加银子(银子,"建邺城赏金任务",1)
            for n=1,#玩家数据[id].召唤兽.数据 do
            玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.35),id,"建邺城赏金任务",self.地图等级)
            end
            玩家数据[id].战斗对话={名称="皇宫护卫",模型="护卫",对话="你是否需要继续领取平定安邦任务？".."#"..取随机数(1,110),选项={"是的，我要继续平定安邦"}}
            玩家数据[id].护卫对话=1
          end
          玩家数据[id].角色:刷新任务跟踪()
        end
              -- 赵捕头的新手任务
      if 玩家数据[id].角色:取任务(66)~=0 then
        local 地图名称=取地图名称(玩家数据[id].角色.数据.地图数据.编号)
        local 任务id=玩家数据[id].角色:取任务(66)
        if 地图名称=="江南野外" or 地图名称=="东海湾" or 地图名称=="东海岩洞" or 地图名称=="东海海底" or 地图名称=="海底沉船" then
          任务数据[任务id].数量=任务数据[任务id].数量-1
        end
        if 任务数据[任务id].数量<=0 then
            任务数据[任务id]=nil
            玩家数据[id].角色:取消任务(任务id)
            local 等级=玩家数据[id].角色.数据.等级
            local 经验=0
            local 银子=0
            local 储备=0
            经验=等级*250
            银子=等级*200
            玩家数据[id].角色:添加经验(经验,"建邺城新手任务")
            玩家数据[id].角色:添加银子(银子,"建邺城新手任务",1)
            for n=1,#玩家数据[id].召唤兽.数据 do
            玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验),id,"建邺城新手任务",self.地图等级)
            end
            玩家数据[id].战斗对话={名称="赵捕头",模型="男人_衙役",对话="你是否需要继续领取新手任务？".."#"..取随机数(1,110),选项={"是的，我要继续领取"}}
            玩家数据[id].赵捕头对话=1
          end
          玩家数据[id].角色:刷新任务跟踪()
        end

    elseif self.战斗类型==100002 then--and id==任务数据[self.任务id].玩家id then --宝图强盗
      任务处理类:完成宝图任务(self.任务id)
    elseif self.战斗类型==100003 and id== self.进入战斗玩家id then --宝图强盗
      玩家数据[id].道具:完成宝图遇怪(id)
    elseif self.战斗类型==100019 then
    if 取随机数(1,100)<=10 then
    local 名称="炼妖石"
    玩家数据[id].道具:给予道具(id,名称,{65,105})
    常规提示(id,"#Y/你获得了"..名称)
    else
    玩家数据[id].角色:添加银子(500,"迷宫小怪",1)
    玩家数据[id].角色:添加经验(500,"迷宫小怪")
    常规提示(id,"#Y/我有10%的几率掉落炼妖石,很可惜你没有获得\n象征性的给你点#Y经验和银子#吧!")
    end
    elseif self.战斗类型==110002 then
    xsjc(id,3)
    elseif self.战斗类型==110016 then
    添加活动次数(id,"日常鬼魂")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,8})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    常规提示(id,"#Y你得到了#R高级魔兽要诀")
    if 取随机数(1,1000)<=1 then
    local 名称="高级魔兽要诀"
    local 技能=取特殊要诀()
    玩家数据[id].道具:给予道具(id,名称,nil,技能)
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    广播消息({内容=format("#S(商人鬼魂史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"商人的鬼魂"),频道="xt"})
    end
    玩家数据[id].角色:添加银子(500000,"日常鬼魂",1)
    玩家数据[id].角色:添加经验(1000000,"日常鬼魂")
    添加仙玉(5,玩家数据[id].账号,id,"日常鬼魂")
    广播消息({内容=format("#S(商人鬼魂史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"商人的鬼魂"),频道="xt"})
    elseif self.战斗类型==110034 then
    local 名称1="战魂"
    玩家数据[id].道具:给予道具(id,名称1,1)
    常规提示(id,"#Y/你获得了"..名称1)
    local 名称2="陨铁"
    玩家数据[id].道具:给予道具(id,名称2,1)
    常规提示(id,"#Y/你获得了"..名称2)
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{15,15})
    local 名称="高级魔兽要诀"
    local 技能=取特殊要诀()
    玩家数据[id].道具:给予道具(id,名称,nil,技能)
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].角色:添加银子(100000,"蚩尤大战",1)
    添加仙玉(100,玩家数据[id].账号,id,"蚩尤大战")
    广播消息({内容=format("#S(蚩尤大战)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"蚩尤","150级书铁+战魂+陨铁"),频道="xt"})
    添加活动次数(id,"蚩尤大战")
    elseif self.战斗类型==110035 then
    添加活动次数(id,"日常妖风")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,8})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    常规提示(id,"#Y你得到了#R高级魔兽要诀")
    if 取随机数(1,1000)<=1 then
    local 名称="高级魔兽要诀"
    local 技能=取特殊要诀()
    玩家数据[id].道具:给予道具(id,名称,nil,技能)
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    广播消息({内容=format("#S(妖风史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"妖风","特殊兽决"),频道="xt"})
    end
    玩家数据[id].角色:添加银子(500000,"日常鬼魂",1)
    玩家数据[id].角色:添加经验(1000000,"日常鬼魂")
    添加仙玉(5,玩家数据[id].账号,id,"日常鬼魂")
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8})
    常规提示(id,"#Y/你获得了灵饰书铁奖励")
    广播消息({内容=format("#S(妖风史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"妖风","80-100级灵饰书铁和100-120级装备书铁"),频道="xt"})
    elseif self.战斗类型==110135 then
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8})
    常规提示(id,"#Y/你获得了灵饰书铁奖励")
    玩家数据[id].角色:添加银子(100000,"日常妖风",1)
    添加仙玉(10,玩家数据[id].账号,id,"日常妖风")
    --添加点卡(10000,玩家数据[id].账号,id,"日常妖风")
    玩家数据[id].角色.数据.比武积分.当前积分=玩家数据[id].角色.数据.比武积分.当前积分+50000
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{14,15})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    常规提示(id,"#Y/你获得了#R50000比武积分")
    添加活动次数(id,"挑战刻晴")
    广播消息({内容=format("#S(挑战刻晴日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"刻晴","100-120级灵饰书铁和140-150级装备书铁"),频道="xt"})
    elseif self.战斗类型==110036 then
    添加活动次数(id,"日常白鹿")
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8})
    常规提示(id,"#Y/你获得了灵饰书铁奖励")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,8})
    常规提示(id,"#Y/你获得了书铁奖励")
    if 取随机数(1,1000)<=1 then
    local 名称="高级魔兽要诀"
    local 技能=取高级要诀()
    玩家数据[id].道具:给予道具(id,名称,nil,技能)
    常规提示(id,"#Y你得到了#R"..技能)
    广播消息({内容=format("#S(白鹿精史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"白鹿精","特殊兽决"),频道="xt"})
    end
    玩家数据[id].角色:添加银子(500000,"日常白鹿",1)
    玩家数据[id].角色:添加经验(1000000,"日常鬼魂")
    添加仙玉(10,玩家数据[id].账号,id,"日常白鹿")
    广播消息({内容=format("#S(白鹿精史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"白鹿精","100-120级灵饰书铁和120级书铁"),频道="xt"})

    elseif self.战斗类型==100223 then
    添加活动次数(id,"日常酒肉")
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8})
    常规提示(id,"#Y/你获得了灵饰书铁奖励")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,8})
    常规提示(id,"#Y/你获得了书铁奖励")
    local 名称="高级魔兽要诀"
    local 技能=取高级要诀()
    玩家数据[id].道具:给予道具(id,名称,nil,技能)
    常规提示(id,"#Y你得到了#R"..技能)
    玩家数据[id].角色:添加银子(1000000,"日常白鹿",1)
    玩家数据[id].角色:添加经验(5000000,"日常鬼魂")
    添加仙玉(10,玩家数据[id].账号,id,"日常白鹿")
    广播消息({内容=format("#S(酒肉和尚史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"酒肉和尚","120级灵饰书铁和130-140级书铁"),频道="xt"})

    elseif self.战斗类型==100224 then
    添加活动次数(id,"守门天兵")
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8})
    常规提示(id,"#Y/你获得了灵饰书铁奖励")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,8})
    常规提示(id,"#Y/你获得了书铁奖励")
    local 名称="高级魔兽要诀"
    local 技能=取高级要诀()
    玩家数据[id].道具:给予道具(id,名称,nil,技能)
    常规提示(id,"#Y你得到了#R"..技能)
    玩家数据[id].角色:添加银子(2000000,"日常白鹿",1)
    玩家数据[id].角色:添加经验(5000000,"日常鬼魂")
    添加仙玉(10,玩家数据[id].账号,id,"日常白鹿")
    广播消息({内容=format("#S(守门天兵史诗日常)#R/%s#Y和他的队友一起战胜了，#W%s#Y因此获得了#G/%s",玩家数据[id].角色.数据.名称,"守门天兵","120-140级灵饰书铁和140级书铁"),频道="xt"})


end

-------------------------------------------------------此处断层---剧情不能组队享受-------------------------------

   if self.战斗类型==110015 then
    if 玩家数据[id].角色:取任务(996) ~= 0 and 任务数据[玩家数据[id].角色:取任务(996)].进程 == 1 then
    任务数据[玩家数据[id].角色:取任务(996)].进程=2
    end
    添加活动次数(id,"天兵飞剑")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予道具(id,"九转金丹",10,100,nil,"专用")
    常规提示(id,"#Y/你获得了#G10#个九转金丹")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,7})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].道具:给予道具(id,"高级召唤兽内丹",1)
    玩家数据[id].道具:给予道具(id,"召唤兽内丹",1)
    常规提示(id,"#Y/你获得了高级召唤兽内丹,召唤兽内丹")
    玩家数据[id].角色:添加经验(800000,"天兵飞剑")
    玩家数据[id].角色:添加银子(500000,"天兵飞剑",1)
    添加仙玉(50,玩家数据[id].账号,id,"天兵飞剑")

    elseif self.战斗类型==110014 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 41 then
    xsjc2(id,42)
    end
    添加活动次数(id,"真刘洪")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    玩家数据[id].道具:给予道具(id,"九转金丹",5,100,nil,"专用")
    玩家数据[id].道具:给予道具(id,"高级召唤兽内丹",1)
    玩家数据[id].道具:给予道具(id,"召唤兽内丹",1)
    常规提示(id,"#Y/你获得了高级召唤兽内丹,召唤兽内丹")
    常规提示(id,"#Y/你获得了#G5#个九转金丹和高级魔兽要诀")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,6})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].角色:添加经验(1500000,"刘洪")
    玩家数据[id].角色:添加银子(500000,"刘洪",1)
    if 首杀记录.真刘洪==0 then
    首杀记录.真刘洪=玩家数据[id].角色.数据.名称
    广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"真刘洪"),频道="xt"})
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
    end
    if 成就数据[id].真刘洪==0 or 成就数据[id].真刘洪==nil then
       成就数据[id].真刘洪=1
      local 成就提示 = "真刘洪"
      local 成就提示1 = "完成玄奘身世系列任务"
      发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
      成就数据[id].成就点 = 成就数据[id].成就点 + 1
      常规提示(id,"#Y/恭喜你获得了1点成就")
     end
    elseif self.战斗类型==110013  then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 40 then
    xsjc2(id,41)
    end
    添加活动次数(id,"假刘洪")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    玩家数据[id].道具:给予道具(id,"九转金丹",5,100,nil,"专用")
    玩家数据[id].道具:给予道具(id,"高级召唤兽内丹",1)
    玩家数据[id].道具:给予道具(id,"召唤兽内丹",1)
    常规提示(id,"#Y/你获得了高级召唤兽内丹,召唤兽内丹")
    常规提示(id,"#Y/你获得了#G5#个九转金丹和高级魔兽要诀")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,6})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].角色:添加经验(800000,"刘洪")
    玩家数据[id].角色:添加银子(500000,"刘洪",1)
    玩家数据[id].战斗对话={名称="程咬金",模型="程咬金",对话="少侠你快去追击#Y真刘洪#吧,这里就交给我们善后了\n我估计他已经逃到#G大唐境外#去完了"}

    elseif self.战斗类型==110012 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 32 then
    xsjc2(id,33)
    end
    添加活动次数(id,"蟹将军")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    玩家数据[id].道具:给予道具(id,"九转金丹",5,100,nil,"专用")
    常规提示(id,"#Y/你获得了#G5#个九转金丹和高级魔兽要诀")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,6})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].角色:添加经验(800000,"蟹将")
    玩家数据[id].角色:添加银子(500000,"蟹将",1)
    if 首杀记录.蟹将军==0 then
    首杀记录.蟹将军=玩家数据[id].角色.数据.名称
    广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"蟹将军"),频道="xt"})
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
    end
    添加最后对话(id,"原来你是来归还#S定颜珠#的呀\n不好意思打错人了#17,我还以为你是#G偷盗的贼人#呢\n#P龟千岁#正等着你呢,快去吧~")

    elseif self.战斗类型==110011 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 20 then
    xsjc2(id,21)
    end
    添加活动次数(id,"幽冥鬼")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    玩家数据[id].道具:给予道具(id,"九转金丹",5,100,nil,"专用")
    常规提示(id,"#Y/你获得了#G5#个九转金丹和高级魔兽要诀")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,6})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].角色:添加经验(800000,"幽冥鬼")
    玩家数据[id].角色:添加银子(500000,"幽冥鬼",1)
    if 首杀记录.幽冥鬼==0 then
    首杀记录.幽冥鬼=玩家数据[id].角色.数据.名称
    广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"幽冥鬼"),频道="xt"})
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
    end
    添加最后对话(id,"其实我不是不想#Y轮回投胎#,只是我现在还放不下一人\n他叫#S文秀#,是我的妻子,我不知道她现在还过得这么样\n如果我能让我知道她还在世的话,我就放心了\n以前我们住在#G大唐国境#附近")

    elseif self.战斗类型==110010 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 17 then
    xsjc2(id,18)
    end
    添加活动次数(id,"酒肉和尚真")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    玩家数据[id].道具:给予道具(id,"月华露",10,100,nil,"专用")
    玩家数据[id].道具:给予道具(id,"九转金丹",5,100)
    玩家数据[id].道具:给予道具(id,"修炼果",5)
    常规提示(id,"#Y/你获得了#G10#个月华露和高级魔兽要诀\n5个九转金丹和5个修炼果")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{5,6})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].角色:添加经验(200000,"酒肉")
    玩家数据[id].角色:添加银子(200000,"酒肉",1)
    if 首杀记录.酒肉和尚==0 then
    首杀记录.酒肉和尚=玩家数据[id].角色.数据.名称
    广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"酒肉和尚"),频道="xt"})
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
    end
    if 成就数据[id].酒肉和尚==0 or 成就数据[id].酒肉和尚==nil then
    成就数据[id].酒肉和尚=1
    local 成就提示 = "玄奘身世上篇"
    local 成就提示1 = "完成酒肉和尚系列任务"
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
    成就数据[id].成就点 = 成就数据[id].成就点 + 1
    常规提示(id,"#Y/恭喜你获得了1点成就")
    end
    添加最后对话(id,"别打了,别打了,#Y我知错了#有个坏消息是:其实我也没有#G解药\n他这个毒需要用到仙家灵药#S九转回魂丹\n你可以去#P普陀山#问问,看谁有此药没#17")

    elseif self.战斗类型==110009 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 14 then
    xsjc2(id,15)
    end
    添加活动次数(id,"白琉璃")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    常规提示(id,"#Y/你获得了#佛光舍利子")
    玩家数据[id].道具:给予道具(id,"佛光舍利子",1,nil,nil,"专用")
    玩家数据[id].角色:添加经验(40000,"琉璃")
    玩家数据[id].角色:添加银子(10000,"琉璃",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",1,nil,nil,"专用")
    常规提示(id,"#Y/你获得了#G炼兽真经")
    添加最后对话(id,"你这个小东西还真有点意思,知道我的#Y弱点是暗器\n我也不瞒你说了,我的经历你大概应该知道了\n我偷佛光舍利的目的,其实就是想报答我的恩人#G卷帘大将#\n他为了让我们#S四姐妹#获得仙体,故意打碎了#Y琉璃盏\n从此我们获得了自由,但因此卷帘大将也被#R贬入凡间\n每天受#G七剑穿心#之苦,我不忍恩人受苦,采取偷取舍利\n希望能缓解他的痛苦,舍利我就交还与你了\n我现在变回#G琉璃碎片#,希望日后你有机会见到#S卷帘大将\n#P把我给他#14")

    elseif self.战斗类型==110008 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 13 then
    xsjc2(id,14)
    end
    添加活动次数(id,"执法天兵")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{3,4})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].角色:添加经验(40000,"天兵")
    玩家数据[id].角色:添加银子(10000,"天兵",1)
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil,"专用")
    玩家数据[id].道具:给予道具(id,"月华露",5,50,nil,"专用")
    玩家数据[id].道具:给予道具(id,"九转金丹",1,100)
    玩家数据[id].道具:给予道具(id,"修炼果",1)
    常规提示(id,"#Y/你获得了#G10#个月华露和高级魔兽要诀\n1个九转金丹和修炼果")
    if 首杀记录.守门天兵==0 then
    首杀记录.守门天兵=玩家数据[id].角色.数据.名称
    广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"守门天兵"),频道="xt"})
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
    end
    添加最后对话(id,"不好意思,我刚才不知道你是来打听#G白琉璃下落#的\n真是不打不相识,可能我们#R下手有点重#还望见谅\n你要找的#G白琉璃#是天宫的#Y琉璃盏#转世,只因卷帘大将失手摔碎#Y琉璃盏#才有的她\n但是我不知道为何她会盗取化生寺的#Y佛光舍利#\n但是我可以告诉你她的下落在哪,刚才我用#S千里眼#看了\n她就在#P大唐国境#附近,你去找他吧!")

    elseif self.战斗类型==110007 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 6 then
    xsjc2(id,7)
    end
    添加活动次数(id,"酒肉和尚假")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(20000,"酒肉")
    玩家数据[id].角色:添加银子(10000,"酒肉",1)
    玩家数据[id].道具:给予道具(id,"月华露",5,50,nil,"专用")
    常规提示(id,"#Y/你获得了#G5#个月华露")

    elseif self.战斗类型==110006 then
    if 玩家数据[id].角色:取任务(997) ~= 0 and 任务数据[玩家数据[id].角色:取任务(997)].进程 == 2 then
    xsjc2(id,3)
    end
    添加活动次数(id,"白鹿精")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(100000,"白鹿精")
    玩家数据[id].角色:添加银子(50000,"白鹿精",1)
    玩家数据[id].道具:给予道具(id,"月华露",5,50,nil,"专用")
    local 名称=取宝石()
    玩家数据[id].道具:给予道具(id,名称,取随机数(1,2))
    常规提示(id,"#Y/你获得了"..名称)
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{3,4})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    常规提示(id,"#Y/你获得了#G5个#Y月华露#和#G1个#R宝石")
    if 首杀记录.白鹿精==0 then
       首杀记录.白鹿精=玩家数据[id].角色.数据.名称
       广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"白鹿精"),频道="xt"})
      玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
      常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
     end
    if 成就数据[id].白鹿精==0 or 成就数据[id].白鹿精==nil then
       成就数据[id].白鹿精=1
     end

    elseif self.战斗类型==110004 then
    if 玩家数据[id].角色:取任务(998) ~= 0 and 任务数据[玩家数据[id].角色:取任务(998)].进程 == 11 then
    xsjc1(id,12)
    end
    添加活动次数(id,"商人的鬼魂")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(10000,"商人鬼魂")
    玩家数据[id].角色:添加银子(30000,"商人鬼魂",1)
    玩家数据[id].道具:给予道具(id,"月华露",5,50,nil,"专用")
    local 名称=取宝石()
    玩家数据[id].道具:给予道具(id,名称,取随机数(1,2))
    常规提示(id,"#Y/你获得了"..名称)
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{3,4})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    常规提示(id,"#Y/你获得了#G5个#Y月华露#和#G1个#R宝石")
    if 首杀记录.商人的鬼魂==0 then
       首杀记录.商人的鬼魂=玩家数据[id].角色.数据.名称
       广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"商人的鬼魂"),频道="xt"})
      玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
      常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
     end
    if 成就数据[id].商人鬼魂==0 or 成就数据[id].商人鬼魂==nil then
       成就数据[id].商人鬼魂=1
      local 成就提示 = "商人的鬼魂"
      local 成就提示1 = "完成建邺城系列任务"
      发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
      成就数据[id].成就点 = 成就数据[id].成就点 + 1
      常规提示(id,"#Y/恭喜你获得了1点成就")
     end








    elseif self.战斗类型==100229 then
    if 玩家数据[id].角色:取任务(500) ~= 0 and 任务数据[玩家数据[id].角色:取任务(500)].进程 == 7 then
    任务数据[玩家数据[id].角色:取任务(500)].进程=8
    end
    添加活动次数(id,"梦战灵鹤2")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"商人鬼魂")
    玩家数据[id].角色:添加银子(50000,"商人鬼魂",1)
    玩家数据[id].道具:给予道具(id,"月华露",5,50,nil,"专用")
    local 名称=取宝石()
    玩家数据[id].道具:给予道具(id,名称,取随机数(1,2))
    常规提示(id,"#Y/你获得了"..名称)
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{3,4})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    常规提示(id,"#Y/你获得了#G5个#Y月华露#和#G1个#R宝石")
    添加最后对话(id,"不愧是皓梦的徒弟真有两下次(#G去找太白金星,把仙丹给他吧#)")

    elseif self.战斗类型==100230 then
    if 玩家数据[id].角色:取任务(501) ~= 0 and 任务数据[玩家数据[id].角色:取任务(501)].进程 == 2 then
    任务数据[玩家数据[id].角色:取任务(501)].进程=3
    end
    添加活动次数(id,"梦战江南小盗")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(20000,"梦战小盗")
    玩家数据[id].角色:添加银子(20000,"梦战小盗",1)
    玩家数据[id].道具:给予道具(id,"天眼通符",50)
    常规提示(id,"#Y/你获得了#G50个#Y天眼通符")
    添加最后对话(id,"别打了别打了,我认输!#15")

    elseif self.战斗类型==100231 then
    if 玩家数据[id].角色:取任务(501) ~= 0 and 任务数据[玩家数据[id].角色:取任务(501)].进程 == 6 then
    任务数据[玩家数据[id].角色:取任务(501)].进程=7
    end
    添加活动次数(id,"梦战大大龟")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"大大龟")
    玩家数据[id].角色:添加银子(50000,"大大龟",1)
    玩家数据[id].道具:给予道具(id,"天眼通符",50)
    常规提示(id,"#Y/你获得了#G50个#Y天眼通符")
    添加最后对话(id,"别杀我们!我们走还不行嘛#15")

    elseif self.战斗类型==100232 then
    if 玩家数据[id].角色:取任务(501) ~= 0 and 任务数据[玩家数据[id].角色:取任务(501)].进程 == 9 then
    任务数据[玩家数据[id].角色:取任务(501)].进程=10
    end
    添加活动次数(id,"梦战绿皮蛙")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"绿皮蛙")
    玩家数据[id].角色:添加银子(50000,"绿皮蛙",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",2,nil,nil,"专用")
    常规提示(id,"#Y/你获得了#G2个#Y炼兽真经")
    添加最后对话(id,"你干嘛~~")

    elseif self.战斗类型==100233 then
    if 玩家数据[id].角色:取任务(501) ~= 0 and 任务数据[玩家数据[id].角色:取任务(501)].进程 == 12 then
    任务数据[玩家数据[id].角色:取任务(501)].进程=13
    end
    添加活动次数(id,"梦战屈原")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"屈原")
    玩家数据[id].角色:添加银子(50000,"屈原",1)
    玩家数据[id].道具:给予道具(id,"元宵",取随机数(1,5))
    常规提示(id,"#Y/你获得了元宵")
    添加最后对话(id,"有两下子嘛,小兄弟")

    elseif self.战斗类型==100234 then
    if 玩家数据[id].角色:取任务(501) ~= 0 and 任务数据[玩家数据[id].角色:取任务(501)].进程 == 14 then
    任务数据[玩家数据[id].角色:取任务(501)].进程=15
    end
    添加活动次数(id,"梦战狂盗")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"狂盗")
    玩家数据[id].角色:添加银子(50000,"狂盗",1)
    玩家数据[id].道具:给予道具(id,"元宵",取随机数(1,5))
    常规提示(id,"#Y/你获得了元宵")
    添加最后对话(id,"你..你这是趁人之危\n我因夺取百鲜丹受了重伤\n不然怎么会打不过你!\n我现在是打不过你,不过作为盗贼\n啊呸,作为大盗\n我逃跑技术可是登峰造极,我跑!")

    elseif self.战斗类型==100236 then
    if 玩家数据[id].角色:取任务(502) ~= 0 and 任务数据[玩家数据[id].角色:取任务(502)].进程 == 1 then
    任务数据[玩家数据[id].角色:取任务(502)].进程=2
    end
    添加活动次数(id,"梦战马全有")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(100000,"马全有")
    玩家数据[id].角色:添加银子(100000,"马全有",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",1)
    常规提示(id,"#Y/你获得了炼兽真经")
    添加最后对话(id,"别打了,我知道错了,我以后不在海毛虫下崽的时候抓它们就是了!#17")

    elseif self.战斗类型==100237 then
    if 玩家数据[id].角色:取任务(502) ~= 0 and 任务数据[玩家数据[id].角色:取任务(502)].进程 == 2 then
    任务数据[玩家数据[id].角色:取任务(502)].进程=3
    end
    添加活动次数(id,"梦战海盗头子")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(100000,"海盗头子")
    玩家数据[id].角色:添加银子(100000,"海盗头子",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",1)
    常规提示(id,"#Y/你获得了炼兽真经")
    添加最后对话(id,"算你牛,我们吉祥三宝第一次输给一个凡人,真是奇耻大辱#4\n(回到#Y小小七#那里交任务)")

    elseif self.战斗类型==100238 then
    if 玩家数据[id].角色:取任务(502) ~= 0 and 任务数据[玩家数据[id].角色:取任务(502)].进程 == 6 then
    任务数据[玩家数据[id].角色:取任务(502)].进程=7
    end
    添加活动次数(id,"梦战浪鬼")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(100000,"梦战浪鬼")
    玩家数据[id].角色:添加银子(100000,"梦战浪鬼",1)
    玩家数据[id].道具:给予道具(id,"高级召唤兽内丹",1)
    玩家数据[id].道具:给予道具(id,"召唤兽内丹",1)
    常规提示(id,"#Y/你获得了高级召唤兽内丹,召唤兽内丹")






    elseif self.战斗类型==100243 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 1 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=2
    end
    添加活动次数(id,"洛树妖")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"洛树妖")
    玩家数据[id].角色:添加银子(50000,"洛树妖",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",1)
    常规提示(id,"#Y/你获得了炼兽真经")
    添加最后对话(id,"算你厉害!")
    elseif self.战斗类型==100244 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 4 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=5
    end
    添加活动次数(id,"赌徒喽啰")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"赌徒喽啰")
    玩家数据[id].角色:添加银子(50000,"赌徒喽啰",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",1)
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你获得了炼兽真经")
    常规提示(id,"#Y/你获得了#G高级兽决#")
    添加最后对话(id,"真是厉害!")
    elseif self.战斗类型==100245 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 6 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=7
    end
    添加活动次数(id,"江州县令")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(50000,"赌徒喽啰")
    玩家数据[id].角色:添加银子(50000,"赌徒喽啰",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",1)
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你获得了炼兽真经")
    常规提示(id,"#Y/你获得了#G高级兽决#")
    添加最后对话(id,"真是厉害!")
    elseif self.战斗类型==100246 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 9 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=10
    end
    添加活动次数(id,"江洋大盗")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(200000,"江洋大盗")
    玩家数据[id].角色:添加银子(200000,"江洋大盗",1)
    玩家数据[id].道具:给予道具(id,"炼兽真经",1)
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    玩家数据[id].道具:给予道具(id,"高级召唤兽内丹",1)
    玩家数据[id].道具:给予道具(id,"召唤兽内丹",1)
    常规提示(id,"#Y/你获得了高级召唤兽内丹,召唤兽内丹")
    常规提示(id,"#Y/你获得了炼兽真经")
    常规提示(id,"#Y/你获得了#G高级兽决#")
    添加最后对话(id,"真是厉害!")

    elseif self.战斗类型==100247 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 11 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=12
    end
    添加活动次数(id,"洛川鬼")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(200000,"洛川鬼")
    玩家数据[id].角色:添加银子(200000,"洛川鬼",1)
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,6})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,6})
    常规提示(id,"#Y/你获得了#S灵饰书铁奖励#")
    常规提示(id,"#Y/你获得了#G高级兽决#")
    添加最后对话(id,"真是厉害!")

    elseif self.战斗类型==100248 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 14 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=15
    end
    添加活动次数(id,"妩媚狐仙")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(200000,"妩媚狐仙")
    玩家数据[id].角色:添加银子(200000,"妩媚狐仙",1)
    玩家数据[id].道具:给予道具(id,"附魔宝珠",1,nil,nil)
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,6})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,6})
    常规提示(id,"#Y/你获得了#S灵饰书铁奖励#")
    常规提示(id,"#Y/你获得了#G附魔宝珠#")
    添加最后对话(id,"真是厉害!")

    elseif self.战斗类型==100249 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 15 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=16
    end
    添加活动次数(id,"赌霸城")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(200000,"赌霸城")
    玩家数据[id].角色:添加银子(200000,"赌霸城",1)
    玩家数据[id].道具:给予道具(id,"附魔宝珠",1,nil,nil)
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,6})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,6})
    常规提示(id,"#Y/你获得了#S灵饰书铁奖励#")
    常规提示(id,"#Y/你获得了#G附魔宝珠#")
    添加最后对话(id,"真是厉害!")

    elseif self.战斗类型==100250 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 17 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=18
    end
    添加活动次数(id,"半阁守将")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(200000,"半阁守将")
    玩家数据[id].角色:添加银子(200000,"半阁守将",1)
    玩家数据[id].道具:给予道具(id,"附魔宝珠",1,nil,nil)
    玩家数据[id].道具:给予道具(id,"彩果",15,nil,nil)
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,6})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,6})
    常规提示(id,"#Y/你获得了#S灵饰书铁奖励#")
    常规提示(id,"#Y/你获得了#G附魔宝珠和彩果#")
    添加最后对话(id,"真是厉害!")

    elseif self.战斗类型==100251 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 19 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=20
    end
    添加活动次数(id,"流氓兔")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(200000,"流氓兔")
    玩家数据[id].角色:添加银子(200000,"流氓兔",1)
    玩家数据[id].道具:给予道具(id,"附魔宝珠",1,nil,nil)
    玩家数据[id].道具:给予道具(id,"吸附石",10,nil,nil)
    玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,6})
    玩家数据[id].道具:给予道具(id,"元灵晶石",{6,6})
    常规提示(id,"#Y/你获得了#S灵饰书铁奖励#")
    常规提示(id,"#Y/你获得了#G附魔宝珠和吸附石#")
    添加最后对话(id,"真是厉害!")

    elseif self.战斗类型==100254 then
    if 玩家数据[id].角色:取任务(503) ~= 0 and 任务数据[玩家数据[id].角色:取任务(503)].进程 == 20 then
    任务数据[玩家数据[id].角色:取任务(503)].进程=21
    end
    添加活动次数(id,"大雁塔塔主")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(200000,"大雁塔塔主")
    玩家数据[id].角色:添加银子(200000,"大雁塔塔主",1)
    玩家数据[id].道具:给予道具(id,"附魔宝珠",1,nil,nil)
    玩家数据[id].道具:给予道具(id,"吸附石",10,nil,nil)
    玩家数据[id].道具:给予书铁(id,{7,8},"指南书")
    玩家数据[id].道具:给予书铁(id,{7,8},"精铁")
    常规提示(id,"#Y/你获得了#S70-80级书铁奖励#")
    常规提示(id,"#Y/你获得了#G附魔宝珠和吸附石#")
    添加最后对话(id,"真是厉害!")

     elseif self.战斗类型==100255 then
    if 玩家数据[id].角色:取任务(996) ~= 0 and 任务数据[玩家数据[id].角色:取任务(996)].进程 == 2 then
    任务数据[玩家数据[id].角色:取任务(996)].进程=3
    end
    添加活动次数(id,"卷帘大将1")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予道具(id,"九转金丹",10,100,nil,"专用")
    常规提示(id,"#Y/你获得了#G10#个九转金丹")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,7})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].道具:给予道具(id,"高级召唤兽内丹",1)
    玩家数据[id].道具:给予道具(id,"召唤兽内丹",1)
    常规提示(id,"#Y/你获得了高级召唤兽内丹,召唤兽内丹")
    玩家数据[id].角色:添加经验(800000,"卷帘大将1")
    玩家数据[id].角色:添加银子(500000,"卷帘大将1",1)
    添加仙玉(50,玩家数据[id].账号,id,"卷帘大将1")

    elseif self.战斗类型==100257 then
    if 玩家数据[id].角色:取任务(996) ~= 0 and 任务数据[玩家数据[id].角色:取任务(996)].进程 == 9 then
    任务数据[玩家数据[id].角色:取任务(996)].进程=10
    end
    添加活动次数(id,"路人甲")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,7})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].道具:给予道具(id,"附魔宝珠",2)
    玩家数据[id].道具:给予道具(id,"坐骑内丹",2)
    常规提示(id,"#Y/你获得了附魔宝珠,坐骑内丹")
    玩家数据[id].角色:添加经验(800000,"路人甲")
    玩家数据[id].角色:添加银子(500000,"路人甲",1)

    elseif self.战斗类型==100258 then
    if 玩家数据[id].角色:取任务(996) ~= 0 and 任务数据[玩家数据[id].角色:取任务(996)].进程 == 12 then
    任务数据[玩家数据[id].角色:取任务(996)].进程=13
    end
    添加活动次数(id,"杨戬")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{7,8})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].道具:给予道具(id,"附魔宝珠",2)
    玩家数据[id].道具:给予道具(id,"坐骑内丹",2)
    常规提示(id,"#Y/你获得了附魔宝珠,坐骑内丹")
    玩家数据[id].角色:添加经验(800000,"杨戬")
    玩家数据[id].角色:添加银子(500000,"杨戬",1)

    elseif self.战斗类型==100259 then
    if 玩家数据[id].角色:取任务(996) ~= 0 and 任务数据[玩家数据[id].角色:取任务(996)].进程 == 13 then
    任务数据[玩家数据[id].角色:取任务(996)].进程=14
    end
    添加活动次数(id,"龙孙")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    local 奖励数据=玩家数据[id].道具:给予书铁(id,{7,8})
    常规提示(id,"#Y你得到了#R"..奖励数据[1])
    玩家数据[id].道具:给予道具(id,"星辉石",取随机数(1,2))
    local 名称=取宝石()
    玩家数据[id].道具:给予道具(id,名称,取随机数(3,5))
    常规提示(id,"#Y/你获得了星辉石,各种3-5级宝石")
    玩家数据[id].角色:添加经验(800000,"龙孙")
    玩家数据[id].角色:添加银子(500000,"龙孙",1)

    elseif self.战斗类型==100260 then
    if 玩家数据[id].角色:取任务(996) ~= 0 and 任务数据[玩家数据[id].角色:取任务(996)].进程 == 15 then
    local 任务id=玩家数据[id].角色:取任务(996)
    玩家数据[id].角色:取消任务(任务id)
    if 成就数据[id].大战心魔==0 or 成就数据[id].大战心魔==nil then
       成就数据[id].大战心魔=1
      local 成就提示 = "大战心魔"
      local 成就提示1 = "完成大战心魔系列任务"
      发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
      成就数据[id].成就点 = 成就数据[id].成就点 + 1
      常规提示(id,"#Y/恭喜你获得了1点成就")
     end
    end
    添加活动次数(id,"卷帘大将3")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].道具:给予书铁(id,{8,8},"指南书")
    玩家数据[id].道具:给予书铁(id,{8,8},"精铁")
    常规提示(id,"#Y/你获得了#S80级书铁奖励#")
    玩家数据[id].道具:给予道具(id,"星辉石",取随机数(2,3))
    local 名称=取宝石()
    玩家数据[id].道具:给予道具(id,名称,取随机数(5,5))
    常规提示(id,"#Y/你获得了星辉石,各种5级宝石")
    玩家数据[id].角色:添加经验(800000,"卷帘大将3")
    玩家数据[id].角色:添加银子(500000,"卷帘大将3",1)

    elseif self.战斗类型==100261 then
    if 成就数据[id].突破任务==0 or 成就数据[id].突破任务==nil then
       成就数据[id].突破任务=1
     end
    添加最后对话(id,"恭喜你完成突破战斗,现在你可以升级到109了！")
    玩家数据[id].角色:添加剧情点5()
    常规提示(id,"#Y/你获得了#G5点#剧情点数")
    elseif self.战斗类型==100262 then
    if 玩家数据[id].角色:取任务(504) ~= 0 and 任务数据[玩家数据[id].角色:取任务(504)].进程 == 1 then
    任务数据[玩家数据[id].角色:取任务(504)].进程=2
    end
    添加活动次数(id,"空慈方丈")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(20000000,"空慈方丈")
    玩家数据[id].角色:添加银子(500000,"空慈方丈",1)
    玩家数据[id].道具:给予道具(id,"钨金",1)
    玩家数据[id].道具:给予道具(id,"内丹",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予书铁(id,{9,9},"指南书")
    玩家数据[id].道具:给予书铁(id,{9,9},"精铁")
    添加最后对话(id,"哼，我们走着瞧。")
    常规提示(id,"#Y/你获得了#Y90级书铁#,#G1个钨金#,#S1套法宝材料#")
    elseif self.战斗类型==100263 then
    if 玩家数据[id].角色:取任务(504) ~= 0 and 任务数据[玩家数据[id].角色:取任务(504)].进程 == 3 then
    任务数据[玩家数据[id].角色:取任务(504)].进程=4
    end
    添加活动次数(id,"王福来")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(20000000,"王福来")
    玩家数据[id].角色:添加银子(500000,"王福来",1)
    玩家数据[id].道具:给予道具(id,"钨金",1)
    玩家数据[id].道具:给予道具(id,"内丹",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予书铁(id,{9,9},"指南书")
    玩家数据[id].道具:给予书铁(id,{9,9},"精铁")
    常规提示(id,"#Y/你获得了#Y90级书铁#,#G1个钨金#,#S1套法宝材料#")
    elseif self.战斗类型==100264 then
    if 玩家数据[id].角色:取任务(504) ~= 0 and 任务数据[玩家数据[id].角色:取任务(504)].进程 == 5 then
    任务数据[玩家数据[id].角色:取任务(504)].进程=6
    end
    添加活动次数(id,"蓝火兽")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(20000000,"蓝火兽")
    玩家数据[id].角色:添加银子(500000,"蓝火兽",1)
    玩家数据[id].道具:给予道具(id,"钨金",1)
    玩家数据[id].道具:给予道具(id,"内丹",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予书铁(id,{9,9},"指南书")
    玩家数据[id].道具:给予书铁(id,{9,9},"精铁")
    常规提示(id,"#Y/你获得了#Y90级书铁#,#G1个钨金#,#S1套法宝材料#")
    elseif self.战斗类型==100265 then
    if 玩家数据[id].角色:取任务(504) ~= 0 and 任务数据[玩家数据[id].角色:取任务(504)].进程 == 6 then
    任务数据[玩家数据[id].角色:取任务(504)].进程=7
    end
    添加活动次数(id,"吸血蝙蝠")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(20000000,"吸血蝙蝠")
    玩家数据[id].角色:添加银子(500000,"吸血蝙蝠",1)
    玩家数据[id].道具:给予道具(id,"钨金",1)
    玩家数据[id].道具:给予道具(id,"内丹",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予书铁(id,{9,9},"指南书")
    玩家数据[id].道具:给予书铁(id,{9,9},"精铁")
    常规提示(id,"#Y/你获得了#Y90级书铁#,#G1个钨金#,#S1套法宝材料#")

    elseif self.战斗类型==100266 then
    local 任务id=玩家数据[id].角色:取任务(504)
    玩家数据[id].角色:取消任务(任务id)
    添加活动次数(id,"肾宝狼")
    玩家数据[id].角色:添加剧情点1()
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    玩家数据[id].角色:添加经验(20000000,"肾宝狼")
    玩家数据[id].角色:添加银子(500000,"肾宝狼",1)
    玩家数据[id].道具:给予道具(id,"钨金",1)
    玩家数据[id].道具:给予道具(id,"内丹",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予道具(id,"金凤羽",1)
    玩家数据[id].道具:给予书铁(id,{9,9},"指南书")
    玩家数据[id].道具:给予书铁(id,{9,9},"精铁")
    添加最后对话(id,"新剧情暂时结束了等待下次更新！")
    常规提示(id,"#Y/你获得了#Y90级书铁#,#G1个钨金#,#S1套法宝材料#")


    elseif self.战斗类型==110005 and 玩家数据[id].角色.数据.妖风战斗== nil then
    玩家数据[id].角色:添加剧情点1()
    添加活动次数(id,"妖风战斗")
    常规提示(id,"#Y/你获得了#G1点#剧情点数")
    --玩家数据[id].道具:给予道具(id,"青花瓷",1,nil,nil,"专用")
    local 任务id=玩家数据[id].角色:取任务(898)
    玩家数据[id].角色:取消任务(任务id)
    玩家数据[id].角色:添加经验(50000,"妖风")
    玩家数据[id].角色:添加银子(30000,"妖风",1)
    玩家数据[id].道具:给予道具(id,"月华露",5,50,nil,"专用")
    玩家数据[id].道具:给予道具(id,"超级金柳露",10,nil,nil,"专用")
    玩家数据[id].道具:给予道具(id,"金柳露",20,nil,nil,"专用")
    常规提示(id,"#Y/你获得了月华露,超级金柳露,金柳露")
    --常规提示(id,"#Y/你获得了一件#G青花瓷#锦衣")
    if 首杀记录.妖风==0 then
    首杀记录.妖风=玩家数据[id].角色.数据.名称
    广播消息({内容=format("#S(首杀公告)#Y恭喜%s#R成功首杀#G%s#Y大家为他欢呼吧!",玩家数据[id].角色.数据.名称,"妖风"),频道="xt"})
    玩家数据[id].道具:给予道具(id,"高级魔兽要诀",1,nil,nil)
    常规提示(id,"#Y/你额外获得首杀奖励:\n#G高级兽决#")
    end
    玩家数据[id].角色.数据.妖风战斗=1

    elseif self.战斗类型==110003 then
    if 玩家数据[id].角色:取任务(999) ~= 0 and 任务数据[玩家数据[id].角色:取任务(999)].进程 == 7 then
        local 任务id=玩家数据[id].角色:取任务(999)
        玩家数据[id].角色:取消任务(任务id)
        任务处理类:设置商人的鬼魂(id)
    end
    if 成就数据[id].完成桃园==nil then
       成就数据[id].完成桃园=1
    local 成就提示 = "初入桃源村"
    local 成就提示1 = "完成桃源村系列任务"
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
    成就数据[id].成就点 = 成就数据[id].成就点 + 1
    常规提示(id,"#Y/恭喜你获得了1点成就")
    end



end


--------------------------------------------------------以上剧情不能组队享受------------------------------------------------------------------








    if self.战斗类型==100226 then
    任务数据[玩家数据[id].角色:取任务(401)].进程=2
    if 支线奖励[id]==nil or 支线奖励[id].狸猫奖励==nil then
    支线奖励[id]={}
    支线奖励[id].狸猫奖励=true
    end
    常规提示(id,"#Y快去找郭大哥领取奖励吧")

    elseif self.战斗类型==100227 then
    任务数据[玩家数据[id].角色:取任务(400)].进程=7
    if 支线奖励[id]==nil or 支线奖励[id].虎子奖励==nil then
    支线奖励[id]={}
    支线奖励[id].虎子奖励=true
    end
    常规提示(id,"#Y快去找云游神医问个究竟!")

	elseif self.战斗类型==100222 then
	  local 玩家门派 = 玩家数据[id].角色.数据.门派
	  local 首席玩家数据={积分=0,奖励=false,id=id,连胜次数=0,等级=玩家数据[id].角色.数据.等级,名称=玩家数据[id].角色.数据.名称,模型=玩家数据[id].角色.数据.模型,染色组=玩家数据[id].角色.数据.染色组,染色方案=玩家数据[id].角色.数据.染色方案}
	  if 玩家数据[id].角色.数据.装备[3] ~= nil and 玩家数据[id].道具.数据[玩家数据[id].角色.数据.装备[3]] ~= nil then
		  首席玩家数据.武器=玩家数据[id].道具.数据[玩家数据[id].角色.数据.装备[3]].名称
		  首席玩家数据.武器等级=玩家数据[id].道具.数据[玩家数据[id].角色.数据.装备[3]].级别限制
		  首席玩家数据.武器染色方案=玩家数据[id].道具.数据[玩家数据[id].角色.数据.装备[3]].染色方案
		  首席玩家数据.武器染色组=玩家数据[id].道具.数据[玩家数据[id].角色.数据.装备[3]].染色组
	  end
	  首席争霸[玩家门派]=首席玩家数据
	  玩家数据[id].角色:添加称谓(id,玩家门派.."首席大弟子")
	  常规提示(id,"恭喜你，获得了#R"..玩家门派.."首席大弟子#Y称谓！！！")
	  地图处理类:删除单位(Q_首席弟子[玩家门派].地图,1000)
	  保存系统数据()
	  任务处理类:加载首席单位()

    elseif self.战斗类型==100008 and 取任务符合id(id,self.任务id) then
      local 等级1=玩家数据[id].角色.数据.等级
      local 等级=取队伍平均等级(玩家数据[id].队伍,id)
      local 奖励影响=self:取野外等级差(等级,等级1)
      local 经验=qz((等级*40*4*(玩家数据[id].角色.数据.捉鬼次数*1.1))*奖励影响)
      local 银子=qz((等级*40*3*(玩家数据[id].角色.数据.捉鬼次数*1.1))*奖励影响)
      添加活动次数(id,"抓鬼任务")
      玩家数据[id].角色:添加经验(经验,"捉鬼")
      玩家数据[id].角色:添加银子(银子,"捉鬼",1)
      活跃数据[id].活跃度=活跃数据[id].活跃度+2
      玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+2
      if 任务数据[self.任务id].变异奖励  then
        local 银子=取随机数(20000,40000)
        玩家数据[id].角色:添加银子(银子,"捉鬼触发变异",1)
        广播消息({内容=format("#S(捉鬼任务)#R/%s#Y在捉鬼任务中成功保护了#W%s#Y因此获得了其赠送的#G/%s#Y两银子".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,"善良的"..任务数据[self.任务id].模型,银子),频道="xt"})
      end
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.8),id,"捉鬼",self.地图等级)
      end
      玩家数据[id].角色:取消任务(self.任务id)
      if 玩家数据[id].角色.数据.捉鬼次数==10 then
        if 取随机数()<=10 then
          玩家数据[id].道具:取随机装备(id,取随机数(6,8))
          广播消息({内容=format("#S(捉鬼任务)#R/%s#Y完成抓鬼任务中表现优异，#W%s#Y因此获得了其赠送的#G60-80级装备",玩家数据[id].角色.数据.名称,"钟馗",名称),频道="xt"})
          常规提示(id,"#Y/你获得了60-80级装备")
        end
      end
      玩家数据[id].角色.数据.捉鬼次数=玩家数据[id].角色.数据.捉鬼次数+1
      if 玩家数据[id].角色.数据.捉鬼次数>10 then
        玩家数据[id].角色.数据.捉鬼次数=1
      end
      if id==self.进入战斗玩家id then
        玩家数据[id].战斗对话={名称="钟馗",模型="男人_钟馗",对话="少侠干得不错哟，如果你愿意继续协助我捉拿这些小鬼，我可以帮你直接传送回阴曹地府哟。".."#"..取随机数(1,110),选项={"把我送回来","我不想协助你了"}}
        玩家数据[id].钟馗对话=1
      end
    if 成就数据[id].抓鬼==nil then
    成就数据[id].抓鬼=0
    end
    if 成就数据[id].抓鬼<1001 then
    成就数据[id].抓鬼=成就数据[id].抓鬼+1
    end
    if 成就数据[id].抓鬼 == 1 then
    local 成就提示 = "钟馗小帮手"
    local 成就提示1 = "完成1次了抓鬼"
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
    elseif 成就数据[id].抓鬼==1000 then
    local 成就提示 = "钟馗小帮手"
    local 成就提示1 = "完成1000次了抓鬼"
    成就数据[id].成就点 = 成就数据[id].成就点 + 1
    常规提示(id,"#Y/恭喜你获得了1点成就")
    发送数据(玩家数据[id].连接id,149,{内容=成就提示,内容1=成就提示1})
    玩家数据[id].角色:添加称谓(id,"僵尸道长")
    end
    elseif self.战斗类型==100009 then
      local 等级=取队伍平均等级(玩家数据[id].队伍,id)
      local 经验=等级*3000*2
      local 银子=等级*3000*2
      添加活动次数(id,"星宿")
      玩家数据[id].角色:添加经验(经验,"二十八星宿")
      玩家数据[id].角色:添加银子(银子,"二十八星宿",1)
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"二十八星宿",self.地图等级)
      end
        活跃数据[id].活跃度=活跃数据[id].活跃度+50
        玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+50
      local 奖励参数=取随机数(1,300)
        if 奖励参数<=35 then
        local 奖励数据=玩家数据[id].道具:给予书铁(id,{11,13})
        local 名称=奖励数据[1]
        常规提示(id,"#Y你得到了#R"..名称)
        广播消息({内容=format("#S(十二星宿)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"110-120级书铁"),频道="xt"})
        elseif 奖励参数<=45 then
          local 名称="附魔宝珠"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(十二星宿)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，#Y因此获得了唐王奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
        elseif 奖励参数<=60 then
          local 名称="点化石"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(十二星宿)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，#Y因此获得了唐王奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
        elseif 奖励参数<=85 then
          local 名称="易经丹"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(十二星宿)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，#Y因此获得了唐王奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
        elseif 奖励参数<=90 then
          local 名称="月华露"
          玩家数据[id].道具:给予道具(id,名称,1,100)
          常规提示(id,"#Y/你获得了"..名称)
        elseif 奖励参数<=100 then
          local 名称="高级魔兽要诀"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
        elseif 奖励参数<=110 then
          local 名称="炼兽真经"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
        elseif 奖励参数<=120 then
          玩家数据[id].道具:给予道具(id,"清灵净瓶",1)
          常规提示(id,"#Y/你获得了清灵净瓶")

        end

    elseif self.战斗类型==100010 then
      local 等级=取队伍平均等级(玩家数据[id].队伍,id)
      local 经验=等级*120*2
      local 银子=等级*60*2
      添加活动次数(id,"妖魔鬼怪")
      玩家数据[id].角色:添加经验(经验,"妖魔鬼怪")
      玩家数据[id].角色:添加银子(银子,"妖魔鬼怪",1)
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"妖魔鬼怪",self.地图等级)
      end
      if 妖魔积分[id]==nil then
         妖魔积分[id]={当前=0,总计=0,使用=0}
      end
      活跃数据[id].活跃度=活跃数据[id].活跃度+2
      玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+2
      妖魔积分[id].当前=妖魔积分[id].当前+1
      妖魔积分[id].总计=妖魔积分[id].总计+1
      常规提示(id,"#Y/你获得了1点妖魔积分，#Y妖魔积分#可以在#G商城积分#兑换里面#R换取内丹")
        local 随机参数 = 取随机数(1,100)
        if 随机参数<=30  then
          local 名称="魔兽要诀"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(妖魔鬼怪)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，#Y因此获得了唐王奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
        elseif 随机参数<=40 then
          local 名称="彩果"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
        elseif 随机参数<=50  then
          local 名称="制造指南书"
          local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,8})
          常规提示(id,"#Y/你获得了"..名称)
         广播消息({内容=format("#S(妖魔鬼怪)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，#Y因此获得了唐王奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"60-100灵饰书"),频道="xt"})
        elseif 随机参数<=60  then
          local 名称="百炼精铁"
          local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,8})
          常规提示(id,"#Y/你获得了"..名称)
         广播消息({内容=format("#S(妖魔鬼怪)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，#Y因此获得了唐王奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"60-100灵饰铁"),频道="xt"})
        end

    elseif self.战斗类型==100011 then
      local 等级=取队伍平均等级(玩家数据[id].队伍,id)
      local 任务id1=玩家数据[id].角色:取任务(107)
      local 经验=等级*3000*2
      local 银子=等级*200*2
      if 妖魔积分[id]==nil then
      妖魔积分[id]={当前=0,总计=0,使用=0}
      end
      妖魔积分[id].当前=妖魔积分[id].当前+3
      妖魔积分[id].总计=妖魔积分[id].总计+3
      常规提示(id,"#Y/你获得了3点妖魔积分\n(#G可用于兑换和幸运转盘抽奖#)")
      添加活动次数(id,"门派闯关")
      玩家数据[id].角色:添加经验(经验,"门派闯关")
      玩家数据[id].角色:添加银子(银子,"门派闯关",1)
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"门派闯关",self.地图等级)
      end
        活跃数据[id].活跃度=活跃数据[id].活跃度+5
        玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+5
        常规提示(id,"#Y/你获得了5点活跃度\n(#G用于领取奖励和签到#)")
          local 奖励参数=取随机数(10,520)
          if 奖励参数<=5 then
          local 名称="高级魔兽要诀"
          玩家数据[id].道具:给予道具(id,名称)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=30 then
         local 名称=取强化石()
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=40 then
          local 名称="随机宝石一"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=50 then
        local 名称="高级召唤兽内丹"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=60 then
           local 名称="彩果"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=70 then
          local 名称="星辉石"
          玩家数据[id].道具:给予道具(id,名称,取随机数(1,3))
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=80 then
          名称=玩家数据[id].道具:取五宝()
          玩家数据[id].道具:给予道具(id,名称,取随机数(1,5))
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=90 then
          local 名称="召唤兽内丹"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

        elseif 奖励参数<=100 then
          local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,13})
          常规提示(id,"#Y你得到了#R"..奖励数据[1])
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

         elseif 奖励参数<=110 then
          local 奖励数据=玩家数据[id].道具:给予书铁(id,{6,13})
          常规提示(id,"#Y你得到了#R"..奖励数据[1])
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

           elseif 奖励参数<=120 then
          local 名称="海马"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

           elseif 奖励参数<=130 then
          local 名称="金柳露"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=140 then
          local 名称="超级金柳露"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=150 then
          local 名称="珍珠"
          玩家数据[id].道具:给予道具(id,名称,160)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=160 then
          local 名称="魔兽要诀"
          玩家数据[id].道具:给予道具(id,名称)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=170 then
          local 名称="怪物卡片"
          玩家数据[id].道具:给予道具(id,名称,取随机数(1,8))
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=180 then
          local 名称="未激活的符石"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=190 then
          local 名称="九转金丹"
          玩家数据[id].道具:给予道具(id,名称,1,150)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=200 then
          local 名称="修炼果"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=210 then
          local 名称="月华露"
          玩家数据[id].道具:给予道具(id,名称,1,300)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=220 then
          local 名称="灵饰指南书"
          玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8,10,12})
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=230 then
          local 名称="元灵晶石"
          玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8,10,12})
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=240 then
          local 名称="神兜兜"
          玩家数据[id].道具:给予道具(id,"神兜兜",1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=250 then
          local 名称="元宵"
          玩家数据[id].道具:给予道具(id,名称,1)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=260 then
          local 名称="金银锦盒"
          玩家数据[id].道具:给予道具(id,名称,5)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=265 then
          local 名称="神灵宝珠"
          玩家数据[id].道具:给予道具(id,名称,5)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})

          elseif 奖励参数<=270 then
          local 名称="仙灵宝珠"
          玩家数据[id].道具:给予道具(id,名称,5)
          常规提示(id,"#Y/你获得了"..名称)
          广播消息({内容=format("#S(门派闯关)#R/%s#Y在门派闯关活动表现优异，获得了门派护法奖励的#G/%s#Y".."#"..取随机数(1,120),玩家数据[id].角色.数据.名称,名称),频道="hd"})
            end

  elseif self.战斗类型==100020 then
    local 等级=取队伍平均等级(玩家数据[id].队伍,id)
    local 经验=qz(等级*500*2)
    local 银子=qz(等级*500*2)
    添加活动次数(id,"妖王")
    if 妖魔积分[id]==nil then
    妖魔积分[id]={当前=0,总计=0,使用=0}
    end
    妖魔积分[id].当前=妖魔积分[id].当前+10
    妖魔积分[id].总计=妖魔积分[id].总计+10
    常规提示(id,"#Y/你获得了10点妖魔积分\n(#G可用于兑换和幸运转盘抽奖#)")
    玩家数据[id].角色:添加经验(经验,"妖王战斗")
    玩家数据[id].角色:添加银子(银子,"妖王战斗",1)
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"妖王战斗",self.地图等级)
      end
      活跃数据[id].活跃度=活跃数据[id].活跃度+5
      玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+5
      常规提示(id,"#Y/你获得了5点活跃度\n(#G用于领取奖励和签到#)")
    local 奖励参数=取随机数(1,200)
    if 奖励参数<=1 then
      local 名称="100-120级精铁"
      玩家数据[id].道具:给予书铁(id,{10,12},"精铁")
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(妖王)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"100-120级精铁"),频道="xt"})
    elseif 奖励参数<=2 then
    local 名称="100-120级指南书"
    玩家数据[id].道具:给予书铁(id,{10,12},"指南书")
    常规提示(id,"#Y/你获得了"..名称)
    广播消息({内容=format("#S(妖王)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"100-120级指南书"),频道="xt"})
    elseif 奖励参数<=5 then
      local 名称="高级魔兽要诀"
      玩家数据[id].道具:给予道具(id,名称)
      常规提示(id,"#Y/你获得了"..名称)
       广播消息({内容=format("#S(妖王)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"高级魔兽要诀"),频道="xt"})
    elseif 奖励参数<=20 then
      local 名称=取宝石()
      玩家数据[id].道具:给予道具(id,名称,取随机数(1,3))
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(妖王)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"1-3级宝石"),频道="xt"})
    elseif 奖励参数<=60 then
    local 名称="元宵"
    玩家数据[id].道具:给予道具(id,名称,1)
    常规提示(id,"#Y/你获得了"..名称)
    广播消息({内容=format("#S(妖王)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"元宵"),频道="xt"})
    elseif 奖励参数<=100 then
      local 名称="金银锦盒"
      玩家数据[id].道具:给予道具(id,名称,5)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(妖王)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"金银锦盒"),频道="xt"})
    end
  elseif self.战斗类型==100021 then
    local 等级=玩家数据[id].角色.数据.等级
    local 经验=qz(等级*800*2)
    local 银子=qz(等级*200*2)
    添加活动次数(id,"初出江湖")
    玩家数据[id].角色:添加经验(经验,"初出江湖")
    玩家数据[id].角色:添加银子(银子,"初出江湖",1)
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"初出江湖",self.地图等级)
      end
    if 玩家数据[id].角色.数据.江湖次数>=10 then
      玩家数据[id].角色.数据.江湖次数=0
      if 妖魔积分[id]==nil then
      妖魔积分[id]={当前=0,总计=0,使用=0}
      end
      妖魔积分[id].当前=妖魔积分[id].当前+20
      妖魔积分[id].总计=妖魔积分[id].总计+20
      常规提示(id,"#Y/你获得了20点妖魔积分\n(#G可用于兑换和幸运转盘抽奖#)")
      活跃数据[id].活跃度=活跃数据[id].活跃度+20
      玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+20
      常规提示(id,"#Y/你获得了2点活跃度\n(#G用于领取奖励和签到#)")
      if 取随机数()<=25 then
      玩家数据[id].道具:给予书铁(id,{6,7},"指南书")
      常规提示(id,"#Y/你获得了#G随机书铁奖励")
      广播消息({内容=format("#S(初出江湖)#R/%s#Y完成初出江湖，#Y随机书铁奖励",玩家数据[id].角色.数据.名称),频道="xt"})
      elseif 取随机数()<=25 then
      玩家数据[id].道具:给予书铁(id,{6,7},"精铁")
      常规提示(id,"#Y/你获得了#G随机书铁奖励")
      广播消息({内容=format("#S(初出江湖)#R/%s#Y完成初出江湖，#Y随机书铁奖励",玩家数据[id].角色.数据.名称),频道="xt"})
      elseif 取随机数()<=40 then
        local 名称="金银锦盒"
        玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(初出江湖)#R/%s#Y完成初出江湖，#Y金银锦盒奖励",玩家数据[id].角色.数据.名称),频道="xt"})
      end
    end
    玩家数据[id].角色:取消任务(self.任务id)
  elseif self.战斗类型==110000 then
        添加活动次数(id,"木桩伤害")
  elseif self.战斗类型==100242 then
    添加活动次数(id,"降妖伏魔")
    local 等级=玩家数据[id].角色.数据.等级
    local 经验=qz(等级*等级*20*任务数据[self.任务id].分类*0.3)
    local 银子=qz(等级*等级*20*任务数据[self.任务id].分类*0.3)
    玩家数据[id].角色:添加经验(经验,"降妖伏魔")
    玩家数据[id].角色:添加银子(银子,"降妖伏魔",1)
    for n=1,#玩家数据[id].召唤兽.数据 do
    玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"降妖伏魔",self.地图等级)
    end
    玩家数据[id].角色:取消任务(self.任务id)
    地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
    玩家数据[id].角色:取消任务(self.任务id)
    if 降妖伏魔[id]==nil then
    降妖伏魔[id]=1
    end
    降妖伏魔[id]=降妖伏魔[id]+1
    if 取随机数(1,100)<=10 then
    local 名称="镇妖拘魂铃"
    玩家数据[id].道具:给予道具(id,名称,1)
    常规提示(id,"#Y/你运气爆棚,恭喜获得1个"..名称)
    广播消息({内容=format("#S(降妖伏魔)#R/%s#Y完成降妖伏魔，#Y镇妖拘魂铃奖励",玩家数据[id].角色.数据.名称),频道="xt"})
    end

    if 取随机数(1,100)<=2 then
    local 名称="神灵宝珠"
    玩家数据[id].道具:给予道具(id,名称,1)
    常规提示(id,"#Y/你运气爆棚,恭喜获得1个"..名称)
    广播消息({内容=format("#S(降妖伏魔)#R/%s#Y完成降妖伏魔，#Y镇妖拘魂铃奖励",玩家数据[id].角色.数据.名称),频道="xt"})

    elseif 取随机数(1,100)<=5 then
    local 名称="仙灵宝珠"
    玩家数据[id].道具:给予道具(id,名称,1)
    常规提示(id,"#Y/你运气爆棚,恭喜获得1个"..名称)
    广播消息({内容=format("#S(降妖伏魔)#R/%s#Y完成降妖伏魔，#Y镇妖拘魂铃奖励",玩家数据[id].角色.数据.名称),频道="xt"})


    end

  if 任务数据[self.任务id].分类==5 then
  降妖伏魔[id]=1
  local 名称="镇妖拘魂铃"
  玩家数据[id].道具:给予道具(id,名称,取随机数(5,10))
  常规提示(id,"#Y/你运气爆棚,恭喜获得5-10个"..名称)
    广播消息({内容=format("#S(降妖伏魔)#R/%s#Y完成降妖伏魔，#Y镇妖拘魂铃奖励",玩家数据[id].角色.数据.名称),频道="xt"})
  end

  elseif self.战斗类型==100022 then
    local 等级=玩家数据[id].角色.数据.等级
    local 经验=qz(等级*等级*15*任务数据[self.任务id].分类*0.3)
    添加活动次数(id,"皇宫飞贼")
    玩家数据[id].角色:添加经验(经验,"皇宫飞贼")
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"皇宫飞贼",self.地图等级)
      end
    玩家数据[id].角色:取消任务(self.任务id)
    if 皇宫飞贼[id]==nil then
    皇宫飞贼[id]=1
    end
    皇宫飞贼[id]=皇宫飞贼[id]+1
    if 取随机数()<=30 then
      local 名称="金银锦盒"
      玩家数据[id].道具:给予道具(id,名称,2)
      常规提示(id,"#Y/你获得了"..名称)
    end
      if 皇宫飞贼.贼王[id]==nil then
        皇宫飞贼.贼王[id]=0
      end
      皇宫飞贼.贼王[id]=皇宫飞贼.贼王[id]+1
  elseif self.战斗类型==100023 then
     local 等级=玩家数据[id].角色.数据.等级
     local 经验=qz(等级*1000*2)
     local 银子=qz(等级*1000*2)
     添加活动次数(id,"皇宫飞贼贼王")
      if 妖魔积分[id]==nil then
      妖魔积分[id]={当前=0,总计=0,使用=0}
      end
      妖魔积分[id].当前=妖魔积分[id].当前+30
      妖魔积分[id].总计=妖魔积分[id].总计+30
      常规提示(id,"#Y/你获得了30点妖魔积分(可用于兑换和幸运转盘抽奖)")
     玩家数据[id].角色:添加经验(经验,"皇宫飞贼贼王")
     玩家数据[id].角色:添加银子(银子,"皇宫飞贼贼王",1)
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"皇宫飞贼",self.地图等级)
      end
      玩家数据[id].角色:取消任务(self.任务id)
      皇宫飞贼.贼王[id]=nil
      local 奖励参数=取随机数(1,100)
      if 奖励参数<=30 then
        local 名称="炼兽真经"
        玩家数据[id].道具:给予道具(id,名称,1)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(皇宫飞贼)#R/%s#Y成功缉拿住幕后贼王，因此获得了御林军左统领奖励的的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,名称),频道="xt"})
      elseif 奖励参数<=35 then
        local 名称="元宵"
        玩家数据[id].道具:给予道具(id,名称,1)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(皇宫飞贼)#R/%s#Y成功缉拿住幕后贼王，因此获得了御林军左统领奖励的的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,名称),频道="xt"})
      elseif 奖励参数<=55 then
        local 名称=取宝石()
        玩家数据[id].道具:给予道具(id,名称,取随机数(1,3))
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(皇宫飞贼)#R/%s#Y成功缉拿住幕后贼王，因此获得了御林军左统领奖励的的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,名称),频道="xt"})
      elseif 奖励参数<=70 then
        local 名称="坐骑内丹"
        玩家数据[id].道具:给予道具(id,名称,1)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(皇宫飞贼)#R/%s#Y成功缉拿住幕后贼王，因此获得了御林军左统领奖励的的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,名称),频道="xt"})
      elseif 奖励参数<=85 then
      local 名称="仙玉"
      添加仙玉(取随机数(10,15),玩家数据[id].账号,id,"皇宫飞贼")
        常规提示(id,"#Y/你获得了"..名称)
       广播消息({内容=format("#S(皇宫飞贼)#R/%s#Y成功缉拿住幕后贼王，因此获得了御林军左统领奖励的的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,名称),频道="xt"})
      elseif 奖励参数<=90 then
        local 名称="附魔宝珠"
        玩家数据[id].道具:给予道具(id,名称,1)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(皇宫飞贼)#R/%s#Y成功缉拿住幕后贼王，因此获得了御林军左统领奖励的的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,名称),频道="xt"})
        else
       local 名称="未激活的符石"
      玩家数据[id].道具:给予道具(id,名称,1)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(皇宫飞贼)#R/%s#Y成功缉拿住幕后贼王，因此获得了御林军左统领奖励的的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,名称),频道="xt"})
      end
    elseif self.战斗类型==100025 then
      local 经验加成=1
      local 银子加成=1
      if 任务数据[self.任务id].难度=="高级" then
        经验加成=2
        银子加成=1.25
      elseif 任务数据[self.任务id].难度=="珍贵" then
        经验加成=4
        银子加成=1.5
        end
     local 等级=玩家数据[id].角色.数据.等级
     local 经验=qz(等级*50*2*经验加成)
     local 银子=qz(等级*50*2*银子加成)
     玩家数据[id].角色:添加经验(经验,"镖王活动")
     玩家数据[id].角色:添加银子(银子,"镖王活动",1)
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"镖王活动",self.地图等级)
      end
     -- 0914
    elseif self.战斗类型==100026 then
      local 银子=50000
      添加活动次数(id,"三界悬赏令")
      if 妖魔积分[id]==nil then
      妖魔积分[id]={当前=0,总计=0,使用=0}
      end
      妖魔积分[id].当前=妖魔积分[id].当前+20
      妖魔积分[id].总计=妖魔积分[id].总计+20
      常规提示(id,"#Y/你获得了20点妖魔积分\n(#G可用于兑换和幸运转盘抽奖#)")
      玩家数据[id].角色:添加银子(银子,"三界悬赏令",1)
      local 奖励参数=取随机数(1,100)
      if 奖励参数<=5 then
        local 名称="高级召唤兽内丹"
        玩家数据[id].道具:给予道具(id,名称)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(三界悬赏令)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"高级召唤兽内丹"),频道="xt"})
      elseif 奖励参数<=10 then
        local 名称="高级魔兽要诀"
        玩家数据[id].道具:给予道具(id,名称)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(三界悬赏令)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
      elseif 奖励参数<=60 then
        local 名称="召唤兽内丹"
        玩家数据[id].道具:给予道具(id,名称)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(三界悬赏令)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=20 then
        local 名称="修炼果"
        玩家数据[id].道具:给予道具(id,名称,1)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(三界悬赏令)#R/%s#Y跋山涉水终于成功擒拿了#R%s#Y，因此获得了铁无双其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,"坐骑内丹"),频道="xt"})
     end
  elseif self.战斗类型==100027 then  -------完成知了王
    local 等级=取队伍平均等级(玩家数据[id].队伍,id)
    local 经验=qz(等级*500*20)
    local 银子=qz(等级*500*20)
    玩家数据[id].角色:添加银子(银子,"知了王",1)
    玩家数据[id].角色:添加经验(经验,"知了王")
    添加活动次数(id,"知了王")
      for n=1,#玩家数据[id].召唤兽.数据 do
      玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"知了王",self.地图等级)
      end

    local 奖励参数=取随机数(1,300)
          if 奖励参数<=10 then
      local 名称=取宝石()
      玩家数据[id].道具:给予道具(id,名称,取随机数(1,3))
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=20 then
      local 名称="怪物卡片"
      玩家数据[id].道具:给予道具(id,名称,8)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=30 then
      local 名称="上古锻造图策"
      玩家数据[id].道具:给予道具(id,名称,{65,85,105})
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=40 then
      local 名称="炼妖石"
      玩家数据[id].道具:给予道具(id,名称,{65,85,105})
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=45 then
      local 名称="高级魔兽要诀"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=70 then
      local 名称="易经丹"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=80 then
      local 名称="高级召唤兽内丹"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=85 then
      local 名称="灵饰指南书"
      玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8,10})
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
    elseif 奖励参数<=90 then
      local 名称="元灵晶石"
      玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8,10})
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(知了王)#R/%s#Y对着知了王一顿乱打脚踢，打得知了王双手奉上了#G/%s#Y以求活命。".."#"..取随机数(1,200),玩家数据[id].角色.数据.名称,名称),频道="hd"})
      end

    elseif self.战斗类型==100024 then
      local 等级=任务数据[self.任务id].等级
      local 平均等级 = 取队伍平均等级(玩家数据[id].队伍,id)
      local 经验=平均等级*平均等级*69
      添加活动次数(id,"世界BOSS")
      玩家数据[id].角色:添加经验(经验,任务数据[self.任务id].名称)
      玩家数据[id].角色:添加银子(2000000,"世界BOSS",1)
      添加仙玉(10,玩家数据[id].账号,id,"世界BOSS")
        活跃数据[id].活跃度=活跃数据[id].活跃度+50
        玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+50
       for n=1,#玩家数据[id].召唤兽.数据 do
       玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"世界BOSS",self.地图等级)
       end
      local 奖励参数=取随机数(1,320)
        if 等级==60 or 等级==100 or 等级==150 then
          if 奖励参数<=10 then
          local 名称="制造指南书"
          玩家数据[id].道具:给予书铁(id,{10,13},"指南书")
          常规提示(id,"#Y/你获得了"..名称)
            广播消息({内容=format("#S(世界BOSS)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
          elseif 奖励参数<=20 then
          local 名称="百炼精铁"
          玩家数据[id].道具:给予书铁(id,{10,13},"精铁")
          常规提示(id,"#Y/你获得了"..名称)
            广播消息({内容=format("#S(世界BOSS)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
          elseif 奖励参数<=30 then
            local 名称="高级召唤兽内丹"
            玩家数据[id].道具:给予道具(id,名称,1)
            常规提示(id,"#Y/你获得了"..名称)
            广播消息({内容=format("#S(世界BOSS)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
          elseif 奖励参数<=40 then
            local 名称="高级魔兽要诀"
          local 技能=取特殊要诀()
          玩家数据[id].道具:给予道具(id,名称,nil,技能)
            常规提示(id,"#Y/你获得了"..名称)
            广播消息({内容=format("#S(世界BOSS)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
            elseif 奖励参数<=50 then
            local 名称="修炼果"
            玩家数据[id].道具:给予道具(id,名称,1)
            常规提示(id,"#Y/你获得了"..名称)
            广播消息({内容=format("#S(世界BOSS)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
          elseif 奖励参数<=60 then
            local 名称="高级召唤兽内丹"
            玩家数据[id].道具:给予道具(id,名称)
            常规提示(id,"#Y/你获得了"..名称)
            广播消息({内容=format("#S(世界BOSS)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
          else
            local 名称="召唤兽内丹"
            玩家数据[id].道具:给予道具(id,名称,1)
            常规提示(id,"#Y/你获得了"..名称)
            广播消息({内容=format("#S(世界BOSS)#R/%s#Y经过一番激烈的战斗，最终战胜了#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
      end
    end
     elseif self.战斗类型==110038 then
    玩家数据[id].角色.数据.跑镖遇怪时间=os.time()+取随机数(80,130)
    -- local 等级=取等级(id)----------跑镖遇怪经验银子
    -- local 经验=等级*500+3000
    -- local 银子=等级*等级*5
    -- local 奖励参数=取随机数(1,200)


    -- 玩家数据[id].角色:添加银子(银子,"天庭叛逆")
    -- 常规提示(id,"#Y/你获得了"..银子.."银子和"..经验.."经验")
    -- 添加仙玉(取随机数(5,10),玩家数据[id].账号,id,"天庭叛逆")
    -- 玩家数据[id].角色.数据.比武积分.当前积分=玩家数据[id].角色.数据.比武积分.当前积分+200
    -- 玩家数据[id].角色.数据.比武积分.总积分=玩家数据[id].角色.数据.比武积分.总积分+200

    -- 添加活动次数(id,"天庭叛逆")

  elseif self.战斗类型==100032 then--天庭叛逆
    local 等级=取等级(id)
    local 经验=等级*700*2
    local 银子=等级*400*2
    local 奖励参数=取随机数(1,180)
    添加活动次数(id,"天庭叛逆")
    玩家数据[id].角色:添加经验(经验,"天庭叛逆")
    玩家数据[id].角色:添加银子(银子,任务数据[self.任务id].名称,1)
       for n=1,#玩家数据[id].召唤兽.数据 do
       玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"天庭叛逆",self.地图等级)
       end
      活跃数据[id].活跃度=活跃数据[id].活跃度+2
      玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+2
    if 奖励参数<=5 then
      local 名称="特赦令牌"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(天庭叛逆)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=6 then
      local 名称="高级魔兽要诀"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(天庭叛逆)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=20 then
      local 名称="未激活的符石"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(天庭叛逆)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=22 then
      local 名称="修炼果"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(天庭叛逆)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=30 then
      local 名称="清灵净瓶"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(天庭叛逆)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=40 then
      local 名称="魔兽要诀"
      玩家数据[id].道具:给予道具(id,名称)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(天庭叛逆)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    end

  elseif self.战斗类型==100033 then--捣乱的水果
    local 等级=取队伍平均等级(玩家数据[id].队伍,id)
    local 经验=等级*700*2
    local 银子=等级*400*2
    local 奖励参数=取随机数(1,100)
    添加活动次数(id,"扰乱水果")
    玩家数据[id].角色:添加银子(银子,"捣乱的水果",1)
    玩家数据[id].角色:添加经验(经验,"捣乱的水果")
    活跃数据[id].活跃度=活跃数据[id].活跃度+2
    玩家数据[id].角色.数据.累积活跃.当前积分=玩家数据[id].角色.数据.累积活跃.当前积分+2
    常规提示(id,"#Y/你获得了2点活跃数据")
       for n=1,#玩家数据[id].召唤兽.数据 do
       玩家数据[id].召唤兽:获得经验(玩家数据[id].召唤兽.数据[n].认证码,qz(经验*0.5),id,"捣乱的水果",self.地图等级)
       end
    if 奖励参数<=20 then
        local 名称="炼妖石"
        玩家数据[id].道具:给予道具(id,名称,{45,65})
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(捣乱的水果)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=30 then
        local 名称="上古锻造图策"
        玩家数据[id].道具:给予道具(id,名称,{45,65})
        常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(捣乱的水果)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
  elseif 奖励参数<=40 then
      local 名称="百炼精铁"
      玩家数据[id].道具:给予书铁(id,{6,8},"精铁")
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(捣乱的水果)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
  elseif 奖励参数<=50 then
      local 名称="制造指南书"
      玩家数据[id].道具:给予书铁(id,{6,8},"指南书")
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(捣乱的水果)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
  elseif 奖励参数<=60 then
      local 名称="金银锦盒"
      玩家数据[id].道具:给予道具(id,名称,1)
      常规提示(id,"#Y/你获得了"..名称)
      广播消息({内容=format("#S(捣乱的水果)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
  elseif 奖励参数<=70 then
        local 名称="海马"
        玩家数据[id].道具:给予道具(id,名称,1)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(捣乱的水果)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    elseif 奖励参数<=80 then
        local 名称="魔兽要诀"
        玩家数据[id].道具:给予道具(id,名称)
        常规提示(id,"#Y/你获得了"..名称)
        广播消息({内容=format("#S(捣乱的水果)#R/%s#Y经过一番激烈的战斗，最终战胜了叛逃的#R%s#Y，因此获得了其奖励的#G/%s#Y".."#"..取随机数(1,110),玩家数据[id].角色.数据.名称,任务数据[self.任务id].名称,名称),频道="xt"})
    end

  elseif self.战斗类型==100120 then
    local 主任务id = 任务数据[self.任务id].主任务
    if 任务数据[主任务id] ~= nil then
      if 任务数据[主任务id].阶段<=3 then
        任务数据[主任务id].成功操作 = 任务数据[主任务id].成功操作 + 1
      elseif 任务数据[主任务id].阶段 == 4 then
        任务数据[主任务id].次数 = 任务数据[主任务id].次数 + 1
      end
      任务数据[主任务id].刷出强盗 = nil
    end
    地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
    玩家数据[id].角色:取消任务(self.任务id)
  end
end

function 战斗处理类:失败处理(失败id,是否逃跑,胜利id)
  if 失败id==0 then return  end
  local id组={}
 if self.战斗类型==200006 then
    for n=1,#self.参战玩家 do
      if self.参战玩家[n].队伍==失败id and 玩家数据[self.参战玩家[n].id]~=nil then
       -- id组[#id组+1]=self.参战玩家[n].id
          if 是否逃跑==nil then
             if  玩家数据[self.参战玩家[n].id].角色.数据.帮战次数==nil then
                 玩家数据[self.参战玩家[n].id].角色.数据.帮战次数=0
             end
             if  玩家数据[self.参战玩家[n].id].角色.数据.帮战积分==nil then
                 玩家数据[self.参战玩家[n].id].角色.数据.帮战积分=0
             end
          玩家数据[self.参战玩家[n].id].角色.数据.帮战次数  = 玩家数据[self.参战玩家[n].id].角色.数据.帮战次数 +1
          玩家数据[self.参战玩家[n].id].角色.数据.帮战积分  = 玩家数据[self.参战玩家[n].id].角色.数据.帮战积分 +1
          地图处理类:跳转地图(self.参战玩家[n].id,1001,385,21,true)
          常规提示(玩家数据[self.参战玩家[n].id].角色.数据.数字id,"#Y被虐了..获得#R1#Y帮战积分#52")
          end
      end
    end
    return
end

  self.战斗失败=true

  for n=1,#self.参战玩家 do
      if self.参战玩家[n].队伍==失败id and 玩家数据[self.参战玩家[n].id]~=nil then
          if 是否逃跑==nil  and self.战斗类型~=200003 and self.战斗类型~=200004 and self.战斗类型~=200005 and self.战斗类型~=200006 and self.战斗类型~=100114 and self.战斗类型~=100115 and self.战斗类型~=300001 then
            if self.战斗类型 == 200008 then
              -- self:扣经验(self.参战玩家[n].id,0.25)
              -- self:扣银子(self.参战玩家[n].id,0.22)
              国庆数据[失败id].累积=国庆数据[失败id].累积+1
               玩家数据[self.参战玩家[n].id].角色:死亡处理()
               玩家数据[self.参战玩家[n].id].角色:刷新信息("1")
              --常规提示(失败id,"#Y/灭队了#17灭队了#28刻晴好开心#17")
            else
              -- self:扣经验(self.参战玩家[n].id,0.085)
              -- self:扣银子(self.参战玩家[n].id,0.075)

               玩家数据[self.参战玩家[n].id].角色:死亡处理()
               玩家数据[self.参战玩家[n].id].角色:刷新信息("1")
               -- 常规提示(失败id,"#Y/灭队了#17灭队了#28刻晴好开心#17")
            end
          end
          id组[#id组+1]=self.参战玩家[n].id
      end
  end
  for i=1,#id组 do
    if 玩家数据[id组[i]]~=nil then
      if self.战斗脚本 and self.战斗脚本.战斗失败 then
        --self.战斗脚本:OnTurnReady(1)
        __gge.safecall(self.战斗脚本.战斗失败,self,失败id,是否逃跑,胜利id)
      end
      if self.战斗类型==100006 then--科举
        游戏活动类:科举回答题目(玩家数据[self.进入战斗玩家id].连接id,self.进入战斗玩家id,答案,5)
        if 是否逃跑==nil then
          self:死亡对话(id组[i])
        end
      elseif self.战斗类型==100017 or self.战斗类型==100016  then
        地图处理类:删除单位(任务数据[self.任务id].地图编号,任务数据[self.任务id].单位编号)
        常规提示(self.进入战斗玩家id,"#Y/你的师门任务失败了")
        玩家数据[self.进入战斗玩家id].角色:取消任务(self.任务id)
        任务数据[self.任务id]=nil
        玩家数据[self.进入战斗玩家id].角色.数据.师门次数=0
        if 是否逃跑==nil then
          --self:死亡对话(id组[i])
        end


      elseif self.战斗类型==100114 or self.战斗类型==100115 then
        常规提示(id组[i],"#Y/想要击败我必须找到观音的法宝，哈哈")
        local 副本id=任务数据[玩家数据[self.进入战斗玩家id].角色:取任务(150)].副本id
        if self.战斗类型==100114 then
          副本数据.水陆大会.进行[副本id].翼虎=true
          任务数据[self.任务id].战斗=nil
        else
          副本数据.水陆大会.进行[副本id].蝰蛇=true
          任务数据[self.任务id].战斗=nil
        end
        if 副本数据.水陆大会.进行[副本id].翼虎 and 副本数据.水陆大会.进行[副本id].蝰蛇 then
          副本数据.水陆大会.进行[副本id].进程=5
          任务处理类:设置水陆大会副本(副本id)
          玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
        end
        elseif self.战斗类型==100235 then
        常规提示(self.进入战斗玩家id,"#Y/黄狮王好强啊!")
        任务数据[玩家数据[self.进入战斗玩家id].角色:取任务(501)].进程=18
        玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
        elseif self.战斗类型==100256 then
       常规提示(self.进入战斗玩家id,"#Y/看来想要打败心魔,必须找到方法才行")
       if 玩家数据[self.进入战斗玩家id].角色:取任务(996) ~= 0 then
       任务数据[玩家数据[self.进入战斗玩家id].角色:取任务(996)].进程=4
       玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
     end
      elseif self.战斗类型==100018  then--门派乾坤袋
        local xy=地图处理类.地图坐标[任务数据[self.任务id].地图编号]:取随机点()
        任务数据[self.任务id].x,任务数据[self.任务id].y=xy.x,xy.y
        玩家数据[self.进入战斗玩家id].角色:刷新任务跟踪()
        地图处理类:添加单位(self.任务id)
        if 是否逃跑==nil then
          --self:死亡对话(id组[i])
        end
      elseif  self.战斗类型==100001 or self.战斗类型==100007 then--野外野怪死亡
        if 玩家数据[self.进入战斗玩家id].角色.数据.等级~=nil and 玩家数据[self.进入战斗玩家id].角色.数据.等级>10 then
          if 是否逃跑==nil then
            --self:死亡对话(id组[i])
          end
        end
      elseif self.战斗类型~=100007 and self.战斗类型~=100001 and self.战斗类型~=200003 and self.战斗类型~=200004 and self.战斗类型~=200005 and self.战斗类型~=200006 and self.战斗类型>=100002 or self.战斗类型<=100010 or self.战斗类型<=300001 then--前面活动
          if 是否逃跑==nil then
            --self:死亡对话(id组[i])
          end
          if self.战斗类型 == 100027 then
            广播消息({内容=format("#R听说#G%s#R在挑战知了王时,被打的鼻青脸肿,连他妈都不认识了#24",玩家数据[id组[i]].角色.数据.名称),频道="cw"})
          elseif self.战斗类型 == 100037 then
            广播消息({内容=format("#R听说#G%s#R在挑战地煞星时,被打的抱头鼠窜,一时成为了三界笑谈#24",玩家数据[id组[i]].角色.数据.名称),频道="cw"})
          elseif self.战斗类型 == 199406 then
            广播消息({内容=format("#R听说#G%s#R在挑战征战神州时,被打的抱头鼠窜,一时成为了三界笑谈#24",玩家数据[id组[i]].角色.数据.名称),频道="cw"})




      elseif self.战斗类型 == 200007 then
            local 胜利队长
            for n=1,#self.参战玩家 do
              if self.参战玩家[n].队伍==胜利id and 玩家数据[self.参战玩家[n].id]~=nil and (玩家数据[self.参战玩家[n].id].队长 or 玩家数据[self.参战玩家[n].id].队伍 == 0) then
                胜利队长 = self.参战玩家[n].id
              end
            end
            if 胜利队长 ~= nil and 玩家数据[胜利队长] ~= nil then
              广播消息({内容=format("#Y听说#G%s#Y在与#R%s#Ypk时,被打的头破血流,从此夹着尾巴做人！#24",玩家数据[id组[i]].角色.数据.名称,玩家数据[胜利队长].角色.数据.名称),频道="cw"})
            end
          elseif self.战斗类型 == 200008 then
            local 胜利队长
            for n=1,#self.参战玩家 do
              if self.参战玩家[n].队伍==胜利id and 玩家数据[self.参战玩家[n].id]~=nil and (玩家数据[self.参战玩家[n].id].队长 or 玩家数据[self.参战玩家[n].id].队伍 == 0) then
                胜利队长 = self.参战玩家[n].id
              end
            end
            if 玩家数据[id组[i]].角色.数据.强P开关 ~= nil then
              玩家数据[id组[i]].角色.数据.强P开关 = nil
              发送数据(玩家数据[id组[i]].连接id,94)
              地图处理类:更改强PK(id组[i])
              if 玩家数据[id组[i]].角色.数据.PK开关 ~= nil then
                发送数据(玩家数据[id组[i]].连接id,93,{开关=true})
                地图处理类:更改PK(id组[i],true)
              end
            end
            if 胜利队长 ~= nil and 玩家数据[胜利队长] ~= nil and (玩家数据[id组[i]].队伍 == 0 or 玩家数据[id组[i]].队长)  then
              广播消息({内容=format("#Y听说#G%s#Y被#R%s#Y强行XXXXX,从此结下了血海深仇！#24",玩家数据[id组[i]].角色.数据.名称,玩家数据[胜利队长].角色.数据.名称),频道="cw"})
            end

          elseif self.战斗类型==110038 then
            玩家数据[self.进入战斗玩家id].角色:取消任务(玩家数据[self.进入战斗玩家id].角色:取任务(300))
            玩家数据[self.进入战斗玩家id].角色.押镖间隔=os.time()+180
            添加最后对话(self.进入战斗玩家id,format("任务失败,押镖任务失败,您三分钟之内无法再次领取押镖任务"))
            玩家数据[self.进入战斗玩家id].角色.数据.跑镖遇怪时间=0
        end
      end
    end
  end
  if self.任务id==nil or 任务数据[self.任务id]==nil then return  end
  任务数据[self.任务id].战斗=nil
end

function 战斗处理类:死亡对话(id)
  玩家数据[id].战斗=0
  if 玩家数据[id].队长 then
  else
    队伍处理类:退出队伍(id)
  end
  local wb={}
  wb[1] = "生死有命,请珍惜生命？"
  local xx = {}
  self.临时数据={"白无常","白无常",wb[取随机数(1,#wb)],xx}
  self.发送数据={}
  self.发送数据.模型=self.临时数据[1]
  self.发送数据.名称=self.临时数据[2]
  self.发送数据.对话=self.临时数据[3]
  self.发送数据.选项=self.临时数据[4]
  发送数据(玩家数据[id].连接id,1501,self.发送数据)
  地图处理类:跳转地图(id,1125,24,27)
end

function 战斗处理类:扣经验(失败id,倍率)
  -- if 倍率~=nil then
  --   self.扣除经验 = math.floor(玩家数据[失败id].角色.数据.当前经验 * 0.05)
  -- else
  --   self.扣除经验 = math.floor(玩家数据[失败id].角色.数据.当前经验 * 0.05)
  -- end
  -- if 玩家数据[失败id].角色.数据.当前经验>=self.扣除经验 then
  --   玩家数据[失败id].角色.数据.当前经验=玩家数据[失败id].角色.数据.当前经验-self.扣除经验
  --   发送数据(玩家数据[失败id].连接id,38,{内容="#Y/你因为死亡损失了" .. self.扣除经验 .. "点经验",频道="xt"})
  --   常规提示(失败id,"#Y/你因为死亡损失了" .. self.扣除经验 .. "点经验")
  -- end
end

function 战斗处理类:扣银子(失败id,倍率)
  -- if 倍率~=nil then
  --   self.扣除银子 = math.floor(玩家数据[失败id].角色.数据.银子 * 倍率)
  -- else
  --   self.扣除银子 = math.floor(玩家数据[失败id].角色.数据.银子 * 0.08)
  -- end
  -- if 玩家数据[失败id].角色.数据.银子>=self.扣除银子 then
  --   玩家数据[失败id].角色.数据.银子=玩家数据[失败id].角色.数据.银子-self.扣除银子
  --   发送数据(玩家数据[失败id].连接id,38,{内容="#Y/你因为死亡损失了" .. self.扣除银子 .. "两银子",频道="xt"})
  --   常规提示(失败id,"#Y/你因为死亡损失了" .. self.扣除银子 .. "两银子")
  -- end
end

function 战斗处理类:还原指定单位属性(id)
 for n=1,#self.参战单位 do
    if self.参战单位[n].气血<0 then self.参战单位[n].气血=0 end
    if self.参战单位[n].魔法<0 then self.参战单位[n].魔法=0 end
      if self.参战单位[n].队伍~=0 and self.参战单位[n].玩家id==id then
          if self.参战单位[n].类型=="角色" then
              if self.参战单位[n].气血<=0 then
                  玩家数据[self.参战单位[n].玩家id].角色:死亡处理()
                  玩家数据[self.参战单位[n].玩家id].角色:刷新信息("1")
                else
                 玩家数据[self.参战单位[n].玩家id].角色:刷新信息()
                 玩家数据[self.参战单位[n].玩家id].角色.数据.气血= self.参战单位[n].气血
                 玩家数据[self.参战单位[n].玩家id].角色.数据.魔法= self.参战单位[n].魔法
                 玩家数据[self.参战单位[n].玩家id].角色.数据.愤怒= self.参战单位[n].愤怒
                 end
              发送数据(玩家数据[self.参战单位[n].玩家id].连接id,33,玩家数据[self.参战单位[n].玩家id].角色:取总数据())
            elseif self.参战单位[n].类型=="bb" then
               if self.参战单位[n].气血<=0 then
                  玩家数据[self.参战单位[n].玩家id].召唤兽:死亡处理(self.参战单位[n].认证码)
                  玩家数据[self.参战单位[n].玩家id].召唤兽:刷新信息1(self.参战单位[n].认证码,"1")
                else
                  玩家数据[self.参战单位[n].玩家id].召唤兽:刷新信息1(self.参战单位[n].认证码)
                  玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血= self.参战单位[n].气血
                  玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法= self.参战单位[n].魔法
                 end
             end
         end
   end
end

function 战斗处理类:还原单位属性()
 for n=1,#self.参战单位 do
    if self.参战单位[n].气血<0 then self.参战单位[n].气血=0 end
    if self.参战单位[n].魔法<0 then self.参战单位[n].魔法=0 end
      if self.参战单位[n]~=nil and self.参战单位[n].队伍~=0 and self.参战单位[n].逃跑==nil and self.参战单位[n].系统队友==nil and 玩家数据[self.参战单位[n].玩家id]~=nil then
          if self.参战单位[n].类型=="角色" and self.参战单位[n].助战编号 == nil then
            if self.参战单位[n].气血<=0 and self.战斗失败== false then
              玩家数据[self.参战单位[n].玩家id].角色:死亡处理()
              玩家数据[self.参战单位[n].玩家id].角色:刷新信息("1")
            else
              玩家数据[self.参战单位[n].玩家id].角色.数据.气血= self.参战单位[n].气血
              玩家数据[self.参战单位[n].玩家id].角色.数据.魔法= self.参战单位[n].魔法
              玩家数据[self.参战单位[n].玩家id].角色.数据.愤怒= self.参战单位[n].愤怒
              玩家数据[self.参战单位[n].玩家id].角色:刷新信息()
            end

            if 玩家数据[self.参战单位[n].玩家id].角色:取任务(10)~=0 and self.战斗类型 ~= 100050 and self.战斗类型 ~= 100051 and self.战斗类型 ~= 100052 and self.战斗类型 ~= 100053 and self.战斗类型 ~= 100130 and self.战斗类型 ~= 100131 and self.战斗类型 ~= 100132 and self.战斗类型 ~= 100133 then
              local 恢复id=玩家数据[self.参战单位[n].玩家id].角色:取任务(10)
              if 玩家数据[self.参战单位[n].玩家id].角色.数据.气血<玩家数据[self.参战单位[n].玩家id].角色.数据.最大气血 then
                if 任务数据[恢复id].气血>0 then
                  if 任务数据[恢复id].气血>玩家数据[self.参战单位[n].玩家id].角色.数据.最大气血-玩家数据[self.参战单位[n].玩家id].角色.数据.气血 then
                    任务数据[恢复id].气血=任务数据[恢复id].气血-(玩家数据[self.参战单位[n].玩家id].角色.数据.最大气血-玩家数据[self.参战单位[n].玩家id].角色.数据.气血)
                    玩家数据[self.参战单位[n].玩家id].角色.数据.气血=玩家数据[self.参战单位[n].玩家id].角色.数据.最大气血
                    玩家数据[self.参战单位[n].玩家id].角色.数据.气血上限=玩家数据[self.参战单位[n].玩家id].角色.数据.最大气血
                  else
                    玩家数据[self.参战单位[n].玩家id].角色.数据.气血=玩家数据[self.参战单位[n].玩家id].角色.数据.气血+任务数据[恢复id].气血
                    玩家数据[self.参战单位[n].玩家id].角色.数据.气血上限=玩家数据[self.参战单位[n].玩家id].角色.数据.最大气血
                    任务数据[恢复id].气血=0
                  end
                  if 任务数据[恢复id].气血==0  and  任务数据[恢复id].魔法==0 then
                    玩家数据[self.参战单位[n].玩家id].角色:取消任务(恢复id)
                  end
                  玩家数据[self.参战单位[n].玩家id].角色:刷新任务跟踪()
                end
              end
              if 玩家数据[self.参战单位[n].玩家id].角色.数据.魔法<玩家数据[self.参战单位[n].玩家id].角色.数据.最大魔法 then
                if 任务数据[恢复id].魔法>0 then
                  if 任务数据[恢复id].魔法>玩家数据[self.参战单位[n].玩家id].角色.数据.最大魔法-玩家数据[self.参战单位[n].玩家id].角色.数据.魔法 then
                    任务数据[恢复id].魔法=任务数据[恢复id].魔法-(玩家数据[self.参战单位[n].玩家id].角色.数据.最大魔法-玩家数据[self.参战单位[n].玩家id].角色.数据.魔法)
                    玩家数据[self.参战单位[n].玩家id].角色.数据.魔法=玩家数据[self.参战单位[n].玩家id].角色.数据.最大魔法
                  else
                    玩家数据[self.参战单位[n].玩家id].角色.数据.魔法=玩家数据[self.参战单位[n].玩家id].角色.数据.魔法+任务数据[恢复id].魔法
                    任务数据[恢复id].魔法=0
                  end
                  if 任务数据[恢复id].气血==0  and  任务数据[恢复id].魔法==0 then
                    玩家数据[self.参战单位[n].玩家id].角色:取消任务(恢复id)
                  end
                  玩家数据[self.参战单位[n].玩家id].角色:刷新任务跟踪()
                end
              end
            end
            发送数据(玩家数据[self.参战单位[n].玩家id].连接id,33,玩家数据[self.参战单位[n].玩家id].角色:取总数据())
          elseif self.参战单位[n].类型=="角色" and self.参战单位[n].助战编号 ~= nil then
            local 助战编号 = self.参战单位[n].助战编号
            if self.参战单位[n].气血<=0 then
              玩家数据[self.参战单位[n].玩家id].助战:刷新信息(助战编号,1)
            else
              玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].气血= self.参战单位[n].气血
              玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].魔法= self.参战单位[n].魔法
              玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].愤怒= self.参战单位[n].愤怒+150
              玩家数据[self.参战单位[n].玩家id].助战:刷新信息(助战编号)
            end
            if 玩家数据[self.参战单位[n].玩家id].角色:取任务(10)~=0 and self.战斗类型 ~= 100050 and self.战斗类型 ~= 100051 and self.战斗类型 ~= 100052 and self.战斗类型 ~= 100053 and self.战斗类型 ~= 100130 and self.战斗类型 ~= 100131 and self.战斗类型 ~= 100132 and self.战斗类型 ~= 100133 then
              local 恢复id=玩家数据[self.参战单位[n].玩家id].角色:取任务(10)
              if 玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].气血 < 玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大气血 then
                if 任务数据[恢复id].气血>0 then
                  if 任务数据[恢复id].气血>玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大气血-玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].气血 then
                    任务数据[恢复id].气血=任务数据[恢复id].气血-(玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大气血-玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].气血)
                    玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].气血=玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大气血
                  else
                    玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].气血=玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].气血+任务数据[恢复id].气血
                    任务数据[恢复id].气血=0
                  end
                  if 任务数据[恢复id].气血==0  and  任务数据[恢复id].魔法==0 then
                    玩家数据[self.参战单位[n].玩家id].角色:取消任务(恢复id)
                  end
                  玩家数据[self.参战单位[n].玩家id].角色:刷新任务跟踪()
                end
              end
              if 玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].魔法<玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大魔法 then
                if 任务数据[恢复id].魔法>0 then
                  if 任务数据[恢复id].魔法>玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大魔法-玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].魔法 then
                    任务数据[恢复id].魔法=任务数据[恢复id].魔法-(玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大魔法-玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].魔法)
                    玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].魔法=玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].最大魔法
                  else
                    玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].魔法=玩家数据[self.参战单位[n].玩家id].助战.数据[助战编号].魔法+任务数据[恢复id].魔法
                    任务数据[恢复id].魔法=0
                  end
                  if 任务数据[恢复id].气血==0  and  任务数据[恢复id].魔法==0 then
                    玩家数据[self.参战单位[n].玩家id].角色:取消任务(恢复id)
                  end
                  玩家数据[self.参战单位[n].玩家id].角色:刷新任务跟踪()
                end
              end
            end
            发送数据(玩家数据[self.参战单位[n].玩家id].连接id,100,{编号=助战编号,数据= 玩家数据[self.参战单位[n].玩家id].助战:取指定数据(助战编号)})
          else
            if  self.参战单位[n].类型=="bb" and self.参战单位[n].助战宝宝编号==nil and 玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.认证码~=nil then
              if self.参战单位[n].气血<=0 then
                  玩家数据[self.参战单位[n].玩家id].召唤兽:死亡处理(self.参战单位[n].认证码)
                  玩家数据[self.参战单位[n].玩家id].召唤兽:刷新信息1(self.参战单位[n].认证码,"1")
              else
                  玩家数据[self.参战单位[n].玩家id].召唤兽:刷新信息1(self.参战单位[n].认证码)
                  玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血= self.参战单位[n].气血
                  玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法= self.参战单位[n].魔法
              end
              if 玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血 > 玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大气血 then
                玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血 = 玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大气血
              end
              if 玩家数据[self.参战单位[n].玩家id].角色:取任务(10)~=0 and self.战斗类型 ~= 100050 and self.战斗类型 ~= 100051 and self.战斗类型 ~= 100052 and self.战斗类型 ~= 100053 and self.战斗类型 ~= 100130 and self.战斗类型 ~= 100131 and self.战斗类型 ~= 100132 and self.战斗类型 ~= 100133 then
                local 恢复id=玩家数据[self.参战单位[n].玩家id].角色:取任务(10)
                if 玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝~=nil and 玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血<玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大气血 then
                  if 任务数据[恢复id].气血>0 then
                    if 任务数据[恢复id].气血>玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大气血-玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血 then
                        任务数据[恢复id].气血=任务数据[恢复id].气血-(玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大气血-玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血)
                        玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血=玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大气血
                    else
                        玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血=玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.气血+任务数据[恢复id].气血
                        任务数据[恢复id].气血=0
                    end
                    if 任务数据[恢复id].气血==0  and  任务数据[恢复id].魔法==0 then
                      玩家数据[self.参战单位[n].玩家id].角色:取消任务(恢复id)
                    end
                    玩家数据[self.参战单位[n].玩家id].角色:刷新任务跟踪()
                  end
              end
              if 玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法<玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大魔法 then
                 if 任务数据[恢复id].魔法>0 then
                   if 任务数据[恢复id].魔法>玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大魔法-玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法 then
                      任务数据[恢复id].魔法=任务数据[恢复id].魔法-(玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大魔法-玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法)
                      玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法=玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.最大魔法
                    else
                      玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法=玩家数据[self.参战单位[n].玩家id].角色.数据.参战宝宝.魔法+任务数据[恢复id].魔法
                      任务数据[恢复id].魔法=0
                     end
                    if 任务数据[恢复id].气血==0  and  任务数据[恢复id].魔法==0 then
                     玩家数据[self.参战单位[n].玩家id].角色:取消任务(恢复id)
                      end
                   玩家数据[self.参战单位[n].玩家id].角色:刷新任务跟踪()
                   end
                 end
                end
                end
            发送数据(玩家数据[self.参战单位[n].玩家id].连接id,33,玩家数据[self.参战单位[n].玩家id].角色:取总数据())
           end
        end
   end
end

function 战斗处理类:取是否合击(编号,目标)
  if self.参战单位[目标]==nil or self:取玩家战斗()==true then
    return false
  elseif self.参战单位[编号].队伍==0 or self.参战单位[编号].气血<=0 then
    return false
  elseif self.参战单位[目标].队伍==self.参战单位[编号].队伍 then
    return false
  elseif self.参战单位[目标].气血==0 or self.参战单位[目标].法术状态.楚楚可怜~=nil or self.参战单位[目标].法术状态.催眠符~=nil or self.参战单位[目标].法术状态.分身术~=nil then
    return false
  elseif self.参战单位[目标].指令.类型=="防御" then
    return false
  elseif 取随机数()<=10 then
  --检查是否有保护
    for n=1,#self.参战单位 do
      if self:取行动状态(n) and self.参战单位[目标].法术状态.惊魂掌==nil and self.参战单位[n].指令.类型=="保护" and  self.参战单位[n].队伍==self.参战单位[目标].队伍 and  self.参战单位[n].指令.目标==目标 then
        return false
      end
    end
  --检查有无相同攻击方
    local 队友组={}
    local 队友=0
    for n=1,#self.参战单位 do
      if n~=编号 and self:取行动状态(n) and self:取攻击状态(n) and self.参战单位[n].气血>0 and self.参战单位[n].队伍==self.参战单位[编号].队伍 and self.参战单位[n].指令.执行==nil and self.参战单位[n].指令.类型=="攻击" and self.参战单位[n].指令.目标==目标 then
        队友组[#队友组+1]=n
      end
    end
    if #队友组==0 then
      return false
    else
      队友=队友组[取随机数(1,#队友组)]
      local 伤害=self:取基础物理伤害(编号,目标)
      伤害=math.floor((伤害+self:取基础物理伤害(队友,目标)*0.75))
      self.战斗流程[#self.战斗流程+1]={流程=700,攻击方=编号,队友=队友,挨打方={[1]={挨打方=目标,伤害=伤害,特效={}}}}
      self.战斗流程[#self.战斗流程].挨打方[1].死亡= self:减少气血(目标,伤害,编号)
      self.参战单位[编号].指令.下达=true
      self.参战单位[编号].指令.类型=""
      self.参战单位[队友].指令.下达=true
      self.参战单位[队友].指令.类型=""
      return true
    end
  end
  return false
end


function 战斗处理类:经脉回合开始处理(编号)
  if self.参战单位[编号].奇经八脉 ~= nil then

    if 编号~=nil and self:取奇经八脉是否有(编号,"回魔") and (self.参战单位[编号].最大魔法-self.参战单位[编号].灵力)>0 then
      self:增加魔法(编号,qz((self.参战单位[编号].最大魔法-self.参战单位[编号].灵力)*0.05))
    end


    if 编号~=nil and self:取奇经八脉是否有(编号,"龙骇") and self.参战单位[编号].龙骇==nil then
      if self.参战单位[编号].法暴 == nil then
        self.参战单位[编号].法暴=0
      end
    self.参战单位[编号].法暴=self.参战单位[编号].法暴+15
    self.参战单位[编号].龙骇=true
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"战魄") then
      self.参战单位[编号].愤怒 = self.参战单位[编号].愤怒+1
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"鬼火") then
      self.参战单位[编号].愤怒 = self.参战单位[编号].愤怒+5
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"默诵") then
      self.参战单位[编号].愤怒 = self.参战单位[编号].愤怒+3
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"汲魂") then
      if self.参战单位[编号].汲魂 == nil or self.参战单位[编号].汲魂 <= 100 then
        if self.参战单位[编号].汲魂  == nil then
          self.参战单位[编号].汲魂  = 0
        end
        self.参战单位[编号].伤害 = self.参战单位[编号].伤害+100
        self.参战单位[编号].汲魂 = self.参战单位[编号].汲魂  +20
      end
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"怒火释放") and self.参战单位[编号].怒火释放==nil then
            if self.参战单位[编号].怒火释放==nil then
          self.参战单位[编号].怒火释放=0
      end
    self.参战单位[编号].伤害 = qz(self.参战单位[编号].伤害*1.15)
    self.参战单位[编号].防御 = qz(self.参战单位[编号].防御*0.9)
    self.参战单位[编号].怒火释放=true
    end

  if 编号~=nil and self:取奇经八脉是否有(编号,"神念") then
      self.参战单位[编号].愤怒=self.参战单位[编号].愤怒+10
      if self.参战单位[编号].愤怒 > 150 then
        self.参战单位[编号].愤怒 = 150
      end
  end
    if 编号~=nil and self:取奇经八脉是否有(编号,"补缺") and self.参战单位[编号].魔法 <= self.参战单位[编号].最大魔法*0.3 then
      self:增加魔法(编号,self.参战单位[编号].最大魔法*0.1)
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"神躯") and self.参战单位[编号].神躯==nil then
      if self.参战单位[编号].神躯==nil then
          self.参战单位[编号].神躯=0
      end
      self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.2)
      self.参战单位[编号].法防=qz(self.参战单位[编号].法防*1.2)
      self.参战单位[编号].神躯=true
    end


    if 编号~=nil and self:取奇经八脉是否有(编号,"不惊") and self.参战单位[编号].不惊==nil then
      if self.参战单位[编号].不惊==nil then
          self.参战单位[编号].不惊=0
      end
      self.参战单位[编号].伤害=self.参战单位[编号].伤害+qz(self.参战单位[编号].防御*0.1)
      self.参战单位[编号].不惊=true
    end
  end
end

function 战斗处理类:经脉属性处理(编号)
      if 编号~=nil and self:取奇经八脉是否有(编号,"花舞") then
      self.参战单位[编号].速度 = self.参战单位[编号].速度 + self.参战单位[编号].速度*0.3
 end
   if self.参战单位[编号].奇经八脉 ~= nil then
    if 编号~=nil and self:取奇经八脉是否有(编号,"额外能力") then
          self.参战单位[编号].伤害 = self.参战单位[编号].伤害*1.1
          self.参战单位[编号].防御 = self.参战单位[编号].防御*1.1
          self.参战单位[编号].灵力 = self.参战单位[编号].灵力*1.1
          self.参战单位[编号].法防 = self.参战单位[编号].法防*1.1
          self.参战单位[编号].速度 = self.参战单位[编号].速度*1.1
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"洞察") then
        self.参战单位[编号].伤害 = self.参战单位[编号].伤害+self.参战单位[编号].等级/2
        self.参战单位[编号].防御 = self.参战单位[编号].防御+self.参战单位[编号].等级/2
        self.参战单位[编号].灵力 = self.参战单位[编号].灵力+self.参战单位[编号].等级/2
        self.参战单位[编号].法防 = self.参战单位[编号].法防+self.参战单位[编号].等级/2
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"修身") then
        self.参战单位[编号].伤害 = self.参战单位[编号].伤害+50
        self.参战单位[编号].防御 = self.参战单位[编号].防御+50
        self.参战单位[编号].灵力 = self.参战单位[编号].灵力+50
        self.参战单位[编号].法防 = self.参战单位[编号].法防+50
        self.参战单位[编号].气血 = self.参战单位[编号].气血+50*4.5
        self.参战单位[编号].最大气血 = self.参战单位[编号].最大气血+50*4.5
        self.参战单位[编号].速度 = self.参战单位[编号].速度+50
        self.参战单位[编号].最大魔法 = self.参战单位[编号].最大魔法+50
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"聚魂") then
      if self.参战单位[编号].法伤==nil then
        self.参战单位[编号].法伤=1
      end
        self.参战单位[编号].伤害 = self.参战单位[编号].伤害+100
        self.参战单位[编号].防御 = self.参战单位[编号].防御+100
        self.参战单位[编号].灵力 = self.参战单位[编号].灵力+100
        self.参战单位[编号].法防 = self.参战单位[编号].法防+100
        self.参战单位[编号].法伤 = self.参战单位[编号].法伤+100
        self.参战单位[编号].必杀 = self.参战单位[编号].必杀+20
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"六道无量") then
        self.参战单位[编号].必杀 = self.参战单位[编号].必杀+20
    end
    if 昼夜参数==1 then
      if 编号~=nil and self:取奇经八脉是否有(编号,"夜行") then
        self.参战单位[编号].伤害=self.参战单位[编号].伤害+40
        self.参战单位[编号].速度=self.参战单位[编号].速度+40
        self.参战单位[编号].固定伤害=self.参战单位[编号].固定伤害+50
      end
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"忘形") then
      if self.参战单位[编号].必杀==nil then
          self.参战单位[编号].必杀=0
      end
      if self.参战单位[编号].法暴==nil then
        self.参战单位[编号].法暴=0
      end
       self.参战单位[编号].必杀 = self.参战单位[编号].必杀+3
       self.参战单位[编号].法暴 = self.参战单位[编号].法暴+3
    end
    if 编号~=nil then
    self.参战单位[编号].法暴 = self.参战单位[编号].法暴+3
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"舍利") then
    self.参战单位[编号].法暴 = self.参战单位[编号].法暴+10
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"化身") then
    self.参战单位[编号].法暴 = self.参战单位[编号].法暴+20
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"诸天看护") then
    self.参战单位[编号].法暴 = self.参战单位[编号].法暴+15
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"雨杀") then
      self.参战单位[编号].必杀 = self.参战单位[编号].必杀+20
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"坚甲")  then
      self.参战单位[编号].防御 = self.参战单位[编号].防御*1.3
  end
    if 编号~=nil and self:取奇经八脉是否有(编号,"豪胆") then
      if self.参战单位[编号].必杀==nil then
        self.参战单位[编号].必杀=0
      end
      self.参战单位[编号].必杀 = self.参战单位[编号].必杀+10
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"静岳") then
        self.参战单位[编号].气血 = self.参战单位[编号].气血*1.3
        self.参战单位[编号].最大气血 = self.参战单位[编号].最大气血*1.3
        if self.参战单位[编号].法伤==nil then
          self.参战单位[编号].法伤=self.参战单位[编号].灵力
        end
        self.参战单位[编号].法伤 = self.参战单位[编号].法伤 + qz(self.参战单位[编号].伤害/self.参战单位[编号].耐力)*30
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"狂月") then
         self.参战单位[编号].魔法 = self.参战单位[编号].魔法*1.3
        self.参战单位[编号].最大魔法 = self.参战单位[编号].最大魔法*1.3
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"燃魂") then
    self.参战单位[编号].灵力 = self.参战单位[编号].灵力+qz(self.参战单位[编号].最大气血/100)
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"灵光") then
      self.参战单位[编号].灵力 =self.参战单位[编号].灵力+self.参战单位[编号].灵力*0.5
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"神律") then
      self.参战单位[编号].必杀 = self.参战单位[编号].必杀+15
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"雷波") then
      self.参战单位[编号].法暴 = self.参战单位[编号].法暴+10
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"魔焰滔天") then
      self.参战单位[编号].法暴 = self.参战单位[编号].法暴+20
    end
  if 编号~=nil and self:取奇经八脉是否有(编号,"敛恨") then
  self.参战单位[编号].法防=qz(self.参战单位[编号].法防*1.15)
  self.参战单位[编号].防御=qz(self.参战单位[编号].防御*1.15)
  self.参战单位[编号].法暴 = self.参战单位[编号].法暴+5
  end

    if 编号~=nil and self:取奇经八脉是否有(编号,"狂狷") then
        self.参战单位[编号].伤害 = self.参战单位[编号].伤害 + (self.参战单位[编号].力量/self.参战单位[编号].耐力)*16
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"烈焰真诀") then
        self.参战单位[编号].法暴 = self.参战单位[编号].法暴 + 10
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"归气") then
        if self.参战单位[编号].治疗能力==nil then
          self.参战单位[编号].治疗能力=0
        end
        self.参战单位[编号].治疗能力 = self.参战单位[编号].治疗能力 +(self.参战单位[编号].灵力/10)
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"佛誉") then
        if self.参战单位[编号].治疗能力==nil then
          self.参战单位[编号].治疗能力=0
        end
        self.参战单位[编号].治疗能力 = self.参战单位[编号].治疗能力+200
    end

        if 编号~=nil and self:取奇经八脉是否有(编号,"意境") then
        if self.参战单位[编号].治疗能力==nil then
          self.参战单位[编号].治疗能力=0
        end
        self.参战单位[编号].治疗能力 = self.参战单位[编号].治疗能力 +self.参战单位[编号].伤害*0.5
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"驭意") then
        self.参战单位[编号].速度 = self.参战单位[编号].速度 + self.参战单位[编号].魔力*0.1
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"神凝") then
        if self.参战单位[编号].抵抗封印等级 == nil then
          self.参战单位[编号].抵抗封印等级 = 0
        end
        self.参战单位[编号].抵抗封印等级 = self.参战单位[编号].抵抗封印等级 + 100
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"破击") then
      if self.参战单位[编号].必杀 == nil then
      self.参战单位[编号].必杀 = 0
      end
      self.参战单位[编号].必杀 = self.参战单位[编号].必杀 + 20
      end

    if 编号~=nil and self:取奇经八脉是否有(编号,"慈心") then
    self.参战单位[编号].防御=self.参战单位[编号].防御+200
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"流刚") then
        self.参战单位[编号].防御 = self.参战单位[编号].防御 *1.3
        self.参战单位[编号].法防 = self.参战单位[编号].法防 *1.3
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"魔息") then
        self.参战单位[编号].防御 = self.参战单位[编号].防御 *1.3
        self.参战单位[编号].法防 = self.参战单位[编号].法防 *1.3
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"念心") then
       self.参战单位[编号].必杀 = self.参战单位[编号].必杀 *1.2
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"傲视") then
    self.参战单位[编号].伤害 = self.参战单位[编号].伤害+200
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"海沸") then
       self.参战单位[编号].伤害 = self.参战单位[编号].伤害 + self.参战单位[编号].力量*0.08
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"纯净") then
       self.参战单位[编号].最大气血 = self.参战单位[编号].最大气血+(self.参战单位[编号].灵力/2)
    end

    if 编号~=nil and self:取奇经八脉是否有(编号,"护佑") then
       self.参战单位[编号].防御 = self.参战单位[编号].防御+300
       self.参战单位[编号].法防 = self.参战单位[编号].法防+300
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"化血") then
       self.参战单位[编号].吸血=0.05
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"狂袭") then
       self.参战单位[编号].偷袭=1
       self.参战单位[编号].伤害 = self.参战单位[编号].伤害 + self.参战单位[编号].武器伤害*0.18
    end
    if 编号~=nil and self:取奇经八脉是否有(编号,"风刃") then
       self.参战单位[编号].溅射人数=self.参战单位[编号].溅射人数+2
       self.参战单位[编号].溅射=self.参战单位[编号].溅射+0.001
    end
  end
end

function 战斗处理类:发送退出信息()
  for n=1,#self.参战玩家 do
      if 自动遇怪[self.参战玩家[n].id]~=nil then
        自动遇怪[self.参战玩家[n].id]=os.time()
      end
      if 玩家数据[self.参战玩家[n].id]~=nil then
        发送数据(self.参战玩家[n].连接id,5505)
        玩家数据[self.参战玩家[n].id].战斗=0
        玩家数据[self.参战玩家[n].id].遇怪时间=os.time()+取随机数(10,20)
        玩家数据[self.参战玩家[n].id].道具:重置法宝回合(self.参战玩家[n].id)
        玩家数据[self.参战玩家[n].id].角色.数据.战斗开关=nil
        地图处理类:设置战斗开关(self.参战玩家[n].id)
        if 玩家数据[self.参战玩家[n].id].战斗对话~=nil then
          发送数据(玩家数据[self.参战玩家[n].id].连接id,1501,玩家数据[self.参战玩家[n].id].战斗对话)
          end
          if self.战斗类型==100011 then
            发送数据(玩家数据[self.参战玩家[n].id].连接id,1501,self.对话数据)
          end
          玩家数据[self.参战玩家[n].id].战斗对话=nil
          if self.参战玩家[n].断线 then
            系统处理类:断开游戏(self.参战玩家[n].id)
          end
        end
        if self.战斗类型==100019 and self.玩家胜利 and 取随机数()<=2 then
          local id=self.进入战斗玩家id
          if 玩家数据[id].角色.数据.地图数据.编号~=1620 then
            local 随机递增=取随机数(1,3)
            local 传送地图= 玩家数据[id].角色.数据.地图数据.编号+随机递增
            if 传送地图>1620 then
              传送地图=1620
            end
            local xy=地图处理类.地图坐标[传送地图]:取随机点()
            地图处理类:跳转地图(id,传送地图,xy.x,xy.y)
            常规提示(id,"#Y你击败了迷宫小怪后，意外地发现自己来到了#R"..取地图名称(传送地图))
          end
    elseif self.战斗类型==100214 and self.玩家胜利 then --大闹黑白无常
      if self.参战玩家[n].id == self.进入战斗玩家id then
        地图处理类:跳转地图(self.参战玩家[n].id,6037,100,101)
      end
    elseif self.战斗类型==100215 and self.玩家胜利 then
      if self.参战玩家[n].id == self.进入战斗玩家id then
        地图处理类:跳转地图(self.参战玩家[n].id,6036,12,108)
      end
        end
  end
  for i,v in pairs(self.观战玩家) do
    if 玩家数据[i] ~= nil then
      if 自动遇怪[i]~=nil then
        自动遇怪[i]=os.time()
      end
      发送数据(玩家数据[i].连接id,5505)
      玩家数据[i].战斗=0
      玩家数据[i].观战=nil
      玩家数据[i].遇怪时间=os.time()+取随机数(10,20)
    end
  end
  self.结束条件=true
  if self.战斗类型==100050 and self.战斗失败==false then
    local 数字id=self.进入战斗玩家id
              local 剑会假人属性 = {}
          local 武器伤害 = 0
          for n=1,5 do
          if 玩家数据[数字id].角色.数据.装备[3]~=nil then
            local 临时武器=table.loadstring(table.tostring(玩家数据[数字id].道具.数据[玩家数据[数字id].角色.数据.装备[3]]))
            武器伤害=qz(临时武器.伤害+临时武器.命中*0.3)
          end
          剑会假人属性[#剑会假人属性+1]={
            名称="飞升守护者",
            模型=玩家数据[数字id].角色.数据.模型,
            等级=玩家数据[数字id].角色.数据.等级,
            气血=玩家数据[数字id].角色.数据.最大气血,
            魔法=玩家数据[数字id].角色.数据.最大魔法,
            伤害=玩家数据[数字id].角色.数据.伤害,
            灵力=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术伤害,
            速度=玩家数据[数字id].角色.数据.速度,
            防御=玩家数据[数字id].角色.数据.防御,
            法防=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术防御,
            攻击修炼=玩家数据[数字id].角色.数据.修炼.攻击修炼[1],
            法术修炼=玩家数据[数字id].角色.数据.修炼.法术修炼[1],
            防御修炼=玩家数据[数字id].角色.数据.修炼.防御修炼[1],
            抗法修炼=玩家数据[数字id].角色.数据.修炼.抗法修炼[1],
            角色分类="角色",
            门派=玩家数据[数字id].角色.数据.门派,
            五维属性={体质=玩家数据[数字id].角色.数据.体质,魔力=玩家数据[数字id].角色.数据.魔力,力量=玩家数据[数字id].角色.数据.力量,耐力=玩家数据[数字id].角色.数据.耐力,敏捷=玩家数据[数字id].角色.数据.敏捷},
            武器伤害=武器伤害,
            位置=n,
          }
          -- table.print(玩家数据[数字id].角色.数据)
          if not 判断是否为空表(玩家数据[数字id].角色.数据.参战宝宝) then
            剑会假人属性[#剑会假人属性+1]={
              名称=玩家数据[数字id].角色.数据.参战宝宝.模型,
              模型=玩家数据[数字id].角色.数据.参战宝宝.模型,
              等级=玩家数据[数字id].角色.数据.参战宝宝.等级,
              气血=玩家数据[数字id].角色.数据.参战宝宝.最大气血,
              魔法=玩家数据[数字id].角色.数据.参战宝宝.最大魔法,
              伤害=玩家数据[数字id].角色.数据.参战宝宝.伤害,
              灵力=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              速度=玩家数据[数字id].角色.数据.参战宝宝.速度,
              防御=玩家数据[数字id].角色.数据.参战宝宝.防御,
              法防=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              攻击修炼=玩家数据[数字id].角色.数据.bb修炼.攻击控制力[1],
              法术修炼=玩家数据[数字id].角色.数据.bb修炼.法术控制力[1],
              防御修炼=玩家数据[数字id].角色.数据.bb修炼.防御控制力[1],
              抗法修炼=玩家数据[数字id].角色.数据.bb修炼.抗法控制力[1],
              技能=玩家数据[数字id].角色.数据.参战宝宝.技能,
              参战等级=玩家数据[数字id].角色.数据.参战宝宝.参战等级,
              五维属性={体质=玩家数据[数字id].角色.数据.参战宝宝.体质,魔力=玩家数据[数字id].角色.数据.参战宝宝.魔力,力量=玩家数据[数字id].角色.数据.参战宝宝.力量,耐力=玩家数据[数字id].角色.数据.参战宝宝.耐力,敏捷=玩家数据[数字id].角色.数据.参战宝宝.敏捷},
              内丹数据=玩家数据[数字id].角色.数据.参战宝宝.内丹数据,
              位置=n+5
            }
          end
        end
          战斗准备类:创建战斗(数字id,100051,任务id,任务id,剑会假人属性)
    --战斗准备类:创建战斗(id,100051,self.任务id)
  elseif self.战斗类型==100051 and self.战斗失败==false then
    local 数字id=self.进入战斗玩家id
              local 剑会假人属性 = {}
          local 武器伤害 = 0
          for n=1,5 do
          if 玩家数据[数字id].角色.数据.装备[3]~=nil then
            local 临时武器=table.loadstring(table.tostring(玩家数据[数字id].道具.数据[玩家数据[数字id].角色.数据.装备[3]]))
            武器伤害=qz(临时武器.伤害+临时武器.命中*0.3)
          end
          剑会假人属性[#剑会假人属性+1]={
            名称="飞升守护者",
            模型=玩家数据[数字id].角色.数据.模型,
            等级=玩家数据[数字id].角色.数据.等级,
            气血=玩家数据[数字id].角色.数据.最大气血,
            魔法=玩家数据[数字id].角色.数据.最大魔法,
            伤害=玩家数据[数字id].角色.数据.伤害,
            灵力=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术伤害,
            速度=玩家数据[数字id].角色.数据.速度,
            防御=玩家数据[数字id].角色.数据.防御,
            法防=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术防御,
            攻击修炼=玩家数据[数字id].角色.数据.修炼.攻击修炼[1],
            法术修炼=玩家数据[数字id].角色.数据.修炼.法术修炼[1],
            防御修炼=玩家数据[数字id].角色.数据.修炼.防御修炼[1],
            抗法修炼=玩家数据[数字id].角色.数据.修炼.抗法修炼[1],
            角色分类="角色",
            门派=玩家数据[数字id].角色.数据.门派,
            五维属性={体质=玩家数据[数字id].角色.数据.体质,魔力=玩家数据[数字id].角色.数据.魔力,力量=玩家数据[数字id].角色.数据.力量,耐力=玩家数据[数字id].角色.数据.耐力,敏捷=玩家数据[数字id].角色.数据.敏捷},
            武器伤害=武器伤害,
            位置=n,
          }
          -- table.print(玩家数据[数字id].角色.数据)
          if not 判断是否为空表(玩家数据[数字id].角色.数据.参战宝宝) then
            剑会假人属性[#剑会假人属性+1]={
              名称=玩家数据[数字id].角色.数据.参战宝宝.模型,
              模型=玩家数据[数字id].角色.数据.参战宝宝.模型,
              等级=玩家数据[数字id].角色.数据.参战宝宝.等级,
              气血=玩家数据[数字id].角色.数据.参战宝宝.最大气血,
              魔法=玩家数据[数字id].角色.数据.参战宝宝.最大魔法,
              伤害=玩家数据[数字id].角色.数据.参战宝宝.伤害,
              灵力=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              速度=玩家数据[数字id].角色.数据.参战宝宝.速度,
              防御=玩家数据[数字id].角色.数据.参战宝宝.防御,
              法防=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              攻击修炼=玩家数据[数字id].角色.数据.bb修炼.攻击控制力[1],
              法术修炼=玩家数据[数字id].角色.数据.bb修炼.法术控制力[1],
              防御修炼=玩家数据[数字id].角色.数据.bb修炼.防御控制力[1],
              抗法修炼=玩家数据[数字id].角色.数据.bb修炼.抗法控制力[1],
              技能=玩家数据[数字id].角色.数据.参战宝宝.技能,
              参战等级=玩家数据[数字id].角色.数据.参战宝宝.参战等级,
              五维属性={体质=玩家数据[数字id].角色.数据.参战宝宝.体质,魔力=玩家数据[数字id].角色.数据.参战宝宝.魔力,力量=玩家数据[数字id].角色.数据.参战宝宝.力量,耐力=玩家数据[数字id].角色.数据.参战宝宝.耐力,敏捷=玩家数据[数字id].角色.数据.参战宝宝.敏捷},
              内丹数据=玩家数据[数字id].角色.数据.参战宝宝.内丹数据,
              位置=n+5
            }
          end
        end
          战斗准备类:创建战斗(数字id,100052,任务id,任务id,剑会假人属性)
  elseif self.战斗类型==100052 and self.战斗失败==false then
    local 数字id=self.进入战斗玩家id
              local 剑会假人属性 = {}
          local 武器伤害 = 0
          for n=1,5 do
          if 玩家数据[数字id].角色.数据.装备[3]~=nil then
            local 临时武器=table.loadstring(table.tostring(玩家数据[数字id].道具.数据[玩家数据[数字id].角色.数据.装备[3]]))
            武器伤害=qz(临时武器.伤害+临时武器.命中*0.3)
          end
          剑会假人属性[#剑会假人属性+1]={
            名称="飞升守护者",
            模型=玩家数据[数字id].角色.数据.模型,
            等级=玩家数据[数字id].角色.数据.等级,
            气血=玩家数据[数字id].角色.数据.最大气血,
            魔法=玩家数据[数字id].角色.数据.最大魔法,
            伤害=玩家数据[数字id].角色.数据.伤害,
            灵力=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术伤害,
            速度=玩家数据[数字id].角色.数据.速度,
            防御=玩家数据[数字id].角色.数据.防御,
            法防=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术防御,
            攻击修炼=玩家数据[数字id].角色.数据.修炼.攻击修炼[1],
            法术修炼=玩家数据[数字id].角色.数据.修炼.法术修炼[1],
            防御修炼=玩家数据[数字id].角色.数据.修炼.防御修炼[1],
            抗法修炼=玩家数据[数字id].角色.数据.修炼.抗法修炼[1],
            角色分类="角色",
            门派=玩家数据[数字id].角色.数据.门派,
            五维属性={体质=玩家数据[数字id].角色.数据.体质,魔力=玩家数据[数字id].角色.数据.魔力,力量=玩家数据[数字id].角色.数据.力量,耐力=玩家数据[数字id].角色.数据.耐力,敏捷=玩家数据[数字id].角色.数据.敏捷},
            武器伤害=武器伤害,
            位置=n,
          }
          -- table.print(玩家数据[数字id].角色.数据)
          if not 判断是否为空表(玩家数据[数字id].角色.数据.参战宝宝) then
            剑会假人属性[#剑会假人属性+1]={
              名称=玩家数据[数字id].角色.数据.参战宝宝.模型,
              模型=玩家数据[数字id].角色.数据.参战宝宝.模型,
              等级=玩家数据[数字id].角色.数据.参战宝宝.等级,
              气血=玩家数据[数字id].角色.数据.参战宝宝.最大气血,
              魔法=玩家数据[数字id].角色.数据.参战宝宝.最大魔法,
              伤害=玩家数据[数字id].角色.数据.参战宝宝.伤害,
              灵力=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              速度=玩家数据[数字id].角色.数据.参战宝宝.速度,
              防御=玩家数据[数字id].角色.数据.参战宝宝.防御,
              法防=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              攻击修炼=玩家数据[数字id].角色.数据.bb修炼.攻击控制力[1],
              法术修炼=玩家数据[数字id].角色.数据.bb修炼.法术控制力[1],
              防御修炼=玩家数据[数字id].角色.数据.bb修炼.防御控制力[1],
              抗法修炼=玩家数据[数字id].角色.数据.bb修炼.抗法控制力[1],
              技能=玩家数据[数字id].角色.数据.参战宝宝.技能,
              参战等级=玩家数据[数字id].角色.数据.参战宝宝.参战等级,
              五维属性={体质=玩家数据[数字id].角色.数据.参战宝宝.体质,魔力=玩家数据[数字id].角色.数据.参战宝宝.魔力,力量=玩家数据[数字id].角色.数据.参战宝宝.力量,耐力=玩家数据[数字id].角色.数据.参战宝宝.耐力,敏捷=玩家数据[数字id].角色.数据.参战宝宝.敏捷},
              内丹数据=玩家数据[数字id].角色.数据.参战宝宝.内丹数据,
              位置=n+5
            }
          end
        end
          战斗准备类:创建战斗(数字id,100053,任务id,任务id,剑会假人属性)
  elseif self.战斗类型==100053 and self.战斗失败==false then
    local 数字id=self.进入战斗玩家id
              local 剑会假人属性 = {}
          local 武器伤害 = 0
          for n=1,5 do
          if 玩家数据[数字id].角色.数据.装备[3]~=nil then
            local 临时武器=table.loadstring(table.tostring(玩家数据[数字id].道具.数据[玩家数据[数字id].角色.数据.装备[3]]))
            武器伤害=qz(临时武器.伤害+临时武器.命中*0.3)
          end
          剑会假人属性[#剑会假人属性+1]={
            名称="飞升守护者",
            模型=玩家数据[数字id].角色.数据.模型,
            等级=玩家数据[数字id].角色.数据.等级,
            气血=玩家数据[数字id].角色.数据.最大气血,
            魔法=玩家数据[数字id].角色.数据.最大魔法,
            伤害=玩家数据[数字id].角色.数据.伤害,
            灵力=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术伤害,
            速度=玩家数据[数字id].角色.数据.速度,
            防御=玩家数据[数字id].角色.数据.防御,
            法防=玩家数据[数字id].角色.数据.灵力+玩家数据[数字id].角色.数据.法术防御,
            攻击修炼=玩家数据[数字id].角色.数据.修炼.攻击修炼[1],
            法术修炼=玩家数据[数字id].角色.数据.修炼.法术修炼[1],
            防御修炼=玩家数据[数字id].角色.数据.修炼.防御修炼[1],
            抗法修炼=玩家数据[数字id].角色.数据.修炼.抗法修炼[1],
            角色分类="角色",
            门派=玩家数据[数字id].角色.数据.门派,
            五维属性={体质=玩家数据[数字id].角色.数据.体质,魔力=玩家数据[数字id].角色.数据.魔力,力量=玩家数据[数字id].角色.数据.力量,耐力=玩家数据[数字id].角色.数据.耐力,敏捷=玩家数据[数字id].角色.数据.敏捷},
            武器伤害=武器伤害,
            位置=n,
          }
          -- table.print(玩家数据[数字id].角色.数据)
          if not 判断是否为空表(玩家数据[数字id].角色.数据.参战宝宝) then
            剑会假人属性[#剑会假人属性+1]={
              名称=玩家数据[数字id].角色.数据.参战宝宝.模型,
              模型=玩家数据[数字id].角色.数据.参战宝宝.模型,
              等级=玩家数据[数字id].角色.数据.参战宝宝.等级,
              气血=玩家数据[数字id].角色.数据.参战宝宝.最大气血,
              魔法=玩家数据[数字id].角色.数据.参战宝宝.最大魔法,
              伤害=玩家数据[数字id].角色.数据.参战宝宝.伤害,
              灵力=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              速度=玩家数据[数字id].角色.数据.参战宝宝.速度,
              防御=玩家数据[数字id].角色.数据.参战宝宝.防御,
              法防=玩家数据[数字id].角色.数据.参战宝宝.灵力,
              攻击修炼=玩家数据[数字id].角色.数据.bb修炼.攻击控制力[1],
              法术修炼=玩家数据[数字id].角色.数据.bb修炼.法术控制力[1],
              防御修炼=玩家数据[数字id].角色.数据.bb修炼.防御控制力[1],
              抗法修炼=玩家数据[数字id].角色.数据.bb修炼.抗法控制力[1],
              技能=玩家数据[数字id].角色.数据.参战宝宝.技能,
              参战等级=玩家数据[数字id].角色.数据.参战宝宝.参战等级,
              五维属性={体质=玩家数据[数字id].角色.数据.参战宝宝.体质,魔力=玩家数据[数字id].角色.数据.参战宝宝.魔力,力量=玩家数据[数字id].角色.数据.参战宝宝.力量,耐力=玩家数据[数字id].角色.数据.参战宝宝.耐力,敏捷=玩家数据[数字id].角色.数据.参战宝宝.敏捷},
              内丹数据=玩家数据[数字id].角色.数据.参战宝宝.内丹数据,
              位置=n+5
            }
          end
        end
          战斗准备类:创建战斗(数字id,100054,任务id,任务id,剑会假人属性)
  end
  if self.战斗类型==100130 and self.战斗失败==false then
    local id=self.进入战斗玩家id
    战斗准备类:创建战斗(id,100131,self.任务id)
  elseif self.战斗类型==100131 and self.战斗失败==false then
    local id=self.进入战斗玩家id
    战斗准备类:创建战斗(id,100132,self.任务id)
  elseif self.战斗类型==100132 and self.战斗失败==false then
    local id=self.进入战斗玩家id
    战斗准备类:创建战斗(id,100133,self.任务id)
  elseif self.战斗类型==100133 and self.战斗失败==false then
    local id=self.进入战斗玩家id
    战斗准备类:创建战斗(id,100134,self.任务id)
  elseif self.战斗类型==100228 and self.战斗失败==false then
    local id=self.进入战斗玩家id
    战斗准备类:创建战斗(id,100229,self.任务id)
  elseif self.战斗类型==100252 and self.战斗失败==false then
    local id=self.进入战斗玩家id
    战斗准备类:创建战斗(id,100253,self.任务id)
  elseif self.战斗类型==100253 and self.战斗失败==false then
    local id=self.进入战斗玩家id
    战斗准备类:创建战斗(id,100254,self.任务id)

  end
end



function 战斗处理类:更新(dt) --自动时间
  if self.回合进程=="命令回合" then
    if os.time()-self.等待起始>=3 then
      for n=1,#self.参战单位 do
        if self.参战单位[n].自动战斗 and self.参战单位[n].指令.下达==false then
          if self.参战单位[n].自动指令~=nil and 玩家数据[self.参战单位[n].玩家id]~=nil and 玩家数据[self.参战单位[n].玩家id].角色.数据.自动战斗 then
            self.参战单位[n].指令=table.loadstring(table.tostring(self.参战单位[n].自动指令))
            --重新计算
            if self.参战单位[n].指令.类型=="法术" then
              if self.参战单位[n].指令.参数=="" then
                self.参战单位[n].指令.类型="攻击"
                self.参战单位[n].指令.目标=self:取单个敌方目标(n)
              else
                local 临时技能=取法术技能(self.参战单位[n].指令.参数)
                if 临时技能[3]==4 then
                  self.参战单位[n].指令.目标=self:取单个敌方目标(n)
                else
                  self.参战单位[n].指令.目标=self:取单个友方目标(n)
                end
              end
            end
            if self.参战单位[self.参战单位[n].指令.目标]==nil and self.参战单位[n].指令.类型~="防御" then
              self.参战单位[n].指令.类型="攻击"
              self.参战单位[n].指令.目标=self:取单个敌方目标(n)
            end
          else
            self.参战单位[n].指令.类型="攻击"
            self.参战单位[n].指令.目标=self:取单个敌方目标(n)
          end
          self.参战单位[n].指令.下达=true
          if 玩家数据~=nil and self.参战单位[n].玩家id~=nil and 玩家数据[self.参战单位[n].玩家id]~=nil then
            发送数据(玩家数据[self.参战单位[n].玩家id].连接id,5511)
          end
          if self.参战单位[n].队伍~=0 and self.参战单位[n].类型=="角色" and self.参战单位[n].助战编号==nil then
            self.加载数量=self.加载数量-1
          end
        end
      end
    end
    if self.加载数量<=0 then
      self.回合进程="计算回合"
      self:设置执行回合()
    end
    if os.time()-self.等待起始>=62 then
      self.回合进程="计算回合"
      self:设置执行回合()
    end
  elseif self.回合进程=="执行回合" then
      --检查是否有自动
     --[[local 断线数量=0
     for n=1,#self.参战玩家 do
       if self.参战玩家[n].断线等待 then
         断线数量=断线数量+1
         end
       end
     if 断线数量==#self.参战玩家  then
       --self.执行等待=os.time()+5
         for n=1,#self.参战玩家 do
            self.参战玩家[n].断线等待=nil
          end
       return
       end --]]
       --print(os.time(),self)
    if os.time()>=self.执行等待 and self.回合进程~="结束回合" then
      self.回合进程="结束回合"
      self:结算处理()
    end
  end
end
function 战斗处理类:显示(x,y)end
return 战斗处理类