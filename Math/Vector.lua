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

local function LineIntersect(line1A, line1B, line2A, line2B)
    A1 = line1B.y - line1A.y;
	B1 = line1A.x - line1B.x;
	C1 = line1B.x * line1A.y - line1A.x * line1B.y;

	A2 = line2B.y - line2A.y;
	B2 = line2A.x - line2B.x;
    C2 = line2B.x * line2A.y - line2A.x * line2B.y;

	return Vector:new( (B1 * C2 - B2 * C1) / (A1 * B2 - A2 * B1),
                        (C1 * A2 - C2 * A1) / (A1 * B2 - A2 * B1) )
end

function SegmentIntersect(seg1A, seg1B, seg2A, seg2B)
    local r = seg1B - seg1A
    local s = seg2B - seg2A
    local rxs = r.x * s.y - r.y * s.x

    if rxs == 0 then
        return nil -- parallel
    end

    local t = ((seg2A.x - seg1A.x) * s.y - (seg2A.y - seg1A.y) * s.x) / rxs
    local u = ((seg2A.x - seg1A.x) * r.y - (seg2A.y - seg1A.y) * r.x) / rxs

    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        return Vector:new(seg1A.x + t * r.x, seg1A.y + t * r.y)
    end

    return nil
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