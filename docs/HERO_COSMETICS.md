# Hero Cosmetics and Default Looks

Custom games do not make player Steam inventory cosmetics *resident* in the
addon resource mount. The client still tries to attach those items, so missing
models render as floating **"error" quads**. This project disables client
wearable attachment and rebuilds each hero's intended look on the server.

## Problem summary

| Symptom | Cause |
|---|---|
| Error quads on the hero | Econ cosmetics attached client-side; models not in addon precache |
| Bald / naked hero after "fixing" errors | `DisableWearables` also skips default body slots |
| Ability mesh stuck on legs/feet (nimbus, ult wings) | Ability FX models incorrectly listed as body wearables |
| Weapon on the ground / held mid-blade | Bone-merge used instead of hand attach, or missing activity modifiers |
| Arcana missing clothing or particles | Full `entity_model` body set without clothing slots / particle_create FX |

## Architecture

```text
Confirm selection
       │
       ▼
CreateHeroForPlayer / ReplaceHeroWith
       │
       ├─ npc_heroes_custom.txt: DisableWearables "1"
       │     → client does not attach Steam loadout
       │
       ├─ ApplyDefaultWearables / ApplyCosmeticOverrides
       │     ├─ optional activity modifiers (dualwield, arcana, ti9, …)
       │     ├─ optional _visual_presets (full body model, particles, weapons)
       │     └─ prop_dynamic pieces from default_wearables.lua
       │
       └─ StripEconWearables loop (online backup for networked wearables)
```

### Why `prop_dynamic` and not `dota_item_wearable`

`DisableWearables` hides **all** `dota_item_wearable` children on the client,
including ones the server creates. `prop_dynamic` still renders and can
bone-merge or parent to attachment points.

### Entity creation API (server)

```lua
Entities:CreateByClassname("prop_dynamic")
-- then either:
wearable:FollowEntity(hero, true)           -- body slots (bone-merge)
-- or:
wearable:SetParent(hero, "attach_attack1")  -- hand / hitloc attach
wearable:SetLocalOrigin(Vector(...))
wearable:SetModel(modelPath)
```

Do **not** call `Spawn()` after `CreateByClassname` (not available / breaks
parenting). Do **not** use `CreateEntityByName` / global `CreateEntity` — they
are nil in this VM.

## Source files

| File | Role |
|---|---|
| `game/scripts/npc/npc_heroes_custom.txt` | `DisableWearables "1"` per hero unit name |
| `game/scripts/vscripts/default_wearables.lua` | Body-slot lists + `_visual_presets` + `_activity_modifiers` |
| `game/scripts/vscripts/precache_cosmetics.lua` | Optional per-**archetype** override map (wins over defaults) |
| `game/scripts/vscripts/addon_game_mode.lua` | Precache, attach, particles, strip, confirm flow |
| `game/scripts/vscripts/addon_game_mode_client.lua` | Client-side hide loop (backup; limited entity API) |

Authoritative hero → unit name mapping for gameplay is still
`ARCHETYPES` in `addon_game_mode.lua` (and the Panorama class catalog for UI).

## Default body slots

`default_wearables.lua` maps `npc_dota_hero_*` → a list of model paths.

Entry forms:

```lua
-- Bone-merge body piece (default)
"models/heroes/spectre/spectre_hat.vmdl",

-- Hand / hitloc parent (weapons, floating props)
{ model = "models/heroes/zeus/zeus_sigil.vmdl", attach = "attach_hitloc", offset = { 0, 0, 80 } },

-- Explicit bone-merge weapon
{ model = "models/items/.../weapon.vmdl", bone_merge = true },
```

### What belongs in the list

Only **default loadout body slots** from Dota's `items_game.txt`
(`prefab` = `default_item`, `used_by_heroes` = that hero).

**Do not attach:**

- Ability / ult meshes (Omni Guardian Angel wings, Zeus nimbus/`zeus_sigil`,
  Gyro Homing Missile / sidegunner, BH shuriken, Brewmaster mug, Ringmaster whip)
- Spirit / summon / true-form models
- Debut, persona export-only, FX-only, lookdev meshes
- Arcana clothing when a `_visual_presets` full body already covers the look
  (unless the arcana still needs separate slots — see Drow)

### Harvesting models

List compiled models from the game VPK directory (paths end in `.vmdl_c`; use
`.vmdl` in Lua):

```bash
# Example helper (paths only):
python3 vpk_list.py "$DOTA/game/dota/pak01_dir.vpk" "models/heroes/<folder>/"
```

Folder names often differ from unit names (`zuus` → `zeus`, `skeleton_king` →
`wraith_king`, `gyrocopter` → `gyro`, `drow_ranger` → `drow`, `largo` → `bard`).

Cross-check against `scripts/items/items_game.txt` inside the same VPK for
`default_item` rows for that hero.

## Arcana / immortal presets

Some ascendancies force a premium look for **all** players (not the player's
Steam loadout). Data lives under `default_wearables.lua`:

