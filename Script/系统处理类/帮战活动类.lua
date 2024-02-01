-- @作者: baidwwy
-- @邮箱:  313738139@qq.com
-- @创建时间:   2022-03-01 14:10:16
-- @最后修改来自: baidwwy
-- @Last Modified time: 2023-05-08 13:23:00

local 帮战活动类 = class()
local function 积分排序(a,b) return a.积分>b.积分 end

function 帮战活动类:初始化()
	self.入场开关=false
	self.活动开关=false
	self.入场时间=600
	self.活动时间=1800
	self.入场名单={}
	self.入场帮派={}
	self.当前获胜帮派 = 0
	self.帮派进入限制 = 86400
	if f函数.文件是否存在([[tysj/帮战活动.txt]])==false then
		self.帮派冷却统计 = {}
		写出文件([[tysj/帮战活动.txt]],table.tostring(self.帮派冷却统计))
	else
		self.帮派冷却统计=table.loadstring(读入文件([[tysj/帮战活动.txt]]))
	end
end

function 帮战活动类:活动开启()
	if self.活动开关 or self.入场开关 then
		return "活动已经开启"
	else
		self.入场开关 = true
		self.入场名单={}
		self.入场帮派={}
		self.当前获胜帮派 = 0
		self:入场倒计时()
		发送公告("#S帮派大乱斗活动#G开始进场了,请所有帮派玩家去长安城找到#R帮派竞赛主持人#G进场！#Y10分钟后将无法进场！")
	end
end

function 帮战活动类:入场倒计时()
	local 任务id = "5594_"..os.time()..取随机数(88,99999999)
	任务数据[任务id]={
		id = 任务id,
		起始=os.time(),
    	结束=self.入场时间,
    	类型=5594,
	}
end

function 帮战活动类:开启比赛()
	for k,v in pairs(self.帮派冷却统计) do
		if v<=os.time() then
			v=nil
		end
	end
	self.入场开关 = false
	self.活动开关 = true
	local 任务id = "5595_"..os.time()..取随机数(88,99999999)
	任务数据[任务id]={
		id = 任务id,
		起始=os.time(),
    	结束=self.活动时间,
    	类型=5595,
	}
	发送公告("#S帮派大乱斗活动#G正式开打,#R胜利场数最多得帮派#G将获得本次大乱斗胜利,#Y活动时间持续1小时！")
end

function 帮战活动类:结束比赛(任务id)
	local 任务id=玩家数据[数字id].角色:取任务(5595)
          玩家数据[数字id].角色:取消任务(任务id)


	self.入场开关 = false
	self.活动开关 = false
	任务数据[任务id]=nil
	for n, v in pairs(战斗准备类.战斗盒子) do
		if 战斗准备类.战斗盒子[n].战斗类型==200006 then
			战斗准备类.战斗盒子[n]:结束战斗(0,0,1)
		end
	end
	地图处理类:清除地图玩家(6010,1001,136,22)
	self:奖励结算()
end

