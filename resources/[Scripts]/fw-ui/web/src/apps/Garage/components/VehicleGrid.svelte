<script>
    import VehicleCard from "./Card.svelte";

    export let Vehicles = [];
    export let SelectedPlate = null;
    export let OnSelect = () => {};
</script>

<div class="garage-grid-wrap">
    {#if Vehicles.length === 0}
        <div class="garage-misc-empty">
            <i class="fas fa-frown"></i>
            <p>You have no vehicles in this garage.</p>
        </div>
    {:else}
        <div class="garage-grid">
            {#each Vehicles as Vehicle (Vehicle.Plate)}
                <VehicleCard
                    {...Vehicle}
                    Selected={SelectedPlate === Vehicle.Plate}
                    {OnSelect}
                />
            {/each}
        </div>
    {/if}
</div>

<style>
    .garage-grid-wrap {
        flex: 1 1 0%;
        overflow-y: auto;
        padding: 0.6vh 2.2vh 2vh;
    }

    .garage-grid-wrap::-webkit-scrollbar {
        display: none;
    }

    .garage-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(15vh, 1fr));
        gap: 1.4vh;
    }

    .garage-misc-empty {
        position: relative;
        left: 0;
        right: 0;
        text-align: center;
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .garage-misc-empty > i {
        font-size: 4.5vh;
    }

    .garage-misc-empty > p {
        margin-top: 3.3vh;
        font-size: 1.8vh;
        font-weight: bold;
        font-family: Roboto;
    }
</style>