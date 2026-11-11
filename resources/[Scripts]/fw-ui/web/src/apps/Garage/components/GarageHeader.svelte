<script>
    export let Title = "Garage Manager";
    export let Label = "";
    export let SearchTerm = "";
</script>

<div class="garage-header">
    <div class="garage-header-title">
        <p class="title">{Title}</p>
        {#if Label}<p class="label">{Label}</p>{/if}
    </div>

    <label class="garage-search">
        <i class="fas fa-search"></i>
        <input type="text" placeholder="Search" spellcheck="false" bind:value={SearchTerm} />
        {#if SearchTerm.length > 0}
            <button class="clear" tabindex="-1" on:click={() => (SearchTerm = "")}>
                <i class="fas fa-times"></i>
            </button>
        {/if}
    </label>
</div>

<style>
    .garage-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 2vh;
        padding: 1.8vh 2vh;
        background: var(--header);
    }

    .garage-header-title {
        display: flex;
        flex-direction: column;
        min-width: 0;
    }

    .title {
        margin: 0;
        font-size: 2.6vh;
        font-weight: 700;
        font-style: italic;
        letter-spacing: 0.05vh;
        text-transform: uppercase;
        line-height: 1;
        white-space: nowrap;
    }

    .label {
        margin: 0.4vh 0 0 0;
        font-size: 1.2vh;
        font-weight: 600;
        font-style: italic;
        text-transform: uppercase;
        color: var(--text-muted);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .garage-search {
        flex: 0 0 52%;
        display: flex;
        align-items: center;
        gap: 1vh;
        height: 3.4vh;
        padding: 0 1.2vh;
        background: var(--input);
        border: 0.1vh solid transparent;
        border-radius: 0.3vh;
        cursor: text;
        transition: border-color 0.15s ease;
    }

    .garage-search:focus-within {
        border-color: rgba(255, 255, 255, 0.25);
    }

    .garage-search > i {
        font-size: 1.3vh;
        color: var(--text-muted);
    }

    input {
        flex: 1;
        min-width: 0;
        background: transparent;
        border: none;
        outline: none;
        color: var(--text);
        font-family: inherit;
        font-size: 1.45vh;
        font-weight: 600;
        font-style: italic;
    }

    input::placeholder {
        color: var(--text-muted);
    }

    .clear {
        background: none;
        border: none;
        padding: 0;
        color: var(--text-muted);
        font-size: 1.2vh;
        cursor: pointer;
    }

    .clear:hover {
        color: var(--text);
    }
</style>
