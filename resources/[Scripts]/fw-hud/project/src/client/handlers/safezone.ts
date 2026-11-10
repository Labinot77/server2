// Port of the safezone check in codera-hud client/minimap.lua.
// The radar ring is positioned against the full screen, so a safezone below 1.0 misaligns it.

import { Safezone } from "../../shared/config";
import { SendUIMessage } from "../../shared/utils";
import { LoggedIn } from "../client";

let Shown: boolean | null = null;

setInterval(() => {
    const Warn = Safezone.Show
        && LoggedIn
        && !IsPauseMenuActive()
        && GetSafeZoneSize() < Safezone.Required;

    if (Warn == Shown) return;
    Shown = Warn;
    SendUIMessage("Hud", "SetSafezoneWarning", { Visible: Warn });
}, 1000);

// Called after a UI restart so the (fresh) UI gets the current state again.
export const ResetSafezone = () => {
    Shown = null;
};
