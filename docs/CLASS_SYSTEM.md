# Class Selection System

The hero picker uses two stages. First, the player chooses a base class, which establishes the class identity and determines the three ascendency options shown next. The player then chooses an ascendency; that ascendency's mapped Dota hero is the playable hero spawned after confirmation. Back navigation returns to the seven base classes and clears the ascendancy choice.

## UI source of truth

`content/panorama/scripts/custom_game/class_definitions.js` is the authoritative client-side catalog for class order, base-class identity, attributes, descriptions, ascendancies, and hero mappings. The Panorama controller generates both the class carousel and ascendancy controls from that catalog; individual class cards are not duplicated in XML. Add, remove, rename, or reorder UI classes and ascendancies in the catalog rather than editing `hero_selection.xml`.

Server-side selection validation must still accept the same ascendancy keys and hero mappings. Dota's Lua runtime cannot directly import a Panorama JavaScript file, so server definitions remain a separate runtime boundary until the catalog is moved to a server-published data format.

| Base class | Identity hero | Ascendancy | Playable hero | Presentation intent |
|---|---|---|---|---|
| Warrior | Mars (`npc_dota_hero_mars`) | Paladin | Omniknight (`npc_dota_hero_omniknight`) | Base |
| Warrior | Mars (`npc_dota_hero_mars`) | Berserker | Wraith King (`npc_dota_hero_skeleton_king`) | Arcana desired |
| Warrior | Mars (`npc_dota_hero_mars`) | Slayer | Spectre (`npc_dota_hero_spectre`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Deadeye | Windranger (`npc_dota_hero_windrunner`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Gunslinger | Muerta (`npc_dota_hero_muerta`) | Base |
| Ranger | Hoodwink (`npc_dota_hero_hoodwink`) | Witch Hunter | Drow Ranger (`npc_dota_hero_drow_ranger`) | Arcana desired |
| Mage | Invoker (`npc_dota_hero_invoker`) | Fire Mage | Lina (`npc_dota_hero_lina`) | Base |
| Mage | Invoker (`npc_dota_hero_invoker`) | Frost Mage | Crystal Maiden (`npc_dota_hero_crystal_maiden`) | Base |
| Mage | Invoker (`npc_dota_hero_invoker`) | Lightning Mage | Zeus (`npc_dota_hero_zuus`) | Base |
| Mercenary | Anti-Mage (`npc_dota_hero_antimage`) | Artillerist | Gyrocopter (`npc_dota_hero_gyrocopter`) | Base |
| Mercenary | Anti-Mage (`npc_dota_hero_antimage`) | Death Blade | Legion Commander (`npc_dota_hero_legion_commander`) | Arcana desired |
| Mercenary | Anti-Mage (`npc_dota_hero_antimage`) | Bloodhound | Bounty Hunter (`npc_dota_hero_bounty_hunter`) | Base |
| Specialist | Arc Warden (`npc_dota_hero_arc_warden`) | Druid | Lone Druid (`npc_dota_hero_lone_druid`) | Base |
| Specialist | Arc Warden (`npc_dota_hero_arc_warden`) | Spiritkin | Void Spirit (`npc_dota_hero_void_spirit`) | Base |
| Specialist | Arc Warden (`npc_dota_hero_arc_warden`) | Summoner | Warlock (`npc_dota_hero_warlock`) | Base |
| Performer | Monkey King (`npc_dota_hero_monkey_king`) | Bard | Largo (`npc_dota_hero_largo`) | Base |
| Performer | Monkey King (`npc_dota_hero_monkey_king`) | Drunkard | Brewmaster (`npc_dota_hero_brewmaster`) | Base |
| Performer | Monkey King (`npc_dota_hero_monkey_king`) | Puppeteer | Ringmaster (`npc_dota_hero_ringmaster`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | Striker | Marci (`npc_dota_hero_marci`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | Glaivier | Phantom Lancer (`npc_dota_hero_phantom_lancer`) | Base |
| Martial Artist | Juggernaut (`npc_dota_hero_juggernaut`) | War Dancer | Axe (`npc_dota_hero_axe`) | Arcana desired |

Arcana / immortal presentation for selected ascendancies is enforced in-game via the hero cosmetics system (not the player's Steam loadout). See [`HERO_COSMETICS.md`](HERO_COSMETICS.md) for DisableWearables, default body slots, and forced looks (Drow Arcana, Voth Domosh, Zeus Arcana, Axe Unleashed).

The current implementation boundary is selection, confirmation, party readiness, assignment/control of the chosen ascendancy hero, and default/forced cosmetics. No class or ascendancy abilities are implemented yet (the Specialist Druid kit was a prototype and was removed). See [`CUSTOM_ABILITIES.md`](CUSTOM_ABILITIES.md) for the ability registration and granting requirements specific to this engine build, and [`GDD.md`](GDD.md) §7 for the Specialist design. Stats, progression, and combat systems are not yet implemented.
