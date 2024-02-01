-- @Author: baidwwy
-- @Date:   2023-03-10 11:49:53
-- @Last Modified by:   baidwwy
-- @Last Modified time: 2023-06-22 17:28:24
--======================================================================--
-- @作者: GGE研究群: 342119466
-- @创建时间:   2018-03-03 02:34:19
-- @Last Modified time: 2023-05-05 00:53:29
-- 梦幻西游游戏资源破解 baidwwy@vip.qq.com(313738139) 老毕   和 C++PrimerPlus 717535046 这俩位大神破解所以资源
--======================================================================--
local 网络处理类 = class()
function 网络处理类:初始化() end

function 网络处理类:取角色选择id(id,账号)
  if 账号==nil or id==nil then
    return 0
  end
  local 临时id = 0
  if f函数.文件是否存在([[data/]]..账号..[[/信息.txt]])==false then
    return 0
  else
    local 临时文件=读入文件([[data/]]..账号..[[/信息.txt]])
    local 写入信息=table.loadstring(临时文件)
    if 写入信息[id+0]~=nil then
      if f函数.文件是否存在([[data/]]..账号..[[/]]..写入信息[id+0]..[[/角色.txt]])==false then
        return 0
      else
        local 读取文件=读入文件([[data/]]..账号..[[/]]..写入信息[id+0]..[[/角色.txt]])
        local 还原数据=table.loadstring(读取文件)
        if 还原数据~=nil then
          临时id = 还原数据.数字id
        else
          return 0
        end
      end
    else
       return 0
    end
  end
  return 临时id
end


function 错误消息输出(内容,事件,id)
     -- print(内容)
     -- print(事件)
    if __C客户信息[id]~=nil then
      --table.print(__C客户信息[id])
    end
    --__S服务:断开连接(id)
    --print("==================分隔符===================")
end

