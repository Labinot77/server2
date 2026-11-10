<script>
    import { MyPreferences } from "../../Preferences/preferences.store.js";
    import { HudVisible, Player, LayoutEditing } from "../hud.store.js";
    import { Layout } from "../layout.js";

    const Pad = (Value) => String(Math.max(0, Math.floor(Number(Value) || 0))).padStart(2, "0");

    // Sample values while the /hudsettings layout editor is open.
    $: Clip = $LayoutEditing && !$Player.HasWeapon ? 12 : $Player.AmmoClip;
    $: Reserve = $LayoutEditing && !$Player.HasWeapon ? 96 : $Player.AmmoReserve;
</script>

{#if $HudVisible && ($Player.HasWeapon || $LayoutEditing) && !$MyPreferences['BlackBars.Show']}
    <div class="weapon-hud" use:Layout={"weapon"}>
        <div class="ammo">
            <span class="clip" class:empty={Clip <= 0}>{Pad(Clip)}</span>
            <span class="separator"></span>
            <span class="total">{Pad(Reserve)}</span>
        </div>
        <svg class="icon" viewBox="0 0 829 566" aria-hidden="true">
            <path fill="currentColor" fill-rule="evenodd" d="M653.2 565.0C616.8 564.5 617.0 564.5 617.0 558.5C617.0 557.3 615.6 555.1 613.9 553.4C608.8 548.6 608.0 546.1 608.0 534.8C608.0 522.2 608.5 520.3 612.1 518.5C613.9 517.5 615.0 516.1 615.2 514.3C615.5 511.3 610.1 495.4 605.1 485.0C603.2 481.0 602.0 476.9 602.0 474.3C602.0 468.6 597.6 455.9 594.7 453.4C589.8 449.2 588.7 446.5 589.5 440.3C590.3 433.1 587.6 424.7 582.7 419.0C578.9 414.5 576.9 408.8 576.9 402.7C576.9 397.0 573.1 385.4 570.3 382.3C565.7 377.5 565.0 375.5 565.2 369.4C565.3 364.2 564.0 359.7 554.4 331.9C548.4 314.5 542.8 299.5 542.0 298.5C539.3 295.3 536.4 295.1 510.9 296.8C473.1 299.3 368.2 299.2 359.3 296.8C341.8 292.0 328.2 280.4 320.0 263.5C315.8 255.0 313.0 244.7 303.4 202.6C301.2 193.0 297.0 185.7 291.2 181.3C282.5 174.7 289.6 175.0 151.7 175.0L26.8 175.0L23.9 171.9C22.3 170.1 20.7 167.2 20.4 165.1C19.9 162.0 19.3 161.2 16.7 160.4L13.5 159.5L12.7 145.3C11.9 130.7 12.6 124.6 15.5 121.6C16.8 120.4 16.8 120.0 15.5 119.0C14.7 118.3 14.0 116.5 14.0 114.9C14.0 112.3 13.7 112.0 10.7 112.0C6.5 112.0 3.2 109.6 1.4 105.4C-0.8 100.2 -0.6 50.6 1.6 45.1C3.4 40.5 6.7 38.0 10.8 38.0C13.3 38.0 13.8 37.5 14.4 34.9C15.3 30.1 20.1 26.0 24.8 26.0C29.7 26.0 30.4 25.3 36.0 12.6C41.5 0.6 42.2 0.0 54.2 0.0C65.6 -0.0 66.8 0.7 71.3 9.3C73.3 13.3 76.3 18.7 78.0 21.3L81.0 26.0L383.8 26.0L686.7 26.0L691.7 14.2C695.3 5.9 697.4 2.1 699.1 1.3C702.1 -0.3 725.1 -0.5 726.7 1.1C727.2 1.6 729.9 2.4 732.6 2.8L737.5 3.5L740.1 10.0C741.5 13.6 743.5 18.6 744.4 21.2L746.1 25.8L755.5 26.2C767.6 26.6 771.1 29.3 772.0 38.7C772.5 44.3 772.6 44.4 777.1 46.8C779.7 48.1 784.8 49.6 788.6 50.2C803.7 52.6 809.0 56.3 809.8 65.4C810.2 70.8 810.2 70.8 805.2 75.7C802.4 78.3 798.2 83.4 795.9 87.0C793.6 90.6 788.8 97.3 785.1 102.0C779.2 109.6 778.5 110.9 778.5 115.0C778.5 119.7 779.7 134.0 780.4 137.5C780.6 138.7 781.1 142.2 781.5 145.5C782.0 148.8 782.9 152.9 783.6 154.7C785.7 159.6 785.4 166.3 782.9 169.4C780.1 173.0 777.9 174.0 771.7 174.6C755.6 176.1 736.1 179.4 731.5 181.5C719.0 187.0 711.3 202.1 715.0 213.6C717.1 220.0 728.6 246.9 744.2 282.0C770.5 340.8 804.7 424.0 815.4 455.0C818.6 464.1 821.8 473.2 822.5 475.2C825.0 481.6 829.0 496.8 829.0 499.5C829.0 503.4 826.5 508.7 823.6 510.5C820.2 512.8 798.7 522.3 792.4 524.4L787.2 526.1L787.7 530.3C788.1 533.3 789.1 535.2 791.3 537.0C794.5 539.8 795.8 544.8 795.9 555.2C796.0 564.3 794.9 565.0 779.2 565.0C772.2 565.1 748.5 565.2 726.5 565.3C704.5 565.4 671.5 565.3 653.2 565.0ZM459.5 272.0C486.5 270.9 513.8 268.6 520.2 266.9C528.7 264.7 532.5 255.9 529.0 247.0C527.8 244.0 524.1 234.2 520.9 225.2C514.4 207.3 514.2 206.7 509.4 199.4C503.2 190.0 493.0 185.0 480.0 185.0C470.0 185.0 468.5 186.8 467.7 200.2C466.2 225.1 453.0 247.4 430.9 262.2C423.2 267.4 401.6 272.1 397.6 269.5C393.6 266.8 394.4 264.3 401.8 256.6C421.0 236.6 428.9 216.1 424.6 197.0C423.7 192.9 422.1 188.0 421.0 186.2L419.0 183.0L396.3 182.8C383.7 182.6 364.5 182.6 353.5 182.8L333.5 183.0L331.1 185.7C328.3 188.9 328.1 187.0 336.5 230.9C341.3 255.9 351.1 268.2 369.5 272.6C375.3 274.0 418.4 273.7 459.5 272.0Z"/>
        </svg>
    </div>
{/if}

<style>
    .weapon-hud {
        position: absolute;
        right: calc(1.5vw + 2.3vh);
        bottom: 14.35vh;
        z-index: 90;
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 0.28vh;
        color: #fff;
        font-family: 'Barlow Semi Condensed', Arial, sans-serif;
        font-style: italic;
        text-shadow: 0 0.19vh 0.56vh rgba(0, 0, 0, 0.85);
        pointer-events: none;
    }

    .ammo {
        display: flex;
        align-items: center;
        gap: 0.56vh;
        line-height: 1;
    }

    .clip {
        font-size: 2.4vh;
        font-weight: 800;
        letter-spacing: 0.05vh;
        font-variant-numeric: tabular-nums;
        transition: color 0.15s ease;
    }

    .clip.empty { color: #ff4b4b; }

    .separator {
        width: 0.19vh;
        height: 2.04vh;
        border-radius: 0.09vh;
        background: rgba(255, 255, 255, 0.55);
        box-shadow: 0 0.09vh 0.37vh rgba(0, 0, 0, 0.7);
        transform: skewX(-14deg);
    }

    .total {
        color: rgba(255, 255, 255, 0.78);
        font-size: 1.67vh;
        font-weight: 800;
        letter-spacing: 0.05vh;
        font-variant-numeric: tabular-nums;
    }

    .icon {
        display: block;
        width: 4.07vh;
        height: auto;
        color: #fff;
        filter: drop-shadow(0 0.19vh 0.37vh rgba(0, 0, 0, 0.8));
    }
</style>
