<script>
    import { fade } from "svelte/transition";

    import { WheaterIcons } from "../../config";
    import { AddNotification, IsEnvBrowser, Notifications, OnEvent, RemoveNotification, SendEvent, SetDropdown, SetExitHandler, ShowSuccessModal, UpdateNotification } from "../../utils/Utils"
    import AppProvider from "./AppProvider.svelte";
    import Application from "./components/Application.svelte";
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
        ...(Shop ? [{ Id: "cars", Label: "Dealership", Tooltip: Shop[0], Icon: Shop[1], Color: ["#ff5252", "#b71c1c"] }] : []),
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
        <div transition:fade={{ duration: 250 }} class="phone-hotkeys" style={IsBurnerCurrent ? "right: 58vh" : ""}>
            {#each Hotkeys as [Key, Label]}
                <div class="phone-hotkey"><span>{Key}</span><p>{Label}</p></div>
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
                        <div class="phone-clock">{Clock} <span>{Meridiem}</span></div>
                        <div class="phone-location">
                            <i class="fas fa-{WheaterIcons[CurrentWeather]}" />
                            {CurrentLocation}
                        </div>

                        <div class="phone-applications">
                            {#each Burner ? BurnerApps : Apps as App (App.Id)}
                                <Application {...App} HasUnread={UnreadApps[App.Id]} on:click={() => SetCurrentApp(App.Id)} />
                            {/each}
                        </div>

                        {#if !Burner}
                            <div class="phone-dock">
                                {#each DockApps as App (App.Id)}
                                    <div class="phone-dock-app" data-tooltip={App.Label} on:keyup on:click={() => SetCurrentApp(App.Id)}>
                                        <i class="fas fa-{App.Icon}" />
                                        {#if UnreadApps[App.Id]}<div class="phone-dock-unread" />{/if}
                                    </div>
                                {/each}
                                <div class="phone-dock-app" data-tooltip="Selfie!" on:keyup on:click={Selfie}><i class="fas fa-camera" /></div>
                            </div>
                        {/if}
                    </div>
                {:else}
                    <AppProvider App={CurrentApp} />
                {/if}

                <div class="phone-statusbar">
                    <div class="phone-statusbar-time">{Clock} {Meridiem}</div>
                    <div class="phone-statusbar-icons">
                        <i on:keyup on:click={ToggleSound} data-tooltip="Notifications On/Off" class="fas fa-bell{SoundsMuted ? "-slash" : ""}" />
                        {#if $HasVpn}<i class="fas fa-lock" />{/if}
                        {#if IsNetworkEnabled}
                            <i
                                on:keyup
                                on:click={ConnectNetwork}
                                class:dim={IsNearNetwork && !CurrentNetwork}
                                class="fas fa-{IsNearNetwork ? "wifi" : "signal"}"
                            />
                        {:else}
                            <i class="fas fa-signal-slash dim" />
                        {/if}
                        <i class="fas fa-battery-full" />
                    </div>
                </div>

                <div on:keyup on:click={GoHome} class="phone-home-indicator"><div /></div>
            {/if}
        </Container>
    {/each}
</div>

<style>
    .phone-wrapper {
        --phone-bg: #0e0f12;
        --phone-surface: rgba(30, 31, 36, 0.97);
        --phone-card: rgba(255, 255, 255, 0.07);
        --phone-card-hover: rgba(255, 255, 255, 0.12);
        --phone-line: rgba(255, 255, 255, 0.09);
        --phone-muted: rgba(235, 235, 245, 0.6);
        --phone-accent: #0a84ff;
        --phone-green: #34c759;
        --phone-red: #ff3b30;
        --phone-orange: #ff9f0a;
        --phone-radius: 1.2vh;

        position: absolute;
        inset: 0;
        font-family: Roboto;
        font-size: 1vh;
        color: white;
        user-select: none;
    }

    /* Keybind hints, left of the phone */
    .phone-hotkeys {
        position: absolute;
        right: 30vh;
        bottom: 4vh;
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 0.6vh;
    }

    .phone-hotkey {
        display: flex;
        gap: 0.3vh;
        font-family: "Barlow Condensed", Roboto;
        font-weight: 700;
        font-size: 1.25vh;
        letter-spacing: 0.08vh;
        text-transform: uppercase;
        color: #111;
    }

    .phone-hotkey > span,
    .phone-hotkey > p {
        margin: 0;
        padding: 0.45vh 0.7vh;
        border-radius: 0.25vh;
        box-shadow: 0 0.2vh 0.5vh rgba(0, 0, 0, 0.4);
    }

    .phone-hotkey > span { min-width: 1.2vh; text-align: center; background: white; }
    .phone-hotkey > p { min-width: 8vh; background: rgba(235, 235, 235, 0.92); }

    /* Home screen */
    .phone-home {
        position: absolute;
        inset: 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding-top: 3.6vh;
    }

    .phone-clock {
        font-family: "Barlow Condensed", Roboto;
        font-style: italic;
        font-weight: 800;
        font-size: 4.6vh;
        line-height: 1;
        text-shadow: 0 0.3vh 1vh rgba(0, 0, 0, 0.6);
    }

    .phone-clock > span { font-size: 3.4vh; }

    .phone-location {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.7vh;
        width: 82%;
        margin-top: 0.8vh;
        padding: 0.55vh 0;
        background: rgba(0, 0, 0, 0.55);
        font-family: "Barlow Condensed", Roboto;
        font-style: italic;
        font-weight: 700;
        font-size: 1.35vh;
        letter-spacing: 0.15vh;
        text-transform: uppercase;
    }

    .phone-applications {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        grid-auto-rows: min-content;
        row-gap: 1.5vh;
        width: 90%;
        flex: 1;
        margin: 2.2vh 0 1vh;
        overflow-y: auto;
    }

    .phone-applications::-webkit-scrollbar { display: none; }

    .phone-dock {
        display: flex;
        justify-content: space-around;
        width: 86%;
        margin-bottom: 2.6vh;
        padding: 0.9vh 0.6vh;
        border-radius: 2.2vh;
        background: rgba(30, 30, 34, 0.55);
        backdrop-filter: blur(1vh);
    }

    .phone-dock-app {
        position: relative;
        font-size: 1.7vh;
        padding: 0.4vh 0.7vh;
        cursor: pointer;
        opacity: 0.9;
    }

    .phone-dock-app:hover { opacity: 1; }

    .phone-dock-unread {
        position: absolute;
        top: 0;
        right: 0.2vh;
        width: 0.8vh;
        height: 0.8vh;
        border-radius: 50%;
        background: #ff3b30;
    }

    /* Status bar */
    .phone-statusbar {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 2.6vh;
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 2.2vh 0 2.6vh;
        font-size: 1.15vh;
        font-weight: 600;
        z-index: 250;
        pointer-events: none;
    }

    .phone-statusbar-icons {
        display: flex;
        align-items: center;
        gap: 0.6vh;
        pointer-events: all;
    }

    .phone-statusbar-icons > i { cursor: pointer; }
    .phone-statusbar-icons > .dim { opacity: 0.5; }

    /* Home indicator */
    .phone-home-indicator {
        position: absolute;
        bottom: 0;
        left: 50%;
        transform: translateX(-50%);
        padding: 0.9vh 3vh 0.7vh;
        cursor: pointer;
        z-index: 250;
    }

    .phone-home-indicator > div {
        width: 9vh;
        height: 0.45vh;
        border-radius: 0.3vh;
        background: white;
        opacity: 0.85;
    }
</style>
