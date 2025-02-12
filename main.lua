local LOVElyBullets = require "LOVElyBullets.BulletSystem"
Components = require "components"
local Generators = require "generators"

local entity = {
    position = { x = 0, y = 0 },
}

local bullet_system = LOVElyBullets.new()
local generator = nil

local time_scale = 1
local paused = false

function love.load()
    entity.position.x = love.graphics.getWidth() / 2
    entity.position.y = love.graphics.getHeight() / 2
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == "space" then
        paused = not paused
    end
end

function love.update(dt)
    if love.keyboard.isDown("left") then
        time_scale = time_scale - 2 * dt
    end

    if love.keyboard.isDown("right") then
        time_scale = time_scale + 2 * dt
    end

    time_scale = math.max(0.000001, math.min(10, time_scale))

    local velocity = 300
    local input = { x = 0, y = 0 }
    if love.keyboard.isDown("w") then input.y = input.y - 1 end
    if love.keyboard.isDown("s") then input.y = input.y + 1 end
    if love.keyboard.isDown("a") then input.x = input.x - 1 end
    if love.keyboard.isDown("d") then input.x = input.x + 1 end

    local input_magnitude = math.sqrt(input.x ^ 2 + input.y ^ 2)
    if input_magnitude > 0 then
        input.x = input.x / input_magnitude
        input.y = input.y / input_magnitude
    end

    entity.position.x = entity.position.x + input.x * velocity * dt
    entity.position.y = entity.position.y + input.y * velocity * dt

    if not paused then
        bullet_system:update(dt *time_scale)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        generator = bullet_system:new_generator(Generators.two_circle, 20, 96, entity.position, {
            radius = 5,
            colour = { 0.5, 1, 0.8 }
        })
    end
    if button == 2 then
        if generator then generator(true) end
    end
end

function love.draw()
    love.graphics.circle("fill", entity.position.x, entity.position.y, 10)
    bullet_system:draw()
    local graphicsState = love.graphics.getStats()
    love.graphics.print("Time scale: " .. time_scale, 10, 90)
    love.graphics.print("Paused: " .. tostring(paused), 10, 110)
    love.graphics.print("Bullets: " .. bullet_system:total_bullet_count(), 10, 10)
    love.graphics.print("Active Bullets: " .. bullet_system:active_bullet_count(), 10, 30)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 50)
    love.graphics.print("Draw calls: " .. graphicsState.drawcalls, 10, 70)

    -- Print simulation controls
    love.graphics.print("Left/Right Arrows to change time scale", 10, love.graphics.getHeight() - 70)
    love.graphics.print("Space to pause", 10, love.graphics.getHeight() - 50)
    love.graphics.print("Left click to spawn bullets", 10, love.graphics.getHeight() - 30)
end
