<script>
    import { onMount } from "svelte";
    import Header from "./Header.svelte";
    import Rails from "./Rails.svelte";
    import Icon from "./Icon.svelte";
    import { CopyToClipboard } from "../../../utils/Utils";
    import { Post, Price } from "../clothing.store";

    export let Path = [];
    export let RailProps = {};
    export let Navigate = (NewPath) => {};
    export let Close = false; // set when opened with [G]: no back button, a close button instead

    let Outfits = [], Loading = true, Worn = null;
    let Mode = false; // "save" | "import" | "share"
    let Name = "", Code = "", Error = "", Shared = null, Copied = false, Busy = false;

    const Load = async () => {
        Loading = true;
        const Result = await Post("Clothing/GetOutfits");
        Outfits = Array.isArray(Result) ? Result : [];
        Loading = false;
    };
    onMount(Load);

    const Toggle = (NewMode) => {
        Mode = Mode == NewMode ? false : NewMode;
        Name = ""; Code = ""; Error = ""; Copied = false;
    };

    const Wear = async (Outfit) => {
        if (Busy) return;
        Busy = true;
        const Result = await Post("Clothing/WearOutfit", { Id: Outfit.Id });
        Busy = false;
        if (Result?.Success) {
            Worn = Outfit.Id;
            if (typeof Result.Price == "number") Price.set(Result.Price);
        }
    };

    const Save = async () => {
        if (!Name.trim() || Busy) return;
        Busy = true;
        const Result = await Post("Clothing/SaveOutfit", { Name: Name.trim().slice(0, 50) });
        Busy = false;
        if (Result?.Outfits) Outfits = Result.Outfits;
        Toggle(false);
    };

    const Import = async () => {
        if (!Name.trim() || !Code.trim() || Busy) return;
        Busy = true;
        const Result = await Post("Clothing/ImportOutfit", { Name: Name.trim().slice(0, 50), Code: Code.trim() });
        Busy = false;
        if (!Result?.Success) return (Error = Result?.Msg || "Importing failed, check the code.");
        if (Result.Outfits) Outfits = Result.Outfits;
        Toggle(false);
    };

    const Share = async (Outfit) => {
        const Result = await Post("Clothing/ShareOutfit", { Id: Outfit.Id });
        if (!Result?.Code) return;
        Mode = "share"; Copied = false;
        Shared = { Name: Outfit.Title, Code: Result.Code };
    };

    const Remove = async (Outfit) => {
        const Result = await Post("Clothing/DeleteOutfit", { Id: Outfit.Id });
        if (Result?.Outfits) Outfits = Result.Outfits;
        else Outfits = Outfits.filter((O) => O.Id != Outfit.Id);
        if (Worn == Outfit.Id) Worn = null;
    };

    const Copy = () => {
        CopyToClipboard(Shared.Code);
        Copied = true;
        setTimeout(() => (Copied = false), 2000);
    };
</script>

