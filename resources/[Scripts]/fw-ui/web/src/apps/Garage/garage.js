import { writable, derived } from "svelte/store";

// Vehicle shape sent from fw-vehicles (BuildVehiclePayload):
// { Plate, Model, Name, State: "Stored" | "Out" | "Impounded", Type: "Personal" | "Shared",
//   Seats, Image?, Stats: { Fuel (0-100), Engine (0-1000), Body (0-1000) },
//   Impound only: Retrievable, Fee, FeeLabel, Details: [{ Label, Value }] }

export const Tabs = ["All", "Personal", "Shared"];
export const COLUMNS = 3;

export const GarageTitle = writable("Garage Manager");
export const GarageLabel = writable("");
export const EmptyText = writable("");
export const Vehicles = writable([]);

export const ActiveTab = writable("All");
export const SearchTerm = writable("");
export const FocusIndex = writable(0);

// Context menu (Retrieve / Information) on a card
export const MenuPlate = writable(null);
export const MenuIndex = writable(0);

// Information modal
export const InfoPlate = writable(null);

export const FilteredVehicles = derived(
    [Vehicles, ActiveTab, SearchTerm],
    ([$Vehicles, $ActiveTab, $SearchTerm]) => {
        let List = $Vehicles;

        if ($ActiveTab !== "All") {
            List = List.filter((v) => v.Type === $ActiveTab);
        }

        const Term = $SearchTerm.trim().toLowerCase();
        if (Term.length > 0) {
            List = List.filter(
                (v) =>
                    (v.Name || "").toLowerCase().includes(Term) ||
                    (v.Plate || "").toLowerCase().includes(Term) ||
                    (v.Model || "").toLowerCase().includes(Term)
            );
        }

        return List;
    }
);

export const GetImage = (Vehicle) => {
    if (!Vehicle) return null;
    if (Vehicle.Image) return Vehicle.Image;
    if (Vehicle.Model) return `./images/pdm/${String(Vehicle.Model).toLowerCase()}.jpg`;
    return null;
};

export const Percent = (Value, Max = 100) => {
    if (Value === undefined || Value === null || isNaN(Value)) return "--";
    return `${Math.max(0, Math.min(100, Math.round((Value / Max) * 100)))}%`;
};

// Impound vehicles send Retrievable (released + paid on retrieve); garage vehicles must be Stored
export const CanRetrieve = (Vehicle) =>
    !!Vehicle && (Vehicle.Retrievable !== undefined ? !!Vehicle.Retrievable : Vehicle.State === "Stored");

export const RetrieveLabel = (Vehicle) => {
    if (!Vehicle) return "Retrieve Vehicle";
    if (CanRetrieve(Vehicle)) return Vehicle.Fee > 0 ? `Retrieve Vehicle (${Vehicle.FeeLabel})` : "Retrieve Vehicle";
    if (Vehicle.State === "Impounded") return Vehicle.Retrievable === false ? "Not Released Yet" : "Vehicle Impounded";
    return "Vehicle Is Out";
};

export const StatusClass = (State) =>
    State === "Stored" ? "stored" : State === "Impounded" ? "impounded" : "out";

export const ResetGarageState = () => {
    Vehicles.set([]);
    ActiveTab.set("All");
    SearchTerm.set("");
    FocusIndex.set(0);
    MenuPlate.set(null);
    MenuIndex.set(0);
    InfoPlate.set(null);
};
