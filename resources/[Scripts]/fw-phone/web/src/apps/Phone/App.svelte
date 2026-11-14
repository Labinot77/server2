<script>
    import { fade } from "svelte/transition";

    import { WheaterIcons } from "../../config";
    import { AddNotification, IsEnvBrowser, Notifications, OnEvent, RemoveNotification, SendEvent, SetDropdown, SetExitHandler, ShowSuccessModal, UpdateNotification } from "../../utils/Utils"
    import AppProvider from "./AppProvider.svelte";
    import Application from "./components/Application.svelte";
    import Icon from "./components/Icon.svelte";
    import { HomeApps, CarShops, DockApps, BurnerApps, Hotkeys } from "./apps";
    import Container from "./Container.svelte";
    import Input from "./Modals/Input.svelte";
    import Loader from "./Modals/Loader.svelte";
    import Success from "./Modals/Success.svelte";
    import { HasVpn, HasRacingUsb, HasPDRacingUsb, RacingAlias, InputModal, JobManager, CurrentDocument, DocumentIsDrop, LoaderModal, PlayerData, SuccessModal, Brand, EmbedsEnabled, PhoneBackground, Settings } from "./phone.stores";
    import { ImageHoverData } from "../../stores";

    let PhoneVisible = IsEnvBrowser(); // Is A phone visible?
    let IsBurnerCurrent = false; // Is the phone a burner?
    let SoundsMuted = false;
    let IsNearNetwork = false;
    let IsNetworkEnabled = true;

    let CurrentNetwork = "";
    let CurrentApp = "home" // Default: "home";
    let CurrentTime = [12, 0]
    let CurrentWeather = "EXTRASUNNY";
    let CurrentLocation = "Los Santos";
    let UnreadApps = {};

    const SetCurrentApp = (App) => {
        CurrentApp = App;
        UnreadApps[App] = false;
        SendEvent("SetCurrentApp", {App})
    };

    const ToggleSound = () => {
        SoundsMuted = !SoundsMuted;
        SendEvent("Phone/ToggleSounds", {State: SoundsMuted})
    };

    const GoHome = () => {
        if (CurrentApp != "home") {
            CurrentApp = "home"
            SendEvent("SetCurrentApp", {App: "home"})
        };
    };

    const ConnectNetwork = () => {
        if (!IsNearNetwork) return;

        SendEvent("Network/GetNetworks", {}, (Success, Data) => {
            if (!Success) return;

            InputModal.set({
                Visible: true,
                Inputs: [
                    {
                        Id: "Network",
                        Type: "TextField",
                        Data: {
                            Title: "Network:",
                            Select: Data.map(({ Id, Name }) => ({ Text: Name, Value: Id })),
                            Value: Data[0]?.Value,
                            RealValue: Data[0]?.Text,
                        },
                    },
                    {
                        Id: "Password",
                        Type: "TextField",
                        Data: {
                            Title: "Password",
                            Type: "password",
                            Icon: "user-lock"
                        },
                    },
                ],
                OnSubmit: (Result) => {
                    if (Result.Network.length <= 0) return;

                    LoaderModal.set(true);
                    SendEvent("Network/Connect", Result, (Success, Data) => {
                        LoaderModal.set(false);
                        if (!Success) return;
                        if (Data) ShowSuccessModal();
                    });
                },
            });
        })
    };

    const Selfie = () => {
        SendEvent("Phone/Selfie");
    };

    OnEvent("SetPhoneBrand", (Data) => {
        Brand.set(Data.Brand);
    });

    let DefaultBackground = $PhoneBackground;
    OnEvent("SetPhoneBackground", (Data) => {
        DefaultBackground = Data.Background;
        if (!$Settings.Background) PhoneBackground.set(Data.Background);
    });

    OnEvent("SetEmbedsEnabled", (Data) => {
        EmbedsEnabled.set(Data.Enabled)
    });

    OnEvent("ClosePhone", (Data) => {
        CurrentApp = "home";
        PhoneVisible = false;
        InputModal.set({Visible: false});
        ImageHoverData.set({Show: false});
        SetDropdown(false);
    });

    OnEvent("OpenPhone", (Data) => {
        PhoneVisible = true;
        IsBurnerCurrent = Data.IsBurner;

        CurrentWeather = Data.Weather;
        CurrentLocation = Data.Location || CurrentLocation;
        Settings.set(Data.Settings || {});
        PhoneBackground.set($Settings.Background || DefaultBackground);
        HasVpn.set(Data.HasVPN);
        HasRacingUsb.set(Data.HasRacingUsb);
        HasPDRacingUsb.set(Data.HasPDRacingUsb);
        RacingAlias.set(Data.RacingAlias);
        CurrentTime = Data.Time;

        IsNearNetwork = Data.IsNearNetwork;
        IsNetworkEnabled = Data.IsNetworkEnabled;

        PlayerData.set(Data.PlayerData);
    });

    OnEvent("UpdatePlayerData", (Data) => {
        PlayerData.set(Data.PlayerData);
    });

    OnEvent("Notification", AddNotification);
    OnEvent("UpdateNotification", UpdateNotification);
    OnEvent("RemoveNotification", RemoveNotification);

    OnEvent("SetAppUnread", (Data) => {
        UnreadApps[Data.App] = true;
    });

    OnEvent("SetCurrentNetwork", (Data) => {
        CurrentNetwork = Data.Network;
    });

    OnEvent("SetJobManager", (Data) => {
        JobManager.set(Data.JobManager);
    });

    OnEvent("Documents/SetDocument", (Data) => {
        CurrentDocument.set(Data.Document);
        DocumentIsDrop.set(Data.IsDrop);
        CurrentApp = "documents";
    });

    $: Shop = CarShops[CurrentNetwork];
    $: State = { HasVpn: $HasVpn, HasRacingUsb: $HasRacingUsb, HasPDRacingUsb: $HasPDRacingUsb, Network: CurrentNetwork };
    $: Apps = [
        ...HomeApps.filter(A => !A.Show || A.Show(State)),
        ...(Shop ? [{ Id: "cars", Label: "Dealership", Tooltip: Shop[0], Icon: Shop[1], Tile: "red" }] : []),
    ];

    $: Clock = `${CurrentTime[0] % 12 || 12}:${String(CurrentTime[1]).padStart(2, "0")}`;
    $: Meridiem = CurrentTime[0] < 12 ? "AM" : "PM";

    const GoBack = () => $InputModal.Visible ? InputModal.set({ Visible: false }) : GoHome();
    const Select = () => [...document.querySelectorAll(":hover")].pop()?.click();
    const Keys = { y: GoHome, u: ToggleSound, Enter: Select, Backspace: GoBack };

    const OnKeyDown = (e) => {
        const El = document.activeElement;
        if (!PhoneVisible || El?.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(El?.tagName)) return;
        const Fn = Keys[e.key.length == 1 ? e.key.toLowerCase() : e.key];
        if (!Fn) return;
        e.preventDefault();
        Fn();
    };

    SetExitHandler("ClosePhone", "ClosePhone", () => {
        return PhoneVisible
    });
