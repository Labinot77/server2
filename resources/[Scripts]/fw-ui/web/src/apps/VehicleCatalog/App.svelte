<script>
    import "@fontsource/barlow-condensed/500.css";
    import "@fontsource/barlow-condensed/600.css";
    import "@fontsource/barlow-condensed/700.css";
    import "@fontsource/barlow-condensed/700-italic.css";
    import "@fontsource/barlow-condensed/800-italic.css";

    import { onMount, tick } from "svelte";
    import { fade, fly } from "svelte/transition";
    import AppWrapper from "../../components/AppWrapper.svelte";
    import { Delay, FormatCurrency, OnEvent, SetExitHandler, SendEvent as _SendEvent } from "../../utils/Utils";
    import Car from "./components/Car.svelte";

    const SendEvent = (Event, Parameters, Callback) => _SendEvent(Event, Parameters, Callback, "fw-businesses");

    const ALL_CATEGORY = "Alle";
    const SORT_OPTIONS = [
        { Id: "category", Label: "Categorie" },
        { Id: "name", Label: "Naam A-Z" },
        { Id: "price-asc", Label: "Prijs laag-hoog" },
        { Id: "price-desc", Label: "Prijs hoog-laag" },
    ];
    const PAINT_COLORS = [
        { Label: "Wit", Rgb: [240, 240, 240] },
        { Label: "Zilver", Rgb: [170, 174, 180] },
        { Label: "Grafiet", Rgb: [62, 64, 70] },
        { Label: "Zwart", Rgb: [12, 12, 14] },
        { Label: "Rood", Rgb: [178, 18, 24] },
        { Label: "Oranje", Rgb: [242, 110, 20] },
        { Label: "Geel", Rgb: [242, 196, 20] },
        { Label: "Groen", Rgb: [30, 120, 60] },
        { Label: "Mint", Rgb: [46, 230, 184] },
        { Label: "Blauw", Rgb: [22, 66, 190] },
        { Label: "Hemelblauw", Rgb: [80, 160, 230] },
        { Label: "Paars", Rgb: [100, 40, 150] },
        { Label: "Roze", Rgb: [230, 90, 160] },
        { Label: "Bruin", Rgb: [100, 62, 36] },
    ];
    const STATS = [
        { Key: "Acceleration", Label: "Acceleratie" },
        { Key: "Speed", Label: "Topsnelheid" },
        { Key: "Handling", Label: "Handling" },
        { Key: "Braking", Label: "Remmen" },
    ];

    let Visible = false;
    let IntroState = "Out";
    let Shop = "";

    let Vehicles = [];
    let Categories = [];
    let ActiveCategory = ALL_CATEGORY;
    let SearchQuery = "";
    let SortMode = "category";

    let SelectedModel = null;
    let VehicleStats = false;

    let LoadingModel = null;
    let QueuedModel = null;

    let ShowStats = true;
    let ShowColors = false;
    let HideUI = false;
    let PaintSlot = "Primary";
    let ActivePaint = { Primary: null, Secondary: null };

    let SearchRef;
    let CarouselRef;
    let CardRefs = {};
    let SuppressEscape = false;

    // ---------------------------------------------------------------- Derived

    $: FilteredVehicles = SortVehicles(
        Vehicles.filter((Veh) => {
            if (ActiveCategory != ALL_CATEGORY && Veh.Category != ActiveCategory) return false;
            if (!SearchQuery.trim()) return true;
            const Query = SearchQuery.trim().toLowerCase();
            return Veh.Name.toLowerCase().includes(Query) || Veh.Vehicle.toLowerCase().includes(Query);
        }),
        SortMode
    );

    $: CurrentIndex = FilteredVehicles.findIndex((Veh) => Veh.Vehicle == SelectedModel);
    $: CurrentVehicle = Vehicles.find((Veh) => Veh.Vehicle == SelectedModel);
    $: CategoryTabs = [ALL_CATEGORY, ...Categories];
    $: CategoryCounts = Categories.reduce((Acc, Cat) => {
        Acc[Cat] = Vehicles.filter((Veh) => Veh.Category == Cat).length;
        return Acc;
    }, { [ALL_CATEGORY]: Vehicles.length });

    $: [Brand, Model] = SplitName(CurrentVehicle?.Name || "");

    function SortVehicles(List, Mode) {
        const Sorted = [...List];
        switch (Mode) {
            case "name": return Sorted.sort((a, b) => a.Name.localeCompare(b.Name));
            case "price-asc": return Sorted.sort((a, b) => a.Price - b.Price);
            case "price-desc": return Sorted.sort((a, b) => b.Price - a.Price);
            default: return Sorted.sort((a, b) => a.Category.localeCompare(b.Category) || a.Price - b.Price);
        }
    }

    function SplitName(Name) {
        const [First, ...Rest] = Name.split(" ");
        if (Rest.length == 0) return ["", First || ""];
        return [First, Rest.join(" ")];
    }

    const FormatPrice = (Price) => FormatCurrency.format(Price || 0).replace(/,00$/, "");
    const StatPercent = (Value) => Math.max(0, Math.min(100, (Value || 0) * 10));

    // ---------------------------------------------------------------- Vehicle loading

    const LoadModel = (ModelName) => {
        LoadingModel = ModelName;
        SendEvent("VehicleCatalog/SetVehicle", { Model: ModelName }, (Success, Data) => {
            const Loaded = LoadingModel;
            LoadingModel = null;

            // The player skipped ahead while this one was spawning, load the latest pick.
            if (QueuedModel && QueuedModel != Loaded) {
                const Next = QueuedModel;
                QueuedModel = null;
                LoadModel(Next);
                return;
            }

            QueuedModel = null;
            if (Success && Data) VehicleStats = Data;
        });
    };

    const SelectVehicle = async (ModelName) => {
        if (!ModelName || ModelName == SelectedModel) return;

        SelectedModel = ModelName;
        VehicleStats = false;
        ActivePaint = { Primary: null, Secondary: null };

        await tick();
        CardRefs[ModelName]?.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" });

        if (LoadingModel) {
            QueuedModel = ModelName;
            return;
        }
        LoadModel(ModelName);
    };

    const Step = (Direction) => {
        if (FilteredVehicles.length == 0) return;
        const Start = CurrentIndex == -1 ? (Direction > 0 ? -1 : 0) : CurrentIndex;
        const Next = (Start + Direction + FilteredVehicles.length) % FilteredVehicles.length;
        SelectVehicle(FilteredVehicles[Next].Vehicle);
    };

    const SetCategory = async (Category) => {
        ActiveCategory = Category;
        await tick();
        if (CurrentIndex == -1 && FilteredVehicles[0]) SelectVehicle(FilteredVehicles[0].Vehicle);
        else if (SelectedModel) CardRefs[SelectedModel]?.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" });
    };

    const StepCategory = (Direction) => {
        const Index = CategoryTabs.indexOf(ActiveCategory);
        SetCategory(CategoryTabs[(Index + Direction + CategoryTabs.length) % CategoryTabs.length]);
    };

    const OnFiltersChanged = async () => {
        await tick();
        if (CurrentIndex == -1 && FilteredVehicles[0]) SelectVehicle(FilteredVehicles[0].Vehicle);
    };

    // ---------------------------------------------------------------- Showroom controls

    let RotateDirection = 0;
    const SetRotation = (Direction) => {
        if (RotateDirection == Direction) return;
        RotateDirection = Direction;
        SendEvent("VehicleCatalog/Rotate", { Direction });
    };

    let DragX = null;
    let DragDelta = 0;
    let DragTimer = null;
    const OnStageMouseDown = (Event) => {
        if (Event.button != 0) return;
        DragX = Event.clientX;
    };
    const OnWindowMouseMove = (Event) => {
        if (DragX === null) return;
        DragDelta += (Event.clientX - DragX) * 0.35;
        DragX = Event.clientX;
        if (!DragTimer) DragTimer = setTimeout(FlushDrag, 40);
    };
    const OnWindowMouseUp = () => { DragX = null; };
    const FlushDrag = () => {
        DragTimer = null;
        if (Math.abs(DragDelta) < 0.1) return;
        SendEvent("VehicleCatalog/RotateBy", { Delta: DragDelta });
        DragDelta = 0;
    };

    const ApplyPaint = (Rgb) => {
        ActivePaint = { ...ActivePaint, [PaintSlot]: Rgb };
        SendEvent("VehicleCatalog/SetColor", { Slot: PaintSlot, Rgb });
    };

    const ResetPaint = () => {
        ActivePaint = { Primary: null, Secondary: null };
        SendEvent("VehicleCatalog/SetColor", { Slot: "Reset" });
    };

    const RevEngine = () => SendEvent("VehicleCatalog/DoRPM");

    // ---------------------------------------------------------------- Open / close

    SetExitHandler("", "VehicleCatalog/Close", () => Visible && IntroState == "Out" && !SuppressEscape, { __resource: "fw-businesses" });

    const ResetState = () => {
        Vehicles = [];
        Categories = [];
        ActiveCategory = ALL_CATEGORY;
        SearchQuery = "";
        SortMode = "category";
        SelectedModel = null;
        VehicleStats = false;
        LoadingModel = null;
        QueuedModel = null;
        ShowColors = false;
        HideUI = false;
        ActivePaint = { Primary: null, Secondary: null };
        CardRefs = {};
        RotateDirection = 0;
    };

    const LoadCatalog = async (Data) => {
        Visible = true;
        await Delay(0.05);
        IntroState = "In";

        await Delay(1.2);

        Vehicles = (Data.Vehicles || []).filter((Veh) => Veh && Veh.Vehicle);
        Categories = [...new Set(Vehicles.map((Veh) => Veh.Category).filter(Boolean))].sort((a, b) => a.localeCompare(b));

        await tick();
        if (FilteredVehicles[0]) SelectVehicle(FilteredVehicles[0].Vehicle);

        await Delay(1.4);
        IntroState = "Out";
    };

    OnEvent("VehicleCatalog", "SetVisibility", (Data) => {
        if (!Data.Visible) {
            Visible = false;
            IntroState = "Out";
            return;
        }

        ResetState();
        Shop = Data.Shop;
        LoadCatalog(Data);
    });

    // ---------------------------------------------------------------- Keyboard

    const IsTyping = () => document.activeElement && ["INPUT", "SELECT", "TEXTAREA"].includes(document.activeElement.tagName);

    const HandleKeyDown = (Event) => {
        if (!Visible || IntroState != "Out") return;

        if (Event.key == "Escape") {
            if (IsTyping()) { document.activeElement.blur(); SuppressEscape = true; return; }
            if (ShowColors) { ShowColors = false; SuppressEscape = true; return; }
            if (HideUI) { HideUI = false; SuppressEscape = true; return; }
            return;
        }

        if (IsTyping()) {
            if (Event.key == "Enter") document.activeElement.blur();
            return;
        }

        const Key = Event.key.toLowerCase();
        switch (Key) {
            case "arrowright": Event.preventDefault(); Step(1); break;
            case "arrowleft": Event.preventDefault(); Step(-1); break;
            case "e": StepCategory(1); break;
            case "q": StepCategory(-1); break;
            case "a": SetRotation(-1); break;
            case "d": SetRotation(1); break;
            case "w": RevEngine(); break;
            case "c": if (!HideUI) ShowColors = !ShowColors; break;
            case "h": HideUI = !HideUI; break;
            case "/": case "f": Event.preventDefault(); if (!HideUI) SearchRef?.focus(); break;
        }
    };

    const HandleKeyUp = (Event) => {
        // Cleared on the next tick so the window-level exit handler still sees the flag for this keyup.
        if (Event.key == "Escape") { setTimeout(() => (SuppressEscape = false), 0); return; }
        const Key = Event.key.toLowerCase();
        if ((Key == "a" && RotateDirection == -1) || (Key == "d" && RotateDirection == 1)) SetRotation(0);
    };

    const HandleWheel = (Event) => {
        if (!CarouselRef || Math.abs(Event.deltaY) < Math.abs(Event.deltaX)) return;
        CarouselRef.scrollLeft += Event.deltaY;
    };

    onMount(() => {
        document.addEventListener("keydown", HandleKeyDown);
        document.addEventListener("keyup", HandleKeyUp);
        window.addEventListener("blur", () => SetRotation(0));

        return () => {
            document.removeEventListener("keydown", HandleKeyDown);
            document.removeEventListener("keyup", HandleKeyUp);
        };
    });
