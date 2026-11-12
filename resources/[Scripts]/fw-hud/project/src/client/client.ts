import { SendUIMessage, exp } from "../shared/utils"
export const FW = exp['fw-core'].GetCoreObject();
export let LoggedIn = false;

import { InitiateStress } from "./handlers/stress";
import './handlers/preferences'
import './handlers/buffs'
import './handlers/vehicle'
import './handlers/binds'
import { InitiateHud } from "./handlers/hud";
import { GetPreferences, LoadPreferences } from "./handlers/preferences";
import { StartCompass } from "./handlers/compass";

import './handlers/minimap'
import { ForceMinimapSync } from "./handlers/minimap";
import { InitiatePlayer } from "./handlers/player";

import './handlers/main'
import './handlers/settings'
import './handlers/safezone'
import './handlers/chat'
import { InitiateChat, ResyncChat } from "./handlers/chat";
import { SyncHudSettings } from "./handlers/settings";
import { ResetSafezone } from "./handlers/safezone";

onNet("FW:Client:OnPlayerLoaded", () => {
    LoggedIn = true;
    InitiateStress();
    InitiateHud();
    InitiatePlayer();    
    SyncHudSettings();           // add

    if (exp['fw-inventory'].HasEnoughOfItem("pdwatch", 1)) {
        StartCompass();
    };
});

onNet("fw-ui:appRestart", (App: string) => {
    if (!LoggedIn || (App != "root" && App != "Hud" && App != "Preferences")) return;
    InitiateHud();
    InitiatePlayer();  
    ResyncChat();
SyncHudSettings();
ResetSafezone();             // add

    ForceMinimapSync();

    const Preferences = GetPreferences()
    SendUIMessage("Preferences", "UpdatePreferences", {Preferences})
});

onNet("FW:Client:OnPlayerUnload", () => {
    LoggedIn = false;
    SendUIMessage("Hud", "SetHudComponents", []);
});

onNet("fw-hud:Client:ShowCash", () => {
    SendUIMessage("Hud", "ShowCash", FW.Functions.GetPlayerData().money.cash);
});

onNet("fw-hud:Client:MoneyChange", (Amount: number, IsPositive: boolean) => {
    SendUIMessage("Hud", "ShowCashChange", {
        Plus: IsPositive,
        Amount: Amount,
        MyCash: FW.Functions.GetPlayerData().money.cash
    });
});

setImmediate(LoadPreferences);