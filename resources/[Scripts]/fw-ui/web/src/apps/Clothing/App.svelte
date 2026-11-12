<script>
    // Clothing / barber / tattoo / character creation menu.
    // Layout and look ported from illenium-appearance (Codera UI), driven by fw-clothes.
    import "./fonts/fonts.css";
    import "./clothing.css";

    import { onMount } from "svelte";
    import AppWrapper from "../../components/AppWrapper.svelte";
    import { IsEnvBrowser, OnEvent } from "../../utils";
    import { Visible, MenuType, Values, Skin, Blocked, Meta, Price, Post, RefreshPrice } from "./clothing.store";
    import { MenuTabs, StartPath, ApparelFolders, TabItems, Leaves } from "./menu";

    import Navigation from "./components/Navigation.svelte";
    import Sidebar from "./components/Sidebar.svelte";
    import Grid from "./components/Grid.svelte";
    import Sliders from "./components/Sliders.svelte";
    import SidePanel from "./components/SidePanel.svelte";
    import Outfits from "./components/Outfits.svelte";
    import Checkout from "./components/Checkout.svelte";
    import Keybinds from "./components/Keybinds.svelte";
    import Toggles from "./components/Toggles.svelte";

    let Path = ["APPAREL"];
    let Modal = false;
    let Scale = 1, Width = 1920;

    // ---- Events from fw-clothes ----
    OnEvent("Clothing", "SetVisibility", (Data) => {
        Visible.set(!!Data.Visible);
        Modal = false;
        if (!Data.Visible) return;

        MenuType.set(Data.Type || "Creation");
        Price.set(0);
        Path = StartPath[Data.Type] || StartPath.Creation;
        Focus("character");
    });

    OnEvent("Clothing", "SetComponentValues", (Data) => {
        if (Data.Values != undefined) Values.set(Data.Values);
        if (Data.CurrentSkin != undefined) Skin.set(Data.CurrentSkin);
        if (Data.BlockedValues != undefined) Blocked.set(Data.BlockedValues);

        Meta.update((M) => {
            const N = { ...M };
            for (const Key of ["Model", "Gender", "PedId", "IsCustomPed", "CustomPeds", "PedList", "TattooNames", "MaxTattooLayers", "IsFree", "ItemPrice", "Images", "Money"]) {
                if (Data[Key] != undefined) N[Key] = Data[Key];
            }
            if (Data.IsCustomPed) N.Model = Data.IsCustomPed;
            return N;
        });
    });

    // ---- Menu structure ----
    $: Tabs = (MenuTabs[$MenuType] || MenuTabs.Creation);
    $: ActiveTab = Math.max(0, Tabs.indexOf(Path[0]));
    $: Folders = Object.keys(ApparelFolders).filter((F) => F != "OUTFITS" || $MenuType == "Clothes");
    $: TabList = (Tab) => (TabItems[Tab] || []).filter((I) => I != "CUSTOM PEDS" || ($Meta.CustomPeds || []).length > 0);

    $: IsApparel = Path[0] == "APPAREL";
    $: Depth = IsApparel ? 3 : 2;
    $: Label = Path.length >= Depth ? Path[Path.length - 1] : null;
    $: Leaf = Label ? Leaves[Label] : null;
    $: SidebarItems = IsApparel ? (Path.length == 1 ? Folders : ApparelFolders[Path[1]] || []) : TabList(Path[0]);
    $: RailProps = IsApparel
        ? { Folders, FolderItems: ApparelFolders, Items: ApparelFolders[Path[1]] || [] }
        : { Items: TabList(Path[0]) };
    $: ShowSide = Leaf && (Leaf.Kind == "component" || Leaf.Kind == "hair" || Leaf.Kind == "overlay");

    const Focus = (Where) => Post("Clothing/SetCameraFocus", { Focus: Where });

    $: OutfitsOnly = $MenuType == "Outfits";

    const Navigate = (NewPath) => {
        if (OutfitsOnly) return; // single view, nothing to navigate to
        Path = NewPath;
        const NewLabel = NewPath.length >= (NewPath[0] == "APPAREL" ? 3 : 2) ? NewPath[NewPath.length - 1] : null;
        if (NewLabel && Leaves[NewLabel]) return Focus(Leaves[NewLabel].Cam);
        Focus(["FACE & BODY", "FACE ADJUSTMENTS", "OVERLAYS", "HAIR"].includes(NewPath[0]) ? "head" : "character");
    };

    const SelectTab = (Index) => {
        if (Index < 0 || Index >= Tabs.length) return;
        Navigate([Tabs[Index]]);
    };

    // ---- Checkout ----
    $: Free = $Meta.IsFree || $Price <= 0;

    const Confirm = () => {
        if (Free) return Pay("Cash");
        Modal = "payment";
    };

    const Pay = (Type) => {
        Modal = false;
        Post("Clothing/CloseMenu", { Pay: true, Type });
    };

    const Discard = () => {
        Modal = false;
        Post("Clothing/CloseMenu", { Pay: false });
    };

    // ---- Keyboard ----
    const OnKey = (Event) => {
        if (!$Visible) return;
        const Tag = Event.target?.tagName;
        if (Tag == "INPUT" || Tag == "TEXTAREA") {
            if (Event.key == "Escape") Event.target.blur();
            return;
        }

        const Key = Event.key.toLowerCase();
        if (Event.key == "Escape") {
            if (OutfitsOnly) return Discard();
            Modal = Modal ? false : "exit";
        } else if (Event.key == "Tab" || Event.key == "Enter") {
            Event.preventDefault();
            if (!Modal && !OutfitsOnly) Confirm();
        } else if (Modal) {
            return;
        } else if (Key == "q") {
            SelectTab(ActiveTab - 1);
        } else if (Key == "e") {
            SelectTab(ActiveTab + 1);
        } else if (Key == "a" || Event.key == "ArrowLeft") {
            Post("Clothing/Rotate", { Dir: -1 });
        } else if (Key == "d" || Event.key == "ArrowRight") {
            Post("Clothing/Rotate", { Dir: 1 });
        } else if (Key == "w" || Event.key == "ArrowUp") {
            Post("Clothing/CameraStep", { Up: false });
        } else if (Key == "s" || Event.key == "ArrowDown") {
            Post("Clothing/CameraStep", { Up: true });
        }
    };

    // Designed at 1080p (illenium sizes), scaled to the real screen.
    const Resize = () => {
        Scale = window.innerHeight / 1080;
        Width = window.innerWidth / Scale;
    };

    onMount(() => {
        Resize();
        if (IsEnvBrowser() && location.hash.startsWith("#clothing")) LoadPreview();
    });

    // Browser preview: npm run dev, open http://localhost:5173/#clothing (or #clothing-Barber etc.)
    const LoadPreview = () => {
        const Type = location.hash.split("-")[1] || "Clothes";
        Values.set({ Jacket: { MaxComps: 120, MaxTxts: 6 }, Undershirt: { MaxComps: 60, MaxTxts: 3 }, Pants: { MaxComps: 80, MaxTxts: 4 }, Shoes: { MaxComps: 70, MaxTxts: 2 },
            Hat: { MaxComps: 90, MaxTxts: 3 }, Masks: { MaxComps: 150, MaxTxts: 2 }, Hair: { MaxComps: 70, MaxTxts: 4 }, Beard: { MaxComps: 28, MaxTxts: 0 }, Eyebrows: { MaxComps: 33, MaxTxts: 0 },
            Makeup: { MaxComps: 70, MaxTxts: 0 }, Fade: { MaxComps: 70, MaxTxts: 0 }, Blemishes: { MaxComps: 23, MaxTxts: 0 } });
        Skin.set({ Jacket: [4, 0], Undershirt: [15, 0], Pants: [1, 0], Shoes: [1, 0], Hat: [-1, 0], Masks: [0, 0], Hair: [12, 0, 3, 5], Beard: [2, 100, 1, 0], Eyebrows: [3, 80, 0, 0],
            Makeup: [-1, 0, 0, 0], Fade: [0], FaceOne: [21, 3], FaceTwo: [33, 8], FaceThree: [0, 0], FaceMix: 50, SkinMix: 40, ThirdFaceMix: 0, FaceNose: [10, -20, 0, 0, 0, 0],
            FaceEyeColor: [4], TattoosTorso: [3, 7], Blemishes: [0, 0] });
        Meta.update((M) => ({ ...M, PedList: ["mp_m_freemode_01", "a_m_y_skater_01", "a_m_y_hipster_01", "ig_bankman"], Money: { Cash: 5420, Bank: 18250 }, ItemPrice: 28,
            TattooNames: { Torso: ["MP_Bea_M_Back_000", "MP_Bea_M_Chest_000", "MP_Bea_M_Chest_001", "MP_Biker_Tat_000_M", "MP_Biker_Tat_001_M", "MP_Biker_Tat_003_M", "MP_Biker_Tat_005_M", "MP_Biker_Tat_006_M"] } }));
        MenuType.set(Type);
        Visible.set(true);
        Path = StartPath[Type];
        RefreshPrice();
    };
