// Port of codera-hud client/settings.lua: the /hudsettings menu, the per-element layout
// (position + scale) and the show/hide toggles. Everything is stored in a KVP.
// Also contains the /cinematic and /devmode commands from client/main.lua, because
// cinematic mode is mapped onto your existing "BlackBars" preference.

import { Config, HudSettingsBrand } from "../../shared/config";
import { RegisterNUICallback, SendUIMessage, SetUIFocus } from "../../shared/utils";
import { FW, LoggedIn } from "../client";
import { ForceMinimapSync } from "./minimap";

const KvpKey = "fw-hud_hudsettings";

interface LayoutEntry { x: number; y: number; scale: number; }

export interface HudSettings {
    layout: {
        player: LayoutEntry;   // health, armor, needs, voice (+ chat)
        status: LayoutEntry;   // stamina / oxygen / engine bars
        weapon: LayoutEntry;   // ammo counter
        vehicle: LayoutEntry;  // speedometer
        compass: LayoutEntry;  // minimap, compass, location, waypoint
    };
    map: { showMinimap: boolean; showHeading: boolean; showLocation: boolean; showWaypoint: boolean; };
    player: { showVoice: boolean; showNeeds: boolean; showArmor: boolean; showStamina: boolean; showAmmo: boolean; };
    vehicle: { unit: string; showGear: boolean; showFuel: boolean; showIcons: boolean; showControls: boolean; };
    general: { opacity: number; snap: boolean; };
}

const Defaults: HudSettings = {
    layout: {
        player:  { x: 0, y: 0, scale: 1 },
        status:  { x: 0, y: 0, scale: 1 },
        weapon:  { x: 0, y: 0, scale: 1 },
        vehicle: { x: 0, y: 0, scale: 1 },
        compass: { x: 0, y: 0, scale: 1 },
    },
    map: { showMinimap: true, showHeading: true, showLocation: true, showWaypoint: true },
    player: { showVoice: true, showNeeds: true, showArmor: true, showStamina: true, showAmmo: true },
    vehicle: { unit: "auto", showGear: true, showFuel: true, showIcons: true, showControls: true },
    general: { opacity: 100, snap: true },
};

const Limits: {[key: string]: [number, number]} = {
    x: [-1, 1],
    y: [-1, 1],
    scale: [0.4, 2.5],
    opacity: [30, 100],
};

const Units = ["auto", "mph", "kmh"];

const Clamp = (Value: number, Min: number, Max: number) => Math.min(Max, Math.max(Min, Value));
const DeepCopy = <T>(Value: T): T => JSON.parse(JSON.stringify(Value));

// Rebuilds `Input` so it has exactly the shape (and valid values) of `Template`.
const Sanitize = (Input: any, Template: any): any => {
    if (typeof Input != "object" || Input == null) Input = {};
    const Out: {[key: string]: any} = {};

    for (const [Key, Default] of Object.entries(Template)) {
        const Value = Input[Key];

        if (typeof Default == "object") {
            Out[Key] = Sanitize(Value, Default);
        } else if (typeof Default == "boolean") {
            Out[Key] = typeof Value == "boolean" ? Value : Default;
        } else if (typeof Default == "number") {
            let Num = Number(Value);
            if (Value == undefined || Num != Num) Num = Default;
            if (Limits[Key]) Num = Clamp(Num, Limits[Key][0], Limits[Key][1]);
            Out[Key] = Num;
        } else if (typeof Default == "string") {
            Out[Key] = Key == "unit" && Units.includes(Value) ? Value : Default;
        };
    };

    return Out;
};

const Load = (): HudSettings => {
    const Raw = GetResourceKvpString(KvpKey);
    if (!Raw || Raw == "") return DeepCopy(Defaults);

    try {
        return Sanitize(JSON.parse(Raw), Defaults);
    } catch (e) {
        return DeepCopy(Defaults);
    };
};

let Settings: HudSettings = Load();
let MenuOpen = false;

const Save = () => SetResourceKvp(KvpKey, JSON.stringify(Settings));

export const GetHudSettings = () => Settings;

export const GetHudSetting = (Group: "map" | "player" | "vehicle" | "general", Key: string, Default: any) => {
    const Section: any = (Settings as any)[Group];
    if (!Section || Section[Key] == undefined) return Default;
    return Section[Key];
};

const PushSettings = () => {
    SendUIMessage("Hud", "SetHudSettings", {
        Settings,
        Brand: HudSettingsBrand,
    });
    emit("fw-hud:Client:OnHudSettingsUpdate", Settings);
};

