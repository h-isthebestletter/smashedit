---@class Vec2
---@field x number
---@field y number
local Vec2 = {}

---@param x number
---@param y number
---@return Vec2
function Vec2:new(x, y)
    if x == nil or y == nil then
    	error("Values of Vec2 cannot be nil")
    end
    local o = {x = x, y = y}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param other Vec2
---@return Vec2
function Vec2:__add(other)
    return Vec2:new(self.x + other.x, self.y + other.y)
end

---@param other Vec2
---@return Vec2
function Vec2:__sub(other)
    return Vec2:new(self.x - other.x, self.y - other.y)
end

---@param n number
---@return Vec2
function Vec2:__mul(n)
    return Vec2:new(self.x * n, self.y * n)
end

---@param n number
---@return Vec2
function Vec2:__div(n)
    return Vec2:new(self.x / n, self.y / n)
end

---@param other Vec2
---@return boolean
function Vec2:__eq(other)
    return self.x == other.x and self.y == other.y
end

---@return number, number
function Vec2:unpack()
    return self.x, self.y
end

---@return string
function Vec2:__tostring()
    return string.format("Vec2(x = %f, y = %f)", self:unpack())
end

Vec2.RIGHT  = Vec2:new( 1,  0)
Vec2.LEFT   = Vec2:new(-1,  0)
Vec2.TOP    = Vec2:new( 0,  1)
Vec2.BOTTOM = Vec2:new( 0, -1)
Vec2.ZERO   = Vec2:new( 0,  0)

---@class Vec3
---@field x number
---@field y number
---@field z number
local Vec3 = {}

---@param x number
---@param y number
---@param z number
---@return Vec3
function Vec3:new(x, y, z)
    if x == nil or y == nil or z == nil then
    	error("Values of Vec3 cannot be nil")
    end
    local o = {x = x, y = y, z = z}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param other Vec3
---@return Vec3
function Vec3:__add(other)
    return Vec3:new(self.x + other.x, self.y + other.y, self.z + other.z)
end

---@param other Vec3
---@return Vec3
function Vec3:__sub(other)
    return Vec3:new(self.x - other.x, self.y - other.y, self.z - other.z)
end

---@param n number
---@return Vec3
function Vec3:__mul(n)
    return Vec3:new(self.x * n, self.y * n, self.z * n)
end

---@param n number
---@return Vec3
function Vec3:__div(n)
    return Vec3:new(self.x / n, self.y / n, self.z / n)
end

---@param other Vec3
---@return boolean
function Vec3:__eq(other)
    return self.x == other.x and self.y == other.y and self.z == other.z
end

---@return number, number, number
function Vec3:unpack()
    return self.x, self.y, self.z
end

---@return string
function Vec3:__tostring()
    return string.format("Vec3(x = %f, y = %f, z = %f)", self:unpack())
end

Vec3.RIGHT  = Vec3:new( 1,  0,  0)
Vec3.LEFT   = Vec3:new(-1,  0,  0)
Vec3.TOP    = Vec3:new( 0,  1,  0)
Vec3.BOTTOM = Vec3:new( 0, -1,  0)
Vec3.FRONT  = Vec3:new( 0,  0,  1)
Vec3.BACK   = Vec3:new( 0,  0, -1)
Vec3.ZERO   = Vec3:new( 0,  0,  0)

---@class Vec4
---@field x number
---@field y number
---@field z number
---@field w number
local Vec4 = {}

---@param x number
---@param y number
---@param z number
---@param w number
---@return Vec4
function Vec4:new(x, y, z, w)
    if x == nil or y == nil or z == nil or w == nil then
    	error("Values of Vec4 cannot be nil")
    end
    local o = {x = x, y = y, z = z, w = w}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param other Vec4
---@return Vec4
function Vec4:__add(other)
    return Vec4:new(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w)
end

---@param other Vec4
---@return Vec4
function Vec4:__sub(other)
    return Vec4:new(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w)
end

---@param n number
---@return Vec4
function Vec4:__mul(n)
    return Vec4:new(self.x * n, self.y * n, self.z * n, self.w * n)
end

---@param n number
---@return Vec4
function Vec4:__div(n)
    return Vec4:new(self.x / n, self.y / n, self.z / n, self.w / n)
end

---@param other Vec4
---@return boolean
function Vec4:__eq(other)
    return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w
end

---@return number, number, number, number
function Vec4:unpack()
    return self.x, self.y, self.z, self.w
end

---@return string
function Vec4:__tostring()
    return string.format("Vec4(x = %f, y = %f, z = %f, w = %f)", self:unpack())
end

return {
    Vec2 = Vec2,
    Vec3 = Vec3,
    Vec4 = Vec4,
}
