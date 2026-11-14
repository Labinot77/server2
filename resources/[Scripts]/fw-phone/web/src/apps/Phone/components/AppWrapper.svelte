<script>
    import { fly } from "svelte/transition";
</script>

<div {...$$restProps} in:fly={{ y: 60, duration: 280 }} class="phone-app-wrapper {$$restProps?.class || ''}">
    <slot />
</div>

<style>
    /* Codera app view: solid panel sliding up over the home screen */
    .phone-app-wrapper {
        position: absolute;
        inset: 0;
        isolation: isolate;
        color: #f3f4f6;
        background: var(--phone-bg);
        z-index: 20;
    }
</style>
