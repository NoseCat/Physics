local Object = require('Object.Object')

Shape = setmetatable({}, { __index = Object })
Shape.__index = Shape
function Shape:new(a, b)
    local obj = Object.new(self, a, b)

    --relative to pos
    obj.center = Vector:new(a,b)
    --reletive to pos
    obj.points = {}

    return obj
end

function Shape:addPoint(x, y)
    table.insert(self.points, Vector:new(x, y))
    self:updateConstants()
end

function Shape:draw()
    Object.draw(self)
    love.graphics.setColor({1,0,0})
    love.graphics.circle("fill", self.pos.x + self.center.x, self.pos.y + self.center.y, 10)

    if #self.points < 3 then
        return
    end

    love.graphics.setColor(0.7, 0.7, 0.7)
    local realPoints = self:getRealPoints()
    local points = {}
    for _, point in ipairs(realPoints) do
        table.insert(points, point.x)
        table.insert(points, point.y)
    end
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", points)
end

function Shape:update(delta)
   Object.update(self, delta)
end

function Shape:updateConstants()
    if #self.points == 0 then
        return
    end
    if #self.points == 1 then
        self.center = self.points[1]
        return
    end
    if #self.points == 2 then
        self.center = (self.points[1] + self.points[2])/2
        return
    end

    local sumPoints = Vector:new(0,0)
    for _, point in ipairs(self.points) do
        sumPoints = sumPoints + point
    end
    self.center = sumPoints / #self.points
end

function Shape:getRealPoints()
    local rotPoints = self:getRotatedPoints()
    local points = {}
    for _, point in ipairs(rotPoints) do
        table.insert(points, point + self.pos)
    end
    return points
end

function Shape:getRotatedPoints()
    local points = {}
    for _, point in ipairs(self.points) do
        table.insert(points, point:rotateAround(self.center, self.rot))
    end
    return points
end

function Shape:project(axis)
    local realPoints = self:getRealPoints()
    axis = axis:normalized()

    local min = math.huge
    local max = -math.huge
    for _, point in ipairs(realPoints) do
        local proj = point:dot(axis)
        if proj < min then
            min = proj
        end
        if proj > max then
            max = proj
        end
    end
    return min, max, axis * min, axis * max, axis * min - axis * max 
end

return Shape