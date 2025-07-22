UniqueSet = {}
UniqueSet.__index = UniqueSet
function UniqueSet:new()
    local newSet = setmetatable({}, self)

    newSet.array = {}

    return newSet
end

function UniqueSet:insert(value, margin)
    margin = margin or 0
    local key = value:hash(margin)

    if self.array[key] then return false end

    self.array[key] = value
    return true
end

function UniqueSet:contains(value, margin)
    margin = margin or 0
    return self.array[value:hash(margin)] ~= nil
end

function UniqueSet:remove(value, margin)
    margin = margin or 0
    self.array[value:hash(margin)] = nil
end

function UniqueSet:size()
    local count = 0
    for _ in pairs(self.array) do
        count = count + 1
    end
    return count
end

function UniqueSet:clear()
    for k in pairs(self.array) do
        self.array[k] = nil
    end
end

local function deepHash(value, margin)
    margin = margin or 0
    local ty = type(value)

    if ty == "number" then
        -- For numbers, apply margin and ensure integer hash
        return math.floor(value + margin)
    elseif ty == "string" then
        -- For strings, use a simple hash (similar to Java's String.hashCode)
        local hash = 0
        for i = 1, #value do
            hash = 31 * hash + string.byte(value, i)
        end
        return hash + margin
    elseif ty == "boolean" then
        -- Booleans: 1 for true, 0 for false
        return (value and 1 or 0) + margin
    elseif ty == "table" then
        -- For tables, recursively hash keys and values
        local hash = 0
        for k, v in pairs(value) do
            hash = hash + deepHash(k, margin) * 31 + deepHash(v, margin)
        end
        return hash
    elseif ty == "nil" then
        return 0 + margin
    else
        -- For functions, userdata, etc., fall back to tostring + string hash
        return deepHash(tostring(value), margin)
    end
end

return UniqueSet