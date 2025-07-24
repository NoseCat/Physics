Static = require('Object.PhysicsObject.TexturedStaticBody')
Dynamic = require('Object.PhysicsObject.TexturedDynamicBody')
Soft = require('Object.PhysicsObject.TexturedSoftBody')

ItemCreator = {}
ItemCreator.__index = ItemCreator
function ItemCreator.create(itemName, x, y)
    if itemName == "box1" then
        local box = Dynamic:new(x, y, 5, love.graphics.newImage("Sprites/CheckerBoard1.png"))
        box:addPoint(20, -20)
        box:addPoint(20, 20)
        box:addPoint(-20, 20)
        box:addPoint(-20, -20)
        return box
    end
    if itemName == "box2" then
        local box = Dynamic:new(x, y, 15, love.graphics.newImage("Sprites/CheckerBoard2.png"))
        box:addPoint(20, -20)
        box:addPoint(20, 20)
        box:addPoint(-20, 20)
        box:addPoint(-20, -20)
        return box
    end
end

return ItemCreator