function 帮战活动类:奖励结算()
	local 奖励表 = {}
	for k,v in pairs(self.入场帮派) do
		奖励表[#奖励表+1] = {帮派id=k,积分=v.积分}
	end
	table.sort(奖励表,积分排序)
	if #奖励表>0 then
		if 奖励表[1].积分>0 then
			self.当前获胜帮派 = 奖励表[1].帮派id
			发送公告("#S帮派大乱斗活动#G结束了,#G当前获胜帮派是#R"..帮派数据[奖励表[1].帮派id].帮派名称)
			print("当前获胜帮派是"..帮派数据[奖励表[1].帮派id].帮派名称)
			self.帮派冷却统计[self.当前获胜帮派]= os.time() + self.帮派进入限制
			return
		end
	end
    发送公告("#G此次帮派活动没有帮派获得第一")
end

function 帮战活动类:进入比赛场景(id)
	if 玩家数据[id].队伍~=0 then
	    常规提示(id,"只能单人进入")
	    return
	elseif 玩家数据[id].角色.数据.帮派数据==nil or 玩家数据[id].角色.数据.帮派数据.编号==nil then
		常规提示(id,"你还没有帮派呢")
	    return
	elseif not self.入场开关 then
        常规提示(id,"该活动还没有开启呢或者你已经失败了")
	    return
	end
	local 帮派id = 玩家数据[id].角色.数据.帮派数据.编号
	if self.帮派冷却统计[帮派id]~=nil then
	    常规提示(id,"你的帮派在XXX小时内获取过第一了")
	    return
	end
	if self.入场名单[帮派id]==nil then
		self.入场名单[帮派id]={}
	end
	if self.入场名单[帮派id][id]==nil then
		self.入场名单[帮派id][id] = {id=id,参与战斗场次=0,奖励领取=false}
	end
	if self.入场帮派[帮派id] == nil then
		self.入场帮派[帮派id] = {积分=0}
	end
	-- local 临时yx=地图处理类.地图坐标[6010]:取随机点()
	玩家数据[id].角色.数据.当前称谓 = 帮派数据[帮派id].帮派名称.."的成员"
    地图处理类:跳转地图(id,6010,121,19)
    常规提示(id,"#Y/进入帮战地图")
end

function 帮战活动类:进入战斗(进攻id,防守id)
	if not self.活动开关 then
    	常规提示(进攻id,"#Y/当前为帮派竞赛准备时间，无法进行切磋。")
    	return
	end
	战斗准备类:创建玩家战斗(进攻id, 200006, 防守id, 1501)
	if 玩家数据[进攻id].队伍~=0 then
		local 队伍id = 玩家数据[进攻id].队伍
		for n=1,#队伍数据[队伍id].成员数据 do
	        local 队员id=队伍数据[队伍id].成员数据[n]
	       	local 帮派id = 玩家数据[队员id].角色.数据.帮派数据.编号
	       	self.入场名单[帮派id][队员id].参与战斗场次 = self.入场名单[帮派id][队员id].参与战斗场次 + 1
      	end
	else
		local 帮派id = 玩家数据[进攻id].角色.数据.帮派数据.编号
		self.入场名单[帮派id][进攻id].参与战斗场次 = self.入场名单[帮派id][进攻id].参与战斗场次 + 1
	end
	if 玩家数据[防守id].队伍~=0 then
		local 队伍id = 玩家数据[防守id].队伍
		for n=1,#队伍数据[队伍id].成员数据 do
	        local 队员id=队伍数据[队伍id].成员数据[n]
	       	local 帮派id = 玩家数据[队员id].角色.数据.帮派数据.编号
	       	self.入场名单[帮派id][队员id].参与战斗场次 = self.入场名单[帮派id][队员id].参与战斗场次 + 1
      	end
	else
		local 帮派id = 玩家数据[防守id].角色.数据.帮派数据.编号
		self.入场名单[帮派id][防守id].参与战斗场次 = self.入场名单[帮派id][防守id].参与战斗场次 + 1
	end
end

function 帮战活动类:胜利处理(id,失败id)
	-- print(id,失败id)
	local 帮派id = 玩家数据[id].角色.数据.帮派数据.编号
	self.入场帮派[帮派id].积分 = self.入场帮派[帮派id].积分 + 1--
	if 玩家数据[失败id].队伍~=0 then
		local 队伍id = 玩家数据[失败id].队伍
        local 队员id=队伍数据[队伍id].成员数据[1]
        地图处理类:跳转地图(队员id,1001,136,22,true)
        常规提示(id,"你挑战失败了")
    else
    	 地图处理类:跳转地图(失败id,1001,136,22,true)
    	 常规提示(id,"你挑战失败了")
	end
end


function 帮战活动类:领取奖励(id)
	if self.当前获胜帮派~=0 and not self.入场开关 and not self.活动开关 then
		if 玩家数据[id].角色.数据.帮派数据==nil or 玩家数据[id].角色.数据.帮派数据.编号==nil then
			常规提示(id,"你还没有帮派呢")
		    return
		end
		local 帮派id = 玩家数据[id].角色.数据.帮派数据.编号
		if self.入场名单[帮派id]~=nil and self.入场名单[帮派id][id]~=nil then
			if self.入场名单[帮派id][id].参与战斗场次>0 and self.入场名单[帮派id][id].奖励领取==false then
		    self.入场名单[帮派id][id].奖励领取=true
			if 取随机数(1,300)<=1 then
			local 名称="90级制造书"
			玩家数据[id].道具:给予书铁(id,{9,9},"指南书")
			常规提示(id,"#Y/你获得了"..名称)
			广播消息({内容=format("#S(帮战参与奖励)#R/%s#Y完成了帮派对战，人气爆棚获得了#G/%s",玩家数据[id].角色.数据.名称,名称),频道="xt"})
			end
			玩家数据[id].道具:给予书铁(id,{7,8})
			玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,6})
			玩家数据[id].道具:给予道具(id,"元灵晶石",{6,6})
			玩家数据[id].角色:添加银子(1000000,"乌鸡国国王",1)
            常规提示(id,"#Y/你获得了#G70-80级装备书铁#和#G60级灵饰书铁#Y奖励")
			else
				常规提示(id,"你没有对帮派做出贡献,或已经领取过了")
		    	return
			end
		else
			常规提示(id,"你还没有参加过此次活动")
		    return
		end
	else
    	常规提示(id,"#Y/当前活动正在进行中,无法领取奖励")
	end
