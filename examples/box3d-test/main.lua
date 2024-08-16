-- g3d example
local g3d = require "g3d"
local World = g3d.world.newWorld() 
-- world automatically attaches a camera to itself
local earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {4,0,0})
local moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {4,5,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)
-- or: 
--local background = g3d.model.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)
local timer = 0
moon.update = function(self, dt)
    self:setTranslation(math.cos(timer)*5 + 4, math.sin(timer)*5, 0)
    self:setRotation(0, 0, timer - math.pi/2)
end

local boxes = {}

function love.load()
    World:add(earth)
    World:add(moon)
    World:add(background)

    for i = 1, 3 do
        boxes[i] = g3d.box3d.newBox3D("assets/moon.png", {i * 3, 0, 0}, {0, 0, 0}, 1)
    end
end
function love.update(dt)
    timer = timer + dt

    World:update(dt) -- `World:update()` calls all the `update` functions for models if they exist.
    -- since we added a `moon.update` function it would update the moon
    for _, box in pairs(boxes) do
        box:update(dt)
    end
    World.cameras.getCurrent():update(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
end

function love.draw()
    World:draw()
    
    for _, box in pairs(boxes) do
        box:draw()
        love.graphics.print(("pos: x: %.2f z: %.2f y: %.2f"):format(box.position[1], box.position[3], box.position[2]), 10, _ * 20)
        love.graphics.print(("vel: x: %.2f y: %.2f z: %.2f"):format(box.velocity.x, box.velocity.y, box.velocity.z), 210, _ * 20)
        love.graphics.print(("acc: x: %.2f z: %.2f y: %.2f"):format(box.acceleration.x, box.acceleration.y, box.acceleration.z), 410, _ * 20)
    end
end

function love.mousemoved(x,y, dx,dy)
    World.cameras.getCurrent():mousemoved(dx,dy)
end

function love.keypressed(key)
    World.cameras.getCurrent():keypressed(key)
    if key == "up" then
        for _, box in pairs(boxes) do
            box:applyForce(0, 10, 0)
        end
    elseif key == "down" then
        for _, box in pairs(boxes) do
            box:applyForce(0, -10, 0)
        end
    elseif key == "left" then
        for _, box in pairs(boxes) do
            box:applyForce(-10, 0, 0)
        end
    elseif key == "right" then
        for _, box in pairs(boxes) do
            box:applyForce(10, 0, 0)
        end
    elseif key == "space" then
        for _, box in pairs(boxes) do
            box:setVelocity(0, 10, 0)
        end
    end
end