-- test the XML library, unused file
local utils = require("lib.utils")

local testXml = [[
    <elem attr1="this is 1" attr2="this is 2">
        <nullelem attr3="this is 3" />
        <content attr4="this is attr4">
            stuff go here
        </content>
        <childtest></childtest>
    </elem>
]]

local parsed = utils.readXml(testXml)
utils.printTable(parsed)
print(parsed._children[3]._children)
