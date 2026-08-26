-- Runs on the client only; loaded by the engine alongside the server-side
-- addon_game_mode.lua. The client itself attaches the local player's econ
-- loadout (arcana, cosmetics); those item models are not part of the addon's
-- precache manifest and render as "error" quads. The client script VM only
-- exposes Entities:First()/Next() (no FindAllBy*), so walk the entity chain
-- manually and disable rendering on wearables whose model lives under
-- models/items/. Default wearables live under models/heroes/ and keep
-- rendering. Online games are additionally covered server-side by
-- StripEconWearables in addon_game_mode.lua.

local ECON_MODEL_PREFIX = "models/items/"
local THINK_INTERVAL_SECONDS = 0.25

local censusPrinted = false

local function hideEconWearables()
    local hidden = 0
    local seen = 0
    local ok, first = pcall(function() return Entities:First() end)
    if not ok or first == nil then
        return 0
    end

    local entity = first
    while entity ~= nil do
        local nextOk, nextEntity = pcall(function() return Entities:Next(entity) end)
        if not nextOk then nextEntity = nil end

        local classOk, classname = pcall(function() return entity:GetClassname() end)
        if classOk and (classname == "dota_item_wearable" or classname == "additional_wearable") then
            seen = seen + 1
            local modelOk, model = pcall(function() return entity:GetModelName() end)
            if modelOk and type(model) == "string"
                and string.sub(model, 1, #ECON_MODEL_PREFIX) == ECON_MODEL_PREFIX then
                if pcall(function() entity:SetRenderingEnabled(false) end) then
                    hidden = hidden + 1
                end
            end
        end

        entity = nextEntity
    end

    if not censusPrinted then
        censusPrinted = true
        print("[POA] client init: first pass found " .. tostring(seen)
            .. " wearable entities, hid " .. tostring(hidden))
    end
    return hidden
end

local function startThinkLoop()
    local ok, host = pcall(function() return Entities:First() end)
    if not ok or host == nil then
        print("[POA] client init: no entity to anchor wearable-hide think loop")
        return
    end

    host:SetContextThink("POA_HideEconWearables", function()
        hideEconWearables()
        return THINK_INTERVAL_SECONDS
    end, 0.1)
    print("[POA] client init: econ wearable hide loop started")
end

startThinkLoop()
