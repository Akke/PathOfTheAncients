-- Specialist innate runtime: Manifestation + Resonance.
--
-- Manifestation: the Specialist projects an aspect of itself onto the
-- battlefield as a summonable companion (a controllable creature that fights
-- alongside the hero). Resonance: the bond between the Specialist and the
-- manifestation, which builds while both fight together and decays when the
-- manifestation is lost.
--
-- The innate loop implemented here is:
--   1. Manifest      -- the player summons a manifestation of the Specialist.
--   2. Fight-together -- the manifestation mirrors the player's attack target
--                    so it actually engages alongside the Specialist.
--   3. Resonance     -- Resonance stacks build while both are fighting together,
--                    and decay after the manifestation dies (Severance).
--
-- Resonance is stored as modifier stacks on the hero (modifier_poa_specialist_
-- resonance) so it reads as a stack count on the HUD and is freely consumable
-- by other systems. This is a shared library: the Manifest ability
-- (abilities/poa_innate_specialist.lua) calls into it, and
-- addon_game_mode.lua requires it up front to link its modifiers.

LinkLuaModifier("modifier_poa_specialist_resonance", "innates/specialist_manifestation", LUA_MODIFIER_MOTION_NONE)

local INNATE = require("class_innates").specialist

local MOD_RESONANCE = "modifier_poa_specialist_resonance"

local THINK_INTERVAL = 0.25
local NETTABLE_NAME = "poa_innate"
local NETTABLE_KEY = "specialist"

-- Active manifestation per Specialist, keyed by owner (stable across the
-- ReplaceHeroWith hero swap used by -ascend, unlike hero entindex). Unowned
-- heroes fall back to an entity key.
local manifests = {}

local specialist_innate = {}

local function manifest_key(hero)
    local playerID = -1
    pcall(function() playerID = hero:GetPlayerOwnerID() end)
    if type(playerID) == "number" and playerID >= 0 then
        return "player_" .. playerID
    end
    return "entity_" .. hero:entindex()
end

local function get_resonance_modifier(hero)
    if hero == nil or hero:IsNull() then
        return nil
    end
    local mod = hero:FindModifierByName(MOD_RESONANCE)
    if mod ~= nil and not mod:IsNull() then
        return mod
    end
    return nil
end

function specialist_innate.EnsureResonanceModifier(hero)
    local existing = get_resonance_modifier(hero)
    if existing ~= nil then
        return existing
    end
    local ok, result = pcall(function()
        return hero:AddNewModifier(hero, nil, MOD_RESONANCE, {})
    end)
    if ok then
        print("[POA] specialist innate: Resonance attached to " .. hero:GetUnitName())
    else
        print("[POA] specialist innate: failed to attach Resonance: " .. tostring(result))
    end
    return result
end

function specialist_innate.OnHeroApply(hero)
    if hero ~= nil and not hero:IsNull() then
        specialist_innate.EnsureResonanceModifier(hero)
        specialist_innate.ReconcileManifestation(hero)
    end
end

function specialist_innate.GetManifestation(hero)
    if hero == nil or hero:IsNull() then
        return nil
    end
    local key = manifest_key(hero)
    local entry = manifests[key]
    if entry == nil then
        return nil
    end
    if entry:IsNull() or not entry:IsAlive() then
        -- Manifestation died: drop the registry entry instead of masking it.
        manifests[key] = nil
        return nil
    end
    return entry
end

-- Re-parents a surviving manifestation onto the current hero after a hero
-- replacement (ascend). Without this the unit stays in the world ownerless
-- under the dead hero's entindex and a second Manifest duplicates it.
function specialist_innate.ReconcileManifestation(hero)
    if hero == nil or hero:IsNull() then
        return nil
    end
    local unit = specialist_innate.GetManifestation(hero)
    if unit == nil then
        return nil
    end
    pcall(function() unit:SetOwner(hero) end)
    local player = nil
    pcall(function() player = hero:GetPlayerOwner() end)
    if player ~= nil then
        pcall(function()
            unit:SetControllableByPlayer(player:GetPlayerID(), true)
        end)
    end
    return unit
