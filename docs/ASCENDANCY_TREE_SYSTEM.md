# Ascendancy Tree System
*System is still work in progress and requires further finetuning once all characters are complete and have been tested.*

The Ascendancy Tree uses data from a table inside `core/ascendancy_tree.lua` and emits it through an event to the client UI, where it builds up the tree using the available data. Actions that are performed by the user are always verified by the server before finalized, e.g. before marking a talent as learned, the server will receive the learn event and then emit a learn success event in return to tell the UI to mark it as learned. **Updating the JS will require a match restart to reload it as data is only sent once at the start of the game and when ascending.**

# Commands
```
-asctree (opens; can only be used after ascending)
-ascreset (resets all + refunds)
-ascpoints <number> (to give points)
```

# Setting up ascendancies
Talent configuration is stored in the `ASCENDANCY_TREE_CONFIG` table.

The following structure must be followed precisely. Adding too many or too few talents in each bracket will cause the UI to break as its designed for this exact amount of talents.

Example:
```lua
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
```

Note: `requires` can take multiple values.

After adding a talent into this table, you need to create the modifier for the talent inside of `modifiers/ascendancy/base class/ascendancy class` and name it `modifier_<ascendancy class>_<talent name>` and link it inside of `ascendancy_tree.lua` (or it won't work). It's very important for all names to match.

Example:
```lua
modifier_witch_hunter_decimating_strike = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

function modifier_witch_hunter_decimating_strike:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE
    }
end

function modifier_witch_hunter_decimating_strike:GetModifierPhysicalArmorBase_Percentage()
    return 80 -- 100 - 20
end
```

It is a good idea to use the ascendancy innate as the ability source of damage if it applies any damage.