local vector = require("lib.vector")
local Vec2, Vec3, Vec4 = vector.Vec2, vector.Vec3, vector.Vec4
local uv = require("lib.uv")
local UV, UVPair = uv.UV, uv.UVPair
local Color = require("lib.color").Color

local utils = require("lib.utils")
local segmentXmlLoader = require("lib.segmentxmlloader")

local boxMesh = love.graphics.newMesh(
    {
        {"VertexPosition", "float", 3}
    },
    {
         0.5,  0.5,  0.5,
         0.5,  0.5, -0.5,
         0.5, -0.5,  0.5,
         0.5, -0.5, -0.5,
        -0.5,  0.5,  0.5,
        -0.5,  0.5, -0.5,
        -0.5, -0.5,  0.5,
        -0.5, -0.5, -0.5,
    },
    "triangles"
)
boxMesh:setVertexMap(
    5, 7, 1,
    1, 7, 3,
    1, 3, 2,
    2, 3, 4,
    2, 4, 6,
    6, 4, 8,
    6, 8, 5,
    5, 8, 7,
    6, 5, 2,
    2, 5, 1,
    7, 8, 3,
    3, 8, 4
)

local boxInstanceVertexFormat = {
    {"BoxSize", "float", 3},
    {"BoxTile", ""}
}

---@class SegmentBox
---@field center Vec3
---@field size Vec3
---@field halfSize Vec3
---@field rtf Vec3
---@field lbb Vec3
---@field color {x: Color, y: Color, z: Color}
---@field tile Vec3
---@field tileSize Vec3
---@field tileRot Vec3
---@field ambientLight {right: number, left: number, top: number, bottom: number, front: number, back: number}
local SegmentBox = {}

---@param center Vec3
---@param size Vec3
---@param color {x: Color, y: Color, z: Color}
---@param tile Vec3
---@param tileSize Vec3
---@param tileRot Vec3
---@return SegmentBox
function SegmentBox:new(center, size, color, tile, tileSize, tileRot)
    local halfSize = size * 0.5

    local o = {
        -- x is right, y is up, z is toward viewer
        center = center, size = size, halfSize = halfSize,
        rtf = center + halfSize, -- right top left vertex
        lbb = center - halfSize, -- left bottom back vertex
        color = color,
        tile = tile, tileSize = tileSize, tileRot = tileRot,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param center Vec3
---@param halfSize Vec3
---@param color {x: Color, y: Color, z: Color}
---@param tile Vec3
---@param tileSize Vec3
---@param tileRot Vec3
---@return SegmentBox
function SegmentBox:fromHalfSize(center, halfSize, color, tile, tileSize, tileRot)
    local size = halfSize * 2
    return SegmentBox:new(center, size, color, tile, tileSize, tileRot)
end

---Makes a box from the table returned by the segment XML parser.
---@param elem {pos: Vec3, size: Vec3, color: {x: Color, y: Color, z: Color}, tile: Vec3, tileSize: Vec3, tileRot: Vec3}
---@return SegmentBox
function SegmentBox:fromElem(elem)
    return SegmentBox:new(
        elem.pos, elem.size * 2,
        elem.color, elem.tile, elem.tileSize, elem.tileRot
    )
end

---@return string
function SegmentBox:__tostring()
    return string.format(
        "SegmentBox(center = %s, size = %s, color = {x = %s, y = %s, z = %s}, tile = %s, tileSize = %s, tileRot = %s)",
        tostring(self.center), tostring(self.size), tostring(self.color.x), tostring(self.color.y), tostring(self.color.z), tostring(self.tile), tostring(self.tileSize), tostring(self.tileRot)
    )
end

function SegmentBox:asLove2dMesh()
    
end
