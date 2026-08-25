(function () {
    "use strict";

    var CLASSES = {
        warrior: { card: "WarriorCard", scene: "WarriorScene", select: "WarriorSelect", name: "Warrior", base: "Mars", baseHero: "npc_dota_hero_mars", specialists: [
            { key: "paladin", name: "Paladin", hero: "npc_dota_hero_omniknight", presentation: "Omniknight" },
            { key: "berserker", name: "Berserker", hero: "npc_dota_hero_skeleton_king", presentation: "Wraith King • Arcana desired" },
            { key: "slayer", name: "Slayer", hero: "npc_dota_hero_spectre", presentation: "Spectre" }
        ]},
        ranger: { card: "RangerCard", scene: "RangerScene", select: "RangerSelect", name: "Ranger", base: "Hoodwink", baseHero: "npc_dota_hero_hoodwink", specialists: [
            { key: "gunslinger", name: "Gunslinger", hero: "npc_dota_hero_muerta", presentation: "Muerta" },
            { key: "sharpshooter", name: "Sharpshooter", hero: "npc_dota_hero_windrunner", presentation: "Windranger" },
            { key: "witch_hunter", name: "Witch Hunter", hero: "npc_dota_hero_drow_ranger", presentation: "Drow Ranger • Arcana desired" }
        ]},
        mage: { card: "MageCard", scene: "MageScene", select: "MageSelect", name: "Mage", base: "Invoker", baseHero: "npc_dota_hero_invoker", specialists: [
            { key: "fire_mage", name: "Fire Mage", hero: "npc_dota_hero_lina", presentation: "Lina" },
            { key: "frost_mage", name: "Frost Mage", hero: "npc_dota_hero_crystal_maiden", presentation: "Crystal Maiden" },
            { key: "lightning_mage", name: "Lightning Mage", hero: "npc_dota_hero_zuus", presentation: "Zeus" }
        ]},
        mercenary: { card: "MercenaryCard", scene: "MercenaryScene", select: "MercenarySelect", name: "Mercenary", base: "Legion Commander", baseHero: "npc_dota_hero_legion_commander", specialists: [
            { key: "death_blade", name: "Death Blade", hero: "npc_dota_hero_antimage", presentation: "Anti-Mage • Persona desired" },
            { key: "artillerist", name: "Artillerist", hero: "npc_dota_hero_gyrocopter", presentation: "Gyrocopter" },
            { key: "trickster", name: "Trickster", hero: "npc_dota_hero_monkey_king", presentation: "Monkey King" }
        ]},
        druid: { card: "DruidCard", scene: "DruidScene", select: "DruidSelect", name: "Druid", base: "Nature's Prophet", baseHero: "npc_dota_hero_furion", specialists: [
            { key: "wolf", name: "Wolf", hero: "npc_dota_hero_lycan", presentation: "Lycan" },
            { key: "bear", name: "Bear", hero: "npc_dota_hero_lone_druid", presentation: "Lone Druid" },
            { key: "dragon", name: "Dragon", hero: "npc_dota_hero_dragon_knight", presentation: "Dragon Knight" }
        ]},
        martial_artist: { card: "MartialArtistCard", scene: "MartialArtistScene", select: "MartialArtistSelect", name: "Martial Artist", base: "Juggernaut", baseHero: "npc_dota_hero_juggernaut", specialists: [
            { key: "striker", name: "Striker", hero: "npc_dota_hero_marci", presentation: "Marci" },
            { key: "glavier", name: "Glavier", hero: "npc_dota_hero_void_spirit", presentation: "Void Spirit" },
            { key: "war_dancer", name: "War Dancer", hero: "npc_dota_hero_axe", presentation: "Axe • Arcana desired" }
        ]}
    };

    var selectedClass = null;
    var selectedSpecialist = null;
    var confirmed = false;
    var classOrder = ["warrior", "ranger", "mage", "mercenary", "druid", "martial_artist"];
    var carouselPage = 0;
    var previewRequest = 0;
    var classPreviewRequest = 0;

    function UpdateCarousel(page) {
        carouselPage = Math.max(0, Math.min(1, page));
        classOrder.forEach(function (key, index) {
            $("#" + CLASSES[key].card).SetHasClass("CarouselHidden", Math.floor(index / 3) !== carouselPage);
        });
        $("#CarouselLeft").enabled = carouselPage > 0;
        $("#CarouselRight").enabled = carouselPage < 1;
        $("#CarouselPageLabel").text = (carouselPage + 1) + " / 2";
        $.Msg("[LOA UI] Class carousel page: " + (carouselPage + 1));
        QueueVisibleClassPreviews();
    }

    function QueueVisibleClassPreviews() {
        classPreviewRequest += 1;
        var request = classPreviewRequest;
        $.Schedule(0.0, function () {
            if (request !== classPreviewRequest || $("#BaseStage").BHasClass("HiddenStage")) return;
            classOrder.forEach(function (key, index) {
                if (Math.floor(index / 3) !== carouselPage) return;
                var definition = CLASSES[key];
                var card = $("#" + definition.card);
                var scene = $("#" + definition.scene);
                if (card && scene && !card.BHasClass("CarouselHidden")) {
                    scene.SetUnit(definition.baseHero, "default", true);
                    $.Msg("[LOA UI] Lit class portrait: " + definition.baseHero);
                }
            });
        });
    }

    function HideDefaultHeroSelection() {
        ["DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS", "DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME", "DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK", "DOTA_DEFAULT_UI_HERO_SELECTION_HEADER", "DOTA_DEFAULT_UI_HERO_SELECTION_GAME_MODE", "DOTA_DEFAULT_UI_HERO_SELECTION_BATTLEPASS", "DOTA_DEFAULT_UI_HERO_SELECTION_STRATEGY"].forEach(function (name) {
            if (DotaDefaultUIElement_t[name] !== undefined) GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t[name], false);
        });
    }

    function FindSpecialist(key) {
        if (!selectedClass) return null;
        var list = CLASSES[selectedClass].specialists;
        for (var i = 0; i < list.length; i++) if (list[i].key === key) return list[i];
        return null;
    }

    function SetPreviewUnit(heroName) {
        var preview = $("#HeroScenePreview");
        if (!preview || !heroName) return;
        previewRequest += 1;
        var request = previewRequest;
        $.Schedule(0.0, function () {
            if (request !== previewRequest || $("#SpecialistStage").BHasClass("HiddenStage")) return;
            preview.SetUnit(heroName, "default", true);
            $.Msg("[LOA UI] Post-layout 3D preview unit: " + heroName);
        });
    }

    function ShowClassStage() {
        if (confirmed) return;
        selectedClass = null;
        selectedSpecialist = null;
        $("#SpecialistCards").RemoveAndDeleteChildren();
        $("#BaseStage").RemoveClass("HiddenStage");
        $("#SpecialistStage").AddClass("HiddenStage");
        $("#ScreenTitle").text = "Choose Your Class";
        $("#ScreenSubtitle").text = "Choose a path, then select one of its three specialists.";
        $("#SelectedHeroName").text = "Choose a class";
        $("#SelectedRole").text = "Select a class to reveal its specialists";
        $("#ReadyStatus").text = "Choose a class to continue";
        $("#ConfirmButton").enabled = false;
        QueueVisibleClassPreviews();
    }

    function SelectClass(classKey) {
        if (confirmed || !CLASSES[classKey]) return;
        selectedClass = classKey;
        selectedSpecialist = null;
        var definition = CLASSES[classKey];
        var holder = $("#SpecialistCards");
        holder.RemoveAndDeleteChildren();
        definition.specialists.forEach(function (specialist) {
            var card = $.CreatePanel("Button", holder, "Specialist_" + specialist.key);
            card.AddClass("HeroCard"); card.AddClass("SpecialistCard"); card.hittestchildren = false;
            var portrait = $.CreatePanel("DOTAHeroImage", card, "");
            portrait.AddClass("SpecialistPortrait");
            portrait.SetAttributeString("heroname", specialist.hero);
            portrait.SetAttributeString("heroimagestyle", "landscape");
            portrait.hittest = false;
            var smoke = $.CreatePanel("Panel", card, ""); smoke.AddClass("SpecialistSmoke"); smoke.hittest = false;
            var topRule = $.CreatePanel("Panel", card, ""); topRule.AddClass("SpecialistTopRule"); topRule.hittest = false;
            var diamond = $.CreatePanel("Label", card, ""); diamond.AddClass("SpecialistDiamond"); diamond.text = "◆"; diamond.hittest = false;
            var mark = $.CreatePanel("Panel", card, ""); mark.AddClass("CardSelectionMark"); mark.hittest = false;
            var check = $.CreatePanel("Label", mark, ""); check.text = "✓"; check.hittest = false;
            var copy = $.CreatePanel("Panel", card, ""); copy.AddClass("HeroCopy"); copy.hittest = false;
            var heroLabel = $.CreatePanel("Label", copy, ""); heroLabel.AddClass("SpecialistHeroLabel"); heroLabel.text = specialist.presentation;
            var title = $.CreatePanel("Label", copy, ""); title.AddClass("HeroName"); title.text = specialist.name;
            var classLabel = $.CreatePanel("Label", copy, ""); classLabel.AddClass("SpecialistClassLabel"); classLabel.text = definition.name + " SPECIALIST";
            var cta = $.CreatePanel("Panel", copy, ""); cta.AddClass("SpecialistCTA"); cta.hittest = false;
            var ctaLabel = $.CreatePanel("Label", cta, ""); ctaLabel.text = "CHOOSE SPECIALIST"; ctaLabel.hittest = false;
            card.SetPanelEvent("onactivate", function () { SelectSpecialist(specialist.key); });
        });
        $("#BaseStage").AddClass("HiddenStage");
        $("#SpecialistStage").RemoveClass("HiddenStage");
        $("#SpecialistHeading").text = definition.name + " Specialists";
        $("#ScreenTitle").text = definition.name;
        $("#ScreenSubtitle").text = "Choose one specialist. This determines your playable hero.";
        $("#SelectedHeroName").text = definition.name;
        $("#SelectedRole").text = "Base identity: " + definition.base;
        $("#ReadyStatus").text = "Choose a specialist to continue";
        $("#ConfirmButton").enabled = false;
        SetPreviewUnit(definition.baseHero);
        $.Msg("[LOA UI] Selected base class: " + classKey);
    }

    function SelectSpecialist(key) {
        if (confirmed) return;
        var specialist = FindSpecialist(key);
        if (!specialist) return;
        CLASSES[selectedClass].specialists.forEach(function (item) { var panel = $("#Specialist_" + item.key); if (panel) panel.SetHasClass("Selected", item.key === key); });
        selectedSpecialist = key;
        SetPreviewUnit(specialist.hero);
        $("#SelectedHeroName").text = CLASSES[selectedClass].name + " — " + specialist.name;
        $("#SelectedRole").text = specialist.presentation;
        $("#ReadyStatus").text = "Ready to confirm";
        $("#ConfirmButton").enabled = true;
        $.Msg("[LOA UI] Selected specialist: " + key + " (" + specialist.hero + ")");
        GameEvents.SendCustomGameEventToServer("loa_preview_selection", { archetype: key });
    }

    function ConfirmSelection() {
        if (confirmed || !selectedSpecialist) return;
        confirmed = true; $("#HeroSelectionRoot").AddClass("IsConfirming"); $("#ConfirmButton").enabled = false;
        $("#ConfirmLabel").text = "LOCKING IN…"; $("#ReadyStatus").text = "Waiting for the server";
        GameEvents.SendCustomGameEventToServer("loa_confirm_selection", { archetype: selectedSpecialist });
    }

    function OnSelectionAccepted(event) { $.Msg("[LOA UI] Selection accepted: " + (event.archetype || "unknown")); confirmed = true; $("#HeroSelectionRoot").RemoveClass("IsConfirming"); $("#HeroSelectionRoot").AddClass("Confirmed"); $("#ConfirmLabel").text = "READY"; $("#ReadyStatus").text = event.message || "Specialist confirmed"; }
    function OnSelectionRejected(event) { confirmed = false; $("#HeroSelectionRoot").RemoveClass("IsConfirming"); $("#ConfirmButton").enabled = selectedSpecialist !== null; $("#ConfirmLabel").text = "CONFIRM SPECIALIST"; $("#ReadyStatus").text = event.message || "Selection could not be confirmed"; }
    function OnPartyReady() { $.Msg("[LOA UI] Party ready; game start requested"); var root = $("#HeroSelectionRoot"), wrapper = root && root.GetParent(), context = $.GetContextPanel(); root.AddClass("PartyReady"); root.hittest = false; root.hittestchildren = false; if (wrapper) { wrapper.hittest = false; wrapper.hittestchildren = false; } context.hittest = false; context.hittestchildren = false; context.style.visibility = "collapse"; $.Msg("[LOA UI] Hero selection context collapsed; gameplay input released"); }
    function UpdatePartyStatus() { var state = CustomNetTables.GetTableValue("loa_selection", "party"); if (!state) { $("#PartyStatus").text = "Choose your class"; return; } $("#PartyStatus").text = (Number(state.ready_count) || 0) + " / " + (Number(state.player_count) || 1) + " players ready"; }

    Object.keys(CLASSES).forEach(function (key) {
        $("#" + CLASSES[key].select).SetPanelEvent("onactivate", function () { SelectClass(key); });
    });
    $("#CarouselLeft").SetPanelEvent("onactivate", function () { UpdateCarousel(carouselPage - 1); });
    $("#CarouselRight").SetPanelEvent("onactivate", function () { UpdateCarousel(carouselPage + 1); });
    $("#BackButton").SetPanelEvent("onactivate", ShowClassStage);
    $("#ConfirmButton").SetPanelEvent("onactivate", ConfirmSelection);
    HideDefaultHeroSelection();
    GameEvents.Subscribe("loa_selection_accepted", OnSelectionAccepted); GameEvents.Subscribe("loa_selection_rejected", OnSelectionRejected); GameEvents.Subscribe("loa_party_ready", OnPartyReady);
    CustomNetTables.SubscribeNetTableListener("loa_selection", function (table, key) { if (table === "loa_selection" && key === "party") UpdatePartyStatus(); });
    UpdatePartyStatus();
    UpdateCarousel(0);
})();
