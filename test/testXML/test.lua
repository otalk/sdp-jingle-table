package.path = '../../lua-otalk/?.lua;' .. '../src/?.lua;' .. package.path

require "verse".init("client")
c = verse.new()

local converter = require "converter"
local utils = require "utils"

require "jingleStanza"
local iqStanza = jingleStanza()

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

local toTable = converter.toTable("jingle", "urn:xmpp:jingle:1")
local jingleTable = toTable(iqStanza:get_child("jingle", "urn:xmpp:jingle:1"))
local meta = {__tostring = utils.tableString}
utils.setMetatableRecursively(jingleTable, meta)
print(jingleTable)

local toStanza = converter.toStanza("jingle", "urn:xmpp:jingle:1")
local newStanza = toStanza(jingleTable)
print(newStanza)

require "jingleTable"
local sdpStanza = toStanza(export)
print(sdpStanza)
