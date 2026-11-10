<script>
    import Header from "./Header.svelte";
    import Rails from "./Rails.svelte";
    import Icon from "./Icon.svelte";
    import ItemImage from "./ItemImage.svelte";
    import { IconFor, RemoveDefaults } from "../menu";
    import { ClothingImages, LocalImage, PedImages, TattooLabel } from "../images";
    import { Values, Skin, Blocked, Meta, Price, Post, RefreshPrice, LuaIndex, TattooSet, SetSkin } from "../clothing.store";

    export let Path = [];
    export let Label = "";
    export let Leaf = {};
    export let RailProps = {};
    export let Navigate = (NewPath) => {};

    let Search = "";
    $: Label, (Search = "");

    const Range = (From, To) => {
        const R = [];
        for (let i = From; i <= To; i++) R.push(i);
        return R;
    };

    // ---- Items for the current category ----
    $: Max = $Values[Leaf.Id]?.MaxComps ?? 0;
    $: BlockedList = ($Blocked[Leaf.Id] || []).map(Number);
    $: Items = BuildItems(Leaf, Max, BlockedList, $Meta);

    const BuildItems = (Leaf, Max, BlockedList, Meta) => {
        switch (Leaf.Kind) {
            case "component": {
                const List = Leaf.Prop ? Range(-1, Max - 2) : Range(0, Max - 1);
                return List.filter((V) => !BlockedList.includes(V)).map((V) => ({
                    Value: V,
                    Name: V < 0 ? "NONE" : `${Label} ${V}`,
                    Images: ClothingImages(Meta.Images, Meta.Model, Leaf.GtaType, Leaf.GtaId, V, 0),
                }));
            }
            case "hair":
                return Range(0, Max - 1).map((V) => ({ Value: V, Name: `STYLE ${V}`, Images: ClothingImages(Meta.Images, Meta.Model, "component", 2, V, 0) }));
            case "overlay":
                return Range(-1, Max).map((V) => ({
                    Value: V, Name: V < 0 ? "NONE" : `STYLE ${V}`,
                    Images: Leaf.Images ? [LocalImage(`${Leaf.Images}/${V}.webp`)] : [],
                }));
            case "fade":
                return Range(0, Max).map((V) => ({ Value: V, Name: V == 0 ? "NONE" : `FADE ${V}`, Images: [] }));
            case "eyecolor":
                return Range(0, 31).map((V) => ({ Value: V, Name: `COLOR ${V}`, Images: [LocalImage(`eyes/${V}.webp`)] }));
            case "ped":
                return (Meta.PedList || []).map((Model, Index) => ({ Value: Index, Model, Name: Model, Images: PedImages(Model) }));
            case "customped":
                return (Meta.CustomPeds || []).map((Model, Index) => ({ Value: Index, Model, Name: Model, Images: PedImages(Model) }));
            case "tattoo":
                return (Meta.TattooNames?.[Leaf.Zone] || []).map((Name, Index) => ({ Value: Index + 1, Name: TattooLabel(Name), Raw: Name, Images: [] }));
        }
        return [];
    };

    $: Filtered = Search.trim() == "" ? Items : Items.filter((I) => {
        const Q = Search.toLowerCase().trim();
        return String(I.Name).toLowerCase().replace(/_/g, " ").includes(Q.replace(/_/g, " ")) || String(I.Value) == Q || (I.Raw || "").toLowerCase().includes(Q);
    });

    // ---- Which item is worn ----
    $: Worn = LuaIndex($Skin[Leaf.Id], 0);
    $: WornTattoos = Leaf.Kind == "tattoo" ? TattooSet($Skin[Leaf.Id]) : new Set();
    const IsActive = (Item, Worn, WornTattoos, Model) => {
        if (Leaf.Kind == "ped" || Leaf.Kind == "customped") return String(Model || "").toLowerCase() == String(Item.Model).toLowerCase();
        if (Leaf.Kind == "tattoo") return WornTattoos.has(Item.Value);
        return Number(Worn) == Item.Value;
    };

    // ---- Changing things ----
    const SetDrawable = async (Value) => {
        const Result = await Post("Clothing/ProcessComponentChange", { componentId: Leaf.Id, value: Value, type: "Drawable" });
        if (!Result?.Success) return;
        if (Result.Values) Values.update((V) => ({ ...V, [Leaf.Id]: Result.Values }));
        SetSkin(Leaf.Id, 0, Value);
        if (Leaf.Kind != "overlay") SetSkin(Leaf.Id, 1, 0);
    };

    const Select = async (Item) => {
        switch (Leaf.Kind) {
            case "component":
            case "hair":
                await SetDrawable(Item.Value);
                break;
            case "overlay": {
                await SetDrawable(Item.Value);
                // A style with 0% opacity looks like nothing happened, so make it visible.
                const Opacity = Number(LuaIndex($Skin[Leaf.Id], 1) || 0);
                if (Item.Value >= 0 && Opacity <= 0) {
                    await Post("Clothing/ProcessSliderChange", { componentId: Leaf.Id, valueId: 1, value: 100 });
                    SetSkin(Leaf.Id, 1, 100);
                }
                break;
            }
            case "fade":
                await Post("Clothing/ProcessComponentChange", { componentId: "Fade", value: Item.Value });
                Skin.update((S) => ({ ...S, Fade: [Item.Value] }));
                break;
            case "eyecolor":
                await Post("Clothing/ProcessComponentChange", { componentId: "FaceEyeColor", value: Item.Value });
                SetSkin("FaceEyeColor", 0, Item.Value);
                break;
            case "ped":
                Meta.update((M) => ({ ...M, Model: Item.Model, PedId: Item.Value }));
                await Post("Clothing/ProcessComponentChange", { componentId: "Peds", value: Item.Value });
                break;
            case "customped":
                Meta.update((M) => ({ ...M, Model: Item.Model }));
                await Post("Clothing/SetCustomPed", { Ped: Item.Model });
                break;
            case "tattoo": {
                const Result = await Post("Clothing/ToggleTattoo", { Zone: Leaf.Id, Index: Item.Value });
                if (Result?.Success) {
                    Skin.update((S) => ({ ...S, [Leaf.Id]: Result.Zone }));
                    if (typeof Result.Price == "number") Price.set(Result.Price);
                }
                return;
            }
        }
        RefreshPrice();
    };

    const Remove = async () => {
        if (Leaf.Kind == "tattoo") {
            await Post("Clothes/ClearTattoos", { Zone: Leaf.Id });
            Skin.update((S) => ({ ...S, [Leaf.Id]: [0] }));
            return RefreshPrice();
        }
        const Value = Leaf.Kind == "component" ? (Leaf.Prop ? -1 : RemoveDefaults(Leaf.Id, $Meta.Gender))
            : Leaf.Kind == "overlay" ? -1 : 0;
        Select({ Value });
    };

    $: CanRemove = ["component", "hair", "overlay", "fade", "tattoo"].includes(Leaf.Kind);
    $: ShowPrice = !["ped", "customped"].includes(Leaf.Kind);
