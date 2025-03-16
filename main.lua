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
local showDebugInfo = true

function love.load()
    love.window.setTitle("Physics")
    love.window.setMode(800, 600)

    --test
    -- Create a static floor
    floor = PhysicsBody:new(400, 580, 1)
    floor:addPoint(400, 0)
    floor:addPoint(-400, 0)
    floor:addPoint(-400, 20)
    floor:addPoint(400, 20)
    floor.static = true

    s1 = PhysicsBody:new(200,200, 10)
    s1:addPoint(40,0)
    s1:addPoint(-40,0)
    s1:addPoint(0,40)
    s2 = PhysicsBody:new(150,155, 2)
    s2:addPoint(80,0)
    s2:addPoint(20,-60)
    s2:addPoint(-40,0)
    s2:addPoint(20,60)
    s2.rot = s2.rot + math.pi/4
    s2.pos.y = s2.pos.y + 10
    --s1.static = true
    NextTime = love.timer.getTime()
end

local logFlushAcc = 0
local logFlushTime = 5
function love.update(dt)
    NextTime = NextTime + 1 / FPSLimit

    logFlushAcc = logFlushAcc + dt
    if logFlushAcc > logFlushTime then
        Log:flush()
    end

    --test
    --s2.rot = s2.rot + dt/2
    local mx, my = love.mouse.getPosition()
    if love.mouse.isDown(1) then
        s2:applyForce((Vector:new(mx,my) - (s2.center + s2.pos)):normalized() * 100)
        s1:applyForceAtPoint(Vector:new(0,-1) * 100, Vector:new(mx,my))
    end

    OM:update(dt)
    PM:iterate(dt, 3)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    OM:draw()
    love.graphics.setLineWidth(1)

    --debug
    print(s1.vel:len())

    local curTime = love.timer.getTime()
    if NextTime <= curTime then
        NextTime = curTime
        return
    end
    love.timer.sleep(NextTime - curTime)
end
