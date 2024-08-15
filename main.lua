-- g3d example
local g3d = require "g3d"
local World = g3d.world.newWorld() 
-- world automatically attaches a camera to itself
local earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {4,0,0})
local moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {4,5,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)

local timer = 0
moon.update = function(self, dt)
    self:setTranslation(math.cos(timer)*5 + 4, math.sin(timer)*5, 0)
    self:setRotation(0, 0, timer - math.pi/2)
end

function love.load()
    World:add(earth)
    World:add(moon)
    World:add(background)
end
function love.update(dt)
    timer = timer + dt

    World:update(dt) -- `World:update()` calls all the `update` functions for models if they exist.
    -- since we added a `moon.update` function it would update the moon
    World.cameras.getCurrent():update(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
end

function love.draw()
    World:draw()
end

function love.mousemoved(x,y, dx,dy)
    World.cameras.getCurrent():mousemoved(dx,dy)
end

function love.keypressed(key)
    World.cameras.getCurrent():keypressed(key)
end