```lua
_activity_modifiers = {
    ["npc_dota_hero_legion_commander"] = { "dualwield", "arcana" },
},

_visual_presets = {
    ["npc_dota_hero_drow_ranger"] = {
        model = "models/items/drow/drow_arcana/drow_arcana.vmdl",  -- entity_model
        skin = 0,
        activity_modifiers = { ... },  -- optional; or use _activity_modifiers
        weapons = {
            { model = "...", bone_merge = true },
            { model = "...", attach = "attach_attack1" },
        },
        particles = {
            { path = "particles/econ/...", attach = "follow_origin" },
            { path = "particles/econ/...", attach = "attach_attack1" },
        },
    },
},
```

### Current forced looks

| Ascendancy | Hero | Forced look | Notes |
|---|---|---|---|
| Witch Hunter | Drow | Dread Retribution (Arcana) | Full `entity_model` body + clothing slots + ambient FX |
| Death Blade | Legion Commander | Blades of Voth Domosh (Arcana) | `dualwield` + `arcana`; bone-merge blades; main/offhand particles |
| Lightning Mage | Zeus | Thundergod Arcana | Full body model; chariot + eye particles (not `zeus_sigil`) |
| War Dancer | Axe | Axe Unleashed (TI9 immortal persona) | `axe_bare` body; `ti9` activity; hair/belt + ambients |

### Reading `items_game.txt` asset_modifiers

When adding a new arcana/immortal:

1. Find the item by name / `model_player` in `items_game.txt`.
2. Note:
   - `entity_model` → full body path for `preset.model`
   - `activity` → strings for `AddActivityModifier`
   - `particle_create` → ambient FX paths
   - `model_skin` / `skin`
   - Bundle children for hair/belt/armor slot models
3. Precache is automatic if paths are listed under `_visual_presets` or the
   hero's piece list (see `Precache()` in `addon_game_mode.lua`).

### Per-archetype overrides

`precache_cosmetics.lua` is keyed by **archetype** name (`berserker`,
`witch_hunter`, …), not unit name. If present, that list replaces defaults for
that pick (after confirm). Use for one-off experiments without editing the
global default table.

## Runtime flow (confirm)

On `poa_confirm_selection` success:

1. `ScheduleEconWearableStripping` — removes networked `dota_item_wearable`
   under `models/items/` for ~60s (helps online GC loadouts).
2. If `precache_cosmetics[archetype]` is set → attach those pieces only.
3. Else `ApplyDefaultWearables`:
   - `_activity_modifiers[hero]`
   - `_visual_presets[hero]` (model swap, extra weapons, particles)
   - remaining `default_wearables[hero]` body pieces

## Precache

`Precache()` must list every model/particle you attach, or you get silent
missing meshes / FX. Covered automatically for:

- All `ARCHETYPES` + `PREVIEW_HEROES` units (`PrecacheUnitByNameSync`)
- Every path in `default_wearables` piece lists
- `_visual_presets` models, weapons, and particles
- `precache_cosmetics` override paths

## Debugging

Console log (Dota install):

```text
game/dota/console.log
```

Useful greps:

```bash
grep '\[POA\]' console.log | tail -40
grep nonresident console.log | sort -u
```

Expected on a good confirm:

```text
[POA] Created, assigned, and enabled control of npc_dota_hero_...
[POA] Applied activity modifier '...'   # if any
[POA] Set visual model ...              # if entity_model preset
[POA] Attached N/N default wearables ...
[POA] Spawned particle ...              # if preset particles
[POA] All connected players ready; starting game
```

Attach failures print per-model errors (pcall-wrapped).

### Client script limits

`addon_game_mode_client.lua` only has `Entities:First` / `Next` (no
`FindAllByClassname`). Client hide loops are a weak backup; **server rebuild**
is the real fix. Do not put player-specific fixes in `poa_dev.cfg` — that file
is local launch only and does not ship with the addon.

## Adding a new hero

1. Add `DisableWearables "1"` override in `npc_heroes_custom.txt`.
2. Add `["npc_dota_hero_..."] = { ... }` body pieces in `default_wearables.lua`.
3. If the hero is only a carousel preview, also list it in `PREVIEW_HEROES` in
   `addon_game_mode.lua` so selection scenes precache correctly.
4. Restart Dota (NPC KV + Precache load at map start).

## Adding a new arcana / immortal default

1. Extract asset_modifiers from `items_game.txt` (see above).
2. Add `_visual_presets["npc_dota_hero_..."]` with `model` / `activity_modifiers` /
   `weapons` / `particles` as needed.
3. Put remaining clothing slots on the hero's piece list (Drow-style).
4. Prefer **bone-merge** for dual-wield immortal weapons that ship as one mesh
   plus activity modifiers (LC Voth Domosh). Prefer **full entity_model** when
   the item replaces the whole body (Drow, Zeus, Axe Unleashed).
5. Never bone-merge floating ability props (nimbus, ult wings).

## Related commits

- `554fc65` — team assign so game starts after confirm  
- `ed83934` — initial DisableWearables + prop_dynamic approach (WK)  
- `6196a13` — default wearables for full roster  
- `108253a` — arcana/immortal presets (Drow, LC, Zeus, Axe)

## Related docs

- [`CLASS_SYSTEM.md`](CLASS_SYSTEM.md) — class / ascendancy catalog and hero mappings  
- [`PROJECT_CONVENTIONS.md`](PROJECT_CONVENTIONS.md) — language and tooling conventions  
- [`../README.md`](../README.md) — addon layout and local link setup  
