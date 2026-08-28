require("libraries/timers")

-- Custom ability kits per playable (base class or ascendancy key), granted
-- server-side after spawn so they do not depend on hero KV override loading.
-- See docs/CUSTOM_ABILITIES.md for the ability registration format and the
-- fixes required to make custom abilities load in this engine build. Defined
-- in modules, not inline, so class data stays out of the game mode file.
local CLASS_ABILITIES = require("class_abilities")

-- Class innate data (per base class and ascendancy). Distinct from ability
-- kits: an innate is the signature class identity + resource, not a list of
-- bar abilities. Ascendancy innates (CLASS_INNATES.ascendancies) override the
-- base class innate. See class_innates.lua. NOTE: this engine's require only
-- returns the first value, so both tables ride on the same module (CLASS_INNATES
-- holds .ascendancies).
local CLASS_INNATES = require("class_innates")
local ASCENDANCY_INNATES = CLASS_INNATES.ascendancies

-- Innate runtime modules by base class key, populated by each class's
-- implementing branch via require. Modules self-register their modifiers and
-- are linked up front so they are available before any innate is granted.
local INNATE_MODULES = {
    specialist = require("innates/specialist_manifestation"),
}

if PathOfTheAncients == nil then
    PathOfTheAncients = class({})
end

-- Fallback cap only: the game normally starts early via ForceGameStart once
-- every connected player has confirmed a specialist, so this exists just to
-- keep the server from forcing the game forward while players read hero
-- details.
local HERO_SELECTION_TIMEOUT_SECONDS = 3600

local BASE_CLASSES = {
    warrior = { hero = "npc_dota_hero_mars", display_name = "Warrior" },
    mercenary = { hero = "npc_dota_hero_antimage", display_name = "Mercenary" },
    ranger = { hero = "npc_dota_hero_hoodwink", display_name = "Ranger" },
    performer = { hero = "npc_dota_hero_monkey_king", display_name = "Performer" },
    mage = { hero = "npc_dota_hero_invoker", display_name = "Mage" },
    martial_artist = { hero = "npc_dota_hero_juggernaut", display_name = "Martial Artist" },
    specialist = { hero = "npc_dota_hero_arc_warden", display_name = "Specialist" },
}

-- Order matches class_definitions.js ascendencies arrays (-ascend 1/2/3).
local CLASS_ASCENDANCIES = {
    warrior = {
        { key = "berserker", hero = "npc_dota_hero_skeleton_king", display_name = "Berserker" },
        { key = "paladin", hero = "npc_dota_hero_omniknight", display_name = "Paladin" },
        { key = "slayer", hero = "npc_dota_hero_spectre", display_name = "Slayer" },
    },
    mercenary = {
        { key = "artillerist", hero = "npc_dota_hero_gyrocopter", display_name = "Artillerist" },
        { key = "death_blade", hero = "npc_dota_hero_legion_commander", display_name = "Death Blade" },
        { key = "bloodhound", hero = "npc_dota_hero_bounty_hunter", display_name = "Bloodhound" },
    },
    ranger = {
        { key = "deadeye", hero = "npc_dota_hero_windrunner", display_name = "Deadeye" },
        { key = "gunslinger", hero = "npc_dota_hero_muerta", display_name = "Gunslinger" },
        { key = "witch_hunter", hero = "npc_dota_hero_drow_ranger", display_name = "Witch Hunter" },
    },
    performer = {
        { key = "bard", hero = "npc_dota_hero_largo", display_name = "Bard" },
        { key = "drunkard", hero = "npc_dota_hero_brewmaster", display_name = "Drunkard" },
        { key = "puppeteer", hero = "npc_dota_hero_ringmaster", display_name = "Puppeteer" },
    },
    mage = {
        { key = "fire_mage", hero = "npc_dota_hero_lina", display_name = "Fire Mage" },
        { key = "frost_mage", hero = "npc_dota_hero_crystal_maiden", display_name = "Frost Mage" },
        { key = "lightning_mage", hero = "npc_dota_hero_zuus", display_name = "Lightning Mage" },
    },
    martial_artist = {
        { key = "glaivier", hero = "npc_dota_hero_phantom_lancer", display_name = "Glaivier" },
        { key = "striker", hero = "npc_dota_hero_marci", display_name = "Striker" },
        { key = "war_dancer", hero = "npc_dota_hero_axe", display_name = "War Dancer" },
    },
    specialist = {
        { key = "druid", hero = "npc_dota_hero_lone_druid", display_name = "Druid" },
        { key = "spiritkin", hero = "npc_dota_hero_void_spirit", display_name = "Spiritkin" },
        { key = "summoner", hero = "npc_dota_hero_warlock", display_name = "Summoner" },
    },
}

local ASCENDANCY_BY_KEY = {}
for classKey, list in pairs(CLASS_ASCENDANCIES) do
    for index, ascendancy in ipairs(list) do
        ASCENDANCY_BY_KEY[ascendancy.key] = {
            key = ascendancy.key,
            hero = ascendancy.hero,
            display_name = ascendancy.display_name,
            class_key = classKey,
            index = index,
        }
    end
end

-- Optional per-class cosmetic overrides; see precache_cosmetics.lua.
-- When set, these replace the hero's default_wearables.lua pieces.
local COSMETIC_OVERRIDES = require("precache_cosmetics")

-- Default wearable models per hero for heroes whose KV override sets
-- DisableWearables 1; see default_wearables.lua.
local DEFAULT_WEARABLES = require("default_wearables")

function Precache(context)
    local precached = {}
    local function precacheUnit(heroName)
        if not precached[heroName] then
            PrecacheUnitByNameSync(heroName, context)
            precached[heroName] = true
        end
    end
    for _, classDef in pairs(BASE_CLASSES) do
        precacheUnit(classDef.hero)
    end
    for _, list in pairs(CLASS_ASCENDANCIES) do
        for _, ascendancy in ipairs(list) do
            precacheUnit(ascendancy.hero)
        end
    end
    for baseClassKey, innate in pairs(CLASS_INNATES) do
        if innate ~= nil and type(innate.unit) == "string" then
            precacheUnit(innate.unit)
        end
    end
    for ascendancyKey, innate in pairs(ASCENDANCY_INNATES) do
        if innate ~= nil and type(innate.unit) == "string" then
            precacheUnit(innate.unit)
        end
    end
    for _, models in pairs(COSMETIC_OVERRIDES) do
        for _, model in pairs(models) do
            PrecacheModel(model, context)
        end
    end
    for key, models in pairs(DEFAULT_WEARABLES) do
        if type(key) == "string" and string.sub(key, 1, 1) ~= "_" and type(models) == "table" then
            for _, entry in pairs(models) do
                local model = nil
                if type(entry) == "string" then
                    model = entry
                elseif type(entry) == "table" then
                    model = entry.model
                end
                if type(model) == "string" then
                    PrecacheModel(model, context)
                end
            end
        end
    end
    local presets = DEFAULT_WEARABLES._visual_presets
    if type(presets) == "table" then
        for _, preset in pairs(presets) do
            if type(preset.model) == "string" then
                PrecacheModel(preset.model, context)
            end
            if type(preset.weapons) == "table" then
                for _, weapon in pairs(preset.weapons) do
                    if type(weapon.model) == "string" then
                        PrecacheModel(weapon.model, context)
                    end
                end
            end
            if type(preset.particles) == "table" then
                for _, particle in pairs(preset.particles) do
                    if type(particle.path) == "string" then
                        PrecacheResource("particle", particle.path, context)
                    end
                end
            end
        end
    end
