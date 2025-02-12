local module = (...):match("(.-)[^%.]+$")
local Generator = require(module .. "BulletGenerator")
local Bullet = require(module .. "Bullet")

---@class Rioni.LOVElyBullets.BulletSystem
---@field private _generators Rioni.LOVElyBullets.Generator[] List of all generators
---@field private _bullets Rioni.LOVElyBullets.Bullet[] List of all bullets (active and pooled)
---@field private _pool Rioni.LOVElyBullets.Bullet[] List of pooled bullets
---@field private _active_count number Number of active bullets
local BulletSystem = {}
BulletSystem.__index = BulletSystem

---Creates a new BulletSystem
---@return Rioni.LOVElyBullets.BulletSystem
function BulletSystem.new()
    local self = setmetatable({}, BulletSystem)
    self._generators = {}
    self._bullets = {}
    self._pool = {}
    self._active_count = 0
    return self
end

--- Creates a bullet from the pool or creates a new one if the pool is empty
---@param bullet_data Rioni.LOVElyBullets.Bullet.InitializationData
---@return Rioni.LOVElyBullets.Bullet
function BulletSystem:create_bullet(bullet_data)
    local bullet
    if #self._pool > 0 then
        bullet = table.remove(self._pool)
        bullet:reset(bullet_data)
    else
        bullet = Bullet.new(bullet_data, self)
        table.insert(self._bullets, bullet)
    end

    bullet.on_spawn(bullet)
    self._active_count = self._active_count + 1
    
    return bullet
end

---Removes a bullet from the system (puts it back in the pool)
---@param bullet Rioni.LOVElyBullets.Bullet
---@package
function BulletSystem:_remove_bullet(bullet)
    if not bullet._pooled then ---@diagnostic disable-line: invisible
        bullet.active = false
        bullet.on_despawn(bullet)
        self._active_count = self._active_count - 1
        table.insert(self._pool, bullet)
    end
end

---Returns the number of active bullets
---@return number
function BulletSystem:active_bullet_count()
    return self._active_count
end

---Returns the total number of bullets (active and pooled)
function BulletSystem:total_bullet_count()
    return #self._bullets
end

---Updates the bullet system
function BulletSystem:update(dt)
    for _, generator in ipairs(self._generators) do
        generator:update(dt)
    end

    for _, bullet in ipairs(self._bullets) do
        if not bullet._pooled then ---@diagnostic disable-line: invisible
            bullet:update(dt)
        end
    end
end

---Draws all the bullets
function BulletSystem:draw()
    love.graphics.push("all")
    for _, bullet in ipairs(self._bullets) do
        if not bullet._pooled then ---@diagnostic disable-line: invisible
            bullet:draw()
        end
    end
    love.graphics.pop()
end

---Removes a generator from the system
---@param generator Rioni.LOVElyBullets.Generator
---@package
function BulletSystem:_remove_generator(generator)
    for i, group in ipairs(self._generators) do
        if group == generator then
            table.remove(self._generators, i)
            break
        end
    end
end

---Creates a new generator. Returns a function that can be called to cancel the generator
---@param func fun(...) A coroutine function that generates bullets
---@vararg any Arguments for the coroutine
---@return fun(keep_bullets:boolean) Cancels the generator and removes the bullets if keep_bullets is false, otherwise they are activated
function BulletSystem:new_generator(func, ...)
    local generator = Generator.new(self, coroutine.create(func), { ... })
    table.insert(self._generators, generator)
    return function(keep_bullets) if generator then generator:cancel(keep_bullets) end end
end


return BulletSystem