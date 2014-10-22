package.path = '../../lua-otalk/?.lua;' .. package.path

require "verse"

local M = {}
local converter = require "converter"

function M.getAttribute(element, attr, defaultVal)
    return element.attr[attr] or defaultVal or ""
end

function M.setAttribute(element, name, value)
    if value and string.len(value) > 0 then
        element.attr[name] = value
    end
end

function M.setAttributes(element, attrs)
    for key, value in pairs(attrs) do
        M.setAttribute(element, key, value)
    end
end

-- borrowed from http://hg.prosody.im/0.9/file/ce66fe13eebe/util/stanza.lua until it's in our included Verse
function M.childtags(element, name, xmlns)
    local tags = element.tags;
    local start_i, max_i = 1, #tags;
    return function ()
        for i = start_i, max_i do
            local v = tags[i];
            if (not name or v.name == name)
            and ((not xmlns and element.attr.xmlns == v.attr.xmlns)
                or v.attr.xmlns == xmlns
                or (xmlns and not v.attr.xmlns and element.attr.xmlns == xmlns) -- Added this condition so default namespace on element will match
                or (xmlns and not v.attr.xmlns and not element.attr.xmlns)) then -- Added so default namespace two levels deep will match - absolutely horrible way to handle this
                start_i = i+1;
                return v;
            end
        end
    end;
end

function M.get_child(element, name, xmlns)
    for _, child in ipairs(element.tags) do
        if (not name or child.name == name)
            and ((not xmlns and element.attr.xmlns == child.attr.xmlns)
            or child.attr.xmlns == xmlns
            or (xmlns and not child.attr.xmlns and element.attr.xmlns == xmlns) -- Added this condition so default namespace on element will matchthen
            or (xmlns and not child.attr.xmlns and not element.attr.xmlns)) then -- Added so default namespace two levels deep will match - absolutely horrible way to handle this
          
            return child;
        end
    end
end
-- End borrowing

function M.getChildren(element, name, namespace)
    local children = {}
    for tag in M.childtags(element, name, namespace) do
        local toTable = converter.toTable(name, namespace)
        local child = toTable(tag)
        if (child) then
            table.insert(children, child)
        end
    end
    return children
end

function M.addChildren(element, object, key, name, namespace)
    local toStanza = converter.toStanza(name, namespace)
    if toStanza and object[key] then
        for _, child in pairs(object[key]) do
            element:add_child(toStanza(child))
        end
    end
end

function M.getSubText(element, name, namespace, defaultVal)
    defaultVal = defaultVal or ""

    local child = M.get_child(element, name, namespace)
    if not child then
        return defaultVal
    end

    return child:get_text() or defaultVal
end

function M.getSubAttribute(element, name, namespace, attr, defaultVal)
    local child = M.get_child(element, name, namespace)
    if not child then
        return ""
    end

    return child.attr[attr] and defaultVal or ""
end

function M.getMultiSubText(element, name, namespace, callback)
    local results = {}

    if not callback then
        callback = function (value)
            return value:get_text() or ""
        end
    end

    for child in M.childtags(element, name, namespace) do
        table.insert(results, callback(child))
    end
    return results
end

function M.setMultiSubText(element, name, namespace, value, callback)
    if not callback then
        callback = function (value)
            local child = stanza.stanza(name)
            child:text(value)
            element:add_child(child)
        end
    end

    local values
    if value.type == "string" then
        values = utils.split(value, "\n")
    else
        values = value
    end

    element:maptags(function (child)
        if child.name == name and child.attr.xmlns == namespace then
            return nil
        else
            return child
        end
    end)

    for _, value in pairs(values) do
        callback(value)
    end
end

function M.getMultiSubAttribute(element, name, namespace, attr)
    return M.getMultiSubText(element, name, namespace, function (value)
        return M.getAttribute(value, attr)
    end)
end

function M.setMultiSubAttribute(element, name, namespace, attr, value)
    M.setMultiSubText(element, name, namespace, value, function (value)
        local child = stanza.stanza(name)
        local attrs = { xmlns = namespace, [attr] = value }
        M.setAttributes(child, attrs)
        element:add_child(child)
    end)
end

return M
