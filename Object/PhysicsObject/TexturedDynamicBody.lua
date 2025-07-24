DynamicBody = require('Object.PhysicsObject.DynamicBody')

local TexturedDB = setmetatable({}, { __index = DynamicBody })
TexturedDB.__index = TexturedDB
function TexturedDB:new(a, b, m, sprite)
    local obj = DynamicBody.new(self, a, b, m)

    obj.sprite = sprite

    return obj
end

function TexturedDB:updateConstants()
    DynamicBody.updateConstants(self)
    self.bbox:updatePoints(self:getRealPoints())
    self.quad = love.graphics.newQuad(0, 0,
    self.bbox.pointB.x - self.bbox.pos.x, self.bbox.pos.y - self.bbox.pointB.y,
    self.bbox.pointB.x - self.bbox.pos.x, self.bbox.pos.y - self.bbox.pointB.y)

    local spritePos = Vector:new(self.bbox.pos.x, self.bbox.pos.y - (self.bbox.pos.y - self.bbox.pointB.y))
    self.spriteCenter = self:getRealCenter() - spritePos
end

function TexturedDB:draw()
    local triangles = self:triangulate()
    love.graphics.stencil(function()
        love.graphics.setColor(1,1,1)
        for _, triangle in ipairs(triangles) do
            local points = {}
            for _, point in ipairs(triangle) do
                table.insert(points, point.x)
                table.insert(points, point.y)
            end
            love.graphics.polygon("fill", points)
        end
    end, "replace", 1)

    -- 2. Only draw where stencil value is 1
    love.graphics.setStencilTest("equal", 1)
    local curCenter = self:getRealCenter()
    love.graphics.draw(self.sprite, self.quad, curCenter.x, curCenter.y,
    self.rot, 1, 1, self.spriteCenter.x, self.spriteCenter.y) --setting origin to center
    love.graphics.setStencilTest() -- Disable stencil
end

return TexturedDB