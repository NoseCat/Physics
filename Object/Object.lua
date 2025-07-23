require('Math.Vector')
local OBJECTMANAGER = require('Object.Manager')
local OM = OBJECTMANAGER:getInstance()
OBJECTMANAGER = nil
DebugVI = require('Debug.VisualInfo')

Object = {}
Object.__index = Object
function Object:new(a,b)
    local newObj = setmetatable({}, self)
    newObj.live = true

    newObj.pos = Vector:new(a,b)

    table.insert(OM.objs, newObj)

    return newObj
end

function Object:update(delta)
--    print("updating empty object")
--    self:print()
end

function Object:draw()
    if not DebugVI.showObjectPos then return end
    love.graphics.setColor({1,1,0})
    love.graphics.circle("fill", self.pos.x, self.pos.y, 5)
end

function Object:kill()
    --self = nil
    self.live = false
end

function Object:print()
    print("normal object")
end

return Object