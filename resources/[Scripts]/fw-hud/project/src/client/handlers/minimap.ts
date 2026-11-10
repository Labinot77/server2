import { Config, Minimap } from "../../shared/config";
import { Delay, SendUIMessage } from "../../shared/utils";
import { GetMinimapRadarRect, GetScreenDebugText } from "./screen";
import { GetHudSetting } from "./settings";

          
const StreamedTxd = "circlemap_codera";

// const RadarMaskFile = 'project/src/assets/radar-mask.png';
const RadarMaskName = "round_mask";
const LoadTimeoutMs = 5000;

const DefaultLayout = [
    { Name: "minimap",      AlignX: "L", AlignY: "B", X: 0.0,    Y: -0.047, W: 0.14,  H: 0.188 },
    { Name: "minimap_mask", AlignX: "L", AlignY: "B", X: 0.0,    Y: 0.0,    W: 0.125, H: 0.19 },
    { Name: "minimap_blur", AlignX: "L", AlignY: "B", X: -0.008, Y: -0.008, W: 0.162, H: 0.234 },
];

let MinimapVisible = false;
let MinimapReady = false;
let MinimapLoading = false;
let RuntimeTxd = 0;
let RadarMaskTxd = "";
let RadarLocked = false;
let LayoutGeneration = 0;
let ScreenGeneration = 0;
let BigmapRefreshRunning = false;
let LastSentVisible: boolean | null = null;
let ZoomDistance = Minimap.Zoom;

// Zoom levels
setImmediate(() => {
    SetMapZoomDataLevel(0, 2.75, 0.9, 0.08, 0.0, 0.0);
    SetMapZoomDataLevel(1, 2.8, 0.9, 0.08, 0.0, 0.0);
    SetMapZoomDataLevel(2, 8.0, 0.9, 0.08, 0.0, 0.0);
    SetMapZoomDataLevel(3, 20.0, 0.9, 0.08, 0.0, 0.0);
    SetMapZoomDataLevel(4, 35.0, 0.9, 0.08, 0.0, 0.0);
    SetMapZoomDataLevel(5, 55.0, 0.0, 0.1, 2.0, 1.0);
    SetMapZoomDataLevel(6, 450.0, 0.0, 0.1, 1.0, 1.0);
    SetMapZoomDataLevel(7, 4.5, 0.0, 0.0, 0.0, 0.0);
    SetMapZoomDataLevel(8, 11.0, 0.0, 0.0, 2.0, 3.0);
});

on("fw-hud:Client:OnHudSettingsUpdate", () => UpdateMinimapVisibility());


RegisterCommand("minimapmask", async () => {
    RequestStreamedTextureDict(StreamedTxd, false);
    await Delay(1000);
    console.log(`[fw-hud] ready=${MinimapReady} txdLoaded=${HasStreamedTextureDictLoaded(StreamedTxd)}`);
}, false);

const RadarWanted = () => MinimapVisible && MinimapReady && !Config.MyPreferences["BlackBars.Show"]
    && GetHudSetting("map", "showMinimap", true);

// Single place that decides if the radar + UI ring are visible.
export const UpdateMinimapVisibility = (Force: boolean = false) => {
    const Wanted = RadarWanted();

    // Until the custom radar is ready, fall back to the default radar instead of hiding it.
    const Blackbars = Config.MyPreferences["BlackBars.Show"];
    DisplayRadar(MinimapReady ? Wanted : (MinimapVisible && !Blackbars));

    if (!Force && LastSentVisible == Wanted) return;
    LastSentVisible = Wanted;
    SendUIMessage("Hud", "SetMinimapVisibility", { Visible: Wanted });
};

export const SetMinimapVisible = (Visible: boolean) => {
    MinimapVisible = Visible;
    UpdateMinimapVisibility();
};


const LoadRadarMask = (): boolean => {
    RequestStreamedTextureDict(StreamedTxd, false);
    if (!HasStreamedTextureDictLoaded(StreamedTxd)) return false;

    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", StreamedTxd, "radarmasksm");
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", StreamedTxd, "radarmasksm");
    AddReplaceTexture("platform:/textures/graphics", "radarmasklg", StreamedTxd, "radarmasklg");
    return true;
};

// --- Layout -----------------------------------------------------------------

