local vector = require("lib.vector")
local Vec2, Vec3, Vec4 = vector.Vec2, vector.Vec3, vector.Vec4
local uv = require("lib.uv")
local UV, UVPair = uv.UV, uv.UVPair
local Color = require("lib.color").Color

local utils = require("lib.utils")
local segmentXmlLoader = require("lib.segmentxmlloader")

---@class MeshQuad
---@field center Vec3
---@field size Vec3
---@field halfSize Vec3
---@field normal Vec3
---@field rtf Vec3 The right-top-front (+x, +y, +z) corner of the MeshQuad.
---@field lbb Vec3 The left-bottom-back (-x, -y, -z) corner of the MeshQuad.
---@field uvPair UVPair
---@field color Color
---@field tile number
---@field tileSize Vec3
---@field tileRot number
local MeshQuad = {}

--- `tile` and `tileRot` MUST be numbers at this point!
---@param center Vec3
---@param size Vec3
---@param normal Vec3
---@param color Color
---@param tile number
---@param tileSize Vec3
---@param tileRot number
---@return MeshQuad
function MeshQuad:new(center, size, normal, color, tile, tileSize, tileRot)
    local halfSize = size * 0.5
    ---@type MeshQuad
    local o = {
        -- x is right, y is up, z is toward viewer
        center = center, size = size, halfSize = halfSize, normal = normal,
        rtf = center + halfSize, -- right top left vertex
        lbb = center - halfSize, -- left bottom back vertex
        uvPair = UVPair:new(UV:new(0, 0), UV:new(1, 1)),
        color = color, tile = tile, tileSize = tileSize, tileRot = tileRot,

        -- internal properties
        tileSelected = false,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return string
function MeshQuad:__tostring()
    return string.format(
        "MeshQuad(center = %s, size = %s, normal = %s, uv = %s, tile = %d, tileSize = %s, tileRot = %d)",
        tostring(self.center), tostring(self.size), tostring(self.normal), tostring(self.uvPair), self.tile, tostring(self.tileSize), self.tileRot
    )
end

---@return number
function MeshQuad:getArea()
    if self.normal.x ~= 0 then
    	return self.size.y * self.size.z
    elseif self.normal.y ~= 0 then
        return self.size.x * self.size.z
    elseif self.normal.z ~= 0 then
        return self.size.x * self.size.y
    end
end

---@return MeshQuad[]
function MeshQuad:subdivideInto()
    local quads = {}

    local newX = self.lbb.x
    repeat
        local newY = self.lbb.y
    	repeat
        	local newZ = self.lbb.z
        	repeat
        	    local minX = math.min(self.rtf.x - newX, self.tileSize.x)
        	    local minY = math.min(self.rtf.y - newY, self.tileSize.y)
        	    local minZ = math.min(self.rtf.z - newZ, self.tileSize.z)

                local newMeshQuad = MeshQuad:new(
                    Vec3:new(newX + minX / 2, newY + minY / 2, newZ + minZ / 2),
            	    Vec3:new(minX, minY, minZ),
            	    self.normal,
            	    self.color, self.tile, self.tileSize, self.tileRot
            	)
            	-- TODO: this could bake some textures flipped,
            	-- because we don't take into account which side (e.g. left/right) we are baking
            	-- does it matter? probably not
            	-- right, top, front sides are flipped about z, z, and x axes
            	-- could be the reason why this works
            	if self.normal.x ~= 0 then
                	newMeshQuad.uvPair.rt.u = minZ / self.tileSize.z
                	newMeshQuad.uvPair.rt.v = minY / self.tileSize.y
                elseif self.normal.y ~= 0 then
                    newMeshQuad.uvPair.rt.u = minX / self.tileSize.x
                    newMeshQuad.uvPair.rt.v = minZ / self.tileSize.z
                elseif self.normal.z ~= 0 then
                    newMeshQuad.uvPair.rt.u = minX / self.tileSize.x
                    newMeshQuad.uvPair.rt.v = minY / self.tileSize.y
                end
            	table.insert(quads, newMeshQuad)

        	    newZ = newZ + self.tileSize.z
            until newZ >= self.rtf.z
            newY = newY + self.tileSize.y
        until newY >= self.rtf.y
    	newX = newX + self.tileSize.x
    until newX >= self.rtf.x

    return quads
end

---@param rowCount integer|nil The number of rows in tiles.png.mtx (default = 8)
---@param colCount integer|nil The number of columns in tiles.png.mtx (default = 8)
function MeshQuad:selectTile(rowCount, colCount)
    if self.tileSelected then
        warn("Tile alredy selected for quad")
        return
    end

    rowCount = rowCount or 8
    colCount = colCount or 8

    local tileWidth = 1 / colCount
    local tileHeight = 1 / rowCount

    -- local testTile = 62
    local testTile
    local row = math.floor((testTile or self.tile) / rowCount)
    local col = (testTile or self.tile) % colCount
    -- print(row, col)

    local paddingWidth, paddingHeight = (0.03125 * tileWidth), (0.03125 * tileHeight)

    local actualURange = {col * tileWidth + paddingWidth, (col + 1) * tileWidth - paddingWidth}
    local actualVRange = {row * tileHeight + paddingHeight, (row + 1) * tileHeight - paddingHeight}
    -- assert(actualURange[1] <= self.uvPair.lb.u)
    -- assert(actualURange[2] >= self.uvPair.rt.u)
    -- assert(actualVRange[1] <= self.uvPair.lb.v)
    -- assert(actualVRange[2] >= self.uvPair.rt.v)
    -- print(actualURange[1], actualURange[2], actualVRange[1], actualVRange[2])

    self.uvPair = UVPair:new(
        UV:new(
            actualURange[1] + self.uvPair.lb.u * (actualURange[2] - actualURange[1]),
            actualVRange[1] + self.uvPair.lb.v * (actualVRange[2] - actualVRange[1])
        ),
        UV:new(
            actualURange[1] + self.uvPair.rt.u * (actualURange[2] - actualURange[1]),
            actualVRange[1] + self.uvPair.rt.v * (actualVRange[2] - actualVRange[1])
        )
    )

    self.tileSelected = true
end

---@return {rtf: Vec3, ltf: Vec3, rbf: Vec3, rtb: Vec3, lbb: Vec3, rbb: Vec3, ltb: Vec3, lbf: Vec3}
function MeshQuad:getCorners()
    local rtf = self.rtf
    local lbb = self.lbb

    local ltf = Vec3:new(lbb.x, rtf.y, rtf.z)
    local rbf = Vec3:new(rtf.x, lbb.y, rtf.z)
    local rtb = Vec3:new(rtf.x, rtf.y, lbb.z)

    local rbb = Vec3:new(rtf.x, lbb.y, lbb.z)
    local ltb = Vec3:new(lbb.x, rtf.y, lbb.z)
    local lbf = Vec3:new(lbb.x, lbb.y, rtf.z)

    return {
        rtf = rtf, ltf = ltf, rbf = rbf, rtb = rtb,
        lbb = lbb, rbb = rbb, ltb = ltb, lbf = lbf
    }
end

-- TODO: make a parameter to specify if baking mesh in menu mode
---@param cameraXY Vec2|nil The X and Y corrdinates of the camera (default = Vec2(0, 1))
---@return boolean
function MeshQuad:isVisible(cameraXY)
    if self.normal.z == 1 then return true end -- faces camera, automatically visible
    if self.normal.z == -1 then return false end -- back faces camera, automatically not visible

    cameraXY = cameraXY or Vec2:new(0, 1)
    if self.normal.x == 1 then
    	-- faces right
    	return self.center.x < cameraXY.x
    elseif self.normal.x == -1 then
        -- faces left
        return self.center.x > cameraXY.x
    elseif self.normal.y == 1 then
        -- faces top
        return self.center.y < cameraXY.y
    elseif self.normal.y == -1 then
        -- faces bottom
        return self.center.y > cameraXY.y
    end
end

-- only used for ambient occlusion
---@class SimpleBox
---@field center Vec3
---@field size Vec3
---@field halfSize Vec3
---@field rtf Vec3
---@field lbb Vec3
local SimpleBox = {}

---@param center Vec3
---@param size Vec3
---@return SimpleBox
function SimpleBox:new(center, size)
    local halfSize = size * 0.5
    local o = {
        -- x is right, y is up, z is toward viewer
        center = center, size = size, halfSize = halfSize,
        rtf = center + halfSize, -- right top left vertex
        lbb = center - halfSize, -- left bottom back vertex
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return string
function SimpleBox:__tostring()
    return string.format(
        "SimpleBox(center = %s, size = %s)",
        tostring(self.center), tostring(self.size)
    )
end

---@return number
function SimpleBox:getVolume()
    return self.size.x * self.size.y * self.size.z
end

---@class MeshBox
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
local MeshBox = {}

---@param center Vec3
---@param size Vec3
---@param color {x: Color, y: Color, z: Color}
---@param tile Vec3
---@param tileSize Vec3
---@param tileRot Vec3
---@return MeshBox
function MeshBox:new(center, size, color, tile, tileSize, tileRot)
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
---@return MeshBox
function MeshBox:fromHalfSize(center, halfSize, color, tile, tileSize, tileRot)
    local size = halfSize * 2
    return MeshBox:new(center, size, color, tile, tileSize, tileRot)
end

---Makes a box from the table returned by the segment XML parser.
---@param elem {pos: Vec3, size: Vec3, color: {x: Color, y: Color, z: Color}, tile: Vec3, tileSize: Vec3, tileRot: Vec3}
---@return MeshBox
function MeshBox:fromElem(elem)
    return MeshBox:new(
        elem.pos, elem.size * 2,
        elem.color, elem.tile, elem.tileSize, elem.tileRot
    )
end

---@return string
function MeshBox:__tostring()
    return string.format(
        "MeshBox(center = %s, size = %s, color = {x = %s, y = %s, z = %s}, tile = %s, tileSize = %s, tileRot = %s)",
        tostring(self.center), tostring(self.size), tostring(self.color.x), tostring(self.color.y), tostring(self.color.z), tostring(self.tile), tostring(self.tileSize), tostring(self.tileRot)
    )
end

---@return number
function MeshBox:getVolume()
    return self.size.x * self.size.y * self.size.z
end

---@return {rtf: Vec3, ltf: Vec3, rbf: Vec3, rtb: Vec3, lbb: Vec3, rbb: Vec3, ltb: Vec3, lbf: Vec3}
function MeshBox:getCorners()
    local rtf = self.rtf
    local lbb = self.lbb

    local ltf = Vec3:new(lbb.x, rtf.y, rtf.z)
    local rbf = Vec3:new(rtf.x, lbb.y, rtf.z)
    local rtb = Vec3:new(rtf.x, rtf.y, lbb.z)

    local rbb = Vec3:new(rtf.x, lbb.y, lbb.z)
    local ltb = Vec3:new(lbb.x, rtf.y, lbb.z)
    local lbf = Vec3:new(lbb.x, lbb.y, rtf.z)

    return {
        rtf = rtf, ltf = ltf, rbf = rbf, rtb = rtb,
        lbb = lbb, rbb = rbb, ltb = ltb, lbf = lbf
    }
end

---@return {right: Vec3, left: Vec3, top: Vec3, bottom: Vec3, front: Vec3, back: Vec3}
function MeshBox:getFaceCenters()
    local rtf = self.rtf

    local right = Vec3:new(rtf.x, rtf.y - self.halfSize.y, rtf.z - self.halfSize.z)
    local top   = Vec3:new(rtf.x - self.halfSize.x, rtf.y, rtf.z - self.halfSize.z)
    local front = Vec3:new(rtf.x - self.halfSize.x, rtf.y - self.halfSize.y, rtf.z)

    local lbb = self.lbb
    local left   = Vec3:new(lbb.x, lbb.y + self.halfSize.y, lbb.z + self.halfSize.z)
    local bottom = Vec3:new(lbb.x + self.halfSize.x, lbb.y, lbb.z + self.halfSize.z)
    local back   = Vec3:new(lbb.x + self.halfSize.x, lbb.y + self.halfSize.y, lbb.z)

    return {
        right = right, left = left,
        top = top, bottom = bottom,
        front = front, back = back
    }
end

---@return {right: MeshQuad, left: MeshQuad, top: MeshQuad, bottom: MeshQuad, front: MeshQuad, back: MeshQuad}
function MeshBox:getFaces()
    local faceCenters = self:getFaceCenters()

    local right  = MeshQuad:new(faceCenters.right , Vec3:new(0          , self.size.y, self.size.z), Vec3:new(1 , 0 ,  0), self.color.x, self.tile.x, self.tileSize, self.tileRot.x)
    local left   = MeshQuad:new(faceCenters.left  , Vec3:new(0          , self.size.y, self.size.z), Vec3:new(-1, 0 ,  0), self.color.x, self.tile.x, self.tileSize, self.tileRot.x)
    local top    = MeshQuad:new(faceCenters.top   , Vec3:new(self.size.x, 0          , self.size.z), Vec3:new(0 , 1 ,  0), self.color.y, self.tile.y, self.tileSize, self.tileRot.y)
    local bottom = MeshQuad:new(faceCenters.bottom, Vec3:new(self.size.x, 0          , self.size.z), Vec3:new(0 , -1,  0), self.color.y, self.tile.y, self.tileSize, self.tileRot.y)
    local front  = MeshQuad:new(faceCenters.front , Vec3:new(self.size.x, self.size.y, 0)          , Vec3:new(0 , 0 ,  1), self.color.z, self.tile.z, self.tileSize, self.tileRot.z)
    local back   = MeshQuad:new(faceCenters.back  , Vec3:new(self.size.x, self.size.y, 0)          , Vec3:new(0 , 0 , -1), self.color.z, self.tile.z, self.tileSize, self.tileRot.z)

    return {
        right = right, left = left,
        top = top, bottom = bottom,
        front = front, back = back
    }
end

---@param other MeshBox|SimpleMeshBox
---@return number
function MeshBox:getIntersectionVolume(other)
    local overlap = {
        x = math.max(0, math.min(self.rtf.x, other.rtf.x) - math.max(self.lbb.x, other.lbb.x)),
        y = math.max(0, math.min(self.rtf.y, other.rtf.y) - math.max(self.lbb.y, other.lbb.y)),
        z = math.max(0, math.min(self.rtf.z, other.rtf.z) - math.max(self.lbb.z, other.lbb.z)),
    }
    return overlap.x * overlap.y * overlap.z
end

---@param other MeshBox|SimpleMeshBox|MeshQuad
---@return boolean
function MeshBox:fullySurrounds(other)
    return self.lbb.x <= other.lbb.x and self.lbb.y <= other.lbb.y and self.lbb.z <= other.lbb.z
        and self.rtf.x >= other.rtf.x and self.rtf.y >= other.rtf.y and self.rtf.z >= other.rtf.z
end


---@param parsedSegment Element
local function bakeMesh(parsedSegment)
    --[[
        1. for each box, get its faces as quads
        2. test if the quad is not back-facing the player (isVisible)
        3. for each face, subdivide it into smallMeshQuads
        4. check if smallMeshQuad is not inside another box and tht it actually has area
        5. select the tile for each smallMeshQuad
        6. make 2 triangles out of every smallMeshQuad
        7. rotate UVs according to tileRot
        8. write everything into a mesh file
    ]]

    local boxes = {}
    for _, v in ipairs(parsedSegment._children) do
        if v:getTagName() == "box" then
            table.insert(boxes, MeshBox:fromElem(v))
        end
    end

    local light = {
        right = parsedSegment.lightRight,
        left = parsedSegment.lightLeft,
        top = parsedSegment.lightTop,
        bottom = parsedSegment.lightBottom,
        front = parsedSegment.lightFront,
        back = parsedSegment.lightBack,
    }
    
    ---@type {x: number, y: number, z: number, u: number, v: number, r: number, g: number, b: number, a: number, normal: Vec3}[]
    local vertices = {}
    ---@type number[][]
    local indices = {}

    for _, box in ipairs(boxes) do
        local faces = box:getFaces()
    	for _, quad in pairs(faces) do
            if quad:isVisible() then
                if quad.normal.x == 1 then
                    quad.color = quad.color:mulRGB(light.right)
                elseif quad.normal.x == -1 then
                    quad.color = quad.color:mulRGB(light.left)
                elseif quad.normal.y == 1 then
                    quad.color = quad.color:mulRGB(light.top)
                elseif quad.normal.y == -1 then
                    quad.color = quad.color:mulRGB(light.bottom)
                elseif quad.normal.z == 1 then
                    quad.color = quad.color:mulRGB(light.front)
                elseif quad.normal.z == -1 then
                    quad.color = quad.color:mulRGB(light.back)
                end
            	for _, smallMeshQuad in ipairs(quad:subdivideInto()) do
            	    ---@cast smallMeshQuad MeshQuad
            	    local smallMeshQuadIsContained = false
            	    for _, testMeshBox in ipairs(boxes) do
                    	if testMeshBox ~= box and testMeshBox:fullySurrounds(smallMeshQuad) then
                        	smallMeshQuadIsContained = true
                        end
                    end
                    if (not smallMeshQuadIsContained) and smallMeshQuad:getArea() > 0 then
                    	smallMeshQuad:selectTile()

                	    -- indices
                	    local baseIndex = #vertices
                        table.insert(indices, {baseIndex + 0, baseIndex + 1, baseIndex + 2})
                        table.insert(indices, {baseIndex + 2, baseIndex + 1, baseIndex + 3})

                        -- vertices
                        local corners = smallMeshQuad:getCorners()
                        local quadVertices = {}
                        -- rotate cw: 1234 -> 3142, rotate ccw: 1234 -> 2143
                        if smallMeshQuad.normal.x == 1 then
                            -- faces right
                            quadVertices = {corners.rtf, corners.rbf, corners.rtb, corners.rbb}
                        elseif smallMeshQuad.normal.x == -1 then
                            -- faces left
                            quadVertices = {corners.ltb, corners.lbb, corners.ltf, corners.lbf}
                        elseif smallMeshQuad.normal.y == 1 then
                            -- faces top
                            quadVertices = {corners.ltb, corners.ltf, corners.rtb, corners.rtf}
                        elseif smallMeshQuad.normal.y == -1 then
                            -- faces bottom
                            quadVertices = {corners.lbf, corners.lbb, corners.rbf, corners.rbb}
                        elseif smallMeshQuad.normal.z == 1 then
                            -- faces front
                            quadVertices = {corners.ltf, corners.lbf, corners.rtf, corners.rbf}
                        elseif smallMeshQuad.normal.z == -1 then
                            -- faces back
                            quadVertices = {corners.rtb, corners.rbb, corners.ltb, corners.lbb}
                        end

                        local uvs = smallMeshQuad.uvPair:getIndividualCorners()
                        for _ = 1, smallMeshQuad.tileRot do
                            uvs:rotateClockwiseInPlace()
                        end

                        table.insert(vertices, { -- top left vertex (lt)
                            x = quadVertices[1].x, y = quadVertices[1].y, z = quadVertices[1].z, u = uvs.lt.u, v = uvs.lt.v,
                            r = smallMeshQuad.color.r * 127, g = smallMeshQuad.color.g * 127, b = smallMeshQuad.color.b * 127, a = 255,
                            normal = smallMeshQuad.normal,
                        })
                        table.insert(vertices, { -- bottom left vertex (lb)
                            x = quadVertices[2].x, y = quadVertices[2].y, z = quadVertices[2].z, u = uvs.lb.u, v = uvs.lb.v,
                            r = smallMeshQuad.color.r * 127, g = smallMeshQuad.color.g * 127, b = smallMeshQuad.color.b * 127, a = 255,
                            normal = smallMeshQuad.normal,
                        })
                        table.insert(vertices, { -- top right vertex (rt)
                            x = quadVertices[3].x, y = quadVertices[3].y, z = quadVertices[3].z, u = uvs.rt.u, v = uvs.rt.v,
                            r = smallMeshQuad.color.r * 127, g = smallMeshQuad.color.g * 127, b = smallMeshQuad.color.b * 127, a = 255,
                            normal = smallMeshQuad.normal,
                        })
                        table.insert(vertices, { -- bottom right vertex (rb)
                            x = quadVertices[4].x, y = quadVertices[4].y, z = quadVertices[4].z, u = uvs.rb.u, v = uvs.rb.v,
                            r = smallMeshQuad.color.r * 127, g = smallMeshQuad.color.g * 127, b = smallMeshQuad.color.b * 127, a = 255,
                            normal = smallMeshQuad.normal,
                        })
                    end
                end
            end
        end
    end

    for _, vertex in ipairs(vertices) do
    	local occludeMeshBox = SimpleBox:new(Vec3:new(vertex.x + vertex.normal.x, vertex.y + vertex.normal.y, vertex.z + vertex.normal.z), Vec3:new(1, 1, 1))
    	local occludeMeshBoxVolume = occludeMeshBox:getVolume()
    	local totalIntersectionVolume = 0
    	for _, box in ipairs(boxes) do
            totalIntersectionVolume = totalIntersectionVolume + box:getIntersectionVolume(occludeMeshBox)
        end
        local shade = math.min(math.max(totalIntersectionVolume, 0), occludeMeshBoxVolume) / occludeMeshBoxVolume
        vertex.a = vertex.a * (1 - 0.47 * (shade ^ (1/3)))
    end

    -- print("packing...")

    local bin = ""
    -- how many vertices
    bin = bin .. utils.leStrFromUInt32(#vertices)
    --[[
        write the vertices
        vertices: {
            {x, y, z, u, v, r, g, b, a}, ...
        }
    ]]

    -- for this operation we could instead go bin = bin .. love.data.pack(...),
    -- but string concatenation in Lua is apparently quite slow so instead we use a temporary table
    local binVertices = {}
    for _, vertex in ipairs(vertices) do
        table.insert(binVertices, love.data.pack(
            "string",
            "<f<f<f<f<f<I1<I1<I1<I1",
            vertex.x, vertex.y, vertex.z, vertex.u, vertex.v, vertex.r, vertex.g, vertex.b, vertex.a
        ))
    end
    bin = bin .. table.concat(binVertices, "")

    -- how many indices
    bin = bin .. utils.leStrFromUInt32(#indices)
    --[[
        write the indices
        indices: {
            {1, 2, 3}, ...
        }
    ]]
    local binIndices = {}
    for _, index in ipairs(indices) do
    	table.insert(binIndices, love.data.pack("string", "<i4<i4<i4", index[1], index[2], index[3]))
    end
    bin = bin .. table.concat(binIndices, "")

    -- print("writing file...")

    local file, err = io.open("test.mesh", "wb")
    if file then
        file:write(utils.compressZlib(bin))
        file:close()
    else
        error(err)
    end
end

-- sample driver code to bake a mesh
local templates = utils.readXml(utils.readFile("smashhit143/assets/templates.xml.mp3"))
-- local segment = utils.readXml(utils.decompressGZip(utils.readFileBin("smashhit143/assets/segments/holodeck/calm0.xml.gz.mp3")))
local segment = utils.readXml(utils.decompressGZip(utils.readFileBin("smashhit143/assets/segments/basic/basic/start.xml.gz.mp3")))
utils.printTable(segment)
local segmentParsed = segmentXmlLoader.parseSegments(segment, templates)
-- utils.printTable(segmentParsed)
bakeMesh(segmentParsed)
