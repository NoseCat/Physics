local Object = require('Object.Object')

Shape = setmetatable({}, { __index = Object })
Shape.__index = Shape
function Shape:new(a, b)
    local obj = Object.new(self, a, b)

    obj.rot = 0

    --reletive to pos
    obj.points = {}

    return obj
end

function Shape:draw()
    Object.draw(self)
    if DebugVI.showShapeCenter then
        love.graphics.setColor(1,0,0)
        local center = self:getRealCenter()
        love.graphics.circle("fill", center.x, center.y, 10)
    end

    if #self.points < 3 then
        return
    end

    if DebugVI.showShapeEdges then
        love.graphics.setColor(0.7, 0.7, 0.7)
        local realPoints = self:getRealPoints()
        local points = {}
        for index, point in ipairs(realPoints) do
            if DebugVI.showShapePointOrder then
                love.graphics.print(index, point.x, point.y)
            end
            table.insert(points, point.x)
            table.insert(points, point.y)
        end
        love.graphics.setLineWidth(3)
        love.graphics.polygon("line", points)
    end

    if not DebugVI.showShapeTriagnulation then return end

    local triangles = self:triangulate()
    for _, triangle in ipairs(triangles) do
        love.graphics.setColor(0.7, 0, 0)
        love.graphics.setLineWidth(1)
        local tpoints = {}
        for _, point in ipairs(triangle) do
            table.insert(tpoints, point.x)
            table.insert(tpoints, point.y)
        end
        love.graphics.polygon("line", tpoints)
    end
end

function Shape:update(delta)
    Object.update(self, delta)
end

function Shape:addPoint(x, y)
    table.insert(self.points, Vector:new(x, y))
    self:updateConstants()
end

--is called when we add points. Useful to calculate shape dependent behaviour once
function Shape:updateConstants()
   return
end

function Shape:getRealPoints()
    local points = {}
    for _, point in ipairs(self.points) do
        table.insert(points, point:rotateAround(self:getRealCenter() - self.pos, self.rot) + self.pos)
    end
    return points
end

function Shape:getRealCenter()
    local center = Vector:new(0, 0)
    for _, point in ipairs(self.points) do
        center = center + point
    end
    return center / #self.points + self.pos
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

local function findIntersections(points)
    if #points <= 3 then
        return {}
    end
    local intersections = {}
    for i = 1, #points, 1 do
        local iNext = (i % #points) + 1
        for j = i + 2, #points, 1 do
            local jNext = (j % #points) + 1

            if j == iNext or jNext == i then
                goto continue
            end
            local intersect = Vector.SegmentIntersect(points[i], points[iNext], points[j], points[jNext])
            if intersect then
                table.insert(intersections, intersect)
            end
            ::continue::
        end
    end
    return intersections
end

function Shape:triangulate()
    local Rpoints = self:getRealPoints()
    local points = {}
    for _, point in ipairs(Rpoints) do
        table.insert(points, point.x)
        table.insert(points, point.y)
    end
    if love.math.isConvex(points) or #findIntersections(Rpoints) > 0 then
        return {Rpoints}
    end
    --return love.math.triangulate(points)
    local trianglesRaw = love.math.triangulate(points)
    local triangles = {}
    for _, triangle in ipairs(trianglesRaw) do
        local point1 = Vector:new(triangle[1], triangle[2])
        local point2 = Vector:new(triangle[3], triangle[4])
        local point3 = Vector:new(triangle[5], triangle[6])
        table.insert(triangles, {point1, point2, point3})
    end
    return triangles
end

return Shape