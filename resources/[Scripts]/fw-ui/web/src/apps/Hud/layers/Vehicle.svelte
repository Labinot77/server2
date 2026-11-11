<script>
    import { OnEvent } from "../../../utils/Utils";
    import { MyPreferences } from "../../Preferences/preferences.store.js";
    import { VehicleData } from "../hud.store.js";

     import { LayoutEditing } from "../hud.store.js";
    import { Layout } from "../layout.js";

    // Keys must match your actual keybinds in fw-vehicles, these are only labels.
    const ControlHints = [
        { Key: "L", Label: "Lock/Unlock" },
        { Key: "H", Label: "Headlights" },
        { Key: "E", Label: "Horn" },
        { Key: "F", Label: "Get out" },
    ];

    OnEvent("Hud", "SetVehicleVisibility", (Data) => {
        VehicleData.update((Val) => ({ ...Val, Visible: Data.Visible }));
    });

    let PhoneOpen = false;
    OnEvent("Hud", "SetPhoneOpen", (Open) => PhoneOpen = Open);

    OnEvent("Hud", "SetVehicleData", (Data) => {
        VehicleData.update((Val) => ({ ...Val, ...Data }));
    });

    $: Speed = Math.min(999, Math.max(0, Math.round($VehicleData.Speed) || 0));
    $: SpeedPercent = Math.min(100, (Speed / ($VehicleData.MaxSpeed || 240)) * 100);
    $: Fuel = Math.min(100, Math.max(0, $VehicleData.Fuel || 0));
    $: LowFuel = Fuel <= 20;

    $: Digits = [...String(Speed).padStart(3, "0")].map((Char, Index) => ({
        Char,
        Dim: Speed <= 0 || (Speed < 10 && Index < 2) || (Speed < 100 && Index < 1),
    }));
</script>

