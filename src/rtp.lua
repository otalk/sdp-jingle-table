package.path = '../../lua-otalk/?.lua;' .. package.path

local M = {}

local converter = require "converter"
local helpers = require "helpers"
local utils = require "utils"

local NS = "urn:xmpp:jingle:apps:rtp:1"
local FBNS = "urn:xmpp:jingle:apps:rtp:rtcp-fb:0"
local HDRNS = "urn:xmpp:jingle:apps:rtp:rtp-hdrext:0"
local INFONS = "urn:xmpp:jingle:apps:rtp:info:1"
local SSMANS = "urn:xmpp:jingle:apps:rtp:ssma:0"
local GROUPNS = "urn:xmpp:jingle:apps:grouping:0"

function descriptionToTable(element)
    local description = {}

    description.descType = "rtp"
    description.media = helpers.getAttribute(element, "media")
    description.ssrc = helpers.getAttribute(element, "ssrc")

    description.bandwidth = helpers.getSubText(element, "bandwidth", NS)
    description.bandwidthType = helpers.getSubAttribute(element, "bandwidth", NS, "type")
    description.mux = helpers.get_child(element, "rtcp-mux", NS) and true or false

    local feedback = helpers.getChildren(element, "rtcp-fb", FBNS)
    utils.appendTable(feedback, helpers.getChildren(element, "rtcp-fb-trr-int", FBNS))
    description.feedback = feedback;

    description.headerExtensions = helpers.getChildren(element, "rtp-hdrext", HDRNS)
    description.payloads = helpers.getChildren(element, "payload-type", NS)
    description.sourceGroups = helpers.getChildren(element, "ssrc-group", SSMANS)
    description.sources = helpers.getChildren(element, "source", SSMANS)

    return description; 
end

function tableToDescription(description)
    local element = stanza.stanza("description")
    local attrs = { xmlns = NS, media = description.media, ssrc = description.ssrc }
    helpers.setAttributes(element, attrs)

    if description.bandwidth then
        local bandwidth = stanza.stanza("bandwidth")
        local attrs = { xmlns = NS, type = description.bandwidthType }
        helpers.setAttributes(element, attrs)
        bandwidth:text(description.bandwidth)
        element:add_child(bandwidth)
    end
    if description.mux then
        local mux = stanza.stanza("rtcp-mux", { xmlns = NS })
        element:add_child(mux)
    end

    local feedbackToStanza = converter.toStanza("rtcp-fb", FBNS)
    local moreFeedbackToStanza = converter.toStanza("rtcp-fb-trr-int", FBNS)
    for _, feedback in pairs(description.feedback) do
        if feedback.type == "trr-int" then
            element:add_child(feedbackToStanza(feedback))
        else
            element:add_child(moreFeedbackToStanza(feedback))
        end
    end

    helpers.addChildren(element, description, "headerExtensions", "rtp-hdrext", HDRNS)
    helpers.addChildren(element, description, "payloads", "payload-type", NS)
    helpers.addChildren(element, description, "sourceGroups", "ssrc-group", SSMANS)
    helpers.addChildren(element, description, "sources", "source", SSMANS)

    return element
end

function payloadToTable(element)
    local payload = {}

    payload.channels = helpers.getAttribute(element, "channels")
    payload.clockrate = helpers.getAttribute(element, "clockrate")
    payload.id = helpers.getAttribute(element, "id")
    payload.maxptime = helpers.getAttribute(element, "maxptime")
    payload.name = helpers.getAttribute(element, "name")
    payload.ptime = helpers.getAttribute(element, "ptime")

    local feedback = helpers.getChildren(element, "rtcp-fb", FBNS)
    utils.appendTable(feedback, helpers.getChildren(element, "rtcp-fb-trr-int", FBNS))
    payload.feedback = feedback;

    payload.parameters = helpers.getChildren(element, "parameter", NS)

    return payload;
end

