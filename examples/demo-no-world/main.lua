-- g3d example
local g3d = require "path.to.g3d"
local earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {4,0,0})
local moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {4,5,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)

local cameras = g3d.cameras()

local timer = 0
function love.update(dt)
    timer = timer + dt
    moon:setTranslation(math.cos(timer)*5 + 4, math.sin(timer)*5, 0)
    moon:setRotation(0, 0, timer - math.pi/2)
    cameras.getCurrent():update(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
end

function love.draw()
    earth:draw()
    moon:draw()
    background:draw()
end

function love.mousemoved(x,y, dx,dy)
    cameras.getCurrent():mousemoved(dx,dy)
end

function love.keypressed(key)
    cameras.getCurrent():keypressed(key)
end