Vector = {}

function Vector:new(a, b)
    local newObj = {x = a, y = b}

    self.__index = self
    return setmetatable(newObj, self)
end

function Vector.__add(a, b)
    return Vector:new(a.x + b.x, a.y + b.y)
end

function Vector.__sub(a, b)
    return Vector:new(a.x - b.x, a.y - b.y)
end

function Vector.__mul(a, b)
    return Vector:new(a.x * b, a.y * b)
end

function Vector:dot(b)
    return self.x * b.x + self.y * b.y
end

function Vector.__div(a, b)
    return Vector:new(a.x / b, a.y / b)
end

function Vector:len()
    return math.sqrt(self.x^2 + self.y^2)
end

--length ^2, faster
function Vector:len2()
    return self.x^2 + self.y^2
end

function Vector:normalized()
    local len = self:len()
    if len == 0 then
        return Vector:new(0,0)
    end
    return Vector:new(self.x / len, self.y / len)
end

--radians, clockwise
function Vector:rotate(angle)
    return Vector.rotateAround(self, Vector:new(0,0), angle)
end

--radians, clockwise
function Vector:rotateAround(rotationPoint, angle)
    local newPoint = Vector:new(0,0)
    newPoint.x = rotationPoint.x + (self.x - rotationPoint.x) * math.cos(angle) - (self.y - rotationPoint.y) * math.sin(angle)
    newPoint.y = rotationPoint.y + (self.x - rotationPoint.x) * math.sin(angle) + (self.y - rotationPoint.y) * math.cos(angle)

    return newPoint
end

function Vector:project(A, B)
    local AB = B - A  
    local AP = self - A

    local ab2 = AB:len2()
    if ab2 == 0 then
        return A
    end

    local t = AP:dot(AB) / ab2  
    t = math.max(0, math.min(1, t))

    return Vector:new(A.x + t * AB.x, A.y + t * AB.y)
end

local function triangleHeight(A, B, C)
    local AB = B - A

    if AB == 0 then
        return 0
    end

    local area = ((A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y)) / 2)
    local height = (2 * area) / AB
    return height
end