</script>

<svelte:window on:keydown={OnKey} on:resize={Resize} />

<AppWrapper AppName="Clothing" Focused={$Visible}>
    {#if $Visible}
        <div class="fwc" style="zoom: {Scale}; width: {Width}px;">
            <Navigation Tabs={Tabs} Active={ActiveTab} Select={SelectTab} Money={$Meta.Money} ShowMoney={!$Meta.IsFree && !OutfitsOnly} />

            {#key Path.join("/")}
                {#if !Leaf}
                    <Sidebar {Path} Items={SidebarItems} {Navigate} />
                {:else if Leaf.Kind == "outfits"}
                    <Outfits {Path} RailProps={OutfitsOnly ? {} : RailProps} {Navigate} Close={OutfitsOnly && Discard} />
                {:else if Leaf.Kind == "headblend" || Leaf.Kind == "features"}
                    <Sliders {Path} {Leaf} {RailProps} {Navigate} />
                {:else}
                    <Grid {Path} {Label} {Leaf} {RailProps} {Navigate} />
                {/if}
            {/key}

            {#if ShowSide}
                {#key Label}
                    <SidePanel {Leaf} />
                {/key}
            {/if}

            {#if IsApparel}
                <Toggles />
            {/if}

            <Keybinds CheckoutLabel={OutfitsOnly ? false : Free ? "SAVE" : "CHECKOUT"} />
            {#if !OutfitsOnly}
            <Checkout
                Total={$Price} IsFree={$Meta.IsFree} Money={$Meta.Money} {Modal}
                CanDiscard={$MenuType != "Creation"}
                {Confirm} {Pay} {Discard} CloseModal={() => (Modal = false)}
            />
            {/if}
        </div>
    {/if}
</AppWrapper>
