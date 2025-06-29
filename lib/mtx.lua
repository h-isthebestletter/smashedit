local utils = require("lib/utils")

local function parseMtxV0(reader)
    local lengthFirst = utils.asLeUInt32(reader(4))
    local lengthSecond = utils.asLeUInt32(reader(4))

    local firstImage = reader(lengthFirst)
    local secondImage = reader(lengthSecond)

    return {
        image1 = love.graphics.newImage(love.filesystem.newFileData(firstImage, "image1.jpg")),
        image2 = love.graphics.newImage(love.filesystem.newFileData(secondImage, "image2.jpg")),
        mtxVersion = 0
    }
end

local function parseMtxV1(reader)
    -- file header (excluding magic)
    local lengthFirst = utils.asLeUInt32(reader(4))
    local lengthSecond = utils.asLeUInt32(reader(4))

    -- first block header
    local magic1 = utils.asLeUInt32(reader(4))
    if magic1 ~= 1 then warn("mtx parser: mtxv1 magic is not 1") end
    local width1 = utils.asLeUInt32(reader(4))
    local height1 = utils.asLeUInt32(reader(4))

    -- first image
    local colorDataLength1 = utils.asLeUInt32(reader(4))
    local colorData1 = utils.decompressZlib(reader(colorDataLength1))
    local maskDataLength1 = utils.asLeUInt32(reader(4))
    local maskData1 = utils.decompressZlib(reader(maskDataLength1))

    -- second block header
    local magic2 = utils.asLeUInt32(reader(4))
    if magic2 ~= 1 then warn("mtx parser: mtxv1 magic is not 1") end
    local width2 = utils.asLeUInt32(reader(4))
    local height2 = utils.asLeUInt32(reader(4))

    -- second image
    local colorDataLength2 = utils.asLeUInt32(reader(4))
    local colorData2 = utils.decompressZlib(reader(colorDataLength1))
    local maskDataLength2 = utils.asLeUInt32(reader(4))
    local maskData2 = utils.decompressZlib(reader(maskDataLength1))

    return { colorData1 = colorData1, colorData2 = colorData2, maskData1 = maskData1, maskData2 = maskData2, mtxVersion = 1 }
end

local function parseMtxFile(fn)
    local reader = utils.streamReader(io.open(fn, "rb"):read("*a"))
    local magic = utils.asLeUInt32(reader(4))
    if magic == 0 then
        print("is mtx version 0")
    	return parseMtxV0(reader)
    elseif magic == 1 then
        print("is mtx version 1")
        return parseMtxV1(reader)
    elseif magic == 2 then
        error("mtx version 2 not supported!")
    end
end

return { parseMtxFile = parseMtxFile }