const ApplyRadarLayout = () => {
    SetMinimapClipType(1);
    const [X, Y, W, H] = GetMinimapRadarRect(Minimap.MaskScale, Minimap.MaskOffsetX, Minimap.MaskOffsetY);
    for (const Name of ["minimap", "minimap_mask", "minimap_blur"]) {
        SetMinimapComponentPosition(Name, "L", "T", X, Y, W, H);
    }
};

const ApplyDefaultLayout = () => {
    SetMinimapClipType(0);
    for (const C of DefaultLayout) SetMinimapComponentPosition(C.Name, C.AlignX, C.AlignY, C.X, C.Y, C.W, C.H);
};

const UnlockMinimap = () => {
    if (!RadarLocked) return;
    UnlockMinimapAngle();
    UnlockMinimapPosition();
    RadarLocked = false;
};

const RefreshBigmap = async () => {
    if (BigmapRefreshRunning || IsPauseMenuActive()) return;
    BigmapRefreshRunning = true;

    ApplyRadarLayout();
    DisplayRadar(false);
    SetRadarBigmapEnabled(true, false);
    await Delay(50);
    SetRadarBigmapEnabled(false, false);
    ApplyRadarLayout();
    DisplayRadar(RadarWanted());

    BigmapRefreshRunning = false;
};

on("fw-hud:Client:ScreenChanged", async () => {
    ScreenGeneration += 1;
    const Generation = ScreenGeneration;

    while (Generation == ScreenGeneration && (IsPauseMenuActive() || !MinimapReady)) await Delay(100);
    if (Generation != ScreenGeneration) return;

    await Delay(350);
    for (let i = 1; i <= 6; i++) {
        if (Generation != ScreenGeneration || IsPauseMenuActive()) return;
        if (LoadRadarMask()) {
            ApplyRadarLayout();
            if (i == 1 || i == 6) RefreshBigmap();
        }
        await Delay(350);
    }
});

on("fw-hud:Client:ApplyMinimapLayout", async () => {
    if (!MinimapReady) return;
    ApplyRadarLayout();

    LayoutGeneration += 1;
    const Generation = LayoutGeneration;

    await Delay(250);
    while (Generation == LayoutGeneration && IsPauseMenuActive()) await Delay(100);
    if (Generation == LayoutGeneration && MinimapReady) RefreshBigmap();
});

// --- Setup ------------------------------------------------------------------

const WaitForPlayerReady = async () => {
    while (!NetworkIsPlayerActive(PlayerId())) await Delay(100);
    while (GetIsLoadingScreenActive()) await Delay(100);
    while (!IsScreenFadedIn()) await Delay(100);
    while (!DoesEntityExist(PlayerPedId())) await Delay(100);
    await Delay(1500);
};

const SetupMinimap = async () => {
    if (MinimapReady || MinimapLoading) return;
    MinimapLoading = true;

    const Deadline = GetGameTimer() + LoadTimeoutMs;
    while (!LoadRadarMask()) {
        if (Deadline < GetGameTimer()) {
            // console.log(`[fw-hud] Timed out loading "${RadarMaskFile}"; keeping the default minimap.`);
            MinimapLoading = false;
            return;
        }
        await Delay(0);
    }

    ApplyRadarLayout();
    DisplayRadar(false);
    SetRadarBigmapEnabled(true, false);
    await Delay(50);
    SetRadarBigmapEnabled(false, false);
    SetMinimapClipType(1);

    MinimapLoading = false;
    MinimapReady = true;
    UpdateMinimapVisibility(true);
};

const PostSpawnRefresh = async () => {
    if (!MinimapReady) return;
    for (let i = 0; i < 30; i++) {
        ApplyRadarLayout();
        await Delay(100);
    }
    RefreshBigmap();
};

(async () => {
    await WaitForPlayerReady();
    while (!MinimapReady) {
        await SetupMinimap();
        if (!MinimapReady) await Delay(1000);
    }
    PostSpawnRefresh();
})();

onNet("FW:Client:OnPlayerLoaded", async () => {
    await Delay(1500);
    PostSpawnRefresh();
});

on("onClientResourceStart", async (Name: string) => {
    if (Name != GetCurrentResourceName()) return;
    await Delay(1500);
    PostSpawnRefresh();
});

