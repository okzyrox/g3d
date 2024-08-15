-- World
-- stores a list of models to update and draw
-- written by okzyrox
-- MIT license

local cameras = require(g3d.path .. ".camera")
local Class = require("lib.classic")

local world = Class:extend()

function world:new()
    self.models = {}
    self.cameras = cameras()
    self.cameras.getCurrent():updateProjectionMatrix()
    self.cameras.getCurrent():updateViewMatrix()
end

function world:add(model)
    table.insert(self.models, model)
end

function world:update(dt)
    for _, model in ipairs(self.models) do
        if model.update then
            model:update(dt)
        end
    end
end

function world:draw()
    for _, model in ipairs(self.models) do
        model:draw()
    end
end

function world.newWorld()
    return world()
end

return world