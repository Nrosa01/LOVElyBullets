---@alias Rioni.Math.Point {x:number, y:number}

---@class Rioni.LOVElyBullets.Bullet
---@field position Rioni.Math.Point The current position of the bullet. In the reset function, it is the initial position
---@field private _entity_position Rioni.Math.Point The position of the entity that spawned the bullet. This is used to calculate the relative position of the bullet
---@field components Rioni.LOVElyBullets.Component[] A list of components that the bullet has. This is the same as the components passed in the initialization data
---@field private _updateables {on_update: fun(bullet:Rioni.LOVElyBullets.Bullet, dt:number)}[] A list of components that have an on_update function
---@field private _drawables {on_draw: fun(bullet:Rioni.LOVElyBullets.Bullet)}[] A list of components that have a on_draw function
---@field private _disablateables {on_disabled: fun(bullet:Rioni.LOVElyBullets.Bullet, dt: number)}[] A list of components that have a on_disabled function
---@field private _despawneables {on_despawn: fun(bullet:Rioni.LOVElyBullets.Bullet)}[] A list of components that have a on_disabled function
---@field private _spawnables {on_spawn: fun(bullet: Rioni.LOVElyBullets.Bullet)}[] A list of components that have a on_spawn function
---@field active boolean If true, the bullet will be updated, but it's drawn regardless of this value. Bullet is only not drawn if it's pooled
---@field private _pooled boolean If true, the bullet is not drawn and is not updated. It's in the pool for later reuse
---@field on_spawn fun(bullet: Rioni.LOVElyBullets.Bullet) A function that is called when the bullet is spawned
---@field on_despawn fun(bullet: Rioni.LOVElyBullets.Bullet) A function that is called when the bullet is despawned
---@field on_spawn_callback fun(bullet: Rioni.LOVElyBullets.Bullet) A function that is called when the bullet is spawned
---@field on_despawn_callback fun(bullet: Rioni.LOVElyBullets.Bullet) A function that is called when the bullet is despawned
---@field system Rioni.LOVElyBullets.BulletSystem The bullet system that created this bullet
local Bullet = {}
Bullet.__index = Bullet

---@alias Rioni.LOVElyBullets.Component {on_update: fun(bullet:Rioni.LOVElyBullets.Bullet, dt:number)?, on_draw: fun(bullet:Rioni.LOVElyBullets.Bullet)?, on_disabled: fun(bullet:Rioni.LOVElyBullets.Bullet, dt:number)?, on_despawn: fun(bullet: Rioni.LOVElyBullets.Bullet)?, on_spawn: fun(bullet: Rioni.LOVElyBullets.Component)?}

---@alias Rioni.LOVElyBullets.Bullet.InitializationData {position:Rioni.Math.Point, spawn_point:Rioni.Math.Point?, relative:boolean?, components:Rioni.LOVElyBullets.Component[], active:boolean?, on_spawn:fun(bullet: Rioni.LOVElyBullets.Bullet)?, on_despawn:fun(bullet: Rioni.LOVElyBullets.Bullet)?}

---Initializes the bullet from data, it's called on bullet creation and also when spawned from a pool
---@param data Rioni.LOVElyBullets.Bullet.InitializationData
function Bullet:reset(data)
    -- I do it this way to avoid table references. Imagine you pass here your entity.position
    -- and then the generator changes bullet position... That would be a mess
    assert(data.position, "Bullet must have a position")

    self.position = {
        x = data.position.x,
        y = data.position.y
    }

    assert(data.components, "Bullet must have components")
    self._updateables = {}
    for _, comp in ipairs(data.components) do
        if comp.on_update then
            table.insert(self._updateables, comp)
        end
    end

    --- If tested that iterating components and doing
    ---
    --- for _, comp in ipairs(data.components) do
    ---     if comp.on_update then
    ---         comp.on_update(self, 0)
    ---     end
    --- end
    --- Results in less performance than having arrays for each callback so I can
    --- call them directly. Also, if you have 40 components and only 2 of then are drawable
    --- you will iterate 40 times instead of 2 in the draw function


    self.components = data.components

    self._drawables = {}
    for _, comp in ipairs(data.components) do
        if comp.on_draw then
            table.insert(self._drawables, comp)
        end
    end

    self._disablateables = {}
    for _, comp in ipairs(data.components) do
        if comp.on_disabled then
            table.insert(self._disablateables, comp)
        end
    end

    self._despawneables = {}
    for _, comp in ipairs(data.components) do
        if comp.on_despawn then
            table.insert(self._despawneables, comp)
        end
    end

    self._spawnables = {}
    for _, comp in ipairs(data.components) do
        if comp.on_spawn then
            table.insert(self._spawnables, comp)
        end
    end

    self.active = data.active or false
    self._pooled = false
    self.on_spawn_callback = data.on_spawn or function(_) end
    self.on_despawn_callback = data.on_despawn or function(_) end
end

---Creates a brand new bullet. You must not call this directly, use BulletSystem:create_bullet instead
---@param data Rioni.LOVElyBullets.Bullet.InitializationData
---@param system Rioni.LOVElyBullets.BulletSystem
---@return Rioni.LOVElyBullets.Bullet
function Bullet.new(data, system)
    local self = setmetatable({}, Bullet)
    self.system = system
    self:reset(data)
    return self
end

function Bullet:get_position()
    return self.position
end

---Translates the bullet by the given amount
---@param x number
---@param y number
function Bullet:move_by(x, y)
    self.position.x = self.position.x + x
    self.position.y = self.position.y + y
end

function Bullet:on_spawn()
    self._pooled = false

    for _, comp in ipairs(self._spawnables) do
        comp.on_spawn(self)
    end

    self.on_spawn_callback(self)
end

function Bullet:on_despawn()
    self._pooled = true

    for _, comp in ipairs(self._despawneables) do
        comp.on_despawn(self)
    end

    self.on_despawn_callback(self)
end

---Sets the bullet position to the given coordinates
---@param x number
---@param y number
function Bullet:move_to(x, y)
    self.position.x = x
    self.position.y = y
end

function Bullet:destroy()
    self.system:_remove_bullet(self) ---@diagnostic disable-line:invisible
end

---Updates the bullet. If it's not active and it's relative, it will maintain the relative position, otherwise it iterates its updateable components.
---@param dt any
function Bullet:update(dt)
    if self.active then
        for _, comp in ipairs(self._updateables) do
            comp.on_update(self, dt)
        end
    else
        for _, comp in ipairs(self._disablateables) do
            comp.on_disabled(self, dt)
        end
    end
end

--- Calls every drawble component on the bullet
function Bullet:draw()
    for _, comp in ipairs(self._drawables) do
        comp.on_draw(self)
    end
end

return Bullet