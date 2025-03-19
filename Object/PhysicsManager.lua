--to include:
-- local PHYSICSMANAGER = require('Object.PhysicsManager')
-- local PM = PHYSICSMANAGER:getInstance()
-- PHYSICSMANAGER = nil

FreeFallAcceleration = 9.8 * 10 * 2
Drag = 50
RotDrag = 10000

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

--TODO add margin to bounce
function PhysicsManager:iterate(delta, iterations)
    local collisions = {}
    for i = 1, iterations, 1 do
        for idx1 = 1, #self.objs do
            for idx2 = idx1 + 1, #self.objs do
                local obj1 = self.objs[idx1]
                local obj2 = self.objs[idx2]
                local collision = obj1:collide(obj2)
                if collision.isCollided and i == 1 then
                    table.insert(collisions, collision)
                end
                collision:resolve()
            end
        end
    end

    for _, obj in ipairs(self.objs) do
        obj:applyForce(Vector:new(0, 1) * obj.mass * FreeFallAcceleration) --gravity
        obj:applyForce(obj.vel * -Drag * delta) --linear drag
        obj:applyTorque(obj.rotVel * delta * -RotDrag) --angular drag
    end

    for _, collision in ipairs(collisions) do
        collision:applyBounce(delta)
        --collision:applyRotBounce(delta)
        collision:applyFriction(delta)
    end
end

return PhysicsManager
