import { writable, derived } from "svelte/store";

export const GarageLabel = writable("None");
export const Vehicles = writable([]); // [{ Plate, Model, Name, State, Locked, Type, Stats: {Engine, Body} }]

export const ActiveTab = writable("All"); // "All" | "Personal" | "Job"
export const SearchTerm = writable("");
export const SelectedPlate = writable(null);

export const ModalData = writable({ Type: null, Show: false });

export const FilteredVehicles = derived(
    [Vehicles, ActiveTab, SearchTerm],
    ([$Vehicles, $ActiveTab, $SearchTerm]) => {
        let List = $Vehicles;

        if ($ActiveTab !== "All") {
            List = List.filter((v) => v.Type === $ActiveTab);
        }

        if ($SearchTerm.trim().length > 0) {
            const Term = $SearchTerm.trim().toLowerCase();
            List = List.filter(
                (v) => v.Name.toLowerCase().includes(Term) || v.Plate.toLowerCase().includes(Term)
            );
        }

        return List;
    }
);

export const ResetGarageState = () => {
    Vehicles.set([]);
    ActiveTab.set("All");
    SearchTerm.set("");
    SelectedPlate.set(null);
    ModalData.set({ Type: null, Show: false });
};