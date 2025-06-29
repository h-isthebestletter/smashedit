local utils = require("lib/utils")

--[[
local VertexData = {}
function VertexData:new(x, y, z, u, v, r, g, b, a)
    local o = {
        x = x, y = y, z = z,
        u = u, v = v,
        r = r, g = g, b = b, a = a,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end
function VertexData:__tostring()
    return string.format("VertexData(x = %f, y = %f, z = %f, u = %f, v = %f, r = %d, g = %d, b = %d, a = %d)",
        self.x, self.y, self.z,
        self.u, self.v,
        self.r, self.g, self.b, self.a
    )
end

local IndexData = {}
function IndexData:new(a, b, c)
    local o = { a, b, c }
    setmetatable(o, self)
    self.__index = self
    return o
end
function IndexData:__tostring()
    return string.format("IndexData(%d, %d, %d)", self[1], self[2], self[3])
end
]]

local function parseMeshData(fn)
    local reader = utils.streamReader(utils.decompressZlib(io.open(fn, "rb"):read("*a")))

    local vertexCount = utils.asLeUInt32(reader(4))
    print("Vertex count: ", vertexCount)

    local vertices = {}
    for _ = 0, vertexCount - 1 do
    	table.insert(vertices, {
    	    utils.asLeFloat(reader(4)),
    	    utils.asLeFloat(reader(4)),
    	    utils.asLeFloat(reader(4)),
    	    utils.asLeFloat(reader(4)),
    	    utils.asLeFloat(reader(4)),
    	    utils.asLeUInt8(reader(1)) / 127,
    	    utils.asLeUInt8(reader(1)) / 127,
    	    utils.asLeUInt8(reader(1)) / 127,
    	    utils.asLeUInt8(reader(1)) / 255,
	    })
    end

    local indexCount = utils.asLeUInt32(reader(4))
    print("Index count: ", indexCount)

    local indices = {}
    for _ = 0, indexCount - 1 do
        table.insert(indices, utils.asLeInt32(reader(4)) + 1)
        table.insert(indices, utils.asLeInt32(reader(4)) + 1)
        table.insert(indices, utils.asLeInt32(reader(4)) + 1)
        -- print(indices[#indices - 2], indices[#indices - 1], indices[#indices])
    end

    return vertices, indices
end

return { parseMeshData = parseMeshData }

