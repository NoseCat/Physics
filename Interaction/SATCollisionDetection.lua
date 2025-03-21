require('Math.Vector')
require('Object.Shape')

--[[=========================================
        SAT algorithm for collision detection
=============================================]]

function SATCollide(ShapeA, ShapeB)
    --SAT needs to check all normals of both shapes' edges
    local normals = {}
    local function getNormals(points, shapeCenter)
        for i = 1, #points do
            local j = i + 1
            if j > #points then j = 1 end

            local edge = points[i] - points[j]
            local normal = Vector:new(edge.y, -edge.x):normalized()
            table.insert(normals, normal)
        end
    end
    getNormals(ShapeA:getRotatedPoints(), ShapeA.center)
    getNormals(ShapeB:getRotatedPoints(), ShapeB.center)

    local smallestLength = math.huge
    local MTVaxis = Vector:new(0, 0)
    for _, axis in ipairs(normals) do
        local minA, maxA = ShapeA:project(axis)
        local minB, maxB = ShapeB:project(axis)
        --if there is atleast 1 axis with no overlap - shapes dont collide
        if maxA < minB or maxB < minA then
            return false, nil
        end
        --smalest overlap is length of MTV, axis is orientation 
        local len = math.min(maxA, maxB) - math.max(minA, minB)
        if len < smallestLength then
            smallestLength = len
            MTVaxis = axis
        end
    end
    --no axis overlap
    return true, MTVaxis * smallestLength
end