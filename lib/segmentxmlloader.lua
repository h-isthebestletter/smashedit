local vector = require("lib.vector")
local Vec2, Vec3, Vec4 = vector.Vec2, vector.Vec3, vector.Vec4
local uv = require("lib.uv")
local UV, UVPair = uv.UV, uv.UVPair
local Color = require("lib.color").Color

local utils = require("lib.utils")

---@param str string
---@return number[]
local function parseSpaceSeparatedNumbers(str)
    local res = {}
    for s in string.gmatch(str, "%S+") do
    	table.insert(res, tonumber(s))
    end
    return res
end

---@param str string
---@return Color|Color[]
local function parseColorString(str)
    local separated = parseSpaceSeparatedNumbers(str)
    if #separated == 3 then
        return Color:new(separated[1], separated[2], separated[3])
    elseif #separated == 4 then
        return Color:new(separated[1], separated[2], separated[3], separated[4])
    elseif #separated == 6 then
        return {
            Color:new(separated[1], separated[2], separated[3]),
            Color:new(separated[4], separated[5], separated[6]),
        }
    -- elseif #separated == 9 then
    --     return {
    --         Color:new(separated[1], separated[2], separated[3]),
    --         Color:new(separated[4], separated[5], separated[6]),
    --         Color:new(separated[7], separated[8], separated[9]),
    --     }
    end
end

---@param str string
---@return {x: Color, y: Color, z: Color}
local function parse3ColorString(str)
    local separated = parseSpaceSeparatedNumbers(str)
    if #separated == 3 then
        return {
            x = Color:new(separated[1], separated[2], separated[3]),
            y = Color:new(separated[1], separated[2], separated[3]),
            z = Color:new(separated[1], separated[2], separated[3]),
        }
    elseif #separated == 9 then
        return {
            x = Color:new(separated[1], separated[2], separated[3]),
            y = Color:new(separated[4], separated[5], separated[6]),
            z = Color:new(separated[7], separated[8], separated[9]),
        }
    end
end

---@param str string
---@return Vec2
local function parseVector2String(str)
    local separated = parseSpaceSeparatedNumbers(str)
    return Vec2:new(separated[1], separated[2])
end

---@param str string
---@return Vec3|Vec3[]
local function parseVector3String(str)
    local separated = parseSpaceSeparatedNumbers(str)
    if #separated == 1 then
        return Vec3:new(separated[1], separated[1], separated[1])
    elseif #separated == 3 then
        return Vec3:new(separated[1], separated[2], separated[3])
    elseif #separated == 6 then
        return {
            Vec3:new(separated[1], separated[2], separated[3]),
            Vec3:new(separated[4], separated[5], separated[6]),
        }
    elseif #separated == 9 then
        return {
            Vec3:new(separated[1], separated[2], separated[3]),
            Vec3:new(separated[4], separated[5], separated[6]),
            Vec3:new(separated[7], separated[8], separated[9]),
        }
    end
end


---@param str string
---@return boolean
local function parseBooleanString(str)
    return str == "1" or str == "true"
end

local defaults = {
    segment = {
        template    = "_missing",                                                             -- string containing the template name to use
        size        = Vec3:new(0, 0, 0),                                                      -- vec3 x 1
        lightRight  = 1,                                                                      -- number
        lightLeft   = 1,                                                                      -- number
        lightTop    = 1,                                                                      -- number
        lightBottom = 1,                                                                      -- number
        lightFront  = 1,                                                                      -- number
        lightBack   = 1,                                                                      -- number
        fogcolor    = {Color:new(1, 1, 1), Color:new(1, 1, 1)},                               -- color x 2
        softshadow  = 0.7,                                                                    -- number
    },
    obstacle = {
        -- our system cannot handle paramX so they end up using the fallback (left as-is)
        pos        = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        template   = "_missing",                                                              -- string containing the template name to use
        hidden     = false,                                                                   -- bool
        type       = "scoretop",                                                              -- string
        rot        = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        difficulty = {0, 1},                                                                  -- number x 2
        mode       = 255,                                                                     -- number
    },
    box = {
        pos        = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        template   = "_missing",                                                              -- string containing the template name to use
        hidden     = false,                                                                   -- bool
        size       = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        visible    = true,                                                                    -- bool
        color      = {x = Color:new(1, 1, 1), y = Color:new(1, 1, 1), z = Color:new(1, 1, 1)}, -- color x 1 or color x 3, but parse into color x 3
        tile       = Vec3:new(0, 0, 0),                                                       -- number or vec3 x 1, but parse into vec3 x 1
        tileSize   = Vec3:new(1, 1, 1),                                                       -- number or vec3 x 1, but parse into vec3 x 1
        tileRot    = Vec3:new(0, 0, 0),                                                       -- number or vec3 x 1, but parse into vec3 x 1
        reflection = false,                                                                   -- bool
    },
    powerup = {
        pos        = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        template   = "_missing",                                                              -- string containing the template name to use
        hidden     = false,                                                                   -- bool
        type       = "ballfrenzy",                                                            -- string
        difficulty = {0, 1},                                                                  -- number x 2
    },
    decal = {
        pos        = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        template   = "_missing",                                                              -- string containing the template name to use
        hidden     = false,                                                                   -- bool
        tile       = 0,                                                                       -- number
        size       = Vec2:new(1, 1),                                                          -- vec2 x 1
        rot        = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        color      = Color:new(1, 1, 1, 1),                                                   -- colorWithAlpha x 1
        blend      = 1,                                                                       -- number
        difficulty = {0, 1},                                                                  -- number x 2
    },
    water = {
        pos        = Vec3:new(0, 0, 0),                                                       -- vec3 x 1
        template   = "_missing",                                                              -- string containing the template name to use
        hidden     = false,                                                                   -- bool
        size       = Vec2:new(16, 16),                                                        -- vec2 x 1
        resolution = Vec2:new(32, 32),                                                        -- vec2 x 1
    },
}

