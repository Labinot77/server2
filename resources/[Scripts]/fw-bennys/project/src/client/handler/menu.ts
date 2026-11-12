import { ColorPalette, PaintTypes } from "../../shared/config";
import { exp, RegisterNUICallback, SendUIMessage, SetUIFocus } from "../../shared/utils";
import type { CameraFocus, CartEntry, OpenPayload } from "../../shared/types";
import { BennysCamera } from "./camera";
import { BuildCatalog } from "./catalog";
import { GetPrice, VehicleState } from "./vehicle";
import { SetMenuOpen } from "../exports";

let State: VehicleState | null = null;
let Labels: Record<string, { Label: string; Option: string }> = {};
let FrameTick: ReturnType<typeof setTick> | null = null;
let OrderBusiness: string | undefined;

// Whole fw-hud (status, speedometer, minimap). Never let a missing/old fw-hud break the menu.
const SetVehicleHud = (Visible: boolean) => {
    try { exp['fw-hud'].SetHudBlocked(Visible ? false : "all"); } catch { /* fw-hud not running */ }
};

const VehicleName = (Vehicle: number) => {
    const Display = GetDisplayNameFromVehicleModel(GetEntityModel(Vehicle));
    const Label = GetLabelText(Display);
    return Label && Label !== "NULL" ? Label : Display;
};

const BuildCart = (): CartEntry[] => {
    if (!State) return [];
    return Object.keys(State.Pending).map(Slot => ({
        Slot,
        Label: Labels[Slot]?.Label || Slot,
        Option: Labels[Slot]?.Option || "",
        Value: State!.Pending[Slot],
        Price: GetPrice(State!, Slot, State!.Pending[Slot]),
    }));
};

const SyncCart = () => {
    SendUIMessage("Bennys", "SetCart", { Cart: BuildCart(), Current: State ? State.Current() : {} });
};

const Close = (Commit: boolean) => {
    if (!State) return;
    const Vehicle = State.Vehicle;

    if (!Commit) {
        State.RevertAll();
    } else if (State.HasPendingStance()) {
        State.CommitStance();
    }

    if (FrameTick) clearTick(FrameTick);
    FrameTick = null;

    BennysCamera.Destroy();
    SendUIMessage("Bennys", "SetVisibility", { Visibility: false });
    SetVehicleHud(true); // fw-hud shows it again on its next tick
    SetNuiFocusKeepInput(false);
    SetUIFocus(false, false);
    FreezeEntityPosition(Vehicle, false);

    State = null;
    Labels = {};
    SetMenuOpen(false);
};

export const Menu = {
    IsOpen: () => State !== null,

    // The vehicle whose stance the menu is previewing (cl_stance.lua leaves it alone meanwhile), or 0.
    PreviewingStanceVehicle: () => (State && State.HasPendingStance() ? State.Vehicle : 0),

    // Business is set when the zone creates work orders instead of installing directly.
    Open: (Vehicle: number, Business?: string) => {
        if (State) return;
        OrderBusiness = Business;

        State = new VehicleState(Vehicle);
        Labels = {};

        SetMenuOpen(true);

        const Payload: OpenPayload = {
            Resource: GetCurrentResourceName(),
            Header: Business || "Los Santos Benny's",
            SubHeader: Business ? "Place your order" : "Motorworks for everyone",
            Categories: BuildCatalog(State),
            Current: State.Current(),
            Palette: ColorPalette,
            PaintTypes,
        };

        SetVehicleHud(false);
        BennysCamera.Create(Vehicle);

        SendUIMessage("Bennys", "Open", Payload);
        SendUIMessage("Bennys", "SetVisibility", { Visibility: true });
        SetNuiFocusKeepInput(true);
        SetUIFocus(true, true);

        FrameTick = setTick(() => {
            if (!State) return;

            // Keep game input (for WASD/QE camera) but block everything it would normally do.
            DisableAllControlActions(0);
            DisableControlAction(0, 200, true); // Pause menu
            HideHudAndRadarThisFrame();

            if (!DoesEntityExist(State.Vehicle) || GetPedInVehicleSeat(State.Vehicle, -1) !== PlayerPedId()) {
                return Close(false);
            }

            if (State.HasPendingStance()) State.ApplyStance();
            BennysCamera.Tick();
        });
    },

    Close,
};

// ---------- NUI ----------

RegisterNUICallback("Bennys/PlaySoundFrontend", (Data: { Name: string; Set: string }, Cb: Function) => {
    PlaySoundFrontend(-1, Data.Name, Data.Set, true);
    Cb("Ok");
});

RegisterNUICallback("Bennys/Preview", (Data: { Slot: string; Value: any; Label: string; Option: string }, Cb: Function) => {
    if (!State) return Cb("Ok");
    Labels[Data.Slot] = { Label: Data.Label, Option: Data.Option };
    State.Preview(Data.Slot, Data.Value);
    SyncCart();
    Cb("Ok");
});

RegisterNUICallback("Bennys/Revert", (Data: { Slot: string }, Cb: Function) => {
    if (!State) return Cb("Ok");
    State.Revert(Data.Slot);
    SyncCart();
    Cb("Ok");
});

RegisterNUICallback("Bennys/Focus", (Data: { Camera: CameraFocus }, Cb: Function) => {
    BennysCamera.Focus(Data.Camera);
    Cb("Ok");
});

RegisterNUICallback("Bennys/RotateCamera", (Data: { X: number; Y: number }, Cb: Function) => {
    BennysCamera.Rotate(Data.X, Data.Y);
    Cb("Ok");
});

RegisterNUICallback("Bennys/Zoom", (Data: { Delta: number }, Cb: Function) => {
    BennysCamera.Zoom(Data.Delta);
    Cb("Ok");
});

RegisterNUICallback("Bennys/Close", (_Data: any, Cb: Function) => {
    Close(false);
    Cb("Ok");
});

RegisterNUICallback("Bennys/Checkout", (Data: { Method: "Bank" | "Cash" }, Cb: Function) => {
    if (!State) return Cb("Ok");

    const Vehicle = State.Vehicle;
    const Items = BuildCart();
    if (Items.length === 0) return Cb("Ok");

    const Receipt = {
        Method: Data.Method,
        Plate: GetVehicleNumberPlateText(Vehicle).trim(),
        Model: VehicleName(Vehicle),
        Items,
        Total: Items.reduce((Sum, Item) => Sum + Item.Price, 0),
    };

    // TODO: Payment. For now we only log the purchase.
    console.log(`[fw-bennys] Checkout:\n${JSON.stringify(Receipt, null, 2)}`);

    if (OrderBusiness) {
        // Order zone: put the car back to how it was, a mechanic installs everything later.
        emitNet("fw-bennys:Server:Orders:Create", OrderBusiness, Receipt, NetworkGetNetworkIdFromEntity(Vehicle));
        Close(false);
        PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", true);
        return Cb("Ok");
    }

    const WantsRepair = "Repair" in State.Pending;
    Close(true);
    PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", true);

    // Progress bars are Lua only (sync callbacks), see client/cl_orders.lua.
    if (WantsRepair) emit("fw-bennys:Client:RepairVehicle", Vehicle);
    Cb("Ok");
});
