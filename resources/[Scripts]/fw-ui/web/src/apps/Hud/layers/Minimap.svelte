<script>
    import { onMount } from "svelte";
    import { OnEvent } from "../../../utils/Utils";
    import { MyPreferences } from "../../Preferences/preferences.store.js";

    import { LayoutEditing } from "../hud.store.js";
    import { Layout } from "../layout.js";
    import { BlipSprites, BlipColours } from "../blips.js";

    // sample waypoint while the layout editor is open
    $: ShownWaypoint = Waypoint || ($LayoutEditing ? { Distance: "1.20 km", Direction: "right" } : false);

    const DirectionAngles = { straight: 0, right: 90, left: -90, back: 180 };

    let Visible = false;
    let Street = "";
    let Zone = "";
    let Waypoint = false;

    // Heading animation (camera bearing, also rotates the map)
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

    // --- Map ----------------------------------------------------------------
    // World -> map image pixels (same calibration as the dispatch map, 6144px image cut in 512px tiles).
    const ToImage = (X, Y) => [0.49728 * X + 2815.2, -0.492 * Y + 4147.2];
    const PixelsPerMeter = 0.495;
    const TileSize = 512, TileCount = 12;
    const Ocean = "#0fa8d2";
    const BlipSize = 17, ArrowSize = 9;

    let Canvas;
    let MapFrame = null, MapLast = null;
    let Target = null, Pos = null;
    let Blips = [], Route = [], RouteColour = "#3fc8f4";

    const Tiles = {}, Icons = {};

    const GetTile = (X, Y) => {
        const Key = `${X}_${Y}`;
        if (!Tiles[Key]) {
            Tiles[Key] = new Image();
            Tiles[Key].src = `./images/minimap/${Key}.webp`;
        }
        return Tiles[Key].complete && Tiles[Key].naturalWidth ? Tiles[Key] : null;
    };

    // Blip icons are white with a black outline: multiply by the blip colour like the game does.
    const GetIcon = (Sprite, Colour) => {
        const Key = `${Sprite}_${Colour}`;
        if (Icons[Key] !== undefined) return Icons[Key];

        const Name = BlipSprites[Sprite];
        if (!Name) return (Icons[Key] = null);

        Icons[Key] = false; // loading
        const Img = new Image();
        Img.onload = () => {
            const C = document.createElement("canvas");
            C.width = Img.width; C.height = Img.height;
            const Ctx = C.getContext("2d");
            Ctx.drawImage(Img, 0, 0);
            const Hex = BlipColours[Colour];
            if (Hex && Colour != 0) {
                Ctx.globalCompositeOperation = "multiply";
                Ctx.fillStyle = Hex;
                Ctx.fillRect(0, 0, C.width, C.height);
                Ctx.globalCompositeOperation = "destination-in";
                Ctx.drawImage(Img, 0, 0);
            }
            Icons[Key] = C;
        };
        Img.onerror = () => (Icons[Key] = null);
        Img.src = `./images/blips/${Name}.png`;
        return false;
    };

    const DrawMap = (Timestamp) => {
        MapFrame = requestAnimationFrame(DrawMap);
        if (!Canvas || !Target) return;

        const Dt = MapLast === null ? 16.67 : Math.min(100, Timestamp - MapLast);
        MapLast = Timestamp;

        // Smooth between the ~30 fps position updates, snap on teleports.
        if (!Pos || Math.hypot(Target.X - Pos.X, Target.Y - Pos.Y) > 150) Pos = { ...Target };
        const K = 1 - Math.exp(-Dt / 45), KZ = 1 - Math.exp(-Dt / 300);
        Pos.X += (Target.X - Pos.X) * K;
        Pos.Y += (Target.Y - Pos.Y) * K;
        Pos.Zoom += (Target.Zoom - Pos.Zoom) * KZ;
        Pos.Heading = Target.Heading;

        const Dpr = window.devicePixelRatio || 1;
        const Size = Math.round(Canvas.clientWidth * Dpr);
        if (Canvas.width != Size) Canvas.width = Canvas.height = Size;

        const Ctx = Canvas.getContext("2d");
        const R = Size / 2;
        const Scale = R / (Pos.Zoom * PixelsPerMeter);
        const Angle = -RenderedHeading * Math.PI / 180;
        const Cos = Math.cos(Angle), Sin = Math.sin(Angle);
        const [IX, IY] = ToImage(Pos.X, Pos.Y);

        Ctx.setTransform(1, 0, 0, 1, 0, 0);
        Ctx.clearRect(0, 0, Size, Size);
        Ctx.save();
        Ctx.beginPath();
        Ctx.arc(R, R, R, 0, Math.PI * 2);
        Ctx.clip();
        Ctx.fillStyle = Ocean;
        Ctx.fillRect(0, 0, Size, Size);

        // Tiles + route in map space
        Ctx.translate(R, R);
        Ctx.rotate(Angle);
        Ctx.scale(Scale, Scale);
        Ctx.translate(-IX, -IY);

        const Reach = (R * 1.45) / Scale;
        for (let TY = Math.max(0, Math.floor((IY - Reach) / TileSize)); TY <= Math.min(TileCount - 1, Math.floor((IY + Reach) / TileSize)); TY++) {
            for (let TX = Math.max(0, Math.floor((IX - Reach) / TileSize)); TX <= Math.min(TileCount - 1, Math.floor((IX + Reach) / TileSize)); TX++) {
                const Tile = GetTile(TX, TY);
                if (Tile) Ctx.drawImage(Tile, TX * TileSize, TY * TileSize, TileSize + 0.5, TileSize + 0.5);
            }
        }

        if (Route.length >= 4) {
            Ctx.beginPath();
            Ctx.moveTo(IX, IY);
            for (let i = 0; i < Route.length; i += 2) Ctx.lineTo(...ToImage(Route[i], Route[i + 1]));
            Ctx.lineCap = Ctx.lineJoin = "round";
            Ctx.strokeStyle = "rgba(0, 0, 0, 0.35)";
            Ctx.lineWidth = (9 * Dpr) / Scale;
            Ctx.stroke();
            Ctx.strokeStyle = RouteColour;
            Ctx.lineWidth = (6 * Dpr) / Scale;
            Ctx.stroke();
        }

        // Blips in screen space so they stay upright; long-range ones stick to the edge.
        Ctx.setTransform(1, 0, 0, 1, 0, 0);
        const Half = (BlipSize * Dpr) / 2;
        for (const [X, Y, Sprite, Colour, ShortRange] of Blips) {
            const Icon = GetIcon(Sprite, Colour);
            if (!Icon) continue;

            const [BX, BY] = ToImage(X, Y);
            const DX = (BX - IX) * Scale, DY = (BY - IY) * Scale;
            let SX = DX * Cos - DY * Sin, SY = DX * Sin + DY * Cos;

            const Dist = Math.hypot(SX, SY), Max = R - Half - 2 * Dpr;
            if (Dist > Max) {
                if (ShortRange) continue;
                SX *= Max / Dist; SY *= Max / Dist;
            }
            Ctx.drawImage(Icon, R + SX - Half, R + SY - Half, Half * 2, Half * 2);
        }

        // Player arrow: ped bearing relative to the camera bearing.
        Ctx.translate(R, R);
        Ctx.rotate((-Pos.Heading - RenderedHeading) * Math.PI / 180);
        const A = ArrowSize * Dpr;
        Ctx.beginPath();
        Ctx.moveTo(0, -A);
        Ctx.lineTo(A * 0.75, A);
        Ctx.lineTo(0, A * 0.45);
        Ctx.lineTo(-A * 0.75, A);
        Ctx.closePath();
        Ctx.fillStyle = "#fff";
        Ctx.strokeStyle = "#1b1b1f";
        Ctx.lineWidth = 2 * Dpr;
        Ctx.lineJoin = "round";
        Ctx.stroke();
        Ctx.fill();

        Ctx.restore();
    };

    const StartMap = () => {
        if (MapFrame === null) MapFrame = requestAnimationFrame(DrawMap);
    };

    const StopMap = () => {
        if (MapFrame !== null) cancelAnimationFrame(MapFrame);
        MapFrame = null;
        MapLast = null;
        Pos = null;
    };

    $: (Visible || $LayoutEditing) ? StartMap() : StopMap();

    OnEvent("Hud", "SetMinimapVisibility", (Data) => {
        Visible = Data.Visible;
        if (!Visible) {
            StopAnimation();
            Waypoint = false;
        };
    });

    OnEvent("Hud", "SetMinimapPosition", (Data) => Target = Data);
    OnEvent("Hud", "SetMinimapBlips", (Data) => Blips = Data.Blips || []);
    OnEvent("Hud", "SetMinimapRoute", (Data) => {
        Route = Data.Points || [];
        if (Data.Colour) RouteColour = Data.Colour;
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

    onMount(() => () => {
        StopAnimation();
        StopMap();
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

    <div class="compass__ring">
        <canvas class="compass__map" bind:this={Canvas}></canvas>
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
    

    .compass__map {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        z-index: 0;
        border-radius: 50%;
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