local handlers = {
    -- for every property we define a function that can handle it.
    -- segment tag properties
    segment = {
        template    = tostring,                   -- string containing the template name to use
        size        = parseVector3String,         -- vec3 x 1
        lightRight  = tonumber,                   -- number
        lightLeft   = tonumber,                   -- number
        lightTop    = tonumber,                   -- number
        lightBottom = tonumber,                   -- number
        lightFront  = tonumber,                   -- number
        lightBack   = tonumber,                   -- number
        fogcolor    = parseColorString,           -- color x 2
        softshadow  = tonumber,                   -- number
    },
    obstacle = {
        -- our cannot handle paramX so they end up using the fallback (left as-is)
        pos         = parseVector3String,         -- vec3 x 1
        template    = tostring,                   -- string containing the template name to use
        hidden      = parseBooleanString,         -- bool
        type        = tostring,                   -- string
        rot         = parseVector3String,         -- vec3 x 1
        difficulty  = parseSpaceSeparatedNumbers, -- number x 2
        mode        = tonumber,                   -- number
    },
    box = {
        pos         = parseVector3String,         -- vec3 x 1
        template    = tostring,                   -- string containing the template name to use
        hidden      = parseBooleanString,         -- bool
        size        = parseVector3String,         -- vec3 x 1
        visible     = parseBooleanString,         -- bool
        color       = parse3ColorString,          -- color x 1 or color x 3
        tile        = parseVector3String,         -- number or vec3 x 1 but parse into vec3
        tileSize    = parseVector3String,         -- number or vec3 x 1 but parse into vec3
        tileRot     = parseVector3String,         -- number or vec3 x 1 but parse into vec3
        reflection  = parseBooleanString,         -- bool
    },
    powerup = {
        pos         = parseVector3String,         -- vec3 x 1
        template    = tostring,                   -- string containing the template name to use
        hidden      = parseBooleanString,         -- bool
        type        = tostring,                   -- string
        difficulty  = parseSpaceSeparatedNumbers, -- number x 2
    },
    decal = {
        pos         = parseVector3String,         -- vec3 x 1
        template    = tostring,                   -- string containing the template name to use
        hidden      = parseBooleanString,         -- bool
        tile        = tonumber,                   -- number
        size        = parseVector2String,         -- vec2 x 1
        rot         = parseVector3String,         -- vec3 x 1
        color       = parseColorString,           -- colorWithAlpha x 1
        blend       = tonumber,                   -- number
        difficulty  = parseSpaceSeparatedNumbers, -- number x 2
    },
    water = {
        pos         = parseVector3String,         -- vec3 x 1
        template    = tostring,                   -- string containing the template name to use
        hidden      = parseBooleanString,         -- bool
        size        = parseVector2String,         -- vec2 x 1
        resolution  = parseVector2String,         -- vec2 x 1
    },
}

---@class Element
---@field template string|nil
local Element = {}

function Element:new(elem)
    --[[
        for an element <elemname attr1="a" attr2="b" attr3="c">...</elemname>
        elem._name = elemname
        elem._attr = {attr1 = "a", attr2 = "b", attr3 = "c"}
        elem._children = ...
    ]]
    local o = {}
    if elem ~= nil then
        for attrName, attr in pairs(elem._attr) do
            if handlers[elem._name] and handlers[elem._name][attrName] then
            	o[attrName] = handlers[elem._name][attrName](attr)
            else
                o[attrName] = attr
            end
        end
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function Element:getTagName()
    error("Only descendants of Element have getTagName() defined")
end

---Modifies `self` directly.
---@param templates table
function Element:mergeWithTemplate(templates)
    if not self.template then return end
    --[[
        templates is like
        {
            templateName: {attr1 = ..., attr2 = ..., ...},
            ...
        }
    ]]
    for attrName, attr in pairs(templates[self.template]) do
    	if self[attrName] == nil then
    	    if handlers[self:getTagName()] and handlers[self:getTagName()][attrName] then
            	self[attrName] = handlers[self:getTagName()][attrName](attr)
            else
                self[attrName] = attr
            end
        end
    end
