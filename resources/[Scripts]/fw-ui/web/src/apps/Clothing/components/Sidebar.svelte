<script>
    import Header from "./Header.svelte";
    import Icon from "./Icon.svelte";
    import { IconFor } from "../menu";

    export let Path = [];
    export let Items = [];
    export let Navigate = (NewPath) => {};
</script>

<div class="column enter" style="width: 440px;">
    <Header {Path} {Navigate} />

    <div class="list scroll">
        {#each Items as Item (Item)}
            <button class="entry" class:active={Path[Path.length - 1] == Item} on:click={() => Navigate([...Path, Item])}>
                <Icon Name={IconFor(Item)} Size={24} />
                <span>{Item}</span>
            </button>
        {/each}
    </div>
</div>

<style>
    .list { display: flex; flex-direction: column; gap: 2px; max-height: 800px; }

    .entry {
        display: flex; align-items: center; gap: 16px; width: 100%; padding: 12px 20px;
        background: rgba(20, 22, 27, 0.8) !important; color: white !important;
        border-left: 2px solid rgba(255, 255, 255, 0.7) !important; transition: background .15s, color .15s;
    }
    .entry:hover, .entry.active { background: white !important; color: black !important; border-left-color: white !important; }
    .entry span { font-size: 22px; letter-spacing: 0.025em; text-transform: uppercase; font-style: italic; font-weight: 700; }
</style>
