local Shape = require('Object.Shape')
local Bbox = require('Interaction.BoundingBox')
require('Math.Vector')
local PHYSICSMANAGER = require('Object.PhysicsManager')
local PM = PHYSICSMANAGER:getInstance()
PHYSICSMANAGER = nil

local PhysicsObject = setmetatable({}, { __index = Shape })
PhysicsObject.__index = PhysicsObject
function PhysicsObject:new(a, b)

    local obj = Shape.new(self, a, b)

    obj.bounce = 0.5
    obj.friction = 0.3

    obj.static = false --!!!!
    obj.bbox = Bbox:new()

    table.insert(PM.objs, obj)
    return obj
end

function PhysicsObject:update(delta) -- inherit
    self.bbox:updatePoints(self:getRealPoints())
end

function PhysicsObject:updateConstants() --!!!!
    Shape.updateConstants(self)
end

function PhysicsObject:applyForce(force)
    print("ApplyForce method not realised")
end

function PhysicsObject:applyTorque(torque)
    print("ApplyTorque method not realised")
end

function PhysicsObject:applyForceAtPoint(force, point)
    print("ApplyForceAtPoint method not realised")
end

function PhysicsObject:unCollide(dir)
    print("unCollide method not realised")
end

function PhysicsObject:getMass()
    print("getMass method not realised")
end

function PhysicsObject:getInertia()
    print("getInertia method not realised")
end

function PhysicsObject:getVel()
    print("getVel method not realised")
end

function PhysicsObject:getRotVel()
    print("getRotVel method not realised")
end

function PhysicsObject:print()
    print("PhysicsObject")
end

return PhysicsObject