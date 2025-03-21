require('Math.Vector')

require('Object.Object')
Shape = require('Object.Shape')
PhysicsBody = require('Object.PhysicsBody')
local OBJECTMANAGER = require('Object.Manager')
OM = OBJECTMANAGER:getInstance()
local PHYSICSMANAGER = require('Object.PhysicsManager')
local PM = PHYSICSMANAGER:getInstance()

require('Interaction.Collision')

local LOG = require('Debug.Log')
Log = LOG:getInstance()

local FPSLimit = 60

function love.load()
    love.window.setTitle("Physics")
    love.window.setMode(800, 600)

    --test
    -- Create a static floor
    floor = PhysicsBody:new(400, 580, 1000)
    floor:addPoint(400, 0)
    floor:addPoint(-400, 0)
    floor:addPoint(-400, 20)
    floor:addPoint(400, 20)
    floor.static = true

    s1 = PhysicsBody:new(400,200, 10)
    s1:addPoint(40,0)
    s1:addPoint(-40,0)
    s1:addPoint(0,40)
    --s1.force = Vector:new(-500000, 0)
    s2 = PhysicsBody:new(150,200, 2)
    s2:addPoint(80,0)
    s2:addPoint(20,-60)
    s2:addPoint(-40,0)
    s2:addPoint(20,60)
    s2.rot = s2.rot + math.pi/4
    s2.rotVel = 10
    s2.pos.y = s2.pos.y + 10
    --s2.force = Vector:new(500000, 0)
    s3 = PhysicsBody:new(600,200, 5)
    s3:addPoint(-60,60)
    s3:addPoint(-100,0)
    s3:addPoint(-60,-60)
    s3:addPoint(60,-60)
    s3:addPoint(100,0)
    s3:addPoint(60,60)

    NextTime = love.timer.getTime()
end

local logFlushAcc = 0
local logFlushTime = 5

local grabPoint = Vector:new(0,0)
local grab = false
local grabbed = nil
local grabRotation = 0
function love.update(dt)
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
            grabPoint = mouse - (obj.pos + obj.center)
            grabRotation = obj.rot
            grab = true
            grabbed = obj
            break
        end
    end
    if not love.mouse.isDown(1) then
        grab = false
        grabRotation = 0
        grabbed = nil
    end
    if grab and grabbed and love.mouse.isDown(1) then
        grabbed:applyForceAtPoint((mouse - (grabbed.pos + grabbed.center + grabPoint:rotate(grabbed.rot - grabRotation))) * 50, grabbed.pos + grabbed.center + grabPoint:rotate(grabbed.rot - grabRotation))
    end

    OM:update(dt)
    PM:iterate(dt, 3)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    OM:draw()
    love.graphics.setLineWidth(1)
    if love.mouse.isDown(1) and grab and grabbed then
        local point = grabbed.pos + grabbed.center + grabPoint:rotate(grabbed.rot - grabRotation)
        love.graphics.line(point.x, point.y, mouse.x, mouse.y)
    end

    local curTime = love.timer.getTime()
    if NextTime <= curTime then
        NextTime = curTime
        return
    end
    love.timer.sleep(NextTime - curTime)
end
