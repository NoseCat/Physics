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

    instance.point = Vector:new(0,0) --collision point
    instance.mtv = Vector:new(0,0) --minumum translation vector, points from B to A

    return instance
end

--creates collsion object for 2 shapes
function Collide(ShapeA, ShapeB)
    local collision = Collision:new(ShapeA, ShapeB)

    local isCollided, MTV = SATCollide(ShapeA, ShapeB)
    collision.isCollided = isCollided

    if isCollided and MTV then
        local colPoints = collision:getPoints()

        local minus = -1
        if MTV:dot((ShapeA.pos + ShapeA.center) - (ShapeB.pos + ShapeB.center)) < 0 then
            minus = 1
        end
        MTV = MTV * minus -- fix MTV so it always points from B to A
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

--returns array of points of intersections of lines of 2 objects
function Collision:getPoints()
    local SArealPoints = self.shapeA:getRealPoints()
    local SBrealPoints = self.shapeB:getRealPoints()
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

--moves objects so they dont collide
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

--applies impulse parralel to mtv
function Collision:applyBounce(delta)
    local bounce = math.min(self.shapeA.bounce, self.shapeB.bounce)

    local mtv = self.mtv:normalized()
    local rA = self.point - (self.shapeA.pos + self.shapeA.center)
    local rB = self.point - (self.shapeB.pos + self.shapeB.center)
    --relvel = relative Linear velocity + relative Angular velocity 
    local relVel = (self.shapeB.vel - self.shapeA.vel) - rA:perp() * self.shapeA.rotVel + rB:perp() * self.shapeB.rotVel
    local velAlongNormal = relVel:dot(mtv)
    if velAlongNormal > 0 then
        return
    end

    local impulse = (1 + bounce) * velAlongNormal
    impulse = impulse / (1/self.shapeA.mass + 1/self.shapeB.mass + (rA:cross(mtv)^2 / self.shapeA.inertia) + (rB:cross(mtv)^2 / self.shapeB.inertia))

    self.shapeA:applyForceAtPoint(mtv * (impulse / delta), self.point)
    self.shapeB:applyForceAtPoint(mtv * -(impulse / delta), self.point)
end

--applies impulse perpendicular to mtv (friction)
function Collision:applyFriction(delta)
    local friction = math.min(self.shapeA.friction, self.shapeB.friction)

    local mtv = self.mtv:normalized()
    local rA = self.point - (self.shapeA.pos + self.shapeA.center)
    local rB = self.point - (self.shapeB.pos + self.shapeB.center)
    --relvel = relative Linear velocity + relative Angular velocity 
    local relVel = (self.shapeB.vel - self.shapeA.vel) - rA:perp() * self.shapeA.rotVel + rB:perp() * self.shapeB.rotVel
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
    impulse = impulse / (1/self.shapeA.mass + 1/self.shapeB.mass + (rA:cross(perp)^2 / self.shapeA.inertia) + (rB:cross(perp)^2 / self.shapeB.inertia))

    self.shapeA:applyForceAtPoint(perp * (impulse / delta), self.point)
    self.shapeB:applyForceAtPoint(perp * (impulse / -delta), self.point)
end

return Collision