local M = {}

local converter = require "converter"

-- Usage:
-- local convert = require "jingletolua"
-- convert.init()
-- convert.toSDP(jingle)

M.init = function()
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
    local toSDP = require "toSDP"
    local toTable = converter.toTable("jingle", "urn:xmpp:jingle:1")
    local jingleTable = toTable(jingle)
    return toSDP.toSessionSDP(jingleTable), jingleTable
end

function M.toJingle(sdp, role)
    local toTable = require "toTable"
    local jingleTable = toTable.toSessionTable(sdp, role)
    local toStanza = converter.toStanza("jingle", "urn:xmpp:jingle:1")
    return toStanza(jingleTable), jingleTable
end
