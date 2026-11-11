<script>
    import Card from "./Card.svelte";

    export let Vehicles = [];
    export let FocusIndex = 0;
    export let MenuPlate = null;
    export let MenuIndex = 0;
    export let HasSearch = false;
    export let EmptyText = "";
    export let OnFocus = () => {};
    export let OnOpenMenu = () => {};
    export let OnRetrieve = () => {};
    export let OnInfo = () => {};
</script>

<div class="grid-wrap">
    {#if Vehicles.length === 0}
        <div class="empty">
            <i class="fas fa-car-side"></i>
            <p>{HasSearch ? "No vehicles match your search" : EmptyText || "No vehicles in this garage"}</p>
        </div>
    {:else}
        <div class="grid">
            {#each Vehicles as Vehicle, i (Vehicle.Plate)}
                <Card
                    {Vehicle}
                    Focused={FocusIndex === i}
                    MenuOpen={MenuPlate === Vehicle.Plate}
                    bind:MenuIndex
                    OnFocus={() => OnFocus(i)}
                    {OnOpenMenu}
                    {OnRetrieve}
                    {OnInfo}
                />
            {/each}
        </div>
    {/if}
</div>

<style>
    .grid-wrap {
        flex: 1 1 0%;
        min-height: 0;
        overflow-y: auto;
        padding: 1.8vh 2vh;
    }

    .grid-wrap::-webkit-scrollbar {
        width: 0.4vh;
    }

    .grid-wrap::-webkit-scrollbar-thumb {
        background: rgba(255, 255, 255, 0.15);
        border-radius: 0.4vh;
    }

    .grid {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 1.2vh;
    }

    .empty {
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1.4vh;
        color: var(--text-muted);
    }

    .empty i {
        font-size: 5vh;
        opacity: 0.5;
    }

    .empty p {
        margin: 0;
        font-size: 1.6vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
    }
</style>
