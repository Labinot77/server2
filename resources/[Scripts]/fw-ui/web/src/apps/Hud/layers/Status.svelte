<script>
    import { OnEvent } from "../../../utils/Utils";
    import { MyPreferences } from "../../Preferences/preferences.store.js";

    import Circle from "../components/Circle.svelte";
    import Bar from "../components/Bar.svelte";
    import Need from "../components/Need.svelte";

    import { HudVisible, Player, HudSettings, ChatOpen, ChatInputWidth, DevMode } from "../hud.store.js";
    import { Layout } from "../layout.js";

        $: ChatOffset = $ChatOpen ? (($ChatInputWidth + 6) / 10.8) * $HudSettings.layout.player.scale : 0;

    // Ids drawn by the dedicated widgets below. Everything else stays a Circle.
    const CoreIds = [ "Voice", "Health", "Armor", "Food", "Water", "Oxygen" ];
    const HidableIds = [ "Health", "Armor", "Food", "Water" ];

    const RadioDefaultColors = [ "#fff", "#EBD334" ]; // voice colors fw-voice uses while NOT on radio

    let HudComponents = [];

    // Re-run the template when a preference changes.
    MyPreferences.subscribe(() => { HudComponents = HudComponents; });

    const ShowHudComponent = (Data) => {
        if (!Data) return false;
        if (Data.IsEnhancement && !$MyPreferences['Status.ShowBuffs']) return false;

        // Did we disable the hud, or is the hud value beyond the hide value?
        if (HidableIds.includes(Data.Id)) {
            if (!$MyPreferences[`Status.Show${Data.Id}`]) return false;
            if (Data.Value > $MyPreferences[`Status.${Data.Id}Value`]) return false;

            if ($MyPreferences[`Status.${Data.Id}Value`] >= 100) return true;
        };

        if (Data.Id == "Stress" && !$MyPreferences[`Status.ShowStress`]) return false;

        return Data.Show;
    };

    const Find = (Components, Id) => Components.find(Val => Val.Id == Id);

    $: Voice = Find(HudComponents, "Voice");
    $: Health = Find(HudComponents, "Health");
    $: Armor = Find(HudComponents, "Armor");
    $: Food = Find(HudComponents, "Food");
    $: Water = Find(HudComponents, "Water");
    $: Circles = HudComponents.filter(Val => !CoreIds.includes(Val.Id));

    // Voice badge state, derived from the Voice hud item fw-voice already updates.
    $: VoiceMode = !Voice ? 2 : (Voice.Value <= 33 ? 1 : (Voice.Value <= 66 ? 2 : 3));
    $: IsTalking = Voice?.Color == "#EBD334";
    $: RadioText = Voice?.InsideText && $MyPreferences['Status.RadioVisibility'] != "Nooit" ? Voice.InsideText : false;
    $: IsRadioTalking = !!Voice?.InsideText && !RadioDefaultColors.includes(Voice.Color);

    OnEvent("Hud", "SetHudComponents", (Data) => {
        HudComponents = Data;
    });

    OnEvent("Hud", "SetHudData", (Data) => {
        const HudIndex = HudComponents.findIndex(Val => Val.Id == Data.Id);
        if (HudIndex > -1) HudComponents[HudIndex] = Data;
    });
</script>

