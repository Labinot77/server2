<script>
    import { onMount } from "svelte";
    import { fade, fly } from "svelte/transition";
    import { OnEvent } from "../../utils/Utils";
    import AppWrapper from "../../components/AppWrapper.svelte";

    import ItemCard from "./components/ItemCard.svelte";
    import ColorPicker from "./components/ColorPicker.svelte";
    import Cart from "./components/Cart.svelte";
    import { FormatPrice, PlaySound, Request, Same, SetResource, Throttle } from "./bennys.utils";
    import { StartMock } from "./bennys.mock";

    let Visible = false;
    let Header = "Los Santos Benny's";
    let SubHeader = "Motorworks for everyone";

    let Categories = [];
    let Original = {};
    let Current = {};
    let CartItems = [];
    let Palette = [];
    let PaintTypes = [];
    let Icons = {};

    let ActiveCategory = 0;
    let Stack = [];          // Opened nodes (Menu / Options / Slider)
    let ActiveColor = null;  // Color node of the current menu

    let ItemsList;

    $: Category = Categories[ActiveCategory];
    $: Top = Stack[Stack.length - 1];
    $: ListItems = !Top ? (Category?.Items || []) : Top.Type === "Menu" ? Top.Children : [];
    $: Title = ActiveColor ? `${Top?.Label || ""} ${ActiveColor.Label}`.trim() : Top?.Label;

    // ---------- Helpers ----------

    const CollectIcons = (Nodes, Into = {}) => {
        for (const Node of Nodes) {
            if (Node.Slot) Into[Node.Slot] = Node.Icon;
            if (Node.TypeSlot) Into[Node.TypeSlot] = Node.Icon;
            if (Node.Sliders) Node.Sliders.forEach(S => (Into[S.Slot] = Node.Icon));
            if (Node.Children) CollectIcons(Node.Children, Into);
        }
        return Into;
    };

    const Focus = Camera => Request("Focus", { Camera: Camera || "default" });

    const Preview = (Slot, Value, Label, Option, Price) => {
        Current = { ...Current, [Slot]: Value }; // Optimistic, client re-syncs.
        Request("Preview", { Slot, Value, Label, Option, Price });
    };

    const PreviewThrottled = Throttle(Preview, 60);

    // ---------- Navigation ----------

    const OpenCategory = Index => {
        if (Index === ActiveCategory && Stack.length === 0 && !ActiveColor) return;
        PlaySound();
        ActiveCategory = Index;
        Stack = [];
        ActiveColor = null;
        Focus("default");
        if (ItemsList) ItemsList.scrollLeft = 0;
    };

    const SelectNode = Node => {
        PlaySound();
        if (Node.Camera) Focus(Node.Camera);

        switch (Node.Type) {
            case "Menu":
            case "Options":
            case "Slider":
                ActiveColor = null;
                Stack = [...Stack, Node];
                if (ItemsList) ItemsList.scrollLeft = 0;
                break;
            case "Color":
                ActiveColor = ActiveColor?.Id === Node.Id ? null : Node;
                break;
            case "Action":
                if (CartItems.some(Item => Item.Slot === Node.Slot)) Revert(Node.Slot);
                else Preview(Node.Slot, Node.Value, Node.Label, "", Node.Price);
                break;
        }
    };

    const Back = () => {
        if (ActiveColor) {
            ActiveColor = null;
        } else if (Stack.length > 0) {
            Stack = Stack.slice(0, -1);
        } else {
            return;
        }
        PlaySound("BACK");
        Focus(Stack[Stack.length - 1]?.Camera || "default");
    };

    // ---------- Actions ----------

    const SelectOption = (Node, Option) => {
        PlaySound();
        const IsWheels = Node.Slot === "Wheels";
        Preview(Node.Slot, Option.Value, IsWheels ? "Wheels" : Node.Label, IsWheels ? `${Node.Label} - ${Option.Label}` : Option.Label, Option.Price);
    };

    const ColorLabel = Node => `${Stack[Stack.length - 1]?.Label === "Colors" ? "Colors " : ""}${Node.Label}`;

    const ChangeColor = (Node, Detail) => {
        PreviewThrottled(Node.Slot, Detail.Value, ColorLabel(Node), Detail.Hex.toUpperCase(), Node.Price);
    };

    const ChangePaintType = (Node, Type) => {
        PlaySound();
        Preview(Node.TypeSlot, Type.Value, `${ColorLabel(Node)} Type`, Type.Label, Node.TypePrice);
    };

    const ChangeSlider = (Node, Slider, Value) => {
        PreviewThrottled(Slider.Slot, Number(Value), `${Node.Label} ${Slider.Label}`, Number(Value).toFixed(2), Node.Price);
    };

    const Revert = Slot => {
        PlaySound("BACK");
        Current = { ...Current, [Slot]: Original[Slot] };
        Request("Revert", { Slot });
    };

    const Checkout = Method => {
        if (CartItems.length === 0) return;
        PlaySound();
        Request("Checkout", { Method });
    };

    const Exit = () => {
        PlaySound("BACK");
        Request("Close");
    };

    // State is passed in explicitly so Svelte re-renders when it changes.
    const ColorHex = (Node, State, Colors) => {
        const Value = State[Node.Slot];
        if (Node.Mode === "Index") return Colors[Value] || "#000000";
        return Value || "#000000";
    };


    const OptionFooter = (Slot, Option, Installed) => {
        if (Same(Installed[Slot], Option.Value)) return ["Installed", FormatPrice(0)];
        return ["In stock", FormatPrice(Option.Price)];
    };

    // ---------- Free camera (drag on empty space) + zoom ----------

    let Dragging = false;
    let DragDelta = { X: 0, Y: 0 };
    let DragFrame = null;

    const FlushDrag = () => {
        DragFrame = null;
        if (DragDelta.X === 0 && DragDelta.Y === 0) return;
        Request("RotateCamera", { ...DragDelta });
        DragDelta = { X: 0, Y: 0 };
    };

    const OnBackgroundDown = Event => {
        if (Event.button !== 0 && Event.button !== 1) return;
        Event.preventDefault();
        Dragging = true;
    };

    const OnMouseMove = Event => {
        if (!Dragging) return;
        DragDelta.X += Event.movementX;
        DragDelta.Y += Event.movementY;
        if (!DragFrame) DragFrame = requestAnimationFrame(FlushDrag);
    };

    const OnMouseUp = () => (Dragging = false);

    const OnBackgroundWheel = Event => Request("Zoom", { Delta: Event.deltaY > 0 ? 0.45 : -0.45 });

    // Mouse wheel over the item list scrolls it sideways instead of zooming.
    const OnListWheel = Event => {
        Event.stopPropagation();
        if (!ItemsList) return;
        ItemsList.scrollLeft += Event.deltaY + Event.deltaX;
    };

    // ---------- Keys ----------

    const OnKeyUp = Event => {
        if (!Visible) return;
        if (Event.key === "Escape") Exit();
        else if (Event.key === "Backspace") Back();
    };

    onMount(() => {
        window.addEventListener("keyup", OnKeyUp);
        window.addEventListener("mousemove", OnMouseMove);
        window.addEventListener("mouseup", OnMouseUp);
        StartMock();
        return () => {
            window.removeEventListener("keyup", OnKeyUp);
            window.removeEventListener("mousemove", OnMouseMove);
            window.removeEventListener("mouseup", OnMouseUp);
        };
    });

    // ---------- Events ----------

    OnEvent("Bennys", "Open", Data => {
        SetResource(Data.Resource);
        Header = Data.Header || Header;
        SubHeader = Data.SubHeader || SubHeader;
        Categories = Data.Categories;
        Original = Data.Current;
        Current = { ...Data.Current };
        Palette = Data.Palette;
        PaintTypes = Data.PaintTypes;
        Icons = CollectIcons(Categories.flatMap(C => C.Items));
        CartItems = [];
        ActiveCategory = 0;
        Stack = [];
        ActiveColor = null;
    });

    OnEvent("Bennys", "SetCart", Data => {
        CartItems = Data.Cart;
        Current = Data.Current;
    });

    OnEvent("Bennys", "SetVisibility", Data => {
        Visible = Data.Visibility;
        Dragging = false;
    });

    const Keys = [
        ["Up", "W"], ["Down", "S"], ["Left", "A"], ["Right", "D"],
        ["Zoom Out", "Q"], ["Zoom In", "E"], ["Free Camera", "Mouse Wheel"], ["Exit", "ESC"],
    ];
