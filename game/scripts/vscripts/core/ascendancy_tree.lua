LinkLuaModifier("modifier_witch_hunter_decimating_strike", "modifiers/ascendancy/ranger/witch_hunter/modifier_witch_hunter_decimating_strike.lua", LUA_MODIFIER_MOTION_NONE)

AscendancyTree = AscendancyTree or class({})

local ASCENDANCY_TREE_CONFIG = {
    ranger = {
        witch_hunter = {
            starting_node = {
                name = "decimating_strike",
                title = "Decimating Strike",
                description = "Attacks ignore 20% of the target's base armor.",
                requires = {},
            },

            left = {
                {
                    {
                        name = "elemental_infusion",
                        title = "Elemental Infusion",
                        description = "Grants [Elemental Infusion] Ability — Crossbow Bolts can be infused with Fire, Lightning or Cold, each applying a distinct on-hit effect. Fire: Applies Flammable, stackable damage over time for 15% of the attack for 3s. Lightning: 35% chance to release a lightning arc to chains to 2-3 enemies, dealing 75% of the attack damage. Cold: Applies frost buildup, freezing enemies when fully built up.",
                        requires = { "decimating_strike" },
                    },
                },
                {
                    {
                        name = "elemental_cascade",
                        title = "Elemental Cascade",
                        description = "Fire: Bolts have a 25% chance to explode for 135% of their damage. Lightning: 5% chance to apply shock to enemies, causing them to take 20% increased damage for 4s. Cold: Killing frozen enemies causes them to shatter, dealing damage for 100% of the attack in an area.",
                        requires = { "elemental_infusion" },
                    },
                    {
                        name = "emboldened_infusion",
                        title = "Emboldened Infusion",
                        description = "25% increased chance to Shock. 50% increased Flammability Magnitude. 25% increased Freeze Buildup.",
                        requires = { "elemental_cascade" },
                    },
                },
                {
                    {
                        name = "stripped_defense",
                        title = "Stripped Defenses",
                        description = "Elemental damage you inflict reduces the targets resistances to that element by 20% for 5s.",
                        requires = {
                            "elemental_cascade",
                        },
                    },
                },
            },

            right = {
                {
                    {
                        name = "witchbane",
                        title = "Witchbane",
                        description = "Enemies have Maximum Concentration equal to 30% of their Maximum Life. Break enemy Concentration on attacks equal to 100% of Damage Dealt. Enemies regain 10% of Concentration every second if they haven't lost Concentration in the past 5 seconds.",
                        requires = { "decimating_strike" },
                    },
                },
                {
                    {
                        name = "no_mercy",
                        title = "No Mercy",
                        description = "Deal up to 40% more Damage to Enemies based on their missing Concentration.",
                        requires = { "witchbane" },
                    },
                    {
                        name = "zealous_inquisition",
                        title = "Zealous Inquisition",
                        description = "10% chance for Enemies you Kill to Explode, dealing 100% of their maximum Life as Physical Damage.",
                        requires = { "no_mercy" },
                    },
                },
                {
                    {
                        name = "damage_vs_low_life_enemies",
                        title = "Damage vs Low Life Enemies",
                        description = "35% increased Damage with attacks against Enemies that have less than 10% remaining health.",
                        requires = { "no_mercy" },
                    },
                },
            },
        },
    },
}

local STARTING_POINTS = 2

function AscendancyTree:Init()
    self.points = {} -- table of how many points players has to spend (only if its > 0)

    CustomGameEventManager:RegisterListener(
        "poa_ascendancy_node_learn",
        function(_, event) self:OnNodeLearn(event) end
    )

    local gameMode = GameRules.PathOfTheAncients
    if not gameMode then return end

    self.PathOfTheAncients = gameMode

    Timers:CreateTimer(1, function()
        CustomGameEventManager:Send_ServerToAllClients("poa_ascenscion_tree_config_send", {
        config = ASCENDANCY_TREE_CONFIG
    })
    end)
end

