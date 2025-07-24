--to include:
-- local PHYSICSMANAGER = require('Object.PhysicsManager')
-- local PM = PHYSICSMANAGER:getInstance()
-- PHYSICSMANAGER = nil

FreeFallAcceleration = 9.8 * 20 -- * 20 so it looks better
Drag = 10
RotDrag = 0.5

local PhysicsManager = {}
PhysicsManager.__index = PhysicsManager
local instance = nil

function PhysicsManager:getInstance()
    if instance then
        return instance
    end

    local sTone = setmetatable({}, PhysicsManager)
    sTone.objs = {}
    --sTone.msgs = {}
    instance = sTone

    return instance
end

--TODO add margin to bounce
function PhysicsManager:iterate(delta, iterations)
    local ResolvedCollisions = {}
    for i = 1, iterations, 1 do
        for _, obj in ipairs(self.objs) do
            obj:physicsUpdate(delta, iterations)
        end

        local collisions = {}
        for idx1 = 1, #self.objs do
            for idx2 = idx1 + 1, #self.objs do
                local obj1 = self.objs[idx1]
                local obj2 = self.objs[idx2]
                local collision = Collision.Collide(obj1, obj2)
                if collision.isCollided then
                    table.insert(collisions, collision)
                end
                if collision.isCollided and i == 1 then --wierd
                    table.insert(ResolvedCollisions, collision)
                end
            end
        end
        table.sort(collisions, function (a, b) return a.mtv:len2() > b.mtv:len2() end)
        for _, collision in ipairs(collisions) do
            collision:resolve()
        end
    end

    for _, obj in ipairs(self.objs) do
        obj:physicsUpdateFinish(delta) -- previous frame done

        obj:applyForce(Vector:new(0, 1) * obj:getMass() * FreeFallAcceleration) --gravity
        obj:applyForce(obj:getVel() * -Drag * delta) --linear drag
        obj:applyTorque(obj:getRotVel() * -RotDrag * delta) --angular drag
    end

    for _, collision in ipairs(ResolvedCollisions) do
        collision:applyBounce(delta)
        collision:applyFriction(delta)
    end
end

return PhysicsManager
