<script>
    import VehicleImage from "./VehicleImage.svelte";
    import { GetImage, Percent, StatusClass, CanRetrieve as CanTake, RetrieveLabel } from "../garage.js";

    export let Vehicle;
    export let Focused = false;
    export let MenuOpen = false;
    export let MenuIndex = 0;
    export let OnFocus = () => {};
    export let OnOpenMenu = () => {};
    export let OnRetrieve = () => {};
    export let OnInfo = () => {};

    let Element;
    $: if (Focused && Element) Element.scrollIntoView({ block: "nearest", behavior: "smooth" });

    $: CanRetrieve = CanTake(Vehicle);
    $: Options = [
        { Label: CanRetrieve || Vehicle.State !== "Impounded" ? "Retrieve Vehicle" : RetrieveLabel(Vehicle), Disabled: !CanRetrieve, Action: () => OnRetrieve(Vehicle.Plate) },
        { Label: "Information", Disabled: false, Action: () => OnInfo(Vehicle.Plate) },
    ];
</script>

<div
    class="card"
    class:focused={Focused}
    bind:this={Element}
    on:mouseenter={OnFocus}
    on:click={() => !MenuOpen && OnOpenMenu(Vehicle.Plate)}
    role="button"
    tabindex="-1"
    on:keydown={() => {}}
>
    <div class="card-top">
        <div class="card-title">
            <p class="name" title={Vehicle.Name}>{Vehicle.Name}</p>
            <p class="status {StatusClass(Vehicle.State)}">{Vehicle.State}</p>
        </div>
        <div class="plate">
            <span class="plate-state">San Andreas</span>
            <span class="plate-text">{Vehicle.Plate}</span>
        </div>
    </div>

    <div class="card-image">
        <VehicleImage Src={GetImage(Vehicle)} Alt={Vehicle.Name} IconSize="4.2vh" />
    </div>

    <div class="card-stats">
        <span>Fuel <b>{Percent(Vehicle.Stats?.Fuel)}</b></span>
        <span>Engine <b>{Percent(Vehicle.Stats?.Engine, 1000)}</b></span>
        <span>Body <b>{Percent(Vehicle.Stats?.Body, 1000)}</b></span>
    </div>

    {#if MenuOpen}
        <div class="card-menu" on:click|stopPropagation on:keydown={() => {}} role="menu" tabindex="-1">
            {#each Options as Option, i}
                <button
                    class="menu-option"
                    class:active={MenuIndex === i}
                    disabled={Option.Disabled}
                    tabindex="-1"
                    on:mouseenter={() => (MenuIndex = i)}
                    on:click={Option.Action}
                >
                    {Option.Label}
                </button>
            {/each}
        </div>
    {/if}
</div>

<style>
    .card {
        position: relative;
        display: flex;
        flex-direction: column;
        min-width: 0;
        height: 13vh;
        padding: 0.9vh 1vh 0.8vh;
        background: var(--card);
        border: 0.1vh solid transparent;
        border-radius: 0.2vh;
        cursor: pointer;
        transition: border-color 0.12s ease, background 0.12s ease;
    }

    .card.focused {
        border-color: rgba(255, 255, 255, 0.55);
        background: var(--card-hover);
    }

    .card-top {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 0.6vh;
    }

    .card-title {
        min-width: 0;
    }

    .name {
        margin: 0;
        font-size: 1.45vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        line-height: 1.1;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .status {
        margin: 0.15vh 0 0 0;
        font-size: 1.1vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
    }

    .status.stored { color: var(--stored); }
    .status.out { color: var(--out); }
    .status.impounded { color: var(--impounded); }

    .plate {
        flex-shrink: 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 0.15vh 0.5vh 0.2vh;
        background: #e9ebee;
        border-radius: 0.25vh;
        color: #2a2f3a;
        line-height: 1;
    }

    .plate-state {
        font-size: 0.6vh;
        font-weight: 700;
        text-transform: uppercase;
        color: #8a93a3;
        letter-spacing: 0.03vh;
    }

    .plate-text {
        margin-top: 0.1vh;
        font-size: 1.2vh;
        font-weight: 700;
        letter-spacing: 0.08vh;
    }

    .card-image {
        flex: 1;
        min-height: 0;
        padding: 0.4vh 0;
    }

    .card-stats {
        display: flex;
        justify-content: space-between;
        gap: 0.4vh;
        font-size: 0.95vh;
        font-weight: 600;
        font-style: italic;
        text-transform: uppercase;
        color: var(--text-muted);
        white-space: nowrap;
    }

    .card-stats b {
        color: var(--text);
        font-weight: 700;
    }

    /* Context menu covering the card */
    .card-menu {
        position: absolute;
        inset: -0.1vh;
        z-index: 2;
        display: flex;
        flex-direction: column;
        justify-content: center;
        gap: 1vh;
        padding: 1vh;
        background: var(--panel);
        border: 0.1vh solid rgba(255, 255, 255, 0.35);
        border-radius: 0.2vh;
        cursor: default;
        animation: menu-in 0.12s ease-out;
    }

    .menu-option {
        height: 3.3vh;
        border: 0.1vh solid rgba(255, 255, 255, 0.45);
        border-radius: 0.1vh;
        background: transparent;
        color: var(--text);
        font-family: inherit;
        font-size: 1.3vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        cursor: pointer;
        transition: background 0.1s ease, color 0.1s ease;
    }

    .menu-option.active:not(:disabled) {
        background: var(--text);
        color: #111;
        border-color: var(--text);
    }

    .menu-option:disabled {
        opacity: 0.35;
        cursor: not-allowed;
    }

    @keyframes menu-in {
        from { opacity: 0; transform: scale(0.96); }
        to { opacity: 1; transform: scale(1); }
    }
</style>
