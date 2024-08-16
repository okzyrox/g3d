-- written by groverbuger for g3d
-- september 2021
-- MIT license

local Matrix = require(g3d.path .. ".matrix")
local loader = require(g3d.path .. ".loader")
local collisions = require(g3d.path .. ".collisions")
local vectors = require(g3d.path .. ".vectors")
local camera = require(g3d.path .. ".camera")

local Class = require("lib.classic")

local vectorCrossProduct = vectors.crossProduct
local vectorNormalize = vectors.normalize

----------------------------------------------------------------------------------------------------
-- define a model class
----------------------------------------------------------------------------------------------------

local model = {}
local Model = Class:extend()

local shader = g3d.shader

function Model:new(obj, texture, translation, rotation, scale)
    if obj == nil and texture == nil and translation == nil and rotation == nil and scale == nil then
        return self
    end
    -- if verts is a string, use it as a path to a .obj file
    -- otherwise verts is a table, use it as a model defintion
    if type(obj) == "string" then
        obj = loader:loadObj(obj)
    end

    -- if texture is a string, use it as a path to an image file
    -- otherwise texture is already an image, so don't bother
    if type(texture) == "string" then
        texture = love.graphics.newImage(texture)
    end

    self.vertexFormat = {
        { "VertexPosition", "float", 3 },
        { "VertexTexCoord", "float", 2 },
        { "VertexNormal",   "float", 3 },
        { "VertexColor",    "byte",  4 },
    }
    self.shader = shader

    self.verts = obj
    self.texture = texture
    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
    self.matrix = Matrix.newMatrix()
    if type(scale) == "number" then scale = { scale, scale, scale } end
    self:setTransform(translation or { 0, 0, 0 }, rotation or { 0, 0, 0 }, scale or { 1, 1, 1 })

    return self
end

-- populate model's normals in model's mesh automatically
-- if true is passed in, then the normals are all flipped
function Model:makeNormals(isFlipped)
    for i = 1, #self.verts, 3 do
        if isFlipped then
            self.verts[i + 1], self.verts[i + 2] = self.verts[i + 2], self.verts[i + 1]
        end

        local vp = self.verts[i]
        local v = self.verts[i + 1]
        local vn = self.verts[i + 2]

        local n_1, n_2, n_3 = vectorNormalize(vectorCrossProduct(v[1] - vp[1], v[2] - vp[2], v[3] - vp[3], vn[1] - v[1],
            vn[2] - v[2], vn[3] - v[3]))
        vp[6], v[6], vn[6] = n_1, n_1, n_1
        vp[7], v[7], vn[7] = n_2, n_2, n_2
        vp[8], v[8], vn[8] = n_3, n_3, n_3
    end

    self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
end

-- move and rotate given two 3d vectors
function Model:setTransform(translation, rotation, scale)
    self.translation = translation or self.translation
    self.rotation = rotation or self.rotation
    self.scale = scale or self.scale
    self:updateMatrix()
end

-- move given one 3d vector
function Model:setTranslation(tx, ty, tz)
    self.translation[1] = tx
    self.translation[2] = ty
    self.translation[3] = tz
    self:updateMatrix()
end

-- rotate given one 3d vector
-- using euler angles
function Model:setRotation(rx, ry, rz)
    self.rotation[1] = rx
    self.rotation[2] = ry
    self.rotation[3] = rz
    self.rotation[4] = nil
    self:updateMatrix()
end

-- create a quaternion from an axis and an angle
function Model:setAxisAngleRotation(x, y, z, angle)
    x, y, z = vectorNormalize(x, y, z)
    angle = angle / 2

    self.rotation[1] = x * math.sin(angle)
    self.rotation[2] = y * math.sin(angle)
    self.rotation[3] = z * math.sin(angle)
    self.rotation[4] = math.cos(angle)

    self:updateMatrix()
end

