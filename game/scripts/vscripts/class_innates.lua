-- Class innate definitions (per base class). An innate is the signature class
-- identity plus the resource/loop that defines how the class fights - distinct
-- from ability kits (CLASS_ABILITIES, which are bar skills).
--
-- Each entry:
--   key        : stable innate key.
--   name       : display name.
--   resource   : name of the class resource the innate builds/spends.
--   skills     : base (base-class-level) skills that drive the innate loop.
--                These are granted as part of the innate, not as a kit.
--   + class-specific tuning consumed by that class's runtime module
--     (innates/<key>.lua).
--
-- This file is the generic scaffold shared by every class. Per-class innate
-- data (skills, resources, tuning) is added on the branch that implements that
-- class; the framework itself stays class-agnostic so each class can be built
-- out without reorganizing this file.

local CLASS_INNATES = {}

-- Generic base-class entries. Populate each on its implementing branch.
CLASS_INNATES.warrior =         { key = "resolve",     resource = "resolve" }
CLASS_INNATES.ranger =          { key = "precision",   resource = "precision" }
CLASS_INNATES.mage =            { key = "arcane_flow", resource = "flow" }
CLASS_INNATES.mercenary =       { key = "spoils",      resource = "spoils" }
CLASS_INNATES.martial_artist =  { key = "combo",       resource = "combo" }
CLASS_INNATES.performer =       { key = "rhythm",      resource = "rhythm" }
CLASS_INNATES.specialist =      { key = "manifestation", resource = "resonance" }

return CLASS_INNATES