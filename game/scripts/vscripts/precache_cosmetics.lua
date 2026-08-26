-- Optional per-archetype cosmetic overrides, keyed by archetype name from
-- addon_game_mode.lua. Each value is a list of model paths that get precached
-- and attached to that hero as wearable entities when the archetype is
-- confirmed. These survive econ-wearable stripping. Archetypes absent from
-- this map use their default look (see StripEconWearables in
-- addon_game_mode.lua).
-- Example:
--     bloodhound = {
--         "models/items/bounty_hunter/....vmdl",
--     },
return {
}
