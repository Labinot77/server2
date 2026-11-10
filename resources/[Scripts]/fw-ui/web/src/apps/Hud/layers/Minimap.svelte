<script>
    import { onMount } from "svelte";
    import { OnEvent, SendEvent as _SendEvent } from "../../../utils/Utils";
    import { MyPreferences } from "../../Preferences/preferences.store.js";

    import { LayoutEditing, LayoutRevision } from "../hud.store.js";
    import { Layout } from "../layout.js";

    // sample waypoint while the layout editor is open
    $: ShownWaypoint = Waypoint || ($LayoutEditing ? { Distance: "1.20 km", Direction: "right" } : false);

    // the layout editor moves/scales .compass, so measure the ring again (put after ScheduleRadarSync is defined)
    $: if ($LayoutRevision) ScheduleRadarSync(250, false);

    const SendEvent = (Event, Parameters, Callback) => _SendEvent(Event, Parameters, Callback, "fw-hud");

    const DirectionAngles = { straight: 0, right: 90, left: -90, back: 180 };

    let Visible = false;
    let Street = "";
    let Zone = "";
    let Waypoint = false;

    // Heading animation
    let TargetHeading = null;
    let RenderedHeading = 0;
    let Frame = null;
    let LastFrame = null;

    const Normalize = (Heading) => ((Heading % 360) + 360) % 360;
    const ShortestDelta = (From, To) => ((To - From + 540) % 360) - 180;

    const Schedule = () => {
        if (Frame === null) Frame = requestAnimationFrame(Render);
    };

    const Render = (Timestamp) => {
        Frame = null;
        if (TargetHeading === null) return;

        const Elapsed = LastFrame === null ? 16.67 : Math.min(50, Timestamp - LastFrame);
        LastFrame = Timestamp;

        const Delta = ShortestDelta(RenderedHeading, TargetHeading);
        if (Math.abs(Delta) <= 0.02) {
            RenderedHeading = TargetHeading;
            LastFrame = null;
            return;
        }

        RenderedHeading = Normalize(RenderedHeading + (Delta * (1 - Math.exp(-Elapsed / 28))));
        Schedule();
    };

    const StopAnimation = () => {
        if (Frame !== null) cancelAnimationFrame(Frame);
        Frame = null;
        TargetHeading = null;
        LastFrame = null;
    };

    // Radar sync: measure the real ring and tell fw-hud where it is.
    let Ring;
    let ScreenRevision = null;
    let LastSent = null;
    let SyncTimer;
    let RetryCount = 0;

    const Round5 = (Value) => Math.round(Value * 100000) / 100000;

    const SendRadarLayout = (Force) => {
        if (!Ring || !Visible || ScreenRevision === null) return;

        const Rect = Ring.getBoundingClientRect();
        if (Rect.width < 2 || Rect.height < 2) return;

        const Layout = {
            revision: ScreenRevision,
            cx: Round5((Rect.left + Rect.width / 2) / window.innerWidth),
            cy: Round5((Rect.top + Rect.height / 2) / window.innerHeight),
            diameter: Round5(Math.max(Rect.width, Rect.height) / window.innerHeight),
            dx: Round5(Rect.width / window.innerWidth),
            dy: Round5(Rect.height / window.innerHeight),
        };

        if (!Force && LastSent
            && LastSent.revision == Layout.revision
            && Math.abs(LastSent.cx - Layout.cx) < 0.0002
            && Math.abs(LastSent.cy - Layout.cy) < 0.0002
            && Math.abs(LastSent.diameter - Layout.diameter) < 0.0002) return;

        SendEvent("Minimap/RadarLayout", Layout, (Success, Reply) => {
            if (Success && Reply && Reply.ok) {
                LastSent = Layout;
                RetryCount = 0;
            } else if (Success && Reply && Reply.screen && RetryCount < 5) {
                // Screen changed while measuring, adopt the new revision and retry.
                RetryCount++;
                ScreenRevision = Reply.screen.revision;
                ScheduleRadarSync(120, true);
            }
        });
    };

    const ScheduleRadarSync = (Delay, Force) => {
        clearTimeout(SyncTimer);
        SyncTimer = setTimeout(() => SendRadarLayout(Force), Delay);
    };

    const HandleScreenChange = (Screen) => {
        if (Screen && typeof Screen.revision == "number") ScreenRevision = Screen.revision;
        LastSent = null;
        RetryCount = 0;

        // CEF resizes a moment after the game does, measure a few times to settle.
        [60, 300, 900].forEach((Delay) => setTimeout(() => SendRadarLayout(true), Delay));
    };

    OnEvent("Hud", "SetScreen", (Data) => HandleScreenChange(Data.Screen));

    OnEvent("Hud", "SetMinimapVisibility", (Data) => {
        Visible = Data.Visible;

        if (Visible) {
            ScheduleRadarSync(50, true);
        } else {
            StopAnimation();
            Waypoint = false;
        };
    });

    OnEvent("Hud", "SetCompassHeading", (Data) => {
        const Heading = Normalize(Number(Data.Heading) || 0);

        if (TargetHeading === null) RenderedHeading = Heading;
        TargetHeading = Heading;
        Schedule();
    });

    OnEvent("Hud", "SetCompassDetails", (Data) => {
        Street = Data.Street;
        Zone = Data.Zone;
    });

    OnEvent("Hud", "SetWaypoint", (Data) => {
        Waypoint = Data.Visible ? { Distance: Data.Distance, Direction: Data.Direction } : false;
    });

    onMount(() => {
        const OnResize = () => HandleScreenChange(null);
        window.addEventListener("resize", OnResize);

        let Observer;
        if (typeof ResizeObserver == "function") {
            Observer = new ResizeObserver(() => ScheduleRadarSync(150, false));
            Observer.observe(document.documentElement);
        };

        SendEvent("Minimap/ScreenReady", {}, (Success, Reply) => {
            if (Success && Reply && Reply.screen) HandleScreenChange(Reply.screen);
        });

        return () => {
            window.removeEventListener("resize", OnResize);
            if (Observer) Observer.disconnect();
            clearTimeout(SyncTimer);
            StopAnimation();
        };
    });
