<script>
    import { createEventDispatcher } from "svelte";
    import { HexToHsv, HsvToHex, NearestPaletteIndex } from "../bennys.utils";

    export let Hex = "#000000";
    export let Mode = "Custom";      // Custom | RGB | Index
    export let Palette = [];
    export let PaintTypes = [];
    export let PaintType = null;      // number, or null to hide the finish tabs
    export let SelectedIndex = null;  // Index mode

    const Dispatch = createEventDispatcher();

    let H = 0, S = 0, V = 0;
    let LastHex = null;

    // Only resync HSV when the value changed from outside (avoids hue jumping while dragging).
    $: if (Hex !== LastHex) {
        const Hsv = HexToHsv(Hex);
        if (Hsv.S > 0 && Hsv.V > 0) H = Hsv.H;
        S = Hsv.S;
        V = Hsv.V;
        LastHex = Hex;
    }

    $: CurrentHex = HsvToHex(H, S, V);

    const Emit = () => {
        // $: CurrentHex hasn't updated yet inside the same tick, so compute it here.
        const NewHex = HsvToHex(H, S, V);
        LastHex = NewHex;
        if (Mode === "Index") {
            const Index = NearestPaletteIndex(NewHex, Palette);
            LastHex = Palette[Index]; // Keep the handle where the user drags, not on the snapped colour.
            Dispatch("change", { Value: Index, Hex: Palette[Index] });
        } else {
            Dispatch("change", { Value: NewHex, Hex: NewHex });
        }
    };

    const Drag = (Node, Handler) => {
        const Move = Event => {
            const Rect = Node.getBoundingClientRect();
            const X = Math.max(0, Math.min(1, (Event.clientX - Rect.left) / Rect.width));
            const Y = Math.max(0, Math.min(1, (Event.clientY - Rect.top) / Rect.height));
            Handler(X, Y);
            Emit();
        };
        const Up = () => {
            window.removeEventListener("pointermove", Move);
            window.removeEventListener("pointerup", Up);
        };
        const Down = Event => {
            Event.preventDefault();
            Move(Event);
            window.addEventListener("pointermove", Move);
            window.addEventListener("pointerup", Up);
        };
        Node.addEventListener("pointerdown", Down);
        return { destroy: () => { Node.removeEventListener("pointerdown", Down); Up(); } };
    };

    const SetSV = (X, Y) => { S = X; V = 1 - Y; };
    const SetHue = X => { H = X * 359.9; };

    const PickSwatch = Index => {
        LastHex = Palette[Index];
        Dispatch("change", { Value: Index, Hex: Palette[Index] });
    };
</script>