function tableToPayload(payload)
    local element = stanza.stanza("payload-type")
    local attrs = {
        xmlns = NS,
        channels = payload.channels,
        clockrate = payload.clockrate,
        id = payload.id,
        maxptime = payload.maxptime,
        name = payload.name,
        ptime = payload.ptime
    }
    helpers.setAttributes(element, attrs)

    local feedbackToStanza = converter.toStanza("rtcp-fb", FBNS)
    local moreFeedbackToStanza = converter.toStanza("rtcp-fb-trr-int", FBNS)
    for _, feedback in pairs(payload.feedback) do
        if feedback.type == "trr-int" then
            element:add_child(feedbackToStanza(feedback))
        else
            element:add_child(moreFeedbackToStanza(feedback))
        end
    end

    helpers.addChildren(element, payload, "parameters", "parameter", NS)

    return element
end

function feedbackToTable(element)
    local feedback = {}
    feedback.type = helpers.getAttribute(element, "type")
    feedback.subtype = helpers.getAttribute(element, "subtype")
    return feedback
end

function tableToFeedback(feedback)
    local element = stanza.stanza("rtcp-fb")

    local attrs = {
        xmlns = FBNS,
        type = feedback.type,
        subtype = feedback.subtype
    }
    helpers.setAttributes(element, attrs)

    return element
end

function moreFeedbackToTable(element)
    local feedback = {}
    feedback.type = helpers.getAttribute(element, "type")
    feedback.value = helpers.getAttribute(element, "value")
    return feedback
end

function tableToMoreFeedback(feedback)
    local element = stanza.stanza("rtcp-fb-trr-int")

    local attrs = {
        xmlns = FBNS,
        type = feedback.type,
        value = feedback.value
    }
    helpers.setAttributes(element, attrs)

    return element
end

function headerToTable(element)
    local header = {}
    header.id = helpers.getAttribute(element, "id")
    header.uri = helpers.getAttribute(element, "uri")
    header.senders = helpers.getAttribute(element, "senders")
    return header
end

function tableToHeader(header)
    local element = stanza.stanza("rtp-hdrext")

    local attrs = {
        xmlns = HDRNS,
        id = header.id,
        uri = header.uri,
        senders = header.senders
    }
    helpers.setAttributes(element, attrs)

    return element;
end

function parameterToTable(element)
    local parameter = {}
    parameter.key = helpers.getAttribute(element, "name")
    parameter.value = helpers.getAttribute(element, "value")
    return parameter
end

function tableToParameter(feedback)
    local element = stanza.stanza("parameter")

    local attrs = {
        xmlns = NS,
        name = feedback.key,
        value = feedback.value
    }
    helpers.setAttributes(element, attrs)

    return element
end

function talkyDescriptionToTable(element)
    local description = {}
    description.descType = "datachannel"
    return description
end

function tableToTalkyDescription(description)
    local element = stanza.stanza("description", { xmlns = "http://talky.io/ns/datachannel" })

    return element
end

function contentGroupToTable(element)
    local contentGroup = {}
    contentGroup.semantics = helpers.getAttribute(element, "semantics")
    contentGroup.contents = helpers.getMultiSubAttribute(element, "content", GROUPNS, "name")
    return contentGroup
end

function tableToContentGroup(contentGroup)
    local element = stanza.stanza("group")
    helpers.setAttributes(element, { xmlns = GROUPNS, semantics = contentGroup.semantics })

    helpers.setMultiSubAttribute(element, "content", GROUPNS, "name", contentGroup.contents)

    return element
end

function sourceGroupToTable(element)
    local sourceGroup = {}
    sourceGroup.semantics = helpers.getAttribute(element, "semantics")
    sourceGroup.sources = helpers.getMultiSubAttribute(element, "source", SSMANS, "ssrc")
    return sourceGroup
end

