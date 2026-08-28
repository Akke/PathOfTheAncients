-- Class innate definitions (per base class). An innate is the signature class
-- identity plus the resource/loop that defines how the class fights - distinct
-- from ability kits (CLASS_ABILITIES, which are bar skills).
--
-- Each entry:
--   key        : stable innate key.
--   name       : display name.
--   resource   : name of the class resource the innate builds/spends.
--   unit       : optional creature name the innate summons (precached on load).
--   skills     : base (base-class-level) skills that drive the innate loop.
--                These are granted as part of the innate, not as a kit.
--   + class-specific tuning consumed by that class's runtime module
--     (innates/<key>.lua).
--
-- Ascendancy innates
-- ------------------
-- An ascendancy REPLACES its base class innate with its own: each ascendancy
-- has a distinct innate identity (e.g. the Druid shifts beast forms instead
-- of summoning the base Manifestation aspect). Ascendancy innates are keyed by
-- the ascendancy key and exposed on the base table as `.ascendancies`.
-- GrantClassInnate prefers the ascendancy innate and falls back to the base
-- class innate when the ascendancy defines none.

local CLASS_INNATES = {}

-- Ascendancy innate data, keyed by ascendancy key. Populated on the branch
-- that implements each ascendancy.
local ASCENDANCY_INNATES = {}

-- Generic base-class entries. Populate each on its implementing branch.
CLASS_INNATES.warrior =         { key = "resolve",     resource = "resolve" }
CLASS_INNATES.ranger =          { key = "precision",   resource = "precision" }
CLASS_INNATES.mage =            { key = "arcane_flow", resource = "flow" }
CLASS_INNATES.mercenary =       { key = "spoils",      resource = "spoils" }
CLASS_INNATES.martial_artist =  { key = "combo",       resource = "combo" }
CLASS_INNATES.performer =       { key = "rhythm",      resource = "rhythm" }

-- Specialist (Manifestation): summons an aspect to fight alongside the hero.
CLASS_INNATES.specialist = {
    key = "manifestation",
    name = "Manifestation",
    resource = "resonance",
    -- The creature the innate summons; precached generically by the framework
    -- (addon_game_mode precache reads innate.unit).
    unit = "npc_dota_poa_specialist_manifestation",
    max_manifestations = 1,
    -- Single innate skill for the Specialist class: Manifest. Other skills are
    -- part of the future base kit, not the innate, so they are NOT granted
    -- here.
    skills = {
        "poa_innate_specialist",
    },
    resonance = {
        -- Resonance is a spent resource: the Specialist builds charge while
        -- fighting together with the manifestation, and spends it to empower
        -- the aspect. Values are deliberately loose tuning numbers to be
        -- adjusted after playtesting.
        max = 40,
        gain_per_second = 4,    -- while fighting together with a live manifestation
        decay_per_second = 6,   -- Severance burn-off after the manifestation dies
        attack_follow_range = 800, -- manifestation mirrors the Specialist's attack target
    },
}

-- ---------------------------------------------------------------------------
-- Ascendancy innates (override the base class innate when the ascendancy
-- defines one). Each key matches the ascendancy key in system:
-- CLASS_ASCENDANCIES / -ascend index.
-- ---------------------------------------------------------------------------

-- Druid: Adaptability (replaces Manifestation). The Druid's own body is the
-- manifestation - beast forms. "Adapt" to the fight: shift between Wolf,
-- Bear, Wyvern. No external unit to spawn; the hero transforms instead.
ASCENDANCY_INNATES.druid = {
    key = "adaptability",
    name = "Adaptability",
    resource = "resonance",
    -- Self-manifestation: the hero IS the aspect. No unit.
    forms = {
        { key = "wolf",   hero = "npc_dota_hero_lycan",          identity = "feral faster assassin" },
        { key = "bear",   hero = "npc_dota_hero_lone_druid",     identity = "durable mauler" },
        { key = "wyvern", hero = "npc_dota_hero_winter_wyvern",  identity = "ranged elemental breath" },
    },
    resonance = {
        -- Adaptability still funnels through Resonance (bond to the form).
        max = 100,
        gain_per_second = 4,
        decay_per_second = 6,
    },
    skills = {
        "poa_innate_specialist_druid",
    },
}

-- Spiritkin: Harmony (new innate). The Spiritkin's manifestation is the
-- self attuned to elements; Harmony is the balance between Storm/Ember/Stone.
ASCENDANCY_INNATES.spiritkin = {
    key = "harmony",
    name = "Harmony",
    resource = "resonance",
    -- Self-manifestation; elemental attunement, no external unit.
    elements = {
        { key = "storm", identity = "speed, chaining, evasion" },
        { key = "ember", identity = "burn, burst, close range" },
        { key = "stone", identity = "durability, control, disruption" },
    },
    resonance = {
        max = 100,
        gain_per_second = 4,
        decay_per_second = 6,
    },
    skills = {
        "poa_innate_specialist_spiritkin",
    },
}

-- Summoner: Convergence (new innate). Summons servants into a single
-- coordinated force - an external manifestation (the summoned constructs).
ASCENDANCY_INNATES.summoner = {
    key = "convergence",
    name = "Convergence",
    resource = "resonance",
    -- External manifestation: a durable construct (placeholder name; define
    -- the actual unit in npc_units_custom.txt and set its real name here).
    unit = "npc_dota_poa_summoner_servant",
    resonance = {
        max = 100,
        gain_per_second = 4,
        decay_per_second = 6,
    },
    skills = {
        "poa_innate_specialist_summoner",
    },
}

-- The engine's require() returns only the FIRST return value, so expose the
-- ascendancy innates on the same table instead of a second return value.
CLASS_INNATES.ascendancies = ASCENDANCY_INNATES

return CLASS_INNATES