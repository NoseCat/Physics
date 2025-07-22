BaseDiagram = require('Diagrams.Diagram')
Voronoi = require('Diagrams.VoronoiDiagram')

VoronoiObjectDiagram = setmetatable({}, { __index = BaseDiagram })
VoronoiObjectDiagram.__index = VoronoiObjectDiagram
function VoronoiObjectDiagram:new(points)
    local obj = BaseDiagram.new(self)

    obj.size = #points
    obj.prevMouse = Vector:new(400, 300)

    obj.perimeterPoints = {}
    for i = 1, 16, 1 do
        local angle = (i / 16) * math.pi * 2
        local x = math.cos(angle) * 600
        local y = math.sin(angle) * 600
        obj.perimeterPoints[i] = Vector:new(400, 300) + Vector:new(x, y)
    end

    obj:getDiagramVoronoi(points)

    return obj
end

function VoronoiObjectDiagram:update(delta)
    local points = {}
    for _, cell in pairs(self.cells.array) do
        if cell.site:isEqual(self.prevMouse, 1e-5) then goto continue end
        for _, point in ipairs(self.perimeterPoints) do
            if cell.site:isEqual(point, 1e-5) then goto continue end
        end

        -- local mid = Vector:new(0,0)
        -- local count = 0
        -- for _, edge in ipairs(cell.edges) do
        --     count = count + 1
        --     mid = mid + edge.a
        -- end
        -- mid = mid / count
        table.insert(points, cell.site )-- + (mid - cell.site) * 0.25 * delta)
        ::continue::
    end

    local mx, my = love.mouse.getPosition()
    local mouse = Vector:new(mx,my)
    mouse = self.prevMouse + (mouse - self.prevMouse) * 0.5 * delta
    self.prevMouse = mouse

    for _, point in ipairs(self.perimeterPoints) do
        table.insert(points, point)
    end
    table.insert(points, mouse)

    self:getDiagramVoronoi(points)
end

function VoronoiObjectDiagram:draw()
    self:drawCells(4, 1, 0.8, 0.8, 0.8, 0.5)
end

return VoronoiObjectDiagram