</script>

<div class="column enter" style="width: 660px;">
    <Header {Path} {Navigate} />

    <div style="display: flex; gap: 3px;">
        <Rails {Path} {Navigate} {...RailProps} />

        <div style="flex: 1; display: flex; flex-direction: column; min-width: 0;">
            <div style="display: flex; gap: 3px; margin-bottom: 12px;">
                <div class="search">
                    <Icon Name="search" Size={16} />
                    <input type="text" placeholder="Search..." bind:value={Search} />
                    {#if Search}
                        <button style="font-size: 12px; color: #a1a1aa;" on:click={() => (Search = "")}>✕</button>
                    {/if}
                </div>
                {#if CanRemove}
                    <button class="tool-btn" title={Leaf.Kind == "tattoo" ? "Remove all tattoos in this zone" : "Remove item"} on:click={Remove}>
                        <Icon Name="trash" Size={20} />
                    </button>
                {/if}
            </div>

            <div class="grid scroll">
                {#each Filtered as Item (Item.Value)}
                    {@const Active = IsActive(Item, Worn, WornTattoos, $Meta.Model)}
                    <button class="tile" class:active={Active} on:click={() => Select(Item)}>
                        <div class="tile-img">
                            <ItemImage Candidates={Item.Images}>
                                <div class="tile-fallback">
                                    {#if Leaf.Kind == "tattoo"}
                                        <div class="circle"><Icon Name="paintbrush" Size={20} /></div>
                                        <span style="font-size: 10px; color: #a1a1aa;">#{Item.Value}</span>
                                    {:else if Item.Value < 0}
                                        <Icon Name="x" Size={32} />
                                    {:else}
                                        <Icon Name={IconFor(Label)} Size={32} />
                                        <span style="font-size: 11px; letter-spacing: 0.05em;">#{Item.Value}</span>
                                    {/if}
                                </div>
                            </ItemImage>
                        </div>

                        <div class="tile-foot">
                            <span class="tile-name">{Item.Name}</span>
                            {#if Active}
                                <span style="color: var(--cyan); display: flex;"><Icon Name="check" Size={16} Stroke={3} /></span>
                            {:else if ShowPrice && !$Meta.IsFree && $Meta.ItemPrice > 0}
                                <div class="price"><span class="dollar">$</span><span class="amount">{$Meta.ItemPrice}</span></div>
                            {:else}
                                <span class="badge-free">FREE</span>
                            {/if}
                        </div>
                    </button>
                {:else}
                    <div class="empty">NOTHING FOUND</div>
                {/each}
            </div>
        </div>
    </div>
</div>

<style>
    .grid {
        display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); grid-auto-rows: max-content;
        align-content: start; gap: 6px; max-height: 760px; padding-right: 4px;
    }
    .circle {
        width: 40px; height: 40px; border-radius: 9999px; background: rgba(255,255,255,.1);
        border: 1px solid rgba(255,255,255,.3); display: flex; align-items: center; justify-content: center; color: white;
    }
    .empty { grid-column: 1 / -1; text-align: center; padding: 40px 0; font-size: 18px; color: rgba(255,255,255,.5); letter-spacing: 0.1em; }
</style>
