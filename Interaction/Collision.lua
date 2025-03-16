require('Math.Vector')
require('Object.Shape')

Collision = {}
Collision.__index = Collision

function Collision:new(shapeA, shapeB)
    local instance = setmetatable({}, Collision)

    instance.isCollided = false
    instance.shapeA = shapeA
    instance.shapeB = shapeB

    instance.point = Vector:new(0,0)
    instance.mtv = Vector:new(0,0)

    return instance
end

function Collide(ShapeA, ShapeB)
    local collision = Collision:new(ShapeA, ShapeB)

    local isCollided, MTV = SATCheckCollision(ShapeA, ShapeB)
    collision.isCollided = isCollided
    local colPoints = GetCollisionPoints(ShapeA, ShapeB)

    if isCollided and MTV then
        local minus = -1
        if MTV:dot((ShapeA.pos + ShapeA.center) - (ShapeB.pos + ShapeB.center)) < 0 then
            minus = 1
        end
        MTV = MTV * minus -- fix MTV
        collision.mtv = MTV

        local sumColPoints = Vector:new(0,0)
        for _, point in ipairs(colPoints) do
            sumColPoints = sumColPoints + point
        end
        if #colPoints > 0 then
            collision.point = sumColPoints / #colPoints
        end
    end
    return collision
end

function Collision:resolve()
    if not self.isCollided then
        return
    end
    local staticA = 0.5
    local staticB = 0.5
    if self.shapeA.static and self.shapeB.static then
        staticA, staticB = 0, 0
    elseif self.shapeA.static then
        staticA, staticB = 0, 1
    elseif self.shapeB.static then
        staticA, staticB = 1, 0
    end
    self.shapeA.pos = self.shapeA.pos - self.mtv * staticA
    self.shapeB.pos = self.shapeB.pos + self.mtv * staticB
end

function GetCollisionPoints(ShapeA, ShapeB)
    local SArealPoints = ShapeA:getRealPoints()
    local SBrealPoints = ShapeB:getRealPoints()
    local points = {}

    for i = 1, #SArealPoints do
        local inext = i + 1
        if inext > #SArealPoints then inext = 1 end
        for j = 1, #SBrealPoints do
            local jnext = j + 1
            if jnext > #SBrealPoints then jnext = 1 end
            local intersection = SegmentIntersect(SArealPoints[i], SArealPoints[inext], SBrealPoints[j], SBrealPoints[jnext])
            if intersection then
                table.insert(points, intersection)
            end
        end
    end
    return points
end

--[[=========================================
        SAT algorithm for collision detection
=============================================]]

function SATCheckCollision(ShapeA, ShapeB)
    --SAT needs to check all normals of both shapes' edges
    local normals = {}
    local function getNormals(points, shapeCenter)
        for i = 1, #points do
            local j = i + 1
            if j > #points then j = 1 end

            local edge = points[i] - points[j]
            local normal = Vector:new(edge.y, -edge.x):normalized()
            table.insert(normals, normal)
        end
    end
    getNormals(ShapeA:getRotatedPoints(), ShapeA.center)
    getNormals(ShapeB:getRotatedPoints(), ShapeB.center)

    local smallestLength = math.huge
    local MTVaxis = Vector:new(0, 0)
    for _, axis in ipairs(normals) do
        local minA, maxA = ShapeA:project(axis)
        local minB, maxB = ShapeB:project(axis)
        --if there is atleast 1 axis with no overlap - shapes dont collide
        if maxA < minB or maxB < minA then
            return false, nil
        end
        --smalest overlap is length of MTV, axis is orientation 
        local len = math.min(maxA, maxB) - math.max(minA, minB)
        if len < smallestLength then
            smallestLength = len
            MTVaxis = axis
        end
    end
    --no axis overlap
    return true, MTVaxis * smallestLength
end


--[[=========================================
        GJK algorithm for collision detection
        with EPA
=============================================]]

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

function GJKsupport(shapeA, shapeB, dir)
    local aFar = FarthestPointInDir(shapeA, dir)
    local bFar = FarthestPointInDir(shapeB, dir * -1)
    return aFar - bFar
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

EPAiterationLimit = 100
EPAtolerance = 0.001
function CalculateCollisionDataEPA(ShapeA, ShapeB, simplex)
    if #simplex.points < 3 then
        return nil, nil
    end
    local Edge
    for i = 1, EPAiterationLimit, 1 do
        Edge = EPAfindClosestEdge(simplex)

        local support = GJKsupport(ShapeA, ShapeB, Edge.normal)
        local distance = Edge.normal:dot(support)

        if math.abs(distance - Edge.distance) > EPAtolerance then
            Edge.distance = math.huge
            table.insert(simplex, Edge.index, support)
        end
    end

    return Edge.normal, Edge.distance + EPAtolerance
end

function EPAfindClosestEdge(simplex)
    local minIndex = 0
    local minDistance = math.huge
    local minNormal = Vector:new(0, 0)
    while minDistance == math.huge do
        for i = 1, #simplex.points do
            local j = i + 1
            if j > #simplex.points then j = 1 end

            local vertexI = simplex.points[i]
            local vertexJ = simplex.points[j]
            local ij = vertexJ - vertexI

            local normal = Vector:new(ij.y, -ij.x):normalized()
            local distance = normal:dot(vertexI)

            if distance < 0 then
                distance = distance * -1
                normal = normal * -1
            end

            if distance < minDistance then
                minDistance = distance
                minNormal = normal
                minIndex = j
            end
        end
    end

    return {
        normal = minNormal,
        distance = minDistance,
        index = minIndex,
    }
end
