<script>
    // Icon columns next to a grid / slider view, so you can jump between categories without going back.
    import Icon from "./Icon.svelte";
    import { IconFor } from "../menu";

    export let Path = [];
    export let Folders = [];   // apparel only: folder names
    export let Items = [];     // items of the current folder / tab
    export let FolderItems = {}; // apparel only: folder -> items
    export let Navigate = (NewPath) => {};
</script>

{#if Folders.length > 0}
    <div class="rail">
        {#each Folders as Folder (Folder)}
            <button
                class="rail-btn folder" class:active={Path[1] == Folder} title={Folder}
                on:click={() => Navigate([Path[0], Folder, (FolderItems[Folder] || [])[0]])}
            ><Icon Name={IconFor(Folder)} /></button>
        {/each}
    </div>
{/if}

{#if Items.length > 0}
    <div class="rail scroll" style="max-height: 760px;">
        {#each Items as Item (Item)}
            <button
                class="rail-btn" class:active={Path[Path.length - 1] == Item} title={Item}
                on:click={() => Navigate([...Path.slice(0, -1), Item])}
            ><Icon Name={IconFor(Item)} /></button>
        {/each}
    </div>
{/if}
