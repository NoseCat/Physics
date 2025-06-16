local PhysicsBody = require('Object.PhysicsBody')
require('Math.Vector')

local SoftBody = setmetatable({}, { __index = PhysicsBody })
SoftBody.__index = SoftBody
function SoftBody:new(a, b, m, k)

    local obj = PhysicsBody.new(self, a, b, m)

    obj.pointsVels = {}
    obj.springRestLens = {}

    obj.bounce = 0.3

    obj.restArea = 0
    obj.stiffness = k

    return obj
end

--контур цепь пружин (двигаем точки, возвращаем силу)
--сохраняем обьём (двигаем точки, возвращаем силу)
--вдавливаем точки (от силы)
-- силу пока не возвращаем пусть отпрыгивает

local Delta = 0

function SoftBody:update(delta)
    Delta = delta
    PhysicsBody.update(self, delta)
    self:springPoints(delta)
    self:preserveArea(delta)

    for index, _ in ipairs(self.points) do
        self.points[index] = self.points[index] + self.pointsVels[index] * delta
    end
end

function SoftBody:springPoints(delta)
    -- for index = 1, #self.points do
    --     local nextIndex = (index % #self.points) + 1

    --     -- Рассчитываем текущий вектор между точками
    --     local vec = self.points[nextIndex] - self.points[index]
    --     local currentLength = vec:len()
    --     local restLength = self.springRestLens[index]

    --     -- Вычисляем разность длин и направление
    --     local diff = currentLength - restLength
    --     local direction = vec:normalized()

    --     -- Сила Гука: F = -k * Δx
    --     local force = direction * (-self.stiffness * diff)

    --     -- Применяем силу к точкам с учетом их масс
    --     self.pointsVels[index] = self.pointsVels[index] + (force / (self.mass / #self.points)) * delta
    --     self.pointsVels[nextIndex] = self.pointsVels[nextIndex] - (force / (self.mass / #self.points)) * delta
    -- end
end

function SoftBody:preserveArea(delta)
    -- local currentArea = self:getArea()
    -- local areaDiff = currentArea - self.restArea

    -- -- Коэффициент жесткости объема (можно настроить отдельно)
    -- local volumeStiffness = self.stiffness * 5

    -- for i = 1, #self.points do
    --     local nextIdx = (i % #self.points) + 1
    --     local prevIdx = (i - 2) % #self.points + 1

    --     -- Вычисляем градиент площади
    --     local dAdx = 0.5 * (self.points[nextIdx].y - self.points[prevIdx].y)
    --     local dAdy = 0.5 * (self.points[prevIdx].x - self.points[nextIdx].x)

    --     -- Сила пропорциональна разности площадей
    --     local force = Vector:new(dAdx, dAdy) * (-volumeStiffness * areaDiff)

    --     -- Применяем силу к точке
    --     self.pointsVels[i] = self.pointsVels[i] + (force / (self.mass / #self.points)) * delta
    -- end
end

function SoftBody:updateConstants()
    PhysicsBody.updateConstants(self)

    -- Инициализация скоростей
    for i = 1, #self.points do
        if not self.pointsVels[i] then
            self.pointsVels[i] = Vector:new(0, 0)
        end
    end

    -- Расчет длин пружин
    self.springRestLens = {}
    for i = 1, #self.points do
        local nextIdx = (i % #self.points) + 1
        self.springRestLens[i] = (self.points[i] - self.points[nextIdx]):len()
    end

    self.restArea = self:getArea()
end

function SoftBody:applyForceAtPoint(force, point)
    PhysicsBody.applyForceAtPoint(self, force, point)

    -- Преобразование в локальные координаты
    local localPoint = (point - (self.pos + self.center)):rotate(-self.rot)
    local localForce = force:rotate(-self.rot)

    -- Распределение силы по точкам
    local totalWeight = 0
    local weights = {}

    for i, pt in ipairs(self.points) do
        local dist = (pt - localPoint):len()
        weights[i] = 1 / (dist^2 + 0.01)  -- +0.01 для избежания деления на 0
        totalWeight = totalWeight + weights[i]
    end

    for i, pt in ipairs(self.points) do
        local forcePart = localForce * (weights[i] / totalWeight)
        self.pointsVels[i] = self.pointsVels[i] + (forcePart / (self.mass / #self.points)) * Delta
    end
end

return SoftBody