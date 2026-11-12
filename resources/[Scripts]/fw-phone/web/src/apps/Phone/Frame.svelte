<script>
    import { PhoneBackground } from "./phone.stores";
    import { WallpaperCss } from "../../utils/Utils";

    export let backgroundOverride = false;
</script>

<div class="phone-frame">
    <div class="phone-buttons" />
</div>

<div class="phone-screen" style="background: {backgroundOverride || `${WallpaperCss($PhoneBackground)} center / cover`}">
    <slot />
    <div class="phone-island"><div class="phone-island-cam" /></div>
</div>

<style>
    .phone-screen {
        position: absolute;
        right: 1.66vh;
        bottom: 1.7vh;
        width: 25.92vh;
        height: 60.37vh;
        z-index: 20;
        overflow: hidden;
        pointer-events: all;
        border-radius: 2.8vh;
    }

    .phone-frame {
        position: absolute;
        right: 0.86vh;
        bottom: 0.9vh;
        width: 27.52vh;
        height: 61.97vh;
        z-index: 10;
        border-radius: 3.6vh;
        background: #0a0a0b;
        border: 0.3vh solid #2d2e31;
        box-sizing: border-box;
        box-shadow: 0 0 0 0.12vh #55575c, 0 1.5vh 3.5vh rgba(0, 0, 0, 0.6), inset 0 0 0.4vh rgba(255, 255, 255, 0.15);
    }

    /* Side buttons: action + volume on the left, power on the right */
    .phone-buttons,
    .phone-buttons::before,
    .phone-buttons::after {
        position: absolute;
        width: 0.3vh;
        background: #3a3b3f;
        border-radius: 0.2vh;
    }

    .phone-buttons { top: 9vh; left: -0.6vh; height: 2.4vh; }
    .phone-buttons::before { content: ""; top: 4vh; left: 0; height: 4.6vh; }
    .phone-buttons::after { content: ""; top: 9.6vh; left: 28.1vh; height: 7vh; }

    .phone-island {
        position: absolute;
        top: 0.55vh;
        left: 50%;
        transform: translateX(-50%);
        width: 7.6vh;
        height: 1.95vh;
        border-radius: 1vh;
        background: black;
        z-index: 300;
        pointer-events: none;
    }

    .phone-island-cam {
        position: absolute;
        right: 0.8vh;
        top: 50%;
        transform: translateY(-50%);
        width: 0.8vh;
        height: 0.8vh;
        border-radius: 50%;
        background: radial-gradient(circle at 35% 35%, #2b4a6b, #0b1320 70%);
    }
</style>
