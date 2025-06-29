--[[
    NOTE:
    extract the Smash Hit APK into a folder called
    smashhit143
    so this program can read the required files

    this program will try to read a file
    test.mesh
    in the root directory. this is defined in variable
    state.editor.meshFilePath

    not much functionality is implemented so just
    comment/uncomment code to disable/enable features.
]]

local Quaternion = require("lib.quaternion").Quaternion
local vector = require("lib.vector")
local Vec2, Vec3, Vec4 = vector.Vec2, vector.Vec3, vector.Vec4
local Mat4 = require("lib.matrix").Mat4

local utils = require("lib.utils")
local parseMeshData = require("lib.meshreader").parseMeshData
local parseMtxFile = require("lib.mtx").parseMtxFile

-- require("lib.testxml")
-- require("lib.meshbaker")
-- require("lib.segment")

local state = {
    renderer = {
        shader = love.graphics.newShader
        [[
            #pragma language glsl3
            uniform mat4 proj_matrix;
            uniform mat4 view_matrix;

            #ifdef VERTEX
            vec4 position(mat4 transform_projection, vec4 vertex_position) {
                return proj_matrix * view_matrix * vec4(vertex_position.xyz, 1.0);
            }
            #endif

            #ifdef PIXEL
            vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
                vec4 tex_color = Texel(tex, texture_coords);
                // return tex_color * vec4(color.xyz * color.w, 1.0); // more obvious ambient occlusion
                return tex_color * vec4(color.xyz * (2 * sqrt(color.w) - color.w), 1.0); // correct ambient occlusion calculation
            }
            #endif
        ]],
        mesh = nil,
        projMatrix = nil,
        viewMatrix = nil,
    },
    editor = {
        templatesFilePath = "smashhit143/assets/templates.xml.mp3",
        segmentXmlFilePath = "smashhit143/assets/segments/basic/basic/start.xml.gz.mp3",
        -- meshFilePath = "smashhit143/assets/segments/basic/basic/start.mesh.mp3",
        meshFilePath = "test.mesh",
        cameraPos = Vec3:new(0, 1, 0),
        cameraRot = Vec2.ZERO,
        wireframeMode = false,
    },
    windowSize = Vec2:new(800, 400),
    cursorFree = false,
    time = 0,
}

function love.load()
    local vertices, indices = parseMeshData(state.editor.meshFilePath)
    state.renderer.mesh = love.graphics.newMesh({
        -- each component must be multiple of 4 bytes
        {"VertexPosition", "float", 3},
        {"VertexTexCoord", "float", 2},
        {"VertexColor", "byte", 4},
    }, vertices, "triangles")
    state.renderer.mesh:setVertexMap(indices)
    state.renderer.mesh:setTexture(parseMtxFile("smashhit143/assets/gfx/tiles.png.mtx.mp3").image2)

    state.renderer.viewMatrix =
        Mat4:fromQuaternion(Quaternion:fromAxisAngle(1, 0, 0, state.editor.cameraRot.y))
        * Mat4:fromQuaternion(Quaternion:fromAxisAngle(0, 1, 0, state.editor.cameraRot.x))
        * Mat4:fromTranslation(-state.editor.cameraPos.x, -state.editor.cameraPos.y, -state.editor.cameraPos.z)
    state.renderer.projMatrix = Mat4:fromPerspectiveRhGL(1, 4/3, 0.01, 1000)
    state.renderer.shader:send("view_matrix", state.renderer.viewMatrix:toFlatArray())
    state.renderer.shader:send("proj_matrix", state.renderer.projMatrix:toFlatArray())

    love.graphics.setMeshCullMode("back")
    love.graphics.setDepthMode("lequal", true)
    love.mouse.setRelativeMode(true)
    love.window.setMode(800, 400, { resizable = true })
    -- love.graphics.setWireframe(true)
end

