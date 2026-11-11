<script>
    import "@fontsource/barlow-condensed/600.css";
    import "@fontsource/barlow-condensed/600-italic.css";
    import "@fontsource/barlow-condensed/700.css";
    import "@fontsource/barlow-condensed/700-italic.css";

    import { onDestroy } from "svelte";
    import { OnEvent, SendEvent as _SendEvent } from "../../utils/Utils";
    const SendEvent = (Event, Parameters, Callback) => _SendEvent(Event, Parameters, Callback, "fw-vehicles");

    import AppWrapper from "../../components/AppWrapper.svelte";
    import GarageHeader from "./components/GarageHeader.svelte";
    import FilterTabs from "./components/FilterTabs.svelte";
    import VehicleGrid from "./components/VehicleGrid.svelte";
    import InfoModal from "./components/InfoModal.svelte";
    import KeyHints from "./components/KeyHints.svelte";

    import {
        Tabs,
        COLUMNS,
        GarageTitle,
        GarageLabel,
        EmptyText,
        CanRetrieve,
        Vehicles,
        ActiveTab,
        SearchTerm,
        FocusIndex,
        MenuPlate,
        MenuIndex,
        InfoPlate,
        FilteredVehicles,
        ResetGarageState,
    } from "./garage.js";

    let Visible = false;
    let State = "Loaded";

    OnEvent("Garage", "SetVisibility", (Data) => {
        if (!Data.Visible) {
            Visible = false;
            ResetGarageState();
            return;
        }

        ResetGarageState();
        GarageTitle.set(Data.Title || "Garage Manager");
        GarageLabel.set(Data.Label || "");
        EmptyText.set(Data.EmptyText || "");
        Vehicles.set(Data.Vehicles || []);

        State = "Loading";
        Visible = true;
        setTimeout(() => (State = "Loaded"), 400);
    });

    OnEvent("Garage", "SetVehicles", (Data) => {
        Vehicles.set(Data.Vehicles || []);
    });

    // Tab counts (respecting the search term)
    $: Counts = Tabs.reduce((Acc, Tab) => {
        const Term = $SearchTerm.trim().toLowerCase();
        Acc[Tab] = $Vehicles.filter(
            (v) =>
                (Tab === "All" || v.Type === Tab) &&
                (!Term || (v.Name || "").toLowerCase().includes(Term) || (v.Plate || "").toLowerCase().includes(Term))
        ).length;
        return Acc;
    }, {});

    // Keep focus inside the list when the filter changes
    $: if ($FilteredVehicles.length === 0) {
        $FocusIndex = 0;
    } else if ($FocusIndex > $FilteredVehicles.length - 1) {
        $FocusIndex = $FilteredVehicles.length - 1;
    }

    $: FocusedVehicle = $FilteredVehicles[$FocusIndex] ?? null;
    $: InfoVehicle = $Vehicles.find((v) => v.Plate === $InfoPlate) ?? null;

    // Spawn the ghost preview of the focused vehicle (debounced so hovering doesn't spam)
    let PreviewTimer, LastPreview = null;
    $: if (Visible && State === "Loaded") QueuePreview(FocusedVehicle?.Plate ?? null);

    const QueuePreview = (Plate) => {
        clearTimeout(PreviewTimer);
        if (!Plate || Plate === LastPreview) return;
        PreviewTimer = setTimeout(() => {
            LastPreview = Plate;
            SendEvent("Garage/SpawnPreview", { Plate });
        }, 250);
    };

    const SetTab = (Direction) => {
        const Index = Tabs.indexOf($ActiveTab);
        $ActiveTab = Tabs[(Index + Direction + Tabs.length) % Tabs.length];
        $FocusIndex = 0;
        $MenuPlate = null;
    };

    const OpenMenu = (Plate) => {
        const Index = $FilteredVehicles.findIndex((v) => v.Plate === Plate);
        if (Index !== -1) $FocusIndex = Index;
        const Vehicle = $FilteredVehicles[Index];
        $MenuIndex = Vehicle && !CanRetrieve(Vehicle) ? 1 : 0;
        $MenuPlate = Plate;
    };

    const OpenInfo = (Plate) => {
        $MenuPlate = null;
        $InfoPlate = Plate;
    };

    const Retrieve = (Plate) => {
        const Vehicle = $Vehicles.find((v) => v.Plate === Plate);
        if (!CanRetrieve(Vehicle)) return;

        SendEvent("Garage/TakeVehicle", { Plate });
        CloseGarage(false);
    };

    const CloseGarage = (DeletePreview = true) => {
        if (!Visible) return;
        Visible = false;
        clearTimeout(PreviewTimer);
        LastPreview = null;
        ResetGarageState();
        SendEvent("Garage/Close", { DeletePreview });
    };

    const MoveFocus = (Delta) => {
        const Count = $FilteredVehicles.length;
        if (Count === 0) return;
        const Next = $FocusIndex + Delta;
        if (Next < 0 || Next > Count - 1) {
            // Left/right wrap, up/down clamp
            if (Math.abs(Delta) === 1) $FocusIndex = (Next + Count) % Count;
            return;
        }
        $FocusIndex = Next;
    };

    const OnKeyDown = (Event) => {
        if (!Visible || State !== "Loaded") return;

        const Typing = document.activeElement && document.activeElement.tagName === "INPUT";
        const Key = Event.key;

        if (Key === "Escape") {
            Event.preventDefault();
            if ($InfoPlate) return ($InfoPlate = null);
            if ($MenuPlate) return ($MenuPlate = null);
            if (Typing) return document.activeElement.blur();
            return CloseGarage();
        }

        if (Typing) {
            if (Key === "Enter" || Key === "ArrowDown") {
                Event.preventDefault();
                document.activeElement.blur();
            }
            return;
        }

        // Information modal
        if ($InfoPlate) {
            if (Key === "Enter" && InfoVehicle) Retrieve(InfoVehicle.Plate);
            return;
        }

        // Context menu
        if ($MenuPlate) {
            const Vehicle = $Vehicles.find((v) => v.Plate === $MenuPlate);
            if (Key === "ArrowUp" || Key === "ArrowDown") {
                Event.preventDefault();
                const Next = $MenuIndex === 0 ? 1 : 0;
                if (Next === 0 && !CanRetrieve(Vehicle)) return;
                $MenuIndex = Next;
            } else if (Key === "Enter") {
                $MenuIndex === 0 ? Retrieve($MenuPlate) : OpenInfo($MenuPlate);
            } else if (Key === "ArrowLeft" || Key === "ArrowRight" || Key === "Backspace") {
                $MenuPlate = null;
            }
            return;
        }

        switch (Key.toLowerCase()) {
            case "q": return SetTab(-1);
            case "e": return SetTab(1);
            case "arrowleft": Event.preventDefault(); return MoveFocus(-1);
            case "arrowright": Event.preventDefault(); return MoveFocus(1);
            case "arrowup": Event.preventDefault(); return MoveFocus(-COLUMNS);
            case "arrowdown": Event.preventDefault(); return MoveFocus(COLUMNS);
            case "enter": if (FocusedVehicle) OpenMenu(FocusedVehicle.Plate); return;
        }
    };

    onDestroy(() => clearTimeout(PreviewTimer));
