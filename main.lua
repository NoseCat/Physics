require('Math.Vector')

require('Object.Object')
require('Object.Shape')
local OBJECTMANAGER = require('Object.Manager')
OM = OBJECTMANAGER:getInstance()

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
    s2:addPoint(60,0)
    s2:addPoint(0,-60)
    s2:addPoint(-60,0)
    s2:addPoint(0,60)
    s3 = Shape:new(400,400)

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
    s2.rot = s2.rot + dt
    showDebugInfo, colPoint, distance = GJKCheckCollision(s1, s2)
    s3.points = MinkowskyDif(s1, s2)

    OM:update(dt)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    OM:draw()
    love.graphics.setLineWidth(1)

    --debug
    if showDebugInfo then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("FPS: " .. love.timer.getFPS())
        --colPsoint.x = -(colPoint.x)
        if colPoint then
            love.graphics.print("\nColPoint: " .. colPoint.x .. " " .. colPoint.y)
            love.graphics.print("\n\nDistance: " .. distance)
            colPoint = colPoint * distance + s1.pos
            love.graphics.circle("line", colPoint.x, colPoint.y, 10)
        end
        --love.graphics.print("\nFPS (average delta): " .. 1/love.timer.getAverageDelta())
    end

    local curTime = love.timer.getTime()
    if NextTime <= curTime then
        NextTime = curTime
        return
    end
    love.timer.sleep(NextTime - curTime)
end
