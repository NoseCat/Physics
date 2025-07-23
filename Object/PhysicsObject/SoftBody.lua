local PhysicsObject = require('Object.PhysicsObject.PhysicsObject')
require('Math.Vector')

local SoftBody = setmetatable({}, { __index = PhysicsObject})
SoftBody.__index = SoftBody
function SoftBody:new(a, b, m)
    local obj = PhysicsObject.new(self, a, b)

    obj.mass = m

--    obj.points = {}
    obj.pointsPrev = {}
    obj.pointsAccel = {}
    obj.pointsForce = {}

    obj.restLens = {}

    obj.restArea = 0
    obj.stiffness = 1
    obj.contourTension = 10
    obj.internalPressure = 6

    return obj
end

local ChaikinPasses = 2

--===============
-- SoftBody
--===============

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

    self.pointsForce[closestIndex] = self.pointsForce[closestIndex] + force
end

--useful for finding a size that is not too small for interactions with SoftBody
local function getMinRestLen(self)
    if #self.restLens == 0 then return 0 end
    local minLen = math.huge
    for _, len in ipairs(self.restLens) do
        if len < minLen then minLen = len end
    end
    return minLen
end

local function getRot(self) -- to update our rotation
    return (self.points[1] - self:getRealCenter()):angleFull(Vector:new(0,-1))
end

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

--===============
-- PhysicsObject
--===============

function SoftBody:getMass()
    return self.mass
end

function SoftBody:applyForce(force)
    for index = 1, #self.points do
        self.pointsForce[index] = self.pointsForce[index] + (force/#self.points)
    end
end

function SoftBody:applyForceAtPoint(force, point)
    local radius = getMinRestLen(self) * 1.1

    local totalWeight = 0
    local weights = {}

    -- calculate "weight" - how much the point is affected relatevly
    for index, bodyPoint in ipairs(self.points) do
        local dist = (bodyPoint - point):len()
        if dist < radius then
            weights[index] = (radius - dist) / radius
            totalWeight = totalWeight + weights[index]
        else
            weights[index] = 0
        end
    end

    if totalWeight <= 0 then
        return self:applyForceAtClosestPoint(force, point)
    end

    for index, weight in pairs(weights) do
        if weight > 0 then
            local partialForce = force * (weight / totalWeight)
            self.pointsForce[index] = self.pointsForce[index] + partialForce
        end
    end
end

function SoftBody:getRotVel()
    local com = self:getRealCenter()
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
    local com = self:getRealCenter()
    for i, point in ipairs(self.points) do
        local r = point - com
        -- Force = torque × r / |r|² (perpendicular to r)
        local force = r:perp():normalized() * (torque / r:len())
        self.pointsForce[i] = self.pointsForce[i] + force
    end
end

function SoftBody:getVel()
    local totalMomentum = Vector:new(0, 0)

    for i, point in ipairs(self.points) do
        local pointVelocity = (point - self.pointsPrev[i])
        totalMomentum = totalMomentum + pointVelocity
    end

    return totalMomentum / #self.points
end

function SoftBody:getInertia()
    local maxDistance = 0
    for _, point in ipairs(self.points) do
        local distance = (point - self:getRealCenter()):len()
        if distance > maxDistance then
            maxDistance = distance
        end
    end

    local k = 0.5
    L = maxDistance
    return k * self:getMass() * L^2
end

local staticTodynamicMovement = 0.9
--staticTodynamicMovement = 1/ (1 + 2*k)
function SoftBody:unCollide(dir, collision, otherShape)
    local collisionPoint = collision.point

    --calculate width (area) of collsion
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

    --dyanimc movement (only affected points)
    for index = 1, #self.points do
        --points is inside "depth" of collsion
        local len = dir:normalized() * (self.points[index] - collisionPoint):dot(dir:normalized())
        if len:len() > dir:len() then
            goto continue
        end

        --points is inside "width" of collsion
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
    --static movement (all points)
    for index = 1, #self.points do
        self.points[index] = self.points[index] + dir * (1 - staticTodynamicMovement)
        self.pointsPrev[index] = self.pointsPrev[index] + dir * (1 - staticTodynamicMovement)
    end
end

function SoftBody:update(delta)
    PhysicsObject.update(self, delta)
    for _ = 1, 8 do
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
end

--===============
-- Shape
--===============

function SoftBody:addPoint(x, y)
    Shape.addPoint(self, x + self.pos.x, y + self.pos.y)
    table.insert(self.pointsPrev, Vector:new(x,y) + self.pos)
    table.insert(self.pointsAccel, Vector:new(0,0))
    table.insert(self.pointsForce, Vector:new(0,0))
end

function SoftBody:updateConstants()
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

function SoftBody:getRealCenter()
    return Shape.getRealCenter(self) - self.pos
end

--===============
-- Object
--===============

local function ChaikinSmoothing(points)
    local CHpoints = {}
    for _, point in ipairs(points) do
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

    return CHpoints
end

function SoftBody:draw()
    Object.draw(self)
    local com = self:getRealCenter()
    love.graphics.setColor({1,0,0})
    love.graphics.circle("fill", com.x, com.y, 10)

    if #self.points < 3 then
        return
    end

    local CHpoints = ChaikinSmoothing(self.points)

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
end


return SoftBody