-- client.lua
local bloodEffect = {}
-- ===== Config inside client.lua =====
local Config = {
    Enabled = true,           -- Enable/Disable blood splatter
    BaseDuration = 3000,      -- Base display duration (ms)
    MaxDuration = 5000,       -- Maximum duration for heavy hits
    MaxOpacity = 1.0,         -- Maximum opacity
    MinOpacity = 0.3,         -- Minimum opacity
    OffsetRange = 0.5,        -- Random position offset
    FadeTime = 1000,          -- Fade-out time for each splatter
    MaxStack = 3,             -- Maximum visible splatters at once
    EnableMelee = true,       -- Enable splatter from melee hits
    EnableFall = true,        -- Enable splatter from falling
    MinFallHeight = 6.0,      -- Minimum fall height to trigger blood
    WeaponMultipliers = {     -- Weapon-specific multipliers
        [-1569615261] = 1.2,  -- Pistol
        [453432689]    = 1.8,  -- Pistol .50
        [-1716589765] = 1.5,  -- Heavy Pistol
        [-1660422300] = 1.5,  -- SMG
        [324215364]   = 2.2,  -- Micro SMG
        [-1074790547] = 2.0,  -- Assault Rifle
        [-2084633992] = 2.5,  -- Carbine Rifle
        [-1357824103] = 3.0,  -- Advanced Rifle
        [736523883]   = 2.8,  -- SMG MK2
        [100416529]   = 3.5,  -- Sniper Rifle
        [205991906]   = 2.0,  -- Heavy Sniper
        [-952879014]  = 1.3,  -- Assault SMG
    }
}

-- ===================================

-- Cache PlayerPedId
local playerPed = nil
local lastFallCheck = 0
local fallDamageTriggered = false

-- Initialize playerPed cache
CreateThread(function()
    while true do
        playerPed = PlayerPedId()
        Wait(1000)
    end
end)

-- Resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    bloodEffect:initialize()
end)

-- Initialize blood effect system
function bloodEffect:initialize()
    self.activeEffects = 0
    self.effectQueue = {}

    -- Event from other resources
    RegisterNetEvent('bf-bloodeffect:showBlood')
    AddEventHandler('bf-bloodeffect:showBlood', function(damage, weaponHash)
        self:handleDamage(damage, weaponHash)
    end)

    self:setupDamageDetection()
    print('^2[BF-BloodEffect] initialized by Dakhchich ^0')
end

-- Weapon / Melee damage detection
function bloodEffect:setupDamageDetection()
    AddEventHandler('gameEventTriggered', function(name, args)
        if not Config.Enabled or name ~= 'CEventNetworkEntityDamage' then return end

        local victim = args[1]
        local attacker = args[2]
        local weaponHash = args[7]
        local damageType = args[10]

        if victim ~= PlayerPedId() then return end

        -- Ignore environmental damage (fire, explosion, drowning)
        if damageType == 3 or damageType == 5 or damageType == 6 then return end

        -- Melee detection (knife, bat, etc.)
        if Config.EnableMelee and IsPedArmed(attacker, 1) then
            self:handleDamage(15, weaponHash or 0)
            return
        end

        -- Weapon damage
        if weaponHash and weaponHash ~= 0 then
            local damage = self:calculateDamage(weaponHash)
            self:handleDamage(damage, weaponHash)
        end
    end)
end

-- Fall damage detection
CreateThread(function()
    while true do
        Wait(500)
        if Config.EnableFall then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if not IsPedFalling(ped) then
                local velZ = GetEntityVelocity(ped).z
                if velZ < -0.8 then lastFallCheck = GetGameTimer() end
            end

            if HasEntityCollidedWithAnything(ped) and not IsPedInAnyVehicle(ped, false) then
                if not fallDamageTriggered and (GetGameTimer() - lastFallCheck) > 1000 then
                    local fallHeight = math.abs(GetEntityHeightAboveGround(ped))
                    if fallHeight >= Config.MinFallHeight then
                        fallDamageTriggered = true
                        bloodEffect:handleDamage(25 + (fallHeight * 2), 0)
                        Wait(1000)
                        fallDamageTriggered = false
                    end
                end
            end
        end
    end
end)

-- Calculate damage intensity based on weapon
function bloodEffect:calculateDamage(weaponHash)
    local baseDamage = 10.0
    local multiplier = Config.WeaponMultipliers[weaponHash] or 1.0
    local randomFactor = math.random(85, 120) / 100.0
    return baseDamage * multiplier * randomFactor
end

-- Handle NUI blood effect
function bloodEffect:handleDamage(damage, weaponHash)
    if self.activeEffects >= Config.MaxStack then
        table.insert(self.effectQueue, {damage = damage, weaponHash = weaponHash})
        return
    end

    local intensity = math.min(damage / 30.0, 1.0)
    local duration = Config.BaseDuration + (intensity * (Config.MaxDuration - Config.BaseDuration))
    local opacity = Config.MinOpacity + (intensity * (Config.MaxOpacity - Config.MinOpacity))
    local offsetX = (math.random() * 2 - 1) * Config.OffsetRange
    local offsetY = (math.random() * 2 - 1) * Config.OffsetRange

    SendNUIMessage({
        action = 'showBlood',
        intensity = intensity,
        duration = duration,
        opacity = opacity,
        offsetX = offsetX,
        offsetY = offsetY,
        fadeTime = Config.FadeTime
    })

    self.activeEffects = self.activeEffects + 1

    SetTimeout(duration + Config.FadeTime, function()
        self.activeEffects = math.max(0, self.activeEffects - 1)
        self:processQueue()
    end)
end

-- Queue handling for rapid hits
function bloodEffect:processQueue()
    if #self.effectQueue > 0 and self.activeEffects < Config.MaxStack then
        local nextEffect = table.remove(self.effectQueue, 1)
        self:handleDamage(nextEffect.damage, nextEffect.weaponHash)
    end
end

-- Export for other resources
exports('showBloodEffect', function(damage, weaponHash)
    bloodEffect:handleDamage(damage or 15, weaponHash or 0)
end)

-- Debug command
RegisterCommand('testblood', function()
    exports['bf-bloodeffect']:showBloodEffect(25, 453432689)
end, false)
