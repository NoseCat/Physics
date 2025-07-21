local Diagram = require('Diagrams.Diagram')

local Delone = {}

local Triangle = {}
Triangle.__index = Triangle
function Triangle:new(edges, id)
    local newObj = setmetatable({}, self)

    newObj.id = id
    newObj.edges = edges

    return newObj
end

local triangleId = 0
local function findSuperTriangle(pointList)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, point in ipairs(pointList) do
        minX = math.min(minX, point.x)
        minY = math.min(minY, point.y)
        maxX = math.max(maxX, point.x)
        maxY = math.max(maxY, point.y)
    end

    local width = maxX - minX
    local height = maxY - minY
    local margin = math.max(width, height) * 2  -- Large margin to ensure all points are inside

    local a = Vector:new(minX - margin, minY - margin * 3)
    local b = Vector:new(minX - margin, maxY + margin)
    local c = Vector:new(maxX + margin * 3, maxY + margin)

    local superTri = Triangle:new({
        {a = a, b = b},
        {a = b, b = c},
        {a = a, b = c}
    }, triangleId)
    triangleId = triangleId + 1
    return superTri
end

function getCircumcircle(a, b, c)
    -- Check if the points are collinear (no circumcircle exists)
    local ab = b - a
    local ac = c - a
    local cross = ab:cross(ac)
    if math.abs(cross) < 1e-5 then  -- Points are collinear
        return Vector:new(0,0), math.huge
    end

    -- Find the perpendicular bisectors of ab and ac
    local abMid = (a + b) * 0.5
    local abPerp = ab:perp()

    local acMid = (a + c) * 0.5
    local acPerp = ac:perp()

    -- Find the intersection of the bisectors (circumcenter)
    local center = Vector.LineIntersect(
        abMid, abMid + abPerp,
        acMid, acMid + acPerp
    )

    local radius = (center - a):len()
    return center, radius
end

local function isInsideCircumcircle(point, triangle) --untested
    local center, radius = getCircumcircle(triangle.edges[1].a, triangle.edges[1].b, triangle.edges[2].b)
    if (point - center):len() < radius then
        return true
    end
    return false
end

local function isSharedEdge(edge, badTriangles, id) --only checks other
    for _, triangle in ipairs(badTriangles) do
        if triangle.id == id then
            goto continue
        end
        for _, edgeB in ipairs(triangle.edges) do
            if ((edge.a - edgeB.a):len() < 1e-5 and (edge.b - edgeB.b):len() < 1e-5) or
               ((edge.a - edgeB.b):len() < 1e-5 and (edge.b - edgeB.a):len() < 1e-5) then
                return true
            end
        end
        ::continue::
    end
    return false
end

local function formTriangle(edge, point)
    local a = edge.a
    local b = edge.b
    local c = point
    local tri = Triangle:new( { {a = a, b = b}, {a = b, b = c}, {a = a, b = c} }, triangleId)
    triangleId = triangleId + 1
    return tri
end

local function hasCommonVertex(triangle1, triangle2)
    local vertexes1 = {triangle1.edges[1].a, triangle1.edges[1].b, triangle1.edges[2].b }
    local vertexes2 = {triangle2.edges[1].a, triangle2.edges[1].b, triangle2.edges[2].b }
    for _, vertex1 in ipairs(vertexes1) do
    for _, vertex2 in ipairs(vertexes2) do
        if (vertex1 - vertex2):len() < 1e-5 then
            return true
        end
    end
    end
    return false
end

function Delone.BowyerWatsonDeloneTriangulation(pointList)
    local triangulation = {} --triangles

    triangleId = 0
    local superTrinagle = findSuperTriangle(pointList)
    triangulation[superTrinagle.id] = superTrinagle

    for _, point in ipairs(pointList) do --add all the points to the triangulation

        local badTriangles = {}
        for _, triangle in pairs(triangulation) do -- first find all the triangles that are no longer valid due to the insertion
            if not triangle then goto continue end
            if isInsideCircumcircle(point, triangle) then
                table.insert(badTriangles, triangle)
            end
            ::continue::
        end

        local polygon = {}
        for _, triangle in ipairs(badTriangles) do -- find the boundary of the polygonal hole
            for _, edge in ipairs(triangle.edges) do
                if not isSharedEdge(edge, badTriangles, triangle.id) then --edge is not shared by any *other*! triangles in badTriangles
                    table.insert(polygon, edge) --add edge to polygon
                end
            end
        end

        for _, triangle in ipairs(badTriangles) do -- remove them from the data structure
            triangulation[triangle.id] = nil
        end

        for _, edge in ipairs(polygon) do -- re-triangulate the polygonal hole
            local newTri = formTriangle(edge, point)
            triangulation[newTri.id] = newTri
        end
    end

    for _, triangle in pairs(triangulation) do -- done inserting points, now clean up
        if not triangle then goto continue end
        if hasCommonVertex(triangle, superTrinagle) then --false
            triangulation[triangle.id] = nil
        end
        ::continue::
    end
    return triangulation, pointList
end

function Diagram:getDiagramDelone(points)
    self:clear()
    local triangles, sites = Delone.BowyerWatsonDeloneTriangulation(points)

    for _, site in ipairs(sites) do
        self:insertVertex(site)
    end

    for _, triangle in pairs(triangles) do
        for _, edge in ipairs(triangle.edges) do
            self:insertEdge(edge.a, edge.b)
        end
    end
end

return Delone