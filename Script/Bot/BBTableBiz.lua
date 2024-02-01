--======================================================================--
-- @作者: 小九呀
-- @QQ：5268416
-- @创建时间: 2018-03-03 02:34:19
-- @Last Modified time: 2020-09-22 02:09:34
--======================================================================--
local BBTableBiz = class()


function BBTableBiz:初始化(source)
	self.bb = source
	self.refreshTime = os.time()
end

function BBTableBiz:isNew(time)
	if time <= self.refreshTime then
		return false
	end
	return true
end

function BBTableBiz:refresh()
	self.refreshTime = os.time()
end

return BBTableBiz