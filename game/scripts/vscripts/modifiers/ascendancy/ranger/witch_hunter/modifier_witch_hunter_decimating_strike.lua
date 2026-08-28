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