// Called by client.ts when the UI restarts, so the UI gets the current state again.
export const ForceMinimapSync = () => UpdateMinimapVisibility(true);

// --- Per-frame radar lock ---------------------------------------------------

let NextLayoutAt = 0;
setTick(async () => {
    if (MinimapReady && RadarWanted() && !IsPauseMenuActive()) {
        const Now = GetGameTimer();
        if (NextLayoutAt <= Now) {
            ApplyRadarLayout();
            SetMinimapClipType(1);
            NextLayoutAt = Now + 500;
        }

        const [X, Y] = GetEntityCoords(PlayerPedId(), true);
        SetRadarAsExteriorThisFrame();
        SetRadarZoomToDistance(ZoomDistance);
        LockMinimapPosition(X, Y);
        const [, , CamZ] = GetGameplayCamRot(2);
        LockMinimapAngle(Math.floor(CamZ + 0.5) % 360);
        RadarLocked = true;
    } else {
        NextLayoutAt = 0;
        UnlockMinimap();
        if (!MinimapReady) await Delay(200);
    }
});

// Hide the engine's north blip (the ring draws its own N)
setInterval(() => {
    if (!MinimapReady) return;
    const Blip = GetNorthRadarBlip();
    if (Blip && DoesBlipExist(Blip)) {
        SetBlipAlpha(Blip, 0);
        SetBlipDisplay(Blip, 0);
    }
}, 500);

// --- Waypoint changes break the radar layout, re-apply when it changes ---------

const GetWaypointState = () => {
    if (!IsWaypointActive()) return "off";
    const Blip = GetFirstBlipInfoId(8);
    if (!DoesBlipExist(Blip)) return "missing";
    const [X, Y] = GetBlipCoords(Blip);
    return `on:${Math.floor(X + 0.5)}:${Math.floor(Y + 0.5)}`;
};

(async () => {
    let LastState = "off";
    let LastRefresh = 0;

    while (true) {
        await Delay(100);
        if (!MinimapReady) continue;

        const State = GetWaypointState();
        if (State != LastState) {
            LastState = State;
            await Delay(150);
            if (!MinimapReady) continue;

            RefreshBigmap();
            for (let i = 0; i < 12; i++) {
                ApplyRadarLayout();
                await Delay(50);
            }
        } else if (State != "off" && State != "missing" && GetGameTimer() - LastRefresh > 250) {
            LastRefresh = GetGameTimer();
            ApplyRadarLayout();
            SetMinimapClipType(1);
        }
    }
})();

// --- Commands & cleanup -----------------------------------------------------

RegisterCommand("mapzoom", (Source: number, Args: string[]) => {
    const Value = Number(Args[0]);
    if (!Value) return console.log(`[fw-hud] usage: /mapzoom <meters> (now: ${ZoomDistance})`);
    ZoomDistance = Math.max(10.0, Value);
}, false);

RegisterCommand("minimapcal", (Source: number, Args: string[]) => {
    console.log(`HELLO`);

    const Keys: {[key: string]: keyof typeof Minimap} = {
        sx: "EngineScaleX", sy: "EngineScaleY", ox: "MaskOffsetX", oy: "MaskOffsetY", scale: "MaskScale",
    };

    if (Args[0] == "debug") return console.log(`[fw-hud] ${GetScreenDebugText()}`);
    if (Args[0] == "auto") Minimap.AutoCalibrate = true;
    if (Args[0] == "values") return console.log(`[fw-hud] ${JSON.stringify(Minimap)}`);

    if (Keys[Args[0]] && !isNaN(Number(Args[1]))) {
        (Minimap as any)[Keys[Args[0]]] = Number(Args[1]);
        if (Args[0] != "scale") Minimap.AutoCalibrate = false;
    }

    emit("fw-hud:Client:ApplyMinimapLayout");
}, false);

on("onResourceStop", (Resource: string) => {
    if (Resource != GetCurrentResourceName()) return;
    RemoveReplaceTexture("platform:/textures/graphics", "radarmasksm");
    RemoveReplaceTexture("platform:/textures/graphics", "radarmask1g");
    RemoveReplaceTexture("platform:/textures/graphics", "radarmasklg");
    UnlockMinimap();
    if (MinimapReady) ApplyDefaultLayout();
});