</script>

<svg width="0" height="0" aria-hidden="true" focusable="false" style="position: absolute;">
    <defs>
        <clipPath id="waypoint-arc-clip" clipPathUnits="objectBoundingBox">
            <path d="M 0 0 H 0.765 C 0.81 0.24 0.91 0.70 1 1 H 0 Z"></path>
        </clipPath>
    </defs>
</svg>

<div class="compass" use:Layout={"compass"} style:display={(Visible || $LayoutEditing) ? "flex" : "none"}>
    {#if $MyPreferences['Compass.Show']}
        <div class="compass__degree"><span>{Math.round(RenderedHeading) % 360}</span>&deg;</div>
    {/if}

    <div class="compass__ring" bind:this={Ring}>
        <div class="compass__border"></div>

        <div class="compass__letters" style="transform: rotate({-RenderedHeading}deg);">
            <span class="compass__intercardinal compass__intercardinal--ne"></span>
            <span class="compass__intercardinal compass__intercardinal--se"></span>
            <span class="compass__intercardinal compass__intercardinal--sw"></span>
            <span class="compass__intercardinal compass__intercardinal--nw"></span>
            <span class="compass__tick compass__tick--north"></span>
            <span class="compass__tick compass__tick--east"></span>
            <span class="compass__tick compass__tick--south"></span>
            <span class="compass__tick compass__tick--west"></span>

            <div class="compass__letter compass__letter--north" style="transform: translate(-50%, -50%) rotate({RenderedHeading}deg);">N</div>
            <div class="compass__letter compass__letter--east" style="transform: translate(-50%, -50%) rotate({RenderedHeading}deg);">E</div>
            <div class="compass__letter compass__letter--south" style="transform: translate(-50%, -50%) rotate({RenderedHeading}deg);">S</div>
            <div class="compass__letter compass__letter--west" style="transform: translate(-50%, -50%) rotate({RenderedHeading}deg);">W</div>
        </div>
    </div>

{#if ShownWaypoint}
        <div class="compass__waypoint">
            <i class="fas fa-arrow-up compass__waypoint-icon" style="transform: rotate({DirectionAngles[Waypoint.Direction] || 0}deg);"></i>
            <span class="compass__waypoint-distance">{Waypoint.Distance}</span>
        </div>
    {/if}

    {#if $MyPreferences['Compass.Show']}
        <div class="compass__location">
            <div class="compass__zone">{Zone}</div>
            <div class="compass__street">{Street}</div>
        </div>
    {/if}
</div>

<style>
    .compass {
        position: absolute;
        top: 10vh;
        right: 1vw;
        width: 14.5vw;
        pointer-events: none;
    }

    .compass__degree {
        position: absolute;
        top: -4.6vh;
        left: 36.2%;
        z-index: 5;
        transform: translateX(-50%);
        min-width: 4.6vw;
        padding: 0.12vh 0.75vw 0.18vh;
        background: linear-gradient(90deg, rgba(12, 12, 15, 0) 0%, rgba(12, 12, 15, 0.5) 28%, rgba(12, 12, 15, 0.5) 72%, rgba(12, 12, 15, 0) 100%);
        color: #fff;
        font-family: 'Barlow Semi Condensed', 'Barlow', Arial, sans-serif;
        font-size: 1.1vw;
        font-weight: 800;
        line-height: 1.05;
        text-align: center;
        text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
    }

    .compass__ring {
        position: relative;
        width: 10.5vw;
        height: 10.5vw;
        border-radius: 50%;
        isolation: isolate;
    }
    

    .compass__border {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: 0;
        border-radius: 50%;
    }

    .compass__border::before {
        position: absolute;
        inset: -22px;
        z-index: -1;
        border-radius: 50%;
        background: radial-gradient(
            circle closest-side at center,
            transparent calc(100% - 22px),
            rgba(12, 12, 15, 0.5) calc(100% - 22px),
            rgba(12, 12, 15, 0.5) calc(100% - 8px),
            rgba(12, 12, 15, 0) 100%
        );
        content: '';
        pointer-events: none;
    }

    .compass__border::after {
        position: absolute;
        inset: 0;
        z-index: 2;
        border: 3px solid #fff;
        border-radius: 50%;
        content: '';
        pointer-events: none;
    }

    .compass__letters {
        position: absolute;
        top: 1px;
        left: 1px;
        width: calc(100% - 2px);
        height: calc(100% - 2px);
        z-index: 1;
        border-radius: 50%;
        transform-origin: center;
    }

    .compass__tick {
        position: absolute;
        z-index: 0;
        display: block;
        border-radius: 1px;
        background: #fff;
        pointer-events: none;
    }

    .compass__tick--north,
    .compass__tick--south {
        left: 50%;
        width: 1px;
        height: 14px;
        transform: translateX(-50%);
    }

    .compass__tick--north { top: -15px; }
    .compass__tick--south { bottom: -15px; }

    .compass__tick--east,
    .compass__tick--west {
        top: 50%;
        width: 14px;
        height: 1px;
        transform: translateY(-50%);
    }

    .compass__tick--east { right: -15px; }
    .compass__tick--west { left: -15px; }

    .compass__intercardinal {
        position: absolute;
        inset: -15px;
        z-index: 0;
        display: block;
        border-radius: 50%;
        pointer-events: none;
    }

    .compass__intercardinal::before {
        position: absolute;
        top: 0;
        left: 50%;
        width: 1px;
        height: 5px;
        border-radius: 1px;
        background: #fff;
        content: '';
        transform: translateX(-50%);
    }

    .compass__intercardinal--ne { transform: rotate(45deg); }
    .compass__intercardinal--se { transform: rotate(135deg); }
    .compass__intercardinal--sw { transform: rotate(225deg); }
    .compass__intercardinal--nw { transform: rotate(315deg); }

    .compass__letter {
        position: absolute;
        color: #fff;
        font-family: 'Barlow Semi Condensed', 'Barlow', Arial, sans-serif;
        font-size: 0.95vw;
        font-weight: 800;
        -webkit-text-stroke: 0.6px rgba(0, 0, 0, 0.85);
        text-shadow: 0 0 4px rgba(0, 0, 0, 0.95), 1px 1px 3px rgba(0, 0, 0, 0.9);
    }

    .compass__letter--north {
        top: 0;
        left: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 1.02vw;
        height: 1.02vw;
        z-index: 1;
        background: transparent;
        color: #090909;
        font-size: 0.76vw;
        line-height: 1;
        -webkit-text-stroke: 0;
        text-shadow: none;
    }

    .compass__letter--north::before {
        position: absolute;
        inset: 0;
        z-index: -1;
        border-radius: 1px;
        background: #fff;
        box-shadow: 0 2px 5px rgba(0, 0, 0, 0.45);
        content: '';
        transform: rotate(45deg);
    }

    .compass__letter--south { top: 100%; left: 50%; }
    .compass__letter--east { top: 50%; left: 100%; }
    .compass__letter--west { top: 50%; left: 0; }

    .compass__waypoint {
        position: absolute;
        top: 82%;
        right: calc(100% - 1.30vw);
        z-index: 6;
        display: flex;
        align-items: center;
        width: 5.9vw;
        gap: 5px;
        transform: translateY(-50%);
        padding: 4px 34px 4px 8px;
        -webkit-clip-path: url('#waypoint-arc-clip');
        clip-path: url('#waypoint-arc-clip');
        background: #fff;
        border-radius: 2px 0 2px 2px;
        color: #090909;
        font-family: 'Barlow Semi Condensed', 'Barlow', Arial, sans-serif;
        font-size: 0.82vw;
        font-style: italic;
        font-weight: 800;
        letter-spacing: 0.25px;
        white-space: nowrap;
        filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.45));
    }

    .compass__waypoint-icon {
        display: inline-flex;
        flex: 0 0 0.85vw;
        align-items: center;
        justify-content: center;
        width: 0.85vw;
        font-size: 0.75vw;
        line-height: 1;
        color: #090909;
        transition: transform 0.2s ease;
    }

    .compass__waypoint-distance {
        flex: 1 0 auto;
        color: #090909;
        font-variant-numeric: tabular-nums;
    }

    .compass__location {
        position: absolute;
        bottom: -5.9vh;
        left: 35%;
        width: 200%;
        transform: translateX(-50%);
        color: #fff;
        font-family: 'Barlow', Arial, sans-serif;
        font-style: italic;
        font-weight: 800;
        line-height: 1.1;
        text-align: center;
        text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
    }

    .compass__zone {
        display: inline-block;
        min-width: 8vw;
        padding: 0.08vh 1.4vw 0.14vh;
        background: linear-gradient(90deg, rgba(12, 12, 15, 0) 0%, rgba(12, 12, 15, 0.5) 28%, rgba(12, 12, 15, 0.5) 72%, rgba(12, 12, 15, 0) 100%);
        font-size: 0.9vw;
        letter-spacing: 1px;
    }

    .compass__street {
        font-size: 1vw;
        letter-spacing: 0.5px;
    }
</style>