end

function Activate()
    GameRules.PathOfTheAncients = PathOfTheAncients()
    GameRules.PathOfTheAncients:InitGameMode()
end

function PathOfTheAncients:InitGameMode()
    self.selections = {}

    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 4)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
    GameRules:EnableCustomGameSetupAutoLaunch(true)
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)
    GameRules:SetHeroSelectionTime(HERO_SELECTION_TIMEOUT_SECONDS)
    GameRules:SetStrategyTime(0)
    GameRules:SetShowcaseTime(0)
    GameRules:SetPreGameTime(0)

    local mode = GameRules:GetGameModeEntity()

    mode:SetExecuteOrderFilter(Dynamic_Wrap(PathOfTheAncients, "OrderFilter"), self)

    mode:SetAnnouncerDisabled(true)
    mode:SetKillingSpreeAnnouncerDisabled(true)

    CustomGameEventManager:RegisterListener(
        "poa_preview_selection",
        function(_, event) self:OnPreviewSelection(event) end
    )
    CustomGameEventManager:RegisterListener(
        "poa_confirm_selection",
        function(_, event) self:OnConfirmSelection(event) end
    )

    -- ListenToGameEvent with nil context passes the event table as arg 1.
    ListenToGameEvent(
        "npc_spawned",
        function(event) self:OnNpcSpawned(event) end,
        nil
    )

    ListenToGameEvent(
        "player_chat",
        function(event) self:OnPlayerChat(event) end,
        nil
    )

    pcall(function()
        -- FCVAR_CHEAT blocks non-cheat consoles; IsDevPlayer still gates the body.
        Convars:RegisterCommand("poa_ascend", function(_, indexArg)
            local player = Convars:GetCommandClient()
            local playerID = -1
            if player ~= nil and player.GetPlayerID ~= nil then
                playerID = player:GetPlayerID()
            end
            if (playerID == nil or playerID < 0) and self:IsDevPlayer(0) then
                playerID = 0
            end
            if not self:IsDevPlayer(playerID) then
                return
            end
            self:DevAscendCommand(playerID, indexArg or "")
        end, "Dev only: ascend to class path 1..N", FCVAR_CHEAT)
    end)

    ListenToGameEvent(
        "player_connect_full",
        function()
            self:AssignTeams()
            self:PublishPartyState()
        end,
        nil
    )
    ListenToGameEvent(
        "player_disconnect",
        function() self:PublishPartyState() end,
        nil
    )
    ListenToGameEvent(
        "game_rules_state_change",
        function() self:OnGameRulesStateChange() end,
        nil
    )

    self:PublishPartyState()
    print("[POA] Custom hero selection initialized")

    if not self.entityApiDumped then
        self.entityApiDumped = true
        local apis = {}
        for _, name in pairs({ "CreateUnitByName", "CreateEntityByName", "CreateEntity", "SpawnEntityFromTable" }) do
            apis[name] = type(_G[name])
        end
        if type(Entities) == "table" then
            for _, name in pairs({ "CreateByClassname", "FindByClassname", "FindAllByClassname", "First", "Next" }) do
                apis["Entities." .. name] = type(Entities[name])
            end
        end
        local parts = {}
        for k, v in pairs(apis) do
            table.insert(parts, k .. "=" .. v)
        end
        print("[POA] entity API: " .. table.concat(parts, ", "))
    end
end

function PathOfTheAncients:OrderFilter(filterTable)
	local order = filterTable.order_type
	local units = filterTable.units
	local playerID = filterTable.issuer_player_id_const
    local player = PlayerResource:GetPlayer(playerID)

    if player ~= nil then
        if player:GetAssignedHero():GetName() == "npc_dota_hero_wisp" then return false end
    end

    return true
end

function PathOfTheAncients:IsValidPlayer(playerID)
    return playerID ~= nil
        and playerID >= 0
        and PlayerResource:IsValidPlayerID(playerID)
        and PlayerResource:GetPlayer(playerID) ~= nil
end

function PathOfTheAncients:AssignTeams()
    local assigned = 0
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if self:IsValidPlayer(playerID) and PlayerResource:GetTeam(playerID) ~= DOTA_TEAM_GOODGUYS then
            PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
            assigned = assigned + 1
            print("[POA] Assigned player " .. tostring(playerID) .. " to team " .. tostring(DOTA_TEAM_GOODGUYS))
        end
    end
    return assigned
end

function PathOfTheAncients:SendToPlayer(playerID, eventName, payload)
    if not self:IsValidPlayer(playerID) then
        return
    end

    CustomGameEventManager:Send_ServerToPlayer(
        PlayerResource:GetPlayer(playerID),
        eventName,
        payload or {}
    )
end

function PathOfTheAncients:ResolveSelectable(key)
    if type(key) ~= "string" then
        return nil, nil
    end
    local classDef = BASE_CLASSES[key]
    if classDef ~= nil then
        return key, classDef
    end
    return nil, nil
end

function PathOfTheAncients:OnPreviewSelection(event)
    local playerID = event.PlayerID
    local classKey, classDef = self:ResolveSelectable(event.archetype or event.class)

    if not self:IsValidPlayer(playerID) or classDef == nil then
        return
    end

    if self.selections[playerID] and self.selections[playerID].confirmed then
        return
    end

    self.selections[playerID] = {
        archetype = classKey,
        confirmed = false,
    }
end

