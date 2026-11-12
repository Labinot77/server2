<script>
    import { fade } from "svelte/transition";
    import { PhoneBackground } from "../phone.stores";
    import { WallpaperCss } from "../../../utils/Utils";
</script>

<div {...$$restProps} in:fade={{ duration: 200 }} class="phone-app-wrapper {$$restProps?.class}" style="--wallpaper: {WallpaperCss($PhoneBackground)}; {$$restProps?.style || ""}">
    <slot />
</div>

<style>
    .phone-app-wrapper {
        position: absolute;
        inset: 0;
        isolation: isolate;
        color: white;
        background: var(--phone-bg);
    }

    /* Blurred wallpaper under a dark tint, so every app feels part of the home screen */
    .phone-app-wrapper::before,
    .phone-app-wrapper::after {
        content: "";
        position: absolute;
        inset: 0;
        z-index: -1;
        pointer-events: none;
    }

    .phone-app-wrapper::before {
        background: var(--wallpaper) center / cover;
        filter: blur(2.5vh) saturate(1.3);
        transform: scale(1.25);
    }

    .phone-app-wrapper::after { background: linear-gradient(180deg, rgba(12, 13, 16, 0.78), rgba(12, 13, 16, 0.92)); }
</style>