// Direct preference write. (exports SetPreferenceById has a bug: the `|| "Audio.PhoneVolume"`
// condition is always true, so it calls .toFixed on every value and breaks booleans.)
const SetPreferenceDirect = (Id: string, Value: any) => {
    Config.MyPreferences[Id] = Value;
    SetResourceKvp("fw-hud_preferences", JSON.stringify(Config.MyPreferences));
    emit("fw-hud:Client:OnPreferenceUpdate", Config.MyPreferences);
    SendUIMessage("Preferences", "UpdatePreferences", { Preferences: Config.MyPreferences });
};

// --- Cinematic mode ---------------------------------------------------------
// Your HUD already has black bars (BlackBars.Show + BlackBars.Percentage) and every layer
// hides while they are on, which is exactly what codera's cinematic mode does.

export const ToggleCinematic = () => {
    SetPreferenceDirect("BlackBars.Show", !Config.MyPreferences["BlackBars.Show"]);
};

RegisterCommand("cinematic", ToggleCinematic, false);
onNet("fw-hud:Client:ToggleCinematic", ToggleCinematic);

// --- Developer badge --------------------------------------------------------

let DevMode = false;

const ToggleDevMode = () => {
    DevMode = !DevMode;
    SendUIMessage("Hud", "SetDevMode", { State: DevMode });
};

// restricted = true: only players with the "command.devmode" ACE permission can run it.
RegisterCommand("devmode", ToggleDevMode, true);
onNet("fw-hud:Client:ToggleDevMode", ToggleDevMode);

// Resend everything the UI keeps in memory (called after a UI restart).
export const SyncHudSettings = () => {
    PushSettings();
    SendUIMessage("Hud", "SetDevMode", { State: DevMode });
};

// --- Menu -------------------------------------------------------------------

const OpenMenu = () => {
    if (MenuOpen) return;

    if (!LoggedIn) return FW.Functions.Notify("You are not logged in.", "error");
    if (IsPauseMenuActive()) return;

    MenuOpen = true;
    SetUIFocus(true, true);
    SendUIMessage("Hud", "SettingsOpen", { Settings, Brand: HudSettingsBrand });
};

const CloseMenu = () => {
    if (!MenuOpen) return;

    MenuOpen = false;
    SetUIFocus(false, false);
    SendUIMessage("Hud", "SettingsClose", {});

    // The Escape that closes the menu would otherwise also open the pause menu.
    const ReleaseAt = GetGameTimer() + 300;
    const Tick = setTick(() => {
        DisableControlAction(0, 199, true);
        DisableControlAction(0, 200, true);

        if (GetGameTimer() > ReleaseAt) clearTick(Tick);
    });
};

RegisterCommand("hudsettings", OpenMenu, false);
onNet("fw-hud:Client:OpenSettings", OpenMenu);

RegisterNUICallback("HudSettings/Get", (Data: any, Cb: Function) => {
    Cb({ Settings, Brand: HudSettingsBrand });
});

RegisterNUICallback("HudSettings/Close", (Data: any, Cb: Function) => {
    CloseMenu();
    Cb("Ok");
});

RegisterNUICallback("HudSettings/Save", (Data: any, Cb: Function) => {
    Settings = Sanitize(Data, Defaults);
    Save();

    emit("fw-hud:Client:OnHudSettingsUpdate", Settings);
    Cb("Ok");
});

RegisterNUICallback("HudSettings/Reset", (Data: { Scope?: string }, Cb: Function) => {
    if (Data && Data.Scope == "layout") {
        Settings.layout = DeepCopy(Defaults.layout);
        Save();
    } else {
        Settings = DeepCopy(Defaults);
        Save();
    };

    emit("fw-hud:Client:OnHudSettingsUpdate", Settings);

    Cb({ Settings, Brand: HudSettingsBrand });
});

RegisterNUICallback("HudSettings/Calibrate", (Data: any, Cb: Function) => {
    CloseMenu();
    Cb("Ok");

    ForceMinimapSync(); // the UI draws the map, so "calibrate" just re-syncs it
});

RegisterNUICallback("HudSettings/Cinematic", (Data: any, Cb: Function) => {
    CloseMenu();
    Cb("Ok");
    ToggleCinematic();
});

on("onResourceStop", (Resource: string) => {
    if (Resource != GetCurrentResourceName()) return;
    if (MenuOpen) SetUIFocus(false, false);
});

setImmediate(() => emit("fw-hud:Client:OnHudSettingsUpdate", Settings));
