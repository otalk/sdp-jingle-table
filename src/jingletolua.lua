local M = {}

local converter = require "converter"

-- Usage:
-- local convert = require "jingletolua"
-- convert.init()
-- convert.toSDP(jingle)

local toSDP = require "toSDP"
local toTable = require "toTable"

function M.init()
    local jingle = require "jingle"
    jingle.registerJingle(converter)
    jingle.registerContent(converter)

    local ice = require "ice"
    ice.registerTransport(converter)
    ice.registerCandidate(converter)
    ice.registerFingerprint(converter)
    ice.registerSCTP(converter)

    local rtp = require "rtp"
    rtp.registerDescription(converter)
    rtp.registerPayload(converter)
    rtp.registerFeedback(converter)
    rtp.registerMoreFeedback(converter)
    rtp.registerHeader(converter)
    rtp.registerParameter(converter)
    rtp.registerTalkyDescription(converter)
    rtp.registerContentGroup(converter)
    rtp.registerSourceGroup(converter)
    rtp.registerSource(converter)
    rtp.registerSourceParameter(converter)
    rtp.registerMute(converter)
    rtp.registerUnmute(converter)
end

function M.toIncomingAnswerSDP(jingle)
    local toTable = converter.toTable("jingle", "urn:xmpp:jingle:1")
    local jingleTable = toTable(jingle)
    return M.toIncomingSDPAnswer(jingleTable), jingleTable
end

function M.toIncomingOfferSDP(jingle)
    local toTable = converter.toTable("jingle", "urn:xmpp:jingle:1")
    local jingleTable = toTable(jingle)
    return M.toIncomingSDPOffer(jingleTable), jingleTable 
end

function M.toOutgoingAnswerJingle(sdp)
    local jingleTable = M.toOutgoingTableAnswer(sdp)
    local toStanza = converter.toStanza("jingle", "urn:xmpp:jingle:1")
    return toStanza(jingleTable), jingleTable
end

function M.toOutgoingOfferJingle(sdp)
    local jingleTable = M.toOutgoingTableOffer(sdp)
    local toStanza = converter.toStanza("jingle", "urn:xmpp:jingle:1")
    return toStanza(jingleTable), jingleTable
end

function M.toJingle(jingleTable)
    local toStanza = converter.toStanza("jingle", "urn:xmpp:jingle:1")
    return toStanza(jingleTable)
end

function M.toSDP(jingle)
    local toTable = converter.toTable("jingle", "urn:xmpp:jingle:1")
    local jingleTable = toTable(jingle)
    return toSDP.toSessionSDP(jingleTable), jingleTable
end

function M.jingleToTable(jingle)
    local toTable = converter.toTable("jingle", "urn:xmpp:jingle:1")
    return toTable(jingle)
end

M.toCandidateSDP = toSDP.toCandidateSDP
M.toCandidateTable = toTable.toCandidateTable

function M.toIncomingSDPOffer(session)
    return toSDP.toSessionSDP(session, {
        role = "responder",
        direction = "incoming"
    })
end

function M.toOutgoingSDPOffer(session)
    return toSDP.toSessionSDP(session, {
        role = "initiator",
        direction = "outgoing"
    })
end

function M.toIncomingSDPAnswer(session)
    return toSDP.toSessionSDP(session, {
        role = "initiator",
        direction = "incoming"
    })
end

function M.toOutgoingSDPAnswer(session)
    return toSDP.toSessionSDP(session, {
        role = "responder",
        direction = "outgoing"
    })
end

function M.toIncomingMediaSDPOffer(media)
    return toSDP.toMediaSDP(media, {
        role = "responder",
        direction = "incoming"
    })
end

function M.toOutgoingMediaSDPOffer(media)
    return toSDP.toMediaSDP(media, {
        role = "initiator",
        direction = "outgoing"
    })
end

function M.toIncomingMediaSDPAnswer(media)
    return toSDP.toMediaSDP(media, {
        role = "initiator",
        direction = "incoming"
    })
end

function M.toOutgoingMediaSDPAnswer(media)
    return toSDP.toMediaSDP(media, {
        role = "responder",
        direction = "outgoing"
    })
end

-- SDP to table

function M.toIncomingTableOffer(sdp, creator)
    return toTable.toSessionTable(sdp, {
        role = "responder",
        direction = "incoming",
        creator = creator
    })
end

function M.toOutgoingTableOffer(sdp, creator)
    return toTable.toSessionTable(sdp, {
        role = "initiator",
        direction = "outgoing",
        creator = creator
    })
end

function M.toIncomingTableAnswer(sdp, creator)
    return toTable.toSessionTable(sdp, {
        role = "initiator",
        direction = "incoming",
        creator = creator
    })
end

function M.toOutgoingTableAnswer(sdp, creator)
    return toTable.toSessionTable(sdp, {
        role = "responder",
        direction = "outgoing",
        creator = creator
    })
end

function M.toIncomingMediaTableOffer(sdp, creator)
    return toTable.toMediaTable(sdp, {
        role = "responder",
        direction = "incoming",
        creator = creator
    })
end

function M.toOutgoingMediaTableOffer(sdp, creator)
    return toTable.toMediaTable(sdp, {
        role = "initiator",
        direction = "outgoing",
        creator = creator
    })
end

function M.toIncomingMediaTableAnswer(sdp, creator)
    return toTable.toMediaTable(sdp, {
        role = "initiator",
        direction = "incoming",
        creator = creator
    })
end

function M.toOutgoingMediaTableAnswer(sdp, creator)
    return toTable.toMediaTable(sdp, {
        role = "responder",
        direction = "outgoing",
        creator = creator
    })
end

return M
