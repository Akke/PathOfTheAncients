if LabyrinthOfTheAncients == nil then
    LabyrinthOfTheAncients = class({})
end

-- Fallback cap only: the game normally starts early via ForceGameStart once
-- every connected player has confirmed a specialist, so this exists just to
-- keep the server from forcing the game forward while players read hero
-- details.
local HERO_SELECTION_TIMEOUT_SECONDS = 3600

local ARCHETYPES = {
    berserker = { hero = "npc_dota_hero_skeleton_king", display_name = "Berserker" },
    paladin = { hero = "npc_dota_hero_omniknight", display_name = "Paladin" },
    slayer = { hero = "npc_dota_hero_spectre", display_name = "Slayer" },

    artillerist = { hero = "npc_dota_hero_gyrocopter", display_name = "Artillerist" },
    bloodhound = { hero = "npc_dota_hero_bounty_hunter", display_name = "Bloodhound" },
    death_blade = { hero = "npc_dota_hero_legion_commander", display_name = "Death Blade" },

    deadeye = { hero = "npc_dota_hero_windrunner", display_name = "Deadeye" },
    gunslinger = { hero = "npc_dota_hero_muerta", display_name = "Gunslinger" },
    witch_hunter = { hero = "npc_dota_hero_drow_ranger", display_name = "Witch Hunter" },

    bard = { hero = "npc_dota_hero_largo", display_name = "Bard" },
    drunkard = { hero = "npc_dota_hero_brewmaster", display_name = "Drunkard" },
    puppeteer = { hero = "npc_dota_hero_ringmaster", display_name = "Puppeteer" },

    fire_mage = { hero = "npc_dota_hero_lina", display_name = "Fire Mage" },
    frost_mage = { hero = "npc_dota_hero_crystal_maiden", display_name = "Frost Mage" },
    lightning_mage = { hero = "npc_dota_hero_zuus", display_name = "Lightning Mage" },

    glaivier = { hero = "npc_dota_hero_phantom_lancer", display_name = "Glaivier" },
    striker = { hero = "npc_dota_hero_marci", display_name = "Striker" },
    war_dancer = { hero = "npc_dota_hero_axe", display_name = "War Dancer" },

    druid = { hero = "npc_dota_hero_lone_druid", display_name = "Druid" },
    spiritkin = { hero = "npc_dota_hero_void_spirit", display_name = "Spiritkin" },
    summoner = { hero = "npc_dota_hero_warlock", display_name = "Summoner" },
}

function Precache(context)
    local precached = {}
    for _, archetype in pairs(ARCHETYPES) do
        if not precached[archetype.hero] then
            PrecacheUnitByNameSync(archetype.hero, context)
            precached[archetype.hero] = true
        end
    end
end

function Activate()
    GameRules.LabyrinthOfTheAncients = LabyrinthOfTheAncients()
    GameRules.LabyrinthOfTheAncients:InitGameMode()
end

