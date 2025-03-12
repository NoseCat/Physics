require('Math.Vector')
local OBJECTMANAGER = require('Object.Manager')
local OM = OBJECTMANAGER:getInstance()
OBJECTMANAGER = nil

Object = {}
Object.__index = Object
function Object:new(a,b)
    local newObj = setmetatable({}, self)
    newObj.live = true

    newObj.pos = Vector:new(a,b)
    newObj.vel = Vector:new(0,0)
    newObj.accel  = Vector:new(0,0)

    newObj.rot = 0
    --newObj.rotV = 0
    --newObj.rotA = 0

    table.insert(OM.objs, newObj)

    return newObj
end

-- function object:setVelocity(x,y)
--     self.vel.x = x
--     self.vel.y = y
-- end

-- function object:setAcceleration(x,y)
--     self.vel.x = x
--     self.vel.y = y
-- end

function Object:update(delta)
    self.vel = self.vel + self.accel * delta
    self.pos = self.pos + self.vel * delta
end

function Object:draw()
    love.graphics.setColor({1,1,0})
    love.graphics.circle("fill", self.pos.x, self.pos.y, 5)

    love.graphics.setColor({1,0,0}) --standart color
end

function Object:kill()
    --self = nil
    self.live = false
end

return Object