require('Math.Vector')
local Delone = require('Diagrams.DeloneTriangualtion')
local Diagram = require('Diagrams.Diagram')
local Vector = require('Math.Vector')

-- Voronoi Diagram Implementation
local Voronoi = {}

local function isPointInTriangle(point, triangle)
    local vertexes = {triangle.edges[1].a, triangle.edges[1].b, triangle.edges[2].b }
    for _, vertex in ipairs(vertexes) do
        if point:isEqual(vertex, 1e-5) then
            return true
        end
    end
    return false
end

local function sortPointsAround(points, center)
    -- Create a copy of the points array to avoid modifying the original
    local sortedPoints = {}
    for i, point in ipairs(points) do
        sortedPoints[i] = point
    end

    -- Calculate angles relative to center and sort
    table.sort(sortedPoints, function(a, b)
        local vecA = a - center
        local vecB = b - center
        
        -- Use the angleFull method which gives -π to π range
        local angleA = vecA:angleFull(Vector:new(1, 0))  -- Angle relative to positive x-axis
        local angleB = vecB:angleFull(Vector:new(1, 0))
        
        -- Convert to 0-2π range for consistent sorting
        if angleA < 0 then angleA = angleA + 2 * math.pi end
        if angleB < 0 then angleB = angleB + 2 * math.pi end
        
        -- Sort by angle
        return angleA < angleB
    end)

    return sortedPoints
end

function Voronoi.getThroughDelone(sites)
    local voronoiCells = {}
    local delone = Delone.BowyerWatsonDeloneTriangulation(sites)

    -- find all circumcenters (Voronoi vertices)
    local circumcenters = {}
    for _, triangle in pairs(delone) do
        local a, b, c = triangle.edges[1].a, triangle.edges[1].b, triangle.edges[2].b
        local circumcenter = getCircumcircle(a, b, c)
        table.insert(circumcenters, {triangle = triangle, center = circumcenter})
    end

    for _, site in pairs(sites) do
        local cellEdges = {}

        local sitePoly = {}
        for _, data in pairs(circumcenters) do
            if isPointInTriangle(site, data.triangle) then
                table.insert(sitePoly, data.center)
            end
        end

        sitePoly = sortPointsAround(sitePoly, site)
        -- Connect the circumcenters of adjacent triangles to form the cell
        for i = 1, #sitePoly do
            local nextIdx = (i % #sitePoly) + 1
            table.insert(cellEdges, {
                a = sitePoly[i],
                b = sitePoly[nextIdx]
            })
        end

        table.insert(voronoiCells, {
            site = site,
            edges = cellEdges
        })
    end
    return voronoiCells, sites
end

function Diagram:getDiagramVoronoi(sites)
    self:clear()
    local rawOutput = Voronoi.getThroughDelone(sites)
    for _, cell in ipairs(rawOutput) do
        for _, edge in ipairs(cell.edges) do
            --vertexes
            self:insertVertex(edge.a)
            self:insertVertex(edge.b)
            --edges
            self:insertEdge(edge.a, edge.b)
        end
        --cells
        self:insertCell(cell.site, cell.edges)
    end
end

return Voronoi