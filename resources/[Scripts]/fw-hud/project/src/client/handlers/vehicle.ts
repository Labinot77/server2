import { Thread } from "../../shared/classes/thread";
import { Delay, SendUIMessage, exp } from "../../shared/utils";
import { FW } from "../client";
import { StartCompass, StopCompass } from "./compass";
import { GetHudId, SetHudValue, SetHudVisibleState } from "./hud";
import { SetMinimapVisible } from "./minimap";
import { IsVehicleHudBlocked } from "./blockers";

const VehicleThread = new Thread("tick", 50);
const IgnoreBeltClasses: number[] = [8, 13]
const IgnoreBeltModels: number[] = [ GetHashKey("polmotor") ];
const ElectricModels: number[] = ["voltic", "voltic2", "khamelion", "raiden"].map((Name) => GetHashKey(Name));
import { GetHudSetting } from "./settings";

const MaxSpeedKmh = 240;
const MaxSpeedKnots = 200;

let VehicleHudState: boolean = false;
let LastFuelWarning: number = 0;
let CurrentNitrousValue: number = 0;
let CurrentHarnessValue: number = 0;
let Cache: {[key: string]: any} | null = null;

const Clamp = (Value: number, Min: number, Max: number) => Math.min(Max, Math.max(Min, Value));

const GetGear = (Vehicle: number): string => {
    const Gear = GetVehicleCurrentGear(Vehicle);
    if (Gear > 0) return String(Gear);

    const [, Forward] = GetEntitySpeedVector(Vehicle, true);
    return Forward < -0.5 ? "R" : "N";
};

const IsLocked = (Vehicle: number): boolean => {
    return GetVehicleDoorLockStatus(Vehicle) >= 2 || !!GetVehicleDoorsLockedForPlayer(Vehicle, PlayerId());
};

// const IsElectric = (Vehicle: number): boolean => {
//     return !!GetIsVehicleElectric(Vehicle) || ElectricModels.includes(GetEntityModel(Vehicle));
// };

// Speedometer: shown while in a vehicle, unless a blocker (phone, inventory, Benny's) is active.
const SyncVehicleVisibility = () => SendUIMessage("Hud", "SetVehicleVisibility", {Visible: VehicleHudState && !IsVehicleHudBlocked()});
on("fw-hud:Client:OnBlockersChanged", SyncVehicleVisibility);

const HideVehicleHud = () => {
    const WasInHeliCam = exp['fw-police'].IsInHeliCam();

    VehicleHudState = false;
    Cache = null;
    SetMinimapVisible(false);
    StopCompass();
    SyncVehicleVisibility();

    if (WasInHeliCam) SetHudVisibleState(false);
};

exp("HideVehicleHud", HideVehicleHud);

const ShowVehicleHud = () => {
    VehicleHudState = true;
    SyncVehicleVisibility();
    StartCompass();
    SetMinimapVisible(true);
    SetHudVisibleState(true);
};
exp("ShowVehicleHud", ShowVehicleHud);

VehicleThread.addHook('active', () => {
    const Ped = PlayerPedId();
    const Vehicle = GetVehiclePedIsIn(Ped, false);

    if (Vehicle == 0 || IsPauseMenuActive() || exp['fw-police'].IsInHeliCam()) {
        if (VehicleHudState) HideVehicleHud();
        return;
    };

    if (!VehicleHudState) ShowVehicleHud();

    const FuelLevel = exp['fw-vehicles'].GetVehicleMeta(Vehicle, "Fuel") || 0;
    if (FuelLevel > 0 && FuelLevel < 10 && LastFuelWarning - GetGameTimer() < 0) {
        LastFuelWarning = GetGameTimer() + 15000;
        WarnFuellevel();
    };

    const IsAircraft = IsPedInAnyHeli(Ped) || IsPedInAnyPlane(Ped);
    const HasBelt = (IgnoreBeltClasses.includes(GetVehicleClass(Vehicle)) || IgnoreBeltModels.includes(GetEntityModel(Vehicle))) || exp['fw-vehicles'].GetBeltStatus();
    const [, LightsOn, HighBeams] = GetVehicleLightsState(Vehicle);
    const Speed = GetEntitySpeed(Vehicle);
    const UseMph = !IsAircraft && GetHudSetting("vehicle", "unit", "auto") == "mph";

    const Data = {
        Speed: Math.ceil(Speed * (IsAircraft ? 1.943844 : (UseMph ? 2.236936 : 3.6))),
        MaxSpeed: IsAircraft ? MaxSpeedKnots : (UseMph ? 150 : MaxSpeedKmh),
        Unit: IsAircraft ? "KNOTS" : (UseMph ? "MPH" : "KM/H"),
        Fuel: Math.round(Clamp(FuelLevel, 0, 100)),
        Gear: GetGear(Vehicle),
        IsAircraft,
        Altitude: IsAircraft ? Math.max(Math.floor(GetEntityHeightAboveGround(Vehicle) * 3.28084) - 4, 0) : 0,
        Lights: LightsOn == 1 || HighBeams == 1,
        Belt: !!HasBelt,
        Locked: IsLocked(Vehicle),
        Engine: Math.floor(Math.max(GetVehicleEngineHealth(Vehicle), 0)),
        EngineOn: !!GetIsVehicleEngineRunning(Vehicle),
        // Electric: IsElectric(Vehicle),

        // Nitrous: CurrentNitrousValue,
        // Harness: CurrentHarnessValue,
    };

    // Only talk to the UI when something actually changed.
    if (!Cache || Object.keys(Data).some((Key) => (Cache as any)[Key] != (Data as any)[Key])) {
        Cache = Data;
        SendUIMessage("Hud", "SetVehicleData", Data);
    };

    const NitrousPercentage = exp['fw-vehicles'].GetVehicleMeta(Vehicle, 'Nitrous');
    const HarnessPercentage = exp['fw-vehicles'].GetVehicleMeta(Vehicle, 'Harness');

    if (NitrousPercentage != CurrentNitrousValue) {
        CurrentNitrousValue = NitrousPercentage
        SetHudValue(GetHudId('Nitrous'), CurrentNitrousValue);
    };

    if (HarnessPercentage != CurrentHarnessValue) {
        CurrentHarnessValue = HarnessPercentage
        SetHudValue(GetHudId('Harness'), CurrentHarnessValue);
    };
});

const WarnFuellevel = async () => {
    FW.Functions.Notify('Fuel level low..', 'error')
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true); await Delay(200);
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true); await Delay(200);
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true);
};

onNet("baseevents:enteredVehicle", (Vehicle: number, SeatIndex: number, DisplayName: string, NetId: number) => {
    VehicleThread.start();
});

onNet("baseevents:leftVehicle", (Vehicle: number, SeatIndex: number, DisplayName: string, NetId: number) => {
    if (VehicleThread.running) VehicleThread.stop();

    CurrentNitrousValue = 0;
    CurrentHarnessValue = 0;
    HideVehicleHud();
});