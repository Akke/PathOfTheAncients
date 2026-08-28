(function () {
    "use strict";

    const rootUI = $("#AscendancyTreeRoot");
    let ASCENDANCY_TREE_CONFIG = undefined;

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
        name.text = nodeData.title;

        const description = AddPanel(
            "Label",
            node,
            "",
            "NodeDescription",
            false,
        );
        description.text = nodeData.description;

        node.AddClass(nodeData.name);

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
            onNodeClicked(node, nodeData.name);
        });

        return node;
    }

    function onNodeClicked(node, nodeName) {
        if(node.BHasClass("learned")) return;

        GameEvents.SendCustomGameEventToServer("poa_ascendancy_node_learn", {
            node: nodeName,
        })
    }

    function CreateBranch(sideName, sideConfig, parent) {
        const side = AddPanel(
            "Panel",
            parent,
            "TreeSide_" + sideName,
            "TreeSide " + sideName,
            false,
        );

        Object.keys(sideConfig)
            .sort((a, b) => Number(a) - Number(b))
            .forEach(function (rowIndex) {
                const row = AddPanel(
                    "Panel",
                    side,
                    "TreeRow_" + sideName + "_" + rowIndex,
                    "TreeRow",
                    false,
                );

                const nodesInRow = sideConfig[rowIndex];

                Object.keys(nodesInRow)
                    .sort((a, b) => Number(a) - Number(b))
                    .forEach(function (nodeIndex) {
                        CreateNode(
                            nodesInRow[nodeIndex],
                            "Node_" + sideName + "_" + rowIndex + "_" + nodeIndex,
                            row,
                        );
                    });
            });
    }

    function CreateNodes(baseClass, ascensionClass) {
        if (!ASCENDANCY_TREE_CONFIG) {
            $.Msg("[POA UI — Ascendancy Tree] Ascendancy config has not loaded yet.");
            return;
        }
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

        $("#AscendancyTreeTitle").text = ascensionClass.replaceAll("_", " ") + " Ascendancy Tree";
        const innateAbility = $("#AscendancyInnateAbility");
        const abilityName = "poa_innate_" + baseClass + "_" + ascensionClass;
        innateAbility.abilityname = abilityName;

        innateAbility.SetPanelEvent("onmouseover", function () {
            $.DispatchEvent(
                "DOTAShowAbilityTooltip",
                abilityName,
            );
        });

        innateAbility.SetPanelEvent("onmouseout", function () {
            $.DispatchEvent("DOTAHideAbilityTooltip", innateAbility);
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

    function OpenAscendancyTree() {
        rootUI.style.visibility = "visible";
        rootUI.style.opacity = "1";
        rootUI.hittest = true;
        rootUI.hittestchildren = true;
    }

    // Called once per player once the game is fully ready after everyone confirmed their picks
    function OnPlayerAscension(data) {
        $("#TreeNodes").AddClass(data.ascensionClass);
        CreateNodes(data.baseClass, data.ascensionClass);
    }

    function OnNodeLearnedSuccess(data) {
        const nodes = $("#TreeNodes").FindChildrenWithClassTraverse(data.node);
        const node = nodes[0];

        if (!node) {
            $.Msg("[POA UI — Ascendancy Tree] Ascendancy node not found: " + data.node);
            return;
        }

        node.AddClass("learned");
    }

    function OnInitialTreeConfigLoad(data) {
        if(!data || !data.config) {
            $.Msg("[POA UI — Ascendancy Tree] Ascension tree config is empty. This should not happen.");
            return;
        }

        ASCENDANCY_TREE_CONFIG = data.config;
        CreateNodes("ranger", "witch_hunter"); // debug purposes
        $.Msg("[POA UI — Ascendancy Tree] Successfully loaded ascendancy tree config.");
    }

    function OnPointsUpdated(data) {
        $("#AscendancyTreeDescription").text = `(${data.points}) Ascendancy Points remaining.`;
    }

    function OnResetAll() {
        const nodes = $("#TreeNodes").FindChildrenWithClassTraverse("Node");
        for(const node of nodes) {
            node.RemoveClass("learned");
        }

        $.Msg("[POA UI — Ascendancy Tree] Reset complete.")
    }

    GameEvents.Subscribe("poa_ascenscion_tree_open", OpenAscendancyTree);
    GameEvents.Subscribe("poa_ascenscion_tree_player_ascension", OnPlayerAscension);
    GameEvents.Subscribe("poa_ascendancy_node_learned_success", OnNodeLearnedSuccess);
    GameEvents.Subscribe("poa_ascenscion_tree_config_send", OnInitialTreeConfigLoad);
    GameEvents.Subscribe("poa_ascenscion_points_updated", OnPointsUpdated);
    GameEvents.Subscribe("poa_ascenscion_reset_all", OnResetAll);
    $.Msg("[POA UI — Ascendancy Tree] Loaded Ascendancy Tree successfully.");
})();
