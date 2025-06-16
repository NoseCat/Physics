local Object = require('Object.Object')
require('Math.Vector')

local SoftBody = setmetatable({}, { __index = Object})
SoftBody.__index = SoftBody
function SoftBody:new(a, b, m, k)
    local obj = Object.new(self, a, b)

    obj.mass = m

    obj.points = {}
    obj.pointsPrev = {}
    obj.pointsAccel = {}
    obj.pointsForce = {}

    obj.restLens = {}

    obj.restArea = 0
    obj.stiffness = k

    return obj
end

function SoftBody:addPoint(x, y)
    table.insert(self.points, Vector:new(x,y) + self.pos)
    table.insert(self.pointsPrev, Vector:new(x,y) + self.pos)
    table.insert(self.pointsAccel, Vector:new(0,0))
    table.insert(self.pointsForce, Vector:new(0,0))
    self:updateConstants()
end

function SoftBody:updateConstants()

    self.restLens = {}
    for i = 1, #self.points do
        local nextIdx = (i % #self.points) + 1
        self.restLens[i] = (self.points[i] - self.points[nextIdx]):len()
    end

    self.restArea = self:getArea()
end

function SoftBody:getArea()
    local sum = 0
    for i = 1, #self.points do
        local j = i + 1
        if j > #self.points then j = 1 end

        sum = sum + self.points[i].x * self.points[j].y - self.points[j].x * self.points[i].y
    end

    return math.abs(sum) / 2
end

function SoftBody:update(delta)
    for _ = 1, 5 do
        self:attachPoints()
        self:preserveArea()
    end
    for index = 1, #self.points do
        --verlet integration
        local nextPos = self.points[index] * 2 - self.pointsPrev[index] + self.pointsAccel[index] * delta ^ 2
        self.pointsPrev[index] = self.points[index]
        self.points[index] = nextPos

        self.pointsAccel[index] = self.pointsForce[index] / (self.mass / #self.points)
        self.pointsForce[index] = Vector:new(0,0)
    end

    self:applyForce(Vector:new(0,10))
end

function SoftBody:preserveArea()
    local areaDiff = (self.restArea - self:getArea()) / self.restArea
    for index = 1, #self.points do
        local nextIdx = (index % #self.points) + 1
        local prevIdx = (index - 2) % #self.points + 1
        local outVector = ((self.points[nextIdx] - self.points[prevIdx]):normalized()):perp() * -1

        self.points[index] = self.points[index] + outVector * 10 * areaDiff * self.stiffness
    end
end

function SoftBody:attachPoints()
    for index = 1, #self.points do
        local nextIdx = (index % #self.points) + 1
        local diff = (self.points[nextIdx] - self.points[index]) / 2
        self.points[nextIdx] = self.points[index] + diff + diff:normalized() * self.restLens[index] / 2
        self.points[index] = self.points[index] + diff - diff:normalized() * self.restLens[index] / 2
    end
end

function SoftBody:applyForce(force)
    for index = 1, #self.points do
        self.pointsForce[index] = self.pointsForce[index] + force
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

function SoftBody:getMinRestLen()
    if #self.restLens == 0 then return 0 end
    local minLen = math.huge
    for _, len in ipairs(self.restLens) do
        if len < minLen then minLen = len end
    end
    return minLen
end

function SoftBody:applyForceAtPoint(force, point)
    radius = self:getMinRestLen() * 1.1

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

function SoftBody:containsPoint(point)
    local x, y = point.x, point.y
    local inside = false

    -- Ray-casting algorithm
    for i = 1, #self.points do
        local j = i % #self.points + 1
        local xi, yi = self.points[i].x, self.points[i].y
        local xj, yj = self.points[j].x, self.points[j].y

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


function SoftBody:draw()
    Object.draw(self)

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