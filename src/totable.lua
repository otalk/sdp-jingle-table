local parsers = require "parsers"
local utils = require "utils"

local M = {}

math.randomseed(os.time())
local idCounter = math.random()

function M._setIdCounter(counter)
  idCounter = counter
end

function M.toSessionTable(sdp, creator)
  -- Divide the SDP into session and media sections
  local media = utils.split(sdp, "\r\nm=")
  for i=2,#media do
    media[i] = "m=" .. media[i]
    if i ~= (#media - 1) then
      media[i] = media[i] .. "\r\n"
    end
  end
  local session = table.remove(media, 1) .. "\r\n"
  local sessionLines = parsers.lines(session)
  local parsed = {}

  local contents = {}
  for _, m in pairs(media) do
    table.insert(contents, M.toMediaTable(m, session, creator))
  end
  parsed.contents = contents

  local groupLines = parsers.findLines("a=group:", sessionLines)
  if utils.tableHasContent(groupLines) then
    parsed.groups = parsers.groups(groupLines)
  end

  return parsed
end

function M.toMediaTable(media, session, creator)
  local lines = parsers.lines(media)
  local sessionLines = parsers.lines(session)
  local mline = parsers.mline(lines[1])

  local content = {
    creator = creator,
    name = mline.media,
    description = {
      descType = "rtp",
      media = mline.media,
      payloads = {},
      encryption = {},
      feedback = {},
      headerExtensions = {}
    },
    transport = {
      transType = "iceUdp",
      candidates = {},
      fingerprints = {}
    }
  }
  if mline.media == "application" then
    -- FIXME: the description is most likely to be independent
    -- of the SDP and should be processed by other parts of the library
    content.description = {
      descType = "datachannel"
    }
    content.transport.sctp = {}
  end
  local desc = content.description
  local trans = content.transport

  -- If we have a mid, use that for the content name instead
  local mid = parsers.findLine("a=mid:", lines)
  if (mid) then
    content.name = string.sub(mid, 7)
  end

  if parsers.findLine("a=sendrecv", lines, sessionLines) then
    content.senders = "both"
  elseif parsers.findLine("a=sendonly", lines, sessionLines) then
    content.senders = "initiator"
  elseif parsers.findLine("a=recvonly", lines, sessionLines) then
    content.senders = "responder"
  elseif parsers.findLine("a=inactive", lines, sessionLines) then
    content.senders = "none"
  end

  if desc.descType == "rtp" then
    local bandwidth = parsers.findLine("b=", lines)
    if bandwidth then
      desc.bandwidth = parsers.bandwidth(bandwidth)
    end

    local ssrc = parsers.findLine("a=ssrc:", lines)
    if ssrc then
      desc.ssrc = utils.split(string.sub(ssrc, 8), " ")[1]
    end

    local rtpmapLines = parsers.findLines("a=rtpmap:", lines)
    for _, line in pairs(rtpmapLines) do
      local payload = parsers.rtpmap(line)
      payload.feedback = {}

      local fmtpLines = parsers.findLines("a=fmtp:" .. payload.id, lines)
      for _, line in pairs(fmtpLines) do
        payload.parameters = parsers.fmtp(line)
      end

      local fbLines = parsers.findLines("a=rtcp-fb:" .. payload.id, lines)
      for _, line in pairs(fbLines) do
        table.insert(payload.feedback, parsers.rtcpfb(line))
      end

      table.insert(desc.payloads, payload)
    end

    local cryptoLines = parsers.findLines("a=crypto:", lines, sessionLines)
    for _, line in pairs(cryptoLines) do
      table.insert(desc.encryption, parsers.crypto(line))
    end

    if parsers.findLine("a=rtcp-mux", lines) then
      desc.mux = true
    end

    local fbLines = parsers.findLines("a=rtcp-fb:*", lines)
    for _, line in pairs(fbLines) do
      table.insert(desc.feedback, parsers.rtcpfb(line))
    end

    local extLines = parsers.findLines("a=extmap:", lines)
    for _, line in pairs(extLines) do
      local ext = parsers.extmap(line)

      local senders = {
        sendonly = "responder",
        recvonly = "initiator",
        sendrecv = "both",
        inactive = "none"
      }
      ext.senders = senders[ext.senders]

      table.insert(desc.headerExtensions, ext)
    end

    local ssrcGroupLines = parsers.findLines("a=ssrc-group:", lines)
    desc.sourceGroups = parsers.sourceGroups(ssrcGroupLines or {})

    local ssrcLines = parsers.findLines("a=ssrc:", lines)
    desc.sources = parsers.sources(ssrcLines or {})
  end

  -- transport specific attributes
  local fingerprintLines = parsers.findLines("a=fingerprint:", lines, sessionLines)
  local setup = parsers.findLine("a=setup:", lines, sessionLines)
  for _, line in pairs(fingerprintLines) do
    local fp = parsers.fingerprint(line)
    if setup then
      fp.setup = string.sub(setup, 9)
    end
    table.insert(trans.fingerprints, fp)
  end

  local ufragLine = parsers.findLine("a=ice-ufrag:", lines, sessionLines)
  local pwdLine = parsers.findLine("a=ice-pwd:", lines, sessionLines)
  if ufragLine and pwdLine then
    trans.ufrag = string.sub(ufragLine, 13)
    trans.pwd = string.sub(pwdLine, 11)
    trans.candidates = {}

    local candidateLines = parsers.findLines("a=candidate:", lines, sessionLines)
    for _, line in pairs(candidateLines) do
      table.insert(trans.candidates, M.toCandidateTable(line))
    end
  end

  if desc.descType == "datachannel" then
    local sctpmapLines = parsers.fineLines("a=sctpmap:", lines)
    for _, line in pairs(sctpmapLines) do
      local sctp = parsers.sctpmap(line)
      table.insert(trans.sctp, sctp)
    end
  end

  return content
end

function M.toCandidateTable(line)
  local candidate = parsers.candidate(utils.split(line, "\r\n")[1])
  local parts = utils.split(string.format("%.16f", idCounter), ".")
  candidate.id = parts[1]
  if tonumber(parts[2]) ~= 0 then
    candidate.id = candidate.id .. "." .. string.format("%x", parts[2])
  end
  idCounter = idCounter + 1
  return candidate
end

return M