function AscendancyTree:OnNodeLearn(event)
    if not event then return end

    local playerID = event.PlayerID

    if not self.PathOfTheAncients:IsValidPlayer(playerID) then return end

    local player = PlayerResource:GetSelectedHeroEntity(playerID)

    if not player then return end

    local node = event.node

    local baseClass = self.PathOfTheAncients:PlayerGetBaseClass(playerID)
    local ascendancy = self.PathOfTheAncients:PlayerGetAscension(playerID)

    if not baseClass or not ascendancy then return end 

    local modifierKey = "modifier_" .. ascendancy .. "_" .. node

    if player:HasModifier(modifierKey) then return end

    -- Check remaining points
    if not self.points[playerID] then return end

    if self.points[playerID] < 1 then
        self.PathOfTheAncients:DisplayHUDError(
            playerID,
            "Not enough Ascension Points."
        )

        return
    end

    -- Check if they have the previous required node
    local tree = ASCENDANCY_TREE_CONFIG[baseClass]
        and ASCENDANCY_TREE_CONFIG[baseClass][ascendancy]

    if not tree then return end

    local nodeData = FindNode(tree, node)

    if not nodeData then
        print("[POA] Unknown node: " .. tostring(node))
        return
    end

    for _, requiredNode in ipairs(nodeData.requires) do
        local requiredModifier =
            "modifier_" .. ascendancy .. "_" .. requiredNode

        if not player:HasModifier(requiredModifier) then
            local requiredNodeData = FindNode(tree, requiredNode)
            local requiredTitle = requiredNodeData
                and requiredNodeData.title
                or requiredNode

            print("[POA] Missing prerequisite: " .. requiredTitle)

            self.PathOfTheAncients:DisplayHUDError(
                playerID,
                "Previous talent not learned: " .. requiredTitle
            )

            return
        end
    end

    -- Learn node
    player:AddNewModifier(player, nil, modifierKey, {})

    -- Attempting to add non-existent modifiers (e.g. when testing) should be prevented
    if not player:HasModifier(modifierKey) then
        self.PathOfTheAncients:DisplayHUDError(
            playerID,
            "Not implemented yet."
        )
        return
    end

    -- Subtract points
    self:SetPoints(playerID, self.points[playerID] - 1)
    
    -- Send event
    self.PathOfTheAncients:SendToPlayer(playerID, "poa_ascendancy_node_learned_success", {
        baseClass = baseClass,
        ascensionClass = ascendancy,
        node = node,
        points = self.points[playerID]
    })

    print("[POA] Assigned talent with modifier " .. modifierKey .. " to player " .. playerID)
end

function FindNode(tree, nodeName)
    if tree.starting_node.name == nodeName then
        return tree.starting_node
    end

    for _, branch in pairs({ tree.left, tree.right }) do
        for _, row in ipairs(branch) do
            for _, node in ipairs(row) do
                if node.name == nodeName then
                    return node
                end
            end
        end
    end

    return nil
end

function AscendancyTree:OnPlayerAscension(playerID, baseClass, ascensionClass, level)
    self.PathOfTheAncients:SendToPlayer(playerID, "poa_ascenscion_tree_player_ascension", {
        baseClass = baseClass,
        ascensionClass = ascensionClass,
        level = level,
        points = self.points[playerID]
    })

    self:SetPoints(playerID, STARTING_POINTS)
end


function AscendancyTree:SetPoints(playerID, points)
    local amount = tonumber(points)
    if amount == nil then
        self.PathOfTheAncients:DisplayHUDError(playerID, "Invalid arguments.") 
        return 
    end

    self.points[playerID] = amount
    self.PathOfTheAncients:SendToPlayer(playerID, "poa_ascenscion_points_updated", {
        points = self.points[playerID]
    })
end

function AscendancyTree:ResetAll(playerID)
    if not self.PathOfTheAncients:IsValidPlayer(playerID) then return end

    local player = PlayerResource:GetSelectedHeroEntity(playerID)

    if not player then return end

    local ascension = self.PathOfTheAncients:PlayerGetAscension(playerID)

    if not ascension then return end

    local function extract_names(node, results)
        results = results or {}

        if type(node) == "table" then
            if type(node.name) == "string" then
                table.insert(results, node.name)
            end
            for _, value in pairs(node) do
                if type(value) == "table" then
                    extract_names(value, results)
                end
            end
        end

        return results
    end

    local removedCount = self.points[playerID]

    local names = extract_names(ASCENDANCY_TREE_CONFIG)
    for _,n in ipairs(names) do
        local keySearch = "modifier_" .. ascension .. "_" .. n
        local foundMods = player:FindAllModifiersByName(keySearch)

        for _,mod in ipairs(foundMods) do 
            mod:Destroy()
            removedCount = removedCount + 1
        end
    end

    if removedCount == 0 then
        removedCount = STARTING_POINTS
    end

    self.PathOfTheAncients:SendToPlayer(playerID, "poa_ascenscion_reset_all", {})

    -- note that it only gives back points if the modifier actually exists on the player
    self:SetPoints(playerID, removedCount)
end