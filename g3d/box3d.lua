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
    self.position = {position[1], position[3], position[2]}
    self.static_block = false
    self.velocity = {x = 0, y = 0, z = 0}
    self.acceleration = {x = 0, y = 0, z = 0}
    self.mass = 1
    self.gravity = {x = 0, y = -9.81, z = 0}
    self.friction = 0.5
    self.restitution = 0.5

    self.gravityMultiplier = 8
    self.terminalVelocity = 160
    
    self.boundingBox = {
        min = {x = -0.5, y = -0.5, z = -0.5},
        max = {x = 0.5, y = 0.5, z = 0.5}
    }

    self.model:setTranslation(self.position[1], self.position[3], self.position[2])
end

function Box3D:update(dt)
    if not self.static_block then
        self.acceleration.y = self.acceleration.y + self.gravity.y * self.gravityMultiplier * dt

        self.velocity.x = self.velocity.x + self.acceleration.x * dt
        self.velocity.y = self.velocity.y + self.acceleration.y * dt
        self.velocity.z = self.velocity.z + self.acceleration.z * dt
        
        if self.velocity.y < -self.terminalVelocity then
            self.velocity.y = -self.terminalVelocity
        end

        -- less friction midair
        local frictionFactor = self.position[2] > 0 and (1 - self.friction * dt * 1) or (1 - self.friction * dt * 0.5)
        self.velocity.x = self.velocity.x * frictionFactor
        self.velocity.y = self.velocity.y * frictionFactor
        self.velocity.z = self.velocity.z * frictionFactor

        local newPosition = {
            [1] = self.position[1] + self.velocity.x * dt,
            [2] = self.position[2] + self.velocity.y * dt,
            [3] = self.position[3] + self.velocity.z * dt
        }
        
        -- Ground is 0
        if newPosition[2] < 0 then
            newPosition[2] = 0
            self.velocity.y = -self.velocity.y * self.restitution
        end

        -- Update model
        self.position = newPosition
        self.model:setTranslation(newPosition[1], newPosition[3], newPosition[2])

        self.acceleration.x = 0
        self.acceleration.y = 0
        self.acceleration.z = 0
    end
end

function Box3D:applyForce(fx, fz, fy)
    self.acceleration.x = self.acceleration.x + fx / self.mass
    self.acceleration.y = self.acceleration.y + fy / self.mass
    self.acceleration.z = self.acceleration.z + fz / self.mass
end

function Box3D:getPosition()
    return {
        x = self.position[1],
        y = self.position[2],
        z = self.position[3]
    }
    
end

function Box3D:getVelocity()
    return {
        x = self.velocity.x,
        y = self.velocity.y,
        z = self.velocity.z
    }
end

function Box3D:getAcceleration()
    return {
        x = self.acceleration.x,
        y = self.acceleration.y,
        z = self.acceleration.z
    }
end

-- The gravity force applied to the box from each angle. Currently only checks for the y axis, so other values can cause the box to fall infinitely.
function Box3D:getGravity()
    return {
        x = self.gravity.x,
        y = self.gravity.y,
        z = self.gravity.z
    }
end

-- Gravity Multiplier increases the speed of gravity applied to the box while falling
function Box3D:getGravityMultiplier()
    return self.gravityMultiplier
end

-- Drag slowdown rate of the box when moving along the ground/air. amplified while in air
function Box3D:getFriction()
    return self.friction
end

-- Maximum speed at which the box will fall
function Box3D:getTerminalVelocity()
    return self.terminalVelocity
end

-- Restitution is the "bounciness" of the box when it hits the ground
function Box3D:getRestitution()
    return self.restitution
end

-- Static determines whether the box is affected by: friction, gravity, velocity, acceleration, etc
function Box3D:getStatic()
    return self.static_block
end

function Box3D:setVelocity(x, y, z)
    self.velocity.x = x
    self.velocity.y = y
    self.velocity.z = z
end

function Box3D:setGravityMultiplier(multiplier)
    self.gravityMultiplier = multiplier
end

function Box3D:setTerminalVelocity(velocity)
    self.terminalVelocity = velocity
end

function Box3D:setAcceleration(x, y, z)
    self.acceleration.x = x
    self.acceleration.y = y
    self.acceleration.z = z
end

function Box3D:setGravity(x, y, z)
    self.gravity.x = x
    self.gravity.y = y
    self.gravity.z = z
end

function Box3D:setStatic(state)
    self.static_block = state
end

function Box3D:isOnGround()
    return self.position[2] == 0
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
            y = pos[3] + self.boundingBox.min.y * scale[2],
            z = pos[2] + self.boundingBox.min.z * scale[3]
        },
        max = {
            x = pos[1] + self.boundingBox.max.x * scale[1],
            y = pos[3] + self.boundingBox.max.y * scale[2],
            z = pos[2] + self.boundingBox.max.z * scale[3]
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
