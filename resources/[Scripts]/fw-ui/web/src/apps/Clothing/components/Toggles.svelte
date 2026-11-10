<script>
    // Quick undress buttons (fw-clothes Clothes/ToggleComponents), restyled.
    import Icon from "./Icon.svelte";
    import { Post } from "../clothing.store";

    const Buttons = [
        { Type: "Hat", Icon: "crown", Label: "HAT" },
        { Type: "Masks", Icon: "ghost", Label: "MASK" },
        { Type: "Glasses", Icon: "glasses", Label: "GLASSES" },
        { Type: "Shirts", Icon: "shirt", Label: "SHIRT" },
        { Type: "Bags", Icon: "backpack", Label: "BAG" },
        { Type: "Pants", Icon: "pants", Label: "PANTS" },
        { Type: "Shoes", Icon: "footprints", Label: "SHOES" },
    ];
</script>

<div class="toggles">
    <span class="label">TOGGLE</span>
    {#each Buttons as B}
        <button class="rail-btn" title={B.Label} on:click={() => Post("Clothes/ToggleComponents", { Type: B.Type })}>
            <Icon Name={B.Icon} Size={22} />
        </button>
    {/each}
</div>

<style>
    .toggles { position: absolute; left: 48px; bottom: 24px; display: flex; align-items: center; gap: 3px; }
    .label { font-family: 'Bebas Neue', sans-serif; font-style: italic; font-size: 24px; letter-spacing: 0.05em; color: rgba(255,255,255,.45); margin-right: 10px; }
    .toggles :global(.rail-btn) { width: 46px; height: 46px; }
</style>
