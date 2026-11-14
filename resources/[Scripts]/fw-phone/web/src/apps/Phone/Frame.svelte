<script>
    import { PhoneBackground } from "./phone.stores";
    import { WallpaperCss } from "../../utils/Utils";

    export let backgroundOverride = false;
</script>

<!-- Codera shell: brushed metal bezel, inset screen, dynamic island -->
<div class="phone-frame" />

<div class="phone-screen" style="background: {backgroundOverride || `${WallpaperCss($PhoneBackground)} center / cover`}">
    <slot />
</div>

<div class="phone-island"><i /></div>

<style>
    .phone-frame {
        position: absolute;
        right: 0.86vh;
        bottom: 0.9vh;
        width: 27.52vh;
        height: 61.97vh;
        z-index: 10;
        border-radius: 2.45vh;
        background: linear-gradient(135deg, #2b3034, #1c201f 45%, #15181a);
        box-shadow: inset 0 0 0 0.09vh rgba(255, 255, 255, 0.3), inset 0 0 0 0.21vh rgba(0, 0, 0, 0.45), 0 2.2vh 2.9vh rgba(0, 0, 0, 0.5);
    }

    .phone-screen {
        position: absolute;
        right: 2vh;
        bottom: 2.04vh;
        width: 25.24vh;
        height: 59.69vh;
        z-index: 20;
        overflow: hidden;
        pointer-events: all;
        border-radius: 1.43vh;
        box-shadow: 0 0 0 0.09vh rgba(0, 0, 0, 0.65);
    }

    .phone-screen::before {
        content: "";
        position: absolute;
        inset: 0;
        background: radial-gradient(120% 60% at 50% 0%, rgba(255, 255, 255, 0.05), transparent 60%), rgba(0, 0, 0, 0.1);
        pointer-events: none;
    }

    .phone-island {
        position: absolute;
        right: 11.71vh;
        bottom: 59.58vh;
        width: 5.8vh;
        height: 1.52vh;
        border-radius: 0.76vh;
        background: #050607;
        z-index: 400;
        pointer-events: none;
        box-shadow: inset 0 0 0 0.05vh rgba(255, 255, 255, 0.08);
    }

    .phone-island > i {
        position: absolute;
        right: 0.93vh;
        top: 50%;
        width: 0.6vh;
        height: 0.6vh;
        margin-top: -0.3vh;
        border-radius: 50%;
        background: radial-gradient(circle at 35% 33%, #6483c2, #1d2a47 45%, #06080d);
        box-shadow: 0 0 0 0.19vh #0e1117, 0 0 0 0.24vh rgba(255, 255, 255, 0.14);
    }
</style>