function PathOfTheAncients:OnConfirmSelection(event)
    local playerID = event.PlayerID
    local classKey, classDef = self:ResolveSelectable(event.archetype or event.class)

    if not self:IsValidPlayer(playerID) or classDef == nil then
        self:SendToPlayer(playerID, "poa_selection_rejected", {
            message = "That class is not available.",
        })
        return
    end

    if self.selections[playerID] and self.selections[playerID].confirmed then
        return
    end

    self.selections[playerID] = {
        archetype = classKey,
        base_class = classKey,
        playable = classKey,
        confirmed = true,
    }

    print("[POA] Confirmed " .. classKey .. " for player " .. tostring(playerID))

    local heroAssigned, assignedHero = self:ApplySelectedHero(playerID, classDef.hero)
    self.selections[playerID].hero_assigned = heroAssigned
    self.selections[playerID].hero_entindex = assignedHero ~= nil and assignedHero:entindex() or nil

    if heroAssigned and assignedHero ~= nil then
        self:ApplyPlayableCosmetics(assignedHero, classKey, classDef.hero)
    end

    self:SendToPlayer(playerID, "poa_selection_accepted", {
        archetype = classKey,
        hero = classDef.hero,
        message = classDef.display_name .. " confirmed"
    })

    self:AssignTeams()

    local allPlayersReady = self:AllConnectedPlayersReady()
    local published, publishError = pcall(function()
        self:PublishPartyState()
    end)

    if not published then
        print("[POA] Party state publish failed: " .. tostring(publishError))
    end

    local allHeroesAssigned = self:AllConfirmedPlayersHaveAssignedHeroes()

    if allPlayersReady and allHeroesAssigned then
        print("[POA] All connected players ready; starting game")
        CustomGameEventManager:Send_ServerToAllClients("poa_party_ready", {})
        GameRules:ForceGameStart()
    elseif allPlayersReady then
        print("[POA] All players confirmed, but hero assignment is incomplete; game start deferred")
    else
        print("[POA] Game start deferred: connected="
            .. tostring(self:GetConnectedPlayerCount())
            .. ", ready=" .. tostring(self:GetReadyPlayerCount()))
    end
end

-- Econ cosmetics worn by a player's Steam inventory are networked to the
-- server in online games, but their models are not resident in the addon
-- mount and render as "error" quads. Strip them server-side so every hero
-- uses its default look; default wearables live under models/heroes/ and are
-- kept. Per-archetype overrides in precache_cosmetics.lua survive stripping.
local ECON_WEARABLE_MODEL_PREFIX = "models/items/"
local WEARABLE_STRIP_DURATION_SECONDS = 60
local WEARABLE_STRIP_INTERVAL_SECONDS = 0.5

function PathOfTheAncients:CreateWearableEntity()
    -- prop_dynamic, not dota_item_wearable: the hero KV sets DisableWearables 1,
    -- which makes the client hide every dota_item_wearable child (including
    -- server-attached ones). prop_dynamic renders normally and bone-follows.
    if type(Entities) == "table" and Entities.CreateByClassname ~= nil then
        return Entities:CreateByClassname("prop_dynamic")
    end
    return nil
end

function PathOfTheAncients:NormalizeWearableEntry(entry)
    if type(entry) == "string" then
        return entry, nil, true, nil
    end
    if type(entry) == "table" and type(entry.model) == "string" then
        local boneMerge = entry.bone_merge
        if boneMerge == nil then
            boneMerge = (entry.attach == nil or entry.attach == "")
        end
        return entry.model, entry.attach, boneMerge, entry.offset
    end
    return nil, nil, true, nil
end

