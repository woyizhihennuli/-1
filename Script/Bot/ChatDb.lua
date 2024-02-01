--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2022-11-28 14:53:37
--======================================================================--
local ChatDb = class() -- 喊话专用

function ChatDb:初始化( ... )
	self.wordChatBase = ""

	self.wordChatList = {}

	self.systemChatList = {}

	self.itemList = {}

	self.nameList = {}
    math.randomseed(tostring(os.clock()):reverse():sub(1, 7))
end


function ChatDb:initWordChatList(arrSrc)
	local count = 0
    for i = 1, #arrSrc do
        count = count + 1
        self.wordChatList[count] = arrSrc[i]
    end
    __S服务:输出("刻晴假人:添加了[" .. count .. "]条世界喊话内容")
end

function ChatDb:initSystemList(arr)
	local count = 0
    for i = 1, #arr do
        count = count + 1
        self.systemChatList[count] = arr[i]
    end
    __S服务:输出("刻晴假人:添加了[" .. count .. "]条系统喊话内容")
end

function ChatDb:setWordChatBase(chatBase)
	self.wordChatBase = chatBase
end

function ChatDb:getWordChatBase()
	return self.wordChatBase .. " "
end

function ChatDb:initNameList(arrSrc)
	local count = 0
    for i = 1, #arrSrc do
        count = count + 1
        self.nameList[count] = arrSrc[i]
    end
    __S服务:输出("刻晴假人:添加了[" .. count .. "]条假人名称")
end

function ChatDb:initItemList(arrSrc)
	local count = 0

    for i = 1, #arrSrc do
        count = count + 1
        self.itemList[count] = arrSrc[i]
    end
   __S服务:输出("刻晴假人:添加了[" .. count .. "]个奖励道具")
end

function ChatDb:getRandomWordChat()
	local idx = math.random(1,#self.wordChatList)
	return self.wordChatList[idx].. " "
end

function ChatDb:getRandomSystemChat()
	local idx = math.random(1,#self.systemChatList)
	return self.systemChatList[idx] .. " "
end

function ChatDb:getRandomItemName()
	local idx = math.random(1,#self.itemList)
	return self.itemList[idx] .." "
end

function ChatDb:getRandomName(cnt)
    local count = 0
	if cnt >= 5 then
		count = 5
    else
        count = 1
    end
	local arr = {}
	self.nameList = self:shuffle(self.nameList)
	for i = 1,count do
	    arr[i] = self.nameList[i]
	end
	return arr
end

function ChatDb:shuffle(t)
    if type(t)~="table" then
        return
    end
    local tab={}
    local index=1

    while #t~=0 do
        local n=math.random(0,#t)
        if t[n]~=nil then
            tab[index]=t[n]
            table.remove(t,n)
            index=index+1
        end
    end
    return tab
end

return ChatDb