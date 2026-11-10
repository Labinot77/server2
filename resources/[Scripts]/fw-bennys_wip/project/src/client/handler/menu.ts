import { ColorPalette, PaintTypes } from "../../shared/config";
import { RegisterNUICallback, SendUIMessage, SetUIFocus } from "../../shared/utils";
import type { CameraFocus, CartEntry, OpenPayload } from "../../shared/types";
import { BennysCamera } from "./camera";
import { BuildCatalog } from "./catalog";
import { GetPrice, VehicleState } from "./vehicle";

let State: VehicleState | null = null;
let Labels: Record<string, { Label: string; Option: string }> = {};
let FrameTick: ReturnType<typeof setTick> | null = null;
let OnRepair: ((Vehicle: number) => void) | null = null;

// Vehicles with purchased stance keep getting it applied (wheel offset natives aren't persistent).
const PersistedStance = new Map<number, VehicleState>();
let PersistTick: ReturnType<typeof setTick> | null = null;

const StartPersistTick = () => {
    if (PersistTick) return;
    PersistTick = setTick(() => {
        for (const [Vehicle, VehState] of PersistedStance) {
            if (!DoesEntityExist(Vehicle)) { PersistedStance.delete(Vehicle); continue; }
            if (State && State.Vehicle === Vehicle) continue; // Menu tick handles it.
            VehState.ApplyStance();
        }
        if (PersistedStance.size === 0 && PersistTick) { clearTick(PersistTick); PersistTick = null; }
    });
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
        PersistedStance.set(Vehicle, State);
        StartPersistTick();
    }

    if (FrameTick) clearTick(FrameTick);
    FrameTick = null;

    BennysCamera.Destroy();
    SendUIMessage("Bennys", "SetVisibility", { Visibility: false });
    SetNuiFocusKeepInput(false);
    SetUIFocus(false, false);
    FreezeEntityPosition(Vehicle, false);

    State = null;
    Labels = {};
};

export const Menu = {
    IsOpen: () => State !== null,

    SetRepairHandler: (Handler: (Vehicle: number) => void) => {
        OnRepair = Handler;
    },

    Open: (Vehicle: number) => {
        if (State) return;

        // Re-opening a vehicle with persisted stance: start from what's on it now.
        PersistedStance.delete(Vehicle);

        State = new VehicleState(Vehicle);
        Labels = {};

        const Payload: OpenPayload = {
            Header: "Los Santos Benny's",
            SubHeader: "Motorworks for everyone",
            Categories: BuildCatalog(State),
            Current: State.Current(),
            Palette: ColorPalette,
            PaintTypes,
        };

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
        Model: GetDisplayNameFromVehicleModel(GetEntityModel(Vehicle)),
        Items,
        Total: Items.reduce((Sum, Item) => Sum + Item.Price, 0),
    };

    // TODO: Payment + saving mods. For now we only log the purchase.
    console.log(`[fw-bennys] Checkout:\n${JSON.stringify(Receipt, null, 2)}`);

    const WantsRepair = "Repair" in State.Pending;
    Close(true);
    PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", true);

    if (WantsRepair && OnRepair) OnRepair(Vehicle);
    Cb("Ok");
});