function 网络处理类:数据解密处理(id,数据内容)
  内容 =self:jm1(数据内容)
  if 内容==nil or 内容=="" then
     --self:断开连接(id,"通讯密码错误")
    return
  end
  --print(内容)
  if NB开关 then
    NB开关 = not NB开关
    --print(内容)
  end
  if string.find(内容, "function") ~= nil then
    错误消息输出(内容,"接收到局域函数信息",id)
    return
  end
  self.数据=分割文本(内容,fgf)
  if self.数据=="" or self.数据==nil then
    self:断开连接(id,"通讯密码错误")
    return
  end

  -- if tonumber(self.数据[1])==nil then
  --   if 老猫附体 then
  --     print("异常数据："..self.数据[1])
  --   end
  --   发送数据(id,999,"你亲妈在天上飞")
  --   return
  -- end
  self.数据[1]=self.数据[1]+0
  --------
  -- 数据校验
  if self.数据[3]==nil or self.数据[4]==nil or self.数据[5]==nil or self.数据[6]==nil then
    --print(内容,"接收到不完整消息",id)
    return
  end
  if os.time()-self.数据[3]>=30 then
      --print(内容,"接收到过期消息",id)
      return
  end
  local 数据校验 = 取校验数据(self.数据[1],self.数据[2],self.数据[5],self.数据[6],self.数据[3])
  if self.数据[4]~= 数据校验 then
      --print(内容,"数据校验错误",id)
      return
  else
      if 数据存档[数据校验]~=nil then
        --print(内容,"接收到重复数据",id)
        return
      else
          数据存档[数据校验] = {时间=os.time()}
      end
  end
  -- 数据校验
  if self.数据[1]==1  or self.数据[1] == 1.1 or self.数据[1] == 1.2 then --版本验证
    self.临时数据=分割文本(self.数据[2],fgc)
    -- if tonumber(self.临时数据[1])==nil then
    --   if 老猫附体 then
    --     print("异常数据："..self.临时数据[1])
    --   end
    --   发送数据(id,999,"你亲妈在天上飞")
    --   return
    -- end
    if (self.数据[1] == 1 or self.数据[1] == 1.1) and self.临时数据[1]+0~= 版本 then
      发送数据(id,999,"您的客户端版本过低，请到群里更新今日最新补丁运行游戏 by:武神坛！")
      return
    elseif f函数.读配置(程序目录..[[data\]]..self.临时数据[2]..[[\账号信息.txt]],"账号配置","封禁") == "1" then
      发送数据(id,999,"该账号已经被封禁！")
    else
      if self.临时数据[5]~=nil then
        self:数据处理(id,table.tostring({序号=-1,内容={账号=self.临时数据[2],密码=self.临时数据[3],qq=self.临时数据[4],硬盘=self.临时数据[5],ip=__C客户信息[id].IP}}))
      else
        local 内容={账号=self.临时数据[2],密码=self.临时数据[3],硬盘=self.临时数据[4],ip=__C客户信息[id].IP}
        -- print(系统处理类:账号验证(id,self.数据[1],内容))
        if 系统处理类:账号验证(id,self.数据[1],内容) then
           __C客户信息[id].账号 = self.临时数据[2]
        else
          __C客户信息[id].账号=nil
        end
        -- __C客户信息[id].账号 = self.临时数据[2]
        -- self:数据处理(id,table.tostring({序号=self.数据[1],内容={账号=self.临时数据[2],密码=self.临时数据[3],硬盘=self.临时数据[4],ip=__C客户信息[id].IP}}))
      end
    end
  elseif self.数据[1]==2 then
      self:数据处理(id,table.tostring({序号=self.数据[1],内容={账号=__C客户信息[id].账号}}))
  elseif self.数据[1]==3 then
      local nr= 分割文本(self.数据[2],"1222*-*1222")
      self:数据处理(id,table.tostring({序号=self.数据[1],内容={账号=__C客户信息[id].账号,模型=nr[1],名称=nr[2],染色ID=nr[3],ip=__C客户信息[id].IP}}))
  elseif self.数据[1]==4 or self.数据[1]==4.1 then
    -- table.print(self.数据)
     if __C客户信息[id].账号~=nil then
      self.临时数据=分割文本(self.数据[2],fgc)
     -- table.print(self.临时数据)
       --print(self.临时数据[1],__C客户信息[id].账号)
      __C客户信息[id].数字id = self:取角色选择id(self.临时数据[1],__C客户信息[id].账号) + 0
      if __C客户信息[id].数字id==0 then
        -- print("尝试错误的方式进入游戏")
        return
      end
       -- print(__C客户信息[id].数字id)
       -- print(self:取角色选择id(self.临时数据[1],__C客户信息[id].账号) + 0)
      -- if __C客户信息[id].数字id==nil or __C客户信息[id].数字id==0 or __C客户信息[id].数字id~=self:取角色选择id(self.临时数据[1],__C客户信息[id].账号) + 0  then

      --   return
      -- end
      self:数据处理(id,table.tostring({序号=self.数据[1],内容={账号=__C客户信息[id].账号,id=__C客户信息[id].数字id,硬盘=self.临时数据[2],ip=__C客户信息[id].IP}}))
     else
        -- print("尝试错误的方式进入游戏")
        return
      end

  elseif self.数据[1]==34 then --版本验证
    self.临时数据=分割文本(self.数据[2],fgc)
    if self.临时数据[1]+0~=版本 then
      发送数据(id,999,"您的客户端版本过低，请到群里更新今日最新补丁运行游戏")
    else
      __C客户信息[id].账号=self.临时数据[2]
      self:数据处理(id,table.tostring({序号=self.数据[1],内容={账号=self.临时数据[2],密码=self.临时数据[3],硬盘=self.临时数据[4],ip=__C客户信息[id].IP}}))
    end
  else
    -- print(self.数据[3])
--       {
--   [1]=14,
--   [2]="''"
--   [3]="时间"
--   [4]=nil
-- }
    self.临时数据=table.loadstring(self.数据[2])
    if self.临时数据==nil or self.临时数据=="" then return  end
    self.临时数据.ip=__C客户信息[id].IP
    self.临时数据.序号=self.数据[1]
    self.临时数据.数字id=__C客户信息[id].数字id
    self:数据处理(id,table.tostring(self.临时数据),self.数据[3])
  end
end

function 取校验数据(序号,内容,随机1,随机2,时间)
  local 加密协议号="xzcjasdiwsnfaasddwf1551337333abc"
  return  f函数.取MD5(序号..内容..随机1..加密协议号..随机2..时间)
