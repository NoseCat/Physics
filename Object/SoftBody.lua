local PhysicsBody = require('Object.PhysicsBody')
require('Math.Vector')

local SoftBody = setmetatable({}, { __index = PhysicsBody})
SoftBody.__index = SoftBody
function SoftBody:new(a, b, m, k)
    local obj = PhysicsBody.new(self, a, b)

    obj.mass = m

    obj.points = {}
    obj.pointsPrev = {}
    obj.pointsAccel = {}
    obj.pointsForce = {}

    obj.restLens = {}

    obj.restArea = 0
    obj.stiffness = k
    obj.contourTension = 5
    obj.internalPressure = 3

--    obj.bounce = 0
  --  obj.friction = 0

    return obj
end

local ChaikinPasses = 2

--=====================================================================
--redifinig methods from PhysicsObject tree because different structure
--=====================================================================

function SoftBody:addPoint(x, y)
    table.insert(self.points, Vector:new(x,y) + self.pos)
    table.insert(self.pointsPrev, Vector:new(x,y) + self.pos)
    table.insert(self.pointsAccel, Vector:new(0,0))
    table.insert(self.pointsForce, Vector:new(0,0))
    self:updateConstants()
end

function SoftBody:updateConstants()
    PhysicsBody.updateConstants(self)
    self.restLens = {}
    for i = 1, #self.points do
        local nextIdx = (i % #self.points) + 1
        self.restLens[i] = (self.points[i] - self.points[nextIdx]):len()
    end

    self.restArea = self:getArea()
end

function SoftBody:getRealPoints()
    return self.points
end

function SoftBody:print()
    print("Soft Body")
end

--needs to return mass of all points in a region
function SoftBody:getMass()
    return self.mass/(#self.points)
end

function SoftBody:applyForce(force)
    for index = 1, #self.points do
        self.pointsForce[index] = self.pointsForce[index] + (force/#self.points)
    end
end

function SoftBody:applyForceAtClosestPoint(force, point)
    local closestDist = math.huge
    local closestIndex = 1

    for index, bodyPoint in ipairs(self.points) do
        local dist = (bodyPoint - point):len2()
        if dist < closestDist then
            closestDist = dist
            closestIndex = index
        end
    end

    -- Применяем силу к ближайшей точке
    self.pointsForce[closestIndex] = self.pointsForce[closestIndex] + force
end

local function getMinRestLen(self)
    if #self.restLens == 0 then return 0 end
    local minLen = math.huge
    for _, len in ipairs(self.restLens) do
        if len < minLen then minLen = len end
    end
    return minLen
end

function SoftBody:applyForceAtPoint(force, point)
    local radius = getMinRestLen(self) * 1.1

    local totalWeight = 0
    local weights = {}

    -- Сначала вычисляем веса для каждой точки
    for index, bodyPoint in ipairs(self.points) do
        local dist = (bodyPoint - point):len()
        if dist < radius then
            weights[index] = (radius - dist) / radius
            totalWeight = totalWeight + weights[index]
        else
            weights[index] = 0
        end
    end

    -- Если ни одна точка не попала в радиус - применяем к ближайшей
    if totalWeight <= 0 then
        return self:applyForceAtClosestPoint(force, point)
    end

    -- Распределяем силу согласно весам
    for index, weight in pairs(weights) do
        if weight > 0 then
            local partialForce = force * (weight / totalWeight)
            self.pointsForce[index] = self.pointsForce[index] + partialForce
        end
    end
end

local function getCenterOfMass(self)
    local com = Vector:new(0, 0)
    for _, point in ipairs(self.points) do
        com = com + point
    end
    return com / #self.points
end

function SoftBody:getRealCenter()
    return getCenterOfMass(self)
end

local function getRot(self)
    return (self.points[1] - self:getRealCenter()):angleFull(Vector:new(0,-1))
end

local function getRotVel(self)
    local com = getCenterOfMass(self)
    local totalAngularVelocity = 0

    for i, point in ipairs(self.points) do
        local pointMass = self.mass / #self.points
        local r = point - com
        local velocity = (point - self.pointsPrev[i]) -- Approximate velocity from last frame
        -- Angular velocity component for this point: (r × v) / |r|²
        local angularVelocity = r:cross(velocity) / r:len2()
        totalAngularVelocity = totalAngularVelocity + angularVelocity * pointMass
    end

    return totalAngularVelocity / self.mass
end

function SoftBody:applyTorque(torque)
    local com = getCenterOfMass(self)
    for i, point in ipairs(self.points) do
        local r = point - com
        -- Force = torque × r / |r|² (perpendicular to r)
        local force = r:perp():normalized() * torque / r:len()
        self.pointsForce[i] = self.pointsForce[i] + force
    end
end

local function getVel(self)
    local totalMomentum = Vector:new(0, 0)

    for i, point in ipairs(self.points) do
        local pointVelocity = (point - self.pointsPrev[i])
        totalMomentum = totalMomentum + pointVelocity
    end

    return totalMomentum / #self.points
end

local staticTodynamicMovement = 0.99
--staticTodynamicMovement = 1/ (1 + 2*k)
function SoftBody:unCollide(dir, collision, otherShape)
    local collisionPoint = collision.point
    -- local projLen = math.huge
    -- local otherShapePoints = otherShape:getRealPoints()
    -- for i, _ in ipairs(otherShapePoints) do
    --     local iNext = (i % #otherShapePoints) + 1

    --     local projectedPoint = collision.point:project(otherShapePoints[i], otherShapePoints[iNext])
    --     if (projectedPoint - collision.point):len() < projLen then
    --         projLen = (projectedPoint - collision.point):len()
    --         collisionPoint = projectedPoint
    --     end
    -- end

    local area = {}
    if #collision.points > 1 then
        local projections = {}
        for index = 1, #collision.points do
            table.insert(projections, index, dir:normalized():perp() * (collision.points[index] - collisionPoint):dot(dir:normalized():perp()))
        end

        local max_dist = -math.huge
        for i = 1, #projections do
            for j = i+1, #projections do
                local dist = (projections[i] - projections[j]):len()
                if dist > max_dist then
                    max_dist = dist
                    -- area.max = collision.points[i]
                    -- area.min = collision.points[j]
                    area.max = collisionPoint + projections[i]
                    area.min = collisionPoint + projections[j]
                end
            end
        end
    end

    if not area.max then
        area.max = dir:normalized():perp() * math.huge
    end
    if not area.min then
        area.min = dir:normalized():perp() * -math.huge
    end

    if (area.max - area.min):len() < getMinRestLen(self) then
        area.min = collision.point - dir:perp():normalized() * getMinRestLen(self)/2
        area.max = collision.point + dir:perp():normalized() * getMinRestLen(self)/2
    end

    area.max = area.max + area.max:normalized() * getMinRestLen(self)/5
    area.min = area.min - area.min:normalized() * getMinRestLen(self)/5

    for index = 1, #self.points do
        -- local collisionPoint = collision.point
        -- local projLen = math.huge
        -- local otherShapePoints = otherShape:getRealPoints()
        -- for i, _ in ipairs(otherShapePoints) do
        --     local iNext = (i % #otherShapePoints) + 1

        --     local projectedPoint = collision.point:project(otherShapePoints[i], otherShapePoints[iNext])
        --     if (projectedPoint - collision.point):len() < projLen then
        --         projLen = (projectedPoint - collision.point):len()
        --         collisionPoint = projectedPoint
        --     end
        -- end

        local len = dir:normalized() * (self.points[index] - collisionPoint):dot(dir:normalized())
        if len:len() > dir:len() then
            goto continue
        end

        local proj = collisionPoint + dir:perp():normalized() * (self.points[index] - collisionPoint):dot(dir:perp():normalized())
        local areaLen = (area.max - area.min):len()
        if (proj - area.max):len() > areaLen or (proj - area.min):len() > areaLen then
            goto continue
        end

        local toPoint = dir:normalized() * (collisionPoint - self.points[index]):dot(dir:normalized())
        self.points[index] = self.points[index] + (toPoint + dir) * staticTodynamicMovement
        --this is how you move points without impacting velocity
        local toPointPrev = dir:normalized() * (collisionPoint - self.pointsPrev[index]):dot(dir:normalized())
        self.pointsPrev[index] = self.pointsPrev[index] + (toPointPrev + dir) * staticTodynamicMovement
        ::continue::
    end
    for index = 1, #self.points do
        self.points[index] = self.points[index] + dir * (1 - staticTodynamicMovement)
        self.pointsPrev[index] = self.pointsPrev[index] + dir * (1 - staticTodynamicMovement)
    end
end

--====================
--actually new methods
--====================

local function preserveArea(self)
    local areaDiff = (self.restArea - self:getArea()) / self.restArea
    for index = 1, #self.points do
        local nextIdx = (index % #self.points) + 1
        local prevIdx = (index - 2) % #self.points + 1
        local outVector = ((self.points[nextIdx] - self.points[prevIdx]):normalized()):perp() * -1

        self.points[index] = self.points[index] + outVector * self.internalPressure *  areaDiff * self.stiffness
    end
end

local function attachPoints(self)
    for index = 1, #self.points do
        local nextIdx = (index % #self.points) + 1
        local dist = (self.points[nextIdx] - self.points[index])
        local diff = (self.restLens[index] - dist:len()) / self.restLens[index]
        self.points[index] = self.points[index] + dist:normalized() * -diff * self.contourTension * self.stiffness
        self.points[nextIdx] = self.points[nextIdx] + dist:normalized() * diff * self.contourTension * self.stiffness
    end
end

function SoftBody:update(delta)
    for _ = 1, 24 do
        attachPoints(self)
        preserveArea(self)
    end
    for index = 1, #self.points do
        --verlet integration
        local nextPos = self.points[index] * 2 - self.pointsPrev[index] + self.pointsAccel[index] * delta ^ 2
        self.pointsPrev[index] = self.points[index]
        self.points[index] = nextPos

        self.pointsAccel[index] = self.pointsForce[index] / (self.mass / #self.points)
        self.pointsForce[index] = Vector:new(0,0)
    end

    self.rot = getRot(self)
    self.rotVel = getRotVel(self)
    self.vel = getVel(self)
    self.bbox:updatePoints(self:getRealPoints())
end

-- function SoftBody:triangulate()
--     local Rpoints = self:getRealPoints()
--     local points = {}
--     for _, point in ipairs(Rpoints) do
--         table.insert(points, point.x)
--         table.insert(points, point.y)
--     end
--     if love.math.isConvex(points) then
--         return {Rpoints}
--     end
--     local triangles = {}
--     for i, _ in ipairs(Rpoints) do
--         local iNext = (i % #Rpoints) + 1
--         table.insert(triangles, {Rpoints[i], self:getRealCenter(), Rpoints[iNext]})
--     end
--     return triangles
-- end

function SoftBody:draw()
    Object.draw(self)
    local com = getCenterOfMass(self)
    love.graphics.setColor({1,0,0})
    love.graphics.circle("fill", com.x, com.y, 10)

    if #self.points < 3 then
        return
    end

    --Chaikin smoothing
    local CHpoints = {}
    for _, point in ipairs(self.points) do
        table.insert(CHpoints, point)
    end

    for i = 1, ChaikinPasses, 1 do
        local tempPoints = {}
        for index = 1, #CHpoints do
            local nextIdx = (index % #CHpoints) + 1

            local point = CHpoints[index] + (CHpoints[nextIdx] - CHpoints[index]) * 0.25
            table.insert(tempPoints, point)
            point = point + (CHpoints[nextIdx] - CHpoints[index]) * 0.5
            table.insert(tempPoints, point)
        end
        CHpoints = {}
        for _, point in ipairs(tempPoints) do
            table.insert(CHpoints, point)
        end
    end

    love.graphics.setLineWidth(5)
    local vertices = {}
    for i, point in ipairs(CHpoints) do
        local progress = (i-1)/(#CHpoints-1)
        local r, g, b = 0, 1 - progress, progress
        table.insert(vertices, {x = point.x, y = point.y, r = r, g = g, b = b})
    end
    for index, vertice in ipairs(vertices) do
        local nextIdx = (index % #vertices) + 1

        love.graphics.setColor(vertice.r, vertice.g, vertice.b)
        love.graphics.line(vertice.x, vertice.y, vertices[nextIdx].x, vertices[nextIdx].y)
    end

    -- love.graphics.setLineWidth(1)
    -- love.graphics.setColor(1, 0, 0)
    -- local triangles = self:triangulate()
    -- for _, triangle in ipairs(triangles) do
    --     local points = {}
    --     for _, point in ipairs(triangle) do
    --         table.insert(points, point.x)
    --         table.insert(points, point.y)
    --     end
    --     love.graphics.polygon("line", points)
    -- end
end


return SoftBody