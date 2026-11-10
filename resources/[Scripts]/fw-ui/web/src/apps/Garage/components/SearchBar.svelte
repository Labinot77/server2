<script>
    export let SearchTerm = "";
    export let ActiveTab = "All";

    const Tabs = ["All", "Personal", "Job"];
</script>

<div class="garage-search-row">
    <div class="garage-search-box">
        <i class="fas fa-search"></i>
        <input type="text" placeholder="Search an automobile" bind:value={SearchTerm} />
    </div>

    <div class="garage-tabs">
        {#each Tabs as Tab}
            <button
                class="garage-tab"
                class:active={ActiveTab === Tab}
                on:click={() => (ActiveTab = Tab)}
            >
                {Tab.toUpperCase()}
            </button>
        {/each}
    </div>
</div>

<style>
    .garage-search-row {
        display: flex;
        align-items: center;
        gap: 1.2vh;
        padding: 1.6vh 2.2vh;
    }

    .garage-search-box {
        flex: 1;
        display: flex;
        align-items: center;
        gap: 1vh;
        background: #102a2e;
        border: 0.1vh solid rgba(94, 196, 184, 0.14);
        border-radius: 0.8vh;
        padding: 1vh 1.4vh;
    }

    .garage-search-box i {
        font-size: 1.4vh;
        color: #5e8a86;
    }

    .garage-search-box input {
        flex: 1;
        background: transparent;
        border: none;
        outline: none;
        color: white;
        font-size: 1.4vh;
        font-family: Roboto;
    }

    .garage-search-box input::placeholder {
        color: #5e8a86;
    }

    .garage-tabs {
        display: flex;
        background: #102a2e;
        border: 0.1vh solid rgba(94, 196, 184, 0.14);
        border-radius: 0.8vh;
        padding: 0.3vh;
        gap: 0.2vh;
    }

    .garage-tab {
        font-size: 1.2vh;
        font-weight: 600;
        letter-spacing: 0.03em;
        padding: 0.8vh 1.5vh;
        border-radius: 0.6vh;
        border: none;
        background: transparent;
        color: #5e8a86;
        cursor: pointer;
        font-family: Roboto;
        transition: background 0.15s ease, color 0.15s ease;
        white-space: nowrap;
    }

    .garage-tab:hover {
        color: #b9d4d1;
    }

    .garage-tab.active {
        background: rgba(79, 216, 196, 0.12);
        color: #4fd8c4;
    }
</style>