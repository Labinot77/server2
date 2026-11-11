<script>
    import { FormatCurrency } from "../../../utils/Utils";

    export let Image = 'preview';
    export let Price = 0;
    export let Name = 'Unknown Car';
    export let Class = '';
    export let Stock = undefined;
    export let Selected = false;
    export let HtmlRef;

    let ImageFailed = false;
    $: Image, (ImageFailed = false);
    $: OutOfStock = Stock === 0;
</script>

<button
    type="button"
    tabindex="-1"
    on:click
    bind:this={HtmlRef}
    class="vc-card"
    class:selected={Selected}
    class:out-of-stock={OutOfStock}
>
    <div class="vc-card-image">
        {#if !ImageFailed}
            <img src="./images/pdm/{Image}.jpg" alt="" on:error={() => (ImageFailed = true)} />
        {:else}
            <svg class="vc-card-fallback" viewBox="0 0 64 32" aria-hidden="true">
                <path d="M6 22c0-2 1-3 3-3.6l8-2.4 7-6c1.2-1 2.6-1.5 4.2-1.5H40c1.6 0 3 .6 4 1.8l4.5 5.2 7 1.2c2 .4 3.5 2 3.5 4V24c0 1-.8 2-2 2h-3a5 5 0 0 0-10 0H20a5 5 0 0 0-10 0H8c-1.2 0-2-1-2-2v-2z" />
            </svg>
        {/if}
    </div>

    {#if Selected}<span class="vc-card-corner"></span>{/if}
    {#if Class}<span class="vc-card-class">{Class}</span>{/if}
    {#if OutOfStock}<span class="vc-card-stock">Uitverkocht</span>{/if}

    <div class="vc-card-footer">
        <span class="vc-card-name">{Name}</span>
        <span class="vc-card-price">{FormatCurrency.format(Price).replace(/,00$/, '')}</span>
    </div>
</button>

<style>
    .vc-card {
        all: unset;
        box-sizing: border-box;
        position: relative;
        flex: 0 0 auto;

        width: 29vh;
        height: 16vh;

        cursor: pointer;
        overflow: hidden;

        background: linear-gradient(180deg, #23262c 0%, #14161a 100%);
        border: .2vh solid rgba(255, 255, 255, 0.06);

        transition: transform .18s ease, border-color .18s ease, box-shadow .18s ease;
    }

    .vc-card:hover { border-color: rgba(255, 255, 255, 0.25); transform: translateY(-.4vh); }

    .vc-card.selected {
        border-color: var(--vc-accent);
        box-shadow: 0 0 0 .1vh var(--vc-accent), 0 1vh 3vh rgba(46, 230, 184, 0.18);
        transform: translateY(-.6vh);
    }

    .vc-card-image {
        position: absolute;
        inset: 0 0 4vh 0;

        display: flex;
        align-items: center;
        justify-content: center;
    }

    .vc-card-image img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        transition: transform .3s ease;
    }
    .vc-card:hover .vc-card-image img,
    .vc-card.selected .vc-card-image img { transform: scale(1.06); }
    .vc-card.out-of-stock .vc-card-image img { filter: saturate(.35) brightness(.7); }

    .vc-card-fallback {
        width: 45%;
        fill: rgba(255, 255, 255, 0.12);
    }

    .vc-card-corner {
        position: absolute;
        top: 0;
        left: 0;

        width: 0;
        height: 0;

        border-top: 1.6vh solid var(--vc-accent);
        border-right: 1.6vh solid transparent;
    }

    .vc-card-class {
        position: absolute;
        top: .8vh;
        left: .8vh;

        min-width: 2.4vh;
        padding: .2vh .6vh;

        font-size: 1.3vh;
        font-weight: 700;
        text-align: center;
        color: #fff;

        background: rgba(0, 0, 0, 0.65);
        border: .1vh solid rgba(255, 255, 255, 0.15);
    }
    .vc-card.selected .vc-card-class { left: 2vh; }

    .vc-card-stock {
        position: absolute;
        top: .9vh;
        right: .9vh;

        font-size: 1.15vh;
        font-weight: 800;
        font-style: italic;
        letter-spacing: .05vh;
        text-transform: uppercase;
        color: var(--vc-danger);
    }

    .vc-card-footer {
        position: absolute;
        left: 0;
        right: 0;
        bottom: 0;

        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: .8vh;

        height: 4vh;
        padding: 0 .9vh;

        background: #0e0f12;
    }

    .vc-card-name {
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;

        font-size: 1.6vh;
        font-weight: 600;
        color: #e9ebee;
    }

    .vc-card-price {
        flex: 0 0 auto;
        padding: .25vh .7vh;

        font-size: 1.5vh;
        font-weight: 700;
        font-style: italic;
        color: #071510;

        background: var(--vc-accent);
    }
    .vc-card.out-of-stock .vc-card-price { background: #3a3d44; color: #c9ccd2; }
</style>
