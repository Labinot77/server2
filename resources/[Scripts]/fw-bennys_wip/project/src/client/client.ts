import { exp } from "../shared/utils"
import { Menu } from "./handler/menu";
export const FW = exp['fw-core'].GetCoreObject();
import './handler/zone';
import { CurrentBennyZone, IsInBennysZone } from "./handler/zone";

exp("GetIsInBennysZone", () => IsInBennysZone);
exp("IsInSecretBennys", () => IsInBennysZone && CurrentBennyZone?.data?.Secret === true);
exp("IsBennysOpen", () => Menu.IsOpen());

const CanOpenBennys = (Authorized?: { Job?: string[]; Business?: string[] }) => {
    if (!Authorized) return true;

    if (Authorized.Job) {
        const MyJob = FW.Functions.GetPlayerData().job.name;
        if (Authorized.Job.includes(MyJob)) return true;
    }

    if (Authorized.Business) {
        for (const Business of Authorized.Business) {
            if (exp['fw-businesses'].IsPlayerInBusiness(Business)) return true;
        }
    }

    return false;
};

// Runs after checkout when "Repair" was in the cart (logic from the old repair menu).
Menu.SetRepairHandler((Vehicle: number) => {
    const BodyHealth = GetVehicleBodyHealth(Vehicle);
    const EngineHealth = GetVehicleEngineHealth(Vehicle);

    const MissingBodyHealth = 1000.0 - BodyHealth;
    const MissingEngineHealth = 1000.0 - EngineHealth;

    SetVehicleHandbrake(Vehicle, true);

    if (MissingEngineHealth > 50) {
        const Finished = FW.Functions.CompactProgressbar(5000 + (MissingEngineHealth / 50), "Motor repareren...", false, false, {disableMovement: true, disableCarMovement: true, disableMouse: false, disableCombat: true}, {}, {}, {}, false);
        if (Finished) {
            SetVehicleEngineHealth(Vehicle, EngineHealth + MissingEngineHealth);
            SetVehiclePetrolTankHealth(Vehicle, 1000.0);
        };
    };

    if (MissingBodyHealth > 50) {
        const Finished = FW.Functions.CompactProgressbar(5000 + (MissingBodyHealth / 50), "Body repareren...", false, false, {disableMovement: true, disableCarMovement: true, disableMouse: false, disableCombat: true}, {}, {}, {}, false);
        if (Finished) {
            SetVehicleDeformationFixed(Vehicle);
            SetVehicleBodyHealth(Vehicle, BodyHealth + MissingBodyHealth);
        };
    };

    if (GetVehicleBodyHealth(Vehicle) >= 900 && GetVehicleEngineHealth(Vehicle) >= 900) {
        FW.VSync.SetVehicleFixed(Vehicle)
    };

    SetVehicleHandbrake(Vehicle, false);
});

onNet("fw-bennys:Client:OpenBennys", (IsAdmin: boolean) => {
    if (Menu.IsOpen()) return;

    const Vehicle = GetVehiclePedIsIn(PlayerPedId(), false);
    if (!DoesEntityExist(Vehicle)) return;

    const DriverPed = GetPedInVehicleSeat(Vehicle, -1);
    if (DriverPed != PlayerPedId()) {
        return FW.Functions.Notify("Je moet in de bestuurderstoel zitten om Bennys te gebruiken.", "error");
    }

    if (!IsAdmin && !CanOpenBennys(CurrentBennyZone?.data?.Authorized)) {
        return FW.Functions.Notify("Deze Bennys kan jij niet gebruiken..", "error");
    }

    // todo: add mechanic online check.

    SetVehicleModKit(Vehicle, 0);
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true);
    if (!IsAdmin && CurrentBennyZone && CurrentBennyZone.data && CurrentBennyZone.data.Heading) {
        SetEntityHeading(Vehicle, CurrentBennyZone.data.Heading);
    };

    FreezeEntityPosition(Vehicle, true);
    exp['fw-ui'].HideInteraction();

    Menu.Open(Vehicle);
});

on("onResourceStop", (Resource: string) => {
    if (Resource !== GetCurrentResourceName()) return;
    if (Menu.IsOpen()) Menu.Close(false);
});
