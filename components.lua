Components = {}

function Components.lifetime(duration)
    local comp = { remaining = duration }
    function comp.on_update(bullet, dt)
        comp.remaining = comp.remaining - dt
        if comp.remaining <= 0 then
            bullet:destroy()
        end
    end

    return comp
end

function Components.move(speed, direction)
    local comp = {}
    function comp.on_update(bullet, dt)
        bullet:move_by(direction.x * speed * dt, direction.y * speed * dt)
    end

    return comp
end

function Components.draw_circle(draw_data)
    local comp = { draw_data = draw_data or {} }
    function comp.on_draw(bullet)
        love.graphics.setColor(comp.draw_data.colour or { 1, 1, 1 })
        love.graphics.circle("fill", bullet.position.x, bullet.position.y, comp.draw_data.radius or 5)
    end

    return comp
end

local function HSL_TO_RGBA(h, s, l, a)
    if s <= 0 then return l, l, l, a end
    h, s, l = h * 6, s, l
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = (1 - math.abs(h % 2 - 1)) * c
    local m, r, g, b = (l - .5 * c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r + m, g + m, b + m, a
end

local function bidirectional_module(start, finish, value)
    local range = finish - start
    local mod = value % (range * 2)
    if mod > range then
        return finish - (mod - range)
    else
        return start + mod
    end
end

function Components.draw_circle_hue_shift(draw_data)
    local comp = { draw_data = draw_data or {} }
    comp.draw_data.start_radius = comp.draw_data.start_radius or 5
    comp.timer = 0
    function comp.on_update(bullet, dt)
        comp.timer               = comp.timer + dt
        comp.draw_data.radius    = comp.draw_data.start_radius + math.sin(comp.timer * 10) * 3
        comp.draw_data.colour[1] = bidirectional_module(0, 1, comp.timer)
    end

    function comp.on_draw(bullet)
        love.graphics.setColor(HSL_TO_RGBA(unpack(comp.draw_data.colour)))
        love.graphics.circle("fill", bullet.position.x, bullet.position.y, comp.draw_data.radius or 5)
    end

    return comp
end

function Components.simulate_parenting(parent_position, spawn_position)
    local comp = {
        offset = {
            x = spawn_position.x - parent_position.x,
            y = spawn_position.y - parent_position.y
        }
    }
    function comp.on_disabled(bullet, dt)
        bullet.position.x = comp.offset.x + parent_position.x
        bullet.position.y = comp.offset.y + parent_position.y
    end

    return comp
end

-- Callback returns a list of components
function Components.explode(count, callback)
    local comp = {}
    ---comment
    ---@param bullet Rioni.LOVElyBullets.Bullet
    function comp.on_despawn(bullet)
        -- Callback returns 3 components, lifetime, move and draw, I will instanti
        for i = 1, count do
            local angle = (i / count) * math.pi * 2
            local direction = { x = math.cos(angle), y = math.sin(angle) }
            bullet.system:create_bullet({
                position = {
                    x = math.cos(angle) + bullet.position.x,
                    y = math.sin(angle) + bullet.position.y
                },
                components = {
                    unpack(callback(2, 500, direction, {
                        radius = 8,
                        colour = { 0.5, 0.7, 0.8 }
                    }))
                },
                active = true
            })
        end
    end

    return comp
end

return Components
