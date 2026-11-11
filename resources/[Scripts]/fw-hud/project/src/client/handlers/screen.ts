import { Minimap } from "../../shared/config";
import { RegisterNUICallback, SendUIMessage } from "../../shared/utils";

interface GfxTransform { x: number; y: number; sx: number; sy: number; }
export interface ScreenData {
    width: number; height: number;
    aspect: number; physicalAspect: number; safezone: number;
    revision: number; transform: GfxTransform;
}
interface RadarLayout { cx: number; cy: number; diameter: number; wFrac?: number; hFrac?: number; }

let CachedScreen: ScreenData | null = null;
let RadarLayoutData: RadarLayout | null = null;
let Revision = 0;

const IsNumber = (Value: any): Value is number => typeof Value == "number" && Value == Value;
const Clamp = (Value: number, Min: number, Max: number) => Math.max(Min, Math.min(Max, Value));

const MeasureGfxRect = (AlignX: string, AlignY: string): GfxTransform => {
    SetScriptGfxAlign(AlignX.charCodeAt(0), AlignY.charCodeAt(0));
    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0);
    const [x, y] = GetScriptGfxPosition(0.0, 0.0);
    const [x2, y2] = GetScriptGfxPosition(1.0, 1.0);
    ResetScriptGfxAlign();
    return { x, y, sx: x2 - x, sy: y2 - y };
};

const GetRadarReference = (Screen: ScreenData): RadarLayout => {
    if (RadarLayoutData) return RadarLayoutData;

    // Fallback until the UI reports the real ring (matches the CSS position of .compass__ring).
    const Diameter = 0.105 * Screen.width;
    RadarLayoutData = {
        cx: 0.8975,
        cy: 0.10 + (Diameter / 2) / Screen.height,
        diameter: Diameter,
    };
    return RadarLayoutData;
};

export const RefreshScreen = (Force: boolean = false) => {
    const [Width, Height] = GetActiveScreenResolution();
    if (Width < 1 || Height < 1) return;

    const Aspect = GetAspectRatio(false);
    const PhysicalAspect = GetAspectRatio(true);
    const Safezone = GetSafeZoneSize();
    const Transform = MeasureGfxRect("L", "T");

    if (!(IsNumber(Transform.sx) && IsNumber(Transform.sy) && Math.abs(Transform.sx) >= 1e-5 && Math.abs(Transform.sy) >= 1e-5)) return;

    if (!Force && CachedScreen
        && CachedScreen.width == Width && CachedScreen.height == Height
        && Math.abs(CachedScreen.aspect - Aspect) < 1e-5
        && Math.abs(CachedScreen.physicalAspect - PhysicalAspect) < 1e-5
        && Math.abs(CachedScreen.safezone - Safezone) < 1e-5
        && Math.abs(CachedScreen.transform.x - Transform.x) < 1e-5
        && Math.abs(CachedScreen.transform.y - Transform.y) < 1e-5
        && Math.abs(CachedScreen.transform.sx - Transform.sx) < 1e-5
        && Math.abs(CachedScreen.transform.sy - Transform.sy) < 1e-5) return;

    Revision += 1;
    CachedScreen = {
        width: Width, height: Height,
        aspect: Aspect, physicalAspect: PhysicalAspect, safezone: Safezone,
        revision: Revision, transform: Transform,
    };
    RadarLayoutData = null;

    SendUIMessage("Hud", "SetScreen", { Screen: CachedScreen });
    emit("fw-hud:Client:ApplyMinimapLayout");
    emit("fw-hud:Client:ScreenChanged");
};

export const GetScreen = (): ScreenData | null => {
    if (!CachedScreen) RefreshScreen(true);
    return CachedScreen;
};

export const GetMinimapRadarRect = (Zoom: number, OffsetX: number, OffsetY: number): [number, number, number, number] => {
    const Screen = GetScreen();
    if (!Screen) return [0, 0, 0, 0];

    const Reference = GetRadarReference(Screen);
    const Transform = Screen.transform;
    const ZoomK = Clamp(Zoom || 1.0, 0.5, 2.0);

    // Ring size in real game pixels (UI viewport can differ from the game resolution).
    const WidthPx = (Reference.wFrac ? Reference.wFrac * Screen.width : Reference.diameter) * ZoomK;
    const HeightPx = (Reference.hFrac ? Reference.hFrac * Screen.height : Reference.diameter) * ZoomK;

    let EngX = Minimap.EngineScaleX;
    let EngY = Minimap.EngineScaleY;
    let OffX = OffsetX;
    let OffY = OffsetY;

    if (Minimap.AutoCalibrate) {
        const T = Clamp(16.0 / 9.0 - Screen.aspect, 0.0, 0.45);
        // Mask circle fills the whole texture, so the rect is the ring itself (keeps the GPS route inside).
        EngX = 1.0;
        EngY = (0.97 + 0.731 * T) / 0.982;
        OffX = -0.15 - 0.1125 * T;
        OffY = -0.01 + 1.294 * T;
    }

    const CenterX = Reference.cx + Clamp(OffX, -0.5, 0.5) * WidthPx / Screen.width;
    const CenterY = Reference.cy + Clamp(OffY, -0.5, 0.5) * HeightPx / Screen.height;
    const LeftN = CenterX - (WidthPx * 0.5) / Screen.width;
    const TopN = CenterY - (HeightPx * 0.5) / Screen.height;

    // GTA minimap X units are fractions of a 16:9 area, not of the real width.
    const ScaleX = Transform.sy * (16.0 / 9.0) / (Screen.width / Screen.height);

    return [
        (LeftN - Transform.x) / ScaleX,
        (TopN - Transform.y) / Transform.sy,
        WidthPx / (Screen.width * ScaleX * EngX),
        HeightPx / (Screen.height * Transform.sy * EngY),
    ];
};

export const GetScreenDebugText = () => {
    const Screen = GetScreen();
    if (!Screen) return "no screen data";
    const [x, y, w, h] = GetMinimapRadarRect(Minimap.MaskScale, Minimap.MaskOffsetX, Minimap.MaskOffsetY);
    return `res ${Screen.width}x${Screen.height} | aspect ${Screen.aspect.toFixed(4)} | safezone ${Screen.safezone.toFixed(3)} | component x=${x.toFixed(4)} y=${y.toFixed(4)} w=${w.toFixed(4)} h=${h.toFixed(4)}`;
};

RegisterNUICallback("Minimap/ScreenReady", (Data: any, Cb: Function) => {
    Cb({ ok: true, screen: GetScreen() });
});

RegisterNUICallback("Minimap/RadarLayout", (Data: any, Cb: Function) => {
    const Screen = GetScreen();
    if (!Screen || !Data || Data.revision != Screen.revision) {
        return Cb({ ok: false, error: "Screen changed", screen: Screen });
    }

    const { cx, cy, diameter, dx, dy } = Data;
    if (!(IsNumber(cx) && IsNumber(cy) && IsNumber(diameter)) || cx < 0 || cx > 1 || cy < 0 || cy > 1 || diameter <= 0 || diameter > 1) {
        return Cb({ ok: false, error: "Invalid radar bounds" });
    }

    RadarLayoutData = {
        cx, cy,
        diameter: diameter * Screen.height,
        wFrac: IsNumber(dx) && dx > 0 && dx <= 1 ? dx : undefined,
        hFrac: IsNumber(dy) && dy > 0 && dy <= 1 ? dy : undefined,
    };

    emit("fw-hud:Client:ApplyMinimapLayout");
    Cb({ ok: true });
});

setInterval(() => RefreshScreen(false), 500);