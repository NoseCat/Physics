require('Vector')
require('Shape')

Simplex = {}
Simplex.__index = Simplex
function Simplex:new()
    local newObj = setmetatable({}, self)
    newObj.points = {}
    return newObj
end

function Simplex:add(point)
    table.insert(self.points, point)
end

function Simplex:CalculateDirection()
    local a = self.points[#self.points]
    local ao = a * -1
    if #self.points == 3 then
        local b = self.points[2]
        local c = self.points[1]

        local ab = b - a
        local ac = c - a

        local abPerp = Vector:new(ab.y, -ab.x)
        if abPerp:dot(c) >= 0 then
            abPerp = abPerp * -1
        end

        if abPerp:dot(ao) > 0 then
            table.remove(self.points, 1)
            return abPerp
        end

        local acPerp = Vector:new(ac.y, -ac.x)
        if acPerp:dot(b) >= 0 then
            acPerp = acPerp * -1
        end

        if acPerp:dot(ao) > 0 then
            table.remove(self.points, 2)
            return acPerp
        end

        return nil
    end

    local b = self.points[1]
    local ab = b - a
    local abPerp = Vector:new(ab.y, -ab.x)

    if abPerp:dot(ao) <= 0 then
        abPerp = abPerp * -1
    end

    return abPerp;
end

-- function CalculateCollisionData(simplex)
--     local collisionPoint = nil
--     local depth = math.huge
--     local zero = Vector:new(0,0)
--     for _, pointA in ipairs(simplex.points) do
--         for _, pointB in ipairs(simplex.points) do
--             local p = zero:project(pointA, pointB)
--             if p:len() < depth then
--                 collisionPoint = p
--                 depth = p:len()
--             end
--         end
--     end

--     return collisionPoint, depth
-- end

function GJKCheckCollision(ShapeA, ShapeB)
    local simplex = Simplex:new()
    local direction = Vector:new(0, 1)

    local initialSupportPoint = GJKsupport(ShapeA, ShapeB, direction)
    simplex:add(initialSupportPoint)
    direction = direction * -1

    while direction do
        local supportPoint = GJKsupport(ShapeA, ShapeB, direction)

        if supportPoint:dot(direction) <= 0 then
            -- No intersection
            return false, nil, nil
        end

        simplex:add(supportPoint)
        direction = simplex:CalculateDirection()
    end
    -- intersection detected
    return true, CalculateCollisionDataEPA(ShapeA, ShapeB, simplex)
end

EPAiterationLimit = 100
EPAtolerance = 0.00001
function CalculateCollisionDataEPA(ShapeA, ShapeB, simplex)
    print("\n")
    for _, value in ipairs(simplex.points) do
        print(value.x .. " " .. value.y .. "  ")
    end
    if #simplex.points < 3 then
        return nil, nil
    end
    for i = 1, EPAiterationLimit, 1 do
        local Edge = EPAfindClosestEdge(simplex)
        local p = GJKsupport(ShapeA, ShapeB, Edge.normal)
        local d = p:dot(Edge.normal)
        if d - Edge.distance < EPAtolerance then
            return Edge.normal, d
        else
            table.insert(simplex, Edge.index, p)
        end
    end
    return nil, nil
end

function EPAfindClosestEdge(simplex)
    local closestDistance = math.huge
    local closestNormal = Vector:new(0, 0)
    local closestIndex = 0
    local closestPoint1, closestPoint2

    for i = 1, #simplex.points do
        local j = i + 1
        if j > #simplex.points then j = 1 end

        local point1 = simplex.points[i]
        local point2 = simplex.points[j]

        local edge = point2 - point1
        local normal = Vector:new(-edge.y, edge.x):normalized()
        local distance = normal:dot(point1)

        if distance < closestDistance then
            closestDistance = distance
            closestNormal = normal
            closestIndex = j
            closestPoint1, closestPoint2 = point1, point2
        end
    end

    return {
        normal = closestNormal,
        distance = closestDistance,
        index = closestIndex,
        point1 = closestPoint1,
        point2 = closestPoint2
    }
end

function MinkowskyDif(ShapeA, ShapeB)
    local shapeARealPoints = ShapeA:getRealPoints()
    local shapeBRealPoints = ShapeB:getRealPoints()

    local dif = {}
    for _, pointA in ipairs(shapeARealPoints) do
        for _, pointB in ipairs(shapeBRealPoints) do
            table.insert(dif, pointA - pointB)
        end
    end
    return dif
end

function FarthestPointInDir(shape, dir)
    local points = shape:getRealPoints()

    local farDist = -math.huge
    local farPoint = Vector:new(0, 0)
    for _, point in ipairs(points) do
        local distInDir = point:dot(dir)
        if distInDir > farDist then
            farPoint = point
            farDist = distInDir
        end
    end
    return farPoint
end

function GJKsupport(shapeA, shapeB, dir)
    local aFar = FarthestPointInDir(shapeA, dir)
    local bFar = FarthestPointInDir(shapeB, dir * -1)
    return aFar - bFar
end

return Shape
