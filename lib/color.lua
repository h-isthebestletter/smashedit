---All components of this class must be between 0 and 1. The alpha component `a` is optional.
---@class Color
---@field r number
---@field g number
---@field b number
---@field a number|nil
local Color = {}

---All components of this class must be between 0 and 1. The alpha component `a` is optional.
---@param r number
---@param g number
---@param b number
---@param a number|nil
---@return Color
function Color:new(r, g, b, a)
    if r == nil or g == nil or b == nil then
        error("Values of Color (except a) cannot be nil")
    end
    -- assert(
    --     0 <= r and r <= 1 and
    --     0 <= g and g <= 1 and
    --     0 <= b and b <= 1
    -- )
    -- if a ~= nil then
    -- 	assert(0 <= a and a <= 1)
    -- end
    local o = {r = r, g = g, b = b, a = a}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return string
function Color:__tostring()
    return string.format("Color(r = %f, g = %f, b = %f, a = %s)", self.r, self.g, self.b, tostring(self.a))
end

---@param m number
---@return Color
function Color:mulRGB(m)
    return Color:new(self.r * m, self.g * m, self.b * m, self.a)
end

return { Color = Color }
