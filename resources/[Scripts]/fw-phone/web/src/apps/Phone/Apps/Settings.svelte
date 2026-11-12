<script>
    import { CopyToClipboard, FormatPhone, SendEvent, WallpaperCss } from "../../../utils/Utils";
    import { PhoneBackground, PlayerData, Settings } from "../phone.stores";

    import AppWrapper from "../components/AppWrapper.svelte";
    import AppHeader from "../components/AppHeader.svelte";
    import Checkbox from "../../../components/Checkbox/Checkbox.svelte";
    import TextField from "../../../components/TextField/TextField.svelte";

    const Wallpapers = [
        "https://i.imgur.com/3KTfLIV.jpg",
        "linear-gradient(160deg, #ff7e5f, #6a3093)",
        "linear-gradient(160deg, #1f4037, #0b1a14)",
        "linear-gradient(160deg, #2b5876, #0f1c2e)",
        "linear-gradient(160deg, #3a1c71, #d76d77 60%, #ffaf7b)",
        "linear-gradient(160deg, #232526, #0a0a0a)",
    ];

    let CustomUrl = "";
    let Copied = "";

    const Save = (Key, Value) => {
        Settings.update(S => ({ ...S, [Key]: Value }));
        SendEvent("Settings/Set", { Key, Value });
    };

    const SetWallpaper = (Bg) => {
        if (!Bg) return;
        PhoneBackground.set(Bg);
        Save("Background", Bg);
    };

    const Copy = (Label, Text) => {
        CopyToClipboard(Text);
        Copied = Label;
        setTimeout(() => (Copied = ""), 1500);
    };

    // Switch on = notifications allowed. Persist only when the value changes.
    let Messages = !$Settings.MuteMessages, Twatter = !$Settings.MuteTwatter;
    $: if (Messages == !!$Settings.MuteMessages) Save("MuteMessages", !Messages);
    $: if (Twatter == !!$Settings.MuteTwatter) Save("MuteTwatter", !Twatter);

    $: Initials = ($PlayerData.Name || "?").split(" ").map(W => W[0]).join("").slice(0, 2);
</script>

<AppWrapper>
    <AppHeader Title="Settings" />

    <div class="settings">
        <div class="group profile">
            <div class="avatar">{Initials}</div>
            <div>
                <p class="name">{$PlayerData.Name || "Unknown"}</p>
                <p class="muted">{FormatPhone($PlayerData.PhoneNumber || "")}</p>
            </div>
        </div>

        <p class="label">About</p>
        <div class="group">
            <div class="row" data-tooltip="Click to copy" on:keyup on:click={() => Copy("cid", $PlayerData.Cid)}>
                <span><i class="fas fa-id-card" /> CID</span>
                <span class="muted">{Copied == "cid" ? "Copied!" : $PlayerData.Cid}</span>
            </div>
            <div class="row">
                <span><i class="fas fa-server" /> Server ID</span>
                <span class="muted">{$PlayerData.Id}</span>
            </div>
            <div class="row" data-tooltip="Click to copy" on:keyup on:click={() => Copy("phone", $PlayerData.PhoneNumber)}>
                <span><i class="fas fa-phone-alt" /> Phone Number</span>
                <span class="muted">{Copied == "phone" ? "Copied!" : FormatPhone($PlayerData.PhoneNumber || "")}</span>
            </div>
        </div>

        <p class="label">Notifications</p>
        <div class="group">
            <div class="row"><Checkbox Title="Messages" bind:Checked={Messages} /></div>
            <div class="row"><Checkbox Title="Twatter" bind:Checked={Twatter} /></div>
        </div>

        <p class="label">Wallpaper</p>
        <div class="group">
            <div class="wallpapers">
                {#each Wallpapers as Bg}
                    <div
                        class="wallpaper"
                        class:active={$PhoneBackground == Bg}
                        style="background: {WallpaperCss(Bg)} center / cover"
                        on:keyup
                        on:click={() => SetWallpaper(Bg)}
                    />
                {/each}
            </div>
            <TextField Title="Custom image URL" Icon="link" Placeholder="https://..." bind:Value={CustomUrl} OnSubmit={SetWallpaper} />
        </div>
        <p class="hint">Paste an image link and press Enter.</p>
    </div>
</AppWrapper>

<style>
    .settings {
        height: calc(100% - 10vh);
        padding: 0 5% 3vh;
        overflow-y: auto;
    }

    .settings::-webkit-scrollbar { display: none; }

    .group {
        padding: 0.4vh 1.2vh;
        border-radius: var(--phone-radius);
        background: var(--phone-card);
    }

    .profile {
        display: flex;
        align-items: center;
        gap: 1.2vh;
        padding: 1.2vh;
    }

    .avatar {
        display: grid;
        place-items: center;
        width: 4.6vh;
        height: 4.6vh;
        border-radius: 50%;
        background: linear-gradient(160deg, #8e9bb0, #59637a);
        font-size: 1.8vh;
        font-weight: 600;
    }

    .name { font-size: 1.6vh; font-weight: 600; }

    p { margin: 0; }
    .muted { color: var(--phone-muted); }

    .label {
        margin: 1.8vh 0 0.6vh 1vh;
        font-size: 1.1vh;
        text-transform: uppercase;
        letter-spacing: 0.05vh;
        color: var(--phone-muted);
    }

    .hint { margin: 0.6vh 1vh 0; font-size: 1.05vh; color: var(--phone-muted); }

    .row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        min-height: 3.6vh;
        font-size: 1.35vh;
        border-bottom: 0.1vh solid var(--phone-line);
        cursor: pointer;
    }

    .row:last-child { border-bottom: none; }
    .row i { width: 2vh; margin-right: 0.6vh; color: var(--phone-accent); }
    .row :global(.ui-switch) { margin: 0; }

    .wallpapers {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 0.8vh;
        padding: 0.8vh 0 1.2vh;
    }

    .wallpaper {
        aspect-ratio: 9 / 16;
        border-radius: 0.8vh;
        border: 0.2vh solid transparent;
        cursor: pointer;
    }

    .wallpaper.active { border-color: var(--phone-accent); }
</style>
