local Object = require('Object.Object')

Shape = setmetatable({}, { __index = Object })
Shape.__index = Shape
function Shape:new(a, b)
    local obj = Object.new(self, a, b)
    --reletive to pos
    obj.points = {}
    --relative to pos
    obj.center = Vector:new(a,b)
    return obj
end

function Shape:addPoint(x, y)
    table.insert(self.points, Vector:new(x, y))
    self:updateCenter()
end

function Shape:updateCenter()
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

function Shape:draw()
--    Object.draw(self)
    love.graphics.setColor({1,0,0})
    love.graphics.circle("fill", self.pos.x + self.center.x, self.pos.y + self.center.y, 10)

    if #self.points < 3 then
        return
    end

    love.graphics.setColor(0.7, 0.7, 0.7)
    local points = {}
    for _, selfp in ipairs(self.points) do
        local point = selfp:rotate(self.rot)
        table.insert(points, point.x + self.pos.x)
        table.insert(points, point.y + self.pos.y)
    end
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", points)
end

function Shape:getRealPoints()
    local points = {}
    for _, selfp in ipairs(self.points) do
        local point = selfp:rotate(self.rot)
        table.insert(points, Vector:new(point.x + self.pos.x, point.y + self.pos.y))
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