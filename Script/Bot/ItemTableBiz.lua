--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2020-09-22 02:10:07
--======================================================================--
local ItemTableBiz = class()


function ItemTableBiz:初始化(source)
	self.item = source
	self.refreshTime = os.time()
end

function ItemTableBiz:isNew(time)
	if time <= self.refreshTime then
		return false
	end
	return true
end

function ItemTableBiz:refresh()
	self.refreshTime = os.time()
end

return ItemTableBiz