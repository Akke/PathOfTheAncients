(function () {
  "use strict";

  const rootUI = $("#AscendancyTreeRoot");

  const ASCENDANCY_TREE_CONFIG = {
    "ranger": {
        "witch_hunter": {
            "starting_node": {
                "name": "Decimating Strike",
                "description": "Attacks ignore 20% of the targets base armor.",
            },
            "left": {
                "row_1": {
                    "node_1": {
                        "name": "Elemental Infusion",
                        "description": "Grants [Elemental Infusion] Ability — Crossbow Bolts can be infused with Fire, Lightning or Cold, each applying a distinct on-hit effect. Fire: Applies Flammable, stackable damage over time for 15% of the attack for 3s. Lightning: 35% chance to release a lightning arc to chains to 2-3 enemies, dealing 75% of the attack damage. Cold: Applies frost buildup, freezing enemies when fully built up.",
                    }
                },
                "row_2": {
                    "node_1": {
                        "name": "Elemental Cascade",
                        "description": "Fire: Bolts have a 25% chance to explode for 135% of their damage. Lightning: 5% chance to apply shock to enemies, causing them to take 20% increased damage for 4s. Cold: Killing frozen enemies causes them to shatter, dealing damage for 100% of the attack in an area.",
                    },
                    "node_2": {
                        "name": "Emboldened Infusion",
                        "description": "25% increased chance to Shock. 50% increased Flammability Magnitude. 25% increased Freeze Buildup.",
                    }
                },
                "row_3": {
                    "node_1": {
                        "name": "Stripped Defenses",
                        "description": "Elemental damage you inflict reduces the targets resistances to that element by 20% for 5s.",
                    },
                }
            },
            "right": {
                "row_1": {
                    "node_1": {
                        "name": "Witchbane",
                        "description": "Enemies have Maximum Concentration equal to 30% of their Maximum Life. Break enemy Concentration on attacks equal to 100% of Damage Dealt. Enemies regain 10% of Concentration every second if they haven't lost Concentration in the past 5 seconds.",
                    }
                },
                "row_2": {
                    "node_1": {
                        "name": "No Mercy",
                        "description": "Deal up to 40% more Damage to Enemies based on their missing Concentration.",
                    },
                    "node_2": {
                        "name": "Zealous Inquisition",
                        "description": "10% chance for Enemies you Kill to Explode, dealing 100% of their maximum Life as Physical Damage.",
                    }
                },
                "row_3": {
                    "node_1": {
                        "name": "Damage vs Low Life Enemies",
                        "description": "35% increased Damage with attacks against Enemies that have less than 10% remaining health.",
                    },
                }
            },
        }
    }
  }

    function AddPanel(type, parent, id, className, hitTest) {
        const panel = $.CreatePanel(type, parent, id || "");
        if (className)
        className.split(/\s+/).forEach(function (name) {
            panel.AddClass(name);
        });
        if (hitTest === false) panel.hittest = false;
        return panel;
    }

    function CreateNode(nodeData, nodeId, parent, className) {
        const node = AddPanel(
            "Panel",
            parent,
            nodeId,
            className || "Node",
            true,
        );

        const name = AddPanel("Label", node, "", "NodeName", false);
        name.text = nodeData.name;

        const description = AddPanel(
            "Label",
            node,
            "",
            "NodeDescription",
            false,
        );
        description.text = nodeData.description;

        node.SetPanelEvent("onmouseover", function () {
            $.DispatchEvent(
                "DOTAShowTextTooltip",
                node,
                nodeData.description,
            );
        });

        node.SetPanelEvent("onmouseout", function () {
            $.DispatchEvent("DOTAHideTextTooltip", node);
        });

        node.SetPanelEvent("onactivate", function () {
            onNodeClicked(node);
        });

        return node;
    }

    function onNodeClicked(node) {
        if(node.BHasClass("learned")) return;

        node.AddClass("learned");
    }

    function CreateBranch(sideName, sideConfig, parent) {
        const side = AddPanel(
            "Panel",
            parent,
            "TreeSide_" + sideName,
            "TreeSide " + sideName,
            false,
        );

        Object.keys(sideConfig).forEach(function (rowName) {
            const row = AddPanel(
                "Panel",
                side,
                "TreeRow_" + sideName + "_" + rowName,
                "TreeRow",
                false,
            );

            const nodes = sideConfig[rowName];

            Object.keys(nodes).forEach(function (nodeName) {
                CreateNode(
                    nodes[nodeName],
                    "Node_" + sideName + "_" + rowName + "_" + nodeName,
                    row,
                );
            });
        });
    }

    function CreateNodes(baseClass, ascensionClass) {
        if(!ASCENDANCY_TREE_CONFIG[baseClass]) return;
        if(!ASCENDANCY_TREE_CONFIG[baseClass][ascensionClass]) return;

        const treeNodes = $("#TreeNodes");
        treeNodes.RemoveAndDeleteChildren();

        const ascendancy =
            ASCENDANCY_TREE_CONFIG[baseClass][ascensionClass];

        const branches = AddPanel(
            "Panel",
            treeNodes,
            "TreeBranches",
            "TreeBranches",
            false,
        );

        CreateBranch("left", ascendancy.left, branches);
        CreateBranch("right", ascendancy.right, branches);

        CreateNode(
            ascendancy.starting_node,
            "StartingNode",
            treeNodes,
            "Node StartingNode",
        );

        $("#AscendancyTreeTitle").text = "Witch Hunter Ascendancy Tree";
        const innateAbility = $("#AscendancyInnateAbility");
        innateAbility.abilityname = "drow_ranger_marksmanship";

        innateAbility.SetPanelEvent("onmouseover", function () {
            $.DispatchEvent(
                "DOTAShowTextTooltip",
                innateAbility,
                "Witch Hunter Innate — Crossbow attacks take longer to reload but deal 20% increased damage.",
            );
        });

        innateAbility.SetPanelEvent("onmouseout", function () {
            $.DispatchEvent("DOTAHideTextTooltip", innateAbility);
        });

        $("#CloseButton").SetPanelEvent("onactivate", function () {
            CloseAscendancyTree();
        });

        $.Msg("[POA UI - Ascendancy Tree] Nodes created.");
    }

    function CloseAscendancyTree() {
        rootUI.style.visibility = "collapse";
        rootUI.style.opacity = "0";
        rootUI.hittest = false;
        rootUI.hittestchildren = false;
    }

    function OnUIOpen() {
        rootUI.style.visibility = "visible";
        rootUI.style.opacity = "1";
        rootUI.hittest = true;
        rootUI.hittestchildren = true;
    }

    // Called once per player once the game is fully ready after everyone confirmed their picks
    function OnPlayerAscension(data) {
        CreateNodes(data.baseClass, data.ascensionClass);
    }

    GameEvents.Subscribe("poa_ascenscion_tree_open", OnUIOpen);
    GameEvents.Subscribe("poa_ascenscion_tree_player_ascension", OnPlayerAscension);
    $.Msg("[POA UI — Ascendancy Tree] Loaded Ascendancy Tree successfully.");
})();
