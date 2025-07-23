local Object = require('Object.Object')

Bbox = setmetatable({}, { __index = Object })
Bbox.__index = Bbox
function Bbox:new()
    local obj = Object.new(self, math.huge, -math.huge)

    obj.pointB = Vector:new(-math.huge, math.huge)

    return obj
end

local function contain(points)
    local pos = Vector:new(math.huge, -math.huge)
    local pointB = Vector:new(-math.huge, math.huge)
    if #points < 1 then
        return
    end
    for _, point in ipairs(points) do
        if point.x < pos.x then
            pos.x = point.x
        end
        if point.y > pos.y then
            pos.y = point.y
        end
        if point.x > pointB.x then
            pointB.x = point.x
        end
        if point.y < pointB.y then
            pointB.y = point.y
        end
    end
    return pos, pointB
end

function Bbox:updatePoints(points)
    self.pos, self.pointB = contain(points)
end

--function Bbox:update(delta)
--end

function Bbox:draw()
    if not DebugVI.showBoundingBox then return end
    love.graphics.setColor(1, 0, 0)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.pos.x, self.pos.y, self.pointB.x - self.pos.x, self.pointB.y - self.pos.y)
end

function Bbox:intersects(other)
    if self.pos.x > other.pointB.x or other.pos.x > self.pointB.x then
        return false
    end
    if self.pointB.y > other.pos.y or other.pointB.y > self.pos.y then
        return false
    end

    return true
end

return Bbox