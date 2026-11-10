<script>
    import { createEventDispatcher } from "svelte";

    export let Label = "";
    export let Description = "";
    export let Icon = "fas fa-wrench";
    export let Swatch = null;      // Hex colour shown instead of the icon
    export let Selected = false;
    export let FooterLeft = "Open Selection";
    export let FooterRight = null;  // null = arrow
    export let Installed = false;

    const Dispatch = createEventDispatcher();
</script>

<button class="item-card" class:selected={Selected} on:click={() => Dispatch("select")}>
    <div class="item-visual">
        {#if Swatch}
            <div class="item-swatch" style="background-color: {Swatch}"></div>
        {/if}
        <i class="{Icon} item-icon" class:with-swatch={Swatch}></i>
        {#if Installed}
            <span class="item-badge"><i class="fas fa-check"></i></span>
        {/if}
        <div class="item-text">
            <p class="item-label">{Label}</p>
            <p class="item-description">{Description}</p>
        </div>
    </div>

    <div class="item-footer">
        <span>{FooterLeft}</span>
        {#if FooterRight !== null}
            <span class="item-price">{FooterRight}</span>
        {:else}
            <i class="fal fa-long-arrow-right"></i>
        {/if}
    </div>
</button>

<style>
    .item-card {
        all: unset;
        cursor: pointer;
        flex: 0 0 auto;
        display: flex;
        flex-direction: column;

        width: 15.2vh;
        height: 18.4vh;
        margin-right: 0.9vh;

        font-family: "Barlow Semi Condensed", sans-serif;
        color: white;

        transition: transform 120ms ease;
    }

    .item-card:hover { transform: translateY(-0.35vh); }

    .item-visual {
        position: relative;
        flex: 1;
        overflow: hidden;

        background: radial-gradient(circle at 50% 35%, rgba(255, 255, 255, 0.08), transparent 70%), var(--bennys-panel);
        border-bottom: 0.2vh solid transparent;

        transition: background 150ms ease, border-color 150ms ease;
    }

    .item-card:hover .item-visual {
        background: radial-gradient(circle at 50% 35%, rgba(63, 216, 230, 0.18), transparent 70%), var(--bennys-panel-hover);
        border-color: var(--bennys-accent);
    }

    .item-card.selected .item-visual {
        background: linear-gradient(160deg, var(--bennys-accent) 0%, var(--bennys-accent-dark) 100%);
        border-color: white;
    }

    .item-icon {
        position: absolute;
        top: 30%;
        left: 50%;
        transform: translate(-50%, -50%);

        font-size: 4.6vh;
        color: white;
        text-shadow: 0 0.4vh 1.2vh rgba(0, 0, 0, 0.5);
    }

    .item-icon.with-swatch {
        font-size: 1.6vh;
        top: 30%;
        color: rgba(255, 255, 255, 0.9);
    }

    .item-swatch {
        position: absolute;
        top: 30%;
        left: 50%;
        transform: translate(-50%, -50%);

        width: 6.4vh;
        height: 6.4vh;
        border-radius: 50%;
        border: 0.25vh solid rgba(255, 255, 255, 0.85);
        box-shadow: 0 0.4vh 1.4vh rgba(0, 0, 0, 0.6);
    }

    .item-badge {
        position: absolute;
        top: 0.8vh;
        right: 0.8vh;

        display: flex;
        align-items: center;
        justify-content: center;
        width: 2vh;
        height: 2vh;

        font-size: 1.05vh;
        color: black;
        background: white;
    }

    .item-text {
        position: absolute;
        left: 1.1vh;
        right: 1.1vh;
        bottom: 1vh;
    }

    .item-label {
        font-size: 1.55vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        letter-spacing: 0.02vh;
        line-height: 1.1;

        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .item-description {
        margin-top: 0.2vh;
        font-size: 1.15vh;
        font-weight: 500;
        color: var(--bennys-muted);

        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .item-card.selected .item-label,
    .item-card.selected .item-icon { color: var(--bennys-ink); text-shadow: none; }
    .item-card.selected .item-description { color: rgba(11, 13, 16, 0.75); }

    .item-footer {
        display: flex;
        align-items: center;
        justify-content: space-between;

        height: 3.2vh;
        margin-top: 0.35vh;
        padding: 0 1.1vh;

        font-size: 1.2vh;
        font-weight: 600;
        font-style: italic;
        text-transform: uppercase;

        background-color: var(--bennys-panel);
        transition: background 150ms ease, color 150ms ease;
    }

    .item-footer > i { font-size: 1.8vh; color: var(--bennys-accent); }
    .item-price { color: var(--bennys-accent); font-weight: 800; }

    .item-card:hover .item-footer { background-color: var(--bennys-panel-hover); }
    .item-card.selected .item-footer { background-color: white; color: var(--bennys-ink); }
    .item-card.selected .item-footer > i,
    .item-card.selected .item-price { color: var(--bennys-ink); }
</style>
