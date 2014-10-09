package.path = '../src/?.lua;' .. package.path

function printTable(table)
    for _,line in pairs(table) do
        if type(line) == "string" then
            print(line)
        elseif type(line) == "table" then
            printTable(line)
        end
    end	
end

require "tableData"
local toSDP = require "tosdp"
local newSDP = toSDP.toSessionSDP(export, 1382398245712, 1385147470924)

io.input("sdpData.txt")
local sdp = io.read("*all")
if newSDP == sdp then
    print("Tests pass")
else
    print("Something went wrong")
end