</script>

<AppWrapper AppName="Bennys" Focused={Visible}>
    {#if Visible}
        <div class="bennys" transition:fade={{ duration: 200 }}>
            <!-- svelte-ignore a11y-no-static-element-interactions -->
            <div class="bennys-backdrop" class:dragging={Dragging} on:mousedown={OnBackgroundDown} on:wheel={OnBackgroundWheel}></div>

            <!-- Brand -->
            <div class="brand">
                <i class="fas fa-cog"></i>
                <div>
                    <p class="brand-title">{Header}</p>
                    <p class="brand-sub">{SubHeader}</p>
                </div>
            </div>

            <!-- Categories -->
            <div class="categories">
                {#each Categories as Cat, Index (Cat.Id)}
                    <div class="category" class:active={ActiveCategory === Index}>
                        <button class="category-card" on:click={() => OpenCategory(Index)}>
                            <i class="{Cat.Icon} category-icon"></i>
                            <div class="category-text">
                                <p class="category-label">{Cat.Label}</p>
                                <p class="category-description">{Cat.Description}</p>
                            </div>
                        </button>
                        <button class="category-open" on:click={() => OpenCategory(Index)}>
                            <span>Open Selection</span>
                            <i class="fal fa-long-arrow-right"></i>
                        </button>
                    </div>
                {/each}
            </div>

            <!-- Items -->
            <div class="items">
                {#if ActiveColor}
                    {#key ActiveColor.Id}
                        <div in:fly={{ y: 12, duration: 160 }}>
                            <ColorPicker
                                Hex={ColorHex(ActiveColor, Current, Palette)}
                                Mode={ActiveColor.Mode}
                                {Palette}
                                {PaintTypes}
                                PaintType={ActiveColor.TypeSlot ? Current[ActiveColor.TypeSlot] : null}
                                SelectedIndex={ActiveColor.Mode === "Index" ? Current[ActiveColor.Slot] : null}
                                on:change={E => ChangeColor(ActiveColor, E.detail)}
                                on:paint={E => ChangePaintType(ActiveColor, E.detail)}
                            />
                        </div>
                    {/key}
                {/if}

                {#if Title}
                    <div class="items-title">
                        <button class="back" on:click={Back}><i class="fal fa-angle-left"></i></button>
                        <p>{Title}</p>
                    </div>
                {/if}

                <div class="items-header">
                    <p>Items List</p>
                    <span></span>
                </div>

                {#if Top && Top.Type === "Slider"}
                    <div class="sliders" in:fly={{ y: 12, duration: 160 }}>
                        {#each Top.Sliders as Slider (Slider.Slot)}
                            <div class="slider-row">
                                <div class="slider-text">
                                    <p class="slider-label">{Slider.Label}</p>
                                    <p class="slider-description">{Slider.Description} | <b>{Number(Current[Slider.Slot] ?? 0).toFixed(2)}</b></p>
                                </div>
                                <input
                                    type="range"
                                    min={Slider.Min}
                                    max={Slider.Max}
                                    step={Slider.Step}
                                    value={Current[Slider.Slot] ?? Slider.Min}
                                    style="--fill: {((Number(Current[Slider.Slot] ?? Slider.Min) - Slider.Min) / (Slider.Max - Slider.Min)) * 100}%"
                                    on:input={E => ChangeSlider(Top, Slider, E.currentTarget.value)}
                                />
                                {#if !Same(Current[Slider.Slot], Original[Slider.Slot])}
                                    <button class="slider-reset" title="Reset" on:click={() => Revert(Slider.Slot)}><i class="fal fa-undo"></i></button>
                                {/if}
                            </div>
                        {/each}
                    </div>
                {:else}
                    <!-- svelte-ignore a11y-no-static-element-interactions -->
                    <div class="items-list" bind:this={ItemsList} on:wheel|preventDefault={OnListWheel}>
                        {#if Top && Top.Type === "Options"}
                            {#each Top.Options as Option, Index (Top.Id + Index)}
                                {@const Footer = OptionFooter(Top.Slot, Option, Original)}
                                <ItemCard
                                    Label={Option.Label}
                                    Description={Top.Description}
                                    Icon={Top.Icon}
                                    Selected={Same(Current[Top.Slot], Option.Value)}
                                    Installed={Same(Original[Top.Slot], Option.Value)}
                                    FooterLeft={Footer[0]}
                                    FooterRight={Footer[1]}
                                    on:select={() => SelectOption(Top, Option)}
                                />
                            {/each}
                        {:else}
                            {#each ListItems as Node (Node.Id)}
                                {#if Node.Type === "Color"}
                                    <ItemCard
                                        Label={Node.Label}
                                        Description={Node.Description}
                                        Icon={Node.Icon}
                                        Swatch={ColorHex(Node, Current, Palette)}
                                        Selected={ActiveColor?.Id === Node.Id}
                                        on:select={() => SelectNode(Node)}
                                    />
                                {:else if Node.Type === "Action"}
                                    {@const InCart = CartItems.some(Item => Item.Slot === Node.Slot)}
                                    <ItemCard
                                        Label={Node.Label}
                                        Description={Node.Description}
                                        Icon={Node.Icon}
                                        Selected={InCart}
                                        FooterLeft={InCart ? "In Cart" : "Add to Cart"}
                                        FooterRight={FormatPrice(Node.Price)}
                                        on:select={() => SelectNode(Node)}
                                    />
                                {:else}
                                    <ItemCard
                                        Label={Node.Label}
                                        Description={Node.Description}
                                        Icon={Node.Icon}
                                        on:select={() => SelectNode(Node)}
                                    />
                                {/if}
                            {/each}
                        {/if}
                    </div>
                {/if}
            </div>

            <!-- Cart + payment -->
            <Cart
                Cart={CartItems}
                {Icons}
                {SubHeader}
                on:remove={E => Revert(E.detail.Slot)}
                on:checkout={E => Checkout(E.detail)}
            />

            <!-- Key hints -->
            <div class="keys">
                {#each Keys as [Label, Key]}
                    <div class="key">
                        <span>{Label}</span>
                        <kbd>{Key}</kbd>
                    </div>
                {/each}
            </div>
        </div>
    {/if}
</AppWrapper>

<style>
    .bennys {
        --bennys-accent: #3fd8e6;
        --bennys-accent-dark: #1b9fb0;
        --bennys-ink: #0b0d10;
        --bennys-panel: rgba(12, 13, 16, 0.78);
        --bennys-panel-hover: rgba(30, 33, 38, 0.88);
        --bennys-muted: #a2a8b0;

        position: absolute;
        inset: 0;
        font-family: "Barlow Semi Condensed", sans-serif;
        color: white;
        user-select: none;
    }

    .bennys-backdrop {
        position: absolute;
        inset: 0;
        cursor: grab;
        background:
            linear-gradient(90deg, rgba(0, 0, 0, 0.55) 0%, rgba(0, 0, 0, 0) 22%),
            linear-gradient(270deg, rgba(0, 0, 0, 0.5) 0%, rgba(0, 0, 0, 0) 22%),
            linear-gradient(0deg, rgba(0, 0, 0, 0.6) 0%, rgba(0, 0, 0, 0) 38%);
    }

    .bennys-backdrop.dragging { cursor: grabbing; }

    /* Brand */
    .brand {
        position: absolute;
        top: 4vh;
        left: 3.5vh;
        display: flex;
        align-items: center;
        gap: 1vh;
        pointer-events: none;
    }

    .brand > i {
        font-size: 2.6vh;
        color: var(--bennys-accent);
    }

    .brand-title {
        font-size: 2.3vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        line-height: 1;
        letter-spacing: 0.03vh;
    }

    .brand-sub {
        font-size: 1.2vh;
        font-weight: 600;
        font-style: italic;
        text-transform: uppercase;
        color: var(--bennys-muted);
    }

    /* Categories */
    .categories {
        position: absolute;
        top: 10vh;
        left: 3.5vh;
        display: flex;
        flex-direction: column;
        gap: 1.8vh;
        width: 16.5vh;
    }

    :where(.category > button) { all: unset; cursor: pointer; box-sizing: border-box; display: flex; width: 100%; }

    .category-card {
        position: relative;
        height: 18.5vh;
        overflow: hidden;
        background: radial-gradient(circle at 50% 30%, rgba(255, 255, 255, 0.08), transparent 70%), var(--bennys-panel);
        border-left: 0.25vh solid transparent;
        transition: background 150ms ease, border-color 150ms ease;
    }

    .category-card:hover { background: radial-gradient(circle at 50% 30%, rgba(63, 216, 230, 0.2), transparent 70%), var(--bennys-panel-hover); }

    .category.active .category-card {
        background: linear-gradient(160deg, var(--bennys-accent) 0%, var(--bennys-accent-dark) 100%);
        border-color: white;
    }

    .category-icon {
        position: absolute;
        top: 32%;
        left: 50%;
        transform: translate(-50%, -50%);
        font-size: 6vh;
        color: white;
        text-shadow: 0 0.5vh 1.4vh rgba(0, 0, 0, 0.5);
    }

    .category-text { position: absolute; left: 1.2vh; right: 1.2vh; bottom: 1.1vh; }

    .category-label {
        font-size: 1.7vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
    }

    .category-description {
        font-size: 1.15vh;
        font-weight: 500;
        line-height: 1.25;
        color: var(--bennys-muted);
    }

    .category.active .category-icon,
    .category.active .category-label { color: var(--bennys-ink); text-shadow: none; }
    .category.active .category-description { color: rgba(11, 13, 16, 0.75); }

    .category-open {
        align-items: center;
        justify-content: space-between;
        height: 3.2vh;
        margin-top: 0.35vh;
        padding: 0 1.2vh;

        font-size: 1.2vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        background: var(--bennys-panel);
        transition: background 150ms ease, color 150ms ease;
    }

    .category-open > i { font-size: 1.8vh; color: var(--bennys-accent); }
    .category-open:hover { background: var(--bennys-panel-hover); }
    .category.active .category-open { background: white; color: var(--bennys-ink); }
    .category.active .category-open > i { color: var(--bennys-ink); }

    /* Items */
    .items {
        position: absolute;
        left: 24vh;
        right: 35vh;
        bottom: 7vh;
    }

    .items-title {
        display: flex;
        align-items: center;
        gap: 1vh;
        margin-bottom: 1.2vh;
    }

    .back {
        all: unset;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 2.6vh;
        height: 2.6vh;
        font-size: 1.8vh;
        color: var(--bennys-accent);
        border: 0.1vh solid var(--bennys-accent);
        transition: all 120ms ease;
    }

    .back:hover { background: var(--bennys-accent); color: var(--bennys-ink); }

    .items-title > p {
        font-size: 2.2vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
    }

    .items-header {
        display: flex;
        align-items: center;
        gap: 1.2vh;
        margin-bottom: 1.1vh;
    }

    .items-header > p {
        font-size: 1.35vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        white-space: nowrap;
    }

    .items-header > span {
        flex: 1;
        height: 0.1vh;
        background: linear-gradient(90deg, rgba(255, 255, 255, 0.5), rgba(255, 255, 255, 0));
    }

    .items-list {
        display: flex;
        overflow-x: auto;
        overflow-y: hidden;
        padding: 0.4vh 0 0.8vh 0;
        scroll-behavior: smooth;
    }

    .items-list::-webkit-scrollbar { height: 0.35vh; }
    .items-list::-webkit-scrollbar-thumb { background: rgba(63, 216, 230, 0.6); }
    .items-list::-webkit-scrollbar-track { background: rgba(255, 255, 255, 0.06); }

    /* Sliders */
    .sliders {
        display: flex;
        flex-direction: column;
        gap: 0.5vh;
        width: 48vh;
        padding: 0.4vh 0;
    }

    .slider-row {
        display: flex;
        align-items: center;
        gap: 1.4vh;
        padding: 1.1vh 1.4vh;
        background: var(--bennys-panel);
        border-left: 0.25vh solid var(--bennys-accent);
    }

    .slider-text { flex: 0 0 19vh; }

    .slider-label {
        font-size: 1.55vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        color: var(--bennys-accent);
    }

    .slider-description { font-size: 1.15vh; font-weight: 500; color: var(--bennys-muted); }
    .slider-description > b { color: white; font-weight: 700; }

    .slider-row > input {
        -webkit-appearance: none;
        appearance: none;
        flex: 1;
        height: 0.5vh;
        cursor: pointer;
        background: linear-gradient(90deg, var(--bennys-accent) var(--fill), rgba(255, 255, 255, 0.18) var(--fill));
        outline: none;
    }

    .slider-row > input::-webkit-slider-thumb {
        -webkit-appearance: none;
        width: 1.1vh;
        height: 2vh;
        background: white;
        box-shadow: 0 0 0.6vh rgba(0, 0, 0, 0.6);
    }

    .slider-reset {
        all: unset;
        cursor: pointer;
        font-size: 1.3vh;
        color: var(--bennys-muted);
    }

    .slider-reset:hover { color: var(--bennys-accent); }

    /* Keys */
    .keys {
        position: absolute;
        right: 3.5vh;
        bottom: 2.2vh;
        display: flex;
        gap: 1.6vh;
        pointer-events: none;
    }

    .key {
        display: flex;
        align-items: center;
        gap: 0.6vh;
        font-size: 1.15vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
    }

    .key > kbd {
        min-width: 1.4vh;
        padding: 0.3vh 0.6vh;
        text-align: center;
        font-family: "Barlow Semi Condensed", sans-serif;
        font-size: 1.1vh;
        font-weight: 800;
        color: var(--bennys-ink);
        background: white;
    }
</style>
