local PhysicsObject = require('Object.PhysicsObject.PhysicsObject')

local StaticBody = setmetatable({}, { __index = PhysicsObject })
StaticBody.__index = StaticBody
function StaticBody:new(a, b)

    local obj = PhysicsObject.new(self, a, b)

    --obj.inertia = 0

    return obj
end

function StaticBody:update(delta)
    PhysicsObject.update(self, delta)
end

function StaticBody:updateConstants() --!!!!
    Shape.updateConstants(self)
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

function StaticBody:unCollide(dir)
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