end

function 帮战活动类:领取奖励1(id)
	if self.当前获胜帮派~=0 and not self.入场开关 and not self.活动开关 then
		if 玩家数据[id].角色.数据.帮派数据==nil or 玩家数据[id].角色.数据.帮派数据.编号==nil then
			常规提示(id,"你还没有帮派呢")
		    return
		end
		local 帮派id = 玩家数据[id].角色.数据.帮派数据.编号
		if  self.入场名单[帮派id]~=nil and self.入场名单[帮派id][id]~=nil then
			if self.入场名单[帮派id][id].参与战斗场次>0 and self.入场名单[帮派id][id].奖励领取==false then
        self.入场名单[帮派id][id].奖励领取=true

		if 取随机数(1,200)<=5 then
		local 名称="90级制造书"
		玩家数据[id].道具:给予书铁(id,{9,9},"指南书")
		常规提示(id,"#Y/你获得了"..名称)
		广播消息({内容=format("#S(帮战胜利奖励)#R/%s#Y完成了帮派对战，人气爆棚获得了#G/%s",玩家数据[id].角色.数据.名称,名称),频道="xt"})
		end
        玩家数据[id].道具:给予书铁(id,{8,8})
        玩家数据[id].道具:给予道具(id,"灵饰指南书",{6,8})
        玩家数据[id].道具:给予道具(id,"元灵晶石",{6,8})
        添加仙玉(5000,玩家数据[id].账号,id,"乌鸡国副本")
        玩家数据[id].角色:添加银子(5000000,"乌鸡国国王",1)
        常规提示(id,"#Y/你获得了胜利帮派的奖励:\n#G80-90级装备书铁#和#G60-80级灵饰书铁#Y奖励\n包括#R5000仙玉")
			else
				常规提示(id,"你没有对帮派做出贡献,或已经领取过了")
		    	return
			end
		else
			常规提示(id,"你还没有参加过此次活动")
		    return
		end
	else
    	常规提示(id,"#Y/当前活动正在进行中,无法领取奖励")
	end
end


function 帮战活动类:更新(dt)

end


function 帮战活动类:显示()

end

return 帮战活动类