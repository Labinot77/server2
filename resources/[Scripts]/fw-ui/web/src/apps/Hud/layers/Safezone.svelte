<script>
    // Port of the safezone warning from codera-hud (index.html + minimap.css).
    // fw-hud handlers/safezone.ts sends Hud/SetSafezoneWarning while GetSafeZoneSize() < Safezone.Required.
    import { OnEvent } from "../../../utils/Utils";
    import { SafezoneWarning } from "../hud.store.js";

    OnEvent("Hud", "SetSafezoneWarning", (Data) => SafezoneWarning.set(!!Data.Visible));
</script>

{#if $SafezoneWarning}
    <section class="safezone-warning" role="alert">
        <div class="safezone-warning__panel">
            <div class="safezone-warning__header">
                <div class="safezone-warning__icon" aria-hidden="true">
                    <i class="fas fa-exclamation-triangle"></i>
                </div>
                <div class="safezone-warning__heading">
                    <span>HUD CALIBRATIE</span>
                    <h1>Safezone needs to be adjusted</h1>
                </div>
            </div>

            <p class="safezone-warning__description">
               Your current display area is too small. Set the safe zone to the maximum,
                so that the minimap and the HUD are correctly aligned.
            </p>

            <div class="safezone-warning__route" aria-label="Instellingen pad">
                <span class="safezone-warning__key">ESC</span>
                <i class="fas fa-chevron-right" aria-hidden="true"></i>
                <span>Settings</span>
                <i class="fas fa-chevron-right" aria-hidden="true"></i>
                <span>Display</span>
                <i class="fas fa-chevron-right" aria-hidden="true"></i>
                <span>Safezone Size</span>
            </div>

            <div class="safezone-warning__instruction">
                <p>Move the <strong>Safezone Size</strong> slider all the way to the right.</p>
                <i class="fas fa-long-arrow-alt-right" aria-hidden="true"></i>
            </div>
        </div>
    </section>
{/if}

<style>
    .safezone-warning {
        position: absolute;
        inset: 0;
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 3vw;
        background: rgba(4, 4, 5, 0.16);
        color: #fff;
        font-family: 'Inter', sans-serif;
        backdrop-filter: none;
    }
    .safezone-warning__panel {
        position: relative;
        width: clamp(540px, 39vw, 750px);
        overflow: hidden;
        padding: clamp(26px, 2vw, 40px);
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 14px;
        background: linear-gradient(145deg, rgba(24, 24, 27, 0.98), rgba(10, 10, 12, 0.98));
        box-shadow: 0 24px 80px rgba(0, 0, 0, 0.62), inset 0 1px 0 rgba(255, 255, 255, 0.05);
    }
    .safezone-warning__panel::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 4px;
        background: linear-gradient(90deg, #ffb52e 0%, #ffb52e 38%, rgba(255, 181, 46, 0) 78%);
    }
    .safezone-warning__header {
        display: flex;
        align-items: center;
        gap: clamp(16px, 1.25vw, 24px);
    }
    .safezone-warning__icon {
        display: grid;
        flex: 0 0 clamp(58px, 4vw, 76px);
        width: clamp(58px, 4vw, 76px);
        height: clamp(58px, 4vw, 76px);
        place-items: center;
        border: 1px solid rgba(255, 181, 46, 0.28);
        border-radius: 12px;
        background: rgba(255, 181, 46, 0.1);
        color: #ffb52e;
        font-size: clamp(25px, 1.75vw, 34px);
        box-shadow: inset 0 0 28px rgba(255, 181, 46, 0.05);
    }
    .safezone-warning__heading span {
        display: block;
        margin-bottom: 5px;
        color: #ffb52e;
        font-size: clamp(10px, 0.62vw, 12px);
        font-weight: 800;
        letter-spacing: 0.24em;
    }
    .safezone-warning__heading h1 {
        font-family: 'Barlow', sans-serif;
        font-size: clamp(27px, 2vw, 39px);
        font-style: italic;
        font-weight: 800;
        line-height: 1;
        text-transform: uppercase;
    }
    .safezone-warning__description {
        max-width: 92%;
        margin-top: clamp(22px, 1.55vw, 30px);
        color: rgba(255, 255, 255, 0.63);
        font-size: clamp(13px, 0.82vw, 16px);
        font-weight: 500;
        line-height: 1.55;
    }
    .safezone-warning__route {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: clamp(8px, 0.65vw, 13px);
        margin-top: clamp(20px, 1.4vw, 27px);
        padding: clamp(12px, 0.9vw, 17px) clamp(14px, 1vw, 20px);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 9px;
        background: rgba(0, 0, 0, 0.34);
        color: rgba(255, 255, 255, 0.82);
        font-size: clamp(11px, 0.72vw, 14px);
        font-weight: 700;
        white-space: nowrap;
    }
    .safezone-warning__route > i {
        color: rgba(255, 255, 255, 0.2);
        font-size: 9px;
    }
    .safezone-warning__key {
        padding: 5px 9px;
        border: 1px solid rgba(255, 255, 255, 0.26);
        border-bottom-width: 3px;
        border-radius: 5px;
        background: rgba(255, 255, 255, 0.08);
        color: #fff;
        font-size: 0.88em;
        letter-spacing: 0.05em;
    }
    .safezone-warning__instruction {
        display: flex;
        align-items: center;
        gap: clamp(12px, 0.9vw, 18px);
        margin-top: 12px;
        padding: clamp(14px, 1vw, 19px);
        border-radius: 9px;
        background: #f2f2f2;
        color: #101012;
    }
    .safezone-warning__instruction p {
        flex: 1;
        font-size: clamp(12px, 0.78vw, 15px);
        font-weight: 500;
        line-height: 1.35;
    }
    .safezone-warning__instruction strong {
        font-weight: 800;
    }
    .safezone-warning__instruction > i {
        color: #101012;
        font-size: clamp(16px, 1.15vw, 22px);
    }
</style>