</script>

<svelte:window on:keydown={OnKeyDown} />

<AppWrapper AppName="Garage" Focused={Visible}>
    {#if Visible}
        <div class="garage-wrapper">
            <div class="garage-column">
                <div class="garage-container" class:loading={State == "Loading"}>
                    {#if State == "Loading"}
                        <div class="loader">
                            <i class="fas fa-circle-notch fa-spin"></i>
                        </div>
                    {:else}
                        <GarageHeader Title={$GarageTitle} Label={$GarageLabel} bind:SearchTerm={$SearchTerm} />

                        <FilterTabs
                            bind:ActiveTab={$ActiveTab}
                            {Counts}
                            OnPrev={() => SetTab(-1)}
                            OnNext={() => SetTab(1)}
                        />

                        <VehicleGrid
                            Vehicles={$FilteredVehicles}
                            FocusIndex={$FocusIndex}
                            MenuPlate={$MenuPlate}
                            bind:MenuIndex={$MenuIndex}
                            HasSearch={$SearchTerm.trim().length > 0}
                            EmptyText={$EmptyText}
                            OnFocus={(i) => !$MenuPlate && ($FocusIndex = i)}
                            OnOpenMenu={OpenMenu}
                            OnRetrieve={Retrieve}
                            OnInfo={OpenInfo}
                        />

                        {#if InfoVehicle}
                            <InfoModal Vehicle={InfoVehicle} OnClose={() => ($InfoPlate = null)} OnRetrieve={Retrieve} />
                        {/if}
                    {/if}
                </div>

                <KeyHints />
            </div>
        </div>
    {/if}
</AppWrapper>

<style>
    .garage-wrapper {
        position: absolute;
        inset: 0;
        display: flex;
        justify-content: flex-end;
        pointer-events: none;
    }

    .garage-column {
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        width: 48vh;
        height: 100vh;
        margin-right: 3vh;
        padding-top: 2vh;
        box-sizing: border-box;

        /* Theme tokens, inherited by child components */
        --header: #15171b;
        --panel: #22252a;
        --card: #191b1f;
        --card-hover: #1d2025;
        --input: #2c3036;
        --text: #f2f3f5;
        --text-muted: rgba(242, 243, 245, 0.55);
        --edge: rgba(255, 255, 255, 0.07);
        --stored: #3fe079;
        --out: #f5c542;
        --impounded: #ff8a34;

        font-family: "Barlow Condensed", "Roboto Condensed", Arial, sans-serif;
        font-weight: 600;
        color: var(--text);
        user-select: none;
    }

    .garage-container {
        position: relative;
        display: flex;
        flex-direction: column;
        flex: 1;
        min-height: 0;
        overflow: hidden;
        background: rgba(34, 37, 42, 0.97);
        border-radius: 0.3vh;
        box-shadow: 0 0 2vh rgba(0, 0, 0, 0.45);
        pointer-events: auto;
        animation: slide-in 0.25s ease-out;
    }

    .garage-container.loading {
        flex: 0 0 18vh;
        margin-bottom: auto;
    }

    .garage-column :global(.key-hints) {
        pointer-events: auto;
    }

    .loader {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 4vh;
        color: var(--text-muted);
    }

    @keyframes slide-in {
        from { opacity: 0; transform: translateX(2vh); }
        to { opacity: 1; transform: none; }
    }
</style>
