SoftBody = require('Object.PhysicsObject.SoftBody')

local TexturedSoftBody = setmetatable({}, { __index = SoftBody })
TexturedSoftBody.__index = TexturedSoftBody
function TexturedSoftBody:new(a, b, m, sprite)
    local obj = SoftBody.new(self, a, b, m)

    obj.sprite = sprite

    return obj
end

local function findMinMaxProjections(points, rotation)
    local primDir = Vector:new(1, 0):rotate(rotation)
    local perpDir = primDir:perp()

    local minPrim, maxPrim = math.huge, -math.huge
    local minPerp, maxPerp = math.huge, -math.huge

    for _, point in ipairs(points) do
        local projPrim = point:dot(primDir)
        minPrim = math.min(minPrim, projPrim)
        maxPrim = math.max(maxPrim, projPrim)

        local projPerp = point:dot(perpDir)
        minPerp = math.min(minPerp, projPerp)
        maxPerp = math.max(maxPerp, projPerp)
    end
    return {
        prim = {min = minPrim, max = maxPrim},
        perp = {min = minPerp, max = maxPerp}
    }
end

function TexturedSoftBody:draw()
    local realPoints = self:getRealPoints()
    local points = {}
    local center = self:getRealCenter()
    for _, point in ipairs(realPoints) do
        table.insert(points, point - center)
    end
    local size = findMinMaxProjections(points, self.rot)
    local width = (size.prim.max - size.prim.min)
    local height = (size.perp.max - size.perp.min)

    local quad = love.graphics.newQuad(0, 0, width, height, width, height)
    local spriteCenter = Vector:new(width/2, height/2)

    love.graphics.stencil(function()
        love.graphics.setColor(1,1,1)
        local points = {}
        for _, point in ipairs(realPoints) do
            table.insert(points, point.x)
            table.insert(points, point.y)
        end
        love.graphics.polygon("fill", points) --can potentially cause crashes if lines intersect
    end, "replace", 1)

    -- 2. Only draw where stencil value is 1
    love.graphics.setStencilTest("equal", 1)
    local curCenter = self:getRealCenter()
    love.graphics.draw(self.sprite, quad, curCenter.x, curCenter.y,
    self.rot, 1, 1, spriteCenter.x, spriteCenter.y) --setting origin to center
    love.graphics.setStencilTest() -- Disable stencil
end

return TexturedSoftBody