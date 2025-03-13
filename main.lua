require('Math.Vector')

require('Object.Object')
require('Object.Shape')
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
    s1 = Shape:new(200,200)
    s1:addPoint(40,0)
    s1:addPoint(-40,0)
    s1:addPoint(0,40)
    s2 = Shape:new(150,155)
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
    s2.pos.x, s2.pos.y = love.mouse.getPosition()
    --collision = Collide(s1,s2)

    OM:update(dt)
    PM:iterate()
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    OM:draw()
    love.graphics.setLineWidth(1)

    --debug
    -- if collision.isCollided then
    --     love.graphics.setColor(1, 1, 1)
    --     love.graphics.print("FPS: " .. love.timer.getFPS())
    --     love.graphics.line(s1.pos.x, s1.pos.y, collision.mtv.x + s1.pos.x, collision.mtv.y + s1.pos.y)
    --     love.graphics.circle("fill", collision.point.x,  collision.point.y, 5)
    -- end

    local curTime = love.timer.getTime()
    if NextTime <= curTime then
        NextTime = curTime
        return
    end
    love.timer.sleep(NextTime - curTime)
end
