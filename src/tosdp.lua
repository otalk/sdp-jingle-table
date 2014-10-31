local utils = require "utils"
local SENDERS = require "senders"

local M = {}

function M.toSessionSDP(session, opts)
    local role = opts.role or "initiator"
    local direction = opts.direction or "outgoing"
    local sid = opts.sid or session.sid or os.time()
    local time = opts.time or os.time()

    local sdp = {
        "v=0",
        "o=- " .. sid .. " " .. time .. " IN IP4 0.0.0.0",
        's=-',
        't=0 0'
        }

    local groups = session.groups or {}
    for _, group in ipairs(groups) do
        table.insert(sdp, "a=group:" .. group.semantics .. " " .. table.concat(group.contents, " "))
    end

    local contents = session.contents or {}
    for _, content in ipairs(contents) do
        table.insert(sdp, M.toMediaSDP(content, opts))
    end

    return table.concat(sdp, "\r\n") .. "\r\n"
end

function M.toMediaSDP(content, opts)
    local sdp = {}

    local role = opts.role or "initiator"
    local direction = opts.direction or "outgoing"

    local desc = content.description or {}
    local transport = content.transport
    local payloads = desc.payloads or {}
    local fingerprints = (transport and transport.fingerprints) or {}

    local mline = {}
    if desc.descType == "datachannel" then
        table.insert(mline, "application")
        table.insert(mline, "1")
        table.insert(mline, "DTLS/SCTP")
        if transport.sctp then
            for _, map in ipairs(transport.sctp) do
                table.insert(mline, map.number)
            end
        end
    else
        table.insert(mline, desc.media)
        table.insert(mline, "1")
        if desc.encryption and utils.tableHasContent(desc.encryption) or utils.tableHasContent(fingerprints) then
            table.insert(mline, "RTP/SAVPF")
        else
            table.insert(mline, "RTP/AVPF")
        end
        for _, payload in pairs(payloads) do
            table.insert(mline, payload.id)
        end
    end

    table.insert(sdp, "m=" .. table.concat(mline, " "))

    table.insert(sdp, "c=IN IP4 0.0.0.0")
    if desc.bandwidth and desc.bandwidth.type and desc.bandwidth.bandwidth then
        table.insert(sdp, "b=" .. desc.bandwidth.type .. ":" .. desc.bandwidth.bandwidth)
    end
    if desc.descType == "rtp" then
        table.insert(sdp, "a=rtcp:1 IN IP4 0.0.0.0")
    end

    if transport then
        if transport.ufrag then
            table.insert(sdp, "a=ice-ufrag:" .. transport.ufrag)
        end
        if transport.pwd then
            table.insert(sdp, "a=ice-pwd:" .. transport.pwd)
        end

        local pushedSetup = false
        for _, fingerprint in pairs(fingerprints) do
            table.insert(sdp, "a=fingerprint:" .. fingerprint.hash .. " " .. fingerprint.value)
            if fingerprint.setup and not pushedSetup then
                table.insert(sdp, "a=setup:" .. fingerprint.setup)
            end
        end

        if transport.sctp then
            for _, map in pairs(transport.sctp) do
                table.insert(sdp, "a=sctpmap:" .. map.number .. " " .. map.protocol .. " " .. map.streams)
            end
        end
    end

    if desc.descType == "rtp" then
        table.insert(sdp, "a=" .. (SENDERS[role][direction][content.senders] or "sendrecv"))
    end
    table.insert(sdp, "a=mid:" .. content.name)

    if desc.mux then
        table.insert(sdp, "a=rtcp-mux")
    end

    local encryption = desc.encryption or {}
    for _, crypto in pairs(encryption) do
        table.insert(sdp, "a=crypto:" .. crypto.tag .. " " .. crypto.cipherSuite .. " " .. crypto.keyParams .. ((string.len(crypto.sessionParams) > 0) and (" " .. crypto.sessionParams) or ""))
    end

    for _, payload in pairs(payloads) do
        local rtpmap = "a=rtpmap:" .. payload.id .. " " .. payload.name .. "/" .. payload.clockrate
        if payload.channels and string.len(payload.channels) > 0 and payload.channels ~= "1" then
            rtpmap = rtpmap .. "/" .. payload.channels
        end
        table.insert(sdp, rtpmap)

        if payload.parameters and utils.tableHasContent(payload.parameters) then
            local fmtp = {"a=fmtp:" .. payload.id}
            local parameters = {}
            for _, param in pairs(payload.parameters) do
                table.insert(parameters, ((param.key and (param.key .. "=")) or "") .. param.value)
            end
            table.insert(fmtp, table.concat(parameters, ";"))
            table.insert(sdp, table.concat(fmtp, " "))
        end

        if payload.feedback then
            for _, fb in pairs(payload.feedback) do
                if fb.type == "trr-int" then
                    table.insert(sdp, "a=rtcp-fb:" .. payload.id .. " trr-int " .. (fb.value or "0"))
                else
                    table.insert(sdp, "a=rtcp-fb:" .. payload.id .. " " .. fb.type .. ((string.len(fb.subtype) > 0) and (" " .. fb.subtype) or ""))
                end
            end
        end
    end

    if desc.feedback then
        for _, fb in pairs(desc.feedback) do
            if fb.type == "trr-int" then
                table.insert(sdp, "a=rtcp-fb:* trr-int " .. (fb.value or "0"))
            else
                table.insert(sdp, "a=rtcp-fb:* " .. fb.type .. (fb.subtype and (" " .. fb.subtype) or ""))
            end
        end
    end

    local hdrExts = desc.headerExtensions or {}
    for _, hdr in pairs(hdrExts) do
        table.insert(sdp, "a=extmap:" .. hdr.id .. ((string.len(hdr.senders) > 0) and ("/" .. SENDERS[role][direction][hdr.senders]) or "") .. " " .. hdr.uri)
    end

    local ssrcGroups = desc.sourceGroups or {}
    for _, ssrcGroup in pairs(ssrcGroups) do
        table.insert(sdp, "a=ssrc-group:" .. ssrcGroup.semantics .. " " .. table.concat(ssrcGroup.sources, " "))
    end

    local ssrcs = desc.sources or {}
    for _, ssrc in pairs(ssrcs) do
        for _, param in ipairs(ssrc.parameters) do
            table.insert(sdp, "a=ssrc:" .. (ssrc.ssrc or desc.ssrc) .. " " .. param.key .. (param.value and (":" .. param.value) or ""))
        end
    end

    local candidates = (transport and transport.candidates) or {}
    for _, candidate in pairs(candidates) do
        table.insert(sdp, M.toCandidateSDP(candidate))
    end

    return table.concat(sdp, "\r\n")
