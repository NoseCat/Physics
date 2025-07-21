local Object = require('Object.Object')

local Edge = {}
Edge.__index = Edge
function Edge:new(a,b)
    local obj = setmetatable({}, self)

    obj.a = a
    obj.b = b

    return obj
end

function Edge:draw(thickness, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(thickness)
    love.graphics.line(self.a.x, self.a.y, self.b.x, self.b.y)
end

local Cell = {}
Cell.__index = Cell
function Cell:new(site)
    local obj = setmetatable({}, self)

    obj.site = site
    obj.edges = {}

    return obj
end

function Cell:draw(vertexesize, thickness, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    love.graphics.circle("fill", self.site.x, self.site.y, vertexesize)
    for _, edge in ipairs(self.edges) do
        edge:draw(thickness, r, g, b, a)
    end
end

-- function Cell:getVertexes()
--     local vertexes = {}
--     for _, edge in ipairs(self.edges) do
--         --table.insert(vertexes, edge.a)
--         table.insert(vertexes, edge.b) --??
--     end
--     return vertexes
-- end

Diagram = setmetatable({}, { __index = Object })
Diagram.__index = Diagram
function Diagram:new()
    local obj = Object.new(self)

    obj.vertexes = {} --points
    obj.edges = {}
    obj.cells = {}

    return obj
end

function Diagram:clear()
    self.vertexes = {}
    self.edges = {}
    self.cells = {}
end

function Diagram:insertVertex(point)
    for _, vertex in ipairs(self.vertexes) do
        if vertex:isEqual(point, 1e-5) then return end
    end
    table.insert(self.vertexes, point)
end

function Diagram:insertEdge(a,b)
    for _, edge in ipairs(self.edges) do
        if (edge.a:isEqual(a, 1e-5) and edge.b:isEqual(b, 1e-5))
        or (edge.a:isEqual(b, 1e-5) and edge.b:isEqual(a, 1e-5)) then
            return
        end
    end
    table.insert(self.edges, Edge:new(a,b))
end

function Diagram:insertCell(site, edges)
    local cell = Cell:new(site)
    for _, edge in ipairs(edges) do
        table.insert(cell.edges, Edge:new(edge.a, edge.b))
    end
    table.insert(self.cells, cell)
end

function Diagram:drawVertexes(size, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    for _, vertex in ipairs(self.vertexes) do
        love.graphics.circle("fill", vertex.x, vertex.y, size)
    end
end

function Diagram:drawEdges(thickness, r, g, b, a)
    for _, edge in ipairs(self.edges) do
        edge:draw(thickness, r, g, b, a)
    end
end

function Diagram:drawCells(siteSize, thickness, r, g, b, a)
    if not self.cells then return end
    for _, cell in ipairs(self.cells) do
        cell:draw(siteSize, thickness, r, g, b, a)
    end
end

return Diagram