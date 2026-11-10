<script>
    import { MyPreferences } from "../../Preferences/preferences.store.js";
    import { HudVisible, Player } from "../hud.store.js";
    import { VehicleData } from "../hud.store.js";

    import { HudSettings, LayoutEditing } from "../hud.store.js";
    import { Layout } from "../layout.js";

    $: Preview = $LayoutEditing;
    $: StaminaShown = ($Player.ShowStamina || Preview) && $HudSettings.player.showStamina;
    $: StaminaValue = Preview && !$Player.ShowStamina ? 70 : Stamina;
    $: OxygenShown = ShowOxygen || Preview;
    $: OxygenValue = Preview && !ShowOxygen ? 60 : Oxygen;
    $: EngineShown = ShowEngine || Preview;
    $: EngineValue = Preview && !ShowEngine ? 80 : EnginePercent;

    let ShowEngine = false;
    let LastEngineHealth = 1000;
    let EngineTimer;

    
    const Clamp = (Value) => Math.min(100, Math.max(0, Number(Value) || 0));

    // Shows for 3s after taking damage, and stays visible at 10% or below.
    const UpdateEngine = (Health, Visible) => {
        if (!Visible || Health >= 995) {
            clearTimeout(EngineTimer);
            ShowEngine = false;
            LastEngineHealth = 1000;
            return;
        };

        const Damaged = Health < LastEngineHealth;
        LastEngineHealth = Health;

        if (Health <= 100) {
            clearTimeout(EngineTimer);
            ShowEngine = true;
        } else if (Damaged) {
            clearTimeout(EngineTimer);
            ShowEngine = true;
            EngineTimer = setTimeout(() => { ShowEngine = false; }, 3000);
        };
    };

    // white above 25%, fades to red below
    const StaminaColor = (Value) => {
        const Stamina = Clamp(Value);
        if (Stamina >= 25) return "rgb(255, 255, 255)";

        const Danger = (25 - Stamina) / 25;
        return `rgb(${Math.round(255 - 24 * Danger)}, ${Math.round(255 - 179 * Danger)}, ${Math.round(255 - 195 * Danger)})`;
    };

    $: UpdateEngine($VehicleData.Engine, $VehicleData.Visible);
    $: EnginePercent = Clamp($VehicleData.Engine / 10);
    $: Stamina = Clamp($Player.Stamina);
    $: Oxygen = Clamp($Player.Oxygen);
    $: ShowOxygen = $Player.IsUnderwater && $MyPreferences['Status.ShowOxygen'];
</script>

{#if $HudVisible && !$MyPreferences['BlackBars.Show']}
<div class="center-status" use:Layout={"status"}>
        {#if $Player.ShowStamina}
            <div class="item">
                <i class="fas fa-running icon"></i>
                <div class="track">
                    <div class="fill" style="width: {Stamina}%; background-color: {StaminaColor(Stamina)};"></div>
                </div>
            </div>
        {/if}

        {#if ShowOxygen}
            <div class="item">
                <i class="fas fa-swimmer icon" style="color: {Oxygen < 20 ? '#e74c3c' : '#fff'};"></i>
                <div class="track">
                    <div class="fill oxygen" style="width: {Oxygen}%;"></div>
                </div>
            </div>
        {/if}

        {#if ShowEngine}
        <div class="item">
            <i class="fas fa-car-crash icon" style="color: {EnginePercent <= 10 ? '#e74c3c' : '#fff'};"></i>
            <div class="track">
                <div class="fill" style="width: {EnginePercent}%;"></div>
            </div>
        </div>
        {/if}
    </div>
{/if}

<style>
    .center-status {
        position: absolute;
        bottom: 2vh;
        left: 50%;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.93vh;
        transform: translateX(-50%);
    }

    .item {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.46vh;
        opacity: 0.9;
    }

    .icon {
        color: #fff;
        font-size: 1.48vh;
        text-shadow: 0 0 0.46vh rgba(0, 0, 0, 0.8);
    }

    .track {
        width: 18.5vh;
        height: 0.37vh;
        overflow: hidden;
        border-radius: 0.19vh;
        background: rgba(0, 0, 0, 0.5);
    }

    .fill {
        height: 100%;
        margin: 0 auto;
        background: #fff;
        transition: width 0.2s linear, background-color 0.2s linear;
    }

    .fill.oxygen { background: #00ffff; }
</style>