end
--     local 序号=self.数据.序号+0
--   if 序号==4.81 or 序号==4.93 then
--     if 老猫附体 then
--       if self.数据.数字id~=nil and self.数据.数字id+0~=nil then
--         __S服务:输出(string.format("账号为：%s，发送序号：%s",玩家数据[self.数据.数字id+0].账号,self.数据.序号))
--       elseif self.数据.内容~=nil then
--         __S服务:输出(string.format("账号为：%s，发送序号：%s，ip为：%s",self.数据.内容.账号,self.数据.序号,self.数据.内容.ip))
--       end
--     end
--   end

-- end

--   local 序号=self.数据.序号+0
--   if 序号==3778 then
--     if 老猫附体 then
--       if self.数据.数字id~=nil and self.数据.数字id+0~=nil then
--         __S服务:输出(string.format("账号为：%s，发送序号：%s",玩家数据[self.数据.数字id+0].账号,self.数据.序号))
--       elseif self.数据.内容~=nil then
--         __S服务:输出(string.format("账号为：%s，发送序号：%s，ip为：%s",self.数据.内容.账号,self.数据.序号,self.数据.内容.ip))
--       end
--     end
--   end
-- end

function 网络处理类:数据处理(id,源,时间记录)
  self.数据=table.loadstring(源)
  --table.print(self.数据)
  local 序号=self.数据.序号+0
  if 序号<=5 or 序号==34 then  --小于等于5(我现在是4.2)
    系统处理类:数据处理(id,序号,self.数据.内容)--走这边
  elseif 序号<=1000 then
    self.数据.数字id=self.数据.数字id+0
    系统处理类:数据处理(id,序号,self.数据)
  elseif 序号>1000 and 序号<=1500 then --地图事件
  	地图处理类:数据处理(id,序号,self.数据.数字id+0,self.数据)
  elseif 序号>1500 and 序号<=2000 then --对话事件
  	对话处理类:数据处理(id,序号,self.数据.数字id+0,self.数据)
  elseif 序号>3500 and 序号<=4000 then --道具事件
  	玩家数据[self.数据.数字id+0].道具:数据处理(id,序号,self.数据.数字id+0,self.数据)
  elseif 序号>4000 and 序号<=4500 then --道具事件
  	队伍处理类:数据处理(id,序号,self.数据.数字id+0,self.数据)

  elseif 序号>4500 and 序号<=4599 then --道具事件
    玩家数据[self.数据.数字id+0].装备:数据处理(id,序号,self.数据.数字id+0,self.数据)
     elseif 序号==5000 then --道具事件
   打造处理类:数据处理(id,序号,self.数据.数字id+0,self.数据)
  elseif 序号>5000 and 序号<=5500 then --道具事件
    玩家数据[self.数据.数字id+0].召唤兽:数据处理(id,序号,self.数据.数字id+0,self.数据)
  elseif 序号>5500 and 序号<=6000 then --道具事件
    -- if tonumber(时间记录)==nil then
    --    __S服务:输出("玩家"..self.数据.数字id.."发送回来时间为空,判定使用跳过战斗!")  --如果没有时间发过来的 肯定用wpe了 给你记录一下  你手动封
    --    return
    -- end
    -- if math.abs(os.time()-时间记录)>=10 then
    --   __S服务:输出("玩家"..self.数据.数字id.."发送回来时间与服务器时间相差10秒以上,可能使用了跳过战斗")  --如果没有时间发过来的 肯定用wpe了 给你记录一下  你手动封
    --   return
    -- end
    if self.数据.数字id~=nil then
    战斗准备类:数据处理(self.数据.数字id+0,序号,self.数据)
    return 0
  end
    --玩家数据[self.数据.数字id+0].召唤兽:数据处理(id,序号,self.数据.数字id+0,self.数据)
  elseif 序号>6000 and 序号<=6100 then --道具事件
    聊天处理类:数据处理(self.数据.数字id+0,序号,self.数据)
  elseif 序号>6100 and 序号<=6199 then --帮派处理
    帮派处理类:数据处理(self.数据.数字id+0,序号,self.数据)
  elseif 序号>=6200 and 序号 <=6300 then--工具
    管理工具类3:数据处理(id,序号,self.数据)
    --管理工具类:数据处理(self.数据.数字id+0,序号,self.数据)
  elseif 序号>6300 and 序号 <=6400 then
    拍卖系统类:数据处理(id,序号,self.数据.数字id+0,self.数据)
  elseif 序号>7000 and 序号<=7100 then --召唤兽仓库事件
      玩家数据[self.数据.数字id+0].召唤兽仓库:数据处理(id,序号,self.数据.数字id+0,self.数据)
    elseif 序号 == 9000 then
      if 玩家数据[self.数据.id].角色.数据.装备查看 == false then
         常规提示(self.数据.数字id+0,"#Y/对方不允许查看装备！")
         return
      end
      玩家数据[self.数据.数字id+0].角色:取玩家装备信息(self.数据.数字id+0,self.数据.id)


  elseif  序号==99997 then
    服务端参数.连接数=self.数据.人数
  elseif  序号==99998 then

  elseif  序号==99999 then

  end
