<script>
    import VehicleImage from "./VehicleImage.svelte";
    import { GetImage, Percent, StatusClass, CanRetrieve as CanTake, RetrieveLabel } from "../garage.js";

    export let Vehicle;
    export let OnClose = () => {};
    export let OnRetrieve = () => {};

    $: CanRetrieve = CanTake(Vehicle);
    $: Rows = [
        { Label: "Vehicle Plate", Value: Vehicle.Plate },
        { Label: "Vehicle Status", Value: Vehicle.State, Class: StatusClass(Vehicle.State) },
        { Label: "Ownership", Value: Vehicle.Type || "Personal" },
        { Label: "Vehicle Seats", Value: Vehicle.Seats ?? "--" },
        { Label: "Fuel", Value: Percent(Vehicle.Stats?.Fuel) },
        { Label: "Engine", Value: Percent(Vehicle.Stats?.Engine, 1000) },
        { Label: "Body", Value: Percent(Vehicle.Stats?.Body, 1000) },
        ...(Vehicle.Details || []),
    ];
</script>

<div class="backdrop" on:click|self={OnClose} on:keydown={() => {}} role="presentation">
    <div class="modal" role="dialog">
        <div class="modal-header">
            <p class="modal-title">{Vehicle.Name}</p>
            <button class="close" tabindex="-1" on:click={OnClose}><i class="fas fa-times"></i></button>
        </div>

        <div class="modal-image">
            <VehicleImage Src={GetImage(Vehicle)} Alt={Vehicle.Name} IconSize="7vh" />
        </div>

        <div class="rows">
            {#each Rows as Row}
                <div class="row">
                    <span class="row-label">{Row.Label}</span>
                    <span class="row-value {Row.Class || ''}">{Row.Value}</span>
                </div>
            {/each}
        </div>

        <button class="retrieve" tabindex="-1" disabled={!CanRetrieve} on:click={() => OnRetrieve(Vehicle.Plate)}>
            {RetrieveLabel(Vehicle)}
        </button>
    </div>
</div>

<style>
    .backdrop {
        position: absolute;
        inset: 0;
        z-index: 10;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(0, 0, 0, 0.55);
        backdrop-filter: blur(0.4vh);
        animation: fade 0.15s ease-out;
    }

    .modal {
        width: 82%;
        padding: 1.8vh;
        background: var(--panel);
        border: 0.1vh solid var(--edge);
        border-radius: 0.3vh;
        box-shadow: 0 1vh 3vh rgba(0, 0, 0, 0.5);
        animation: pop 0.18s ease-out;
    }

    .modal-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1vh;
    }

    .modal-title {
        margin: 0;
        font-size: 2vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .close {
        background: none;
        border: none;
        padding: 0.2vh;
        color: var(--text-muted);
        font-size: 1.8vh;
        cursor: pointer;
    }

    .close:hover {
        color: var(--text);
    }

    .modal-image {
        height: 14vh;
        margin: 1.4vh 0;
        padding: 1vh;
        background: var(--card);
        border: 0.1vh solid var(--edge);
    }

    .rows {
        display: flex;
        flex-direction: column;
        max-height: 46vh;
        overflow-y: auto;
    }

    .rows::-webkit-scrollbar {
        display: none;
    }

    .row {
        display: flex;
        justify-content: space-between;
        gap: 2vh;
        padding: 1vh 0.4vh;
        border-bottom: 0.1vh solid var(--edge);
        font-size: 1.3vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
    }

    .row-label {
        flex-shrink: 0;
        color: var(--text-muted);
    }

    .row-value {
        text-align: right;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .row-value.stored { color: var(--stored); }
    .row-value.out { color: var(--out); }
    .row-value.impounded { color: var(--impounded); }

    .retrieve {
        width: 100%;
        height: 4vh;
        margin-top: 1.8vh;
        border: none;
        border-radius: 0.1vh;
        background: var(--text);
        color: #111;
        font-family: inherit;
        font-size: 1.45vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        cursor: pointer;
        transition: opacity 0.12s ease;
    }

    .retrieve:hover:not(:disabled) {
        opacity: 0.88;
    }

    .retrieve:disabled {
        opacity: 0.35;
        cursor: not-allowed;
    }

    @keyframes fade {
        from { opacity: 0; }
        to { opacity: 1; }
    }

    @keyframes pop {
        from { opacity: 0; transform: translateY(1vh) scale(0.97); }
        to { opacity: 1; transform: none; }
    }
</style>
