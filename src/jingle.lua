package.path = '../../lua-otalk/?.lua;' .. package.path

local M = {}

local helpers = require "helpers"
local converter = require "converter"

local NS = "urn:xmpp:jingle:1"
local GROUPNS = "urn:xmpp:jingle:apps:grouping:0"
local INFONS = "urn:xmpp:jingle:apps:rtp:info:1"

function jingleToTable(element)
    local jingle = {}
    jingle.action = helpers.getAttribute(element, "action")
    jingle.initiator = helpers.getAttribute(element, "initiator")
    jingle.responder = helpers.getAttribute(element, "responder")
    jingle.sid = helpers.getAttribute(element, "sid")

    jingle.contents = helpers.getChildren(element, "content", NS)
    jingle.groups = helpers.getChildren(element, "group", GROUPNS)
    jingle.muteGroup = helpers.getChildren(element, "mute", INFONS)
    jingle.unmuteGroup = helpers.getChildren(element, "unmute", INFONS)
    return jingle
end

function tableToJingle(jingle)
    local element = stanza.stanza("jingle")
    local attrs = { xmlns = NS, action = jingle.action, initiator = jingle.initiator, responder = jingle.responder, sid = jingle.sid }
    helpers.setAttributes(element, attrs)

    helpers.addChildren(element, jingle, "contents", "content", NS)
    helpers.addChildren(element, jingle, "groups", "group", GROUPNS)
    helpers.addChildren(element, jingle, "muteGroup", "mute", INFONS)
    helpers.addChildren(element, jingle, "unmuteGroup", "unmute", INFONS)

    return element
end

function contentToTable(element)
    local content = {}
    content.creator = helpers.getAttribute(element, "creator")
    content.disposition = helpers.getAttribute(element, "disposition", "session")
    content.name = helpers.getAttribute(element, "name")
    content.senders = helpers.getAttribute(element, "senders", "both")

    for child in element:childtags() do
        if child.name == "description" then
            local toTable
            if child.attr.xmlns and child.attr.xmlns == "http://talky.io/ns/datachannel" then
                toTable = converter.toTable("description", "http://talky.io/ns/datachannel")
            else
                toTable = converter.toTable("description", "urn:xmpp:jingle:apps:rtp:1")
            end
            if toTable then
                local description = toTable(child)
                if description then
                    content.description = description
                end
            end
        elseif child.name == "transport" then
            local toTable = converter.toTable("transport", "urn:xmpp:jingle:transports:ice-udp:1")
            if toTable then
                local transport = toTable(child)
                if transport then
                    content.transport = transport
                end
            end
        end
    end

    return content
end

function tableToContent(content)
    local element = stanza.stanza("content")
    local attrs = { xmlns = NS, creator = content.creator, disposition = content.disposition, name = content.name, senders = content.senders }
    helpers.setAttributes(element, attrs)

    local description = content.description
    local toStanza
    if description.descType == "datachannel" then
        toStanza = converter.toStanza("description", "http://talky.io/ns/datachannel")
    else
        toStanza = converter.toStanza("description", "urn:xmpp:jingle:apps:rtp:1")
    end
    element:add_child(toStanza(description))

    toStanza = converter.toStanza("transport", "urn:xmpp:jingle:transports:ice-udp:1")
    element:add_child(toStanza(content.transport))

    return element
end

function M.registerJingle(converter)
    converter.register("jingle", NS, { toTable = jingleToTable, toStanza = tableToJingle })
end

function M.registerContent(converter)
    converter.register("content", NS, { toTable = contentToTable, toStanza = tableToContent })
end

return M
