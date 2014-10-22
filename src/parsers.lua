local utils = require "utils"
local M = {}

function M.lines(sdp)
    return utils.filter(utils.split(sdp, "\r\n"), function (line)
        return string.len(line) > 0
    end)
end

function M.findLine(prefix, mediaLines, sessionLines)
    local prefixLength = string.len(prefix)
    for _, line in pairs(mediaLines) do
        if string.sub(line, 1, prefixLength) == prefix then
            return line
        end
    end
    -- Continue searching in parent session section
    if not sessionLines then
        return nil
    end

    for _, line in pairs(sessionLines) do
        if string.sub(line, 1, prefixLength) == prefix then
            return line
        end
    end

    return nil
end

function M.findLines(prefix, mediaLines, sessionLines)
    local results = {}
    local prefixLength = string.len(prefix)
    for _, line in pairs(mediaLines) do
        if string.sub(line, 1, prefixLength) == prefix then
            table.insert(results, line)
        end
    end
    if (#results > 0) or not sessionLines then
        return results
    end
    for _, line in pairs(sessionLines) do
        if string.sub(line, 1, prefixLength) == prefix then
            table.insert(results, line)
        end
    end
    return results
end

function M.mline(line)
    local parts = utils.split(string.sub(line, 3), " ")
    local parsed = {
        media = parts[1],
        port = parts[2],
        proto = parts[3],
        formats = {}
    }
    for i=4,#parts do
        if parts[i] then
            table.insert(parsed.formats, parts[i])
        end
    end
    return parsed
end

function M.rtpmap(line)
    local parts = utils.split(string.sub(line, 10), " ")
    local parsed = {
        id = table.remove(parts, 1)
    }

    parts = utils.split(parts[1], "/")

    parsed.name = parts[1]
    parsed.clockrate = parts[2]
    parsed.channels = parts[3] or "1"
    return parsed
end

function M.sctpmap(line)
    -- based on -05 draft
    local parts = utils.split(string.sub(line, 11), " ")
    local parsed = {
        number = table.remove(parts, 1),
        protocol = table.remove(parts, 1),
        streams = table.remove(parts, 1)
    }
    return parsed
end

function M.fmtp(line)
    local parts = utils.split(string.sub(line, string.find(line, " ") + 1), ";")
    local parsed = {}
    for _, part in pairs(parts) do
        local kv = utils.split(part, "=")
        local key = utils.trim(kv[1])
        local value = kv[2]
        if key and value then
            table.insert(parsed, {key = key, value = value})
        elseif key then
            table.insert(parsed, {key = "", value = key})
        end
    end
    return parsed
end

function M.crypto(line)
    local parts = utils.split(string.sub(line, 10), " ")
    local parsed = {
        tag = parts[1],
        cipherSuite = parts[2],
        keyParams = parts[3],
        sessionParams = table.concat(utils.subTable(parts, 4, #parts - 4), " ")
    }
    return parsed
end

function M.fingerprint(line)
    local parts = utils.split(string.sub(line, 15), " ")
    return {
        hash = parts[1],
        value = parts[2]
    }
end

function M.extmap(line)
    local parts = utils.split(string.sub(line, 10), " ")
    local parsed = {}

    local idpart = table.remove(parts, 1)
    local sp = string.find(idpart, "/")
    if sp then
        parsed.id = string.sub(idpart, 1, sp - 1)
        parsed.senders = string.sub(idpart, sp + 1)
    else
        parsed.id = idpart
        parsed.senders = "sendrecv"
    end

    parsed.uri = table.remove(parts, 1) or ""

    return parsed
end

function M.rtcpfb(line)
    local parts = utils.split(string.sub(line, 11), " ")
    local parsed = {}
    parsed.id = table.remove(parts, 1)
    parsed.type = table.remove(parts, 1)
    if parsed.type == "trr-int" then
        parsed.value = table.remove(parts, 1)
    else
        parsed.subtype = table.remove(parts, 1) or ""
    end
    parsed.parameters = parts
    return parsed
end

function M.candidate(line)
    local parts
    if string.find(line, "a=candidate:") == 1 then
        parts = utils.split(string.sub(line, 13), " ")
    else
        parts = utils.split(string.sub(line, 11), " ")
    end

    local candidate = {
        foundation = parts[1],
        component = parts[2],
        protocol = string.lower(parts[3]),
        priority = parts[4],
        ip = parts[5],
        port = parts[6],
        -- skip parts[7] == "typ"
        type = parts[8],
        generation = "0"
    }

    for i=9,#parts,2 do
        if parts[i] == "raddr" then
            candidate.relAddr = parts[i + 1]
        elseif parts[i] == "rport" then
            candidate.relPort = parts[i + 1]
        elseif parts[i] == "generation" then
            candidate.generation = parts[i + 1]
        elseif parts[i] == "tcptype" then
            candidate.tcpType = parts[i + 1]
        end
    end

    candidate.network = "1"

    return candidate
end

function M.sourceGroups(lines)
    local parsed = {}
    for _, line in pairs(lines) do
        local parts = utils.split(string.sub(line, 14), " ")
        table.insert(parsed, {
            semantics = table.remove(parts, 1),
            sources = parts
        })
    end
    return parsed
end

function M.sources(lines)
    -- http://tools.ietf.org/html/rfc5576
    local parsed = {}
    local sources = {}
    for _, line in pairs(lines) do
        local parts = utils.split(string.sub(line, 8), " ")
        local ssrc = table.remove(parts, 1)

        if not sources[ssrc] then
            local source = {
                ssrc = ssrc,
                parameters = {}
            }
            table.insert(parsed, source)

            -- Keep an index
            sources[ssrc] = source
        end

        parts = utils.split(table.concat(parts, " "), ":")
        local attribute = table.remove(parts, 1)
        local value = table.concat(parts, ":") or ""

        table.insert(sources[ssrc].parameters, {
            key = attribute,
            value = value
        })
    end

    return parsed
end

function M.groups(lines)
    -- http://tools.ietf.org/html/rfc5888
    local parsed = {}
    local parts
    for _, line in pairs(lines) do
        parts = utils.split(string.sub(line, 9), " ")
        table.insert(parsed, {
            semantics = table.remove(parts, 1),
            contents = parts
        })
    end
    return parsed
end

function M.bandwidth(line)
    local parts = utils.split(string.sub(line, 3), ":")
    local parsed = {}
    parsed.type = table.remove(parts, 1)
    parsed.bandwidth = table.remove(parts, 1)
    return parsed
end

return M