<div class="column enter" style="width: 640px;">
    <Header {Path} {Navigate} CanGoBack={!Close} />

    <div style="display: flex; gap: 3px;">
        <Rails {Path} {Navigate} {...RailProps} />

        <div class="panel">
            <div style="display: flex; gap: 10px; margin-bottom: 16px;">
                <button class="btn-accent action" style="flex: 1;" on:click={() => Toggle("save")}><Icon Name="plus" Size={16} Stroke={3} /> SAVE CURRENT OUTFIT</button>
                <button class="btn-dark action" on:click={() => Toggle("import")}><Icon Name="download" Size={16} /> IMPORT CODE</button>
                {#if Close}<button class="tool-btn" title="Close" style="height: auto;" on:click={Close}><Icon Name="x" Size={18} /></button>{/if}
            </div>

            {#if Mode == "save"}
                <form class="form enter" on:submit|preventDefault={Save}>
                    <span class="hint">Saves the outfit you have paid for. Changes in this shop are not included until you pay.</span>
                    <!-- svelte-ignore a11y-autofocus -->
                    <input class="text-input" placeholder="OUTFIT NAME" maxlength="50" bind:value={Name} autofocus />
                    <div style="display: flex; gap: 8px;">
                        <button type="submit" class="btn-accent action" style="flex: 1;" disabled={!Name.trim()}>SAVE</button>
                        <button type="button" class="btn-dark action" on:click={() => Toggle(false)}>CANCEL</button>
                    </div>
                </form>
            {:else if Mode == "import"}
                <form class="form enter" on:submit|preventDefault={Import}>
                    <!-- svelte-ignore a11y-autofocus -->
                    <input class="text-input" placeholder="OUTFIT NAME" maxlength="50" bind:value={Name} autofocus />
                    <input class="text-input" placeholder="SHARE CODE" bind:value={Code} style="text-transform: uppercase;" />
                    {#if Error}<span class="error">{Error}</span>{/if}
                    <div style="display: flex; gap: 8px;">
                        <button type="submit" class="btn-accent action" style="flex: 1;" disabled={!Name.trim() || !Code.trim()}>IMPORT</button>
                        <button type="button" class="btn-dark action" on:click={() => Toggle(false)}>CANCEL</button>
                    </div>
                </form>
            {:else if Mode == "share" && Shared}
                <div class="form enter">
                    <span class="hint">Share code for <b style="color: white;">{Shared.Name}</b></span>
                    <div style="display: flex; gap: 8px;">
                        <div class="text-input code">{Shared.Code}</div>
                        <button class="btn-accent action" on:click={Copy}><Icon Name={Copied ? "check" : "copy"} Size={16} /> {Copied ? "COPIED" : "COPY"}</button>
                        <button class="tool-btn" style="height: auto;" on:click={() => Toggle(false)}><Icon Name="x" Size={16} /></button>
                    </div>
                </div>
            {/if}

            <div class="list scroll">
                {#if Loading}
                    <div class="note">LOADING OUTFITS...</div>
                {:else if Outfits.length == 0}
                    <div class="empty">
                        <Icon Name="layers" Size={48} style="color: #52525b; margin-bottom: 12px;" />
                        <span style="font-size: 18px; font-weight: 700; letter-spacing: 0.05em; color: #d4d4d8;">NO SAVED OUTFITS</span>
                        <span style="font-size: 12px; color: #71717a; letter-spacing: 0.05em; margin-top: 4px;">Click "+ SAVE CURRENT OUTFIT" to save your current clothing</span>
                    </div>
                {:else}
                    {#each Outfits as Outfit (Outfit.Id)}
                        <div class="outfit" class:on={Worn == Outfit.Id}>
                            <div style="display: flex; align-items: center; gap: 14px; min-width: 0;">
                                <div class="outfit-icon"><Icon Name="layers" Size={20} /></div>
                                <div style="display: flex; flex-direction: column; min-width: 0;">
                                    <span class="outfit-name">{Outfit.Title}</span>
                                    <span style="font-size: 11px; color: #a1a1aa; letter-spacing: 0.05em;">OUTFIT #{Outfit.Id}</span>
                                </div>
                            </div>
                            <div style="display: flex; align-items: center; gap: 8px; flex-shrink: 0;">
                                <button class={Worn == Outfit.Id ? "wear worn" : "wear btn-accent"} on:click={() => Wear(Outfit)}>
                                    {#if Worn == Outfit.Id}<Icon Name="check" Size={14} Stroke={3} /> EQUIPPED{:else}WEAR{/if}
                                </button>
                                <button class="mini" title="Share outfit code" on:click={() => Share(Outfit)}><Icon Name="share" Size={16} /></button>
                                <button class="mini danger" title="Delete outfit" on:click={() => Remove(Outfit)}><Icon Name="trash" Size={16} /></button>
                            </div>
                        </div>
                    {/each}
                {/if}
            </div>
        </div>
    </div>
</div>

<style>
    .panel { flex: 1; display: flex; flex-direction: column; background: rgba(17, 19, 23, 0.95); padding: 16px; border-top: 3px solid #00f0ff; box-shadow: 0 25px 50px rgba(0,0,0,.4); }
    .action { padding: 10px 16px; font-size: 14px; display: flex; align-items: center; justify-content: center; gap: 8px; }
    .action:disabled { opacity: 0.5; cursor: not-allowed; }
    .form { display: flex; flex-direction: column; gap: 10px; margin-bottom: 16px; padding: 12px; background: #16181f; border: 1px solid rgba(255,255,255,.08); }
    .hint { font-size: 12px; color: #a1a1aa; letter-spacing: 0.03em; }
    .error { font-size: 12px; color: #f87171; letter-spacing: 0.03em; }
    .code { font-family: 'Oswald', monospace; font-size: 18px; letter-spacing: 0.2em; color: #00f0ff; user-select: text; }
    .list { display: flex; flex-direction: column; gap: 8px; max-height: 620px; padding-right: 4px; }
    .note { text-align: center; padding: 48px 0; color: #a1a1aa; letter-spacing: 0.15em; font-size: 14px; }
    .empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 64px 24px; text-align: center; border: 1px dashed rgba(255,255,255,.1); background: rgba(22,24,31,.4); }
    .outfit { display: flex; align-items: center; justify-content: space-between; padding: 14px; background: #181a20; border: 1px solid rgba(255,255,255,.05); transition: all .15s; }
    .outfit:hover { border-color: rgba(255,255,255,.2); }
    .outfit.on { border-color: #00f0ff; box-shadow: 0 0 0 1px #00f0ff; }
    .outfit-icon { width: 40px; height: 40px; background: #121418; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(255,255,255,.05); color: #00f0ff; flex-shrink: 0; }
    .outfit-name { font-size: 16px; font-weight: 700; letter-spacing: 0.05em; text-transform: uppercase; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .wear { padding: 6px 16px; font-size: 13px; font-weight: 700; letter-spacing: 0.05em; display: flex; align-items: center; gap: 6px; }
    .wear.worn { background: white !important; color: black !important; }
    .mini { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: #1a1c23 !important; color: #d4d4d8 !important; border: 1px solid rgba(255,255,255,.05) !important; transition: all .15s; }
    .mini:hover { background: #3f3f46 !important; color: white !important; }
    .mini.danger:hover { background: rgba(127, 29, 29, .4) !important; color: #f87171 !important; }
</style>
