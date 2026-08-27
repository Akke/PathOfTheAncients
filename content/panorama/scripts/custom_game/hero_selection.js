(function () {
  "use strict";

  var CLASSES = POA_CLASS_DEFINITIONS;

  var selectedClass = null;
  var previewAscendency = null;
  var confirmed = false;
  var classOrder = POA_CLASS_ORDER.slice();
  var focusIndex = 0;
  var carouselPositions = (function () {
    var ringScales = [1, 0.8, 0.7, 0.6];
    var cardWidth = 250;
    var overlapRatio = 0.1;
    var positions = [0];
    for (var d = 1; d < ringScales.length; d++) {
      var inner = cardWidth * ringScales[d - 1];
      var outer = cardWidth * ringScales[d];
      positions.push(
        positions[d - 1] + (inner + outer) / 2 - overlapRatio * outer,
      );
    }
    return positions;
  })();
  var classPreviewRequest = 0;
  var ascendPreviewRequest = 0;

  function AddPanel(type, parent, id, className, hitTest) {
    var panel = $.CreatePanel(type, parent, id || "");
    if (className)
      className.split(/\s+/).forEach(function (name) {
        panel.AddClass(name);
      });
    if (hitTest === false) panel.hittest = false;
    return panel;
  }

  function BuildClassCard(classKey) {
    var definition = CLASSES[classKey];
    var slot = AddPanel(
      "Panel",
      $("#ClassCarouselTrack"),
      "Slot_" + classKey,
      "CarouselSlot",
      false,
    );
    var card = AddPanel(
      "Panel",
      slot,
      "ClassCard_" + classKey,
      "CardShell BaseCard",
    );
    var art = AddPanel("Panel", card, "", "CardArt");
    var scene = AddPanel(
      "DOTAScenePanel",
      art,
      "ClassScene_" + classKey,
      "CardScene",
    );
    scene.allowrotation = true;
    scene.rotationlimits = "-70 70";
    AddPanel("Panel", art, "", "ArtVignette", false);
    AddPanel("Panel", art, "", "ArtScrim", false);
    AddPanel("Panel", card, "", "CardGlow", false);

    var select = AddPanel(
      "Button",
      card,
      "ClassSelect_" + classKey,
      "CardSelectArea",
    );
    select.hittestchildren = false;
    var info = AddPanel("Panel", select, "", "CardInfo", false);
    AddPanel("Panel", info, "", "InfoRule", false);
    var emblem = AddPanel("Panel", info, "", "CardEmblem", false);
    AddPanel("Panel", emblem, "", "CardEmblemCore", false);
    var title = AddPanel("Label", info, "", "CardTitle", false);
    title.text = definition.name.toUpperCase();
    var type = AddPanel("Label", info, "", "CardType", false);
    type.text = definition.attribute;
    AddPanel("Panel", select, "", "ButtonRule", false);
    var learnRow = AddPanel("Panel", select, "", "LearnMoreRow", false);
    AddPanel("Panel", learnRow, "", "LearnMoreLine Left", false);
    var learnLabel = AddPanel("Label", learnRow, "", "LearnMoreLabel", false);
    learnLabel.text = "Learn More";
    AddPanel("Panel", learnRow, "", "LearnMoreLine Right", false);

    slot.SetPanelEvent("onactivate", function () {
      if (classOrder[focusIndex] === classKey) OpenClassPreview(classKey);
      else UpdateCarousel(classOrder.indexOf(classKey) - focusIndex);
    });
  }

  function BuildClassCarousel() {
    var track = $("#ClassCarouselTrack");
    track.RemoveAndDeleteChildren();
    classOrder.forEach(BuildClassCard);
  }

  function OffsetFromFocus(index) {
    var count = classOrder.length;
    var offset = (((index - focusIndex) % count) + count) % count;
    if (offset > count / 2) offset -= count;
    return offset;
  }

  function UpdateCarousel(step) {
    var count = classOrder.length;
    focusIndex = (((focusIndex + step) % count) + count) % count;
    var track = $("#ClassCarouselTrack");
    var entries = [];
    classOrder.forEach(function (key, index) {
      var offset = OffsetFromFocus(index);
      var distance = Math.abs(offset);
      entries.push({ key: key, distance: distance });
      var slot = $("#Slot_" + key);
      var position =
        carouselPositions[Math.min(distance, carouselPositions.length - 1)];
      slot.style.transform =
        "translateX(" + (offset < 0 ? -position : position) + "px)";
      var card = $("#ClassCard_" + key);
      card.SetHasClass("Ring1", distance === 1);
      card.SetHasClass("Ring2", distance === 2);
      card.SetHasClass("Ring3", distance >= 3);
      card.SetHasClass("Selected", distance === 0);
    });
    entries.sort(function (a, b) {
      return b.distance - a.distance;
    });
    for (var i = entries.length - 1; i >= 0; i--) {
      var slot = $("#Slot_" + entries[i].key);
      var first = track.GetChild(0);
      if (first !== slot) track.MoveChildBefore(slot, first);
    }
    $.Msg("[POA UI] Carousel focus: " + classOrder[focusIndex]);
    QueueVisibleClassPreviews();
  }

  function QueueVisibleClassPreviews() {
    classPreviewRequest += 1;
    var request = classPreviewRequest;
    $.Schedule(0.0, function () {
      if (
        request !== classPreviewRequest ||
        $("#BaseStage").BHasClass("HiddenStage")
      )
        return;
      classOrder.forEach(function (key) {
        var scene = $("#ClassScene_" + key);
        if (scene) scene.SetUnit(CLASSES[key].baseHero, "default", true);
      });
    });
  }

  function HideDefaultHeroSelection() {
    [
      "DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS",
      "DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME",
      "DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK",
      "DOTA_DEFAULT_UI_HERO_SELECTION_HEADER",
      "DOTA_DEFAULT_UI_HERO_SELECTION_GAME_MODE",
      "DOTA_DEFAULT_UI_HERO_SELECTION_BATTLEPASS",
      "DOTA_DEFAULT_UI_HERO_SELECTION_STRATEGY",
    ].forEach(function (name) {
      if (DotaDefaultUIElement_t[name] !== undefined)
        GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t[name], false);
    });
  }

  function FindAscendency(key) {
    if (!selectedClass) return null;
    var list = CLASSES[selectedClass].ascendencies;
    for (var i = 0; i < list.length; i++)
      if (list[i].key === key) return list[i];
    return null;
  }

  function FocusAscendencyPreview(key) {
    var ascendancy = FindAscendency(key);
    if (!ascendancy || !selectedClass) return;
    var definition = CLASSES[selectedClass];
    definition.ascendencies.forEach(function (item) {
      var tab = $("#Tab_" + item.key);
      if (tab) tab.SetHasClass("Selected", item.key === key);
    });
    $("#AscendName").text = ascendancy.name.toUpperCase();
    $("#AscendDesc").text = ascendancy.desc;
    var image = $("#AscendImage");
    if (image)
      image.SetImage(
        "s2r://panorama/images/heroes/" + ascendancy.hero + "_png.vtex",
      );
    ascendPreviewRequest += 1;
    var request = ascendPreviewRequest;
    $.Schedule(0.0, function () {
      if (
        request !== ascendPreviewRequest ||
        $("#AscendencyStage").BHasClass("HiddenStage")
      )
        return;
      var scene = $("#AscendScene");
      if (scene) {
        scene.SetUnit(ascendancy.hero, "default", true);
        $.Msg("[POA UI] Ascendancy preview: " + ascendancy.hero);
      }
    });
    previewAscendency = key;
    // Path summary always reflects the base class being locked in.
    $("#SelectedHeroName").text = definition.name;
    $("#SelectedDesc").text = definition.desc;
    $("#ReadyStatus").text = "Ready to confirm " + definition.name;
    $("#ConfirmButton").enabled = true;
    $("#ConfirmLabel").text = "CONFIRM CHOICE";
  }

  function ShowClassStage() {
    if (confirmed) return;
    selectedClass = null;
    previewAscendency = null;
    $("#AscendencyCards").RemoveAndDeleteChildren();
    $("#BaseStage").RemoveClass("HiddenStage");
    $("#AscendencyStage").AddClass("HiddenStage");
    $("#ScreenTitle").text = "Choose Your Class";
    $("#ScreenSubtitle").text = "Select a class to preview its ascendancies.";
    $("#SelectedHeroName").text = "Choose a class";
    $("#SelectedDesc").text = "Select a class to preview its ascendancies.";
    $("#ReadyStatus").text = "Choose a class to continue";
    $("#ConfirmButton").enabled = false;
    $("#ConfirmLabel").text = "CURRENTLY PICKING...";
    QueueVisibleClassPreviews();
  }

  function OpenClassPreview(classKey) {
    if (confirmed || !CLASSES[classKey]) return;
    selectedClass = classKey;
    previewAscendency = null;
    var definition = CLASSES[classKey];
    var holder = $("#AscendencyCards");
    holder.RemoveAndDeleteChildren();
    var layout = $.CreatePanel("Panel", holder, "AscendLayout");
    layout.AddClass("AscendLayout");
    layout.hittest = false;
    var showcase = $.CreatePanel("Panel", layout, "AscendShowcase");
    showcase.AddClass("AscendShowcase");
    var image = $.CreatePanel("Image", showcase, "AscendImage");
    image.AddClass("AscendImage");
    image.SetScaling("stretch-to-fit-preserve-aspect");
    var shade = $.CreatePanel("Panel", showcase, "");
    shade.AddClass("AscendOverlayShade");
    shade.hittest = false;
    var overlay = $.CreatePanel("Panel", showcase, "");
    overlay.AddClass("AscendOverlay");
    overlay.hittest = false;
    var backdrop = $.CreatePanel("Panel", overlay, "");
    backdrop.AddClass("AscendNameBackdrop");
    backdrop.hittest = false;
    var overlayName = $.CreatePanel("Label", backdrop, "AscendName");
    overlayName.AddClass("AscendNameText");
    overlayName.hittest = false;
    var overlayDesc = $.CreatePanel("Label", backdrop, "AscendDesc"); overlayDesc.AddClass("AscendDescText"); overlayDesc.text = definition.desc; overlayDesc.hittest = false;
    var tabsHolder = $.CreatePanel("Panel", layout, "AscendTabs");
    tabsHolder.AddClass("AscendTabs");
    tabsHolder.hittest = false;
    definition.ascendencies.forEach(function (ascendancy) {
      var tab = $.CreatePanel("Button", tabsHolder, "Tab_" + ascendancy.key);
      tab.AddClass("AscendTab");
      tab.hittestchildren = false;
      var copy = $.CreatePanel("Panel", tab, "");
      copy.AddClass("AscendTabCopy");
      copy.hittest = false;
      var tabName = $.CreatePanel("Label", copy, "");
      tabName.AddClass("AscendTabName");
      tabName.text = ascendancy.name.toUpperCase();
      tabName.hittest = false;
      tab.SetPanelEvent("onactivate", function () { FocusAscendencyPreview(ascendancy.key); });
    });
    var portrait = $.CreatePanel("DOTAScenePanel", tabsHolder, "AscendScene");
    portrait.AddClass("SpecPortrait");
    portrait.allowrotation = true;
    $("#BaseStage").AddClass("HiddenStage");
    $("#AscendencyStage").RemoveClass("HiddenStage");
    $("#AscendencyHeading").text = "Ascendancies";
    $("#ScreenTitle").text = definition.name;
    $("#ScreenSubtitle").text = "Preview future ascendancy paths. Confirm locks in this base class.";
    $("#SelectedHeroName").text = definition.name;
    $("#SelectedDesc").text = definition.desc;
    $("#ReadyStatus").text = "Ready to confirm " + definition.name;
    $("#ConfirmButton").enabled = true;
    $("#ConfirmLabel").text = "CONFIRM CHOICE";
    FocusAscendencyPreview(definition.ascendencies[0].key);
    $.Msg("[POA UI] Opened class preview: " + classKey);
    GameEvents.SendCustomGameEventToServer("poa_preview_selection", { archetype: classKey, class: classKey });
  }

  function ConfirmSelection() {
    if (confirmed || !selectedClass) return;
    confirmed = true;
    $("#HeroSelectionRoot").AddClass("IsConfirming");
    $("#ConfirmButton").enabled = false;
    $("#ConfirmLabel").text = "LOCKING IN…";
    $("#ReadyStatus").text = "Waiting for the server";
    // Confirm the base class only; ascendancy tabs are preview-only.
    GameEvents.SendCustomGameEventToServer("poa_confirm_selection", {
        archetype: selectedClass,
        class: selectedClass,
    });
  }

  function ReturnToClassSelection() {
    if (confirmed) return;
    ShowClassStage();
  }

  function OnSelectionAccepted(event) {
      $.Msg("[POA UI] Selection accepted: " + (event.archetype || "unknown"));
      confirmed = true;
      $("#HeroSelectionRoot").RemoveClass("IsConfirming");
      $("#HeroSelectionRoot").AddClass("Confirmed");
      $("#ConfirmLabel").text = "READY";
      $("#ReadyStatus").text = event.message || "Class confirmed";
  }

  function OnSelectionRejected(event) {
      confirmed = false;
      $("#HeroSelectionRoot").RemoveClass("IsConfirming");
      $("#ConfirmButton").enabled = selectedClass !== null;
      $("#ConfirmLabel").text = "CONFIRM CHOICE";
      $("#ReadyStatus").text = event.message || "Selection could not be confirmed";
  }

  function OnPartyReady() {
    $.Msg("[POA UI] Party ready; game start requested");
    var root = $("#HeroSelectionRoot"),
      wrapper = root && root.GetParent(),
      context = $.GetContextPanel();
    root.AddClass("PartyReady");
    root.hittest = false;
    root.hittestchildren = false;
    if (wrapper) {
      wrapper.hittest = false;
      wrapper.hittestchildren = false;
    }
    context.hittest = false;
    context.hittestchildren = false;
    context.style.visibility = "collapse";
    context.RemoveAndDeleteChildren();
    $.Msg("[POA UI] Hero selection context collapsed; gameplay input released");
  }
  function UpdatePartyStatus() {
      var state = CustomNetTables.GetTableValue("poa_selection", "party");
      if (!state) {
          $("#PartyStatus").text = "Choose your class";
          return;
      }
      $("#PartyStatus").text = (Number(state.ready_count) || 0) + " / " + (Number(state.player_count) || 1) + " players ready";
  }

  BuildClassCarousel();
  $("#CarouselLeft").SetPanelEvent("onactivate", function () {
    UpdateCarousel(-1);
  });
  $("#CarouselRight").SetPanelEvent("onactivate", function () {
    UpdateCarousel(1);
  });
  $("#BackButton").SetPanelEvent("onactivate", ReturnToClassSelection);
  $("#ConfirmButton").SetPanelEvent("onactivate", ConfirmSelection);
  HideDefaultHeroSelection();
  GameEvents.Subscribe("poa_selection_accepted", OnSelectionAccepted);
  GameEvents.Subscribe("poa_selection_rejected", OnSelectionRejected);
  GameEvents.Subscribe("poa_party_ready", OnPartyReady);
  CustomNetTables.SubscribeNetTableListener("poa_selection", function (table, key) {
      if (table === "poa_selection" && key === "party") UpdatePartyStatus();
  });
  UpdatePartyStatus();
  UpdateCarousel(0);
})();
