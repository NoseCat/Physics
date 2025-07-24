local PhysicsObject = require('Object.PhysicsObject.PhysicsObject')

local StaticBody = setmetatable({}, { __index = PhysicsObject })
StaticBody.__index = StaticBody
function StaticBody:new(a, b)

    local obj = PhysicsObject.new(self, a, b)

    --obj.inertia = 0

    return obj
end

function StaticBody:physicsUpdate(delta, iterations)
    PhysicsObject.physicsUpdate(self, delta, iterations)
    delta = delta / iterations
end

function StaticBody:update(delta)
    return
end

function StaticBody:applyForce(force)
    return
end

function StaticBody:applyTorque(torque)
    return
end

function StaticBody:applyForceAtPoint(force, point)
    return
end

function StaticBody:unCollide(dir, collision, otherShape)
    return
end

function StaticBody:getMass()
    return math.huge
end

function StaticBody:getInertia()
    return math.huge
end

function StaticBody:getVel()
    return Vector:new(0,0)
end

function StaticBody:getRotVel()
    return 0
end

return StaticBody