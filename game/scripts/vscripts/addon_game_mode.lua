require("libraries/timers")

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
        confirmed = true,
    }

    print("[POA] Confirmed " .. classKey .. " for player " .. tostring(playerID))

    local heroAssigned, assignedHero = self:ApplySelectedHero(playerID, classDef.hero)
    self.selections[playerID].hero_assigned = heroAssigned
    self.selections[playerID].hero_entindex = assignedHero ~= nil and assignedHero:entindex() or nil

    if heroAssigned and assignedHero ~= nil then
        self:ScheduleEconWearableStripping(assignedHero)
        if COSMETIC_OVERRIDES[classKey] ~= nil then
            self:ApplyCosmeticOverrides(assignedHero, classKey)
        else
            self:ApplyDefaultWearables(assignedHero, classKey, classDef.hero)
        end
    end

    self:SendToPlayer(playerID, "poa_selection_accepted", {
        archetype = classKey,
        hero = classDef.hero,
        message = classDef.display_name .. " confirmed",
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

    local replaced, replacementError = pcall(function()
        return PlayerResource:ReplaceHeroWith(playerID, heroName, 0, 0)
    end)

    if not replaced then
        print("[POA] Hero assignment failed for player " .. tostring(playerID) .. ": " .. tostring(replacementError))
        return false
    end

    local assignedHero = PlayerResource:GetSelectedHeroEntity(playerID) or player:GetAssignedHero()
    if assignedHero ~= nil and assignedHero:GetUnitName() == heroName then
        print("[POA] Assigned " .. heroName .. " to player " .. tostring(playerID))
        return true, assignedHero
    end

    local assignedName = assignedHero ~= nil and assignedHero:GetUnitName() or "none"
    print("[POA] Hero assignment incomplete for player " .. tostring(playerID)
        .. "; requested " .. heroName .. ", found " .. assignedName)
    return false
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
        local classDef = BASE_CLASSES[selection.archetype]
        if selection.confirmed and classDef ~= nil and self:IsValidPlayer(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            local hero = selection.hero_entindex ~= nil
                and EntIndexToHScript(selection.hero_entindex)
                or nil
            if player ~= nil
                and hero ~= nil
                and not hero:IsNull()
                and hero:GetUnitName() == classDef.hero
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
            local classDef = BASE_CLASSES[selection.archetype]
            local player = PlayerResource:GetPlayer(playerID)
            local hero = selection.hero_entindex ~= nil
                and EntIndexToHScript(selection.hero_entindex)
                or nil
            if not selection.hero_assigned
                or classDef == nil
                or player == nil
                or hero == nil
                or hero:IsNull()
                or hero:GetUnitName() ~= classDef.hero
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
