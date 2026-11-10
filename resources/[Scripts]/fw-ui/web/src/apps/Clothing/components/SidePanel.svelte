<script>
    import ItemImage from "./ItemImage.svelte";
    import { ClothingImages } from "../images";
    import { Values, Skin, Meta, Post, RefreshPrice, LuaIndex, SetSkin, HairPalette, MakeupPalette } from "../clothing.store";

    export let Leaf = {};

    let Target = "Primary";
    $: Leaf, (Target = "Primary");

    $: Entry = $Skin[Leaf.Id];
    $: Drawable = Number(LuaIndex(Entry, 0) ?? 0);
    $: Texture = Number(LuaIndex(Entry, 1) ?? 0);
    $: TextureCount = ($Values[Leaf.Id]?.MaxTxts ?? -1) + 1;
    $: HasTextures = (Leaf.Kind == "component" || Leaf.Kind == "hair") && Drawable >= 0;

    $: Palette = Leaf.Palette == "Makeup" ? MakeupPalette : Leaf.Palette == "Hair" ? HairPalette : null;
    // Hair keeps colours on [3]/[4] (0-based 2/3), overlays as well: { style, opacity, colour, second colour }.
    $: Primary = Number(LuaIndex(Entry, 2) ?? 0);
    $: Secondary = Number(LuaIndex(Entry, 3) ?? 0);
    $: Opacity = Number(LuaIndex(Entry, 1) ?? 0);
    $: Selected = Target == "Primary" ? Primary : Secondary;

    const SetTexture = async (Tex) => {
        const Result = await Post("Clothing/ProcessComponentChange", { componentId: Leaf.Id, value: Tex, type: "Texture" });
        if (Result?.Success === false) return;
        SetSkin(Leaf.Id, 1, Tex);
        RefreshPrice();
    };

    const SetColor = async (Index) => {
        SetSkin(Leaf.Id, Target == "Primary" ? 2 : 3, Index);
        await Post("Clothing/ProcessComponentChange", { paletteId: Leaf.Id, value: Index, type: Target });
    };

    let OpacityBusy = false, OpacityNext;
    const SetOpacity = async (V) => {
        SetSkin(Leaf.Id, 1, V);
        OpacityNext = V;
        if (OpacityBusy) return;
        OpacityBusy = true;
        while (OpacityNext != undefined) {
            const Send = OpacityNext;
            OpacityNext = undefined;
            await Post("Clothing/ProcessSliderChange", { componentId: Leaf.Id, valueId: 1, value: Send });
            await new Promise((R) => setTimeout(R, 60));
        }
        OpacityBusy = false;
    };
</script>

