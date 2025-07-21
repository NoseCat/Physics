local AVLTree = {}
AVLTree.__index = AVLTree

-- Вспомогательная функция для создания узла
local function Node(key, value)
    return {
        key = key,
        value = value,
        left = nil,
        right = nil,
        height = 1
    }
end

-- Получение высоты узла (с обработкой nil)
local function getHeight(node)
    return node and node.height or 0
end

-- Обновление высоты узла
local function updateHeight(node)
    node.height = math.max(getHeight(node.left), getHeight(node.right)) + 1
end

-- Вычисление баланс-фактора
local function balanceFactor(node)
    return getHeight(node.left) - getHeight(node.right)
end

-- Правый поворот
local function rotateRight(y)
    local x = y.left
    local T = x.right

    x.right = y
    y.left = T

    updateHeight(y)
    updateHeight(x)
    return x
end

-- Левый поворот
local function rotateLeft(x)
    local y = x.right
    local T = y.left

    y.left = x
    x.right = T

    updateHeight(x)
    updateHeight(y)
    return y
end

-- Балансировка узла
local function balance(node)
    if not node then return nil end

    updateHeight(node)
    local bf = balanceFactor(node)

    -- Левый случай
    if bf > 1 then
        if balanceFactor(node.left) < 0 then
            node.left = rotateLeft(node.left)
        end
        return rotateRight(node)
    end

    -- Правый случай
    if bf < -1 then
        if balanceFactor(node.right) > 0 then
            node.right = rotateRight(node.right)
        end
        return rotateLeft(node)
    end

    return node
end

-- Создание нового AVL-дерева
function AVLTree:new()
    return setmetatable({ root = nil }, self)
end

-- Рекурсивная вставка
local function insertRec(root, key, value)
    if not root then
        return Node(key, value)
    end

    if key < root.key then
        root.left = insertRec(root.left, key, value)
    elseif key > root.key then
        root.right = insertRec(root.right, key, value)
    else
        root.value = value -- Обновление значения
        return root
    end

    return balance(root)
end

-- Вставка элемента
function AVLTree:insert(key, value)
    self.root = insertRec(self.root, key, value)
end

-- Поиск минимального узла
local function findMin(node)
    while node and node.left do
        node = node.left
    end
    return node
end

-- Рекурсивное удаление
local function removeRec(root, key)
    if not root then return nil end

    if key < root.key then
        root.left = removeRec(root.left, key)
    elseif key > root.key then
        root.right = removeRec(root.right, key)
    else
        -- Узел с одним потомком или без
        if not root.left then
            return root.right
        elseif not root.right then
            return root.left
        end

        -- Узел с двумя потомками
        local temp = findMin(root.right)
        local successorKey = temp.key
        local successorValue = temp.value
        root.right = removeRec(root.right, successorKey)
        root.key = successorKey
        root.value = successorValue
    end

    return balance(root)
end

-- Удаление элемента
function AVLTree:remove(key)
    self.root = removeRec(self.root, key)
end

-- Рекурсивный поиск
local function searchRec(root, key)
    if not root then return nil end
    if key == root.key then return root.value end
    return searchRec(key < root.key and root.left or root.right, key)
end

-- Поиск элемента
function AVLTree:search(key)
    return searchRec(self.root, key)
end

-- In-order обход (слева-направо)
local function inorderRec(root, result)
    if root then
        inorderRec(root.left, result)
        table.insert(result, {key = root.key, value = root.value})
        inorderRec(root.right, result)
    end
end

-- Проверка, пустое ли дерево
function AVLTree:isEmpty()
    return self.root == nil
end

-- Получение всех элементов в отсортированном порядке
function AVLTree:inorder()
    local result = {}
    inorderRec(self.root, result)
    return result
end

-- Проверка сбалансированности дереaва (для тестов)
function AVLTree:isBalanced()
    local function check(node)
        if not node then return true, 0 end
        
        local leftBalanced, leftHeight = check(node.left)
        local rightBalanced, rightHeight = check(node.right)
        
        local balanced = leftBalanced and rightBalanced and
                         math.abs(leftHeight - rightHeight) <= 1
        local height = math.max(leftHeight, rightHeight) + 1
        
        return balanced, height
    end
    
    return check(self.root)
end

return AVLTree