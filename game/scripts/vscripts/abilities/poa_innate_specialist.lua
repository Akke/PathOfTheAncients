-- Specialist innate skill: Manifest.
-- Summons the Specialist's base manifestation to fight alongside it and kicks
-- the Resonance loop (see innates/specialist_manifestation.lua).
-- Pure shell: all logic lives in the innate module SPECIALIST_INNATE.
--
-- NOTE: do NOT require("innates/specialist_manifestation") here and do NOT add a
-- GetIntrinsicModifierName pointing at a linked modifier. addon_game_mode.lua
-- loads the module at init, so both the require and the intrinsic path would re-run
-- LinkLuaModifier in this engine build and abort with "Script Runtime Error: error
-- in error handling". The Resonance modifier is created explicitly instead, via
-- SPECIALIST_INNATE.EnsureResonanceModifier (no file reload).

poa_innate_specialist = class({})

function poa_innate_specialist:OnSpellStart()
    local caster = self:GetCaster()
    if caster == nil or caster:IsNull() then
        return
    end
    SPECIALIST_INNATE.EnsureResonanceModifier(caster)
    SPECIALIST_INNATE.SpawnManifestation(caster)
end