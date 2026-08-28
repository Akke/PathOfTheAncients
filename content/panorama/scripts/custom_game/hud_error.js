(function () {
    "use strict";

    GameEvents.Subscribe("CreateIngameErrorMessage", function (data) {
        $.Msg("[POA] CreateIngameErrorMessage received");

        if (!data || typeof data.message !== "string") {
            $.Msg("[POA] Invalid error payload");
            return;
        }

        GameEvents.SendEventClientSide("dota_hud_error_message", {
            splitscreenplayer: 0,
            reason: data.reason || 80,
            message: data.message,
        });
    });

    $.Msg("[POA] Error handler registered");
})();