</script>

<svelte:window on:keydown={OnKeyDown} />

<div class="phone-wrapper">
    {#if PhoneVisible}
        <div transition:fade={{ duration: 250 }} class="phone-hints" style={IsBurnerCurrent ? "right: 58vh" : ""}>
            {#each Hotkeys as [Key, Label]}
                <div><kbd class:wide={Key.length > 1}>{Key}</kbd><span>{Label}</span></div>
            {/each}
        </div>
    {/if}

    {#each [false, true] as Burner}
        <Container
            isBurner={Burner}
            class={Burner
                ? `phone-container ${PhoneVisible && IsBurnerCurrent ? "phone-visible" : "phone-hidden"}`
                : `phone-container ${IsEnvBrowser() ? "phone-debug" : ""} ${PhoneVisible && !IsBurnerCurrent ? "phone-visible" : $Notifications.length > 0 ? "phone-half" : "phone-hidden"}`}
            style={Burner ? "right: 28vh !important;" : ""}
            backgroundOverride={Burner && "linear-gradient(160deg, #3a4a63 0%, #141a24 100%)"}
        >
            {#if !Burner || (PhoneVisible && IsBurnerCurrent)}
                {#if $LoaderModal}<Loader />{/if}
                {#if $SuccessModal}<Success />{/if}
                {#if $InputModal.Visible}<Input />{/if}

                {#if CurrentApp == "home"}
                    <div in:fade={{ duration: 250 }} class="phone-home">
                        <div class="phone-clock">{Clock} {Meridiem}</div>
                        <div class="phone-zone">
                            <i class="fas fa-{WheaterIcons[CurrentWeather]}" />
                            {CurrentLocation}
                        </div>

                        <div class="phone-grid">
                            {#each Burner ? BurnerApps : Apps as App (App.Id)}
                                <Application {...App} HasUnread={UnreadApps[App.Id]} on:click={() => SetCurrentApp(App.Id)} />
                            {/each}
                        </div>

                        {#if !Burner}
                            <div class="phone-dock">
                                {#each DockApps as App (App.Id)}
                                    <div class="phone-dock-app" data-tooltip={App.Label} on:keyup on:click={() => SetCurrentApp(App.Id)}>
                                        <Icon Name={App.Icon} />
                                        {#if UnreadApps[App.Id]}<span class="phone-dock-badge" />{/if}
                                    </div>
                                {/each}
                                <div class="phone-dock-app" data-tooltip="Selfie!" on:keyup on:click={Selfie}><Icon Name="camera" /></div>
                            </div>
                        {/if}
                    </div>
                {:else}
                    <AppProvider App={CurrentApp} />
                {/if}

                <div class="phone-statusbar">
                    <span>{Clock} {Meridiem}</span>
                    <div class="phone-statusbar-icons">
                        <span on:keyup on:click={ToggleSound} class:dim={SoundsMuted} data-tooltip="Notifications On/Off"><Icon Name="bell" /></span>
                        {#if $HasVpn}<i class="fas fa-lock" />{/if}
                        <svg viewBox="0 0 24 24" class:dim={!IsNetworkEnabled}><rect x="2" y="15" width="3" height="6" rx="1"/><rect x="8" y="11" width="3" height="10" rx="1"/><rect x="14" y="7" width="3" height="14" rx="1"/><rect x="20" y="3" width="3" height="18" rx="1"/></svg>
                        {#if IsNetworkEnabled && IsNearNetwork}
                            <svg viewBox="0 0 24 24" on:keyup on:click={ConnectNetwork} class:dim={!CurrentNetwork} class="click"><path d="M2 9a15 15 0 0 1 20 0M5 12.5a10.5 10.5 0 0 1 14 0M8.5 16a5.5 5.5 0 0 1 7 0" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><circle cx="12" cy="19.5" r="1.6"/></svg>
                        {/if}
                        <svg viewBox="0 0 28 24"><rect x="1" y="6" width="22" height="12" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><rect x="3.5" y="8.5" width="14" height="7" rx="1.5"/><rect x="24" y="10" width="3" height="4" rx="1"/></svg>
                    </div>
                </div>

                <div on:keyup on:click={GoHome} class="phone-homebar"><i /></div>
            {/if}
        </Container>
    {/each}
</div>

<style>
    /* Codera palette, shared by every app through these variables */
    .phone-wrapper {
        --phone-bg: #16181c;
        --phone-surface: #1f2227;
        --phone-card: #1f2227;
        --phone-card-hover: #292d34;
        --phone-line: rgba(255, 255, 255, 0.08);
        --phone-muted: #9aa0aa;
        --phone-accent: #4f8cff;
        --phone-green: #2ecc71;
        --phone-red: #ff4d4f;
        --phone-orange: #f5b73b;
        --phone-radius: 1.1vh;

        position: absolute;
        inset: 0;
        font-family: Inter, Roboto, sans-serif;
        font-size: 1vh;
        color: #f3f4f6;
        user-select: none;
    }

    /* Keybind hints, left of the phone */
    .phone-hints {
        position: absolute;
        right: 30vh;
        bottom: 3vh;
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 0.93vh;
    }

    .phone-hints > div {
        display: flex;
        align-items: center;
        gap: 0.74vh;
        padding: 0.37vh 1vh 0.37vh 0.37vh;
        border-radius: 0.46vh;
        background: white;
        box-shadow: 0 0.19vh 0.74vh rgba(0, 0, 0, 0.35);
        font-family: "Barlow Condensed", Inter, sans-serif;
        font-size: 1.39vh;
        font-weight: 800;
        font-style: italic;
        letter-spacing: 0.04vh;
        text-transform: uppercase;
        line-height: 1;
        color: #0b0b0c;
    }

    .phone-hints kbd {
        display: grid;
        place-items: center;
        min-width: 2.2vh;
        height: 2.04vh;
        padding: 0 0.56vh;
        border-radius: 0.37vh;
        background: #0b0b0c;
        color: white;
        font-family: Inter, sans-serif;
        font-size: 1.06vh;
        font-weight: 800;
        font-style: normal;
    }

    .phone-hints kbd.wide { min-width: 3.3vh; }

    /* Home screen */
    .phone-home {
        position: absolute;
        inset: 0;
        padding: 5.2vh 1.5vh 0;
        z-index: 5;
    }

    .phone-clock {
        font-family: "Barlow Condensed", "Arial Narrow", sans-serif;
        font-style: italic;
        font-weight: 800;
        font-size: 5.2vh;
        line-height: 1;
        text-align: center;
        letter-spacing: 0.08vh;
        text-shadow: 0 0.17vh 1.18vh rgba(0, 0, 0, 0.5);
    }

    .phone-zone {
        display: flex;
        align-items: center;
        gap: 0.6vh;
        width: max-content;
        margin: 0.67vh auto 2.2vh;
        padding: 0.25vh 1.18vh;
        border-radius: 0.5vh;
        background: #0a0a0b;
        transform: skewX(-6deg);
        font-family: "Barlow Condensed", sans-serif;
        font-style: italic;
        font-weight: 800;
        font-size: 1.43vh;
        letter-spacing: 0.13vh;
        text-transform: uppercase;
    }

    .phone-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        grid-auto-rows: min-content;
        gap: 1.52vh 0.34vh;
        max-height: 38vh;
        overflow-y: auto;
    }

    .phone-grid::-webkit-scrollbar { display: none; }

    .phone-dock {
        position: absolute;
        left: 50%;
        bottom: 2.53vh;
        transform: translateX(-50%);
        width: 20.4vh;
        height: 4.2vh;
        display: flex;
        justify-content: space-around;
        align-items: center;
        border-radius: 1.85vh;
        background: rgba(14, 15, 18, 0.84);
        backdrop-filter: blur(1.5vh);
        border: 0.08vh solid rgba(255, 255, 255, 0.06);
    }

    .phone-dock-app {
        position: relative;
        display: grid;
        place-items: center;
        width: 3.37vh;
        height: 3.37vh;
        border-radius: 1vh;
        color: white;
        cursor: pointer;
    }

    .phone-dock-app:hover { background: rgba(255, 255, 255, 0.1); }
    .phone-dock-app > :global(.ic) { width: 1.69vh; height: 1.69vh; }

    .phone-dock-badge {
        position: absolute;
        top: 0.3vh;
        right: 0.3vh;
        width: 0.9vh;
        height: 0.9vh;
        border-radius: 50%;
        background: #ff4d4f;
        border: 0.13vh solid rgba(14, 15, 18, 0.9);
    }

    /* Status bar */
    .phone-statusbar {
        position: absolute;
        top: 0.34vh;
        left: 0;
        right: 0;
        height: 2.2vh;
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 2.2vh;
        font-size: 1.01vh;
        font-weight: 600;
        z-index: 250;
        pointer-events: none;
    }

    .phone-statusbar-icons {
        display: flex;
        align-items: center;
        gap: 0.5vh;
        pointer-events: all;
    }

    .phone-statusbar-icons svg, .phone-statusbar-icons :global(.ic) { width: 1.26vh; height: 1.26vh; fill: currentColor; }
    .phone-statusbar-icons :global(.ic) { fill: none; }
    .phone-statusbar-icons > span, .click { cursor: pointer; display: flex; }
    .dim { opacity: 0.45; }

    /* Home indicator */
    .phone-homebar {
        position: absolute;
        bottom: 0;
        left: 50%;
        transform: translateX(-50%);
        width: 14.3vh;
        height: 2.53vh;
        display: grid;
        place-items: center;
        z-index: 250;
        cursor: pointer;
    }

    .phone-homebar > i {
        width: 9.95vh;
        height: 0.42vh;
        border-radius: 0.25vh;
        background: white;
        opacity: 0.85;
    }
</style>