end

---Modifies `self` directly.
function Element:mergeWithDefaults()
    for attrName, attr in pairs(defaults[self:getTagName()]) do
        if self[attrName] == nil then
            self[attrName] = defaults[self:getTagName()][attrName]
        end
    end
end

---@class SegmentElement: Element
---@field template
---@field size Vec3
---@field lightRight number
---@field lightLeft number
---@field lightTop number
---@field lightBottom number
---@field lightFront number
---@field lightBack number
---@field fogcolor {top: Color, bottom: Color}
---@field softshadow number
---@field children Element[]
local SegmentElement = {}
setmetatable(SegmentElement, {__index = Element})

---@return string
function SegmentElement:getTagName()
    return "segment"
end

function SegmentElement:getLight()
    return {right = self.lightRight, left = self.lightLeft, top = self.lightTop, bottom = self.lightBottom, front = self.lightFront, back = self.lightBack}
end

---@class ObstacleElement: Element
---@field pos Vec3
---@field hidden boolean
---@field template string
---@field type string
---@field rot Vec3
---@field difficulty {min: number, max: number}
---@field mode number
---@field param0 string|nil
---@field param1 string|nil
---@field param2 string|nil
---@field param3 string|nil
---@field param4 string|nil
---@field param5 string|nil
---@field param6 string|nil
---@field param7 string|nil
---@field param8 string|nil
---@field param9 string|nil
---@field param10 string|nil
---@field param11 string|nil
local ObstacleElement = {}
setmetatable(ObstacleElement, {__index = Element})

---@return string
function ObstacleElement:getTagName()
    return "obstacle"
end

---@class BoxElement: Element
---@field pos Vec3
---@field hidden boolean
---@field template string
---@field size Vec3
---@field visible boolean
---@field color {x: Color, y: Color, z: Color}
---@field tile Vec3
---@field tileSize Vec3
---@field tileRot Vec3
---@field reflection boolean
local BoxElement = {}
setmetatable(BoxElement, {__index = Element})

---@return string
function BoxElement:getTagName()
    return "box"
end

---@class PowerUpElement: Element
---@field pos Vec3
---@field hidden boolean
---@field template string
---@field type string
---@field difficulty {min: number, max: number}
local PowerUpElement = {}
setmetatable(PowerUpElement, {__index = Element})

---@return string
function PowerUpElement:getTagName()
    return "powerup"
end

---@class DecalElement: Element
---@field pos Vec3
---@field hidden boolean
---@field template string
---@field tile number
---@field size Vec2
---@field rot Vec3
---@field color Color
---@field blend number
---@field difficulty {min: number, max: number}
local DecalElement = {}
setmetatable(DecalElement, {__index = Element})

---@return string
function DecalElement:getTagName()
    return "decal"
end

---@class WaterElement
---@field pos Vec3
---@field hidden boolean
---@field template string
---@field size Vec2
---@field resolution Vec2
local WaterElement = {}
setmetatable(WaterElement, {__index = Element})

---@return string
function WaterElement:getTagName()
    return "water"
end


--- parse the templates.xml.mp3 first before handing the table over to this function!
local function parseTemplates(t)
    local ret = {}
    for _, child in ipairs(t._children) do
    	if child._name == "template" then
    	    ret[child._attr.name] = {}
    	    for name, attr in pairs(child._children[1]._attr) do
    	        -- template attributes cannot be parsed reliably without knowing
    	        -- which segment tag uses it, so we parse them in parseSegments
                ret[child._attr.name][name] = attr
            end
        end
    end
    return ret
end

--- parse the segment.xml.gz.mp3 first before handing the table over to this function!
local function parseSegments(segmentTable, templatesTable)
    local templates = parseTemplates(templatesTable)
    local ret = SegmentElement:new(segmentTable)
    ret._children = {}
    ret:mergeWithTemplate(templates)
    ret:mergeWithDefaults()

    local switch = {
        obstacle = ObstacleElement,
        box = BoxElement,
        powerup = PowerUpElement,
        decal = DecalElement,
        water = WaterElement,
    }
    for _, child in ipairs(segmentTable._children) do
        local elem = switch[child._name]:new(child)
        elem:mergeWithTemplate(templates)
        elem:mergeWithDefaults()
        table.insert(ret._children, elem)
    end

    return ret
end

-- local templates = utils.readXml(utils.readFile("smashhit143/assets/templates.xml.mp3"))
-- -- utils.printTable(parseTemplates(templates))
-- local segment = utils.readXml(utils.decompressGZip(utils.readFileBin("smashhit143/assets/segments/basic/basic/start.xml.gz.mp3")))
-- utils.printTable(parseSegments(segment, templates))

return {
    parseTemplates = parseTemplates,
    parseSegments = parseSegments,
}
