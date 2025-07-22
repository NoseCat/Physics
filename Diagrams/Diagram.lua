local Object = require('Object.Object')
local UniqueSet = require('DataStructure.UniqueSet')

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

function Edge:hash(margin)
    local ha, hb = self.a:hash(margin), self.b:hash(margin)
    return ha < hb and ha.."|"..hb or hb.."|"..ha
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
        edge:draw(thickness, r, g, b, a/2)
    end
end

function Cell:hash(margin)
   return self.site:hash(margin)
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
function Diagram:new(margin)
    local obj = Object.new(self)

    obj.rawData = nil
    obj.vertexes = UniqueSet:new() --points
    obj.edges = UniqueSet:new()
    obj.cells = UniqueSet:new()

    obj.margin = margin or 1e-5

    return obj
end

function Diagram:clear()
    self.vertexes:clear()
    self.edges:clear()
    self.cells:clear()
end

function Diagram:insertVertex(point)
    self.vertexes:insert(point, self.margin)
end

function Diagram:insertEdge(a,b)
    self.edges:insert(Edge:new(a,b))
end

function Diagram:insertCell(site, edges)
    local cell = Cell:new(site)
    for _, edge in ipairs(edges) do
        table.insert(cell.edges, Edge:new(edge.a, edge.b))
    end
    self.cells:insert(cell)
end

function Diagram:drawVertexes(size, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    for _, vertex in pairs(self.vertexes.array) do
        love.graphics.circle("fill", vertex.x, vertex.y, size)
    end
end

function Diagram:drawEdges(thickness, r, g, b, a)
    for _, edge in pairs(self.edges.array) do
        edge:draw(thickness, r, g, b, a)
    end
end

function Diagram:drawCells(siteSize, thickness, r, g, b, a)
    for _, cell in pairs(self.cells.array) do
        cell:draw(siteSize, thickness, r, g, b, a)
    end
end

return Diagram