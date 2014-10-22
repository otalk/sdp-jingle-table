package.path = '../../lua-otalk/?.lua;' .. package.path

local M = {}
local mapTable = {}

function M.register(name, namespace, t)
    local key = name .. "|" .. namespace
    mapTable[key] = t
end

function M.toTable(name, namespace)
    local key = name .. "|" .. namespace
    if mapTable[key] then
        return mapTable[key].toTable
    else
        return nil
    end
end

function M.toStanza(name, namespace)
    local key = name .. "|" .. namespace
    if mapTable[key] then
        return mapTable[key].toStanza
    else
        return nil
    end
end

return M
