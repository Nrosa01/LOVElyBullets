local function deep_copy(obj, seen)
	-- Handle non-tables and previously-seen tables.
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end

	-- New table; mark it as seen an copy recursively.
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in next, obj do res[deep_copy(k, s)] = deep_copy(v, s) end
	return setmetatable(res, getmetatable(obj))
end

local function two_circle(radius, count, spawn_point, draw_data)
    local seconds_between = 0.016 / 8
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local direction = { x = math.cos(angle), y = math.sin(angle) }
        local bullet_position = {
            x = math.cos(angle) * radius + spawn_point.x,
            y = math.sin(angle) * radius + spawn_point.y
        }
        coroutine.yield({
            position = bullet_position,
            spawn_point = spawn_point,
            components = {
                --- Comment the simulate parenting and see what happens
                Components.simulate_parenting(spawn_point, bullet_position),
                Components.lifetime(2),
                Components.move(200, direction),
                Components.draw_circle(deep_copy(draw_data))
            },
        }, seconds_between)
    end

    --- Nil marks the end between sub formations
    coroutine.yield(nil, 0.4, 0.5, true)
    
    -- Here you can do quite a lof of stuff. It has happened 0.9 seconds since
    -- The generator was crated. The entity might have moved, if we had cache its position 
    -- at the beggining, we could spawn bullets at that point, but most of the time
    -- You want to spawn bullets at the point where the entity currently is.
    local original_x = spawn_point.x
    local original_y = spawn_point.y

    for i = 1, count do
        local angle = 360 - (i / count) * math.pi * 2
        local direction = { x = math.cos(angle), y = math.sin(angle) }
        coroutine.yield({
            position = {
                x = math.cos(angle) * radius + original_x,
                y = math.sin(angle) * radius + original_y
            },
            components = {
                Components.lifetime(1.2),
                Components.move(200, direction),
                Components.draw_circle_hue_shift(draw_data),
                Components.explode(5, function (lifetime, speed, direction, draw_data)
                    return {
                        Components.lifetime(lifetime),
                        Components.move(speed, direction),
                        Components.draw_circle(draw_data)
                    }
                end)
            },
            -- Try uncommenting this line and setting line 63 from 0 to 0.05
            -- active = true,
        }, 0)
    end
end

local generators = {
    two_circle = two_circle
}

return generators