-- Made by okzyrox for g3d
-- MIT

-- Light source implementation

local Class = require("lib.classic")

local Light = Class:extend()

function Light:new(position, direction, color, intensity)
    self.position = position or {0, 0, 0}
    self.direction = direction or {0, -1, 0}
    self.color = color or {1, 1, 1}
    self.intensity = intensity or 1
end

function Light.newLight(position, direction, color, intensity)
    return Light(position, direction, color, intensity)
end

return Light