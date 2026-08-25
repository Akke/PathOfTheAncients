(function () {
    "use strict";

    var CLASSES = {
        warrior: { card: "WarriorCard", scene: "WarriorScene", select: "WarriorSelect", name: "Warrior", base: "Mars", attribute: "STRENGTH", baseHero: "npc_dota_hero_mars", specialists: [
            { key: "paladin", name: "Paladin", hero: "npc_dota_hero_omniknight", presentation: "Omniknight" },
            { key: "berserker", name: "Berserker", hero: "npc_dota_hero_skeleton_king", presentation: "Wraith King • Arcana desired" },
            { key: "slayer", name: "Slayer", hero: "npc_dota_hero_spectre", presentation: "Spectre" }
        ]},
        ranger: { card: "RangerCard", scene: "RangerScene", select: "RangerSelect", name: "Ranger", base: "Hoodwink", attribute: "AGILITY", baseHero: "npc_dota_hero_hoodwink", specialists: [
            { key: "gunslinger", name: "Gunslinger", hero: "npc_dota_hero_muerta", presentation: "Muerta" },
            { key: "sharpshooter", name: "Sharpshooter", hero: "npc_dota_hero_windrunner", presentation: "Windranger" },
            { key: "witch_hunter", name: "Witch Hunter", hero: "npc_dota_hero_drow_ranger", presentation: "Drow Ranger • Arcana desired" }
        ]},
        mage: { card: "MageCard", scene: "MageScene", select: "MageSelect", name: "Mage", base: "Invoker", attribute: "INTELLIGENCE", baseHero: "npc_dota_hero_invoker", specialists: [
            { key: "fire_mage", name: "Fire Mage", hero: "npc_dota_hero_lina", presentation: "Lina" },
            { key: "frost_mage", name: "Frost Mage", hero: "npc_dota_hero_crystal_maiden", presentation: "Crystal Maiden" },
            { key: "lightning_mage", name: "Lightning Mage", hero: "npc_dota_hero_zuus", presentation: "Zeus" }
        ]},
        mercenary: { card: "MercenaryCard", scene: "MercenaryScene", select: "MercenarySelect", name: "Mercenary", base: "Legion Commander", attribute: "STRENGTH / AGILITY", baseHero: "npc_dota_hero_legion_commander", specialists: [
            { key: "death_blade", name: "Death Blade", hero: "npc_dota_hero_antimage", presentation: "Anti-Mage • Persona desired" },
            { key: "artillerist", name: "Artillerist", hero: "npc_dota_hero_gyrocopter", presentation: "Gyrocopter" },
            { key: "trickster", name: "Trickster", hero: "npc_dota_hero_monkey_king", presentation: "Monkey King" }
        ]},
        druid: { card: "DruidCard", scene: "DruidScene", select: "DruidSelect", name: "Druid", base: "Nature's Prophet", attribute: "INTELLIGENCE / STRENGTH", baseHero: "npc_dota_hero_furion", specialists: [
            { key: "wolf", name: "Wolf", hero: "npc_dota_hero_lycan", presentation: "Lycan" },
            { key: "bear", name: "Bear", hero: "npc_dota_hero_lone_druid", presentation: "Lone Druid" },
            { key: "dragon", name: "Dragon", hero: "npc_dota_hero_dragon_knight", presentation: "Dragon Knight" }
        ]},
        martial_artist: { card: "MartialArtistCard", scene: "MartialArtistScene", select: "MartialArtistSelect", name: "Martial Artist", base: "Juggernaut", attribute: "AGILITY / INTELLIGENCE", baseHero: "npc_dota_hero_juggernaut", specialists: [
            { key: "striker", name: "Striker", hero: "npc_dota_hero_marci", presentation: "Marci" },
            { key: "glavier", name: "Glavier", hero: "npc_dota_hero_void_spirit", presentation: "Void Spirit" },
            { key: "war_dancer", name: "War Dancer", hero: "npc_dota_hero_axe", presentation: "Axe • Arcana desired" }
        ]},
        spiritkin: { card: "SpiritkinCard", scene: "SpiritkinScene", select: "SpiritkinSelect", name: "Spiritkin", base: "Void Spirit", attribute: "UNIVERSAL", baseHero: "npc_dota_hero_void_spirit", specialists: [
            { key: "storm", name: "Storm", hero: "npc_dota_hero_storm_spirit", presentation: "Storm Spirit" },
            { key: "ember", name: "Ember", hero: "npc_dota_hero_ember_spirit", presentation: "Ember Spirit" },
            { key: "earth", name: "Earth", hero: "npc_dota_hero_earth_spirit", presentation: "Earth Spirit" }
        ]}
    };

    var selectedClass = null;
    var selectedSpecialist = null;
    var confirmed = false;
    var classOrder = ["warrior", "ranger", "mage", "mercenary", "druid", "martial_artist", "spiritkin"];
    var focusIndex = 0;
    var carouselPositions = (function () {
        var ringScales = [1, 0.8, 0.7, 0.6];
        var cardWidth = 250;
        var overlapRatio = 0.10;
        var positions = [0];
        for (var d = 1; d < ringScales.length; d++) {
            var inner = cardWidth * ringScales[d - 1];
            var outer = cardWidth * ringScales[d];
            positions.push(positions[d - 1] + (inner + outer) / 2 - overlapRatio * outer);
        }
        return positions;
    })();
    var classPreviewRequest = 0;
    var specPreviewRequest = 0;

    function OffsetFromFocus(index) {
        var count = classOrder.length;
        var offset = ((index - focusIndex) % count + count) % count;
        if (offset > count / 2) offset -= count;
        return offset;
    }

    function UpdateCarousel(step) {
        var count = classOrder.length;
        focusIndex = ((focusIndex + step) % count + count) % count;
        var track = $("#ClassCarouselTrack");
        var entries = [];
        classOrder.forEach(function (key, index) {
            var offset = OffsetFromFocus(index);
            var distance = Math.abs(offset);
            entries.push({ key: key, distance: distance });
            var slot = $("#Slot_" + key);
            var position = carouselPositions[Math.min(distance, carouselPositions.length - 1)];
            slot.style.transform = "translateX(" + (offset < 0 ? -position : position) + "px)";
            var card = $("#" + CLASSES[key].card);
            card.SetHasClass("Ring1", distance === 1);
            card.SetHasClass("Ring2", distance === 2);
            card.SetHasClass("Ring3", distance >= 3);
        });
        entries.sort(function (a, b) { return b.distance - a.distance; });
        for (var i = entries.length - 1; i >= 0; i--) {
            var slot = $("#Slot_" + entries[i].key);
            var first = track.GetChild(0);
            if (first !== slot) track.MoveChildBefore(slot, first);
        }
        $("#CarouselPageLabel").text = CLASSES[classOrder[focusIndex]].name.toUpperCase();
        $.Msg("[LOA UI] Carousel focus: " + classOrder[focusIndex]);
        QueueVisibleClassPreviews();
    }

    function QueueVisibleClassPreviews() {
        classPreviewRequest += 1;
        var request = classPreviewRequest;
        $.Schedule(0.0, function () {
            if (request !== classPreviewRequest || $("#BaseStage").BHasClass("HiddenStage")) return;
            classOrder.forEach(function (key) {
                var scene = $("#" + CLASSES[key].scene);
                if (scene) scene.SetUnit(CLASSES[key].baseHero, "default", true);
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

    function QueueSpecialistPreviews() {
        specPreviewRequest += 1;
        var request = specPreviewRequest;
        $.Schedule(0.0, function () {
            if (request !== specPreviewRequest || $("#SpecialistStage").BHasClass("HiddenStage")) return;
            CLASSES[selectedClass].specialists.forEach(function (specialist) {
                var scene = $("#SpecScene_" + specialist.key);
                if (scene) {
                    scene.SetUnit(specialist.hero, "default", true);
                    $.Msg("[LOA UI] Lit specialist render: " + specialist.hero);
                }
            });
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
            var card = $.CreatePanel("Panel", holder, "Specialist_" + specialist.key);
            card.AddClass("CardShell"); card.AddClass("SpecialistCard");
            var art = $.CreatePanel("Panel", card, ""); art.AddClass("CardArt"); art.hittest = false;
            var scene = $.CreatePanel("DOTAScenePanel", art, "SpecScene_" + specialist.key);
            scene.AddClass("CardScene"); scene.allowrotation = true;
            var vignette = $.CreatePanel("Panel", art, ""); vignette.AddClass("ArtVignette"); vignette.hittest = false;
            var scrim = $.CreatePanel("Panel", art, ""); scrim.AddClass("ArtScrim"); scrim.hittest = false;
            var glow = $.CreatePanel("Panel", card, ""); glow.AddClass("CardGlow"); glow.hittest = false;
            var select = $.CreatePanel("Button", card, "SpecialistSelect_" + specialist.key);
            select.AddClass("CardSelectArea"); select.hittestchildren = false;
            var info = $.CreatePanel("Panel", select, ""); info.AddClass("CardInfo"); info.hittest = false;
            var rule = $.CreatePanel("Panel", info, ""); rule.AddClass("InfoRule"); rule.hittest = false;
            var emblem = $.CreatePanel("Panel", info, ""); emblem.AddClass("CardEmblem"); emblem.hittest = false;
            var emblemCore = $.CreatePanel("Panel", emblem, ""); emblemCore.AddClass("CardEmblemCore"); emblemCore.hittest = false;
            var title = $.CreatePanel("Label", info, ""); title.AddClass("CardTitle"); title.text = specialist.name.toUpperCase(); title.hittest = false;
            var type = $.CreatePanel("Label", info, ""); type.AddClass("CardType"); type.text = definition.attribute; type.hittest = false;
            var buttonRule = $.CreatePanel("Panel", select, ""); buttonRule.AddClass("ButtonRule"); buttonRule.hittest = false;
            var ctaRow = $.CreatePanel("Panel", select, ""); ctaRow.AddClass("LearnMoreRow"); ctaRow.hittest = false;
            var ctaLeft = $.CreatePanel("Panel", ctaRow, ""); ctaLeft.AddClass("LearnMoreLine"); ctaLeft.AddClass("Left"); ctaLeft.hittest = false;
            var cta = $.CreatePanel("Label", ctaRow, ""); cta.AddClass("LearnMoreLabel"); cta.text = "Learn More"; cta.hittest = false;
            var ctaRight = $.CreatePanel("Panel", ctaRow, ""); ctaRight.AddClass("LearnMoreLine"); ctaRight.AddClass("Right"); ctaRight.hittest = false;
            ["TopLeft", "TopRight", "BottomLeft", "BottomRight"].forEach(function (corner) {
                var mask = $.CreatePanel("Panel", card, ""); mask.AddClass("CornerMask"); mask.AddClass(corner); mask.hittest = false;
            });
            select.SetPanelEvent("onactivate", function () { SelectSpecialist(specialist.key); });
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
        QueueSpecialistPreviews();
        $.Msg("[LOA UI] Selected base class: " + classKey);
    }

    function SelectSpecialist(key) {
        if (confirmed) return;
        var specialist = FindSpecialist(key);
        if (!specialist) return;
        CLASSES[selectedClass].specialists.forEach(function (item) { var panel = $("#Specialist_" + item.key); if (panel) panel.SetHasClass("Selected", item.key === key); });
        selectedSpecialist = key;
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

    classOrder.forEach(function (key) {
        var card = $("#" + CLASSES[key].card);
        var slot = $.CreatePanel("Panel", $("#ClassCarouselTrack"), "Slot_" + key);
        slot.AddClass("CarouselSlot");
        slot.hittest = false;
        card.SetParent(slot);
    });

    Object.keys(CLASSES).forEach(function (key) {
        $("#" + CLASSES[key].select).SetPanelEvent("onactivate", function () {
            if (classOrder[focusIndex] === key) SelectClass(key);
            else UpdateCarousel(classOrder.indexOf(key) - focusIndex);
        });
    });
    $("#CarouselLeft").SetPanelEvent("onactivate", function () { UpdateCarousel(-1); });
    $("#CarouselRight").SetPanelEvent("onactivate", function () { UpdateCarousel(1); });
    $("#BackButton").SetPanelEvent("onactivate", ShowClassStage);
    $("#ConfirmButton").SetPanelEvent("onactivate", ConfirmSelection);
    HideDefaultHeroSelection();
    GameEvents.Subscribe("loa_selection_accepted", OnSelectionAccepted); GameEvents.Subscribe("loa_selection_rejected", OnSelectionRejected); GameEvents.Subscribe("loa_party_ready", OnPartyReady);
    CustomNetTables.SubscribeNetTableListener("loa_selection", function (table, key) { if (table === "loa_selection" && key === "party") UpdatePartyStatus(); });
    UpdatePartyStatus();
    UpdateCarousel(0);
})();
