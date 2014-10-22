package.path = '../../lua-otalk/?.lua;' .. package.path

local M = {}

local helpers = require "helpers"
local converter = require "converter"

local NS = "urn:xmpp:jingle:transports:ice-udp:1"

function transportToTable(element)
    local transport = {}
    transport.transType = "iceUdp"
    transport.pwd = helpers.getAttribute(element, "pwd")
    transport.ufrag = helpers.getAttribute(element, "ufrag")

    transport.candidates = helpers.getChildren(element, "candidate", "urn:xmpp:jingle:transports:ice-udp:1")
    transport.fingerprints = helpers.getChildren(element, "fingerprint", "urn:xmpp:jingle:apps:dtls:0")
    transport.sctp = helpers.getChildren(element, "sctpmap", "urn:xmpp:jingle:transports:dtls-sctp:1")
    return transport
end

function tableToTransport(transport)
    local element = stanza.stanza("transport")
    local attrs = { xmlns = NS, pwd = transport.pwd, ufrag = transport.ufrag }
    helpers.setAttributes(element, attrs)

    helpers.addChildren(element, transport, "candidates", "candidate", "urn:xmpp:jingle:transports:ice-udp:1")
    helpers.addChildren(element, transport, "fingerprints", "fingerprint", "urn:xmpp:jingle:apps:dtls:0")
    helpers.addChildren(element, transport, "sctp", "sctpmap", "urn:xmpp:jingle:transports:dtls-sctp:1")

    return element
end

function candidateToTable(element)
    local candidate = {}

    candidate.component = helpers.getAttribute(element, "component")
    candidate.foundation = helpers.getAttribute(element, "foundation")
    candidate.generation = helpers.getAttribute(element, "generation")
    candidate.id = helpers.getAttribute(element, "id")
    candidate.ip = helpers.getAttribute(element, "ip")
    candidate.network = helpers.getAttribute(element, "network")
    candidate.port = helpers.getAttribute(element, "port")
    candidate.priority = helpers.getAttribute(element, "priority")
    candidate.protocol = helpers.getAttribute(element, "protocol")
    candidate.relAddr = helpers.getAttribute(element, "rel-addr")
    candidate.relPort = helpers.getAttribute(element, "rel-port")
    candidate.type = helpers.getAttribute(element, "type")

    return candidate;
end

function tableToCandidate(candidate)
    local element = stanza.stanza("candidate")

    local attrs = {
        xmlns = NS,
        component = candidate.component,
        foundation = candidate.foundation,
        generation = candidate.generation,
        id = candidate.id,
        ip = candidate.ip,
        network = candidate.network,
        port = candidate.port,
        priority = candidate.priority,
        protocol = candidate.protocol,
        ["rel-addr"] = candidate.relAddr,
        ["rel-port"] = candidate.relPort,
        type = candidate.type
    }
    helpers.setAttributes(element, attrs)

    return element;
end

function fingerprintToTable(element)
    local fingerprint = {}

    fingerprint.hash = helpers.getAttribute(element, "hash")
    fingerprint.setup = helpers.getAttribute(element, "setup")
    fingerprint.value = element:get_text()

    return fingerprint;
end

function tableToFingerprint(fingerprint)
    local element = stanza.stanza("fingerprint")
    element:text(fingerprint.value)

    local attrs = { xmlns = "urn:xmpp:jingle:apps:dtls:0", hash = fingerprint.hash, setup = fingerprint.setup }
    helpers.setAttributes(element, attrs)

    return element;
end

function sctpToTable(element)
    local sctp = {}

    sctp.number = helpers.getAttribute(element, "number")
    sctp.protocol = helpers.getAttribute(element, "protocol")
    sctp.streams = helpers.getAttribute(element, "streams")

    return sctp;
end

function tableToSCTP(sctp)
    local element = stanza.stanza("sctpmap")

    local attrs = { xmlns = "urn:xmpp:jingle:transports:dtls-sctp:1", number = sctp.number, protocol = sctp.protocol, streams = sctp.streams }
    helpers.setAttributes(element, attrs)

    return element;
end

function M.registerTransport(converter)
    converter.register("transport", NS, { toTable = transportToTable, toStanza = tableToTransport })
end

function M.registerCandidate(converter)
    converter.register("candidate", NS, { toTable = candidateToTable, toStanza = tableToCandidate })
end

function  M.registerFingerprint(convert)
    converter.register("fingerprint", "urn:xmpp:jingle:apps:dtls:0", { toTable = fingerprintToTable, toStanza = tableToFingerprint })
end

function M.registerSCTP(converter)
    converter.register("sctpmap", "urn:xmpp:jingle:transports:dtls-sctp:1", { toTable = sctpToTable, toStanza = tableToSCTP })
end

return M
