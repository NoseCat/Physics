local Shape = require('Object.Shape')
require('Math.Vector')
local PHYSICSMANAGER = require('Object.PhysicsManager')
local PM = PHYSICSMANAGER:getInstance()
PHYSICSMANAGER = nil

local PhysicsBody = setmetatable({}, { __index = Shape })
PhysicsBody.__index = PhysicsBody
function PhysicsBody:new(a, b, m)

    local obj = Shape.new(self, a, b)

    obj.static = false

    obj.mass = m
    obj.force = Vector:new(0,0)
    obj.inertia = 0
    obj.torque = 0

    obj.bounce = 0.5
    obj.friction = 0.5

    table.insert(PM.objs, obj)
    return obj
end

function PhysicsBody:update(delta)
    self.accel = self.force / self.mass
    self.vel = self.vel + self.accel * delta
    self.pos = self.pos + self.vel * delta

    self.rotAccel = self.torque / self.inertia
    self.rotVel = self.rotVel + self.rotAccel * delta
    self.rot = self.rot + self.rotVel * delta

    self.force = Vector:new(0, 0)
    self.torque = 0
end

function PhysicsBody:updateConstants()
    Shape.updateConstants(self)
    -- Approximate polygon as a circle
    local maxDistance = 0
    for _, point in ipairs(self.points) do
        local distance = (point - self.center):len()
        if distance > maxDistance then
            maxDistance = distance
        end
    end

    local k = 0.5
    L = maxDistance
    self.inertia = k * self.mass * L^2
end

function PhysicsBody:collide(PhysicsBodyB)
    return Collide(self, PhysicsBodyB)
end

function PhysicsBody:applyForce(force)
    if self.static then
        return
    end
    self.force = self.force + force
end

function PhysicsBody:applyTorque(torque)
    if self.static then
        return
    end
    self.torque = self.torque + torque
end

function PhysicsBody:applyForceAtPoint(force, point)
    if self.static then
        return
    end
    self:applyForce(force)

    local r = point - (self.pos + self.center)
    local torque = r:cross(force)
    self:applyTorque(torque)
end

return PhysicsBody