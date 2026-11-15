<script>
    import { Glyphs, Tiles } from "../icons";

    export let Label = "";
    export let Icon = "question";
    export let Tile = "dark";
    export let Svg = false;
    export let Tooltip = "";
    export let HasUnread = false;

    $: [Bg, Fg, Cut] = Tiles[Tile] || Tiles.dark;
</script>

<div class="app" data-tooltip={Tooltip || null} on:keyup on:click>
    <div class="tile" class:dark={Tile == "dark"} style="background: {Bg}; color: {Fg}; --cut: {Cut}">
        {#if Svg && Glyphs[Svg]}
            <svg class="glyph" class:wide={Svg == "news"} viewBox="0 0 48 48">{@html Glyphs[Svg]}</svg>
        {:else}
            <i class="fas fa-{Icon}" />
        {/if}
        {#if HasUnread}<span class="badge" />{/if}
    </div>
    <p>{Label}</p>
</div>

<style>
    .app {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.5vh;
        cursor: pointer;
        transition: transform 120ms;
    }

    .app:hover { transform: translateY(-0.17vh); }
    .app:active { transform: scale(0.94); }

    .tile {
        position: relative;
        width: 4.4vh;
        height: 4.4vh;
        border-radius: 1.26vh;
        display: grid;
        place-items: center;
        font-size: 1.9vh;
        box-shadow: 0 0.5vh 1.2vh rgba(0, 0, 0, 0.3), inset 0 0.08vh 0 rgba(255, 255, 255, 0.14);
    }

    .tile.dark { backdrop-filter: blur(0.7vh); border: 0.08vh solid rgba(255, 255, 255, 0.04); }

    .glyph { width: 3.2vh; height: 3.2vh; fill: currentColor; overflow: visible; }
    .glyph.wide { width: 3.9vh; height: 3.9vh; }
    .glyph :global(.cut) { fill: var(--cut); }

    .badge {
        position: absolute;
        top: -0.42vh;
        right: -0.42vh;
        width: 1.3vh;
        height: 1.3vh;
        border-radius: 50%;
        background: #ff4d4f;
        box-shadow: 0 0.17vh 0.5vh rgba(0, 0, 0, 0.4);
    }

    p {
        margin: 0;
        font-family: Inter, Roboto, sans-serif;
        font-size: 0.89vh;
        font-weight: 500;
        color: #e8eaee;
        white-space: nowrap;
        text-shadow: 0 0.08vh 0.34vh rgba(0, 0, 0, 0.6);
    }
</style>