function tableToSourceGroup(sourceGroup)
    local element = stanza.stanza("ssrc-group")
    helpers.setAttributes(element, { xmlns = SSMANS, semantics = sourceGroup.semantics })
    
    helpers.setMultiSubAttribute(element, "source", SSMANS, "ssrc", sourceGroup.sources)

    return element
end

function sourceToTable(element)
    local source = {}

    source.ssrc = helpers.getAttribute(element, "ssrc")
    source.parameters = helpers.getChildren(element, "parameter", SSMANS)

    return source
end

function tableToSource(source)
    local element = stanza.stanza("source")
    helpers.setAttributes(element, { xmlns = SSMANS, ssrc = source.ssrc })

    helpers.addChildren(element, source, "parameters", "parameter", SSMANS)

    return element
end

function sourceParameterToTable(element)
    local parameter = {}
    parameter.key = helpers.getAttribute(element, "name")
    parameter.value = helpers.getAttribute(element, "value")
    return parameter
end

function tableToSourceParameter(parameter)
    local element = stanza.stanza("parameter")
    helpers.setAttributes(element, { xmlns = SSMANS, name = parameter.key, value = parameter.value })
    return parameter;
end

function muteToTable(element)
    local mute = {}
    mute.creator = helpers.getAttribute(element, "creator")
    mute.name = helpers.getAttribute(element, "name")
    return mute
end

function tableToMute(mute)
    local element = stanza.stanza("mute")
    helpers.setAttributes(element, { xmlns = INFONS, name = mute.name, creator = mute.creator })
    return element
end

function unmuteToTable(element)
    local unmute = {}
    unmute.creator = helpers.getAttribute(element, "creator")
    unmute.name = helpers.getAttribute(element, "name")
    return unmute
end

function tableToUnmute(unmute)
    local element = stanza.stanza("unmute")
    helpers.setAttributes(element, { xmlns = INFONS, name = unmute.name, creator = unmute.creator })
    return element
end


function M.registerDescription(converter)
    converter.register("description", NS, { toTable = descriptionToTable, toStanza = tableToDescription })
end

function M.registerPayload(converter)
    converter.register("payload-type", NS, { toTable = payloadToTable, toStanza = tableToPayload })
end

function M.registerFeedback(converter)
    converter.register("rtcp-fb", FBNS, { toTable = feedbackToTable, toStanza = tableToFeedback })
end

function M.registerMoreFeedback(converter)
    converter.register("rtcp-fb-trr-int", FBNS, { toTable = moreFeedbackToTable, toStanza = tableToMoreFeedback })
end

function M.registerHeader(converter)
    converter.register("rtp-hdrext", HDRNS, { toTable = headerToTable, toStanza = tableToHeader })
end

function M.registerParameter(converter)
    converter.register("parameter", NS, { toTable = parameterToTable, toStanza = tableToParameter })
end

function M.registerTalkyDescription(converter)
    converter.register("description", "http://talky.io/ns/datachannel", { toTable = talkyDescriptionToTable, toStanza = tableToTalkyDescription })
end

function M.registerContentGroup(converter)
    converter.register("group", GROUPNS, { toTable = contentGroupToTable, toStanza = tableToContentGroup })
end

function M.registerSourceGroup(converter)
    converter.register("ssrc-group", SSMANS, { toTable = sourceGroupToTable, toStanza = tableToSourceGroup })
end

function M.registerSource(converter)
    converter.register("source", SSMANS, { toTable = sourceToTable, toStanza = tableToSource })
end

function M.registerSourceParameter(converter)
    converter.register("parameter", SSMANS, { toTable = sourceParameterToTable, toStanza = tableToSourceParameter })
end

function M.registerMute(converter)
    converter.register("mute", INFONS, { toTable = muteToTable, toStanza = tableToMute })
end

function M.registerUnmute(converter)
    converter.register("unmute", INFONS, { toTable = unmuteToTable, toStanza = tableToUnmute })
end

return M
