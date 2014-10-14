local M = {}

function M.printTable(T)
    for _,line in pairs(T) do
        if type(line) == "table" then
            M.printTable(line)
        else
            print(line)
        end
    end
end

function indentString(indent)
    local indentString = "  "
    for i=1,indent do
        indentString = indentString .. "  "
    end
    return indentString
end

function M.tableString(T, indent)
    indent = indent or 0
    local string = "{\n"
    for key, value in pairs(T) do
        if type(value) == "table" then
            string = string .. indentString(indent) .. key .. "= " .. M.tableString(value, indent + 1) .. "\n"
        elseif type(value) == "boolean" then
            string = string .. indentString(indent) .. key .. "= " .. (value and "true" or "false") .. ",\n"
        else
            string = string .. indentString(indent) .. key .. "= " .. value .. ",\n"
        end
    end
    string = string .. indentString(indent) ..  "},"
    return string
end

function M.tableHasContent(T)
    local hasContent = false
    for _ in pairs(T) do
        hasContent = true
        break
    end
    return hasContent
end

function M.count(t1, t2)
    local count = 0
    for _ in pairs(t1) do
        count = count + 1
    end
    return count
end

function M.split(S, separator)
    local begin = 1
    local index = string.find(S, separator, begin, true)
    local array = {}
    while index do
        local sub = string.sub(S, begin, index - 1)
        table.insert(array, sub)
        begin = index + string.len(separator)
        index = string.find(S, separator, begin, true)
    end

    if table.getn(array) == 0 then
        table.insert(array, S)
    else
        local sub = string.sub(S, begin)
        table.insert(array, sub)
    end

    return array
end

function M.filter(T, func)
    local filtered = {}
    for _, value in pairs(T) do
        if func(value) then
            table.insert(filtered, value)
        end
    end
    return filtered
end

function M.trim(S)
    return string.match(S, "^%s*(.-)%s*$")
end

function M.setMetatableRecursively(T, metatable)
    setmetatable(T, metatable)
    for _,value in pairs(T) do
        if type(value) == "table" then
            M.setMetatableRecursively(value, metatable)
        end
    end
end

function M.equal(t1, t2)
    for key1, value1 in pairs(t1) do
        local result = false
        for key2, value2 in pairs(t2) do
            if key1 == key2 and value1 == value2 then
                result = true
                break
            end
        end
        if not result then
            return false
        end
    end
    if M.count(t1) ~= M.count(t2) then
        return false
    else
        return true
    end
end

function M.subTable(t, i, j)
    local sub = {}
    for k=i,j do
        table.insert(sub, t[k])
    end
    return sub
end  

return M