</script>

<svelte:window on:mousemove={OnWindowMouseMove} on:mouseup={OnWindowMouseUp} />

<AppWrapper AppName="VehicleCatalog" Focused={Visible}>
    {#if Visible}
        <div class="vc-root">
            <!-- Intro -->
            <div class="vc-intro" class:in={IntroState == "In"}>
                <div class="vc-intro-panel">
                    <span class="vc-intro-eyebrow">Welkom bij</span>
                    <span class="vc-intro-shop">{Shop}</span>
                    <span class="vc-intro-line"></span>
                    <span class="vc-intro-sub">Voertuigcatalogus</span>
                </div>
            </div>

            <!-- Drag area for rotating the showroom vehicle -->
            <!-- svelte-ignore a11y-no-static-element-interactions -->
            <div class="vc-stage" class:dragging={DragX !== null} on:mousedown={OnStageMouseDown}></div>

            {#if HideUI}
                <div class="vc-hidden-hint" transition:fade={{ duration: 150 }}>
                    <span class="vc-kbd">H</span> Interface tonen
                    <span class="vc-sep"></span>
                    <span class="vc-kbd">A</span><span class="vc-kbd">D</span> Draaien
                </div>
            {:else}
                <div class="vc-ui" transition:fade={{ duration: 150 }}>
                    <!-- Header -->
                    <header class="vc-header">
                        <h1>Voertuigcatalogus</h1>
                        <p>{Shop}</p>
                    </header>

                    <!-- Key hints -->
                    <div class="vc-keys">
                        <div class="vc-key"><span class="vc-kbd">◀</span><span class="vc-kbd">▶</span> Navigeren</div>
                        <div class="vc-key"><span class="vc-kbd">Q</span><span class="vc-kbd">E</span> Categorie</div>
                        <div class="vc-key"><span class="vc-kbd">A</span><span class="vc-kbd">D</span> Draaien</div>
                        <div class="vc-key"><span class="vc-kbd">W</span> Motor</div>
                        <div class="vc-key"><span class="vc-kbd">C</span> Kleur</div>
                        <div class="vc-key"><span class="vc-kbd">H</span> Verbergen</div>
                        <div class="vc-key"><span class="vc-kbd wide">ESC</span> Sluiten</div>
                    </div>

                    {#if CurrentVehicle}
                        <!-- Hero -->
                        {#key CurrentVehicle.Vehicle}
                            <section class="vc-hero" in:fly={{ x: -30, duration: 260 }}>
                                <div class="vc-hero-eyebrow">
                                    <span>{CurrentVehicle.Category || "Voertuig"}</span>
                                    {#if Brand}<span class="vc-dot"></span><span>{Brand}</span>{/if}
                                </div>
                                <h2 class="vc-hero-name">{Model}</h2>
                                <div class="vc-hero-price">{FormatPrice(CurrentVehicle.Price)}</div>
                                <div class="vc-hero-tax">Incl. registratiebelasting</div>
                                <div class="vc-hero-tags">
                                    {#if CurrentVehicle.Class}<span class="vc-tag class">Klasse {CurrentVehicle.Class}</span>{/if}
                                    {#if CurrentVehicle.Stock === 0}
                                        <span class="vc-tag danger">Uitverkocht</span>
                                    {:else if CurrentVehicle.Stock !== undefined}
                                        <span class="vc-tag ok">Op voorraad · {CurrentVehicle.Stock}</span>
                                    {/if}
                                </div>
                            </section>
                        {/key}

                        <!-- Stats -->
                        {#if ShowStats}
                            <section class="vc-panel vc-stats" transition:fly={{ x: 30, duration: 200 }}>
                                <div class="vc-panel-title">
                                    <span>Prestaties</span>
                                    {#if LoadingModel}<span class="vc-spinner"></span>{/if}
                                </div>
                                {#each STATS as Stat}
                                    <div class="vc-stat">
                                        <div class="vc-stat-row">
                                            <span>{Stat.Label}</span>
                                            <span class="vc-stat-value">{VehicleStats ? Math.min(10, VehicleStats[Stat.Key] || 0).toFixed(1) : "–"}</span>
                                        </div>
                                        <div class="vc-stat-track">
                                            <div class="vc-stat-fill" style="width: {VehicleStats ? StatPercent(VehicleStats[Stat.Key]) : 0}%"></div>
                                            <div class="vc-stat-ticks"></div>
                                        </div>
                                    </div>
                                {/each}
                            </section>
                        {/if}
                    {/if}

                    <!-- Color picker -->
                    {#if ShowColors}
                        <section class="vc-panel vc-colors" transition:fly={{ y: 20, duration: 180 }}>
                            <div class="vc-panel-title">
                                <span>Lakkleur</span>
                                <button class="vc-link" on:click={ResetPaint}>Standaard</button>
                            </div>
                            <div class="vc-segment">
                                <button class:active={PaintSlot == "Primary"} on:click={() => (PaintSlot = "Primary")}>Primair</button>
                                <button class:active={PaintSlot == "Secondary"} on:click={() => (PaintSlot = "Secondary")}>Secundair</button>
                            </div>
                            <div class="vc-swatches">
                                {#each PAINT_COLORS as Paint}
                                    <button
                                        class="vc-swatch"
                                        class:active={ActivePaint[PaintSlot] && ActivePaint[PaintSlot].join() == Paint.Rgb.join()}
                                        title={Paint.Label}
                                        style="--swatch: rgb({Paint.Rgb.join(',')})"
                                        on:click={() => ApplyPaint(Paint.Rgb)}
                                    ></button>
                                {/each}
                            </div>
                            <p class="vc-colors-note">Alleen ter voorbeeld, de definitieve kleur kies je bij de verkoper.</p>
                        </section>
                    {/if}

                    <!-- Bottom dock -->
                    <section class="vc-dock">
                        <div class="vc-toolbar">
                            <div class="vc-count">
                                {#if FilteredVehicles.length}
                                    <strong>{CurrentIndex + 1}</strong> / {FilteredVehicles.length} voertuigen
                                {:else}
                                    Geen voertuigen gevonden
                                {/if}
                            </div>

                            <div class="vc-tools">
                                <div class="vc-search">
                                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M10.5 3a7.5 7.5 0 0 1 5.96 12.05l4.24 4.25-1.4 1.4-4.25-4.24A7.5 7.5 0 1 1 10.5 3zm0 2a5.5 5.5 0 1 0 0 11 5.5 5.5 0 0 0 0-11z"/></svg>
                                    <input
                                        bind:this={SearchRef}
                                        bind:value={SearchQuery}
                                        on:input={OnFiltersChanged}
                                        placeholder="Zoek merk of model..."
                                        spellcheck="false"
                                    />
                                    {#if SearchQuery}
                                        <button class="vc-search-clear" on:click={() => { SearchQuery = ""; OnFiltersChanged(); }}>✕</button>
                                    {/if}
                                </div>

                                <select class="vc-select" bind:value={SortMode} on:change={(e) => { e.currentTarget.blur(); OnFiltersChanged(); }}>
                                    {#each SORT_OPTIONS as Option}
                                        <option value={Option.Id}>{Option.Label}</option>
                                    {/each}
                                </select>

                                <button class="vc-icon-btn" class:active={ShowColors} title="Lakkleur (C)" on:click={() => (ShowColors = !ShowColors)}>
                                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3a9 9 0 0 0 0 18c1.1 0 1.8-.8 1.8-1.7 0-.5-.2-.9-.5-1.2-.3-.3-.4-.7-.4-1.1 0-1 .8-1.8 1.8-1.8h2.1A4.2 4.2 0 0 0 21 11c0-4.4-4-8-9-8zm-5.5 9a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm3-4a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm5 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm3 4a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3z"/></svg>
                                </button>
                                <button class="vc-icon-btn" class:active={ShowStats} title="Prestaties" on:click={() => (ShowStats = !ShowStats)}>
                                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4a10 10 0 0 0-8.66 15h17.32A10 10 0 0 0 12 4zm0 2a8 8 0 0 1 7.4 11H4.6A8 8 0 0 1 12 6zm4.2 2.4-4.9 4.2a1.6 1.6 0 1 0 1.9 1.9l4.2-4.9-1.2-1.2z"/></svg>
                                </button>
                                <button class="vc-icon-btn" title="Motor laten brullen (W)" on:click={RevEngine}>
                                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 5h6v2h-2v2h3l2 2h2V9h2v8h-2v-2h-2l-2 2H8l-2-2H4v2H2V9h2v2h2l1-2h2V7H7V5z"/></svg>
                                </button>
                                <button class="vc-icon-btn" title="Interface verbergen (H)" on:click={() => (HideUI = true)}>
                                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5c5 0 8.6 4.2 9.8 6.4a1.2 1.2 0 0 1 0 1.2C20.6 14.8 17 19 12 19s-8.6-4.2-9.8-6.4a1.2 1.2 0 0 1 0-1.2C3.4 9.2 7 5 12 5zm0 3a4 4 0 1 0 0 8 4 4 0 0 0 0-8zm0 2a2 2 0 1 1 0 4 2 2 0 0 1 0-4z"/></svg>
                                </button>
                            </div>
                        </div>

                        <div class="vc-tabs">
                            <button class="vc-kbd-btn" on:click={() => StepCategory(-1)}>Q</button>
                            <div class="vc-tab-list">
                                {#each CategoryTabs as Category}
                                    <button
                                        class="vc-tab"
                                        class:active={ActiveCategory == Category}
                                        on:click={() => SetCategory(Category)}
                                    >
                                        {Category}
                                        <span class="vc-tab-count">{CategoryCounts[Category] || 0}</span>
                                    </button>
                                {/each}
                            </div>
                            <button class="vc-kbd-btn" on:click={() => StepCategory(1)}>E</button>
                        </div>

                        <div class="vc-carousel-wrap">
                            <button class="vc-arrow left" on:click={() => Step(-1)} aria-label="Vorige">‹</button>
                            <div class="vc-carousel" bind:this={CarouselRef} on:wheel|preventDefault={HandleWheel}>
                                {#each FilteredVehicles as Data (Data.Vehicle)}
                                    <Car
                                        bind:HtmlRef={CardRefs[Data.Vehicle]}
                                        Image={Data.Vehicle}
                                        Price={Data.Price}
                                        Name={Data.Name}
                                        Class={Data.Class}
                                        Stock={Data.Stock}
                                        Selected={SelectedModel == Data.Vehicle}
                                        on:click={() => SelectVehicle(Data.Vehicle)}
                                    />
                                {:else}
                                    <div class="vc-empty">Geen voertuigen die overeenkomen met je zoekopdracht.</div>
                                {/each}
                            </div>
                            <button class="vc-arrow right" on:click={() => Step(1)} aria-label="Volgende">›</button>
                        </div>
                    </section>
                </div>
            {/if}
        </div>
    {/if}
</AppWrapper>

<style>
    .vc-root {
        --vc-accent: #2ee6b8;
        --vc-accent-soft: rgba(46, 230, 184, 0.14);
        --vc-danger: #ff4d5e;
        --vc-panel: rgba(14, 15, 18, 0.78);
        --vc-line: rgba(255, 255, 255, 0.08);
        --vc-text: #eef0f3;
        --vc-muted: #9aa0aa;

        position: absolute;
        inset: 0;

        font-family: "Barlow Condensed", "Roboto Condensed", sans-serif;
        color: var(--vc-text);
        user-select: none;
    }

    .vc-root :global(button) { font-family: inherit; }

    /* ------------------------------------------------ Intro */

    .vc-intro {
        position: absolute;
        inset: 0;
        z-index: 50;

        display: flex;
        align-items: center;
        justify-content: center;

        pointer-events: none;
        opacity: 0;
        background: radial-gradient(ellipse at center, #15181d 0%, #07080a 75%);
        transition: opacity .6s ease;
    }
    .vc-intro.in { opacity: 1; }

    .vc-intro-panel {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: .6vh;

        transform: translateY(2vh);
        transition: transform .9s cubic-bezier(.2, .8, .2, 1);
    }
    .vc-intro.in .vc-intro-panel { transform: translateY(0); }

    .vc-intro-eyebrow {
        font-size: 1.8vh;
        font-weight: 600;
        letter-spacing: .6vh;
        text-transform: uppercase;
        color: var(--vc-muted);
    }

    .vc-intro-shop {
        font-size: 8vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        line-height: 1;
    }

    .vc-intro-line {
        width: 0;
        height: .35vh;
        margin: 1vh 0;
        background: var(--vc-accent);
        box-shadow: 0 0 2vh var(--vc-accent);
        transition: width 1.1s .25s cubic-bezier(.2, .8, .2, 1);
    }
    .vc-intro.in .vc-intro-line { width: 36vh; }

    .vc-intro-sub {
        font-size: 2vh;
        font-weight: 600;
        letter-spacing: .4vh;
        text-transform: uppercase;
        color: var(--vc-accent);
    }

    /* ------------------------------------------------ Stage + shared */

    .vc-stage {
        position: absolute;
        inset: 0;
        cursor: grab;
    }
    .vc-stage.dragging { cursor: grabbing; }

    .vc-ui {
        position: absolute;
        inset: 0;
        pointer-events: none;
    }
    .vc-ui > * { pointer-events: auto; }

    .vc-kbd {
        display: inline-flex;
        align-items: center;
        justify-content: center;

        min-width: 2.3vh;
        height: 2.3vh;
        padding: 0 .4vh;

        font-size: 1.3vh;
        font-weight: 700;
        color: #0b0c0e;

        background: #e9ebee;
        border-radius: .3vh;
    }
    .vc-kbd.wide { padding: 0 .7vh; }

    .vc-panel {
        background: var(--vc-panel);
        border: .1vh solid var(--vc-line);
        backdrop-filter: blur(6px);
    }

    .vc-panel-title {
        display: flex;
        align-items: center;
        justify-content: space-between;

        margin-bottom: 1.4vh;

        font-size: 1.5vh;
        font-weight: 700;
        letter-spacing: .25vh;
        text-transform: uppercase;
        color: var(--vc-muted);
    }

    /* ------------------------------------------------ Header + keys */

    .vc-header {
        position: absolute;
        top: 4vh;
        left: 3vw;

        padding-left: 1.4vh;
        border-left: .45vh solid var(--vc-accent);
        pointer-events: none;
    }

    .vc-header h1 {
        margin: 0;
        font-size: 3.6vh;
        font-weight: 800;
        font-style: italic;
        line-height: 1;
        text-transform: uppercase;
        text-shadow: 0 .3vh 1.2vh rgba(0, 0, 0, 0.5);
    }

    .vc-header p {
        margin: .3vh 0 0;
        font-size: 1.5vh;
        font-weight: 700;
        letter-spacing: .15vh;
        text-transform: uppercase;
        color: var(--vc-muted);
    }

    .vc-keys {
        position: absolute;
        top: 4vh;
        right: 3vw;

        display: flex;
        align-items: center;
        gap: 2vh;

        padding: 1vh 1.8vh;

        background: var(--vc-panel);
        border: .1vh solid var(--vc-line);
        pointer-events: none;
    }

    .vc-key {
        display: flex;
        align-items: center;
        gap: .4vh;

        font-size: 1.45vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        white-space: nowrap;
    }
    .vc-key .vc-kbd:last-of-type { margin-right: .4vh; }

    /* ------------------------------------------------ Hero */

    .vc-hero {
        position: absolute;
        left: 3vw;
        top: 47vh;

        max-width: 42vw;
        padding-left: 1.4vh;
        border-left: .3vh solid var(--vc-accent);
        pointer-events: none;
    }

    .vc-hero-eyebrow {
        display: flex;
        align-items: center;
        gap: .9vh;

        font-size: 1.7vh;
        font-weight: 700;
        font-style: italic;
        letter-spacing: .15vh;
        text-transform: uppercase;
        color: #d7dade;
    }

    .vc-dot {
        width: .5vh;
        height: .5vh;
        background: var(--vc-accent);
        border-radius: 50%;
    }

    .vc-hero-name {
        margin: .2vh 0 0;

        font-size: 7.4vh;
        font-weight: 800;
        font-style: italic;
        line-height: .95;
        text-transform: uppercase;
        overflow-wrap: anywhere;
        text-shadow: 0 .4vh 2vh rgba(0, 0, 0, 0.55);
    }

    .vc-hero-price {
        margin-top: .4vh;

        font-size: 4.2vh;
        font-weight: 800;
        font-style: italic;
        color: var(--vc-accent);
        text-shadow: 0 0 2.4vh rgba(46, 230, 184, 0.35);
    }

    .vc-hero-tax {
        font-size: 1.35vh;
        font-weight: 600;
        letter-spacing: .1vh;
        text-transform: uppercase;
        color: var(--vc-muted);
    }

    .vc-hero-tags {
        display: flex;
        gap: .8vh;
        margin-top: 1.2vh;
    }

    .vc-tag {
        padding: .35vh .9vh;

        font-size: 1.35vh;
        font-weight: 700;
        letter-spacing: .1vh;
        text-transform: uppercase;

        background: rgba(0, 0, 0, 0.55);
        border: .1vh solid var(--vc-line);
    }
    .vc-tag.ok { color: var(--vc-accent); border-color: rgba(46, 230, 184, 0.35); }
    .vc-tag.danger { color: var(--vc-danger); border-color: rgba(255, 77, 94, 0.4); }

    /* ------------------------------------------------ Stats */

    .vc-stats {
        position: absolute;
        top: 11vh;
        right: 3vw;

        width: 32vh;
        padding: 1.8vh 2vh;
    }

    .vc-stat + .vc-stat { margin-top: 1.4vh; }

    .vc-stat-row {
        display: flex;
        justify-content: space-between;
        margin-bottom: .5vh;

        font-size: 1.6vh;
        font-weight: 600;
        text-transform: uppercase;
    }

    .vc-stat-value { font-weight: 700; color: var(--vc-accent); }

    .vc-stat-track {
        position: relative;
        height: .8vh;
        background: rgba(255, 255, 255, 0.08);
        overflow: hidden;
    }

    .vc-stat-fill {
        height: 100%;
        background: linear-gradient(90deg, rgba(46, 230, 184, 0.55), var(--vc-accent));
        transition: width .5s cubic-bezier(.2, .8, .2, 1);
    }

    .vc-stat-ticks {
        position: absolute;
        inset: 0;
        background: repeating-linear-gradient(90deg, transparent 0 calc(10% - .2vh), rgba(14, 15, 18, 0.9) calc(10% - .2vh) 10%);
    }

    .vc-spinner {
        width: 1.4vh;
        height: 1.4vh;
        border: .25vh solid rgba(255, 255, 255, 0.15);
        border-top-color: var(--vc-accent);
        border-radius: 50%;
        animation: vc-spin .7s linear infinite;
    }
    @keyframes vc-spin { to { transform: rotate(360deg); } }

    /* ------------------------------------------------ Colors */

    .vc-colors {
        position: absolute;
        right: 3vw;
        bottom: 33vh;

        width: 32vh;
        padding: 1.8vh 2vh;
    }

    .vc-link {
        all: unset;
        cursor: pointer;
        font-size: 1.35vh;
        font-weight: 700;
        letter-spacing: .1vh;
        color: var(--vc-accent);
    }
    .vc-link:hover { text-decoration: underline; }

    .vc-segment {
        display: grid;
        grid-template-columns: 1fr 1fr;
        margin-bottom: 1.4vh;
        border: .1vh solid var(--vc-line);
    }

    .vc-segment button {
        all: unset;
        padding: .7vh 0;
        cursor: pointer;
        text-align: center;
        font-size: 1.45vh;
        font-weight: 700;
        text-transform: uppercase;
        color: var(--vc-muted);
    }
    .vc-segment button.active { color: #071510; background: var(--vc-accent); }

    .vc-swatches {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        gap: .8vh;
    }

    .vc-swatch {
        all: unset;
        aspect-ratio: 1;
        cursor: pointer;
        background: var(--swatch);
        border: .2vh solid rgba(255, 255, 255, 0.12);
        transition: transform .12s ease;
    }
    .vc-swatch:hover { transform: scale(1.12); }
    .vc-swatch.active { border-color: var(--vc-accent); box-shadow: 0 0 0 .2vh #0e0f12 inset; }

    .vc-colors-note {
        margin: 1.4vh 0 0;
        font-size: 1.25vh;
        font-weight: 500;
        color: var(--vc-muted);
    }

    /* ------------------------------------------------ Dock */

    .vc-dock {
        position: absolute;
        left: 2vw;
        right: 2vw;
        bottom: 2.5vh;
    }

    .vc-toolbar {
        display: flex;
        align-items: flex-end;
        justify-content: space-between;
        margin-bottom: 1vh;
    }

    .vc-count {
        padding-left: 1vw;
        font-size: 1.7vh;
        font-weight: 600;
        text-transform: uppercase;
        color: var(--vc-muted);
    }
    .vc-count strong { color: var(--vc-text); font-weight: 800; }

    .vc-tools {
        display: flex;
        align-items: center;
        gap: .6vh;
    }

    .vc-search {
        position: relative;
        display: flex;
        align-items: center;

        width: 28vh;
        height: 3.8vh;
        padding: 0 1vh;

        background: var(--vc-panel);
        border: .1vh solid var(--vc-line);
    }
    .vc-search:focus-within { border-color: var(--vc-accent); }

    .vc-search svg { width: 1.8vh; fill: var(--vc-muted); flex: 0 0 auto; }

    .vc-search input {
        all: unset;
        flex: 1;
        min-width: 0;
        margin-left: .8vh;
        font-size: 1.6vh;
        font-weight: 600;
        color: var(--vc-text);
    }
    .vc-search input::placeholder { color: #6c717a; }

    .vc-search-clear {
        all: unset;
        cursor: pointer;
        font-size: 1.4vh;
        color: var(--vc-muted);
    }

    .vc-select {
        height: 3.8vh;
        padding: 0 1vh;

        font-family: inherit;
        font-size: 1.55vh;
        font-weight: 700;
        text-transform: uppercase;
        color: var(--vc-text);

        background: var(--vc-panel);
        border: .1vh solid var(--vc-line);
        outline: none;
        cursor: pointer;
    }
    .vc-select option { background: #14161a; }

    .vc-icon-btn {
        all: unset;
        display: flex;
        align-items: center;
        justify-content: center;

        width: 3.8vh;
        height: 3.8vh;
        cursor: pointer;

        background: var(--vc-panel);
        border: .1vh solid var(--vc-line);
        transition: background .15s ease, border-color .15s ease;
    }
    .vc-icon-btn svg { width: 2vh; fill: #d7dade; }
    .vc-icon-btn:hover { border-color: rgba(255, 255, 255, 0.3); }
    .vc-icon-btn.active { background: var(--vc-accent-soft); border-color: var(--vc-accent); }
    .vc-icon-btn.active svg { fill: var(--vc-accent); }

    .vc-tabs {
        display: flex;
        align-items: center;
        justify-content: flex-end;
        gap: .6vh;
        margin-bottom: 1.2vh;
    }

    .vc-tab-list {
        display: flex;
        gap: .6vh;
        max-width: 80vw;
        overflow-x: auto;
    }
    .vc-tab-list::-webkit-scrollbar { display: none; }

    .vc-tab, .vc-kbd-btn {
        all: unset;
        display: flex;
        align-items: center;
        gap: .7vh;
        flex: 0 0 auto;

        height: 3.6vh;
        padding: 0 1.4vh;
        cursor: pointer;

        font-size: 1.6vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        white-space: nowrap;
        color: var(--vc-text);

        background: rgba(10, 11, 13, 0.85);
        border: .1vh solid var(--vc-line);
        transition: background .15s ease, color .15s ease;
    }
    .vc-tab:hover { background: rgba(40, 43, 50, 0.9); }
    .vc-tab.active { color: #0b0c0e; background: #f2f3f5; }

    .vc-tab-count {
        font-size: 1.25vh;
        font-style: normal;
        color: var(--vc-muted);
    }
    .vc-tab.active .vc-tab-count { color: #5b606a; }

    .vc-kbd-btn {
        justify-content: center;
        width: 3.6vh;
        padding: 0;
        font-style: normal;
        color: #0b0c0e;
        background: #e9ebee;
    }

    .vc-carousel-wrap {
        position: relative;
    }

    .vc-carousel {
        display: flex;
        gap: 1vh;

        padding: 1vh 1vw;

        overflow-x: auto;
        overflow-y: hidden;
        scroll-behavior: smooth;
        -webkit-mask-image: linear-gradient(90deg, transparent 0, #000 2vw, #000 calc(100% - 2vw), transparent 100%);
    }
    .vc-carousel::-webkit-scrollbar { display: none; }

    .vc-arrow {
        all: unset;
        position: absolute;
        top: 50%;
        z-index: 2;

        display: flex;
        align-items: center;
        justify-content: center;

        width: 3.6vh;
        height: 6vh;
        cursor: pointer;

        font-size: 3.6vh;
        line-height: 1;
        color: var(--vc-text);

        background: rgba(10, 11, 13, 0.9);
        border: .1vh solid var(--vc-line);
        transform: translateY(-50%);
    }
    .vc-arrow:hover { color: var(--vc-accent); border-color: var(--vc-accent); }
    .vc-arrow.left { left: -1vw; }
    .vc-arrow.right { right: -1vw; }

    .vc-empty {
        display: flex;
        align-items: center;
        justify-content: center;

        width: 100%;
        height: 16vh;

        font-size: 1.9vh;
        font-weight: 600;
        color: var(--vc-muted);
        background: var(--vc-panel);
        border: .1vh dashed var(--vc-line);
    }

    /* ------------------------------------------------ Hidden UI */

    .vc-hidden-hint {
        position: absolute;
        bottom: 3vh;
        left: 50%;

        display: flex;
        align-items: center;
        gap: .5vh;

        padding: 1vh 1.6vh;

        font-size: 1.5vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;

        background: var(--vc-panel);
        border: .1vh solid var(--vc-line);
        transform: translateX(-50%);
        pointer-events: none;
    }

    .vc-sep {
        width: .1vh;
        height: 2vh;
        margin: 0 1vh;
        background: var(--vc-line);
    }
</style>