{#if ($VehicleData.Visible || $LayoutEditing) && !PhoneOpen && !$MyPreferences['BlackBars.Show']}
    <div class="vehicle-row">
        {#if $MyPreferences['Vehicle.ShowControls'] !== false}
            <div class="controls">
                <div class="control-item">
                    <div class="control-key icon" class:flip={!$VehicleData.EngineOn}>
                        <svg viewBox="0 0 34 46" fill="none" aria-hidden="true">
                            <rect x="5" y="2" width="24" height="30" rx="11" stroke="currentColor" stroke-width="3"/>
                            <line x1="17" y1="9" x2="17" y2="16" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>
                            <polygon points="9.5,19.5 24.5,19.5 17,28.5" fill="currentColor"/>
                            <rect x="11" y="40" width="12" height="4" rx="2" fill="currentColor"/>
                        </svg>
                    </div>
                    <span class="control-label">{$VehicleData.EngineOn ? "Motor off" : "Motor on"}</span>
                </div>

                {#each ControlHints as Hint}
                    <span class="control-divider">/</span>
                    <div class="control-item">
                        <div class="control-key">{Hint.Key}</div>
                        <span class="control-label">{Hint.Label}</span>
                    </div>
                {/each}
            </div>
        {/if}

<div class="speedometer" use:Layout={"vehicle"}>
            <svg class="gauges" viewBox="0 0 200 200">
                <defs>
                    <linearGradient id="speedometer-bg-gradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#1e1e1e" stop-opacity="0.88" />
                        <stop offset="35%" stop-color="#141414" stop-opacity="0.60" />
                        <stop offset="70%" stop-color="#0a0a0a" stop-opacity="0.20" />
                        <stop offset="90%" stop-color="#050505" stop-opacity="0.03" />
                        <stop offset="100%" stop-color="#000000" stop-opacity="0" />
                    </linearGradient>
                    <mask id="rpm-segments-mask">
                        <path fill="none" stroke="white" stroke-width="9" stroke-dasharray="11.27 3.18" d="M -7.1,165.1 A 92,92 0 1,1 123.1,165.1" />
                    </mask>
                    <mask id="rpm-progress-mask">
                        <path
                            class="rpm-progress"
                            pathLength="100"
                            stroke-dasharray="100"
                            stroke-dashoffset={100 - SpeedPercent}
                            d="M -7.1,165.1 A 92,92 0 1,1 123.1,165.1"
                        />
                    </mask>
                </defs>

                <circle cx="58" cy="100" r="96" fill="url(#speedometer-bg-gradient)" />
                <path class="rpm-bg" d="M -7.1,165.1 A 92,92 0 1,1 123.1,165.1" />
                <g mask="url(#rpm-progress-mask)">
                    <g mask="url(#rpm-segments-mask)">
                        <path class="rpm-fill low" pathLength="100" stroke-dasharray="30 70" d="M -7.1,165.1 A 92,92 0 1,1 123.1,165.1" />
                        <path class="rpm-fill mid" pathLength="100" stroke-dasharray="0 30 35 35" d="M -7.1,165.1 A 92,92 0 1,1 123.1,165.1" />
                        <path class="rpm-fill high" pathLength="100" stroke-dasharray="0 65 35 0" d="M -7.1,165.1 A 92,92 0 1,1 123.1,165.1" />
                    </g>
                </g>

                <path
                    class="fuel-bg"
                    style="stroke: {LowFuel ? '#e74c3c' : '#fff'}"
                    d="M 144.85,158.44 L 151.15,163.36 A 103,103 0 0,0 157.39,45.38 L 150.61,49.62 A 95,95 0 0,1 144.85,158.44 Z"
                />
                <path
                    class="fuel-fill"
                    style="stroke: {LowFuel ? '#e74c3c' : '#fff'}"
                    pathLength="100"
                    stroke-dasharray="100"
                    stroke-dashoffset={100 - Fuel}
                    d="M 148.0,160.9 A 99,99 0 0,0 154.0,47.5"
                />
            </svg>

            <div class="center">
                {#if $VehicleData.IsAircraft}
                    <div class="altitude">{$VehicleData.Altitude.toLocaleString("nl-NL")}<small>ft</small></div>
                    <span class="gear-label">ALT</span>
                {:else}
                    <div class="gear">{$VehicleData.Gear}</div>
                    <span class="gear-label">GEAR</span>
                {/if}

                <span class="speed">
                    {#each Digits as Digit}
                        <span class="digit" class:dim={Digit.Dim}>{Digit.Char}</span>
                    {/each}
                </span>
                <span class="unit">{$VehicleData.Unit}</span>
            </div>

            <div class="fuel-icon" class:low={LowFuel}>
                <i class="fas {$VehicleData.Electric ? 'fa-bolt' : 'fa-gas-pump'}"></i>
                <i class="fas fa-caret-right fuel-arrow"></i>
            </div>

            <div class="icons">
                <div class="icon" class:lights={$VehicleData.Lights}>
                    <i class="far fa-lightbulb"></i>
                </div>
                <div class="icon" class:belt-on={$VehicleData.Belt} class:belt-off={!$VehicleData.Belt}>
                    <i class="fas {$VehicleData.Belt ? 'fa-user-check' : 'fa-user-slash'}"></i>
                </div>
                <div class="icon" class:locked={$VehicleData.Locked}>
                    <i class="fas {$VehicleData.Locked ? 'fa-lock' : 'fa-unlock'}"></i>
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    .vehicle-row {
        position: absolute;
        right: calc(2vw + 2.85vh);
        bottom: 1vh;
        z-index: 90;
        display: flex;
        align-items: flex-end;
        gap: 0.93vh;
        font-family: 'Barlow Semi Condensed', 'Barlow', Arial, sans-serif;
        pointer-events: none;
    }

    /* speedometer */
    .speedometer {
        position: relative;
        display: flex;
        width: 16.3vh;
        height: 16.3vh;
        align-items: center;
        justify-content: center;
    }

    .gauges {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        overflow: visible;
    }

    .rpm-bg {
        fill: none;
        stroke: rgba(40, 40, 40, 0.9);
        stroke-width: 7.5;
        stroke-dasharray: 11.27 3.18;
    }

    .rpm-progress {
        fill: none;
        stroke: #fff;
        stroke-width: 9;
        transition: stroke-dashoffset 0.05s linear;
    }

    .rpm-fill { fill: none; stroke-width: 7.5; }
    .rpm-fill.low { stroke: #fff; }
    .rpm-fill.mid { stroke: #f1c40f; }
    .rpm-fill.high { stroke: #e74c3c; }

    .fuel-bg {
        fill: rgba(30, 30, 30, 0.9);
        stroke-width: 1.5;
        stroke-linejoin: round;
        transition: stroke 0.3s;
    }

    .fuel-fill {
        fill: none;
        stroke-width: 6;
        transition: stroke-dashoffset 0.5s ease, stroke 0.3s;
    }

    .center {
        position: relative;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        margin-top: 0.16vh;
        transform: translateX(-3.42vh);
        text-align: center;
    }

    .gear {
        display: flex;
        width: 3.6vh;
        height: 3.6vh;
        margin-bottom: 0.16vh;
        align-items: center;
        justify-content: center;
        border: 0.16vh solid rgba(255, 255, 255, 0.35);
        border-radius: 50%;
        color: #fff;
        font-size: 2.04vh;
        font-weight: 900;
        font-style: italic;
    }

    .altitude {
        display: flex;
        min-width: 6vh;
        height: 2.77vh;
        margin: 0.4vh 0 0.57vh;
        padding: 0 1.14vh;
        align-items: center;
        justify-content: center;
        gap: 0.33vh;
        border: 0.08vh solid rgba(255, 255, 255, 0.14);
        border-radius: 999px;
        background: rgba(28, 28, 28, 0.88);
        box-shadow: 0 0.16vh 0.5vh rgba(0, 0, 0, 0.5);
        color: #fff;
        font-size: 1.55vh;
        font-style: italic;
        font-weight: 900;
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
    }

    .altitude small { font-size: 1.22vh; font-weight: 800; opacity: 0.75; }

    .gear-label {
        margin-bottom: 0.33vh;
        color: rgba(255, 255, 255, 0.6);
        font-size: 1.22vh;
        font-weight: 900;
        letter-spacing: 0.07vh;
    }

    .speed {
        display: flex;
        align-items: center;
        justify-content: center;
        color: #fff;
        font-size: 4.9vh;
        font-style: italic;
        font-weight: 900;
        line-height: 1;
        font-variant-numeric: tabular-nums;
        text-shadow: 0.16vh 0.16vh 0.4vh rgba(0, 0, 0, 0.8);
    }

    .digit { display: inline-block; width: 2.77vh; text-align: center; }
    .digit.dim { color: rgba(255, 255, 255, 0.28); text-shadow: none; }

    .unit {
        align-self: flex-end;
        width: 2.77vh;
        margin-top: 0.08vh;
        color: rgba(255, 255, 255, 0.5);
        font-size: 0.9vh;
        font-style: italic;
        font-weight: 800;
        letter-spacing: 0.07vh;
        text-align: center;
    }

    .fuel-icon {
        position: absolute;
        top: 52%;
        right: -0.57vh;
        display: flex;
        align-items: center;
        gap: 0.25vh;
        transform: translateY(-50%);
        color: #fff;
        font-size: 1.47vh;
        transition: color 0.3s;
    }

    .fuel-arrow { font-size: 0.9vh; }
    .fuel-icon.low { color: #e74c3c; animation: Flash 1s infinite; }

    .icons {
        position: absolute;
        top: 50%;
        right: -4.56vh;
        display: flex;
        flex-direction: column;
        gap: 0.81vh;
        transform: translateY(-50%);
    }

    .icon {
        display: flex;
        width: 2.77vh;
        height: 2.77vh;
        align-items: center;
        justify-content: center;
        border: 0.08vh solid rgba(255, 255, 255, 0.08);
        border-radius: 50%;
        background: rgba(12, 12, 12, 0.85);
        box-shadow: 0 0.16vh 0.5vh rgba(0, 0, 0, 0.4);
        color: rgba(255, 255, 255, 0.85);
        font-size: 1.14vh;
        transition: background 0.3s, color 0.3s;
    }

    .icon.lights { color: #fff; }
    .icon.belt-on { color: #2ecc71; }
    .icon.belt-off { color: #ff7a45; animation: Flash 1s infinite; }
    .icon.locked { color: #ff7a45; }

    @keyframes Flash {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.4; }
    }

    /* control hints */
    .controls {
        display: flex;
        align-items: center;
        gap: 1.47vh;
        margin-bottom: 0.81vh;
        margin-right: 2.4vh;
        padding: 0.81vh 1.79vh;
        border: 0.08vh solid rgba(255, 255, 255, 0.08);
        background: rgba(20, 18, 16, 0.32);
        box-shadow: 0 0.33vh 1.14vh rgba(0, 0, 0, 0.25);
        white-space: nowrap;
    }

    .control-item { display: flex; align-items: center; gap: 0.9vh; }

    .control-key {
        display: flex;
        min-width: 2.6vh;
        height: 2.6vh;
        padding: 0 0.65vh;
        align-items: center;
        justify-content: center;
        background: #f7f4ec;
        box-shadow: 0 0.08vh 0 rgba(255, 255, 255, 0.5) inset, 0 0.16vh 0.25vh rgba(0, 0, 0, 0.35);
        color: #211d17;
        font-family: Arial, Helvetica, sans-serif;
        font-size: 1.39vh;
        font-style: italic;
        font-weight: 700;
    }

    .control-key.icon {
        min-width: 0;
        height: auto;
        padding: 0;
        background: none;
        box-shadow: none;
        color: #ece3cf;
        filter: drop-shadow(0.08vh 0.08vh 0.16vh rgba(0, 0, 0, 0.9));
    }

    .control-key.icon svg { width: 2.1vh; height: 2.85vh; transition: transform 0.2s; }
    .control-key.icon.flip svg { transform: scaleY(-1); }

    .control-label {
        color: #f2ede2;
        font-family: Arial, Helvetica, sans-serif;
        font-size: 1.39vh;
        font-style: italic;
        font-weight: 700;
        letter-spacing: 0.02vh;
        text-shadow: 0.08vh 0.08vh 0.25vh rgba(0, 0, 0, 0.9);
        text-transform: uppercase;
    }

    .control-divider {
        color: rgba(242, 237, 226, 0.3);
        font-family: Arial, Helvetica, sans-serif;
        font-size: 1.8vh;
        font-style: italic;
    }
</style>