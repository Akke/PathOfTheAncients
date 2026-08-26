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
    -- Omniknight (no wings — Guardian Angel ult FX)
    ["npc_dota_hero_omniknight"] = {
        "models/heroes/omniknight/bracer.vmdl",
        "models/heroes/omniknight/cape.vmdl",
        "models/heroes/omniknight/hair.vmdl",
        "models/heroes/omniknight/hammer.vmdl",
        "models/heroes/omniknight/head.vmdl",
        "models/heroes/omniknight/shoulder.vmdl",
    },
    -- Spectre
    ["npc_dota_hero_spectre"] = {
        "models/heroes/spectre/spectre_dress.vmdl",
        "models/heroes/spectre/spectre_hat.vmdl",
        "models/heroes/spectre/spectre_weapon.vmdl",
        "models/heroes/spectre/spectre_wings.vmdl",
    },
    -- Gyrocopter (no missile/sidegunner — ability models)
    ["npc_dota_hero_gyrocopter"] = {
        "models/heroes/gyro/gyro_bottles.vmdl",
        "models/heroes/gyro/gyro_goggles.vmdl",
        "models/heroes/gyro/gyro_guns.vmdl",
        "models/heroes/gyro/gyro_head.vmdl",
        "models/heroes/gyro/gyro_propeller.vmdl",
    },
    -- Bounty Hunter (no shuriken — ability prop)
    ["npc_dota_hero_bounty_hunter"] = {
        "models/heroes/bounty_hunter/bounty_hunter_backpack.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_bandana.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_bweapon.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_lweapon.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_pads.vmdl",
        "models/heroes/bounty_hunter/bounty_hunter_rweapon.vmdl",
    },
    -- Legion Commander
    ["npc_dota_hero_legion_commander"] = {
        "models/heroes/legion_commander/legion_commander_arms.vmdl",
        "models/heroes/legion_commander/legion_commander_back.vmdl",
        "models/heroes/legion_commander/legion_commander_head.vmdl",
        "models/heroes/legion_commander/legion_commander_shoulders.vmdl",
        "models/heroes/legion_commander/legion_commander_weapon.vmdl",
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
    -- Drow Ranger
    ["npc_dota_hero_drow_ranger"] = {
        "models/heroes/drow/drow_armor.vmdl",
        "models/heroes/drow/drow_bracer.vmdl",
        "models/heroes/drow/drow_cape.vmdl",
        "models/heroes/drow/drow_haircowl.vmdl",
        "models/heroes/drow/drow_legs.vmdl",
        "models/heroes/drow/drow_quiver.vmdl",
        "models/heroes/drow/drow_weapon.vmdl",
    },
    -- Largo
    ["npc_dota_hero_largo"] = {
        "models/heroes/bard/bard_frog_upperbody.vmdl",
        "models/heroes/bard/bard_frog_lowerbody.vmdl",
        "models/heroes/bard/bard_frog_weapon.vmdl",
    },
    -- Brewmaster (no mug — ability prop)
    ["npc_dota_hero_brewmaster"] = {
        "models/heroes/brewmaster/back.vmdl",
        "models/heroes/brewmaster/barrel.vmdl",
        "models/heroes/brewmaster/bracer.vmdl",
        "models/heroes/brewmaster/shoulder.vmdl",
        "models/heroes/brewmaster/weapon.vmdl",
    },
    -- Ringmaster (no whip/hands — ability props)
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
    -- Zeus (no sigil — ability/nimbus FX)
    ["npc_dota_hero_zuus"] = {
        "models/heroes/zeus/zeus_belt.vmdl",
        "models/heroes/zeus/zeus_bracers.vmdl",
        "models/heroes/zeus/zeus_hair.vmdl",
        "models/heroes/zeus/zeus_vest.vmdl",
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
    -- Axe
    ["npc_dota_hero_axe"] = {
        "models/heroes/axe/axe_armor.vmdl",
        "models/heroes/axe/axe_belt.vmdl",
        "models/heroes/axe/axe_ponytail.vmdl",
        "models/heroes/axe/axe_weapon.vmdl",
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
}
