import type { CameraFocus } from "../../shared/types";

// Orbit camera around the vehicle. Heading is relative to the vehicle (0 = front), pitch in degrees.
type Orbit = { Heading: number; Pitch: number; Distance: number };

const PRESETS: Record<CameraFocus, { Heading: number; Pitch: number; Zoom: number }> = {
    default: { Heading: 35, Pitch: 12, Zoom: 1.0 },
    front: { Heading: 15, Pitch: 10, Zoom: 0.85 },
    rear: { Heading: 165, Pitch: 12, Zoom: 0.85 },
    side: { Heading: 90, Pitch: 6, Zoom: 0.95 },
    wheel: { Heading: 60, Pitch: 2, Zoom: 0.6 },
    top: { Heading: 30, Pitch: 55, Zoom: 1.0 },
    interior: { Heading: 290, Pitch: 22, Zoom: 0.5 },
};

const WALL_PADDING = 0.25; // metres kept between the camera and a wall

const CONTROLS = { W: 32, S: 33, A: 34, D: 35, Q: 44, E: 38 };

let Cam = 0;
let Vehicle = 0;
let CenterZ = 0;
let MinDistance = 3;
let MaxDistance = 10;
let BaseDistance = 6;

const Current: Orbit = { Heading: 35, Pitch: 12, Distance: 6 };
const Target: Orbit = { Heading: 35, Pitch: 12, Distance: 6 };

const Clamp = (V: number, Min: number, Max: number) => Math.max(Min, Math.min(Max, V));
const Rad = (Deg: number) => (Deg * Math.PI) / 180;

const ShortestAngle = (From: number, To: number) => {
    let Diff = (To - From) % 360;
    if (Diff > 180) Diff -= 360;
    if (Diff < -180) Diff += 360;
    return Diff;
};

const UpdateCamPosition = () => {
    const H = Rad(Current.Heading);
    const P = Rad(Current.Pitch);
    const Flat = Current.Distance * Math.cos(P);

    let [X, Y, Z] = GetOffsetFromEntityInWorldCoords(Vehicle, Math.sin(H) * Flat, Math.cos(H) * Flat, CenterZ + Current.Distance * Math.sin(P));
    const [CX, CY, CZ] = GetOffsetFromEntityInWorldCoords(Vehicle, 0.0, 0.0, CenterZ);

    // Raycast car -> camera (world + objects, ignoring the car); stop just in front of anything hit.
    const Ray = StartExpensiveSynchronousShapeTestLosProbe(CX, CY, CZ, X, Y, Z, 1 | 16, Vehicle, 4);
    const [, Hit, HitCoords] = GetShapeTestResult(Ray);
    if (Hit) {
        const Dist = Math.hypot(X - CX, Y - CY, Z - CZ);
        const Safe = Math.max(0, Math.hypot(HitCoords[0] - CX, HitCoords[1] - CY, HitCoords[2] - CZ) - WALL_PADDING) / Dist;
        X = CX + (X - CX) * Safe;
        Y = CY + (Y - CY) * Safe;
        Z = CZ + (Z - CZ) * Safe;
    }

    SetCamCoord(Cam, X, Y, Z);
    PointCamAtCoord(Cam, CX, CY, CZ);
};

export const BennysCamera = {
    Create(Veh: number) {
        Vehicle = Veh;

        const [Min, Max] = GetModelDimensions(GetEntityModel(Veh));
        const Length = Max[1] - Min[1];
        const Width = Max[0] - Min[0];
        CenterZ = (Min[2] + Max[2]) / 2 - 0.1;
        BaseDistance = Math.max(Length, Width) * 0.9 + 1.6;
        MinDistance = Math.max(1.6, BaseDistance * 0.35);
        MaxDistance = BaseDistance * 1.8;

        Object.assign(Target, { Heading: PRESETS.default.Heading, Pitch: PRESETS.default.Pitch, Distance: BaseDistance });
        Object.assign(Current, { ...Target, Heading: Target.Heading + 40, Distance: BaseDistance * 1.3 });

        Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true);
        SetCamFov(Cam, 50.0);
        UpdateCamPosition();
        SetCamActive(Cam, true);
        RenderScriptCams(true, true, 600, true, true);
    },

    Destroy() {
        if (!Cam) return;
        RenderScriptCams(false, true, 600, true, true);
        SetCamActive(Cam, false);
        DestroyCam(Cam, false);
        Cam = 0;
        Vehicle = 0;
    },

    Focus(Focus: CameraFocus = "default") {
        const Preset = PRESETS[Focus] || PRESETS.default;
        Target.Heading = Preset.Heading;
        Target.Pitch = Preset.Pitch;
        Target.Distance = Clamp(BaseDistance * Preset.Zoom, MinDistance, MaxDistance);
    },

    Rotate(DeltaX: number, DeltaY: number) {
        Target.Heading -= DeltaX * 0.3;
        Target.Pitch = Clamp(Target.Pitch + DeltaY * 0.2, -8, 75);
    },

    Zoom(Delta: number) {
        Target.Distance = Clamp(Target.Distance + Delta, MinDistance, MaxDistance);
    },

    // Called every frame while the menu is open.
    Tick() {
        if (!Cam || !DoesEntityExist(Vehicle)) return;

        // Controls are disabled by the menu, so read the disabled state (keys from the hint bar).
        if (IsDisabledControlPressed(0, CONTROLS.W)) Target.Pitch = Clamp(Target.Pitch + 0.9, -8, 75);
        if (IsDisabledControlPressed(0, CONTROLS.S)) Target.Pitch = Clamp(Target.Pitch - 0.9, -8, 75);
        if (IsDisabledControlPressed(0, CONTROLS.A)) Target.Heading += 1.6;
        if (IsDisabledControlPressed(0, CONTROLS.D)) Target.Heading -= 1.6;
        if (IsDisabledControlPressed(0, CONTROLS.Q)) Target.Distance = Clamp(Target.Distance + 0.06, MinDistance, MaxDistance);
        if (IsDisabledControlPressed(0, CONTROLS.E)) Target.Distance = Clamp(Target.Distance - 0.06, MinDistance, MaxDistance);

        const Ease = 0.12;
        Current.Heading += ShortestAngle(Current.Heading, Target.Heading) * Ease;
        Current.Pitch += (Target.Pitch - Current.Pitch) * Ease;
        Current.Distance += (Target.Distance - Current.Distance) * Ease;

        UpdateCamPosition();
    },
};
