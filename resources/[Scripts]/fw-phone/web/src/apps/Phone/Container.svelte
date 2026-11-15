<script>
    import Frame from "./Frame.svelte";
    import Notifications from "./Notifications.svelte";

    export let isBurner = false;
    export let unfold = false;
    export let backgroundOverride = false;
</script>

<div {...$$restProps} class="phone-container {$$restProps.class}" class:unfold>
    <Frame {backgroundOverride}>
        {#if !isBurner}<Notifications />{/if}
        <slot />
    </Frame>
</div>

<style>
    /* Codera proportions: 357x735 folded, 568x680 unfolded */
    .phone-container {
        --pw: 30.1vh;
        --ph: 61.97vh;
        position: absolute;
        bottom: -70vh;
        right: 0;
        transition: bottom 800ms ease;
    }

    .phone-container.unfold { --pw: 47.89vh; --ph: 57.33vh; }

    :global(.phone-container.phone-debug) {
        top: 85%;
        left: -30%;
        transform: translate(-50%, -50%) scale(1.5);
    }

    :global(.phone-container.phone-visible) { bottom: 0; }
    :global(.phone-container.phone-half) { bottom: calc(11vh - var(--ph)); transition: none; }
</style>
