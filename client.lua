local bloodEffect = {}

local Config = {
    Enabled = true,
    BaseDuration = 3000,
    MaxDuration = 5000,
    MaxOpacity = 1.0,
    MinOpacity = 0.3,
    OffsetRange = 0.5,
    FadeTime = 1000,
    MaxStack = 3,
    EnableMelee = true,
    EnableFall = true,
    MinFallHeight = 6.0,
    WeaponMultipliers = {
        [-1569615261] = 1.2,
        [453432689] = 1.8,
        [-1716589765] = 1.5,
        [-1660422300] = 1.5,
        [324215364] = 2.2,
        [-1074790547] = 2.0,
        [-2084633992] = 2.5,
        [-1357824103] = 3.0,
        [736523883] = 2.8,
        [100416529] = 3.5,
        [205991906] = 2.0,
        [-952879014] = 1.3,
    }
}

local playerPed = PlayerPedId()
local lastFallCheck = 0
local fallDamageTriggered = false

bloodEffect.activeEffects = 0
bloodEffect.effectQueue = {}

function bloodEffect:initialize()
    RegisterNetEvent('bf-bloodeffect:showBlood')
    AddEventHandler('bf-bloodeffect:showBlood', function(damage, weaponHash)
        self:handleDamage(damage, weaponHash)
    end)

    self:setupDamageDetection()
end

function bloodEffect:setupDamageDetection()
    AddEventHandler('gameEventTriggered', function(name, args)
        if not Config.Enabled or name ~= 'CEventNetworkEntityDamage' then return end

        local victim = args[1]
        local attacker = args[2]
        local weaponHash = args[7]
        local damageType = args[10]

        if victim ~= PlayerPedId() then return end
        if damageType == 3 or damageType == 5 or damageType == 6 then return end

        if Config.EnableMelee and attacker and IsPedArmed(attacker, 1) then
            self:handleDamage(15, weaponHash or 0)
            return
        end

        if weaponHash and weaponHash ~= 0 then
            self:handleDamage(self:calculateDamage(weaponHash), weaponHash)
        end
    end)
end

CreateThread(function()
    while true do
        Wait(500)

        if Config.EnableFall then
            local ped = PlayerPedId()

            if not IsPedFalling(ped) then
                local velZ = GetEntityVelocity(ped).z
                if velZ < -0.8 then
                    lastFallCheck = GetGameTimer()
                end
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

function bloodEffect:calculateDamage(weaponHash)
    local baseDamage = 10.0
    local multiplier = Config.WeaponMultipliers[weaponHash] or 1.0
    local randomFactor = math.random(85, 120) / 100.0
    return baseDamage * multiplier * randomFactor
end

function bloodEffect:handleDamage(damage, weaponHash)
    if self.activeEffects >= Config.MaxStack then
        table.insert(self.effectQueue, {damage = damage, weaponHash = weaponHash})
        return
    end

    local intensity = math.min(damage / 30.0, 1.0)

    SendNUIMessage({
        action = 'showBlood',
        intensity = intensity,
        duration = Config.BaseDuration + (intensity * (Config.MaxDuration - Config.BaseDuration)),
        opacity = Config.MinOpacity + (intensity * (Config.MaxOpacity - Config.MinOpacity)),
        offsetX = (math.random() * 2 - 1) * Config.OffsetRange,
        offsetY = (math.random() * 2 - 1) * Config.OffsetRange,
        fadeTime = Config.FadeTime
    })

    self.activeEffects = self.activeEffects + 1

    SetTimeout(Config.BaseDuration + Config.FadeTime, function()
        self.activeEffects = math.max(0, self.activeEffects - 1)
        self:processQueue()
    end)
end

function bloodEffect:processQueue()
    if #self.effectQueue > 0 and self.activeEffects < Config.MaxStack then
        local nextEffect = table.remove(self.effectQueue, 1)
        self:handleDamage(nextEffect.damage, nextEffect.weaponHash)
    end
end

exports('showBloodEffect', function(damage, weaponHash)
    bloodEffect:handleDamage(damage or 15, weaponHash or 0)
end)

RegisterCommand('testblood', function()
    exports['bf-bloodeffect']:showBloodEffect(25, 453432689)
end, false)

CreateThread(function()
    bloodEffect:initialize()
end)