end

function M.toCandidateSDP(candidate)
    local sdp = {}

    table.insert(sdp, candidate.foundation)
    table.insert(sdp, candidate.component)
    table.insert(sdp, string.upper(candidate.protocol))
    table.insert(sdp, candidate.priority)
    table.insert(sdp, candidate.ip)
    table.insert(sdp, candidate.port)

    local type = candidate.type
    table.insert(sdp, "typ")
    table.insert(sdp, type)
    if type == "srflx" or type == "prflx" or type == "relay" then
        if candidate.relAddr and candidate.relPort then
            table.insert(sdp, "raddr")
            table.insert(sdp, candidate.relAddr)
            table.insert(sdp, "rport")
            table.insert(sdp, candidate.relPort)
        end
    end
    if candidate.tcpType and string.upper(candidate.protocol) == "TCP" then
        table.insert(sdp, "tcptype")
        table.insert(sdp, candidate.tcpType)
    end

    table.insert(sdp, "generation")
    table.insert(sdp, candidate.generation or "0")

    -- via https://github.com/otalk/sdp-jingle-json/blob/master/lib/tosdp.js#L206
    -- FIXME: apparently this is wrong per spec
    -- but then, we need this when actually putting this into
    -- SDP so it's going to stay.
    -- decision needs to be revisited when browsers dont
    -- accept this any longer
    return "a=candidate:" .. table.concat(sdp, " ")
end

return M
