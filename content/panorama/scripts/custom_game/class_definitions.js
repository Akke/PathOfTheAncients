"use strict";

// Authoritative client-side catalog for the class-selection UI. Keep class
// definitions in display order and each ascendencies array sorted by name.
var LOA_CLASS_ORDER = [
    "warrior",
    "mercenary",
    "ranger",
    "performer",
    "mage",
    "martial_artist",
    "specialist"
];

var LOA_CLASS_DEFINITIONS = {
    warrior: { name: "Warrior", base: "Mars", attribute: "STRENGTH", baseHero: "npc_dota_hero_mars", desc: "Frontline masters of steel and fury. Warriors hold the line, shield their allies and break enemy ranks in a single charge.", ascendencies: [
        { key: "berserker", name: "Berserker", hero: "npc_dota_hero_skeleton_king", presentation: "Wraith King • Arcana desired", desc: "An unkillable warlord who feeds on blood and rises again with every fall." },
        { key: "paladin", name: "Paladin", hero: "npc_dota_hero_omniknight", presentation: "Omniknight", desc: "A holy bulwark who mends wounds in the thick of battle and turns aside death itself." },
        { key: "slayer", name: "Slayer", hero: "npc_dota_hero_spectre", presentation: "Spectre", desc: "A spectral huntress who isolates her prey and punishes any who stand alone." }
    ]},

    mercenary: { name: "Mercenary", base: "Anti-Mage", attribute: "STRENGTH / AGILITY", baseHero: "npc_dota_hero_antimage", desc: "Versatile fighters for hire. Mercenaries trade bladework, firepower and trickery — whatever the contract demands.", ascendencies: [
        { key: "artillerist", name: "Artillerist", hero: "npc_dota_hero_gyrocopter", presentation: "Gyrocopter", desc: "An airborne gunner who blankets the field in rockets, flak and seeking missiles." },
        { key: "death_blade", name: "Death Blade", hero: "npc_dota_hero_legion_commander", presentation: "Legion Commander • Arcana desired", desc: "A duel-hungry commander who grows stronger with every clash she wins." },
        { key: "bloodhound", name: "Bloodhound", hero: "npc_dota_hero_bounty_hunter", presentation: "Bounty Hunter", desc: "A relentless tracker who marks valuable prey, strikes from concealment and always collects the contract." }
    ]},

    ranger: { name: "Ranger", base: "Hoodwink", attribute: "AGILITY", baseHero: "npc_dota_hero_hoodwink", desc: "Swift skirmishers and deadly marksmen. Rangers control the battlefield from afar, striking where the enemy is weakest.", ascendencies: [
        { key: "deadeye", name: "Deadeye", hero: "npc_dota_hero_windrunner", presentation: "Windranger", desc: "A precision archer who binds foes together and unleashes relentless volleys." },
        { key: "gunslinger", name: "Gunslinger", hero: "npc_dota_hero_muerta", presentation: "Muerta", desc: "A pistol-wielding duelist whose bullets tear through armor and soul alike." },
        { key: "witch_hunter", name: "Witch Hunter", hero: "npc_dota_hero_drow_ranger", presentation: "Drow Ranger • Arcana desired", desc: "A cold-eyed stalker whose frost-fletched arrows slow the arcane to a crawl." }
    ]},

    performer: { name: "Performer", base: "Monkey King", attribute: "AGILITY / INTELLIGENCE", baseHero: "npc_dota_hero_monkey_king", desc: "Magnetic entertainers who turn revelry, music and spectacle into weapons of misdirection and control.", ascendencies: [
        { key: "bard", name: "Bard", hero: "npc_dota_hero_largo", presentation: "Largo", desc: "A charismatic musician whose rhythm rallies allies and disrupts the enemy's tempo." },
        { key: "drunkard", name: "Drunkard", hero: "npc_dota_hero_brewmaster", presentation: "Brewmaster", desc: "An unpredictable brawler who turns staggering footwork, liquid courage and crushing blows into a chaotic fighting style." },
        { key: "puppeteer", name: "Puppeteer", hero: "npc_dota_hero_ringmaster", presentation: "Ringmaster", desc: "A sinister showman who manipulates the battlefield, trapping foes in deadly acts staged entirely on his terms." }
    ]},

    mage: { name: "Mage", base: "Invoker", attribute: "INTELLIGENCE", baseHero: "npc_dota_hero_invoker", desc: "Wielders of raw arcane force. Mages reshape the fight with fire, frost and storm before their foes can close the distance.", ascendencies: [
        { key: "fire_mage", name: "Fire Mage", hero: "npc_dota_hero_lina", presentation: "Lina", desc: "A storm of living flame that consumes packs of enemies in a blink." },
        { key: "frost_mage", name: "Frost Mage", hero: "npc_dota_hero_crystal_maiden", presentation: "Crystal Maiden", desc: "A winter weaver who freezes the battlefield solid and feeds allies power." },
        { key: "lightning_mage", name: "Lightning Mage", hero: "npc_dota_hero_zuus", presentation: "Zeus", desc: "A thunder god's heir whose bolts arc from foe to foe without mercy." }
    ]},

    martial_artist: { name: "Martial Artist", base: "Juggernaut", attribute: "INTELLIGENCE / STRENGTH", baseHero: "npc_dota_hero_juggernaut", desc: "Disciplined artists of unarmed and weapon combat. Martial Artists turn motion itself into a lethal weapon.", ascendencies: [
        { key: "glaivier", name: "Glaivier", hero: "npc_dota_hero_phantom_lancer", presentation: "Phantom Lancer", desc: "A relentless lancer who overwhelms enemies beneath an army of mirrored warriors." },
        { key: "striker", name: "Striker", hero: "npc_dota_hero_marci", presentation: "Marci", desc: "A loyal fist who vaults between allies and erupts in sudden fury." },
        { key: "war_dancer", name: "War Dancer", hero: "npc_dota_hero_axe", presentation: "Axe • Arcana desired", desc: "A spinning executioner who dares enemies to strike, and pays them back in full." }
    ]},

    specialist: { name: "Specialist", base: "Arc Warden", attribute: "UNIVERSAL", baseHero: "npc_dota_hero_arc_warden", desc: "Practitioners of rare and singular disciplines — shapers of beasts and riders of the spirit planes.", ascendencies: [
        { key: "druid", name: "Druid", hero: "npc_dota_hero_lone_druid", presentation: "Lone Druid", desc: "A beast-bonded wanderer whose spirit companion rends enemies apart." },
        { key: "spiritkin", name: "Spiritkin", hero: "npc_dota_hero_void_spirit", presentation: "Void Spirit", desc: "A rider of the spirit planes, bound to storm, ember and stone." },
        { key: "summoner", name: "Summoner", hero: "npc_dota_hero_warlock", presentation: "Warlock", desc: "A chaos-touched conjurer whose golems and bindings crush all before them." }
    ]}
};
