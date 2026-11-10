<script>
    import Button from "../../../lib/Button/Button.svelte";

    export let Vehicle = null;
    export let OnTakeVehicle = () => {};

    $: Engine = Vehicle?.Stats ? Math.ceil(Vehicle.Stats.Engine / 10) : null;
    $: Body = Vehicle?.Stats ? Math.ceil(Vehicle.Stats.Body / 10) : null;
    $: IsDepot = Vehicle?.State === "Depot";
    $: CanTake = Vehicle?.State === "in";
</script>

{#if Vehicle}
    <div class="garage-panel">
        <div class="garage-panel-header">
            <p class="garage-panel-title">{Vehicle.Name}</p>
            <span class="garage-panel-plate">{Vehicle.Plate}</span>
        </div>

        <div class="garage-stat-row">
            <div class="garage-stat">
                <span class="garage-stat-label">Status</span>
                <span class="garage-stat-value">{IsDepot ? "Impounded" : Vehicle.State}</span>
            </div>
            <div class="garage-stat">
                <span class="garage-stat-label">Engine</span>
                <span class="garage-stat-value">{Engine}%</span>
            </div>
            <div class="garage-stat">
                <span class="garage-stat-label">Body</span>
                <span class="garage-stat-value">{Body}%</span>
            </div>
        </div>

        <div class="garage-actions">
            <Button Color="success" Disabled={!CanTake} on:click={() => OnTakeVehicle(Vehicle.Plate)}>
                Take out
            </Button>
            <Button Color="default" on:click={() => OnToggleLockdown(Vehicle.Plate)}>
                {Vehicle.Locked ? "Ontgrendelen" : "Vergrendelen"}
            </Button>
        </div>
    </div>
{/if}

<style>
    .garage-panel {
        border-top: 0.1vh solid rgba(94, 196, 184, 0.14);
        padding: 1.6vh 2.2vh;
        display: flex;
        flex-direction: column;
        gap: 1.4vh;
    }

    .garage-panel-header {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
    }

    .garage-panel-title {
        font-size: 1.5vh;
        font-weight: 700;
        color: white;
        margin: 0;
        font-family: Roboto;
    }

    .garage-panel-plate {
        font-size: 1.1vh;
        color: #5e8a86;
        letter-spacing: 0.04em;
        font-family: Roboto;
    }

    .garage-stat-row {
        display: flex;
        gap: 1.8vh;
    }

    .garage-stat {
        display: flex;
        flex-direction: column;
        gap: 0.2vh;
    }

    .garage-stat-label {
        font-size: 1vh;
        color: #5e8a86;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        font-family: Roboto;
    }

    .garage-stat-value {
        font-size: 1.3vh;
        color: #b9d4d1;
        font-weight: 600;
        font-family: Roboto;
    }

    .garage-actions {
        display: flex;
        gap: 0.8vh;
    }
</style>