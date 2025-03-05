local Object = require('Object.Object')

Shape = setmetatable({}, { __index = Object })
Shape.__index = Shape
function Shape:new(a, b)
    local obj = Object.new(self, a, b)
    obj.points = {}

    return obj
end

function Shape:addPoint(x, y)
    table.insert(self.points, Vector:new(x, y))
end

function Shape:draw()
    Object.draw(self)

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
