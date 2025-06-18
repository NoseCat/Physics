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
    obj.internalPressure = 10

    return obj
end

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
    radius = getMinRestLen(self) * 1.1

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

--also needs to resive area of collision
function SoftBody:move(dir, point)
    -- for index = 1, #self.points do
    --     self.points[index] = self.points[index] + dir
    -- end
    for index = 1, #self.points do
        local len = dir:normalized() * (self.points[index] - point):dot(dir:normalized())
        if len:len() > dir:len() then
            goto continue
        end

        local toPoint = dir:normalized() * (point - self.points[index]):dot(dir:normalized())
        self.points[index] = self.points[index] + toPoint + dir
        ::continue::
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
    for _ = 1, 5 do
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

    self.rotVel = getRotVel(self)
    self.vel = getVel(self)
end

function SoftBody:draw()
    Object.draw(self)
    local com = getCenterOfMass(self)
    love.graphics.setColor({1,0,0})
    love.graphics.circle("fill", com.x, com.y, 10)

    if #self.points < 3 then
        return
    end

    love.graphics.setColor(0.5, 0.7, 0.7)
    local points = {}
    for _, point in ipairs(self.points) do
        table.insert(points, point.x)
        table.insert(points, point.y)
    end
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", points)
end


return SoftBody