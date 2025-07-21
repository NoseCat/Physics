local PriorityQueue = {}
function PriorityQueue:new()
    local newObj = {elements = {}}
    self.__index = self
    return setmetatable(newObj, self)
end

function PriorityQueue:push(item, priority)
    table.insert(self.elements, {item = item, priority = priority})
    table.sort(self.elements, function(a, b) return a.priority < b.priority end)
end

function PriorityQueue:pop()
    if #self.elements == 0 then return nil end
    return table.remove(self.elements, 1).item
end

function PriorityQueue:peek()
    if #self.elements == 0 then return nil end
    return self.elements[1].item, self.elements[1].priority
end

function PriorityQueue:isEmpty()
    return #self.elements == 0
end

function PriorityQueue:remove(item)
    for index, itemInList in ipairs(self.elements) do
        if itemInList == item then
            table.remove(self.elements, index)
        end
    end
end

return PriorityQueue