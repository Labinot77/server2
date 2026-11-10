<script>
    // Port of codera-hud web/js/settings.js + settings.css + the hs-* markup in index.html:
    // the /hudsettings menu, the layout editor (drag + resize every HUD block) and the toggles.
    // Always mounted from Hud/App.svelte. State is stored by fw-hud handlers/settings.ts (KVP).
    import { onMount, onDestroy } from "svelte";
    import { get } from "svelte/store";
    import { OnEvent, SendEvent as _SendEvent } from "../../../utils/Utils";
    import { HudSettings, LayoutEditing, DevMode } from "../hud.store.js";
    import { LayoutElements } from "../layout.js";

    const SendEvent = (Event, Data, Callback) => _SendEvent(Event, Data, Callback, "fw-hud");

    const Clamp = (Value, Min, Max) => Math.min(Max, Math.max(Min, Value));
    const Round = (Value, Places = 4) => Math.round(Value * (10 ** Places)) / (10 ** Places);

    let MenuOpen = false;
    let Brand = "FW HUD";
    let CurrentPage = "layout";
    let SaveTimer = null;
    let Saving = false;

    // --- Settings access -----------------------------------------------------

    const GetPath = (Settings, Path) => Path.split(".").reduce((Node, Key) => (Node ? Node[Key] : undefined), Settings);

    const Change = (Path, Value) => {
        HudSettings.update((Settings) => {
            const Keys = Path.split(".");
            const Last = Keys.pop();
            Keys.reduce((Parent, Key) => Parent[Key], Settings)[Last] = Value;
            return Settings;
        });
        ScheduleSave();
    };

    // --- Saving (debounced; everything is stored in a KVP by fw-hud) -------------

    const FlushSave = () => {
        if (SaveTimer) { clearTimeout(SaveTimer); SaveTimer = null; }

        return new Promise((Resolve) => {
            SendEvent("HudSettings/Save", JSON.parse(JSON.stringify(get(HudSettings))), () => {
                Saving = false;
                Resolve();
            });
        });
    };

    const ScheduleSave = () => {
        Saving = true;
        if (SaveTimer) clearTimeout(SaveTimer);
        SaveTimer = setTimeout(FlushSave, 350);
    };

    // --- Hide classes on <body> (see the :global rules in the style block) ---------

    const HideClasses = {
        "map.showMinimap": "hs-no-map",
        "map.showHeading": "hs-no-heading",
        "map.showLocation": "hs-no-location",
        "map.showWaypoint": "hs-no-waypoint",
        "player.showVoice": "hs-no-voice",
        "player.showNeeds": "hs-no-needs",
        "player.showAmmo": "hs-no-ammo",
        "vehicle.showGear": "hs-no-gear",
        "vehicle.showFuel": "hs-no-fuel",
        "vehicle.showIcons": "hs-no-icons",
        "vehicle.showControls": "hs-no-controls",
    };

    const ApplyBody = (Settings) => {
        if (!Settings) return;

        Object.entries(HideClasses).forEach(([Path, ClassName]) => {
            document.body.classList.toggle(ClassName, GetPath(Settings, Path) === false);
        });

        const Opacity = Clamp(Number(Settings.general.opacity) || 100, 30, 100) / 100;
        document.body.style.setProperty("--hs-opacity", String(Opacity));
    };

    $: ApplyBody($HudSettings);
    $: document.body.classList.toggle("layout-editing", $LayoutEditing);

    // --- Menu pages --------------------------------------------------------------

    const Pages = {
        map: {
            Eyebrow: "Minimap",
            Title: "Map & compass",
            Desc: "Kies wat er rond de minimap getoond wordt.",
            Rows: [
                { Type: "toggle", Path: "map.showMinimap", Title: "Minimap & kompas", Desc: "Zet het hele minimap blok aan of uit." },
                { Type: "toggle", Path: "map.showHeading", Title: "Graden", Desc: "Het getal boven de kompas ring." },
                { Type: "toggle", Path: "map.showLocation", Title: "Straat & zone", Desc: "Locatienamen onder de kaart." },
                { Type: "toggle", Path: "map.showWaypoint", Title: "Waypoint afstand", Desc: "Afstand tot je kaartmarkering." },
                { Type: "action", Action: "calibrate", Title: "Minimap kalibreren", Desc: "Herstel de kaart als hij niet in het midden van de ring zit.", Button: "Start kalibratie" },
            ],
        },
        player: {
            Eyebrow: "Te voet",
            Title: "Speler status",
            Desc: "Toon alleen de onderdelen die je wilt zien.",
            Rows: [
                { Type: "toggle", Path: "player.showVoice", Title: "Stem indicator", Desc: "Microfoon icoon met bereik." },
                { Type: "toggle", Path: "player.showArmor", Title: "Armor balk", Desc: "Naast de health balk." },
                { Type: "toggle", Path: "player.showNeeds", Title: "Eten & drinken", Desc: "De twee kleine meters." },
                { Type: "toggle", Path: "player.showStamina", Title: "Stamina balk", Desc: "Zichtbaar tijdens het rennen." },
                { Type: "toggle", Path: "player.showAmmo", Title: "Munitie teller", Desc: "Magazijn en reserve munitie." },
            ],
        },
        vehicle: {
            Eyebrow: "Rijden",
            Title: "Voertuig",
            Desc: "Stel de snelheidsmeter in.",
            Rows: [
                {
                    Type: "segment",
                    Path: "vehicle.unit",
                    Title: "Snelheid eenheid",
                    Desc: "Auto volgt de server instelling (km/u).",
                    Options: [["auto", "Auto"], ["mph", "MPH"], ["kmh", "KM/U"]],
                },
                { Type: "toggle", Path: "vehicle.showGear", Title: "Versnelling", Desc: "Huidige versnelling in het midden." },
                { Type: "toggle", Path: "vehicle.showFuel", Title: "Brandstof", Desc: "Gebogen brandstofbalk en pomp icoon." },
                { Type: "toggle", Path: "vehicle.showIcons", Title: "Status iconen", Desc: "Lichten, gordel en deurslot." },
                { Type: "toggle", Path: "vehicle.showControls", Title: "Bedieningshulp", Desc: "Motor / slot / koplampen / claxon / uitstappen." },
            ],
        },
        general: {
            Eyebrow: "Overig",
            Title: "Algemeen",
            Desc: "Instellingen voor de hele HUD.",
            Rows: [
                { Type: "range", Path: "general.opacity", Min: 30, Max: 100, Unit: "%", Title: "HUD doorzichtigheid", Desc: "Verlaag dit om de HUD minder op te laten vallen." },
                { Type: "toggle", Path: "general.snap", Title: "Magnetisch raster", Desc: "Laat slepen in de layout editor op vaste stappen landen." },
                { Type: "action", Action: "cinematic", Title: "Cinematic modus", Desc: "Verbergt de HUD en toont zwarte balken. Gebruik /cinematic om te stoppen.", Button: "Wisselen" },
            ],
        },
    };

    const Nav = [
        ["layout", "HUD layout"],
        ["map", "Map & kompas"],
        ["player", "Speler status"],
        ["vehicle", "Voertuig"],
        ["general", "Algemeen"],
    ];

    $: PageName = Nav.find((Val) => Val[0] == CurrentPage)?.[1] || "";

    const PaintRange = (Min, Max, Value) => `${((Value - Min) / (Max - Min)) * 100}%`;

    const RunAction = (Action) => {
        if (Action == "calibrate") SendEvent("HudSettings/Calibrate", {});
        if (Action == "cinematic") SendEvent("HudSettings/Cinematic", {});
    };

    // --- Reset buttons (two clicks: the first one arms it) -----------------------------

    let ArmedLayout = false;
    let ArmedAll = false;
    let ArmTimer = null;

    const Arm = (Which) => {
        clearTimeout(ArmTimer);
        ArmedLayout = Which == "layout";
        ArmedAll = Which == "all";
        ArmTimer = setTimeout(() => { ArmedLayout = false; ArmedAll = false; }, 3000);
    };

    const ResetClick = async (Scope) => {
        const Armed = Scope == "layout" ? ArmedLayout : ArmedAll;
        if (!Armed) return Arm(Scope);

        clearTimeout(ArmTimer);
        ArmedLayout = false;
        ArmedAll = false;

        if (SaveTimer) await FlushSave();
        SendEvent("HudSettings/Reset", { Scope }, (Success, Reply) => {
            if (Success && Reply?.Settings) HudSettings.set(Reply.Settings);
            Saving = false;
        });
    };

    // --- Layout editor -----------------------------------------------------------------

    const HandlePad = 6;
    const SnapStep = 0.005; // 0.5% of the screen

    let SelectedId = LayoutElements[0].Id;
    let Rects = {};
    let Frame = null;
    let Drag = null;

    $: SelectedDefinition = LayoutElements.find((Val) => Val.Id == SelectedId);
    $: SelectedLayout = $HudSettings.layout[SelectedId];

    // Bounding box of everything that visibly belongs to an element.
    const Measure = (Definition) => {
        let Left = Infinity, Top = Infinity, Right = -Infinity, Bottom = -Infinity;

        Definition.Measure.forEach((Part) => {
            document.querySelectorAll(Part.Sel).forEach((Node) => {
                let Rect;
                if (Part.Text) {
                    const Range = document.createRange();
                    Range.selectNodeContents(Node);
                    Rect = Range.getBoundingClientRect();
                } else {
                    Rect = Node.getBoundingClientRect();
                };

                if (Rect.width < 1 || Rect.height < 1) return;
                Left = Math.min(Left, Rect.left);
                Top = Math.min(Top, Rect.top);
                Right = Math.max(Right, Rect.right);
                Bottom = Math.max(Bottom, Rect.bottom);
            });
        });

        return Number.isFinite(Left) ? { Left, Top, Right, Bottom } : null;
    };

    const Track = () => {
        const Next = {};
        let Changed = false;

        LayoutElements.forEach((Definition) => {
            const Rect = Measure(Definition);
            Next[Definition.Id] = Rect;

            const Old = Rects[Definition.Id];
            if (!!Old != !!Rect || (Rect && (Old.Left != Rect.Left || Old.Top != Rect.Top || Old.Right != Rect.Right || Old.Bottom != Rect.Bottom))) Changed = true;
        });

        if (Changed) Rects = Next;
        Frame = requestAnimationFrame(Track);
    };

    const StopTrack = () => {
        if (Frame !== null) cancelAnimationFrame(Frame);
        Frame = null;
    };

    const OpenEditor = () => {
        LayoutEditing.set(true);
        // Let the layers render their sample data before the first measurement.
        requestAnimationFrame(() => { if (Frame === null) Frame = requestAnimationFrame(Track); });
    };

    const CloseEditor = () => {
        StopTrack();
        Drag = null;
        LayoutEditing.set(false);
        FlushSave();
    };

    const StartDrag = (Event, Definition) => {
        if (Event.button !== 0) return;
        Event.preventDefault();

        SelectedId = Definition.Id;
        Event.currentTarget.setPointerCapture(Event.pointerId);

        const Layout = get(HudSettings).layout[Definition.Id];
        Drag = {
            Id: Definition.Id,
            PointerId: Event.pointerId,
            StartX: Event.clientX,
            StartY: Event.clientY,
            OriginX: Layout.x,
            OriginY: Layout.y,
            Rect: Measure(Definition),
        };
    };

    const MoveDrag = (Event) => {
        if (!Drag || Event.pointerId !== Drag.PointerId) return;

        const Width = window.innerWidth;
        const Height = window.innerHeight;
        const Settings = get(HudSettings);

        let X = Drag.OriginX + ((Event.clientX - Drag.StartX) / Width);
        let Y = Drag.OriginY + ((Event.clientY - Drag.StartY) / Height);

        if (Settings.general.snap) {
            X = Math.round(X / SnapStep) * SnapStep;
            Y = Math.round(Y / SnapStep) * SnapStep;
        };

        // Keep the whole element on screen.
        if (Drag.Rect) {
            const DX = Clamp((X - Drag.OriginX) * Width, -Drag.Rect.Left, Width - Drag.Rect.Right);
            const DY = Clamp((Y - Drag.OriginY) * Height, -Drag.Rect.Top, Height - Drag.Rect.Bottom);
            X = Drag.OriginX + (DX / Width);
            Y = Drag.OriginY + (DY / Height);
        };

        HudSettings.update((Val) => {
            Val.layout[Drag.Id].x = Round(X);
            Val.layout[Drag.Id].y = Round(Y);
            return Val;
        });
    };

    const EndDrag = (Event) => {
        if (!Drag || Event.pointerId !== Drag.PointerId) return;
        Drag = null;
        ScheduleSave();
    };

    const SetScale = (Percent) => {
        HudSettings.update((Val) => {
            Val.layout[SelectedId].scale = Round(Number(Percent) / 100);
            return Val;
        });
        ScheduleSave();
    };

    const ResetElement = () => {
        HudSettings.update((Val) => {
            Val.layout[SelectedId] = { x: 0, y: 0, scale: 1 };
            return Val;
        });
        ScheduleSave();
    };

    const Nudge = (DxPx, DyPx) => {
        HudSettings.update((Val) => {
            const Layout = Val.layout[SelectedId];
            Layout.x = Round(Layout.x + (DxPx / window.innerWidth));
            Layout.y = Round(Layout.y + (DyPx / window.innerHeight));
            return Val;
        });
        ScheduleSave();
    };

    // --- Open / close ------------------------------------------------------------------

    const RequestClose = () => {
        FlushSave();
        SendEvent("HudSettings/Close", {});
    };

    const OnKeyDown = (Event) => {
        if (!MenuOpen) return;

        if (Event.key == "Escape") {
            Event.preventDefault();
            if ($LayoutEditing) CloseEditor(); else RequestClose();
            return;
        };

        if ($LayoutEditing && Event.target?.type != "range") {
            const Step = Event.shiftKey ? 10 : 1;
            const Moves = { ArrowLeft: [-Step, 0], ArrowRight: [Step, 0], ArrowUp: [0, -Step], ArrowDown: [0, Step] };

            if (Moves[Event.key]) {
                Event.preventDefault();
                Nudge(...Moves[Event.key]);
            };
        };
    };

    const SetOpen = (Data) => {
        if (Data.Settings) HudSettings.set(Data.Settings);
        if (Data.Brand) Brand = Data.Brand;
        Saving = false;
        CurrentPage = "layout";
        LayoutEditing.set(false);
        MenuOpen = true;
    };

    OnEvent("Hud", "SettingsOpen", SetOpen);

    OnEvent("Hud", "SettingsClose", () => {
        StopTrack();
        LayoutEditing.set(false);
        MenuOpen = false;
    });

    OnEvent("Hud", "SetHudSettings", (Data) => {
        if (Data.Settings) HudSettings.set(Data.Settings);
        if (Data.Brand) Brand = Data.Brand;
    });

    OnEvent("Hud", "SetDevMode", (Data) => DevMode.set(!!Data.State));

    // Initial load: fetch the saved settings from fw-hud (retries while the client is still starting).
    const LoadSettings = (Attempt = 0) => {
        SendEvent("HudSettings/Get", {}, (Success, Reply) => {
            if (Success && Reply?.Settings) {
                HudSettings.set(Reply.Settings);
                if (Reply.Brand) Brand = Reply.Brand;
            } else if (Attempt < 10) {
                setTimeout(() => LoadSettings(Attempt + 1), 1000);
            };
        });
    };

    onMount(() => LoadSettings());
    onDestroy(() => {
        StopTrack();
        clearTimeout(SaveTimer);
        clearTimeout(ArmTimer);
    });