end

function specialist_innate.RegisterManifestation(hero, unit)
    if hero ~= nil and not hero:IsNull() and unit ~= nil and not unit:IsNull() then
        manifests[manifest_key(hero)] = unit
    end
end

function specialist_innate.ClearManifestation(hero)
    if hero ~= nil and not hero:IsNull() then
        manifests[manifest_key(hero)] = nil
    end
end

-- Keeps the think loop's float accumulator coherent when an external caller
-- (future ascendancy spends) writes the stack count directly.
local function set_resonance_value(mod, value)
    value = math.max(0, math.min(INNATE.resonance.max, value))
    local display = math.floor(value + 0.0001)
    if type(mod._stacks) == "number" then
        mod._stacks = value
    end
    if type(mod._display) == "number" then
        mod._display = display
    end
    mod:SetStackCount(display)
    return display
end

function specialist_innate.GetResonance(hero)
    local mod = get_resonance_modifier(hero)
    if mod == nil then
        return 0
    end
    return mod:GetStackCount() or 0
end

function specialist_innate.AddResonance(hero, amount)
    local mod = specialist_innate.EnsureResonanceModifier(hero)
    if mod == nil then
        return false
    end
    local current = mod:GetStackCount() or 0
    set_resonance_value(mod, current + amount)
    return true
end

function specialist_innate.SpendResonance(hero, amount)
    local mod = specialist_innate.EnsureResonanceModifier(hero)
    if mod == nil then
        return false
    end
    local current = mod:GetStackCount() or 0
    if current < amount then
        return false
    end
    set_resonance_value(mod, current - amount)
    publish(hero)
    return true
end

local function spawn_manifestation(hero)
    local unitName = INNATE.unit

    -- max_manifestations: a surviving aspect is reused, never duplicated.
    local existing = specialist_innate.GetManifestation(hero)
    if existing ~= nil then
        return existing
    end

    local player = nil
    pcall(function() player = hero:GetPlayerOwner() end)
    local origin = hero:GetAbsOrigin() + hero:GetForwardVector() * 220

    local ok, unit = pcall(function()
        return CreateUnitByName(
            unitName,
            origin,
            true,
            hero,
            nil,
            hero:GetTeamNumber()
        )
    end)
    if not ok or unit == nil or unit:IsNull() then
        print("[POA] specialist innate: manifest spawn failed: " .. tostring(unit))
        return nil
    end

    pcall(function() unit:SetOwner(hero) end)
    if player ~= nil then
        pcall(function()
            unit:SetControllableByPlayer(player:GetPlayerID(), true)
        end)
    end
    pcall(function() unit:SetTeamNumber(hero:GetTeamNumber()) end)
    pcall(function() unit:SetHealth(unit:GetMaxHealth()) end)

    specialist_innate.RegisterManifestation(hero, unit)
    print("[POA] specialist innate: manifested " .. unitName .. " for " .. hero:GetUnitName())
    return unit
end

function specialist_innate.SpawnManifestation(hero)
    return spawn_manifestation(hero)
end

local function publish(hero)
    if hero == nil or hero:IsNull() then
        return
    end
    local ok = pcall(function()
        CustomNetTables:SetTableValue(NETTABLE_NAME, NETTABLE_KEY, {
            class = "specialist",
            resource = INNATE.resource,
            value = specialist_innate.GetResonance(hero),
            max = INNATE.resonance.max,
            manifestation_alive = specialist_innate.GetManifestation(hero) ~= nil,
        })
    end)
    if not ok then
        print("[POA] specialist innate: nettable publish failed")
    end
end

function specialist_innate.Publish(hero, mod)
    publish(hero, mod)
end

local ORDER_ATTACK_TARGET = DOTA_UNIT_ORDER and DOTA_UNIT_ORDER.ATTACK_TARGET or 26

-- Resonance modifier: holds stacks and drives the innate think loop.
modifier_poa_specialist_resonance = class({})

