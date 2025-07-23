require('Math.Vector')
require('Object.Shape')
require('Interaction.SATCollisionDetection')
--require('Interaction.GJKCollisionDetection')

Collision = {}
Collision.__index = Collision

function Collision:new(shapeA, shapeB)
    local instance = setmetatable({}, Collision)

    instance.isCollided = false
    instance.shapeA = shapeA
    instance.shapeB = shapeB

    instance.points = {} --all collision points
    instance.point = Vector:new(0,0) --collision point
    instance.mtv = Vector:new(0,0) --minumum translation vector, points from B to A

    return instance
end

--creates collsion object for 2 shapes
function Collision.Collide(ShapeA, ShapeB)
    local collision = Collision:new(ShapeA, ShapeB)

    if not ShapeA.bbox:intersects(ShapeB.bbox) then
        collision.isCollided = false
        return collision
    end
    local MTV = Vector:new(0,0)
    local trianglesA = ShapeA:triangulate()
    local trianglesB = ShapeB:triangulate()
    local centerA = ShapeA:getRealCenter()
    local centerB = ShapeB:getRealCenter()
    for _, triangleA in ipairs(trianglesA) do
        for _, triangleB in ipairs(trianglesB) do
            local isCollided
            local curMTV
            isCollided, curMTV = SATCollide(triangleA, triangleB)
            if isCollided and curMTV then
                collision.isCollided = true
                if curMTV:len() > MTV:len() then
                    MTV = curMTV
                    local function findCenter(points)
                        local sum = Vector:new(0,0)
                        for _, point in ipairs(points) do
                            sum = sum + point
                        end
                        return sum / #points
                    end
                    centerA = findCenter(triangleA)
                    centerB = findCenter(triangleB)
                end
            end
        end
    end
--    collision.isCollided, MTV = SATCollide(ShapeA:getRealPoints(), ShapeB:getRealPoints())
    if not (collision.isCollided or MTV) then
        return collision
    end

    collision.points = collision:getPoints()
    local sumColPoints = Vector:new(0, 0)
    for _, point in ipairs(collision.points) do
        sumColPoints = sumColPoints + point
    end
    if #collision.points > 0 then
        collision.point = sumColPoints / #collision.points
    end
    local minus = 1

    if MTV:dot(centerB - centerA) < 0 then
        minus = -1
    end
    MTV = MTV * minus -- fix MTV so it always points from B to A
    collision.mtv = MTV

    return collision
end

--returns array of points of intersections of lines of 2 objects
function Collision:getPoints() --Something to improve
    local SArealPoints = self.shapeA:getRealPoints()
    local SBrealPoints = self.shapeB:getRealPoints()
    local points = {}

    for i = 1, #SArealPoints do
        local inext = i + 1
        if inext > #SArealPoints then inext = 1 end
        for j = 1, #SBrealPoints do
            local jnext = j + 1
            if jnext > #SBrealPoints then jnext = 1 end
            local intersection = Vector.SegmentIntersect(SArealPoints[i], SArealPoints[inext], SBrealPoints[j], SBrealPoints[jnext])
            if intersection then
                table.insert(points, intersection)
            end
        end
    end
    return points
end

--moves objects so they dont collide
function Collision:resolve()
    if not self.isCollided then
        return
    end
    local massA = self.shapeA:getMass()
    local massB = self.shapeB:getMass()

    local staticA = math.min(math.max( massB / (massA + massB) , 0), 1)
    local staticB = math.min(math.max( massA / (massA + massB) , 0), 1)
    if massB == math.huge then
        staticA = 1
    end
    if massA == math.huge then
        staticB = 1
    end
    self.shapeA:unCollide(self.mtv * -1 * staticA, self, self.shapeB)
    self.shapeB:unCollide(self.mtv * staticB, self, self.shapeA)
end

--applies impulse parralel to mtv
function Collision:applyBounce(delta)
    local bounce = math.min(self.shapeA.bounce, self.shapeB.bounce)

    local mtv = self.mtv:normalized()
    local rA = self.point - self.shapeA:getRealCenter()
    local rB = self.point - self.shapeB:getRealCenter()
    --relvel = relative Linear velocity + relative Angular velocity 
    local relVel = (self.shapeB:getVel() - self.shapeA:getVel()) - rA:perp() * self.shapeA:getRotVel() + rB:perp() * self.shapeB:getRotVel()
    local velAlongNormal = relVel:dot(mtv)
    if velAlongNormal > 0 then
        return
    end

    local impulse = velAlongNormal * (bounce + 1)
    impulse = impulse / (1/self.shapeA:getMass() + 1/self.shapeB:getMass() + (rA:cross(mtv)^2 / self.shapeA:getInertia()) + (rB:cross(mtv)^2 / self.shapeB:getInertia()))

    self.shapeA:applyForceAtPoint(mtv * (impulse / delta), self.point)
    self.shapeB:applyForceAtPoint(mtv * (impulse / -delta), self.point)
end

--applies impulse perpendicular to mtv (friction)
function Collision:applyFriction(delta)
    local friction = math.min(self.shapeA.friction, self.shapeB.friction)

    local mtv = self.mtv:normalized()
    local rA = self.point - self.shapeA:getRealCenter()
    local rB = self.point - self.shapeB:getRealCenter()
    --relvel = relative Linear velocity + relative Angular velocity 
    local relVel = (self.shapeB:getVel() - self.shapeA:getVel()) - rA:perp() * self.shapeA:getRotVel() + rB:perp() * self.shapeB:getRotVel()
    local velAlongNormal = relVel:dot(mtv)
    if velAlongNormal > 0 then
        return
    end

    local perp = relVel - mtv * velAlongNormal
    if perp:len2() == 0 then
        return
    end
    perp = perp:normalized()
    local velPerpNormal = relVel:dot(perp)
    local impulse = velPerpNormal * (friction)
    impulse = impulse / (1/self.shapeA:getMass() + 1/self.shapeB:getMass() + (rA:cross(perp)^2 / self.shapeA:getInertia()) + (rB:cross(perp)^2 / self.shapeB:getInertia()))

    self.shapeA:applyForceAtPoint(perp * (impulse / delta), self.point)
    self.shapeB:applyForceAtPoint(perp * (impulse / -delta), self.point)
end

return Collision