function love.update(dt)
    state.time = state.time + dt

    -- update state.windowSize and projection matrix
    local width, height = love.window.getMode()
    if width ~= state.windowSize.x or height ~= state.windowSize.y then
    	state.windowSize.x = width
    	state.windowSize.y = height
        state.renderer.projMatrix = Mat4:fromPerspectiveRhGL(1, state.windowSize.x / state.windowSize.y, 0.01, 1000)
        state.renderer.shader:send("proj_matrix", state.renderer.projMatrix:toFlatArray())
    end

    -- calculate camera rotation
    local cameraQuat =
        Quaternion:fromAxisAngle(0, 1, 0, state.editor.cameraRot.x)
        * Quaternion:fromAxisAngle(1, 0, 0, state.editor.cameraRot.y)

    local advanceXAxis = cameraQuat:applyToVec3(Vec3.RIGHT)
    -- local advanceYAxis = cameraQuat:applyToVec3(Vec3.TOP)
    local advanceZAxis = cameraQuat:applyToVec3(Vec3.BACK)

    -- movement, the vector3s are rotated according to the camera rotation
    -- no need to care about diagonal strafing this isn't a game
    local moveSpeed = 0.2
    if love.keyboard.isDown("w") then
        state.editor.cameraPos = state.editor.cameraPos + (advanceZAxis * moveSpeed)
    end
    if love.keyboard.isDown("s") then
        state.editor.cameraPos = state.editor.cameraPos - (advanceZAxis * moveSpeed)
    end
    if love.keyboard.isDown("d") then
        state.editor.cameraPos = state.editor.cameraPos + (advanceXAxis * moveSpeed)
    end
    if love.keyboard.isDown("a") then
        state.editor.cameraPos = state.editor.cameraPos - (advanceXAxis * moveSpeed)
    end
    -- for up (e) and down (q) movements, ignore camera and use absolute up/down to be less disorienting
    if love.keyboard.isDown("e") then
        state.editor.cameraPos = state.editor.cameraPos + (Vec3.TOP * moveSpeed)
        -- state.editor.cameraPos = state.editor.cameraPos + (advanceYAxis * moveSpeed)
    end
    if love.keyboard.isDown("q") then
        state.editor.cameraPos = state.editor.cameraPos + (Vec3.BOTTOM * moveSpeed)
        -- state.editor.cameraPos = state.editor.cameraPos - (advanceYAxis * moveSpeed)
    end

    -- free cursor with LeftAlt
    if love.keyboard.isDown("lalt") and state.cursorFree == false then
        love.mouse.setRelativeMode(false)
        state.cursorFree = true
    elseif not love.keyboard.isDown("lalt") and state.cursorFree == true then
        love.mouse.setRelativeMode(true)
        state.cursorFree = false
    end

    -- update view matrix (the one that handles camera rotation and translation)
    state.renderer.viewMatrix =
        Mat4:fromQuaternion(Quaternion:fromAxisAngle(1, 0, 0, state.editor.cameraRot.y))
        * Mat4:fromQuaternion(Quaternion:fromAxisAngle(0, 1, 0, state.editor.cameraRot.x))
        * Mat4:fromTranslation(-state.editor.cameraPos.x, -state.editor.cameraPos.y, -state.editor.cameraPos.z)
    -- state.renderer.viewMatrix =
        -- Mat4:new(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        -- * Mat4:fromQuaternion(Quaternion:fromAxisAngle(0, 0, 1, time))
        -- * Mat4:fromQuaternion(Quaternion:fromAxisAngle(1, 0, 0, time))
        -- * Mat4:fromTranslation(0, -1, 10 + time * 5)
    state.renderer.shader:send("view_matrix", state.renderer.viewMatrix:toFlatArray())
end

function love.mousemoved(x, y, dx, dy, isTouch)
    if not state.cursorFree then
        local rotSpeed = 0.004
        -- rotate the camera
        state.editor.cameraRot = state.editor.cameraRot - (Vec2:new(dx, dy) * rotSpeed)
        -- clamp the x and y to 0 <= x <= 2pi, -pi/2 <= y <= pi/2
        state.editor.cameraRot.x = state.editor.cameraRot.x % (2 * math.pi)
        state.editor.cameraRot.y = math.min(math.max(state.editor.cameraRot.y, -math.pi / 2), math.pi / 2)
        -- reset cursor position so it is always contained inside the window
    	love.mouse.setPosition(0, 0)
    end

end

function love.keypressed(key)
    if key == "c" then
        state.editor.wireframeMode = not state.editor.wireframeMode
        love.graphics.setWireframe(state.editor.wireframeMode)
    end
end

function love.draw()
    love.graphics.setShader(state.renderer.shader)
    love.graphics.draw(state.renderer.mesh)
end
