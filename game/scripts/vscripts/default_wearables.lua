-- Default wearable models per hero unit name. Used when a hero's
-- npc_heroes_custom.txt override sets DisableWearables 1, which stops the
-- client attaching both econ cosmetics (error quads in custom games) and the
-- hero's default wearables; addon_game_mode.lua re-attaches these models
-- server-side so the hero keeps its default look. A per-archetype override in
-- precache_cosmetics.lua takes precedence over defaults.
-- Harvest paths for a new hero from the game's pak01 VPK, e.g.:
--   python3 vpk_list.py "<dota>/game/dota/pak01_dir.vpk" "models/heroes/<hero>/"
-- and list every *_c model except the base <hero>.vmdl_c body and non-default
-- variants (arcana/frost/persona props).
return {
    ["npc_dota_hero_skeleton_king"] = {
        "models/heroes/wraith_king/wraith_king_head.vmdl",
        "models/heroes/wraith_king/wraith_king_chest.vmdl",
        "models/heroes/wraith_king/wraith_king_shoulder.vmdl",
        "models/heroes/wraith_king/wraith_king_gauntlet.vmdl",
        "models/heroes/wraith_king/wraith_king_cape.vmdl",
        "models/heroes/wraith_king/wraith_king_weapon.vmdl",
    },
}
