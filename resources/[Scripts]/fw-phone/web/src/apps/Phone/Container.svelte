<script>
    import Frame from "./Frame.svelte";
    import Notifications from "./Notifications.svelte";

    export let isBurner = false;
    export let backgroundOverride = false;
</script>

<div {...$$restProps} class="phone-container {$$restProps.class}">
    <Frame {backgroundOverride}>
        {#if !isBurner}<Notifications />{/if}
        <slot />
    </Frame>
</div>

<style>
    .phone-container {
        position: absolute;
        bottom: -70vh;
        right: 0;
        transition: bottom 800ms ease;
    }

    :global(.phone-container.phone-debug) {
        top: 85%;
        left: -30%;
        transform: translate(-50%, -50%) scale(1.5);
    }

    :global(.phone-container.phone-visible) { bottom: 0; }
    :global(.phone-container.phone-half) { bottom: -51vh; transition: none; }
</style>
