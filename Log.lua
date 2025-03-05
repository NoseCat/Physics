--local LOG = require('Log')
--local Log = LOG:getInstance()
--LOG = nil

local Log = {}
Log.__index = Log

local instance = nil

function Log:getInstance()
    if instance then
        return instance
    end

    local sTone = setmetatable({}, Log)
    sTone.msgs = {}
    sTone.file = io.open("log.txt", "w") -- TODO new logs each launch
    if not sTone.file then
        error("Failed to open log file")
    end

    instance = sTone

    -- local function onExit()
    --     instance:flush()
    -- end

    -- Register the exit handler for Love2D
    -- if love and love.event then
    --     love.quit = function()
    --         onExit()
    --     end
    -- end

    return instance
end

function Log:add(message)
    table.insert(self.msgs, message)
end

function Log:flush()
    if self.file then
        for _, msg in ipairs(self.msgs) do
            self.file:write(msg .. "\n")
        end
        self.file:flush() -- Ensure all data is written to the file
        self.msgs = {}    -- Clear the queue
    end
end

function Log:close()
    if self.file then
        self:flush()  -- Flush any remaining messages
        self.file:close()  -- Close the file
        self.file = nil  -- Mark the file as closed
    end
end

-- function Log:print()
--     for _, msg in ipairs(self.msgs) do
--         print(msg)
--     end
-- end

return Log