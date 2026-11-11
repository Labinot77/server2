import { Config, Minimap } from "../../shared/config";
import { Delay, SendUIMessage } from "../../shared/utils";
import { GetHudSetting } from "./settings";

// The engine radar is hidden; the UI draws the map, blips and GPS route itself (fw-ui Hud/layers/Minimap.svelte).

const WaypointSprite = 8;
const HiddenDisplays = [0, 3, 4]; // main map only / hidden
const GpsRouteNative = "0xF3162836C28F9DA5"; // GET_POS_ALONG_GPS_TYPE_ROUTE

let MinimapVisible = false;
let LastSentVisible: boolean | null = null;
let RouteType = 0;

const MinimapWanted = () => MinimapVisible && !Config.MyPreferences["BlackBars.Show"] && GetHudSetting("map", "showMinimap", true);

export const UpdateMinimapVisibility = (Force: boolean = false) => {
    const Wanted = MinimapWanted();
    if (!Force && LastSentVisible == Wanted) return;
    LastSentVisible = Wanted;
    SendUIMessage("Hud", "SetMinimapVisibility", { Visible: Wanted });
};

export const SetMinimapVisible = (Visible: boolean) => {
    MinimapVisible = Visible;
    UpdateMinimapVisibility();
};

// Called by client.ts when the UI restarts.
export const ForceMinimapSync = () => UpdateMinimapVisibility(true);

on("fw-hud:Client:OnHudSettingsUpdate", () => UpdateMinimapVisibility());

// --- Position (every frame the map is shown, throttled to ~30 fps) ----------

let NextPosition = 0;
setTick(() => {
    DisplayRadar(false);
    if (!LastSentVisible || IsPauseMenuActive()) return;

    const Now = GetGameTimer();
    if (Now < NextPosition) return;
    NextPosition = Now + 33;

    const Ped = PlayerPedId();
    const [X, Y] = GetEntityCoords(Ped, true);
    SendUIMessage("Hud", "SetMinimapPosition", {
        X, Y,
        Heading: GetEntityHeading(Ped),
        Zoom: IsPedInAnyVehicle(Ped, false) ? Minimap.ZoomVehicle : Minimap.Zoom,
    });
});

// --- Blips ------------------------------------------------------------------

const CollectBlips = () => {
    const Ignore = [GetMainPlayerBlipId(), GetNorthRadarBlip()];
    const Blips: number[][] = [];

    for (let Sprite = 1; Sprite <= Minimap.MaxBlipSprite; Sprite++) {
        for (let Blip = GetFirstBlipInfoId(Sprite); DoesBlipExist(Blip); Blip = GetNextBlipInfoId(Sprite)) {
            if (Ignore.includes(Blip) || GetBlipAlpha(Blip) == 0 || HiddenDisplays.includes(GetBlipInfoIdDisplay(Blip))) continue;

            const [X, Y] = GetBlipInfoIdCoord(Blip);
            // [x, y, sprite, colour, shortRange(0/1), rotation]
            Blips.push([Math.round(X), Math.round(Y), Sprite, GetBlipColour(Blip), IsBlipShortRange(Blip) ? 1 : 0, GetBlipRotation(Blip)]);
        }
    }
    return Blips;
};

// --- GPS route --------------------------------------------------------------

const GetRoutePoint = (Distance: number, Type: number): number[] | null => {
    const [Found, Pos] = Citizen.invokeNative<[boolean, number[]]>(GpsRouteNative, Citizen.pointerValueVector(), true, Distance, Type, Citizen.returnResultAnyway());
    return Found && Pos && (Pos[0] != 0 || Pos[1] != 0) ? Pos : null;
};

const CollectRoute = () => {
    if (!DoesBlipExist(GetFirstBlipInfoId(WaypointSprite))) return [];

    // The waypoint route slot differs per build; find the one that answers and remember it.
    if (!GetRoutePoint(Minimap.RouteStep, RouteType)) {
        RouteType = [0, 1, 2].find((Type) => GetRoutePoint(Minimap.RouteStep, Type)) ?? 0;
    }

    const Points: number[] = [];
    for (let Distance = 0; Distance <= Minimap.RouteRange; Distance += Minimap.RouteStep) {
        const Pos = GetRoutePoint(Distance, RouteType);
        if (!Pos) break;
        Points.push(Math.round(Pos[0] * 10) / 10, Math.round(Pos[1] * 10) / 10);
    }
    return Points;
};

(async () => {
    let LastBlips = "", LastRoute = "";
    while (true) {
        await Delay(Minimap.DataInterval);
        if (!LastSentVisible || IsPauseMenuActive()) continue;

        const Blips = CollectBlips(), BlipsKey = JSON.stringify(Blips);
        if (BlipsKey != LastBlips) {
            LastBlips = BlipsKey;
            SendUIMessage("Hud", "SetMinimapBlips", { Blips });
        }

        const Points = CollectRoute(), RouteKey = Points.join();
        if (RouteKey != LastRoute) {
            LastRoute = RouteKey;
            SendUIMessage("Hud", "SetMinimapRoute", { Points, Colour: Minimap.RouteColour });
        }
    }
})();

// --- Commands & cleanup -----------------------------------------------------

RegisterCommand("mapzoom", (Source: number, Args: string[]) => {
    const Value = Number(Args[0]);
    if (!Value) return console.log(`[fw-hud] usage: /mapzoom <meters> [vehicle meters] (now: ${Minimap.Zoom} / ${Minimap.ZoomVehicle})`);
    Minimap.Zoom = Math.max(30, Value);
    Minimap.ZoomVehicle = Math.max(30, Number(Args[1]) || Minimap.ZoomVehicle);
}, false);

on("onResourceStop", (Resource: string) => {
    if (Resource == GetCurrentResourceName()) DisplayRadar(true);
});
