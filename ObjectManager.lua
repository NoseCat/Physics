--to include:
-- local OBJECTMANAGER = require('ObjectManager')
-- local OM = OBJECTMANAGER:getInstance()
-- OBJECTMANAGER = nil

local ObjectManager = {}
ObjectManager.__index = ObjectManager

local instance = nil

function ObjectManager:getInstance()
    if instance then
        return instance
    end

    local sTone = setmetatable({}, ObjectManager)
    sTone.objs = {}
    sTone.msgs = {}
    instance = sTone

    return instance
end

function ObjectManager:draw()
    for _, obj in ipairs(self.objs) do
        obj:draw()
    end
end

function ObjectManager:update(delta)
    for index, obj in ipairs(self.objs) do
        if obj.live then
            obj:update(delta)
        else
            table.remove(self.objs, index)
        end
    end
end

return ObjectManager