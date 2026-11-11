<script>
    import { Tabs } from "../garage.js";

    export let ActiveTab = "All";
    export let Counts = {};
    export let OnPrev = () => {};
    export let OnNext = () => {};
</script>

<div class="filter-tabs">
    <button class="key" tabindex="-1" on:click={OnPrev}>Q</button>

    <div class="tabs">
        {#each Tabs as Tab}
            <button
                class="tab"
                class:active={ActiveTab === Tab}
                tabindex="-1"
                on:click={() => (ActiveTab = Tab)}
            >
                {Tab}
                {#if Counts[Tab] !== undefined}<span class="count">{Counts[Tab]}</span>{/if}
            </button>
        {/each}
    </div>

    <button class="key" tabindex="-1" on:click={OnNext}>E</button>
</div>

<style>
    .filter-tabs {
        display: flex;
        align-items: center;
        gap: 1.4vh;
        padding: 1.4vh 2vh 1.6vh;
        border-bottom: 0.1vh solid var(--edge);
    }

    .key {
        flex-shrink: 0;
        width: 2.1vh;
        height: 2.1vh;
        padding: 0;
        border: none;
        border-radius: 0.2vh;
        background: var(--text);
        color: #111;
        font-family: inherit;
        font-size: 1.25vh;
        font-weight: 700;
        cursor: pointer;
    }

    .tabs {
        flex: 1;
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1vh;
    }

    .tab {
        height: 3.2vh;
        border: none;
        border-radius: 0.2vh;
        background: transparent;
        color: var(--text);
        font-family: inherit;
        font-size: 1.4vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        letter-spacing: 0.05vh;
        cursor: pointer;
        transition: background 0.15s ease, color 0.15s ease;
    }

    .tab:hover:not(.active) {
        background: rgba(255, 255, 255, 0.06);
    }

    .tab.active {
        background: var(--text);
        color: #111;
    }

    .count {
        margin-left: 0.4vh;
        font-size: 1.1vh;
        opacity: 0.55;
    }
</style>
