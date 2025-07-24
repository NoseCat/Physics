
--WARNING
--all this code is messy, needs adjustments and could use some cleaning
--thread lightly

require('Math.Vector')

Creator = require('Item.Creator')

require('Interaction.Collision')
local OBJECTMANAGER = require('Object.Manager')
OM = OBJECTMANAGER:getInstance()
local PHYSICSMANAGER = require('Object.PhysicsManager')
local PM = PHYSICSMANAGER:getInstance()

local Voronoi = require('Diagrams.VoronoiObject')

local LOG = require('Debug.Log')
Log = LOG:getInstance()

local FPSLimit = 60

function love.load()
    love.window.setTitle("Physics")
    love.window.setMode(800, 600)

    local points = {}
    for i = 1, 15, 1 do
        table.insert(points, Vector:new(math.random(800), math.random(600)))
    end
    --test
    local dia = Voronoi:new(points)

    floor = StaticBody:new(400, 580)
    floor:addPoint(-400, -20)
    floor:addPoint(400, -20)
    floor:addPoint(400, 120)
    floor:addPoint(-400, 120)

    leftWall = StaticBody:new(-10, 300)
    leftWall:addPoint(-100, -300)
    leftWall:addPoint(20, -300)
    leftWall:addPoint(20, 300)
    leftWall:addPoint(-100, 300)

    rightWall = StaticBody:new(790, 300)
    rightWall:addPoint(0, -300)
    rightWall:addPoint(120, -300)
    rightWall:addPoint(120, 280)
    rightWall:addPoint(0, 280)

    local NoseCat = love.graphics.newImage("Sprites/NoseCat.png")
    -- s1 = TexturedDynamicBody:new(400,200, 5, NoseCat)
    -- for i = 0, 3 - 1 do
    --     local angle = (i / 3) * math.pi * 2
    --     local x = math.cos(angle) * 50
    --     local y = math.sin(angle) * 50
    --     s1:addPoint(x, y)
    -- end
    -- s2 = TexturedDynamicBody:new(150,200, 2, NoseCat)
    -- s2:addPoint(80,0)
    -- s2:addPoint(20,-60)
    -- s2:addPoint(-40,0)
    -- s2:addPoint(20,60)
    -- s2.rot = s2.rot + math.pi/4
    -- s2.rotVel = 10
    -- s2.pos.y = s2.pos.y + 10
    -- cube = StaticBody:new(380, 440)
    -- cube:addPoint(-40, -40)
    -- cube:addPoint(40, -40)
    -- cube:addPoint(40, 40)
    -- cube:addPoint(-40, 40)

    -- bowl = TexturedStaticBody:new(100, 0, NoseCat)
    -- bowl:addPoint(50, 0)
    -- bowl:addPoint(75, 40)
    -- bowl:addPoint(75, 80)
    -- bowl:addPoint(65, 80)
    -- bowl:addPoint(55, 20)
    -- bowl:addPoint(-55, 20)
    -- bowl:addPoint(-65, 80)
    -- bowl:addPoint(-75, 80)
    -- bowl:addPoint(-75, 40)
    -- bowl:addPoint(-50, 0)
    -- bowl2 = DynamicBody:new(300, 0, 10)
    -- bowl2:addPoint(50, 0)
    -- bowl2:addPoint(75, 40)
    -- bowl2:addPoint(75, 80)
    -- bowl2:addPoint(65, 80)
    -- bowl2:addPoint(55, 20)
    -- bowl2:addPoint(-55, 20)
    -- bowl2:addPoint(-65, 80)
    -- bowl2:addPoint(-75, 80)
    -- bowl2:addPoint(-75, 40)
    -- bowl2:addPoint(-50, 0)

    -- s3 = TexturedSoftBody:new(600,200, 5, NoseCat)
    -- local pointCount = 20
    -- local radius = 80
    -- for i = 0, pointCount - 1 do
    --     local angle = (i / pointCount) * math.pi * 2
    --     local x = math.cos(angle) * radius
    --     local y = math.sin(angle) * radius
    --     s3:addPoint(x, y)
    -- end
    -- s4 = SoftBody:new(600,0, 10)
    -- for i = 0, pointCount - 1 do
    --     local angle = (i / pointCount) * math.pi * 2
    --     local x = math.cos(angle) * radius
    --     local y = math.sin(angle) * radius
    --     s4:addPoint(x, y)
    -- end

    NextTime = love.timer.getTime()
end

local logFlushAcc = 0
local logFlushTime = 5
local Delta = 0

local grabPoint = Vector:new(0,0)
local grab = false
local grabbed = nil
local grabRotation = 0

local spamPrevention = false
function love.update(dt)
    Delta = dt
    NextTime = NextTime + 1 / FPSLimit

    logFlushAcc = logFlushAcc + dt
    if logFlushAcc > logFlushTime then
        Log:flush()
    end

    --test
    local mx, my = love.mouse.getPosition()
    mouse = Vector:new(mx,my)

    for _, obj in ipairs(PM.objs) do
        if obj:containsPoint(mouse) and love.mouse.isDown(1) and not grab then
            grabPoint = mouse - obj:getRealCenter()
            grabRotation = obj.rot
            grab = true
            grabbed = obj
            grabbed.bbox.on = true
            break
        end
    end
    if not love.mouse.isDown(1) then
        grab = false
        grabRotation = 0
        if grabbed then
            grabbed.bbox.on = false
        end
        grabbed = nil
    end
    if grab and grabbed and love.mouse.isDown(1) then
        grabbed:applyForceAtPoint((mouse - (grabbed:getRealCenter() + grabPoint:rotate(grabbed.rot - grabRotation))) * 10, grabbed:getRealCenter() + grabPoint:rotate(grabbed.rot - grabRotation))
    end

    if not love.mouse.isDown(1) and spamPrevention  then
        spamPrevention = false
    end
    if love.mouse.isDown(1) and not spamPrevention then
        spamPrevention = true
        if math.random(0,1) == 0 then
            Creator.create("box1", mouse.x, mouse.y)
        else
            Creator.create("box2", mouse.x, mouse.y)
        end
    end

    OM:update(dt)
    PM:iterate(dt, 5)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    OM:draw()

    --test
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.9, 0.9, 0.9)
    if love.mouse.isDown(1) and grab and grabbed then
        local point = grabbed:getRealCenter() + grabPoint:rotate(grabbed.rot - grabRotation)
        love.graphics.line(point.x, point.y, mouse.x, mouse.y)
    end

    love.graphics.print(string.format( "%.2g", Delta), 15)

    local curTime = love.timer.getTime()
    if NextTime <= curTime then
        NextTime = curTime
        return
    end
    love.timer.sleep(NextTime - curTime)
end