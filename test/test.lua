package.path = '../src/?.lua;' .. package.path

local utils = require "utils"

require "tableData"
io.input("sdpData.txt")
local sdp = io.read("*all")

-- Test table -> SDP
local toSDP = require "tosdp"
local newSDP = toSDP.toSessionSDP(export, 1382398245712, 1385147470924)

if newSDP == sdp then
    print("Table -> SDP tests pass")
else
    print("Something went wrong with table -> SDP")
end
-- End table -> SDP

-- Test SDP -> table
local toTable = require "toTable"
toTable._setIdCounter(0)
local newTable = toTable.toSessionTable(sdp, "initiator")

local meta = {__eq = utils.equal, __tostring = utils.tableString}
utils.setMetatableRecursively(export, meta)
utils.setMetatableRecursively(newTable, meta)
if newTable == export then
  print("SDP -> table tests pass")
else
  print("Something went wrong with SDP -> table")
end
-- End SDP -> table