function PathOfTheAncients:AttachWearables(hero, archetypeKey, models, label)
    if hero == nil or hero:IsNull() or models == nil or #models == 0 then
        return
    end

    local attached = 0
    for _, entry in pairs(models) do
        local model, attach, boneMerge, offset = self:NormalizeWearableEntry(entry)
        if model == nil then
            print("[POA] " .. label .. " wearable entry invalid: " .. tostring(entry))
        else
            local ok, result = pcall(function()
                local wearable = self:CreateWearableEntity()
                if wearable == nil then
                    error("no entity creation API available")
                end
                if boneMerge or attach == nil or attach == "" then
                    wearable:FollowEntity(hero, true)
                else
                    wearable:SetParent(hero, attach)
                    local origin = Vector(0, 0, 0)
                    if type(offset) == "table" then
                        origin = Vector(offset[1] or 0, offset[2] or 0, offset[3] or 0)
                    elseif offset ~= nil then
                        origin = offset
                    end
                    wearable:SetLocalOrigin(origin)
                    wearable:SetLocalAngles(0, 0, 0)
                end
                wearable:SetModel(model)
                return wearable
            end)
            if ok and result ~= nil then
                attached = attached + 1
                local playerID = hero:GetPlayerOwnerID()
                local selection = self.selections[playerID]
                if selection ~= nil then
                    selection.override_entindexes = selection.override_entindexes or {}
                    table.insert(selection.override_entindexes, result:entindex())
                end
            else
                print("[POA] " .. label .. " wearable attach failed for " .. model
                    .. " attach=" .. tostring(attach) .. ": " .. tostring(result))
            end
        end
    end
    print("[POA] Attached " .. tostring(attached) .. "/" .. tostring(#models) .. " " .. label
        .. " wearables to " .. hero:GetUnitName() .. " for " .. archetypeKey)
end

function PathOfTheAncients:ApplyActivityModifiers(hero, modifiers)
    if hero == nil or hero:IsNull() or modifiers == nil then
        return
    end
    for _, modifier in pairs(modifiers) do
        local ok, err = pcall(function()
            hero:AddActivityModifier(modifier)
        end)
        if ok then
            print("[POA] Applied activity modifier '" .. modifier .. "' to " .. hero:GetUnitName())
        else
            print("[POA] Activity modifier '" .. modifier .. "' failed: " .. tostring(err))
        end
    end
end

function PathOfTheAncients:AttachHeroParticles(hero, particles)
    if hero == nil or hero:IsNull() or particles == nil then
        return
    end
    for _, particle in pairs(particles) do
        if type(particle.path) == "string" then
            local ok, err = pcall(function()
                local attach = particle.attach or "follow_origin"
                local pid
                if attach == "follow_origin" then
                    pid = ParticleManager:CreateParticle(particle.path, PATTACH_ABSORIGIN_FOLLOW, hero)
                elseif attach == "attach_hitloc" or attach == "attach_attack1" or attach == "attach_attack2" then
                    pid = ParticleManager:CreateParticle(particle.path, PATTACH_POINT_FOLLOW, hero)
                    ParticleManager:SetParticleControlEnt(
                        pid, 0, hero, PATTACH_POINT_FOLLOW, attach, hero:GetAbsOrigin(), true
                    )
                else
                    pid = ParticleManager:CreateParticle(particle.path, PATTACH_ABSORIGIN_FOLLOW, hero)
                end
                -- Do not ReleaseParticleIndex: ambient arcana FX must keep playing.
            end)
            if ok then
                print("[POA] Spawned particle " .. particle.path)
            else
                print("[POA] Particle failed " .. particle.path .. ": " .. tostring(err))
            end
        end
    end
end

function PathOfTheAncients:ApplyVisualPreset(hero, heroName)
    local presets = DEFAULT_WEARABLES._visual_presets
    local preset = presets and presets[heroName]
    if hero == nil or hero:IsNull() or preset == nil then
        return false
    end

    if type(preset.activity_modifiers) == "table" then
        self:ApplyActivityModifiers(hero, preset.activity_modifiers)
    end

    if type(preset.model) == "string" then
        local ok, err = pcall(function()
            if hero.SetOriginalModel ~= nil then
                hero:SetOriginalModel(preset.model)
            end
            hero:SetModel(preset.model)
        end)
        if ok then
            print("[POA] Set visual model " .. preset.model .. " on " .. hero:GetUnitName())
        else
            print("[POA] Set visual model failed: " .. tostring(err))
        end
    end

    if preset.skin ~= nil then
        pcall(function()
            hero:SetSkin(preset.skin)
        end)
        pcall(function()
            hero:SetMaterialGroup(tostring(preset.skin))
        end)
    end

    if type(preset.weapons) == "table" then
        local pieces = {}
        for _, weapon in pairs(preset.weapons) do
            if weapon.bone_merge then
                table.insert(pieces, weapon.model)
            else
                table.insert(pieces, {
                    model = weapon.model,
                    attach = weapon.attach or "attach_attack1",
                })
            end
        end
        self:AttachWearables(hero, heroName, pieces, "preset-weapon")
    end

    self:AttachHeroParticles(hero, preset.particles)
    -- true = preset applied; caller still attaches DEFAULT_WEARABLES body pieces
    return true
end

function PathOfTheAncients:ApplyCosmeticOverrides(hero, archetypeKey)
    self:AttachWearables(hero, archetypeKey, COSMETIC_OVERRIDES[archetypeKey], "override")
end

function PathOfTheAncients:ApplyDefaultWearables(hero, archetypeKey, heroName)
    local modifiers = DEFAULT_WEARABLES._activity_modifiers
        and DEFAULT_WEARABLES._activity_modifiers[heroName]
    self:ApplyActivityModifiers(hero, modifiers)

    local usedPreset = self:ApplyVisualPreset(hero, heroName)
    if not usedPreset then
        self:AttachWearables(hero, archetypeKey, DEFAULT_WEARABLES[heroName], "default")
    elseif DEFAULT_WEARABLES[heroName] ~= nil and #DEFAULT_WEARABLES[heroName] > 0 then
        -- Preset may still want body-slot pieces (e.g. LC body + arcana blades).
        self:AttachWearables(hero, archetypeKey, DEFAULT_WEARABLES[heroName], "default")
    end
end

function PathOfTheAncients:IsOverrideWearable(entity)
    for _, selection in pairs(self.selections) do
        if selection.override_entindexes ~= nil then
            for _, entindex in pairs(selection.override_entindexes) do
                if entindex == entity:entindex() then
                    return true
                end
            end
        end
    end
    return false
end

function PathOfTheAncients:DestroyWearableEntity(entity)
    if entity == nil or entity:IsNull() then
        return false
    end
    local removed = pcall(function()
        entity:RemoveSelf()
    end)
    if not removed then
        removed = pcall(function()
            UTIL_Remove(entity)
        end)
    end
    if not removed then
        removed = pcall(function()
            entity:Remove()
        end)
    end
    return removed
end

-- prop_dynamic pieces FollowEntity the hero; ReplaceHeroWith leaves them
-- orphaned on the ground unless destroyed first.
function PathOfTheAncients:ClearAttachedWearables(playerID, hero)
    local removed = 0
    local selection = self.selections[playerID]

    if selection ~= nil and selection.override_entindexes ~= nil then
        for _, entindex in pairs(selection.override_entindexes) do
            local entity = EntIndexToHScript(entindex)
            if self:DestroyWearableEntity(entity) then
                removed = removed + 1
            end
        end
        selection.override_entindexes = {}
    end

    if hero ~= nil and not hero:IsNull() then
        local child = nil
        pcall(function()
            child = hero:FirstMoveChild()
        end)
        while child ~= nil do
            local nextChild = nil
            pcall(function()
                nextChild = child:NextMovePeer()
            end)
            local classname = nil
            pcall(function()
                classname = child:GetClassname()
            end)
            if classname == "prop_dynamic"
                or classname == "dota_item_wearable"
                or classname == "additional_wearable" then
                if self:DestroyWearableEntity(child) then
                    removed = removed + 1
                end
            end
            child = nextChild
        end
    end

    if removed > 0 then
        print("[POA] Cleared " .. tostring(removed)
            .. " wearables before hero change for player " .. tostring(playerID))
    end
    return removed
end

function PathOfTheAncients:StripEconWearables(hero)
    if hero == nil or hero:IsNull() then
        return 0
    end

    local removed = 0
    local child = hero:FirstMoveChild()
    while child ~= nil do
        local nextChild = child:NextMovePeer()
        local model = child:GetModelName()
        if child:GetClassname() == "dota_item_wearable"
            and model ~= nil
            and string.sub(model, 1, #ECON_WEARABLE_MODEL_PREFIX) == ECON_WEARABLE_MODEL_PREFIX
            and not self:IsOverrideWearable(child)
        then
            child:Remove()
            removed = removed + 1
        end
        child = nextChild
    end

    if removed > 0 then
        print("[POA] Removed " .. tostring(removed) .. " econ wearables from " .. hero:GetUnitName())
    end
    return removed
end

function PathOfTheAncients:ScheduleEconWearableStripping(hero)
    if hero == nil or hero:IsNull() then
        return
    end

    local deadline = GameRules:GetGameTime() + WEARABLE_STRIP_DURATION_SECONDS
    hero:SetContextThink("POA_StripEconWearables", function()
        if hero:IsNull() then
            return nil
        end
        self:StripEconWearables(hero)
        if GameRules:GetGameTime() < deadline then
            return WEARABLE_STRIP_INTERVAL_SECONDS
        end
        return nil
    end, 0.1)
end

-- Steam account IDs allowed to use -ascend outside Workshop Tools.
-- Account ID = the number in [U:1:XXXXXXXX] (not the full 64-bit SteamID).
local DEV_STEAM_ACCOUNT_IDS = {
    [850174398] = true, -- capaxed
    [122677592] = true, -- axwell
}

function PathOfTheAncients:GetPlayerSteamAccountID(playerID)
    local accountID = 0
    pcall(function()
        accountID = PlayerResource:GetSteamAccountID(playerID) or 0
    end)
    return accountID
end

-- Dev commands are never granted by sv_cheats alone (lobby players can enable
-- cheats). Allowed only in Workshop Tools, or for whitelisted Steam accounts.
function PathOfTheAncients:IsDevPlayer(playerID)
    if type(playerID) ~= "number" or playerID < 0 then
        return false
    end

    if IsInToolsMode and IsInToolsMode() then
        return true
    end

    local accountID = self:GetPlayerSteamAccountID(playerID)
    if accountID ~= 0 and DEV_STEAM_ACCOUNT_IDS[accountID] == true then
        return true
    end

    return false
end

function PathOfTheAncients:DumpHeroAbilities(hero, label)
    if hero == nil or hero:IsNull() then
        return
    end
    local count = 0
    pcall(function()
        count = hero:GetAbilityCount() or 0
    end)
    local parts = {}
    for i = 0, count - 1 do
        local ability = nil
        pcall(function()
            ability = hero:GetAbilityByIndex(i)
        end)
        if ability ~= nil and not ability:IsNull() then
            local name = ""
            local level = 0
            pcall(function()
                name = ability:GetAbilityName() or ""
            end)
            pcall(function()
                level = ability:GetLevel() or 0
            end)
            table.insert(parts, tostring(i) .. ":" .. name .. "(" .. tostring(level) .. ")")
        end
    end
    print("[POA DIAG] ability dump [" .. label .. "] " .. hero:GetUnitName()
        .. " count=" .. tostring(count) .. " -> " .. table.concat(parts, " | "))
end

function PathOfTheAncients:GrantClassAbilities(hero, playableKey)
    if hero == nil or hero:IsNull() or type(playableKey) ~= "string" then
        return
    end
    local kit = CLASS_ABILITIES[playableKey]
    if kit == nil then
        return
    end
    local guard = 0
    while guard < 30 do
        local has = false
        pcall(function() has = hero:HasAbility("generic_hidden") or false end)
        if not has then
            break
        end
        local ok = pcall(function()
            hero:RemoveAbility("generic_hidden")
        end)
        if not ok then
            break
        end
        guard = guard + 1
    end
    for _, name in ipairs(kit) do
        local already = false
        pcall(function() already = hero:HasAbility(name) or false end)
        if not already then
            local granted, result = pcall(function()
                return hero:AddAbility(name)
            end)
            if granted and result ~= nil then
                pcall(function()
                    result:SetLevel(1)
                end)
                print("[POA] Granted ability " .. name .. " to " .. hero:GetUnitName())
            else
                print("[POA] Failed to grant ability " .. name .. ": " .. tostring(result))
            end
        else
            pcall(function()
                local existing = hero:FindAbilityByName(name)
                if existing ~= nil then
                    existing:SetLevel(1)
                end
            end)
        end
    end
    self:DumpHeroAbilities(hero, "post-grant")
end

-- Safe error formatter: the engine's default error handler can itself throw and
-- collapse to "Script Runtime Error: error in error handling", hiding the real
-- cause. Catching and re-printing via pcall reveals it.
function PathOfTheAncients:FmtError(e)
    local ok, s = pcall(function() return tostring(e) end)
    if ok then
        return s
    end
    return "non-string error"
end

-- Returns the base class key any playable (base class or ascendancy) belongs
-- to. Innates are base-class systems, so grant one and only one per base class.
function PathOfTheAncients:GetBaseClassKey(playableKey)
    if type(playableKey) ~= "string" then
        return nil
    end
    if BASE_CLASSES[playableKey] ~= nil then
        return playableKey
    end
    local def = ASCENDANCY_BY_KEY[playableKey]
    if def ~= nil then
        return def.class_key
    end
    return nil
end

-- Grants the base class innate: its signature skills plus the runtime module
-- hook (e.g. a class resource attach). Innates are distinct from
-- CLASS_ABILITIES kits; see class_innates.lua.
function PathOfTheAncients:GrantClassInnate(hero, playableKey)
    if hero == nil or hero:IsNull() then
        return
    end
    local baseClassKey = self:GetBaseClassKey(playableKey)
    -- An ascendancy's innate replaces the base class innate: prefer the
    -- ascendancy's own innate, falling back to the base class innate.
    local innate = ASCENDANCY_INNATES[playableKey] or ((baseClassKey ~= nil) and CLASS_INNATES[baseClassKey] or nil)
    if innate == nil then
        return
    end

    -- Grant the innate AFTER the six generic_hidden placeholders (indices 0-5)
    -- left by StripDefaultAbilities, so it appends at a high index and never
    -- occupies a visible QWER slot. Its INNATE_UI behavior renders it in the
    -- innate diamond regardless of the numeric index.
    local startIndex = 6
    local currentIndex = startIndex

    if type(innate.skills) == "table" then
        print("[POA] Granting innate skills for " .. tostring(baseClassKey)
            .. " to " .. hero:GetUnitName() .. ": " .. table.concat(innate.skills, ","))
        for _, name in ipairs(innate.skills) do
            local already = false
            pcall(function() already = hero:HasAbility(name) or false end)
            if not already then
                local granted, result = pcall(function()
                    return hero:AddAbility(name)
                end)
                if granted and result ~= nil then
                    print("[POA] Granted innate skill " .. name .. " at slot "
                        .. tostring(currentIndex) .. " to " .. hero:GetUnitName())
                    currentIndex = currentIndex + 1
                    pcall(function() result:SetLevel(1) end)
                    print("[POA] Innate " .. name .. " leveled to " .. hero:GetUnitName())
                else
                    print("[POA] Failed to grant innate skill " .. name .. ": " .. tostring(result))
                end
            else
                pcall(function()
                    local existing = hero:FindAbilityByName(name)
                    if existing ~= nil then
                        existing:SetLevel(1)
                    end
                end)
            end
        end
    end

-- Runtime module lookup: prefer the innate's own key (ascendancy innates
    -- register under their innate key, e.g. "adaptability"), fall back to the
    -- base class key.
    local module = INNATE_MODULES[innate.key] or INNATE_MODULES[baseClassKey]
    if module ~= nil and type(module.OnHeroApply) == "function" then
        pcall(function()
            module.OnHeroApply(hero)
        end)
    end
end

function PathOfTheAncients:ApplyPlayableCosmetics(hero, playableKey, heroName)
    local ok, err = pcall(function()
        self:ApplyPlayableCosmeticsInner(hero, playableKey, heroName)
    end)
    if not ok then
        print("[POA] ApplyPlayableCosmetics error: " .. self:FmtError(err))
    end
end

function PathOfTheAncients:ApplyPlayableCosmeticsInner(hero, playableKey, heroName)
    if hero == nil or hero:IsNull() then
        return
    end
    local playerID = -1
    pcall(function()
        playerID = hero:GetPlayerOwnerID()
    end)
    if type(playerID) == "number" and playerID >= 0 then
        -- Drop any leftover props from a prior body before attaching new ones.
        self:ClearAttachedWearables(playerID, hero)
    end
    self:StripDefaultAbilities(hero)
    self:GrantClassAbilities(hero, playableKey)
    self:GrantClassInnate(hero, playableKey)
    self:ScheduleEconWearableStripping(hero)
    if COSMETIC_OVERRIDES[playableKey] ~= nil then
        self:ApplyCosmeticOverrides(hero, playableKey)
    else
        self:ApplyDefaultWearables(hero, playableKey, heroName)
    end
end

function PathOfTheAncients:SayDev(playerID, message)
    print("[POA DEV] player " .. tostring(playerID) .. ": " .. tostring(message))
    self:SendToPlayer(playerID, "poa_selection_accepted", {
        message = tostring(message),
    })
    -- Also surface in chat when possible.
    pcall(function()
        GameRules:SendCustomMessage("[POA] " .. tostring(message), 0, 0)
    end)
end

function PathOfTheAncients:ResolveChatPlayerID(event)
    if event == nil then
        return -1
    end

    local playerID = event.playerid
    if playerID == nil then
        playerID = event.PlayerID
    end
    if type(playerID) == "number" and playerID >= 0 then
        return playerID
    end

    local userID = event.userid
    if type(userID) == "number" then
        local mapped = nil
        pcall(function()
            if PlayerResource.GetPlayerCount ~= nil then
                for id = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
                    if PlayerResource:IsValidPlayerID(id)
                        and PlayerResource:GetSteamAccountID(id) ~= 0 then
                        -- fallback scan; prefer GetPlayerIDByUserId when present
                    end
                end
            end
            if PlayerResource.GetPlayerIDByUserId ~= nil then
                mapped = PlayerResource:GetPlayerIDByUserId(userID)
            elseif PlayerResource.GetPlayerIDFromUserID ~= nil then
                mapped = PlayerResource:GetPlayerIDFromUserID(userID)
            end
        end)
        if type(mapped) == "number" and mapped >= 0 then
            return mapped
        end
    end

    return -1
end

function PathOfTheAncients:OnPlayerChat(event)
    if type(event) ~= "table" then
        print("[POA] player_chat ignored: bad event type " .. type(event))
        return
    end

    local text = event.text
    if type(text) ~= "string" then
        print("[POA] player_chat ignored: missing text")
        return
    end

    local playerID = self:ResolveChatPlayerID(event)
    print("[POA] player_chat pid=" .. tostring(playerID)
        .. " text=\"" .. text .. "\"")

    if playerID < 0 then
        -- Solo listen-server chat sometimes omits playerid; default to 0.
        if PlayerResource:IsValidPlayerID(0) then
            playerID = 0
        else
            return
        end
    end

    local normalized = string.lower(string.gsub(text, "^%s+", ""))
    -- Accept "-ascend 1", "ascend 1", "-ASCEND 2"
    local cmd, arg = string.match(normalized, "^%-?([%w_]+)%s*(.*)$")
    if cmd == nil then
        return
    end

    if cmd == "ascend" then
        self:DevAscendCommand(playerID, arg)
    end
end

function PathOfTheAncients:DevAscendCommand(playerID, arg)
    local isDev = self:IsDevPlayer(playerID)
    print("[POA DEV] ascend request player=" .. tostring(playerID)
        .. " steam=" .. tostring(self:GetPlayerSteamAccountID(playerID))
        .. " arg=\"" .. tostring(arg) .. "\" dev=" .. tostring(isDev))

    if not isDev then
        -- Silent reject: do not teach the command to normal players.
        return
    end

    local selection = self.selections[playerID]
    if selection == nil or not selection.confirmed then
        self:SayDev(playerID, "Confirm a base class before ascending.")
        return
    end

    local baseClass = selection.base_class or selection.archetype
    local list = CLASS_ASCENDANCIES[baseClass]
    if list == nil or #list == 0 then
        self:SayDev(playerID, "No ascendancies for class " .. tostring(baseClass))
        return
    end

    arg = string.gsub(tostring(arg or ""), "^%s+", "")
    arg = string.gsub(arg, "%s+$", "")
    if arg == "" then
        local lines = { "Ascendancies for " .. tostring(baseClass) .. ":" }
        lines[#lines+1] = "-ascend 0=Return to base class (" .. (BASE_CLASSES[baseClass] and BASE_CLASSES[baseClass].display_name or baseClass) .. ")"
        for i, ascendancy in ipairs(list) do
            table.insert(lines, "-ascend " .. tostring(i) .. "=" .. ascendancy.display_name)
        end
        self:SayDev(playerID, table.concat(lines, " | "))
        return
    end

    local index = tonumber(arg)
    if index == nil or index < 0 or index > #list or index ~= math.floor(index) then
        self:SayDev(playerID, "Usage: -ascend 0.." .. tostring(#list))
        return
    end

    local ascendancy, targetHero, targetPlayableKey
    local displayName
    if index == 0 then
        -- Return to the base class (drop the ascendancy).
        local baseDef = BASE_CLASSES[baseClass]
        if baseDef == nil then
            self:SayDev(playerID, "No base class definition for " .. tostring(baseClass))
            return
        end
        targetHero = baseDef.hero
        targetPlayableKey = baseClass
        displayName = baseDef.display_name or baseClass
    else
        ascendancy = list[index]
        targetHero = ascendancy.hero
        targetPlayableKey = ascendancy.key
        displayName = ascendancy.display_name
    end

    local previousPlayable = selection.playable or selection.archetype
    -- Mark authorized before replace so enforce-think does not strip the new hero.
    selection.base_class = baseClass
    selection.playable = targetPlayableKey
    selection.archetype = baseClass

    local heroAssigned, assignedHero = self:ApplySelectedHero(playerID, targetHero)
    if not heroAssigned or assignedHero == nil then
        selection.playable = previousPlayable
        self:SayDev(playerID, "Failed to " .. (index == 0 and "return to base class" or "ascend to " .. displayName))
        return
    end

    selection.hero_assigned = true
    selection.hero_entindex = assignedHero:entindex()
    self:ApplyPlayableCosmetics(assignedHero, targetPlayableKey, targetHero)

    if index == 0 then
        print("[POA DEV] player " .. tostring(playerID) .. " returned to base class "
            .. tostring(baseClass))
        self:SayDev(playerID, "Returned to " .. displayName .. " (base class)")
    else
        print("[POA DEV] player " .. tostring(playerID) .. " ascended "
            .. tostring(baseClass) .. " -> " .. ascendancy.key)
        self:SayDev(playerID, "Ascended to " .. displayName
            .. " (" .. tostring(index) .. "/" .. tostring(#list) .. ")")
    end
end

function PathOfTheAncients:GetPlayableDefinition(playableKey)
    if type(playableKey) ~= "string" then
        return nil
    end
    if BASE_CLASSES[playableKey] ~= nil then
        return BASE_CLASSES[playableKey]
    end
    return ASCENDANCY_BY_KEY[playableKey]
end

function PathOfTheAncients:ApplySelectedHero(playerID, heroName)
    local player = PlayerResource:GetPlayer(playerID)
    if player == nil then
        print("[POA] Hero assignment failed for player " .. tostring(playerID) .. ": player handle unavailable")
        return false
    end

    local currentHero = PlayerResource:GetSelectedHeroEntity(playerID) or player:GetAssignedHero()
    if currentHero ~= nil and currentHero:GetUnitName() == heroName then
        print("[POA] Hero already assigned for player " .. tostring(playerID) .. ": " .. heroName)
        return true, currentHero
    end

    if currentHero == nil then
        local created, createdHeroOrError = pcall(function()
            return CreateHeroForPlayer(heroName, player)
        end)

        if not created then
            print("[POA] Hero creation failed for player " .. tostring(playerID) .. ": " .. tostring(createdHeroOrError))
            return false
        end

        currentHero = PlayerResource:GetSelectedHeroEntity(playerID)
            or player:GetAssignedHero()
            or createdHeroOrError

        if currentHero ~= nil and currentHero:GetUnitName() == heroName then
            if currentHero:GetPlayerOwnerID() ~= playerID then
                print("[POA] Hero handoff failed for player " .. tostring(playerID)
                    .. ": created hero has owner " .. tostring(currentHero:GetPlayerOwnerID()))
                return false
            end

            local handedOff, handoffError = pcall(function()
                player:SetAssignedHeroEntity(currentHero)
                currentHero:SetControllableByPlayer(playerID, true)
            end)

            if not handedOff then
                print("[POA] Hero handoff failed for player " .. tostring(playerID)
                    .. ": " .. tostring(handoffError))
                return false
            end

            local assignedHero = player:GetAssignedHero()
            if assignedHero ~= currentHero then
                print("[POA] Hero handoff incomplete for player " .. tostring(playerID)
                    .. ": assigned hero does not match created hero")
                return false
            end

            print("[POA] Created, assigned, and enabled control of " .. heroName
                .. " for player " .. tostring(playerID))
            return true, currentHero
        end

        local createdName = currentHero ~= nil and currentHero:GetUnitName() or "none"
        print("[POA] Hero creation incomplete for player " .. tostring(playerID)
            .. "; requested " .. heroName .. ", found " .. createdName)
        return false
    end

    local progress = self:CaptureHeroProgress(playerID, currentHero)

    -- Destroy FollowEntity props first; ReplaceHeroWith does not take them with
    -- the old hero and they otherwise drop in-world as permanent props.
    self:ClearAttachedWearables(playerID, currentHero)

    local replaced, replacementError = pcall(function()
        return PlayerResource:ReplaceHeroWith(
            playerID,
            heroName,
            progress.gold,
            progress.xp
        )
    end)

    if not replaced then
        print("[POA] Hero assignment failed for player " .. tostring(playerID) .. ": " .. tostring(replacementError))
        return false
    end

    local assignedHero = PlayerResource:GetSelectedHeroEntity(playerID) or player:GetAssignedHero()
    if assignedHero ~= nil and assignedHero:GetUnitName() == heroName then
        self:RestoreHeroProgress(playerID, assignedHero, progress)
        print("[POA] Assigned " .. heroName .. " to player " .. tostring(playerID)
            .. " (level " .. tostring(progress.level) .. ", xp " .. tostring(progress.xp)
            .. ", gold " .. tostring(progress.gold) .. ")")
        return true, assignedHero
    end

    local assignedName = assignedHero ~= nil and assignedHero:GetUnitName() or "none"
    print("[POA] Hero assignment incomplete for player " .. tostring(playerID)
        .. "; requested " .. heroName .. ", found " .. assignedName)
    return false
end

function PathOfTheAncients:CaptureHeroProgress(playerID, hero)
    local progress = {
        gold = 0,
        xp = 0,
        level = 1,
        ability_points = 0,
    }

    pcall(function()
        progress.gold = PlayerResource:GetGold(playerID) or 0
    end)

    if hero == nil or hero:IsNull() then
        return progress
    end

    pcall(function()
        progress.level = hero:GetLevel() or 1
    end)
    pcall(function()
        progress.xp = hero:GetCurrentXP() or 0
    end)
    pcall(function()
        progress.ability_points = hero:GetAbilityPoints() or 0
    end)

    -- If XP looks empty but level is above 1, derive a minimum XP floor from level.
    if (progress.xp == nil or progress.xp <= 0) and progress.level > 1 then
        local derived = 0
        pcall(function()
            if XP_PER_LEVEL_TABLE ~= nil then
                derived = XP_PER_LEVEL_TABLE[progress.level] or 0
            end
        end)
        if derived > 0 then
            progress.xp = derived
        end
    end

    return progress
end

function PathOfTheAncients:RestoreHeroProgress(playerID, hero, progress)
    if hero == nil or hero:IsNull() or progress == nil then
        return
    end

    pcall(function()
        PlayerResource:SetGold(playerID, progress.gold or 0, false)
        PlayerResource:SetGold(playerID, 0, true)
    end)

    local targetLevel = math.max(1, tonumber(progress.level) or 1)
    local targetXP = math.max(0, tonumber(progress.xp) or 0)

    -- ReplaceHeroWith often ignores/resets XP; force level + XP after spawn.
    local currentLevel = 1
    pcall(function() currentLevel = hero:GetLevel() or 1 end)

    if targetLevel > currentLevel then
        for _ = currentLevel, targetLevel - 1 do
            local leveled = pcall(function()
                hero:HeroLevelUp(false)
            end)
            if not leveled then
                break
            end
        end
    end

    local currentXP = 0
    pcall(function() currentXP = hero:GetCurrentXP() or 0 end)
    if targetXP > currentXP then
        local xpReason = 0
        pcall(function()
            if DOTA_ModifyXP_Unspecified ~= nil then
                xpReason = DOTA_ModifyXP_Unspecified
            end
        end)
        pcall(function()
            hero:AddExperience(targetXP - currentXP, xpReason, false, true)
        end)
    end

    -- Keep unspent ability points at least what the player had (HeroLevelUp may add more).
    pcall(function()
        local points = hero:GetAbilityPoints() or 0
        local desired = math.max(points, tonumber(progress.ability_points) or 0)
        if desired > points and hero.SetAbilityPoints ~= nil then
            hero:SetAbilityPoints(desired)
        end
    end)

    pcall(function()
        print("[POA] Restored progress on " .. hero:GetUnitName()
            .. " level=" .. tostring(hero:GetLevel())
            .. " xp=" .. tostring(hero:GetCurrentXP())
            .. " gold=" .. tostring(PlayerResource:GetGold(playerID)))
    end)
end

function PathOfTheAncients:ForceDummyHeroes()
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if self:IsValidPlayer(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            if player ~= nil then
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                    or player:GetAssignedHero()
                if hero == nil or hero:IsNull() then
                    player:SetSelectedHero("npc_dota_hero_wisp")
                    print("[POA] Successfully forced dummy hero for player " .. tostring(playerID))
                end
            end
        end
    end
end

function PathOfTheAncients:OnGameRulesStateChange()
    -- A zero auto-launch delay does not reliably skip the setup screen on
    -- every build, so force it closed as soon as the setup state is entered.
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        self:AssignTeams()
        GameRules:FinishCustomGameSetup()
        return
    end

    if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
        self:ForceDummyHeroes()
        return
    end

    for playerID, selection in pairs(self.selections) do
        local playable = self:GetPlayableDefinition(selection.playable or selection.archetype)
        if selection.confirmed and playable ~= nil and self:IsValidPlayer(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            local hero = selection.hero_entindex ~= nil
                and EntIndexToHScript(selection.hero_entindex)
                or nil
            if player ~= nil
                and hero ~= nil
                and not hero:IsNull()
                and hero:GetUnitName() == playable.hero
                and hero:GetPlayerOwnerID() == playerID
                and player:GetAssignedHero() == hero then
                print("[POA] Verified existing hero for player " .. tostring(playerID)
                    .. "; duplicate creation prevented")
            else
                print("[POA] Recorded hero validation failed for player " .. tostring(playerID)
                    .. "; no replacement hero created")
            end
        end
    end
end

function PathOfTheAncients:GetConnectedPlayerCount()
    local count = 0
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if self:IsValidPlayer(playerID) then
            count = count + 1
        end
    end
    return count
end

function PathOfTheAncients:GetReadyPlayerCount()
    local count = 0
    for playerID, selection in pairs(self.selections) do
        if selection.confirmed and self:IsValidPlayer(playerID) then
            count = count + 1
        end
    end
    return count
end

function PathOfTheAncients:AllConnectedPlayersReady()
    local playerCount = self:GetConnectedPlayerCount()
    return playerCount > 0 and self:GetReadyPlayerCount() >= playerCount
end

function PathOfTheAncients:AllConfirmedPlayersHaveAssignedHeroes()
    for playerID, selection in pairs(self.selections) do
        if selection.confirmed then
            local playable = self:GetPlayableDefinition(selection.playable or selection.archetype)
            local player = PlayerResource:GetPlayer(playerID)
            local hero = selection.hero_entindex ~= nil
                and EntIndexToHScript(selection.hero_entindex)
                or nil
            if not selection.hero_assigned
                or playable == nil
                or player == nil
                or hero == nil
                or hero:IsNull()
                or hero:GetUnitName() ~= playable.hero
                or hero:GetPlayerOwnerID() ~= playerID
                or player:GetAssignedHero() ~= hero then
                return false
            end
        end
    end
    return true
end

function PathOfTheAncients:PublishPartyState()
    CustomNetTables:SetTableValue("poa_selection", "party", {
        player_count = self:GetConnectedPlayerCount(),
        ready_count = self:GetReadyPlayerCount(),
    })
end

function PathOfTheAncients:OnNpcSpawned(event)
    if event == nil or event.entindex == nil then
        return
    end

    local entity = EntIndexToHScript(event.entindex)
    if entity == nil or entity:IsNull() or not entity:IsRealHero() then
        return
    end
end

function PathOfTheAncients:StripDefaultAbilities(hero)
    if hero == nil or hero:IsNull() then
        return 0
    end

    local removed = 0
    local count = 0
    pcall(function()
        count = hero:GetAbilityCount() or 0
    end)

    -- Walk high-to-low so removals do not shift unread indexes.
    for i = count - 1, 0, -1 do
        local ability = nil
        pcall(function()
            ability = hero:GetAbilityByIndex(i)
        end)
        if ability ~= nil and not ability:IsNull() then
            local name = nil
            pcall(function()
                name = ability:GetAbilityName()
            end)
            -- Keep poa_ custom abilities defined in hero KV; strip Dota defaults.
            if type(name) == "string"
                and name ~= ""
                and name ~= "generic_hidden"
                and string.sub(name, 1, 4) ~= "poa_" then
                local ok = pcall(function()
                    hero:RemoveAbility(name)
                end)
                if ok then
                    removed = removed + 1
                end
            end
        end
    end

    -- Keep six blank bar slots for future custom skills.
    local placeholders = 0
    pcall(function()
        for i = 0, 5 do
            local slot = hero:GetAbilityByIndex(i)
            if slot == nil or slot:IsNull() then
                hero:AddAbility("generic_hidden")
                placeholders = placeholders + 1
            end
        end
    end)

    if removed > 0 or placeholders > 0 then
        print("[POA] Stripped " .. tostring(removed) .. " default abilities from "
            .. hero:GetUnitName() .. " (placeholders +" .. tostring(placeholders) .. ")")
    end
    return removed
end