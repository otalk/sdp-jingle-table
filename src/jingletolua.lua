local M = {};

M.init = function() {
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
  return converter;
}

return M;
