PhysicsObject = require('Object.PhysicsObject.PhysicsObject')

local DynamicBody = setmetatable({}, { __index = PhysicsObject })
DynamicBody.__index = DynamicBody
function DynamicBody:new(a, b, m)
    local obj = PhysicsObject.new(self, a, b)

    obj.vel = Vector:new(0,0)
    obj.accel  = Vector:new(0,0)

    obj.rotVel = 0
    obj.rotAccel = 0

    obj.mass = m
    obj.force = Vector:new(0,0)
    obj.inertia = 0
    obj.torque = 0

    return obj
end

function DynamicBody:update(delta)
    PhysicsObject.update(self, delta)

    self.accel = self.force / self.mass
    self.vel = self.vel + self.accel * delta
    self.pos = self.pos + self.vel * delta

    self.rotAccel = self.torque / self.inertia
    self.rotVel = self.rotVel + self.rotAccel * delta
    self.rot = self.rot + self.rotVel * delta

    self.force = Vector:new(0, 0)
    self.torque = 0
end

function DynamicBody:updateConstants()
    -- Approximate polygon as a circle
    local maxDistance = 0
    for _, point in ipairs(self.points) do
        local distance = (point - (self:getRealCenter() - self.pos)):len()
        if distance > maxDistance then
            maxDistance = distance
        end
    end

    local k = 0.5
    L = maxDistance
    self.inertia = k * self.mass * L^2
end

function DynamicBody:applyForce(force)
    if self.static then
        return
    end
    self.force = self.force + force
end

function DynamicBody:applyTorque(torque)
    if self.static then
        return
    end
    self.torque = self.torque + torque
end

function DynamicBody:applyForceAtPoint(force, point)
    if self.static then
        return
    end
    self:applyForce(force)

    local r = point - self:getRealCenter()
    local torque = r:cross(force)
    self:applyTorque(torque)
end

function DynamicBody:unCollide(dir)
    self.pos = self.pos + dir
end

function DynamicBody:getMass()
    return self.mass
end

function DynamicBody:getInertia()
    return self.inertia
end

function DynamicBody:getVel()
    return self.vel
end

function DynamicBody:getRotVel()
    return self.rotVel
end

return DynamicBody