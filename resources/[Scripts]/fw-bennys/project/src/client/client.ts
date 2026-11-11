import "./exports"; // Must stay first: registers GetIsInBennysZone / IsInSecretBennys.
import { exp } from "../shared/utils"
import { Menu } from "./handler/menu";
export const FW = exp['fw-core'].GetCoreObject();
import { CurrentBennyZone } from "./handler/zone";
import { VehicleState } from "./handler/vehicle";

const CanOpenBennys = async (Authorized?: { Job?: string[]; Business?: string[] }) => {
    if (!Authorized) return true;

    if (Authorized.Job) {
        const MyJob = FW.Functions.GetPlayerData().job.name;
        if (Authorized.Job.includes(MyJob)) return true;
    }

    if (Authorized.Business) {
        for (const Business of Authorized.Business) {
            // IsPlayerInBusiness is async in fw-businesses.
            if (await exp['fw-businesses'].IsPlayerInBusiness(Business)) return true;
        }
    }

    return false;
};

exp("GetPreviewingStanceVehicle", () => Menu.PreviewingStanceVehicle());

// Applies one work-order item. Called on the vehicle owner's client (see sv_orders.lua).
exp("ApplyOrderItem", (Vehicle: number, Slot: string, Value: any) => {
    if (!DoesEntityExist(Vehicle)) return false;
    const State = new VehicleState(Vehicle);
    State.Preview(Slot, Value);
    if (Slot.startsWith("Stance:")) State.CommitStance();
    return true;
});

onNet("fw-bennys:Client:OpenBennys", async (IsAdmin: boolean) => {
    if (Menu.IsOpen()) return;

    const Vehicle = GetVehiclePedIsIn(PlayerPedId(), false);
    if (!DoesEntityExist(Vehicle)) return;

    const DriverPed = GetPedInVehicleSeat(Vehicle, -1);
    if (DriverPed != PlayerPedId()) {
        return FW.Functions.Notify("Je moet in de bestuurderstoel zitten om Bennys te gebruiken.", "error");
    }

    if (!IsAdmin && !(await CanOpenBennys(CurrentBennyZone?.data?.Authorized))) {
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

    Menu.Open(Vehicle, IsAdmin ? undefined : CurrentBennyZone?.data?.OrderBusiness);
});

on("onResourceStop", (Resource: string) => {
    if (Resource !== GetCurrentResourceName()) return;
    if (Menu.IsOpen()) Menu.Close(false);
});
