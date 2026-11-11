<script>
    // Shows the vehicle image, or a car icon if there is none / it fails to load.
    export let Src = null;
    export let Alt = "";
    export let IconSize = "4vh";

    let Failed = false;
    $: Src, (Failed = false);
</script>

<div class="vehicle-image">
    {#if Src && !Failed}
        <img src={Src} alt={Alt} on:error={() => (Failed = true)} />
    {:else}
        <i class="fas fa-car-side" style="font-size: {IconSize};"></i>
    {/if}
</div>

<style>
    .vehicle-image {
        width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        overflow: hidden;
    }

    img {
        max-width: 100%;
        max-height: 100%;
        object-fit: contain;
        filter: drop-shadow(0 0.6vh 0.6vh rgba(0, 0, 0, 0.55));
    }

    i {
        color: rgba(255, 255, 255, 0.22);
    }
</style>
