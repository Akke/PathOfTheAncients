# Class Selection System

The hero picker uses two stages. First, the player chooses a base class, which establishes the class identity and determines the three ascendency options shown next. The player then chooses an ascendency; that ascendency's mapped Dota hero is the playable hero spawned after confirmation. Back navigation returns to the seven base classes and clears the ascendancy choice.

| Base class | Identity hero | Ascendancy | Playable hero | Presentation intent |
|---|---|---|---|---|
| Warrior | Mars (`npc_dota_hero_mars`) | Paladin | Omniknight (`npc_dota_hero_omniknight`) | Base |
| Warrior | Mars (`npc_dota_hero_mars`) | Berserker | Wraith King (`npc_dota_hero_skeleton_king`) | Arcana desired |
| Warrior | Mars (`npc_dota_hero_mars`) | Slayer | Spectre (`npc_dota_hero_spectre`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Deadeye | Windranger (`npc_dota_hero_windrunner`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Witch Hunter | Drow Ranger (`npc_dota_hero_drow_ranger`) | Arcana desired |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Bone Fletcher | Clinkz (`npc_dota_hero_clinkz`) | Base |
| Mage | Invoker (`npc_dota_hero_invoker`) | Fire Mage | Lina (`npc_dota_hero_lina`) | Base |
| Mage | Invoker (`npc_dota_hero_invoker`) | Frost Mage | Crystal Maiden (`npc_dota_hero_crystal_maiden`) | Base |
| Mage | Invoker (`npc_dota_hero_invoker`) | Lightning Mage | Zeus (`npc_dota_hero_zuus`) | Base |
| Mercenary | Anti-Mage (`npc_dota_hero_antimage`) | Death Blade | Legion Commander (`npc_dota_hero_legion_commander`) | Arcana desired |
| Mercenary | Anti-Mage (`npc_dota_hero_antimage`) | Trickster | Monkey King (`npc_dota_hero_monkey_king`) | Base |
| Mercenary | Anti-Mage (`npc_dota_hero_antimage`) | Drunkard | Brewmaster (`npc_dota_hero_brewmaster`) | Base |
| Specialist | Arc Warden (`npc_dota_hero_arc_warden`) | Druid | Lone Druid (`npc_dota_hero_lone_druid`) | Base |
| Specialist | Arc Warden (`npc_dota_hero_arc_warden`) | Spiritkin | Void Spirit (`npc_dota_hero_void_spirit`) | Base |
| Specialist | Arc Warden (`npc_dota_hero_arc_warden`) | Summoner | Warlock (`npc_dota_hero_warlock`) | Base |
| Gunner | Sniper (`npc_dota_hero_sniper`) | Gunslinger | Muerta (`npc_dota_hero_muerta`) | Base |
| Gunner | Sniper (`npc_dota_hero_sniper`) | Artillerist | Gyrocopter (`npc_dota_hero_gyrocopter`) | Base |
| Gunner | Sniper (`npc_dota_hero_sniper`) | Sharpshooter | Sniper (`npc_dota_hero_sniper`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | Striker | Marci (`npc_dota_hero_marci`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | Glavier | Void Spirit (`npc_dota_hero_void_spirit`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | War Dancer | Axe (`npc_dota_hero_axe`) | Arcana desired |

Arcana and persona entries are UI labels describing presentation intent only. The prototype does not force cosmetics or alter a player's Steam loadout.

The current implementation boundary is selection, confirmation, party readiness, and assignment/control of the chosen ascendancy hero. It does not implement class or ascendancy abilities, stats, progression, or combat systems.

This implementation has passed static source validation but is not claimed to be tested in-engine.
