-- Custom ability kits per playable (base class or ascendancy key). The module
-- returns the kit table so addon_game_mode.lua can hold a local reference; it
-- is also exposed as the global `class_abilities` for debugging/tools. Each
-- playable key maps to a list of ability names granted server-side after spawn
-- by PathOfTheAncients:GrantClassAbilities.
--
-- Registration rules (see docs/CUSTOM_ABILITIES.md):
--   - Each ability must be defined in game/scripts/npc/npc_abilities_custom.txt
--     with BaseClass "ability_lua", AbilityName, and ScriptFile.
--   - The matching Lua class lives in scripts/vscripts/abilities/<name>.lua
--     and must NOT be require()'d from here (ScriptFile loads it on grant).
--   - Keep names prefixed "poa_" so StripDefaultAbilities preserves them.

local CLASS_ABILITIES = {}

class_abilities = CLASS_ABILITIES

return CLASS_ABILITIES