function modifier_poa_specialist_resonance:IsPurgable() return false end
function modifier_poa_specialist_resonance:IsDebuff() return false end
function modifier_poa_specialist_resonance:RemoveOnDeath() return false end
function modifier_poa_specialist_resonance:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_poa_specialist_resonance:GetTexture() return "arc_warden_magnetic_field" end

function modifier_poa_specialist_resonance:OnCreated(keys)
    -- Resonance accumulates as a float but is only networked (SetStackCount)
    -- when the integer display value changes, so ticks do not spam modifier
    -- state at 4 Hz and fractional decay is not lost to int truncation.
    if not IsServer() then
        return
    end
    self._stacks = 0
    self._display = 0
    self:SetStackCount(0)
    self._lastPublish = -1
    self._lastOrderTime = 0
    self._wasAlive = false
    self:StartIntervalThink(THINK_INTERVAL)
end

function modifier_poa_specialist_resonance:OnIntervalThink()
    if not IsServer() then
        return
    end
    local hero = self:GetParent()
    if hero == nil or hero:IsNull() then
        return
    end
    local resData = INNATE.resonance
    local now = GameRules:GetGameTime()
    local stacks = self._stacks or 0
    local unit = specialist_innate.GetManifestation(hero)

    if unit ~= nil then
        local heroTarget = nil
        pcall(function() heroTarget = hero:GetAttackTarget() end)

        -- Keep the manifestation actually fighting: mirror the hero's target,
        -- but only while the target is within the configured follow range so
        -- the aspect is not dragged across the map after a kited enemy.
        local followRange = resData.attack_follow_range
        if heroTarget ~= nil and not heroTarget:IsNull() then
            local unitTarget = nil
            pcall(function() unitTarget = unit:GetAttackTarget() end)
            local following = unitTarget ~= nil
                and not unitTarget:IsNull()
                and unitTarget:GetEntityIndex() == heroTarget:GetEntityIndex()
            if not following and now - self._lastOrderTime >= 0.5 then
                local inRange = true
                if followRange ~= nil and followRange > 0 then
                    local unitOrigin = nil
                    local targetOrigin = nil
                    pcall(function() unitOrigin = unit:GetAbsOrigin() end)
                    pcall(function() targetOrigin = heroTarget:GetAbsOrigin() end)
                    if unitOrigin ~= nil and targetOrigin ~= nil then
                        inRange = (targetOrigin - unitOrigin):Length2D() <= followRange
                    end
                end
                if inRange then
                    pcall(function()
                        ExecuteOrderFromTable({
                            UnitIndex = unit:GetEntityIndex(),
                            OrderType = ORDER_ATTACK_TARGET,
                            TargetIndex = heroTarget:GetEntityIndex(),
                        })
                    end)
                    self._lastOrderTime = now
                end
            end
        end

        -- Fighting-together check: either the Specialist or the manifestation
        -- is actively attacking (or the hero is channeling).
        local fighting = heroTarget ~= nil
        if not fighting then
            pcall(function()
                fighting = hero:IsChanneling()
                    or unit:GetAttackTarget() ~= nil
            end)
        end
        if fighting and stacks < resData.max then
            stacks = math.min(resData.max, stacks + resData.gain_per_second * THINK_INTERVAL)
        end
        self._wasAlive = true
    else
        -- Severance: manifestation gone, Resonance decays to zero.
        if self._wasAlive and stacks > 0 then
            print("[POA] specialist innate: Severance - manifestation lost, Resonance decaying")
        end
        self._wasAlive = false
        if stacks > 0 then
            stacks = math.max(0, stacks - resData.decay_per_second * THINK_INTERVAL)
        end
    end

    self._stacks = stacks
    local display = math.floor(stacks + 0.0001)
    if display ~= self._display then
        self._display = display
        self:SetStackCount(display)
    end

    -- Publish a HUD/NetTable update roughly once a second.
    if now - self._lastPublish >= 1.0 then
        self._lastPublish = now
        publish(hero, self)
    end
end

-- Module self-wiring so the global is usable by abilities and the game mode.
SPECIALIST_INNATE = specialist_innate
return specialist_innate