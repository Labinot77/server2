<script>
    import { OnEvent, SetExitHandler, SendEvent as _SendEvent } from "../../utils/Utils";
    const SendEvent = (Event, Parameters, Callback) => _SendEvent(Event, Parameters, Callback, "fw-vehicles");

    import AppWrapper from "../../components/AppWrapper.svelte";
    import GarageHeader from "./components/GarageHeader.svelte";
    import VehicleGrid from "./components/VehicleGrid.svelte";
    import VehicleActionPanel from "./components/VehicleActionPanel.svelte";

    import {
        GarageLabel,
        Vehicles,
        SelectedPlate,
        FilteredVehicles,
        ModalData,
        ResetGarageState,
    } from "./garage.js";

    const Modals = {};

    let Visible = false;
    let State = "Loaded";

    OnEvent("Garage", "SetVisibility", (Data) => {
        if (!Data.Visible) {
            Visible = false;
            ResetGarageState();
            return;
        }

        GarageLabel.set(Data.Label || "Development Garage");
        Vehicles.set(Data.Vehicles || []);

        State = "Loading";
        Visible = true;
        setTimeout(() => {
            State = "Loaded";
        }, 600);
    });

    OnEvent("Garage", "SetVehicles", (Data) => {
        Vehicles.set(Data.Vehicles || []);
    });

    $: SelectedVehicle = $Vehicles.find((v) => v.Plate === $SelectedPlate) ?? null;

const HandleSelect = (Plate) => {
    $SelectedPlate = $SelectedPlate === Plate ? null : Plate;

    if ($SelectedPlate) {
        SendEvent("Garage/SpawnPreview", { Plate: $SelectedPlate });
    }
};

const HandleTakeVehicle = (Plate) => {
    const Vehicle = $Vehicles.find((v) => v.Plate === Plate);
    if (!Vehicle || Vehicle.State !== "Stored") return;

    SendEvent("Garage/TakeVehicle", { Plate });
    CloseGarage();
};

    const HandleToggleLockdown = (Plate) => {
        SendEvent("Garage/ToggleLockdown", { Plate });
    };

    const CloseGarage = () => {
        Visible = false;
        ResetGarageState();
        SendEvent("Garage/Close", {});
    };

    SetExitHandler("", "Garage/Close", () => CloseGarage(), {__resource: "fw-vehicles"});
</script>

<AppWrapper AppName="Garage" Focused={Visible}>
    {#if Visible}
        <div class="garage-wrapper">
            <div class="garage-container" class:loading={State == "Loading"}>
                {#if State == "Loading"}
                    <div style="display: flex; justify-content: center; align-items: center; height: 20vh; width: 100%;">
                       <svg xmlns="http://www.w3.org/2000/svg" class="spinner" width="15vh" height="15vh" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid">
    {#each Array(12) as _, i}
        <g transform="rotate({i * 30} 50 50)">
            <rect x="47.5" y="24" rx="1.92" ry="1.92" width="5" height="12" fill="var(--accent)">
                <animate attributeName="opacity" values="1;0" keyTimes="0;1" dur="1s" begin="{-(11 - i) / 12}s" repeatCount="indefinite"></animate>
            </rect>
        </g>
    {/each}
</svg>
                    </div>
                {:else}
                    {#if $ModalData.Type && Modals[$ModalData.Type] && $ModalData.Show}
                        <svelte:component this={Modals[$ModalData.Type]} />
                    {/if}

                    <GarageHeader
                        Breadcrumb={$GarageLabel}
                        Count={$Vehicles.length}
                        Total={$Vehicles.length}
                        OnExit={CloseGarage}
                    />

                    <!-- <SearchBar bind:SearchTerm={$SearchTerm} bind:ActiveTab={$ActiveTab} /> -->

                    <VehicleGrid
                        Vehicles={$FilteredVehicles}
                        SelectedPlate={$SelectedPlate}
                        OnSelect={HandleSelect}
                        OnTakeVehicle={HandleTakeVehicle}
                    />

                    <VehicleActionPanel
                        Vehicle={SelectedVehicle}
                        OnTakeVehicle={HandleTakeVehicle}
                        OnToggleLockdown={HandleToggleLockdown}
                    />
                {/if}
            </div>
        </div>
    {/if}
</AppWrapper>

<style>
    .garage-wrapper {
        display: flex;
        position: absolute;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        overflow: hidden;
        margin: 0;
        align-items: center;
        justify-content: end;
        pointer-events: none;
    }

    .garage-container {
        /* Theme tokens, inherited by child components */
        --accent: #13dff2;
        --accent-success: #43df78;
        --accent-error: #ff4e55;
        --panel: rgba(14, 14, 14, 0.8);
        --panel-solid: rgba(19, 18, 18, 0.96);
        --text: #f4f4f4;
        --text-muted: rgba(244, 244, 244, 0.6);
        --edge: rgba(255, 255, 255, 0.08);

        display: flex;
        flex-direction: column;
        position: relative;
        overflow: hidden;
        width: 45vh;
        height: 75vh;
        margin-right: 2.5vh;

        background: var(--panel);
        border: 0.1vh solid var(--edge);
        border-bottom: 0.3vh solid color-mix(in srgb, var(--accent) 45%, transparent);
        border-radius: 0.3vh;
        box-shadow: 0 0 1vh rgba(0, 0, 0, 0.4);

        font-family: 'Roboto Condensed', Arial, sans-serif;
        font-weight: 500;
        color: var(--text);
        text-shadow: 0 2px 2px rgba(0, 0, 0, 0.75);
        user-select: none;
        pointer-events: auto;

        transition: height 800ms ease 0s;
    }

    .garage-container.loading {
        height: 20vh;
    }

    .spinner {
        margin: auto;
        display: block;
        filter: drop-shadow(0 0 0.6vh var(--accent));
    }
</style>