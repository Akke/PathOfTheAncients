# Adding Custom Abilities (fixes required in this engine build)

Everything below was learned the hard way while implementing the Specialist Druid
kit. Follow it exactly or abilities will silently fail to register, fail to cast,
or never appear on the bar. The Druid implementation was removed again in commit
rework, but the infrastructure fixes below are kept in `addon_game_mode.lua` and
must not be removed.

## 1. Ability KV format — registration

In this engine build, a custom ability **must** declare all three of:

```text
"my_ability"
{
	"BaseClass"					"ability_lua"
	"AbilityName"				"my_ability"
	"ScriptFile"				"abilities/my_ability"
	"AbilityBehavior"			"..."
	"AbilityTextureName"		"some_existing_icon"   // optional but recommended
}
```

- `"BaseClass" "ability_lua"` — required. Without a BaseClass the ability is
  silently not registered: `hero:AddAbility()` returns nil, hero spawn logs
  `Cannot create an entity because entity class is NULL -1` once per slot, and the
  slots fall back to the hero's *default* abilities (which `StripDefaultAbilities`
  then removes).
- `"BaseClass" "ability_datadriven"` registers the ability but does **not**
  dispatch events to Lua classes — pressing the button does nothing. Only
  `ability_lua` dispatches `OnSpellStart`/`GetIntrinsicModifierName`/etc. to the
  Lua class. (For data-driven-only abilities use `ability_datadriven` with KV
  `RunScript` blocks.)
- `"AbilityName"` — self-reference; must equal the ability key and the Lua class.
- `"ScriptFile"` — path to the Lua file relative to `scripts/vscripts/`, without
  the `.lua` extension (e.g. `"abilities/my_ability"` → `scripts/vscripts/abilities/my_ability.lua`).
  Missing it logs `Filename (null) of ability my_ability was not found!` and the
  ability has no behavior.

The ability's Lua file must define a global class with the exact ability name:

```lua
LinkLuaModifier("modifier_my_ability", "abilities/my_ability", LUA_MODIFIER_MOTION_NONE)
my_ability = class({})

function my_ability:OnSpellStart() end
function my_ability:GetIntrinsicModifierName()
    return "modifier_my_ability"
end
```

Do **not** also `require("abilities/...")` the ability file from
`addon_game_mode.lua` — `ScriptFile` loads it when the ability is granted and a
second load re-runs `LinkLuaModifier`. Only the shared libraries need requires.

## 2. KV file mechanics

- `game/scripts/npc/npc_abilities_custom.txt` is read at map start; fully restart
  Dota after editing it (like all NPC KV).
- The file must stay pure ASCII with balanced braces and abilities nested directly
  under `DOTAAbilities`. A single structural mistake (even an extra/missing brace
  further down) can make the engine drop the whole section silently. Check with:
  `python3 -c "d=0; [d:=d+1 if c=='{' else d-1 if c=='}' else d for c in open(f,encoding='ascii').read()]; print(d)"`.
- `game/scripts/npc/npc_items_custom.txt` deliberately uses `"DOTAAbilities"` as
  its top-level key in this build (items live in that section). Do not change it.
- Ability icons: set `"AbilityTextureName"`. The fallback icon
  `panorama/images/spellicons/dota_base_ability_png` does **not** exist in this
  install, so abilities without a texture can render as blank buttons.
- The file loading is **not** the failure mode if `loadfile()` sees the file but
  `AddAbility` fails — use the format above.

## 3. Hero ability assignment — grant in Lua, not hero KV

Hero KV ability overrides (`Ability1` … `Ability25` in `npc_heroes_custom.txt`)
are unreliable in this build:

- Ability slots get scrambled (observed: `Ability1` landed in slot 25).
- Granted abilities spawn at level 0.
- Unknown abilities fall back to the hero's default abilities.

Therefore all custom abilities are granted server-side after spawn, keyed by
playable in `CLASS_ABILITIES` in `addon_game_mode.lua` and applied by
`PathOfTheAncients:GrantClassAbilities`:

- Clear the `generic_hidden` placeholders first — `AddAbility` fills the first
  *free* slot, and the strip leaves `generic_hidden` occupying slots 0-5, which
  would push abilities to slots 6+ (outside the visible QWERDF bar).
- `hero:AddAbility(name)`, then `ability:SetLevel(1)` — level-0 abilities may not
  display.
- `StripDefaultAbilities` keeps every ability whose name starts with `poa_`
  (already fixed in `addon_game_mode.lua`). Keep using that prefix.

## 4. Verification

- `PathOfTheAncients:DumpHeroAbilities(hero, label)` logs every slot+level. For
  the bar to show an ability it must sit in slots 0-5 at level >= 1.
- Symptom -> cause:
  - `Cannot create an entity because entity class is NULL -1` at spawn,
    `AddAbility` returns nil -> ability not registered -> check BaseClass/AbilityName.
  - Ability visible but casting does nothing -> wrong BaseClass (`ability_datadriven`
    instead of `ability_lua`) or missing `ScriptFile`.
  - Ability not on bar -> slot >= 6 (placeholders not cleared) or level 0.
- Console log: `<dota install>/game/dota/console.log`.

## 5. Model swaps / shapeshift visuals

- `hero:SetModel(path)` + `hero:SetOriginalModel(path)` (+ `SetModelScale`) and
  `PrecacheModel` the models. `SetOriginalModel` keeps the form across respawns.
- Wearable props (`prop_dynamic`/`dota_item_wearable` children of the hero) do
  **not** respond reliably to `SetRenderingEnabled(false)` — destroy them with
  `RemoveSelf()` (the pattern kept in `addon_game_mode.lua`). Humanoid clothing
  otherwise clips through beast models. Destroying works; hiding does not.
- Verified models in this install: `models/heroes/lycan/lycan_wolf.vmdl`,
  `models/heroes/lone_druid/spirit_bear.vmdl`,
  `models/heroes/winterwyvern/winterwyvern.vmdl`,
  `models/heroes/dragon_knight/dragon_knight_dragon.vmdl`.

## 6. Keep-in-sync checklist

When re-adding class abilities later:

1. Define the ability in `npc_abilities_custom.txt` with
   `ability_lua` + `AbilityName` + `ScriptFile`.
2. Write `scripts/vscripts/abilities/<name>.lua` with the matching class.
3. Add icons via `AbilityTextureName` (existing spellicon name).
4. Register the kit in `CLASS_ABILITIES[playableKey]` (no hero KV changes).
5. Precache any custom particles/models.
6. Restart Dota, `-ascend`, and read the `[POA DIAG] ability dump`.
