-- World
-- stores a list of models to update and draw
-- written by okzyrox
-- MIT license

local cameras = require(g3d.path .. ".camera")
local light = require(g3d.path .. ".light")
local Class = require("lib.classic")

local world = Class:extend()

function world:new()
    self.drawables = {} -- models and boxes
    self.lights = {}
    self.cameras = cameras()
    self.cameras.getCurrent():updateProjectionMatrix()
    self.cameras.getCurrent():updateViewMatrix()
end

function world:add(object)
    if object:is(light) then
        table.insert(self.lights, object)
    else
        table.insert(self.drawables, object)
    end
end

function world:update(dt)
    for _, drawable in ipairs(self.drawables) do
        if drawable.update then
            drawable:update(dt)
        end
    end
end

function world:draw()
    for _, drawable in ipairs(self.drawables) do
        drawable:draw(nil, nil)
    end
end

function world.newWorld()
    return world()
end

return world