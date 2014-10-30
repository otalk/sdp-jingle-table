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

function M.toSDP(jingle)
    local toTable = converter.toTable("jingle", "urn:xmpp:jingle:1")
    local jingleTable = toTable(jingle)
    return toSDP.toSessionSDP(jingleTable), jingleTable
end

function M.toJingle(sdp, role)
    local jingleTable = toTable.toSessionTable(sdp, role)
    local toStanza = converter.toStanza("jingle", "urn:xmpp:jingle:1")
    return toStanza(jingleTable), jingleTable
end

function M.toCandidateSDP(candidate)
    return toSDP.toCandidateSDP(candidate)
end

function M.toCandidateTable(sdp)
    return toTable.toCandidateTable(sdp)
end

function M.toStanza(jingleTable)
    local toStanza = converter.toStanza("jingle", "urn:xmpp:jingle:1")
    return toStanza(jingleTable)
end

return M