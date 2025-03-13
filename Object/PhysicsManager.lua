--to include:
-- local PHYSICSMANAGER = require('Object.PhysicsManager')
-- local PM = PHYSICSMANAGER:getInstance()
-- PHYSICSMANAGER = nil

local PhysicsManager = {}
PhysicsManager.__index = PhysicsManager
local instance = nil

function PhysicsManager:getInstance()
    if instance then
        return instance
    end

    local sTone = setmetatable({}, PhysicsManager)
    sTone.objs = {}
    sTone.msgs = {}
    instance = sTone

    return instance
end

function PhysicsManager:iterate()
    for _, obj1 in ipairs(self.objs) do
    for _, obj2 in ipairs(self.objs) do
        obj1:collide(obj2)
    end
    end
end

return PhysicsManager