-- rotate given one quaternion
function Model:setQuaternionRotation(x, y, z, w)
    self.rotation[1] = x
    self.rotation[2] = y
    self.rotation[3] = z
    self.rotation[4] = w
    self:updateMatrix()
end

-- resize model's matrix based on a given 3d vector
function Model:setScale(sx, sy, sz)
    self.scale[1] = sx
    self.scale[2] = sy or sx
    self.scale[3] = sz or sx
    self:updateMatrix()
end

-- update the model's transformation matrix
function Model:updateMatrix()
    self.matrix:setTransformationMatrix(self.translation, self.rotation, self.scale)
end

-- draw the model
function Model:draw(shader, light)
    local shader = shader or self.shader
    love.graphics.setShader(shader)
    shader:send("modelMatrix", self.matrix)
    shader:send("viewMatrix", camera.getCurrent():getViewMatrix()) -- Might add these functions to the `cameras` class, which just calls the functions from the current camera
    shader:send("projectionMatrix", camera.getCurrent():getProjectionMatrix())
    if light then
        shader:send("lightPosition", light.position)
        shader:send("lightDirection", light.direction)
        shader:send("lightColor", light.color)
        shader:send("lightIntensity", light.intensity)
    end
    if shader:hasUniform "isCanvasEnabled" then
        shader:send("isCanvasEnabled", love.graphics.getCanvas() ~= nil)
    end
    love.graphics.draw(self.mesh)
    love.graphics.setShader()
end

-- the fallback function if ffi was not loaded
function Model:compress()
    print("[g3d warning] Compression requires FFI!\n" .. debug.traceback())
end

-- makes models use less memory when loaded in ram
-- by storing the vertex data in an array of vertix structs instead of lua tables
-- requires ffi
-- note: throws away the model's verts table
local success, ffi = pcall(require, "ffi")
if success then
    ffi.cdef([[
        struct vertex {
            float x, y, z;
            float u, v;
            float nx, ny, nz;
            uint8_t r, g, b, a;
        }
    ]])

    function model:compress()
        local data = love.data.newByteData(ffi.sizeof("struct vertex") * #self.verts)
        local datapointer = ffi.cast("struct vertex *", data:getFFIPointer())

        for i, vert in ipairs(self.verts) do
            local dataindex           = i - 1
            datapointer[dataindex].x  = vert[1]
            datapointer[dataindex].y  = vert[2]
            datapointer[dataindex].z  = vert[3]
            datapointer[dataindex].u  = vert[4] or 0
            datapointer[dataindex].v  = vert[5] or 0
            datapointer[dataindex].nx = vert[6] or 0
            datapointer[dataindex].ny = vert[7] or 0
            datapointer[dataindex].nz = vert[8] or 0
            datapointer[dataindex].r  = (vert[9] or 1) * 255
            datapointer[dataindex].g  = (vert[10] or 1) * 255
            datapointer[dataindex].b  = (vert[11] or 1) * 255
            datapointer[dataindex].a  = (vert[12] or 1) * 255
        end

        self.mesh:release()
        self.mesh = love.graphics.newMesh(self.vertexFormat, #self.verts, "triangles")
        self.mesh:setVertices(data)
        self.mesh:setTexture(self.texture)
        self.verts = nil
    end
end

function Model:rayIntersection(...)
    return collisions.rayIntersection(self.verts, self, ...)
end

function Model:isPointInside(...)
    return collisions.isPointInside(self.verts, self, ...)
end

function Model:sphereIntersection(...)
    return collisions.sphereIntersection(self.verts, self, ...)
end

function Model:closestPoint(...)
    return collisions.closestPoint(self.verts, self, ...)
end

function Model:capsuleIntersection(...)
    return collisions.capsuleIntersection(self.verts, self, ...)
end

function Model.newModel(obj, texture, translation, rotation, scale)
    return Model(obj, texture, translation, rotation, scale)
end

return Model
