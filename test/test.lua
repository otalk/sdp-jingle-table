package.path = '../src/?.lua;' .. package.path

local utils = require "utils"

function dofile (filename)
    local f = assert(loadfile(filename))
    return f()
end

require "tableData"
io.input("sdpData.txt")
local sdp = io.read("*all")

-- Test table -> SDP
local toSDP = require "tosdp"
local newSDP = toSDP.toSessionSDP(export, {
    role = "initiator",
    direction = "outgoing",
    sid = 1382398245712,
    time = 1385147470924
})

if newSDP == sdp then
    print("Table -> SDP tests pass")
else
    print("Something went wrong with table -> SDP")
end
-- End table -> SDP

-- Test SDP -> table
local toTable = require "toTable"
toTable._setIdCounter(0)
local newTable = toTable.toSessionTable(sdp, {
    creator = "initiator",
    role = "initiator",
    direction = "outgoing"
})

local meta = {__eq = utils.equal, __tostring = utils.tableString}
utils.setMetatableRecursively(export, meta)
utils.setMetatableRecursively(newTable, meta)
if newTable == export then
    print("SDP -> table tests pass")
else
    print("Something went wrong with SDP -> table")
end
-- End SDP -> table
local xmlns_jingle = "urn:xmpp:jingle:1";
local jingletolua = require("jingletolua");
local xml = require("pxml");
jingletolua.init();

function testXML()
    print "XML -> SDP";
    --local jingle_file1 = dofile("testXML/jingle.xml");
    io.input("testXML/jingle.xml");
    local jingle_file1 = io.read("*all");
    local iq1 = xml.parse(jingle_file1)
    --print(jingle_file1);
    print(iq1);
    local jingle1 = iq1:get_child('jingle', xmlns_jingle);
    local sdp_str1 = jingletolua.toIncomingOfferSDP(jingle1);
    print(sdp_str1);
end

function testSDP()
    print "SDP -> XML"
    io.input("testXML/sdp.txt")
    local sdp = io.read("*all")
    print(sdp)
    local jingleTable = jingletolua.toIncomingTableOffer(sdp, "initiator")
    local jingleStanza = jingletolua.toJingle(jingleTable)
    print(jingleStanza)
end

testXML();
testSDP();
