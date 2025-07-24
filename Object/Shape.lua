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
    local points = self:getRealPoints()
    local isInside = false

    for i = 1, #points do
        local j = i % #points + 1
        local v1 = points[i]
        local v2 = points[j]

        -- Skip horizontal edges
        if v1.y == v2.y then goto continue end

        local minY = math.min(v1.y, v2.y)
        local maxY = math.max(v1.y, v2.y)

        -- Check if point's y is strictly above the edge's minY and at/below maxY
        if point.y > minY and point.y <= maxY then
            local edge = v2 - v1
            local t = (point.y - v1.y) / edge.y
            local intersection = v1 + edge * t

            -- Check if point is left of intersection (ray to the right)
            if point.x <= intersection.x then
                isInside = not isInside
            end
        end
        ::continue::
    end

    return isInside
end

function Shape:getBeamIntersection(beamOrigin, beamDirection)
    local realPoints = self:getRealPoints()
    local closestIntersection = nil
    local closestDistance = math.huge
    beamDirection = beamDirection:normalized()

    -- Check each edge of the shape
    for i = 1, #realPoints do
        local j = i % #realPoints + 1
        local edgeStart = realPoints[i]
        local edgeEnd = realPoints[j]

        local intersection = Vector.SegmentIntersect(
            beamOrigin, beamOrigin + beamDirection * 10000, -- Long ray in beam direction
            edgeStart, edgeEnd
        )

        if intersection then
            local distance = (intersection - beamOrigin):len2() -- Use squared distance for comparison

            -- Check if the intersection is in the same direction as the beam
            if distance < closestDistance then
                closestIntersection = intersection
                closestDistance = distance
            end
        end
    end

    return closestIntersection
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