<div class="side scroll enter">
    <h1 class="bebas italic">CUSTOMIZATION</h1>

    {#if Palette}
        <div class="block">
            <div class="box-title">COLORS</div>
            <div class="box-body" style="padding: 10px; display: grid; grid-template-columns: {Leaf.Secondary ? '1fr 1fr' : '1fr'}; gap: 8px;">
                <button class="swatch-btn" class:on={Target == "Primary"} on:click={() => (Target = "Primary")}>
                    <div class="swatch" style="background: {Palette[Primary] || '#1c1e1d'};" />
                    <span>{Leaf.Kind == "hair" ? "PRIMARY" : "COLOR"}</span>
                </button>
                {#if Leaf.Secondary}
                    <button class="swatch-btn" class:on={Target == "Secondary"} on:click={() => (Target = "Secondary")}>
                        <div class="swatch" style="background: linear-gradient(135deg, {Palette[Primary] || '#1c1e1d'} 0%, {Palette[Secondary] || '#1c1e1d'} 100%);" />
                        <span>{Leaf.Kind == "hair" ? "HIGHLIGHT" : "SECONDARY"}</span>
                    </button>
                {/if}
            </div>
        </div>

        <div class="block">
            <div class="box-title"><span>PICK COLOR</span><span style="font-size: 12px; color: #52525b; font-weight: 400;">COLOR #{Selected}</span></div>
            <div class="box-body" style="padding: 8px;">
                <div class="palette scroll">
                    {#each Palette as Hex, Index}
                        <button class="color" class:on={Selected == Index} style="background: {Hex};" title="Color #{Index}" on:click={() => SetColor(Index)}>
                            {#if Selected == Index}<div class="dot" />{/if}
                        </button>
                    {/each}
                </div>
            </div>
        </div>
    {/if}

    {#if Leaf.Kind == "overlay"}
        <div class="block">
            <div class="box-title"><span>FADE & OPACITY</span><span class="pct">{Math.round(Opacity)}%</span></div>
            <div class="box-body" style="padding: 12px; display: flex; align-items: center; gap: 8px;">
                <span class="bebas italic" style="font-size: 14px; color: rgba(255,255,255,.7);">MIN</span>
                <input
                    type="range" min="0" max="100" step="1" value={Opacity}
                    on:input={(e) => SetOpacity(Number(e.target.value))}
                    style="background: linear-gradient(to right, var(--bank) {Opacity}%, #3f3f46 {Opacity}%);"
                />
                <span class="bebas italic" style="font-size: 14px; color: rgba(255,255,255,.7);">MAX</span>
            </div>
        </div>
    {/if}

    {#if HasTextures}
        <div class="block">
            <div style="padding: 6px 0; font-size: 14px; font-weight: 700; letter-spacing: 0.05em; text-align: center; background: white; color: black;">
                {Leaf.Kind == "hair" ? "HAIR TEXTURES" : "STYLES"}
            </div>
            <div style="width: 100%; height: 3px; background: white;" />
            <div class="textures scroll">
                {#if TextureCount <= 0}
                    <div class="box-body" style="grid-column: 1 / -1; padding: 16px; text-align: center; font-size: 14px; color: rgba(255,255,255,.6);">NOTHING EQUIPPED</div>
                {/if}
                {#each Array(Math.max(TextureCount, 0)) as _, Tex (Tex)}
                    <button class="tile" class:active={Texture == Tex} on:click={() => SetTexture(Tex)}>
                        <div class="tile-img" style="padding: 4px;">
                            <ItemImage Candidates={Leaf.GtaType ? ClothingImages($Meta.Images, $Meta.Model, Leaf.GtaType, Leaf.GtaId, Drawable, Tex) : []}>
                                <span class="bebas italic" style="font-size: 30px; color: rgba(255,255,255,.5);">{Tex}</span>
                            </ItemImage>
                        </div>
                        <div style="width: 100%; background: #0a0b0e; padding: 4px; text-align: center; font-size: 10px; font-weight: 700; letter-spacing: 0.03em;">TEXTURE {Tex}</div>
                    </button>
                {/each}
            </div>
        </div>
    {/if}
</div>

<style>
    /* Between the money widget (top) and the total cost box (bottom). */
    .side {
        position: absolute; right: 48px; top: 96px; max-height: 760px;
        width: 380px; display: flex; flex-direction: column; gap: 12px; overflow-y: auto; overflow-x: hidden;
    }
    .side::-webkit-scrollbar { width: 0; }
    h1 { font-size: 52px; letter-spacing: 0.05em; text-align: center; line-height: 1; opacity: 0.95; margin: 0 0 4px 0; font-weight: 400; }
    .block { display: flex; flex-direction: column; gap: 4px; box-shadow: 0 4px 6px rgba(0,0,0,.25); }

    .swatch-btn { display: flex; flex-direction: column; align-items: center; padding: 6px; background: #0e1015 !important; border: 1px solid rgba(255,255,255,.1) !important; transition: all .15s; }
    .swatch-btn:hover { border-color: rgba(255,255,255,.3) !important; }
    .swatch-btn.on { border-color: #22d3ee !important; box-shadow: 0 0 0 2px rgba(34, 211, 238, .5); }
    .swatch-btn span { font-size: 12px; font-weight: 700; letter-spacing: 0.05em; }
    .swatch { width: 100%; height: 48px; border: 1px solid rgba(0,0,0,.4); margin-bottom: 6px; }

    .palette { display: grid; grid-template-columns: repeat(8, 1fr); gap: 6px; max-height: 220px; padding-right: 4px; }
    .color { aspect-ratio: 1; width: 100%; border: 1px solid rgba(0,0,0,.5) !important; display: flex; align-items: center; justify-content: center; transition: transform .1s; }
    .color:hover { transform: scale(1.1); z-index: 2; }
    .color.on { border: 2px solid white !important; box-shadow: 0 0 0 2px #22d3ee; transform: scale(1.05); z-index: 3; }
    .dot { width: 6px; height: 6px; border-radius: 9999px; background: white; }
    .pct { background: black; color: #22d3ee; padding: 2px 6px; font-size: 12px; }

    .textures { display: grid; grid-template-columns: repeat(3, 1fr); grid-auto-rows: max-content; gap: 6px; padding-right: 4px; }
</style>
