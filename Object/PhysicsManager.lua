--to include:
-- local PHYSICSMANAGER = require('Object.PhysicsManager')
-- local PM = PHYSICSMANAGER:getInstance()
-- PHYSICSMANAGER = nil

FreeFallAcceleration = 9.8 * 10 * 2
Drag = 5
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
        for _, obj1 in ipairs(self.objs) do
            for _, obj2 in ipairs(self.objs) do
                local collision = obj1:collide(obj2)
                if collision.isCollided and i == 1 then
                    table.insert(collisions, collision)
                end
                collision:resolve()
            end
        end
    end

    for _, obj in ipairs(self.objs) do
        obj:applyForce(Vector:new(0, 1) * obj.mass * FreeFallAcceleration)
        obj:applyForce(obj.vel * -Drag * delta)
        obj:applyTorque(obj.rotVel * delta * -RotDrag)
    end

    for _, collision in ipairs(collisions) do
        local mtv = collision.mtv:normalized()
        local relVel = collision.shapeB.vel - collision.shapeA.vel
        local velAlongNormal = relVel:dot(mtv)
        if velAlongNormal > 0 then
            return
        end
        --add friction
        --bounce can be calculated in different ways based on options of objects
        local bounce = math.min(collision.shapeA.bounce, collision.shapeB.bounce)
        local impulse = (1 + bounce) * velAlongNormal * collision.shapeA.mass * collision.shapeB.mass
        impulse = impulse / (collision.shapeA.mass + collision.shapeB.mass)

        collision.shapeA:applyForceAtPoint(mtv * (impulse/delta), collision.point)
        collision.shapeB:applyForceAtPoint(mtv * -(impulse/delta), collision.point)
    end
end

return PhysicsManager
