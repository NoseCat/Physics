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

function Vector:dot(b)
    return self.x * b.x + self.y * b.y
end

function Vector:cross(b)
    return self.x * b.y - self.y * b.x
end

-- (-y, x)
function Vector:perp()
    return Vector:new(-self.y, self.x)
end

-- math.atan2
local function my_atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 then
        if y >= 0 then
            return math.atan(y / x) + math.pi
        else
            return math.atan(y / x) - math.pi
        end
    else
        if y > 0 then
            return math.pi / 2
        elseif y < 0 then
            return -math.pi / 2
        else
            return 0 
        end
    end
end

--radians, full angle from -Pi to Pi
function Vector:angleFull(vec)
    return my_atan2(-self:cross(vec) , self:dot(vec))
end

--radians, minimal angle from 0 to Pi
function Vector:angle(vec)
   return math.acos(self:dot(vec) / (self:len() * vec:len()))
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

function Vector:isEqual(vec, margin)
    margin = margin or 0
    if math.abs(self.x - vec.x) < margin and math.abs(self.y - vec.y) < margin then
        return true
    end
    return false
end

function Vector:hash(margin)
    margin = margin or 0
    if margin <= 0 then return string.format("%.15g:%.15g", self.x, self.y)
    else
        local x = math.floor(self.x / margin + 0.5) * margin
        local y = math.floor(self.y / margin + 0.5) * margin
        return string.format("%.15g:%.15g", x, y)
    end
end

function Vector.LineIntersect(line1A, line1B, line2A, line2B) 
    local A1 = line1B.y - line1A.y;
	local B1 = line1A.x - line1B.x;
	local C1 = line1B.x * line1A.y - line1A.x * line1B.y;

	local A2 = line2B.y - line2A.y;
	local B2 = line2A.x - line2B.x;
    local C2 = line2B.x * line2A.y - line2A.x * line2B.y;

	return Vector:new( (B1 * C2 - B2 * C1) / (A1 * B2 - A2 * B1),
                        (C1 * A2 - C2 * A1) / (A1 * B2 - A2 * B1) )
end

function Vector.SegmentIntersect(seg1A, seg1B, seg2A, seg2B)
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

return Vector

--Class Vector new(x,y)
--Methods:
--operator add
--operator sub
--operator mul
--operator div
--len()
--len2() --len squared
--normalized()
--dot(vec)
--cross(vec)
--perp()
--angleFull(vec) --radians, full angle from -Pi to Pi
--angle(vec) --radians, minimal angle from 0 to Pi
--rotate(angle) --radians, clockwise
--rotateAround(rotationPoint, angle) --radians, clockwise
--isEqual(vec, margin) --is vec within certain margin of this