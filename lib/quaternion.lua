local vector = require("lib.vector")

---@class Quaternion
---@field x number
---@field y number
---@field z number
---@field w number
local Quaternion = {}

---@param x number
---@param y number
---@param z number
---@param w number
---@return Quaternion
function Quaternion:new(x, y, z, w)
    local o = {x = x, y = y, z = z, w = w}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param x number Axis vector's X
---@param y number Axis vector's Y
---@param z number Axis vector's Z
---@param angle number (in radians)
---@return Quaternion
function Quaternion:fromAxisAngle(x, y, z, angle)
    local s = math.sin(angle / 2)
    return Quaternion:new(x * s, y * s, z * s, math.cos(angle / 2))
end

---@return string
function Quaternion:__tostring()
    return string.format("Quaternion(x = %f, y = %f, z = %f, w = %f)", self.x, self.y, self.z, self.w)
end

---@param rhs Quaternion
---@return Quaternion
function Quaternion:__mul(rhs)
    local w = self.w * rhs.w - self.x * rhs.x - self.y * rhs.y - self.z * rhs.z
    local x = self.w * rhs.x + self.x * rhs.w + self.y * rhs.z - self.z * rhs.y
    local y = self.w * rhs.y - self.x * rhs.z + self.y * rhs.w + self.z * rhs.x
    local z = self.w * rhs.z + self.x * rhs.y - self.y * rhs.x + self.z * rhs.w
    return Quaternion:new(x, y, z, w)
end

---@return Quaternion
function Quaternion:conjugate()
    return Quaternion:new(-self.x, -self.y, -self.z, self.w)
end

---@return Quaternion
function Quaternion:normalized()
    local dot = self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w
    local sqrt = math.sqrt(dot)
    return Quaternion:new(self.x / sqrt, self.y / sqrt, self.z / sqrt, self.w / sqrt)
end

---@param vec3 Vec3
---@return Vec3
function Quaternion:applyToVec3(vec3)
    local rotated = self * Quaternion:new(vec3.x, vec3.y, vec3.z, 1) * self:conjugate()
    return vector.Vec3:new(rotated.x, rotated.y, rotated.z)
end

return { Quaternion = Quaternion }
