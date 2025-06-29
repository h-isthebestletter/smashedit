local Quaternion = require("lib.quaternion").Quaternion

---@class Mat4
---@field a11 number
---@field a12 number
---@field a13 number
---@field a14 number
---@field a21 number
---@field a22 number
---@field a23 number
---@field a24 number
---@field a31 number
---@field a32 number
---@field a33 number
---@field a34 number
---@field a41 number
---@field a42 number
---@field a43 number
---@field a44 number
local Mat4 = {}

---@param a11 number
---@param a12 number
---@param a13 number
---@param a14 number
---@param a21 number
---@param a22 number
---@param a23 number
---@param a24 number
---@param a31 number
---@param a32 number
---@param a33 number
---@param a34 number
---@param a41 number
---@param a42 number
---@param a43 number
---@param a44 number
---@return Mat4
function Mat4:new(a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44)
    local o = {
        a11 = a11, a12 = a12, a13 = a13, a14 = a14,
        a21 = a21, a22 = a22, a23 = a23, a24 = a24,
        a31 = a31, a32 = a32, a33 = a33, a34 = a34,
        a41 = a41, a42 = a42, a43 = a43, a44 = a44,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return string
function Mat4:__tostring()
    return string.format("+ %f %f %f %f +\n| %f %f %f %f |\n| %f %f %f %f |\n+ %f %f %f %f +",
        self.a11, self.a12, self.a13, self.a14,
        self.a21, self.a22, self.a23, self.a24,
        self.a31, self.a32, self.a33, self.a34,
        self.a41, self.a42, self.a43, self.a44
    )
end

---@return number[]
function Mat4:toFlatArray()
    return {
        self.a11, self.a12, self.a13, self.a14,
        self.a21, self.a22, self.a23, self.a24,
        self.a31, self.a32, self.a33, self.a34,
        self.a41, self.a42, self.a43, self.a44
    }
end

---Makes a Mat4 that encodes the same rotation as the given Quaternion.
---@param quat Quaternion
---@return Mat4
function Mat4:fromQuaternion(quat)
    local num9 = quat.x * quat.x
    local num8 = quat.y * quat.y
    local num7 = quat.z * quat.z
    local num6 = quat.x * quat.y
    local num5 = quat.z * quat.w
    local num4 = quat.z * quat.x
    local num3 = quat.y * quat.w
    local num2 = quat.y * quat.z
    local num1 = quat.x * quat.w
    return Mat4:new(
        1 - (2 * (num8 + num7)), 2 * (num6 + num5)      , 2 * (num4 - num3)      , 0,
        2 * (num6 - num5)      , 1 - (2 * (num7 + num9)), 2 * (num2 + num1)      , 0,
        2 * (num4 + num3)      , 2 * (num2 - num1)      , 1 - (2 * (num8 + num9)), 0,
        0                      , 0                      , 0                      , 1
    )
end

---@param x number Axis vector's X
---@param y number Axis vector's Y
---@param z number Axis vector's Z
---@param angle number (in radians)
---@return Mat4
function Mat4:fromAxisAngle(x, y, z, angle)
    return Mat4:fromQuaternion(Quaternion:fromAxisAngle(x, y, z, angle))
end

---@param x number
---@param y number
---@param z number
---@return Mat4
function Mat4:fromTranslation(x, y, z)
    return Mat4:new(
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1
    )
end

---Ported from [this function](https://registry.khronos.org/OpenGL-Refpages/gl2.1/xhtml/gluPerspective.xml)
---@param fovYRadians number
---@param aspectRatio number
---@param zNear number
---@param zFar number
---@return Mat4
function Mat4:fromPerspectiveRhGL(fovYRadians, aspectRatio, zNear, zFar)
    local invLength = 1 / (zNear - zFar)
    local f = 1 / math.tan(0.5 * fovYRadians)
    local a = f / aspectRatio
    local b = (zNear + zFar) * invLength
    local c = (2 * zNear * zFar) * invLength

    return Mat4:new(
        a, 0, 0, 0,
        0, f, 0, 0,
        0, 0, b, c,
        0, 0, -1, 0
    )
end

---Note that Mat4 * Vec4 is not yet implemented and will error.
---@version JIT
---@param other Mat4|Vec4
---@return Mat4|Vec4
function Mat4:__mul(other)
    if other.a11 then
    	-- other is a matrix
    	local newMatrixParts = {}
        for i = 1, 4 do
        	for j = 1, 4 do
        	    local sum = 0
            	for k = 1, 4 do
                	sum = sum + self["a" .. tostring(i) .. tostring(k)] * other["a" .. tostring(k) .. tostring(j)]
                end
                table.insert(newMatrixParts, sum)
            end
        end
        return Mat4:new(unpack(newMatrixParts))
    elseif other.w then
        -- other is a Vec4
        error("Mat4 * Vec4 is not yet implemented")
    end
    error("Given value is not a Mat4 or a Vec4")
end

return { Mat4 = Mat4 }
