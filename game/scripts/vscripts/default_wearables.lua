-- Default wearable models per hero unit name. Used when a hero's
-- npc_heroes_custom.txt override sets DisableWearables 1, which stops the
-- client attaching both econ cosmetics (error quads in custom games) and the
-- hero's default wearables; addon_game_mode.lua re-attaches these models
-- server-side so the hero keeps its default look. A per-archetype override in
-- precache_cosmetics.lua takes precedence over defaults.
-- Harvest paths for a new hero from the game's pak01 VPK, e.g.:
--   python3 vpk_list.py "<dota>/game/dota/pak01_dir.vpk" "models/heroes/<folder>/"
-- and keep body-slot pieces only (exclude fx, ability, spirit, debut, arcana).
return {
    -- Wraith King
    ["npc_dota_hero_skeleton_king"] = {
        "models/heroes/wraith_king/wraith_king_cape.vmdl",
        "models/heroes/wraith_king/wraith_king_chest.vmdl",
        "models/heroes/wraith_king/wraith_king_gauntlet.vmdl",
        "models/heroes/wraith_king/wraith_king_head.vmdl",
        "models/heroes/wraith_king/wraith_king_shoulder.vmdl",
        "models/heroes/wraith_king/wraith_king_weapon.vmdl",
    },
    -- Omniknight
    ["npc_dota_hero_omniknight"] = {
        "models/heroes/omniknight/bracer.vmdl",
        "models/heroes/omniknight/cape.vmdl",
        "models/heroes/omniknight/hair.vmdl",
        "models/heroes/omniknight/hammer.vmdl",
        "models/heroes/omniknight/head.vmdl",
        "models/heroes/omniknight/shoulder.vmdl",
        -- omniknightwings is Guardian Angel ult FX, not a default body slot
    },
    -- Spectre
    ["npc_dota_hero_spectre"] = {
        "models/heroes/spectre/spectre_dress.vmdl",
        "models/heroes/spectre/spectre_hat.vmdl",
        "models/heroes/spectre/spectre_weapon.vmdl",
        "models/heroes/spectre/spectre_wings.vmdl",
    },
    -- Gyrocopter (no missile/sidegunner — Homing Missile / Flak ability models)
    ["npc_dota_hero_gyrocopter"] = {
        "models/heroes/gyro/gyro_bottles.vmdl",
        "models/heroes/gyro/gyro_goggles.vmdl",
        "models/heroes/gyro/gyro_guns.vmdl",
        "models/heroes/gyro/gyro_head.vmdl",
        "models/heroes/gyro/gyro_propeller.vmdl",
    },
    -- Bounty Hunter (no shuriken — Shuriken Toss, not a default body slot)
    ["npc_dota_hero_bounty_hunter"] = {
        "models/heroes/bounty_hunter/bounty_hunter_backpack.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_bandana.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_bweapon.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_lweapon.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_pads.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_rweapon.vmdl",
    },
    -- Legion Commander body slots; Blades of Voth Domosh handled via _visual_presets.
    ["npc_dota_hero_legion_commander"] = {
        "models/heroes/legion_commander/legion_commander_arms.vmdl",
        "models/heroes/legion_commander/legion_commander_back.vmdl",
        "models/heroes/legion_commander/legion_commander_head.vmdl",
        "models/heroes/legion_commander/legion_commander_shoulders.vmdl",
    },
    -- Windranger
    ["npc_dota_hero_windrunner"] = {
        "models/heroes/windrunner/windrunner_bow.vmdl",
        "models/heroes/windrunner/windrunner_cape.vmdl",
        "models/heroes/windrunner/windrunner_head.vmdl",
        "models/heroes/windrunner/windrunner_quiver.vmdl",
        "models/heroes/windrunner/windrunner_shoulderpads.vmdl",
    },
    -- Muerta
    ["npc_dota_hero_muerta"] = {
        "models/heroes/muerta/muerta_armor.vmdl",
        "models/heroes/muerta/muerta_back.vmdl",
        "models/heroes/muerta/muerta_head.vmdl",
        "models/heroes/muerta/muerta_weapons.vmdl",
    },
    -- Drow Ranger arcana clothing slots (body model comes from _visual_presets).
    ["npc_dota_hero_drow_ranger"] = {
        "models/items/drow/drow_arcana/drow_arcana_arms.vmdl",
        "models/items/drow/drow_arcana/drow_arcana_back.vmdl",
        "models/items/drow/drow_arcana/drow_arcana_head.vmdl",
        "models/items/drow/drow_arcana/drow_arcana_legs.vmdl",
        "models/items/drow/drow_arcana/drow_arcana_quiver.vmdl",
        "models/items/drow/drow_arcana/drow_arcana_shoulder.vmdl",
        { model = "models/items/drow/drow_arcana/drow_arcana_weapon.vmdl", bone_merge = true },
    },
    -- Largo
    ["npc_dota_hero_largo"] = {
        "models/heroes/bard/bard_frog_upperbody.vmdl",
        "models/heroes/bard/bard_frog_lowerbody.vmdl",
        "models/heroes/bard/bard_frog_weapon.vmdl",
    },
    -- Brewmaster (no mug — ability prop, not default loadout)
    ["npc_dota_hero_brewmaster"] = {
        "models/heroes/brewmaster/back.vmdl",
        "models/heroes/brewmaster/barrel.vmdl",
        "models/heroes/brewmaster/bracer.vmdl",
        "models/heroes/brewmaster/shoulder.vmdl",
        "models/heroes/brewmaster/weapon.vmdl",
    },
    -- Ringmaster (no whip/hands — ability props, not default loadout)
    ["npc_dota_hero_ringmaster"] = {
        "models/heroes/ringmaster/ringmaster_armor.vmdl",
        "models/heroes/ringmaster/ringmaster_belt.vmdl",
        "models/heroes/ringmaster/ringmaster_head.vmdl",
        "models/heroes/ringmaster/ringmaster_weapon.vmdl",
    },
    -- Lina
    ["npc_dota_hero_lina"] = {
        "models/heroes/lina/lina_arms.vmdl",
        "models/heroes/lina/lina_belt.vmdl",
        "models/heroes/lina/lina_head.vmdl",
        "models/heroes/lina/lina_neck.vmdl",
    },
    -- Crystal Maiden
    ["npc_dota_hero_crystal_maiden"] = {
        "models/heroes/crystal_maiden/crystal_maiden_cape.vmdl",
        "models/heroes/crystal_maiden/crystal_maiden_cuffs.vmdl",
        "models/heroes/crystal_maiden/crystal_maiden_shoulders.vmdl",
        "models/heroes/crystal_maiden/crystal_maiden_staff.vmdl",
        "models/heroes/crystal_maiden/head_item.vmdl",
    },
    -- Zeus
    -- Zeus arcana clothing (body model + chariot FX from _visual_presets).
    ["npc_dota_hero_zuus"] = {
        "models/heroes/zeus/zeus_hair_arcana.vmdl",
    },
    -- Phantom Lancer
    ["npc_dota_hero_phantom_lancer"] = {
        "models/heroes/phantom_lancer/phantom_lancer_belt.vmdl",
        "models/heroes/phantom_lancer/phantom_lancer_gauntlet.vmdl",
        "models/heroes/phantom_lancer/phantom_lancer_head.vmdl",
        "models/heroes/phantom_lancer/phantom_lancer_shoulderpad.vmdl",
        "models/heroes/phantom_lancer/phantom_lancer_weapon.vmdl",
    },
    -- Marci
    ["npc_dota_hero_marci"] = {
        "models/heroes/marci/marci_back.vmdl",
        "models/heroes/marci/marci_costume.vmdl",
        "models/heroes/marci/marci_head.vmdl",
        "models/heroes/marci/marci_shoulders.vmdl",
    },
    -- Axe Unleashed (TI9 jungle immortal) clothing; body from _visual_presets.
    ["npc_dota_hero_axe"] = {
        "models/items/axe/ti9_jungle_axe/ti9_jungle_axe_hair.vmdl",
        "models/items/axe/ti9_jungle_axe/ti9_jungle_axe_belt.vmdl",
    },
    -- Lone Druid
    ["npc_dota_hero_lone_druid"] = {
        "models/heroes/lone_druid/arms.vmdl",
        "models/heroes/lone_druid/body.vmdl",
        "models/heroes/lone_druid/head.vmdl",
        "models/heroes/lone_druid/shoulder.vmdl",
        "models/heroes/lone_druid/weapon.vmdl",
    },
    -- Void Spirit
    ["npc_dota_hero_void_spirit"] = {
        "models/heroes/void_spirit/void_spirit_armor.vmdl",
        "models/heroes/void_spirit/void_spirit_belt.vmdl",
        "models/heroes/void_spirit/void_spirit_head.vmdl",
        "models/heroes/void_spirit/void_spirit_weapon.vmdl",
    },
    -- Warlock
    ["npc_dota_hero_warlock"] = {
        "models/heroes/warlock/warlock_bag.vmdl",
        "models/heroes/warlock/warlock_bracers.vmdl",
        "models/heroes/warlock/warlock_cape.vmdl",
        "models/heroes/warlock/warlock_lantern.vmdl",
        "models/heroes/warlock/warlock_robe.vmdl",
        "models/heroes/warlock/warlock_shoulder.vmdl",
        "models/heroes/warlock/warlock_staff.vmdl",
    },
    -- Mars
    ["npc_dota_hero_mars"] = {
        "models/heroes/mars/mars_shield.vmdl",
        "models/heroes/mars/mars_spear.vmdl",
        "models/heroes/mars/mars_upper.vmdl",
        "models/heroes/mars/mars_lower.vmdl",
    },
    -- Anti-Mage
    ["npc_dota_hero_antimage"] = {
        "models/heroes/antimage/antimage_arms.vmdl",
        "models/heroes/antimage/antimage_belt.vmdl",
        "models/heroes/antimage/antimage_chest.vmdl",
        "models/heroes/antimage/antimage_head.vmdl",
        "models/heroes/antimage/antimage_offhand_weapon.vmdl",
        "models/heroes/antimage/antimage_weapon.vmdl",
    },
    -- Hoodwink
    ["npc_dota_hero_hoodwink"] = {
        "models/heroes/hoodwink/hoodwink_costume.vmdl",
        "models/heroes/hoodwink/hoodwink_crossbow.vmdl",
        "models/heroes/hoodwink/hoodwink_hood.vmdl",
        "models/heroes/hoodwink/hoodwink_tail.vmdl",
    },
    -- Monkey King
    ["npc_dota_hero_monkey_king"] = {
        "models/heroes/monkey_king/monkey_king_armor.vmdl",
        "models/heroes/monkey_king/monkey_king_base_weapon.vmdl",
        "models/heroes/monkey_king/monkey_king_cape.vmdl",
        "models/heroes/monkey_king/monkey_king_hair.vmdl",
        "models/heroes/monkey_king/monkey_king_shoulders.vmdl",
    },
    -- Invoker
    ["npc_dota_hero_invoker"] = {
        "models/heroes/invoker/invoker_bracer.vmdl",
        "models/heroes/invoker/invoker_cape.vmdl",
        "models/heroes/invoker/invoker_dress.vmdl",
        "models/heroes/invoker/invoker_hair.vmdl",
        "models/heroes/invoker/invoker_head.vmdl",
        "models/heroes/invoker/invoker_shoulder.vmdl",
    },
    -- Juggernaut
    ["npc_dota_hero_juggernaut"] = {
        "models/heroes/juggernaut/jugg_bracers.vmdl",
        "models/heroes/juggernaut/jugg_cape.vmdl",
        "models/heroes/juggernaut/jugg_mask.vmdl",
        "models/heroes/juggernaut/jugg_sword.vmdl",
        "models/heroes/juggernaut/juggernaut_pants.vmdl",
    },
    -- Arc Warden
    ["npc_dota_hero_arc_warden"] = {
        "models/heroes/arc_warden/arc_warden_back.vmdl",
        "models/heroes/arc_warden/arc_warden_bracers.vmdl",
        "models/heroes/arc_warden/arc_warden_shoulder.vmdl",
    },

    -- Hero activity modifiers applied with AddActivityModifier (not wearable models).
    _activity_modifiers = {
        ["npc_dota_hero_legion_commander"] = { "dualwield", "arcana" },
        ["npc_dota_hero_zuus"] = { "arcana" },
        ["npc_dota_hero_axe"] = { "ti9" },
    },

    -- Full arcana / immortal visuals that need model swap, dual-wield, and particles
    -- (from items_game.txt asset_modifiers). Applied by ApplyVisualPreset.
    _visual_presets = {
        ["npc_dota_hero_drow_ranger"] = {
            -- entity_model replacement from the Dread Retribution arcana weapon item
            model = "models/items/drow/drow_arcana/drow_arcana.vmdl",
            skin = 0,
            particles = {
                { path = "particles/econ/items/drow/drow_arcana/drow_arcana_ambient.vpcf", attach = "follow_origin" },
                { path = "particles/econ/items/drow/drow_arcana/drow_arcana_arm_ambient.vpcf", attach = "follow_origin" },
                { path = "particles/econ/items/drow/drow_arcana/drow_arcana_weapon_ambient.vpcf", attach = "attach_attack1" },
                { path = "particles/econ/items/drow/drow_arcana/drow_arcana_ambient_head.vpcf", attach = "attach_hitloc" },
            },
        },
        ["npc_dota_hero_legion_commander"] = {
            activity_modifiers = { "dualwield", "arcana" },
            skin = 1,
            -- Single dual-blade mesh bone-merged; dualwield activity drives two-hand hold.
            weapons = {
                { model = "models/items/legion_commander/demon_sword.vmdl", bone_merge = true },
            },
            particles = {
                { path = "particles/econ/items/legion/legion_weapon_voth_domosh/legion_ambient_arcana.vpcf", attach = "follow_origin" },
                { path = "particles/econ/items/legion/legion_weapon_voth_domosh/legion_arcana_weapon.vpcf", attach = "attach_attack1" },
                { path = "particles/econ/items/legion/legion_weapon_voth_domosh/legion_arcana_weapon_offhand.vpcf", attach = "attach_attack2" },
            },
        },
        ["npc_dota_hero_zuus"] = {
            -- entity_model replacement from Zeus arcana (Thundergod's chariot look)
            model = "models/heroes/zeus/zeus_arcana.vmdl",
            activity_modifiers = { "arcana" },
            particles = {
                { path = "particles/econ/items/zeus/arcana_chariot/zeus_ambient_arcana_eyes.vpcf", attach = "attach_hitloc" },
                { path = "particles/econ/items/zeus/arcana_chariot/zeus_arcana_chariot.vpcf", attach = "follow_origin" },
            },
        },
        ["npc_dota_hero_axe"] = {
            -- Axe Unleashed (TI9 jungle immortal persona)
            model = "models/items/axe/ti9_jungle_axe/axe_bare.vmdl",
            activity_modifiers = { "ti9" },
            particles = {
                { path = "particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_armor_ambient.vpcf", attach = "follow_origin" },
                { path = "particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_head_ambient.vpcf", attach = "attach_hitloc" },
                { path = "particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_belt_ambient.vpcf", attach = "follow_origin" },
            },
        },
    },
}
