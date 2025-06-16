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

function Shape:containsPoint(point)
    local realPoints = self:getRealPoints()
    local x, y = point.x, point.y
    local inside = false

    -- Ray-casting algorithm
    for i = 1, #realPoints do
        local j = i % #realPoints + 1
        local xi, yi = realPoints[i].x, realPoints[i].y
        local xj, yj = realPoints[j].x, realPoints[j].y

        -- Check if the point is on an edge (optional, depending on your use case)
        if (xi == xj and xi == x and y > math.min(yi, yj) and y <= math.max(yi, yj)) or
           (yi == yj and yi == y and x > math.min(xi, xj) and x <= math.max(xi, xj)) then
            return true
        end

        -- Check if the ray intersects with the edge
        if yi > yj then
            xi, xj = xj, xi
            yi, yj = yj, yi
        end

        if y > yi and y <= yj then
            local slope = (xj - xi) / (yj - yi)
            if x <= xi + slope * (y - yi) then
                inside = not inside
            end
        end
    end

    return inside
end

function Shape:getArea()
    local sum = 0
    for i = 1, #self.points do
        local j = i + 1
        if j > #self.points then j = 1 end

        sum = sum + self.points[i].x * self.points[j].y - self.points[j].x * self.points[i].y
    end

    return math.abs(sum) / 2
end

return Shape