</script>

<svelte:window on:keydown={OnKeyDown} />

{#if MenuOpen && !$LayoutEditing}
    <div class="hs-menu" role="dialog" aria-modal="true" aria-labelledby="hs-title" style="pointer-events: auto;">
        <div class="hs-panel" tabindex="-1">
            <header class="hs-head">
                <div class="hs-head__title">
                    <span class="hs-eyebrow">Snel menu</span>
                    <h1 id="hs-title">HUD instellingen</h1>
                </div>
                <div class="hs-head__right">
                    <span class="hs-head__page">{PageName}</span>
                    <button class="hs-close" type="button" aria-label="Sluit menu (Escape)" on:click={RequestClose}>
                        <b>ESC</b><span>Sluiten</span>
                    </button>
                </div>
            </header>

            <div class="hs-body">
                <div class="hs-nav" role="tablist" aria-label="Instellingen secties">
                    {#each Nav as Item, Key}
                        <button
                            class="hs-nav__item"
                            class:is-active={CurrentPage == Item[0]}
                            type="button"
                            role="tab"
                            aria-selected={CurrentPage == Item[0]}
                            on:click={() => { CurrentPage = Item[0]; }}
                        >
                            <i>0{Key + 1}</i><span>{Item[1]}</span>
                        </button>
                    {/each}

                    <div class="hs-nav__foot">
                        <span class="hs-nav__preview">Live voorbeeld</span>
                        <span class="hs-nav__state" class:is-saving={Saving} role="status">{Saving ? "Opslaan…" : "Opgeslagen"}</span>
                    </div>
                </div>

                <main class="hs-main">
                    {#if CurrentPage == "layout"}
                        <section class="hs-page">
                            <header class="hs-page__head">
                                <span class="hs-eyebrow">Positie &amp; grootte</span>
                                <h2>HUD layout aanpassen</h2>
                                <p>Verplaats elk HUD element naar waar je wilt en schaal ze apart.</p>
                            </header>

                            <div class="hs-callout">
                                <div class="hs-callout__text">
                                    <span class="hs-eyebrow">Live scherm editor</span>
                                    <h3>Slepen, verplaatsen en schalen</h3>
                                    <p>Selecteer een HUD element, verplaats het en gebruik de schuif voor de grootte.</p>
                                </div>
                                <button class="hs-btn hs-btn--cyan" type="button" on:click={OpenEditor}>Open layout editor</button>
                            </div>

                            <ol class="hs-steps">
                                <li><b>01</b><span>Kies element</span></li>
                                <li><b>02</b><span>Sleep overal heen</span></li>
                                <li><b>03</b><span>Pas grootte aan</span></li>
                                <li><b>04</b><span>Automatisch opgeslagen</span></li>
                            </ol>
                        </section>
                    {:else}
                        {@const Page = Pages[CurrentPage]}
                        <section class="hs-page">
                            <header class="hs-page__head">
                                <span class="hs-eyebrow">{Page.Eyebrow}</span>
                                <h2>{Page.Title}</h2>
                                <p>{Page.Desc}</p>
                            </header>

                            <div class="hs-rows">
                                {#each Page.Rows as Row}
                                    <div class="hs-row">
                                        <div class="hs-row__text">
                                            <strong>{Row.Title}</strong>
                                            <span>{Row.Desc}</span>
                                        </div>

                                        <div class="hs-row__control">
                                            {#if Row.Type == "toggle"}
                                                <button
                                                    class="hs-switch"
                                                    type="button"
                                                    role="switch"
                                                    aria-label={Row.Title}
                                                    aria-checked={GetPath($HudSettings, Row.Path) !== false}
                                                    on:click={() => Change(Row.Path, GetPath($HudSettings, Row.Path) === false)}
                                                ></button>
                                            {:else if Row.Type == "segment"}
                                                <div class="hs-seg" role="group" aria-label={Row.Title}>
                                                    {#each Row.Options as Option}
                                                        <button
                                                            type="button"
                                                            aria-pressed={GetPath($HudSettings, Row.Path) == Option[0]}
                                                            on:click={() => Change(Row.Path, Option[0])}
                                                        >{Option[1]}</button>
                                                    {/each}
                                                </div>
                                            {:else if Row.Type == "range"}
                                                <div class="hs-range">
                                                    <input
                                                        type="range"
                                                        min={Row.Min}
                                                        max={Row.Max}
                                                        step="1"
                                                        aria-label={Row.Title}
                                                        value={GetPath($HudSettings, Row.Path)}
                                                        style:--p={PaintRange(Row.Min, Row.Max, GetPath($HudSettings, Row.Path))}
                                                        on:input={(Event) => Change(Row.Path, Number(Event.currentTarget.value))}
                                                    />
                                                    <output>{GetPath($HudSettings, Row.Path)}{Row.Unit || ""}</output>
                                                </div>
                                            {:else if Row.Type == "action"}
                                                <button class="hs-btn hs-btn--line" type="button" on:click={() => RunAction(Row.Action)}>{Row.Button}</button>
                                            {/if}
                                        </div>
                                    </div>
                                {/each}
                            </div>
                        </section>
                    {/if}
                </main>
            </div>

            <footer class="hs-foot">
                <span class="hs-foot__brand">{String(Brand).toUpperCase()} / Persoonlijke instellingen</span>
                <div class="hs-foot__actions">
                    <button class="hs-btn hs-btn--line" class:is-armed={ArmedLayout} type="button" on:click={() => ResetClick("layout")}>
                        {ArmedLayout ? "Klik opnieuw om te bevestigen" : "HUD resetten"}
                    </button>
                    <button class="hs-btn hs-btn--cyan" class:is-armed={ArmedAll} type="button" on:click={() => ResetClick("all")}>
                        {ArmedAll ? "Klik opnieuw om te bevestigen" : "Alles resetten"}
                    </button>
                </div>
            </footer>
        </div>
    </div>
{/if}

{#if MenuOpen && $LayoutEditing}
    <div class="hs-editor" role="application" aria-label="Layout editor" style="pointer-events: auto;">
        <div class="hs-editor__grid" aria-hidden="true"></div>

        <div class="hs-handles">
            {#each LayoutElements as Definition (Definition.Id)}
                {@const Rect = Rects[Definition.Id]}
                {#if Rect}
                    <div
                        class="hs-handle"
                        class:is-selected={SelectedId == Definition.Id}
                        class:is-dragging={Drag?.Id == Definition.Id}
                        style:left="{Rect.Left - HandlePad}px"
                        style:top="{Rect.Top - HandlePad}px"
                        style:width="{Rect.Right - Rect.Left + (HandlePad * 2)}px"
                        style:height="{Rect.Bottom - Rect.Top + (HandlePad * 2)}px"
                        on:pointerdown={(Event) => StartDrag(Event, Definition)}
                        on:pointermove={MoveDrag}
                        on:pointerup={EndDrag}
                        on:pointercancel={EndDrag}
                    >
                        <span>{Definition.Label}</span>
                    </div>
                {/if}
            {/each}
        </div>

        <div class="hs-toolbar" role="toolbar" aria-label="Layout editor">
            <div class="hs-toolbar__name">
                <span class="hs-eyebrow">Layout editor</span>
                <strong>{SelectedDefinition.Label}</strong>
            </div>
            <label class="hs-toolbar__size" for="hs-size">
                <span>Grootte</span>
                <input
                    type="range"
                    id="hs-size"
                    min="40"
                    max="200"
                    step="1"
                    value={Math.round(SelectedLayout.scale * 100)}
                    style:--p={PaintRange(40, 200, Math.round(SelectedLayout.scale * 100))}
                    on:input={(Event) => SetScale(Event.currentTarget.value)}
                />
                <output for="hs-size">{Math.round(SelectedLayout.scale * 100)}%</output>
            </label>
            <button class="hs-btn hs-btn--line" type="button" on:click={ResetElement}>Element resetten</button>
            <button class="hs-btn hs-btn--cyan" type="button" on:click={CloseEditor}>Klaar</button>
        </div>

        <p class="hs-editor__hint">Klik op een element om het te selecteren en sleep het. Pijltjestoetsen verplaatsen 1 px, Shift + pijl 10 px. Esc gaat terug naar het menu.</p>
    </div>
{/if}

<style>
    :global(.hs-menu), :global(.hs-editor) {
        --u: min(0.078125vw, 0.138889vh);
        --ink: #101112;
        --cyan: #2ecbe0;
        --cyan-deep: #0e93a6;
        --paper: #ffffff;
        --mist: #eef1f2;
        --wash: #f6f7f7;
        --line: #d7dcde;
        --mute: #6f787c;
        --fs-2xs: max(9px, calc(7 * var(--u)));
        --fs-xs: max(10px, calc(8 * var(--u)));
        --fs-sm: max(11px, calc(9.5 * var(--u)));
        --fs-md: max(12px, calc(11 * var(--u)));
        --fs-lg: max(15px, calc(14 * var(--u)));
        --fs-xl: max(20px, calc(21 * var(--u)));
        font-family: "Barlow Semi Condensed", "Barlow", "Inter", sans-serif;
        color: var(--ink);
    }
    :global(:where(.hs-menu, .hs-editor) button) {
        font: inherit;
        color: inherit;
        cursor: pointer;
    }
    :global(.hs-menu :focus-visible), :global(.hs-editor :focus-visible) {
        outline: 2px solid var(--ink);
        outline-offset: 2px;
    }
    :global(.hs-menu) {
        position: fixed;
        inset: 0;
        z-index: 20000;
        display: grid;
        place-items: center;
        animation: hs-in 0.14s ease-out;
    }
    @keyframes -global-hs-in {from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: none; }
    }
    :global(.hs-panel) {
        display: grid;
        grid-template-rows: auto 1fr calc(34 * var(--u));
        width: calc(750 * var(--u));
        height: calc(470 * var(--u));
        overflow: hidden;
        background: var(--paper);
        box-shadow: 0 calc(20 * var(--u)) calc(60 * var(--u)) rgba(0, 0, 0, 0.35);
    }
    :global(.hs-eyebrow) {
        display: block;
        color: var(--mute);
        font-size: var(--fs-2xs);
        font-weight: 700;
        letter-spacing: 0.02em;
        text-transform: uppercase;
    }
    :global(.hs-head) {
        display: flex;
        align-items: center;
        justify-content: space-between;
        height: calc(56 * var(--u));
        padding: 0 calc(19 * var(--u));
        border-bottom: calc(2 * var(--u)) solid var(--ink);
    }
    :global(.hs-head h1) {
        margin-top: calc(1 * var(--u));
        font-size: var(--fs-xl);
        font-style: italic;
        font-weight: 800;
        line-height: 1;
        text-transform: uppercase;
    }
    :global(.hs-head__right) {
        display: flex;
        align-items: center;
        gap: calc(12 * var(--u));
    }
    :global(.hs-head__page) {
        font-size: var(--fs-xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-close) {
        display: flex;
        align-items: center;
        gap: calc(4 * var(--u));
        height: calc(24 * var(--u));
        padding: 0 calc(10 * var(--u));
        border: 0;
        background: var(--ink);
        color: var(--paper);
        font-style: italic;
        text-transform: uppercase;
    }
    :global(.hs-close b) {
        font-size: var(--fs-xs);
        font-weight: 800;
    }
    :global(.hs-close span) {
        font-size: var(--fs-2xs);
        font-weight: 700;
    }
    :global(.hs-close:hover) {
        background: #2b2f31;
    }
    :global(.hs-body) {
        display: grid;
        grid-template-columns: calc(128 * var(--u)) 1fr;
        min-height: 0;
    }
    :global(.hs-nav) {
        display: flex;
        flex-direction: column;
        background: var(--wash);
        border-right: 1px solid var(--line);
    }
    :global(.hs-nav__item) {
        display: flex;
        align-items: center;
        gap: calc(12 * var(--u));
        height: calc(34 * var(--u));
        padding: 0 calc(12 * var(--u));
        border: 0;
        border-bottom: 1px solid var(--line);
        background: transparent;
        text-align: left;
        text-transform: uppercase;
    }
    :global(.hs-nav__item i) {
        width: calc(12 * var(--u));
        color: var(--mute);
        font-size: var(--fs-2xs);
        font-style: normal;
        font-weight: 700;
    }
    :global(.hs-nav__item span) {
        font-size: var(--fs-sm);
        font-style: italic;
        font-weight: 800;
    }
    :global(.hs-nav__item:hover) {
        background: var(--mist);
    }
    :global(.hs-nav__item.is-active) {
        background: var(--cyan);
    }
    :global(.hs-nav__item.is-active i) {
        color: var(--ink);
    }
    :global(.hs-nav__foot) {
        margin: auto calc(12 * var(--u)) calc(14 * var(--u));
        padding-top: calc(8 * var(--u));
        border-top: calc(1.5 * var(--u)) solid var(--ink);
    }
    :global(.hs-nav__preview) {
        display: block;
        font-size: var(--fs-2xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-nav__state) {
        display: block;
        margin-top: calc(3 * var(--u));
        color: var(--mute);
        font-size: var(--fs-2xs);
        font-weight: 700;
    }
    :global(.hs-nav__state.is-saving) {
        color: var(--cyan-deep);
    }
    :global(.hs-main) {
        min-width: 0;
        min-height: 0;
        padding: calc(14 * var(--u)) calc(17 * var(--u)) calc(14 * var(--u));
        overflow-y: auto;
        background-color: var(--paper);
        background-image:
            linear-gradient(rgba(16, 17, 18, 0.045) 1px, transparent 1px),
            linear-gradient(90deg, rgba(16, 17, 18, 0.045) 1px, transparent 1px);
        background-size: calc(20 * var(--u)) calc(20 * var(--u));
        scrollbar-width: thin;
    }
    :global(.hs-main::-webkit-scrollbar) {
        width: 6px;
    }
    :global(.hs-main::-webkit-scrollbar-thumb) {
        background: var(--line);
    }
    :global(.hs-page__head) {
        padding-bottom: calc(9 * var(--u));
        border-bottom: calc(2 * var(--u)) solid var(--ink);
    }
    :global(.hs-page__head h2) {
        margin-top: calc(2 * var(--u));
        font-size: var(--fs-lg);
        font-style: italic;
        font-weight: 800;
        line-height: 1.1;
        text-transform: uppercase;
    }
    :global(.hs-page__head p) {
        margin-top: calc(4 * var(--u));
        color: var(--mute);
        font-size: var(--fs-xs);
        font-weight: 700;
    }
    :global(.hs-callout) {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: calc(16 * var(--u));
        margin-top: calc(14 * var(--u));
        padding: calc(14 * var(--u)) calc(18 * var(--u));
        border-left: calc(3 * var(--u)) solid var(--cyan);
        background: var(--mist);
    }
    :global(.hs-callout h3) {
        margin-top: calc(3 * var(--u));
        font-size: var(--fs-md);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-callout p) {
        margin-top: calc(5 * var(--u));
        color: var(--mute);
        font-size: var(--fs-xs);
        font-weight: 700;
    }
    :global(.hs-steps) {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: calc(6 * var(--u));
        margin-top: calc(8 * var(--u));
        list-style: none;
    }
    :global(.hs-steps li) {
        display: flex;
        align-items: center;
        gap: calc(8 * var(--u));
        height: calc(28 * var(--u));
        padding: 0 calc(10 * var(--u));
        border: 1px solid var(--line);
        background: var(--paper);
        font-size: var(--fs-xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-steps b) {
        color: var(--cyan-deep);
        font-size: var(--fs-2xs);
        font-style: normal;
    }
    :global(.hs-foot) {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 calc(19 * var(--u));
        border-top: 1px solid var(--line);
        background: var(--paper);
    }
    :global(.hs-foot__brand) {
        color: var(--mute);
        font-size: var(--fs-2xs);
        font-weight: 700;
        text-transform: uppercase;
    }
    :global(.hs-foot__actions) {
        display: flex;
        gap: calc(8 * var(--u));
    }
    :global(.hs-foot .hs-btn) {
        height: calc(22 * var(--u));
    }
    :global(.hs-panel:focus), :global(.hs-editor:focus) {
        outline: none;
    }
    :global(.hs-btn) {
        display: inline-grid;
        place-items: center;
        height: calc(24 * var(--u));
        padding: 0 calc(14 * var(--u));
        border: calc(1.5 * var(--u)) solid var(--ink);
        background: var(--paper);
        font-size: var(--fs-2xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
        white-space: nowrap;
    }
    :global(.hs-btn:hover) {
        background: var(--mist);
    }
    :global(.hs-btn--cyan) {
        border-color: var(--cyan);
        background: var(--cyan);
    }
    :global(.hs-btn--cyan:hover) {
        border-color: #58d8ea;
        background: #58d8ea;
    }
    :global(.hs-callout .hs-btn) {
        height: calc(30 * var(--u));
        padding: 0 calc(22 * var(--u));
    }
    :global(.hs-btn.is-armed) {
        border-color: #c0392b;
        background: #c0392b;
        color: #fff;
    }
    :global(.hs-rows) {
        display: grid;
        gap: calc(6 * var(--u));
        margin-top: calc(12 * var(--u));
    }
    :global(.hs-row) {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: calc(16 * var(--u));
        min-height: calc(38 * var(--u));
        padding: calc(7 * var(--u)) calc(12 * var(--u));
        border: 1px solid var(--line);
        background: var(--paper);
    }
    :global(.hs-row__text strong) {
        display: block;
        font-size: var(--fs-xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-row__text span) {
        display: block;
        margin-top: calc(2 * var(--u));
        color: var(--mute);
        font-size: var(--fs-2xs);
        font-weight: 700;
    }
    :global(.hs-row__control) {
        display: flex;
        flex: 0 0 auto;
        align-items: center;
        gap: calc(10 * var(--u));
    }
    :global(.hs-switch) {
        position: relative;
        width: calc(34 * var(--u));
        height: calc(16 * var(--u));
        padding: 0;
        border: calc(1.5 * var(--u)) solid var(--ink);
        background: var(--paper);
        transition: background-color 0.12s;
    }
    :global(.hs-switch::after) {
        content: "";
        position: absolute;
        top: calc(1.5 * var(--u));
        left: calc(1.5 * var(--u));
        width: calc(10 * var(--u));
        height: calc(10 * var(--u));
        background: var(--ink);
        transition: transform 0.12s;
    }
    :global(.hs-switch[aria-checked="true"]) {
        background: var(--cyan);
    }
    :global(.hs-switch[aria-checked="true"]::after) {
        transform: translateX(calc(18 * var(--u)));
    }
    :global(.hs-seg) {
        display: flex;
        border: calc(1.5 * var(--u)) solid var(--ink);
    }
    :global(.hs-seg button) {
        height: calc(20 * var(--u));
        padding: 0 calc(11 * var(--u));
        border: 0;
        border-left: 1px solid var(--ink);
        background: var(--paper);
        font-size: var(--fs-2xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-seg button:first-child) {
        border-left: 0;
    }
    :global(.hs-seg button[aria-pressed="true"]) {
        background: var(--cyan);
    }
    :global(.hs-range) {
        display: flex;
        align-items: center;
        gap: calc(8 * var(--u));
    }
    :global(.hs-range output) {
        min-width: calc(34 * var(--u));
        font-size: var(--fs-xs);
        font-style: italic;
        font-weight: 800;
        text-align: right;
    }
    :global(.hs-menu input[type="range"]), :global(.hs-editor input[type="range"]) {
        --p: 50%;
        width: calc(130 * var(--u));
        height: calc(14 * var(--u));
        background: transparent;
        appearance: none;
        -webkit-appearance: none;
        cursor: pointer;
    }
    :global(.hs-menu input[type="range"]::-webkit-slider-runnable-track), :global(.hs-editor input[type="range"]::-webkit-slider-runnable-track) {
        height: calc(4 * var(--u));
        background: linear-gradient(90deg, var(--cyan) var(--p), #cfd5d7 var(--p));
    }
    :global(.hs-menu input[type="range"]::-webkit-slider-thumb), :global(.hs-editor input[type="range"]::-webkit-slider-thumb) {
        width: calc(8 * var(--u));
        height: calc(14 * var(--u));
        margin-top: calc(-5 * var(--u));
        border: 0;
        background: var(--ink);
        appearance: none;
        -webkit-appearance: none;
    }
    :global(.hs-editor) {
        position: fixed;
        inset: 0;
        z-index: 20000;
        touch-action: none;
    }
    :global(.hs-editor__grid) {
        position: absolute;
        inset: 0;
        background-image:
            linear-gradient(rgba(255, 255, 255, 0.10) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255, 255, 255, 0.10) 1px, transparent 1px);
        background-size: 5vw 5vw;
        box-shadow: inset 0 0 0 calc(3 * var(--u)) var(--cyan);
    }
    :global(.hs-handles) {
        position: absolute;
        inset: 0;
    }
    :global(.hs-handle) {
        position: absolute;
        border: calc(1.5 * var(--u)) dashed rgba(255, 255, 255, 0.85);
        background: rgba(255, 255, 255, 0.05);
        box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.5);
        cursor: grab;
    }
    :global(.hs-handle span) {
        position: absolute;
        bottom: 100%;
        left: calc(-1.5 * var(--u));
        padding: calc(2 * var(--u)) calc(6 * var(--u));
        background: var(--ink);
        color: #fff;
        font-size: var(--fs-2xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
        white-space: nowrap;
    }
    :global(.hs-handle.is-selected) {
        border: calc(2 * var(--u)) solid var(--cyan);
        background: rgba(46, 203, 224, 0.14);
    }
    :global(.hs-handle.is-selected span) {
        background: var(--cyan);
        color: var(--ink);
    }
    :global(.hs-handle.is-dragging) {
        cursor: grabbing;
    }
    :global(.hs-toolbar) {
        position: absolute;
        top: calc(22 * var(--u));
        left: 50%;
        display: flex;
        align-items: center;
        gap: calc(16 * var(--u));
        padding: calc(10 * var(--u)) calc(14 * var(--u));
        border-top: calc(2 * var(--u)) solid var(--ink);
        background: var(--paper);
        box-shadow: 0 calc(10 * var(--u)) calc(30 * var(--u)) rgba(0, 0, 0, 0.4);
        transform: translateX(-50%);
    }
    :global(.hs-toolbar__name) {
        min-width: calc(120 * var(--u));
    }
    :global(.hs-toolbar__name strong) {
        display: block;
        margin-top: calc(2 * var(--u));
        font-size: var(--fs-md);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-toolbar__size) {
        display: flex;
        align-items: center;
        gap: calc(8 * var(--u));
        font-size: var(--fs-2xs);
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
    }
    :global(.hs-toolbar__size output) {
        min-width: calc(30 * var(--u));
        font-size: var(--fs-xs);
        text-align: right;
    }
    :global(.hs-editor__hint) {
        position: absolute;
        right: 0;
        bottom: calc(18 * var(--u));
        left: 0;
        width: max-content;
        max-width: 90vw;
        margin: 0 auto;
        padding: calc(5 * var(--u)) calc(12 * var(--u));
        background: rgba(16, 17, 18, 0.82);
        color: #fff;
        font-size: var(--fs-xs);
        font-weight: 700;
        text-align: center;
    }

    /* ---- optional HUD parts (toggles). Class names are the ones used by the Svelte layers. ---- */
    :global(body:not(.layout-editing).hs-no-map .compass),
    :global(body:not(.layout-editing).hs-no-heading .compass__degree),
    :global(body:not(.layout-editing).hs-no-location .compass__location),
    :global(body:not(.layout-editing).hs-no-waypoint .compass__waypoint),
    :global(body:not(.layout-editing).hs-no-voice .voice-badge),
    :global(body:not(.layout-editing).hs-no-voice .voice-divider),
    :global(body:not(.layout-editing).hs-no-needs .needs),
    :global(body:not(.layout-editing).hs-no-ammo .weapon-hud),
    :global(body:not(.layout-editing).hs-no-gear .gear),
    :global(body:not(.layout-editing).hs-no-gear .gear-label),
    :global(body:not(.layout-editing).hs-no-fuel .fuel-icon),
    :global(body:not(.layout-editing).hs-no-fuel .fuel-bg),
    :global(body:not(.layout-editing).hs-no-fuel .fuel-fill),
    :global(body:not(.layout-editing).hs-no-icons .icons),
    :global(body:not(.layout-editing).hs-no-controls .controls) {
        display: none !important;
    }

    /* Overall HUD opacity (General page) */
    :global(.player-hud),
    :global(.center-status),
    :global(.weapon-hud),
    :global(.speedometer),
    :global(.controls),
    :global(.compass) {
        opacity: var(--hs-opacity, 1);
    }
</style>
