<script>
    import Header from "./Header.svelte";
    import Rails from "./Rails.svelte";
    import { LocalImage } from "../images";
    import { Skin, Post, RefreshPrice, LuaIndex, SetSkin } from "../clothing.store";

    export let Path = [];
    export let Leaf = {};
    export let RailProps = {};
    export let Navigate = (NewPath) => {};

    // Rows: { Key, Title, Min, Max, MinLabel, MaxLabel, Get(skin), Send(value), Face? }
    const FeatureRow = ([Id, ValueId, Title, MinLabel, MaxLabel]) => ({
        Key: `${Id}-${ValueId}`, Title, MinLabel, MaxLabel, Min: -100, Max: 100, Decimals: true,
        Get: (S) => Number(LuaIndex(S[Id], ValueId) ?? 0),
        Send: (V) => {
            SetSkin(Id, ValueId, V);
            return Post("Clothing/ProcessSliderChange", { componentId: Id, valueId: ValueId, value: V });
        },
    });

    const ParentRow = (Id, Index, Title, MinLabel, MaxLabel, Face) => ({
        Key: `${Id}-${Index}`, Title, MinLabel, MaxLabel, Min: 0, Max: 45, Face,
        Get: (S) => Number(LuaIndex(S[Id], Index) ?? 0),
        Send: (V) => {
            SetSkin(Id, Index, V);
            return Post("Clothing/ProcessComponentChange", { componentId: Id, value: V, type: Index == 0 ? "Drawable" : "Texture" });
        },
    });

    const MixRow = (Id, Title, MinLabel, MaxLabel) => ({
        Key: Id, Title, MinLabel, MaxLabel, Min: 0, Max: 100, Percent: true,
        Get: (S) => Number(S[Id] ?? 0),
        Send: (V) => {
            Skin.update((S) => ({ ...S, [Id]: V }));
            return Post("Clothing/ProcessSliderChange", { componentId: Id, value: V });
        },
    });

    $: Rows = Leaf.Kind == "headblend" ? [
        ParentRow("FaceOne", 0, "FATHER FACE", "", "", true),
        ParentRow("FaceTwo", 0, "MOTHER FACE", "", "", true),
        MixRow("FaceMix", "FACE SHAPE MIX", "FATHER", "MOTHER"),
        ParentRow("FaceOne", 1, "FATHER SKIN TONE", "LIGHT", "DARK"),
        ParentRow("FaceTwo", 1, "MOTHER SKIN TONE", "LIGHT", "DARK"),
        MixRow("SkinMix", "SKIN TONE MIX", "FATHER", "MOTHER"),
        ParentRow("FaceThree", 0, "EXTRA FACE", "", "", true),
        ParentRow("FaceThree", 1, "EXTRA SKIN TONE", "LIGHT", "DARK"),
        MixRow("ThirdFaceMix", "EXTRA MIX", "NONE", "FULL"),
    ] : (Leaf.Sliders || []).map(FeatureRow);

    // Only send the newest value of a slider, at most every 60ms.
    const Pending = {};
    const Update = (Row, Value) => {
        Value = Math.min(Math.max(Math.round(Value), Row.Min), Row.Max);
        const Entry = Pending[Row.Key] || (Pending[Row.Key] = { Busy: false, Next: undefined });
        Entry.Next = Value;
        if (Entry.Busy) return;

        const Flush = async () => {
            if (Entry.Next == undefined) { Entry.Busy = false; return RefreshPrice(); }
            Entry.Busy = true;
            const V = Entry.Next;
            Entry.Next = undefined;
            await Row.Send(V);
            setTimeout(Flush, 60);
        };
        Flush();
    };

    const Display = (Row, V) => Row.Decimals ? (V / 100).toFixed(2) : Row.Percent ? `${Math.round(V)}%` : Math.round(V);
    const Pct = (Row, V) => Math.min(Math.max(((V - Row.Min) / (Row.Max - Row.Min)) * 100, 0), 100);
    const FaceImage = (V) => LocalImage(`faces/SKEL_ROOT.${String(V).padStart(3, "0")}.webp`);
</script>

<div class="column enter" style="width: 560px;">
    <Header {Path} {Navigate} />

    <div style="display: flex; gap: 3px;">
        <Rails {Path} {Navigate} {...RailProps} />

        <div class="rows scroll">
            {#each Rows as Row (Row.Key)}
                {@const V = Row.Get($Skin)}
                <div style="display: flex; flex-direction: column; gap: 4px; box-shadow: 0 4px 6px rgba(0,0,0,.2);">
                    <div class="box-title">
                        <span>{Row.Title}</span>
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <button class="step" on:click={() => Update(Row, V - (Row.Decimals ? 5 : 1))}>‹</button>
                            <span class="value">{Display(Row, V)}</span>
                            <button class="step" on:click={() => Update(Row, V + (Row.Decimals ? 5 : 1))}>›</button>
                        </div>
                    </div>

                    <div class="box-body slider-row">
                        {#if Row.Face}
                            <img class="face" src={FaceImage(V)} alt="" draggable="false" />
                        {:else}
                            <span class="end bebas italic" style="text-align: right;">{Row.MinLabel}</span>
                        {/if}

                        <input
                            type="range" min={Row.Min} max={Row.Max} step="1" value={V}
                            on:input={(e) => Update(Row, Number(e.target.value))}
                            style="background: linear-gradient(to right, #ffffff {Pct(Row, V)}%, #3f3f46 {Pct(Row, V)}%);"
                        />

                        {#if !Row.Face}
                            <span class="end bebas italic">{Row.MaxLabel}</span>
                        {:else}
                            <span class="end bebas italic" style="width: 48px;">#{Math.round(V)}</span>
                        {/if}
                    </div>
                </div>
            {/each}
        </div>
    </div>
</div>

<style>
    .rows { flex: 1; display: flex; flex-direction: column; gap: 14px; max-height: 760px; height: fit-content; padding-right: 4px; }
    .step { width: 20px; height: 20px; background: black !important; color: white !important; font-weight: 700; font-size: 12px; display: flex; align-items: center; justify-content: center; line-height: 1; }
    .step:hover { background: #27272a !important; }
    .value { min-width: 36px; text-align: center; font-size: 12px; font-weight: 700; padding: 2px 6px; background: black; color: white; line-height: 1; }
    .slider-row { padding: 14px; display: flex; align-items: center; justify-content: space-between; gap: 12px; }
    .end { font-size: 17px; letter-spacing: 0.05em; color: rgba(255,255,255,.9); width: 80px; flex-shrink: 0; text-transform: uppercase; }
    .face { width: 56px; height: 56px; object-fit: cover; flex-shrink: 0; background: #0e1015; border: 1px solid rgba(255,255,255,.1); }
</style>