end
function 网络处理类:更新(dt) end
function 网络处理类:显示(x,y) end

function 网络处理类:断开处理(id,内容)
  if 内容 == nil then
    内容 = "未知"
  end
  发送数据(id,998,内容)
end

function 网络处理类:encodeBase641(source_str)
  local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local s64 = ''
  local str = source_str
  while #str > 0 do
      local bytes_num = 0
      local buf = 0

      for byte_cnt=1,3 do
          buf = (buf * 256)
          if #str > 0 then
              buf = buf + string.byte(str, 1, 1)
              str = string.sub(str, 2)
              bytes_num = bytes_num + 1
          end
      end

      for group_cnt=1,(bytes_num+1) do
          local b64char = math.fmod(math.floor(buf/262144),64) + 1
          s64 = s64 .. string.sub(b64chars, b64char, b64char)
          buf = buf * 64
      end

      for fill_cnt=1,(3-bytes_num) do
          s64 = s64 .. '='
      end
  end
  return s64
end

function 网络处理类:decodeBase641(str64)
  local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local temp={}
  for i=1,64 do
      temp[string.sub(b64chars,i,i)] = i
  end
  temp['=']=0
  local str=""
  for i=1,#str64,4 do
      if i>#str64 then
          break
      end
      local data = 0
      local str_count=0
      for j=0,3 do
          local str1=string.sub(str64,i+j,i+j)
          if not temp[str1] then
              return
          end
          if temp[str1] < 1 then
              data = data * 64
          else
              data = data * 64 + temp[str1]-1
              str_count = str_count + 1
          end
      end
      for j=16,0,-8 do
          if str_count > 0 then
              str=str..string.char(math.floor(data/math.pow(2,j)))
              data=math.mod(data,math.pow(2,j))
              str_count = str_count - 1
          end
      end
  end
  local last = tonumber(string.byte(str, string.len(str), string.len(str)))
  if last == 0 then
      str = string.sub(str, 1, string.len(str) - 1)
  end
  return str
end

kemy={}
mab = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/*=.，'
key={["B"]="Cb,",["S"]="3C,",["5"]="6D,",["D"]="2W,",["c"]="dc,",["E"]="cj,",["b"]="vt,",["3"]="Iv,",["s"]="j1,",["N"]="23,",["d"]="mP,",["6"]="wd,",["7"]="7R,",["e"]="ET,",["t"]="nB,",["8"]="9v,",["4"]="yP,",["W"]="j6,",["9"]="Wa,",["H"]="D2,",["G"]="Ve,",["g"]="JA,",["I"]="Au,",["X"]="NR,",["m"]="DG,",["w"]="Cx,",["Y"]="Qi,",["V"]="es,",["F"]="pF,",["z"]="CO,",["K"]="XC,",["f"]="aW,",["J"]="DT,",["x"]="S9,",["y"]="xi,",["v"]="My,",["L"]="PW,",["u"]="Aa,",["k"]="Yx,",["M"]="qL,",["j"]="ab,",["r"]="fN,",["q"]="0W,",["T"]="de,",["l"]="P8,",["0"]="q6,",["n"]="Hu,",["O"]="A2,",["1"]="VP,",["i"]="hY,",["h"]="Uc,",["C"]="cK,",["A"]="f4,",["P"]="is,",["U"]="u2,",["o"]="m9,",["Q"]="vd,",["R"]="gZ,",["2"]="Zu,",["Z"]="Pf,",["a"]="Lq,",["p"]="Sw,"}

function 网络处理类:jm(数据)
  数据=self:encodeBase641(数据)
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

function 网络处理类:jm1(数据)
  local jg=数据
  for n=1,#mab do
    local z=string.sub(mab,n,n)
    if key[z]~=nil then
       jg=string.gsub(jg,key[z],z)
    end
  end
  return self:decodeBase641(jg)
end



return 网络处理类