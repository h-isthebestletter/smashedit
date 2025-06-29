local ffi = require("ffi")
local xml2lua = require("lib.xml2lua.xml2lua")
local xmlHandler = require("lib.xml2lua.xmlhandler.dom")

local function readFile(fn)
    local file, err = io.open(fn, "r")
    if not file then error(err) end

    local content = file:read("*a")
    file:close()
    return content
end

local function readFileBin(fn)
    local file, err = io.open(fn, "rb")
    if not file then error(err) end

    local content = file:read("*a")
    file:close()
    return content
end

local function readXml(xml)
    local handler = xmlHandler:new()
    local parser = xml2lua.parser(handler)
    parser:parse(xml)
    -- print(xml)
    -- xml2lua.printable(handler.root)
    return handler.root
end

local function printTable(t)
    xml2lua.printable(t)
end

local function decompressZlib(bin)
    return love.data.decompress("string", "zlib", bin)
end

local function decompressGZip(bin)
    return love.data.decompress("string", "gzip", bin)
end

local function compressZlib(bin)
    return love.data.compress("string", "zlib", bin)
end

local function compressGZip(bin)
    return love.data.compress("string", "gzip", bin)
end

local function asLeFloat(bin)
    return love.data.unpack("<f", bin)
    -- local correctBin
    -- if ffi.abi("be") then
    -- 	correctBin = string.reverse(bin)
    -- else
    --     correctBin = bin
    -- end
    -- return ffi.cast("float*", ffi.new("const char *", correctBin))[0]
end

local function asLeInt32(bin)
    return love.data.unpack("<i4", bin)
    -- local correctBin
    -- if ffi.abi("be") then
    -- 	correctBin = string.reverse(bin)
    -- else
    --     correctBin = bin
    -- end
    -- return ffi.cast("int32_t*", ffi.new("const char *", correctBin))[0]
end

local function asLeUInt32(bin)
    return love.data.unpack("<I4", bin)
    -- local correctBin
    -- if ffi.abi("be") then
    -- 	correctBin = string.reverse(bin)
    -- else
    --     correctBin = bin
    -- end
    -- return ffi.cast("uint32_t*", ffi.new("const char *", correctBin))[0]
end

local function asLeUInt8(bin)
    return love.data.unpack("<I1", bin)
    -- local correctBin
    -- if ffi.abi("be") then
    -- 	correctBin = string.reverse(bin)
    -- else
    --     correctBin = bin
    -- end
    -- return ffi.cast("uint8_t*", ffi.new("const char *", correctBin))[0]
end

local function leStrFromFloat(num)
    return love.data.pack("string", "<f", num)
end

local function leStrFromInt32(num)
    return love.data.pack("string", "<i4", num)
end

local function leStrFromUInt32(num)
    return love.data.pack("string", "<I4", num)
end

local function leStrFromUInt8(num)
    return love.data.pack("string", "<I1", num)
end

local function streamReader(bin)
    local nextRead = 1
    return function (n)
        local oldNextRead = nextRead
        nextRead = nextRead + n
        return string.sub(bin, oldNextRead, oldNextRead + n - 1)
    end
end

return {
    streamReader = streamReader,
    decompressZlib = decompressZlib,
    decompressGZip = decompressGZip,
    compressZlib = compressZlib,
    compressGZip = compressGZip,
    readFile = readFile,
    readFileBin = readFileBin,
    readXml = readXml,
    printTable = printTable,
    asLeFloat = asLeFloat,
    asLeInt32 = asLeInt32,
    asLeUInt32 = asLeUInt32,
    asLeUInt8 = asLeUInt8,
    leStrFromFloat = leStrFromFloat,
    leStrFromInt32 = leStrFromInt32,
    leStrFromUInt32 = leStrFromUInt32,
    leStrFromUInt8 = leStrFromUInt8,
}
