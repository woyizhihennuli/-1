-- @Author: 作者QQ1551337333
-- @Date:   2023-04-21 16:16:46
-- @Last Modified by:   baidwwy
-- @Last Modified time: 2023-05-13 16:28:26

local 数据库处理 = class()


function 数据库处理:初始化()
 sqlite3 = require("sqlite3类")(lfs.currentdir()..[[\]]..'aabbcc.db',1551337333)
end

function 数据库处理:访问交易中心物品库(数据)
 local  q= sqlite3:执行SQL(string.format("select * from %s ","交易中心"))
 local tt = q:取数量()
 local 统计数据={}
 for i=1,tt do
     table.insert(统计数据,q:取数据())
  end
   local 提取数据={}
  for n=1,#统计数据 do
    if 统计数据[n].分类==数据 then
      table.insert(提取数据,统计数据[n])
    end
  end
  return 提取数据
end
function 数据库处理:获取合成列表(数据)
 local  q= sqlite3:执行SQL(string.format("select * from %s ","合成列表"))
 local tt = q:取数量()
 local 统计数据={}
 for i=1,tt do
     table.insert(统计数据,q:取数据())
  end
  return 统计数据
end
function 数据库处理:获取成就列表(数据)
 local  q= sqlite3:执行SQL(string.format("select * from %s ","成就列表"))
 local tt = q:取数量()
 local 统计数据={}
 for i=1,tt do
     table.insert(统计数据,q:取数据())
  end
  return 统计数据
end
function 数据库处理:获取密码箱奖励()
 local  q= sqlite3:执行SQL(string.format("select * from %s ","密码箱"))
 local tt = q:取数量()
 local 统计数据={}
 for i=1,tt do
     table.insert(统计数据,q:取数据())
  end
  return 统计数据
end
function 数据库处理:访问模块列表(数据)
 local  q= sqlite3:执行SQL(string.format("select * from %s ","模块列表"))
 local tt = q:取数量()
 local 统计数据={}
 for i=1,tt do
     table.insert(统计数据,q:取数据())
  end
  return 统计数据
end
function 数据库处理:访问副本列表()
 local  q= sqlite3:执行SQL(string.format("select * from %s ","副本列表"))
 local tt = q:取数量()
 local 统计数据={}
 for i=1,tt do
     table.insert(统计数据,q:取数据())
  end
  return 统计数据
end
function 数据库处理:查询交易中心物品库(mc,fl)
local 名称=mc
local 分类=fl
local  q= sqlite3:执行SQL(string.format("select * from %s where 商品名称='%s'and 分类='%s'","交易中心",名称,分类))
local tt = q:取数据()
return tt
end
function 数据库处理:更新交易中心物品库(mc,fl,jg,hs,zf)
local 名称=mc
local 分类=fl
local 价格=jg
local 涨幅=zf
local 回收价格=hs
if 回收价格<=10 then
回收价格=10
end
if 涨幅<=0 then
  涨幅=0
end
if 价格<=100 then
	价格=100
end
local  qq= sqlite3:执行SQL(string.format("update %s set 商品价格=%d where 商品名称='%s'and 分类='%s'","交易中心",价格,名称,分类))
local  qq= sqlite3:执行SQL(string.format("update %s set 回收价格=%d where 商品名称='%s'and 分类='%s'","交易中心",回收价格,名称,分类))
local  qq= sqlite3:执行SQL(string.format("update %s set 涨幅=%d where 商品名称='%s'and 分类='%s'","交易中心",涨幅,名称,分类))
end
function 数据库处理:查询装备数据(dk)
local 等级=dk
local  q= sqlite3:执行SQL(string.format("select * from %s where  等级='%s'","装备数据",等级))
local tt = q:取数据()
return tt
end
function 数据库处理:查询神兽数据(dk)
local 造型=dk
local  q= sqlite3:执行SQL(string.format("select * from %s where  造型='%s'","神兽资质",造型))
local tt = q:取数据()
return tt
end
function 数据库处理:活动数据库查询(序列)
local  q
local  tt
local 任务
q= sqlite3:执行SQL(string.format("select * from %s where  任务序列='%s'","任务列表",序列))
任务 = q:取数据()
local im = sqlite3:执行SQL(string.format("select * from %s where 编号<11",任务.任务名称))
local 怪物表={}
for n=1,im:取数量() do
    local imm = im:取数据()
    怪物表[#怪物表+1]=imm
end
 return 怪物表
end
function 数据库处理:自动任务数据(名称)
local  q
local  tt
q= sqlite3:执行SQL(string.format("select * from %s where  任务名称='%s'","任务列表",名称))
tt = q:取数据()

 return tt
end
function 数据库处理:获取爆率(序列)
local  q
local  tt
q= sqlite3:执行SQL(string.format("select * from %s where  任务序列='%s'","任务列表",序列))
tt = q:取数据()

 return tt
end
function 数据库处理:查询商城(dk,数据表)
local 分组=dk
local im = sqlite3:执行SQL(string.format("select * from %s where 商品组='%s'",数据表,分组))
local 物品表={}
--print(im:取数量())
for n=1,im:取数量() do
    local imm = im:取数据()
    local 新编号=#物品表+1
    物品表[新编号]={}
    if imm.其他~=nil then
      local b=table.loadstring("do local ret={"..imm.其他.."} return ret end")
      物品表[新编号]=b
    end
    物品表[新编号].名称=imm.名称
    if imm.可叠加=="是" then
    物品表[新编号].可叠加=true
    else
    物品表[新编号].可叠加=false
    end
    if imm.数量~=nil then
    物品表[新编号].数量=imm.数量
    end
    if imm.价格~=nil then
    物品表[新编号].价格=imm.价格+0
    end
end
--table.print(物品表)
return 物品表
end


function 数据库处理:显示(x,y) end


return 数据库处理