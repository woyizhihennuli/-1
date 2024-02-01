--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2020-09-22 02:10:02
--======================================================================--
local ChatCtrl = class()

function ChatCtrl:初始化( ... )
	self.wordMinTime = 0
	self.wordMaxTime = 0

	self.sysBroadMinTime = 0
	self.sysBroadMaxTime = 0

	self.state_wordInited = false
	self.state_sysInited = false

	self.timeCnt_word = 0
	self.timeCnt_sys = 0

	self.chat_target_word = -1
	self.chat_target_sys = -1
end

function ChatCtrl:initWordChatTime(cfgArr)
	self.wordMinTime = cfgArr[1]
	self.wordMaxTime = cfgArr[2]
	self.state_wordInited = true
	self.chat_target_word = 0
end

function ChatCtrl:initSysChatTime(cfgArr)
	self.sysBroadMinTime = cfgArr[1]
	self.sysBroadMaxTime = cfgArr[2]
	self.state_sysInited = true
	self.chat_target_sys = 0
end

function ChatCtrl:timeLoop()
	self.timeCnt_sys = self.timeCnt_sys+1
	self.timeCnt_word = self.timeCnt_word+1
	if self.chat_target_sys == 0 then
		self.chat_target_sys = math.random(self.sysBroadMinTime,self.sysBroadMaxTime)
	end
	if self.chat_target_word == 0 then
		self.chat_target_word = math.random(self.wordMinTime,self.wordMaxTime)
	end
	self:checkTime()
end

function ChatCtrl:checkTime()
	if self.chat_target_word == self.timeCnt_word then
		self:sendWordChat()
		self.chat_target_word = 0
		self.timeCnt_word = 0
	end
	if self.chat_target_sys == self.timeCnt_sys then
		self:sendSysChat()
		self.chat_target_sys = 0
		self.timeCnt_sys = 0
	end
end

function ChatCtrl:sendWordChat()
	local nameArr = ChatDb:getRandomName(1)
	local str = ChatDb:getWordChatBase()
	local word = ChatDb:getRandomWordChat()
	local ctx = word
	for i=1,#nameArr do
	   广播消息({内容="["..nameArr[i].."]"..ctx,频道="sj"})
	end
end

function ChatCtrl:sendSysChat()
	local nameArr = ChatDb:getRandomName(math.random(0,10))
	local item = ChatDb:getRandomItemName()
	local str = ChatDb:getRandomSystemChat()
	local ctx = string.gsub(str, "ctx", item)
	for i=1,#nameArr do
		local t_ctx = string.gsub((ctx.." "), "name", nameArr[i])
		广播消息({内容=t_ctx,频道="xt"})
	end
end

return ChatCtrl