import { Thread } from "../../shared/classes/thread";
import { SendUIMessage } from "../../shared/utils";
import { LoggedIn } from "../client";

const PlayerThread = new Thread("tick", 200);

const GroupMelee = 2685387236;
const GroupParachute = 431593103;
const Unarmed = GetHashKey("WEAPON_UNARMED");

let Cache: {[key: string]: any} | null = null;

const Clamp = (Value: number, Min: number, Max: number) => Math.min(Max, Math.max(Min, Value));

const EmptyData = {
    Stamina: 0, ShowStamina: false,
    Oxygen: 100, IsUnderwater: false, IsSwimming: false,
    HasWeapon: false, AmmoClip: 0, AmmoReserve: 0,
};

// [HasWeapon, Clip, Reserve]
const GetWeaponData = (Ped: number): [boolean, number, number] => {
    const Weapon = GetSelectedPedWeapon(Ped);
    if (Weapon == 0 || Weapon == Unarmed) return [false, 0, 0];

    const Group = GetWeapontypeGroup(Weapon);
    if (Group == GroupMelee || Group == GroupParachute) return [false, 0, 0];

    const Total = GetAmmoInPedWeapon(Ped, Weapon);
    const MaxClip = GetMaxAmmoInClip(Ped, Weapon, true);

    if (MaxClip > 0) {
        const [Ok, InClip] = GetAmmoInClip(Ped, Weapon);
        const Clip = Ok ? InClip : 0;
        return [true, Clip, Math.max(Total - Clip, 0)];
    };

    return [true, Total, 0];
};

PlayerThread.addHook("active", () => {
    if (!LoggedIn) return PlayerThread.stop();

    const Ped = PlayerPedId();
    const PlayerIdx = PlayerId();

    const InVehicle = IsPedInAnyVehicle(Ped, false);
    const IsSwimming = IsPedSwimming(Ped);
    const [HasWeapon, AmmoClip, AmmoReserve] = GetWeaponData(Ped);

    const Data = {
        Stamina: Math.floor(Clamp(100 - GetPlayerSprintStaminaRemaining(PlayerIdx), 0, 100)),
        ShowStamina: !InVehicle && !IsSwimming && (IsPedRunning(Ped) || IsPedSprinting(Ped)),
        Oxygen: Math.floor(Clamp(GetPlayerUnderwaterTimeRemaining(PlayerIdx) * 10, 0, 100)),
        IsUnderwater: IsPedSwimmingUnderWater(Ped),
        IsSwimming,
        HasWeapon, AmmoClip, AmmoReserve,
    };

    // Only talk to the UI when something actually changed.
    const Changed = !Cache || Object.keys(Data).some((Key) => (Cache as any)[Key] != (Data as any)[Key]);
    if (!Changed) return;

    Cache = Data;
    SendUIMessage("Hud", "SetPlayerData", Data);
});

PlayerThread.addHook("afterStop", () => {
    Cache = null;
    SendUIMessage("Hud", "SetPlayerData", EmptyData);
});

// Safe to call repeatedly, it also forces a resend (used after a UI restart).
export const InitiatePlayer = () => {
    Cache = null;
    PlayerThread.start();
};