function LabyrinthOfTheAncients:InitGameMode()
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
    mode:SetAnnouncerDisabled(true)
    mode:SetKillingSpreeAnnouncerDisabled(true)

    CustomGameEventManager:RegisterListener(
        "loa_preview_selection",
        function(_, event) self:OnPreviewSelection(event) end
    )
    CustomGameEventManager:RegisterListener(
        "loa_confirm_selection",
        function(_, event) self:OnConfirmSelection(event) end
    )

    ListenToGameEvent(
        "player_connect_full",
        function() self:PublishPartyState() end,
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
    print("[LOA] Custom hero selection initialized")
end

function LabyrinthOfTheAncients:IsValidPlayer(playerID)
    return playerID ~= nil
        and playerID >= 0
        and PlayerResource:IsValidPlayerID(playerID)
        and PlayerResource:GetPlayer(playerID) ~= nil
end

function LabyrinthOfTheAncients:SendToPlayer(playerID, eventName, payload)
    if not self:IsValidPlayer(playerID) then
        return
    end

    CustomGameEventManager:Send_ServerToPlayer(
        PlayerResource:GetPlayer(playerID),
        eventName,
        payload or {}
    )
end

function LabyrinthOfTheAncients:OnPreviewSelection(event)
    local playerID = event.PlayerID
    local archetype = ARCHETYPES[event.archetype]

    if not self:IsValidPlayer(playerID) or archetype == nil then
        return
    end

    if self.selections[playerID] and self.selections[playerID].confirmed then
        return
    end

    self.selections[playerID] = {
        archetype = event.archetype,
        confirmed = false,
    }
end

function LabyrinthOfTheAncients:OnConfirmSelection(event)
    local playerID = event.PlayerID
    local archetype = ARCHETYPES[event.archetype]

    if not self:IsValidPlayer(playerID) or archetype == nil then
        self:SendToPlayer(playerID, "loa_selection_rejected", {
            message = "That champion is not available.",
        })
        return
    end

    if self.selections[playerID] and self.selections[playerID].confirmed then
        return
    end

    self.selections[playerID] = {
        archetype = event.archetype,
        confirmed = true,
    }

    print("[LOA] Confirmed " .. event.archetype .. " for player " .. tostring(playerID))

    local heroAssigned, assignedHero = self:ApplySelectedHero(playerID, archetype.hero)
    self.selections[playerID].hero_assigned = heroAssigned
    self.selections[playerID].hero_entindex = assignedHero ~= nil and assignedHero:entindex() or nil

    self:SendToPlayer(playerID, "loa_selection_accepted", {
        archetype = event.archetype,
        hero = archetype.hero,
        message = archetype.display_name .. " confirmed",
    })

    local allPlayersReady = self:AllConnectedPlayersReady()
    local published, publishError = pcall(function()
        self:PublishPartyState()
    end)

    if not published then
        print("[LOA] Party state publish failed: " .. tostring(publishError))
    end

    local allHeroesAssigned = self:AllConfirmedPlayersHaveAssignedHeroes()

    if allPlayersReady and allHeroesAssigned then
        print("[LOA] All connected players ready; starting game")
        CustomGameEventManager:Send_ServerToAllClients("loa_party_ready", {})
        GameRules:ForceGameStart()
    elseif allPlayersReady then
        print("[LOA] All players confirmed, but hero assignment is incomplete; game start deferred")
    end
end

function LabyrinthOfTheAncients:ApplySelectedHero(playerID, heroName)
    local player = PlayerResource:GetPlayer(playerID)
    if player == nil then
        print("[LOA] Hero assignment failed for player " .. tostring(playerID) .. ": player handle unavailable")
        return false
    end

    local currentHero = PlayerResource:GetSelectedHeroEntity(playerID) or player:GetAssignedHero()
    if currentHero ~= nil and currentHero:GetUnitName() == heroName then
        print("[LOA] Hero already assigned for player " .. tostring(playerID) .. ": " .. heroName)
        return true, currentHero
    end

    if currentHero == nil then
        local created, createdHeroOrError = pcall(function()
            return CreateHeroForPlayer(heroName, player)
        end)

        if not created then
            print("[LOA] Hero creation failed for player " .. tostring(playerID) .. ": " .. tostring(createdHeroOrError))
            return false
        end

        currentHero = PlayerResource:GetSelectedHeroEntity(playerID)
            or player:GetAssignedHero()
            or createdHeroOrError

        if currentHero ~= nil and currentHero:GetUnitName() == heroName then
            if currentHero:GetPlayerOwnerID() ~= playerID then
                print("[LOA] Hero handoff failed for player " .. tostring(playerID)
                    .. ": created hero has owner " .. tostring(currentHero:GetPlayerOwnerID()))
                return false
            end

            local handedOff, handoffError = pcall(function()
                player:SetAssignedHeroEntity(currentHero)
                currentHero:SetControllableByPlayer(playerID, true)
            end)

            if not handedOff then
                print("[LOA] Hero handoff failed for player " .. tostring(playerID)
                    .. ": " .. tostring(handoffError))
                return false
            end

            local assignedHero = player:GetAssignedHero()
            if assignedHero ~= currentHero then
                print("[LOA] Hero handoff incomplete for player " .. tostring(playerID)
                    .. ": assigned hero does not match created hero")
                return false
            end

            print("[LOA] Created, assigned, and enabled control of " .. heroName
                .. " for player " .. tostring(playerID))
            return true, currentHero
        end

        local createdName = currentHero ~= nil and currentHero:GetUnitName() or "none"
        print("[LOA] Hero creation incomplete for player " .. tostring(playerID)
            .. "; requested " .. heroName .. ", found " .. createdName)
        return false
    end

    local replaced, replacementError = pcall(function()
        return PlayerResource:ReplaceHeroWith(playerID, heroName, 0, 0)
    end)

    if not replaced then
        print("[LOA] Hero assignment failed for player " .. tostring(playerID) .. ": " .. tostring(replacementError))
        return false
    end

    local assignedHero = PlayerResource:GetSelectedHeroEntity(playerID) or player:GetAssignedHero()
    if assignedHero ~= nil and assignedHero:GetUnitName() == heroName then
        print("[LOA] Assigned " .. heroName .. " to player " .. tostring(playerID))
        return true, assignedHero
    end

    local assignedName = assignedHero ~= nil and assignedHero:GetUnitName() or "none"
    print("[LOA] Hero assignment incomplete for player " .. tostring(playerID)
        .. "; requested " .. heroName .. ", found " .. assignedName)
    return false
end

function LabyrinthOfTheAncients:OnGameRulesStateChange()
    -- A zero auto-launch delay does not reliably skip the setup screen on
    -- every build, so force it closed as soon as the setup state is entered.
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        GameRules:FinishCustomGameSetup()
        return
    end

    if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        return
    end

    for playerID, selection in pairs(self.selections) do
        local archetype = ARCHETYPES[selection.archetype]
        if selection.confirmed and archetype ~= nil and self:IsValidPlayer(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            local hero = selection.hero_entindex ~= nil
                and EntIndexToHScript(selection.hero_entindex)
                or nil
            if player ~= nil
                and hero ~= nil
                and not hero:IsNull()
                and hero:GetUnitName() == archetype.hero
                and hero:GetPlayerOwnerID() == playerID
                and player:GetAssignedHero() == hero then
                print("[LOA] Verified existing hero for player " .. tostring(playerID)
                    .. "; duplicate creation prevented")
            else
                print("[LOA] Recorded hero validation failed for player " .. tostring(playerID)
                    .. "; no replacement hero created")
            end
        end
    end
end

function LabyrinthOfTheAncients:GetConnectedPlayerCount()
    local count = 0
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if self:IsValidPlayer(playerID)
            and PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
            count = count + 1
        end
    end
    return count
end

function LabyrinthOfTheAncients:GetReadyPlayerCount()
    local count = 0
    for playerID, selection in pairs(self.selections) do
        if selection.confirmed and self:IsValidPlayer(playerID) then
            count = count + 1
        end
    end
    return count
end

function LabyrinthOfTheAncients:AllConnectedPlayersReady()
    local playerCount = self:GetConnectedPlayerCount()
    return playerCount > 0 and self:GetReadyPlayerCount() >= playerCount
end

function LabyrinthOfTheAncients:AllConfirmedPlayersHaveAssignedHeroes()
    for playerID, selection in pairs(self.selections) do
        if selection.confirmed then
            local archetype = ARCHETYPES[selection.archetype]
            local player = PlayerResource:GetPlayer(playerID)
            local hero = selection.hero_entindex ~= nil
                and EntIndexToHScript(selection.hero_entindex)
                or nil
            if not selection.hero_assigned
                or archetype == nil
                or player == nil
                or hero == nil
                or hero:IsNull()
                or hero:GetUnitName() ~= archetype.hero
                or hero:GetPlayerOwnerID() ~= playerID
                or player:GetAssignedHero() ~= hero then
                return false
            end
        end
    end
    return true
end

function LabyrinthOfTheAncients:PublishPartyState()
    CustomNetTables:SetTableValue("loa_selection", "party", {
        player_count = self:GetConnectedPlayerCount(),
        ready_count = self:GetReadyPlayerCount(),
    })
end
