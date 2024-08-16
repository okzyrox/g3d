-- written by okzyrox for g3d
-- MIT

-- Box 3d is a 3d model that has physics properties.


local camera = require(g3d.path .. ".camera")
local model = require(g3d.path .. ".model")

local Class = require("lib.classic")

local box_asset = g3d.path .. "/assets/box.obj"
local shader = g3d.shader

local Box3D = Class:extend()
function Box3D:new(texture, position, rotation, scale)
    self.model = model.newModel(box_asset, texture, position, rotation, scale)
    
    -- Physics properties
    self.position = position
    self.velocity = {x = 0, y = 0, z = 0}
    self.acceleration = {x = 0, y = 0, z = 0}
    self.mass = 1
    self.gravity = {x = 0, y = -9.81, z = 0}
    self.friction = 0.1
    self.restitution = 0.5
    
    self.boundingBox = {
        min = {x = -0.5, y = -0.5, z = -0.5},
        max = {x = 0.5, y = 0.5, z = 0.5}
    }
end

function Box3D:update(dt)
    -- Apply gravity

    self.acceleration.x = self.acceleration.x * 0.1 + self.gravity.x
    self.acceleration.y = self.acceleration.y * 0.1 + self.gravity.y
    self.acceleration.z = self.acceleration.z * 0.1 * self.gravity.z
    
    self.velocity.x = self.velocity.x + self.acceleration.x * dt
    self.velocity.y = self.velocity.y + self.acceleration.y * dt
    self.velocity.z = self.velocity.z + self.acceleration.z * dt
    
    local frictionFactor = 1 - self.friction * dt
    self.velocity.x = self.velocity.x * frictionFactor
    self.velocity.z = self.velocity.z * frictionFactor
    
    local newPosition = {
        self.position[1] + self.velocity.x * dt,
        self.position[2] + self.velocity.y * dt,
        self.position[3] + self.velocity.z * dt
    }
    
    -- Ground is 0
    if newPosition[2] < 0 then
        newPosition[2] = 0
        self.velocity.y = -self.velocity.y * self.restitution
    end
    
    -- Update model
    self.position = newPosition
    self.model:setTranslation(newPosition[1], newPosition[2], newPosition[3])
end

function Box3D:applyForce(fx, fy, fz)
    print("Accel: x: ", self.acceleration.x, "y: ", self.acceleration.y, "z: ", self.acceleration.z)
    self.acceleration.x = self.acceleration.x + fx / self.mass
    self.acceleration.y = self.acceleration.y + fy / self.mass
    self.acceleration.z = self.acceleration.z + fz / self.mass
    print("Accel: x: ", self.acceleration.x, "y: ", self.acceleration.y, "z: ", self.acceleration.z)

end

function Box3D:checkCollision(other)
    local a = self:getWorldBoundingBox()
    local b = other:getWorldBoundingBox()
    
    return (a.min.x <= b.max.x and a.max.x >= b.min.x) and
           (a.min.y <= b.max.y and a.max.y >= b.min.y) and
           (a.min.z <= b.max.z and a.max.z >= b.min.z)
end

function Box3D:getWorldBoundingBox()
    local pos = self.position
    local scale = self.model.scale
    return {
        min = {
            x = pos[1] + self.boundingBox.min.x * scale[1],
            y = pos[2] + self.boundingBox.min.y * scale[2],
            z = pos[3] + self.boundingBox.min.z * scale[3]
        },
        max = {
            x = pos[1] + self.boundingBox.max.x * scale[1],
            y = pos[2] + self.boundingBox.max.y * scale[2],
            z = pos[3] + self.boundingBox.max.z * scale[3]
        }
    }
end

function Box3D:draw()
    self.model:draw()
end

function Box3D.newBox3D(texture, position, rotation, scale)
    return Box3D(texture, position, rotation, scale)
end

return Box3D