<div class="picker-row">
    <div class="picker">
        <div class="picker-sv" style="background-color: hsl({H}, 100%, 50%)" use:Drag={SetSV}>
            <div class="picker-sv-white"></div>
            <div class="picker-sv-black"></div>
            <div class="picker-sv-handle" style="left: {S * 100}%; top: {(1 - V) * 100}%; background-color: {CurrentHex}"></div>
        </div>

        <div class="picker-hue" use:Drag={SetHue}>
            <div class="picker-hue-handle" style="left: {(H / 360) * 100}%"></div>
        </div>

        <div class="picker-hex">
            <span class="picker-hex-swatch" style="background-color: {Mode === 'Index' && SelectedIndex !== null ? Palette[SelectedIndex] : CurrentHex}"></span>
            <span>{(Mode === "Index" && SelectedIndex !== null ? Palette[SelectedIndex] : CurrentHex).toUpperCase()}</span>
            {#if Mode === "Index" && SelectedIndex !== null}
                <span class="picker-hex-index">#{SelectedIndex}</span>
            {/if}
        </div>
    </div>

    {#if Mode === "Index"}
        <div class="palette">
            <p class="palette-title">GTA Colors</p>
            <div class="palette-grid">
                {#each Palette as Color, Index}
                    <button
                        class="palette-swatch"
                        class:active={SelectedIndex === Index}
                        style="background-color: {Color}"
                        on:click={() => PickSwatch(Index)}
                    ></button>
                {/each}
            </div>
        </div>
    {/if}
</div>

{#if PaintType !== null}
    <div class="paint-types">
        <p class="paint-title">Color Type</p>
        <span class="paint-line"></span>
        {#each PaintTypes as Type}
            <button class="paint-type" class:active={PaintType === Type.Value} on:click={() => Dispatch("paint", Type)}>
                {Type.Label}
            </button>
        {/each}
    </div>
{/if}

<style>
    .picker-row {
        display: flex;
        align-items: flex-end;
        gap: 1vh;
        margin-bottom: 1.2vh;
    }

    .picker {
        width: 15.2vh;
        padding: 0.9vh;
        background-color: var(--bennys-panel);
    }

    .picker-sv {
        position: relative;
        width: 100%;
        height: 11vh;
        cursor: crosshair;
        touch-action: none;
    }

    .picker-sv-white, .picker-sv-black { position: absolute; inset: 0; pointer-events: none; }
    .picker-sv-white { background: linear-gradient(to right, #fff, rgba(255, 255, 255, 0)); }
    .picker-sv-black { background: linear-gradient(to top, #000, rgba(0, 0, 0, 0)); }

    .picker-sv-handle {
        position: absolute;
        width: 1.2vh;
        height: 1.2vh;
        border: 0.2vh solid white;
        border-radius: 50%;
        transform: translate(-50%, -50%);
        box-shadow: 0 0 0.4vh rgba(0, 0, 0, 0.8);
        pointer-events: none;
    }

    .picker-hue {
        position: relative;
        height: 1vh;
        margin-top: 0.8vh;
        cursor: pointer;
        touch-action: none;
        background: linear-gradient(to right, #f00, #ff0, #0f0, #0ff, #00f, #f0f, #f00);
    }

    .picker-hue-handle {
        position: absolute;
        top: 50%;
        width: 0.6vh;
        height: 1.5vh;
        background: white;
        transform: translate(-50%, -50%);
        box-shadow: 0 0 0.4vh rgba(0, 0, 0, 0.8);
        pointer-events: none;
    }

    .picker-hex {
        display: flex;
        align-items: center;
        gap: 0.6vh;
        height: 2.6vh;
        margin-top: 0.8vh;
        padding: 0 0.7vh;

        font-family: "Roboto Mono", monospace;
        font-size: 1.15vh;
        color: white;
        background: rgba(0, 0, 0, 0.45);
    }

    .picker-hex-swatch { width: 1.3vh; height: 1.3vh; border: 0.1vh solid rgba(255, 255, 255, 0.5); }
    .picker-hex-index { margin-left: auto; color: var(--bennys-accent); }

    .palette {
        width: 31vh;
        padding: 0.9vh;
        background-color: var(--bennys-panel);
    }

    .palette-title, .paint-title {
        font-family: "Barlow Semi Condensed", sans-serif;
        font-size: 1.25vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        color: white;
    }

    .palette-grid {
        display: grid;
        grid-template-columns: repeat(16, 1fr);
        gap: 0.25vh;
        margin-top: 0.6vh;
        max-height: 13.2vh;
        overflow-y: auto;
    }

    .palette-swatch {
        all: unset;
        cursor: pointer;
        aspect-ratio: 1;
        border: 0.1vh solid rgba(255, 255, 255, 0.08);
    }

    .palette-swatch:hover { outline: 0.15vh solid white; }
    .palette-swatch.active { outline: 0.2vh solid var(--bennys-accent); outline-offset: 0.05vh; }

    .paint-types {
        display: flex;
        align-items: center;
        gap: 0.5vh;
        margin-bottom: 1.4vh;
    }

    .paint-line { width: 2vh; height: 0.1vh; margin: 0 0.6vh; background: rgba(255, 255, 255, 0.4); }

    .paint-type {
        all: unset;
        cursor: pointer;
        padding: 0.55vh 1.3vh;

        font-family: "Barlow Semi Condensed", sans-serif;
        font-size: 1.2vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        color: white;

        background-color: var(--bennys-panel);
        transition: background 120ms ease, color 120ms ease;
    }

    .paint-type:hover { background-color: var(--bennys-panel-hover); color: var(--bennys-accent); }
    .paint-type.active { background-color: var(--bennys-accent); color: var(--bennys-ink); }

    ::-webkit-scrollbar { width: 0.4vh; }
    ::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.3); }
</style>