{#if $HudVisible && !$MyPreferences['BlackBars.Show']}
    <div class="player-hud" use:Layout={"player"} style:margin-left="{ChatOffset}vh" style:transition="margin-left 0.32s cubic-bezier(0.16, 1, 0.3, 1)">
        {#if Voice && Voice.Show}
            <div
                class="voice-badge"
                data-mode={VoiceMode}
                class:talking={IsTalking}
                class:radio={IsRadioTalking}
            >
                <i class="fas fa-microphone voice-icon" style="opacity: {RadioText ? 0.25 : 1};"></i>
                {#if RadioText}<span class="voice-radio">{RadioText}</span>{/if}
            </div>
            <div class="voice-divider"></div>
        {/if}

        <div class="stats">
            <div class="bars">
                {#if ShowHudComponent(Health)}
                    <Bar Icon={Health.Icon} Label="HEALTH" Value={Health.Value} />
                {/if}
                {#if ShowHudComponent(Armor) && $HudSettings.player.showArmor}
                    <Bar Icon={Armor.Icon} Label="ARMOR" Value={Armor.Value} />
                {/if}
            </div>

            <div class="needs">
                {#if ShowHudComponent(Food)}<Need Type="Food" Value={Food.Value} />{:else}<div></div>{/if}
                {#if ShowHudComponent(Water)}<Need Type="Water" Value={Water.Value} />{:else}<div></div>{/if}
            </div>
        </div>

        <!-- Everything that isn't a core widget keeps using the reusable Circle -->
        <div class="circles">
            {#each Circles as Data (Data.Id)}
                {#if ShowHudComponent(Data)}
                    <Circle
                        Icon={Data.Icon}
                        Value={Data.Value}
                        Color={Data.Color}
                        Buffed={Data.IsEnhancement || Data.Buffed}
                        Danger={Data.ShowDanger}
                        Text={Data.InsideText}
                    />
                {/if}
            {/each}
        </div>

        {#if $Player.IsSwimming && $MyPreferences['Status.ShowOxygen']}
            <div class="swim-badge" style="--pct: {$Player.Oxygen};">
                <i class="fas fa-lungs"></i>
            </div>
        {/if}
        
        {#if $DevMode}
    <div class="dev-badge"><i class="fas fa-code"></i></div>
{/if}
    </div>
{/if}

<style>
    .player-hud {
        position: absolute;
        left: 1.5vw;
        bottom: 4vh;
        display: flex;
        align-items: center;
    }

    /* voice */
    .voice-badge {
        position: relative;
        display: grid;
        width: 3.24vh;
        height: 3.24vh;
        flex: 0 0 3.24vh;
        margin-top: 0.09vh;
        margin-right: 0.56vh;
        place-items: center;
        border: 0.37vh solid #f7f7f4;
        border-radius: 50%;
        outline: 0.19vh solid rgba(15, 15, 15, 0.88);
        outline-offset: 0.09vh;
        background: rgba(19, 19, 19, 0.84);
        box-shadow: 0 0.28vh 0.46vh rgba(0, 0, 0, 0.58), inset 0 0 0 0.09vh rgba(255, 255, 255, 0.12);
        color: #f7f7f4;
        overflow: hidden;
        transition: color 120ms ease, border-color 120ms ease, border-width 150ms ease, box-shadow 120ms ease;
    }

    .voice-badge[data-mode="1"] { border-width: 0.2vh; }
    .voice-badge[data-mode="2"] { border-width: 0.37vh; }
    .voice-badge[data-mode="3"] { border-width: 0.57vh; }

    .voice-badge.talking {
        border-color: #ff2948;
        box-shadow: 0 0.28vh 0.46vh rgba(0, 0, 0, 0.58), 0 0 0.74vh rgba(176, 38, 255, 0.45);
    }

    .voice-badge.radio {
        border-color: #ff2948;
        color: #ff2948;
        box-shadow: 0 0.28vh 0.46vh rgba(0, 0, 0, 0.58), 0 0 0.74vh rgba(255, 41, 72, 0.45);
    }

    .voice-icon {
        font-size: 1.44vh;
        filter: drop-shadow(0 0.09vh 0.09vh rgba(0, 0, 0, 0.55));
        transition: opacity 0.35s ease;
    }

    .voice-radio {
        position: absolute;
        font-family: Arial, Helvetica, sans-serif;
        font-size: 1.1vh;
        font-weight: bold;
        color: #fff;
    }

    .voice-divider {
        width: 0.19vh;
        height: 2.2vh;
        flex: 0 0 0.19vh;
        margin: 0.46vh 0.56vh 0;
        border-radius: 0.19vh;
        background: rgba(17, 17, 17, 0.62);
        box-shadow: 0.09vh 0 0.09vh rgba(255, 255, 255, 0.08);
    }

    /* bars + needs */
    .stats { position: relative; }

    .bars {
        display: flex;
        gap: 0.37vh;
    }

    /* health = rounded top-left, armor = rounded top-right */
    .bars > :global(.bar:first-child) {
        border-top-left-radius: 2.2vh;
        border-bottom-left-radius: 0.28vh;
    }

    .bars > :global(.bar:last-child) {
        border-top-right-radius: 2.2vh;
        border-bottom-right-radius: 0.28vh;
    }

    /* only one bar visible: round both sides */
    .bars > :global(.bar:only-child) {
        border-radius: 2.2vh 2.2vh 0.28vh 0.28vh;
    }

    .needs {
        position: absolute;
        top: calc(100% + 0.28vh);
        left: 0;
        display: grid;
        width: 100%;
        grid-template-columns: repeat(2, 10.65vh);
        column-gap: 0.37vh;
    }

    .circles {
        display: flex;
        margin-left: 1vh;
    }

    /* swimming */
    .swim-badge {
        display: grid;
        width: 3.24vh;
        height: 3.24vh;
        flex: 0 0 3.24vh;
        margin-top: 0.09vh;
        margin-left: 2.04vh;
        place-items: center;
        border-radius: 50%;
        background: conic-gradient(#a9dced calc(var(--pct) * 1%), rgba(14, 18, 24, 0.9) 0);
        box-shadow: 0 0.28vh 0.46vh rgba(0, 0, 0, 0.58), inset 0 0 0 0.09vh rgba(255, 255, 255, 0.1);
        color: #fff;
        font-size: 1.3vh;
        transition: background 0.3s linear;
    }

    /* Dev */

    .dev-badge {
    display: grid; width: 3.24vh; height: 3.24vh; flex: 0 0 3.24vh;
    margin-top: 0.09vh; margin-left: 2.04vh; place-items: center;
    border-radius: 50%; background: #22c55e; color: #fff; font-size: 1.39vh;
    box-shadow: 0 0.28vh 0.46vh rgba(0, 0, 0, 0.58), inset 0 0 0 0.09vh rgba(255, 255, 255, 0.18);
}
</style>