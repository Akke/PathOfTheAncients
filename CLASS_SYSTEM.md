# Class Selection System

The hero picker uses two stages. First, the player chooses a base class, which establishes the class identity and determines the three specialist options shown next. The player then chooses a specialist; that specialist's mapped Dota hero is the playable hero spawned after confirmation. Back navigation returns to the six base classes and clears the specialist choice.

| Base class | Identity hero | Specialist | Playable hero | Presentation intent |
|---|---|---|---|---|
| Warrior | Mars (`npc_dota_hero_mars`) | Paladin | Omniknight (`npc_dota_hero_omniknight`) | Base |
| Warrior | Mars (`npc_dota_hero_mars`) | Berserker | Wraith King (`npc_dota_hero_skeleton_king`) | Arcana desired |
| Warrior | Mars (`npc_dota_hero_mars`) | Slayer | Spectre (`npc_dota_hero_spectre`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Gunslinger | Muerta (`npc_dota_hero_muerta`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Sharpshooter | Windranger (`npc_dota_hero_windrunner`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Witch Hunter | Drow Ranger (`npc_dota_hero_drow_ranger`) | Arcana desired |
| Mage | Invoker (`npc_dota_hero_invoker`) | Fire Mage | Lina (`npc_dota_hero_lina`) | Base |
| Mage | Invoker (`npc_dota_hero_invoker`) | Frost Mage | Crystal Maiden (`npc_dota_hero_crystal_maiden`) | Base |
| Mage | Invoker (`npc_dota_hero_invoker`) | Lightning Mage | Zeus (`npc_dota_hero_zuus`) | Base |
| Mercenary | Legion Commander (`npc_dota_hero_legion_commander`) | Death Blade | Anti-Mage (`npc_dota_hero_antimage`) | Persona desired |
| Mercenary | Legion Commander (`npc_dota_hero_legion_commander`) | Artillerist | Gyrocopter (`npc_dota_hero_gyrocopter`) | Base |
| Mercenary | Legion Commander (`npc_dota_hero_legion_commander`) | Trickster | Monkey King (`npc_dota_hero_monkey_king`) | Base |
| Druid | Nature's Prophet (`npc_dota_hero_furion`) | Wolf | Lycan (`npc_dota_hero_lycan`) | Base |
| Druid | Nature's Prophet (`npc_dota_hero_furion`) | Bear | Lone Druid (`npc_dota_hero_lone_druid`) | Base |
| Druid | Nature's Prophet (`npc_dota_hero_furion`) | Dragon | Dragon Knight (`npc_dota_hero_dragon_knight`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | Striker | Marci (`npc_dota_hero_marci`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | Glavier | Void Spirit (`npc_dota_hero_void_spirit`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | War Dancer | Axe (`npc_dota_hero_axe`) | Arcana desired |

Arcana and persona entries are UI labels describing presentation intent only. The prototype does not force cosmetics or alter a player's Steam loadout.

The current implementation boundary is selection, confirmation, party readiness, and assignment/control of the chosen specialist hero. It does not implement class or specialist abilities, stats, progression, or combat systems.

This implementation has passed static source validation but is not claimed to be tested in-engine.
