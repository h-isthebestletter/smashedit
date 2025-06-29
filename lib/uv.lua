---@class UV
---@field u number
---@field v number
local UV = {}

---@param u number
---@param v number
---@return UV
function UV:new(u, v)
    if u == nil or v == nil then
    	error("Values of UV cannot be nil")
    end
    local o = {u = u, v = v}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return string
function UV:__tostring()
    return string.format("UV(u = %f, v = %f)", self.u, self.v)
end

---@class UVPair
---@field lb UV The UV of the left-bottom (-u, -v) corner
---@field rt UV The UV of the right-top (+u, +v) corner
local UVPair = {}

---@param lb UV The UV of the left-bottom (-u, -v) corner
---@param rt UV The UV of the right-top (+u, +v) corner
---@return UVPair
function UVPair:new(lb, rt)
    if rt == nil or lb == nil then
    	error("Values of UVPair cannot be nil")
    end

    local o = {rt = rt, lb = lb}
    setmetatable(o, self)
    self.__index = self
    return o
end

---Resets the orientation of the UVPair so that textures baked with it will be upright.
---@return UVPair
function UVPair:makeUpright()
    if self.lb.u <= self.rt.u and self.lb.v <= self.rt.v then
        return UVPair:new(self.lb, self.rt)
    elseif self.lb.u >= self.rt.u and self.lb.v >= self.rt.v then
        return UVPair:new(self.rt, self.lb)
    elseif self.lb.u <= self.rt.u and self.lb.v >= self.rt.v then
        return UVPair:new(UV:new(self.lb.u, self.rt.v), UV:new(self.rt.u, self.lb.v))
    elseif self.lb.u >= self.rt.u and self.lb.v <= self.rt.v then
        return UVPair:new(UV:new(self.rt.u, self.lb.v), UV:new(self.lb.u, self.rt.v))
    end
    error("unreachable")
end

---@return string
function UVPair:__tostring()
    return string.format("UVPair(lb = %s, rt = %s)", tostring(self.lb), tostring(self.rt))
end

---@class UV4
---@field lb UV
---@field rt UV
---@field lt UV
---@field rb UV
local UV4 = {}

function UV4:new(lb, rb, lt, rt)
    local o = {lb = lb, rt = rt, lt = lt, rb = rb}
    setmetatable(o, self)
    self.__index = self
    return o
end

function UV4:rotateClockwiseInPlace()
    self.lb, self.lt, self.rt, self.rb = self.rb, self.lb, self.lt, self.rt
end

function UV4:rotateAntiClockwiseInPlace()
    self.lb, self.rb, self.rt, self.lt = self.lt, self.lb, self.rb, self.rt
end

---@return string
function UV4:__tostring()
    return string.format("UV4(lb = %s, rb = %s, lt = %s, rt = %s)", self.lb, self.rb, self.lt, self.rt)
end

---@return UV4
function UVPair:getIndividualCorners()
    return UV4:new(
        self.lb,
        UV:new(self.rt.u, self.lb.v),
        UV:new(self.lb.u, self.rt.v),
        self.rt
    )
end

return {
    UV = UV, UVPair = UVPair, UV4 = UV4
}
