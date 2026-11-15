<script>
    import AppWrapper from "../../components/AppWrapper.svelte";
    import Button from "../../lib/Button/Button.svelte";
    import TextField from "../../lib/TextField/TextField.svelte";
    import { OnEvent, SendEvent as _SendEvent } from "../../utils/Utils";
    const SendEvent = (Event, Parameters, Callback) => _SendEvent(Event, Parameters, Callback, "fw-characters");

    let Visible = false;
    let MaxCharsOverride = false;
    let Characters = [];
    let ExtraCharacters = [];

    OnEvent("Characters", "LoadCharacters", (Data) => {
        Characters = Data.Characters;
        ExtraCharacters = [];
        MaxCharsOverride = Data.AllowOverride;

        if (Characters.length > 6) {
            for (let i = 6; i < Characters.length; i++) {
                ExtraCharacters.push({
                    Text: `#${Characters[i].Cid} - ${Characters[i].Name}`,
                    Value: i,
                });
            };
        };
    });

    OnEvent("Characters", "SetVisibility", (Data) => {
        Visible = Data.Visible;
        if (!Visible) { Screen = "splash"; MenuIndex = 0; ShowOptions = false; }
    });

    // Title screen + main menu
    const Version = "1.0.0";
    let Screen = "splash"; // splash | menu | characters
    let MenuIndex = 0;
    let ShowOptions = false;

    $: LastChar = Characters.reduce((Last, Char) => !Last || (Char.LastPlayed || 0) > (Last.LastPlayed || 0) ? Char : Last, null);
    $: Panels = [
        { Label: LastChar ? `Continue as ${LastChar.Name}` : "Create Character", Caption: "Pick up where you left off", Image: "continue" },
        { Label: "Characters", Caption: "Select or create a character", Image: "characters" },
        { Label: "Options", Caption: "Adjust your experience", Image: "options" },
    ];

    const SetView = (View) => {
        Screen = View;
        SendEvent("Characters/SetView", { View: View == "characters" ? "peds" : "menu" });
    };

    const SelectMenu = (Index) => {
        MenuIndex = Index;
        if (Index == 0) {
            if (!LastChar) { SetView("characters"); return OpenCreateForm(); }
            CurrentCharacter.Cid = LastChar.Cid;
            return PlayCharacter();
        }
        if (Index == 1) return SetView("characters");
        ShowOptions = true;
    };

    const OnKey = (e) => {
        if (!Visible) return;
        if (Screen == "splash") {
            if (e.key == "Enter") Screen = "menu";
        } else if (Screen == "menu") {
            if (ShowOptions) { if (e.key == "Escape") ShowOptions = false; return; }
            if (e.key == "ArrowLeft") MenuIndex = (MenuIndex + 2) % 3;
            else if (e.key == "ArrowRight") MenuIndex = (MenuIndex + 1) % 3;
            else if (e.key == "Enter") SelectMenu(MenuIndex);
            else if (e.key == "Escape") Screen = "splash";
        } else if (e.key == "Escape" && !CurrentCharacter.Delete && !CreateCharacterForm.IsCreating) {
            CurrentCharacter.Selected = false;
            SetView("menu");
        }
    };

    let CreateCharacterForm = {
        IsCreating: false,
        Processing: false,
        Firstname: '',
        Lastname: '',
        Birthdate: '',
        Gender: 'Man',
        Type: "Normal"
    };

    let CurrentCharacter = {
        Delete: false,
        Selected: false,
        Cid: '0000',
        Name: 'Druk om te Selecteren, of maak een nieuw karakter.'
    };

    const SetCurrent = (SlotId) => {
        let CharacterData = Characters[SlotId - 1];
        if (!CharacterData) return;

        CurrentCharacter.Selected = SlotId;
        CurrentCharacter.Cid = CharacterData.Cid;
        CurrentCharacter.Name = CharacterData.Name;
    };

    const SetCurrentHover = (SlotId) => {
        if (CurrentCharacter.Selected) return;

        let CharacterData = Characters[SlotId - 1];
        if (!SlotId || !CharacterData) {
            return CurrentCharacter.Name = 'Druk om te Selecteren, of maak een nieuw karakter.'
        };

        CurrentCharacter.Cid = CharacterData.Cid;
        CurrentCharacter.Name = CharacterData.Name;
    };

    const OpenCreateForm = () => { CreateCharacterForm.IsCreating = true; }
    const CloseCreateForm = () => { CreateCharacterForm.IsCreating = false; }
    const ProcessNewCharacter = () => {
        CreateCharacterForm.Processing = true;

        setTimeout(() => {
            if (Characters.length >= 6 && !MaxCharsOverride) {
                CreateCharacterForm.Processing = false;
                CreateCharacterForm.Text = 'Limit aan karakters bereikt.';
                setTimeout(() => { CreateCharacterForm.Text = false }, 5000);
                return;
            };

            const Firstname = CreateCharacterForm.Firstname.trim();
            const Lastname = CreateCharacterForm.Lastname.trim();
            const Birthdate = CreateCharacterForm.Birthdate.trim();
            const Gender = CreateCharacterForm.Gender.trim();

            if (!Firstname || !Lastname || !Birthdate || !Gender) {
                CreateCharacterForm.Processing = false;
                CreateCharacterForm.Text = 'Vul alle velden in.';
                setTimeout(() => { CreateCharacterForm.Text = false }, 5000);
                return;
            };

            const BirthYear = new Date(Birthdate).getFullYear();
            const MaxBirthyear = new Date().getFullYear() - 17;
            if (BirthYear < (MaxBirthyear - 101) || BirthYear >= MaxBirthyear) {
                CreateCharacterForm.Processing = false;
                CreateCharacterForm.Text = `Geboortedatum moet tussen ${MaxBirthyear - 101} en ${MaxBirthyear} zitten.`;
                setTimeout(() => { CreateCharacterForm.Text = false }, 5000);
                return;
            };

            if (Gender !== 'Man' && Gender !== 'Vrouw') {
                CreateCharacterForm.Processing = false;
                CreateCharacterForm.Text = 'Ongeldig geslacht.';
                setTimeout(() => { CreateCharacterForm.Text = false }, 5000);
                return;
            };

            SendEvent("Characters/CreateCharacter", CreateCharacterForm);
            CreateCharacterForm.IsCreating = false;
            CreateCharacterForm.Processing = false;
            Visible = false;
        }, 1000);
    };

    const PlayCharacter = (SlotId) => {
        if (SlotId && !Characters[SlotId-1]) return;

        Visible = false;
        SendEvent("Characters/PlayCharacter", {Cid: CurrentCharacter.Cid});
        CurrentCharacter = {
            Delete: false,
            Selected: false,
            Cid: '0000',
            Name: 'Druk om te Selecteren, of maak een nieuw karakter.'
        };
    };

    const OpenDeleteForm = () => { CurrentCharacter.Delete = true; };
    const CloseDeleteForm = () => { CurrentCharacter.Delete = false; };
    const ProcessCharacterDelete = () => {
        Visible = false;
        SendEvent("Characters/DeleteCharacter", {Cid: CurrentCharacter.Cid}, (Success, Data) => {
            CurrentCharacter = {
                Delete: false,
                Selected: false,
                Cid: '0000',
                Name: 'Druk om te Selecteren, of maak een nieuw karakter.'
            };
        });
    };
</script>

<svelte:window on:keydown={OnKey} />

<AppWrapper
    AppName="Characters"
    Focused={Visible}
>
    {#if Visible && Screen == "splash"}
        <div class="title-screen">
            <div class="title-logo"><span class="pixel">costa</span><span class="rp">RP</span></div>
            <p class="title-beta">CLOSED BETA</p>
            <div class="title-start" on:keyup on:click={() => Screen = "menu"}>PRESS <span class="key dark">⏎</span> TO START</div>
            <span class="version">{Version}</span>
        </div>
    {:else if Visible && Screen == "menu"}
        <div class="menu-screen">
            <div class="menu-panels">
                {#each Panels as Panel, i}
                    <div class="menu-panel-glow" class:active={MenuIndex == i}>
                        <div
                            class="menu-panel panel-{i}"
                            style="background-image: url('./images/characters/{Panel.Image}.jpg')"
                            on:keyup on:mouseenter={() => MenuIndex = i} on:click={() => SelectMenu(i)}
                        >
                            {#if MenuIndex == i}<p class="menu-caption">{Panel.Caption}</p>{/if}
                        </div>
                    </div>
                {/each}
            </div>

            <div class="menu-buttons">
                {#each Panels as Panel, i}
                    <div class="menu-button" class:active={MenuIndex == i} on:keyup on:mouseenter={() => MenuIndex = i} on:click={() => SelectMenu(i)}>{Panel.Label}</div>
                {/each}
            </div>

            {#if ShowOptions}
                <div class="menu-options">
                    <p>OPTIONS</p>
                    <div class="menu-button" on:keyup on:click={() => SendEvent("Characters/Disconnect")}>Disconnect</div>
                    <div class="menu-button active" on:keyup on:click={() => ShowOptions = false}>Back</div>
                </div>
            {/if}

            <div class="menu-hints">
                <span class="key">◂▸</span>MOVE <i>/</i> <span class="key">⏎</span>SELECT <i>/</i> <span class="key">ESC</span>EXIT
            </div>
            <span class="version">{Version}</span>
        </div>
    {:else if Visible}
        {#if Characters.length > 6}
            <div class="characters-extra">
                <TextField
                    style="margin: 0;"
                    Title="Selecteer een karakter.."
                    Select={ExtraCharacters}
                    SubSet={(_, Value) => {
                        console.log(Value)
                        SetCurrent(Value + 1);
                    }}
                />
            </div>
        {/if}

        <div class="characters-wrapper">
            {#if !CurrentCharacter.Delete && !CreateCharacterForm.IsCreating}
                <div class="character-current">
                    <p>{CurrentCharacter.Name}</p>
                    <hr />
                    <div>
                        {#if CurrentCharacter.Selected}
                            <Button Color="success" on:click={() => PlayCharacter()}>Spelen</Button>
                            <Button Color="warning" on:click={OpenDeleteForm}>Verwijderen</Button>
                        {:else}
                            <Button Color="success" on:click={OpenCreateForm}>Nieuw Karakter Aanmaken</Button>
                        {/if}
                    </div>
                </div>
            {/if}

            {#if CurrentCharacter.Selected && CurrentCharacter.Delete}
                <div class="character-delete">
                    <p style="padding-bottom: 0;">Karakter Verwijderen #{CurrentCharacter.Cid}</p>
                    <p style="padding-bottom: 0; font-size: 1.7vh;">Weet je zeker dat je {CurrentCharacter.Name} wilt verwijderen?</p>
                    <p style="font-size: 1.7vh;">Het verwijderen van een karakter kan <strong>NIET</strong> ongedaan worden.</p>
                    <hr />
                    <div>
                        <Button Color="error" on:click={ProcessCharacterDelete}>Verwijderen</Button>
                        <Button Color="success" on:click={CloseDeleteForm}>Terug</Button>
                    </div>
                </div>
            {/if}

            {#if CreateCharacterForm.IsCreating}
                <div class="character-create">
                    <p style="padding-bottom: 3vh;">Karakter Aanmaken</p>

                    {#if CreateCharacterForm.Processing}
                        <hr/>
                        <p style="font-size: 2vh; padding-bottom: 0;">Data controleren...</p>
                        <p style="font-size: 3vh; padding-bottom: 3vh;"><i class="fas fa-spinner fa-pulse"></i></p>
                    {:else if CreateCharacterForm.Text}
                        <hr/>
                        <p style="font-size: 2vh; padding-bottom: 3vh;">{CreateCharacterForm.Text}</p>
                    {:else}
                        <div class="creation-gender">
                            <img
                                alt=""
                                src="./images/characters/male.png"
                                class:highlight={CreateCharacterForm.Gender == 'Man'}
                                on:keyup on:click={() => CreateCharacterForm.Gender = 'Man'}
                            />
                            <img
                                alt=""
                                src="./images/characters/female.png"
                                class:highlight={CreateCharacterForm.Gender == 'Vrouw'}
                                on:keyup on:click={() => CreateCharacterForm.Gender = 'Vrouw'}
                            />
                        </div>

                        <TextField bind:Value={CreateCharacterForm.Firstname} style="width: 90%" Title='Voornaam' Placeholder='Bob'/>
                        <TextField bind:Value={CreateCharacterForm.Lastname} style="width: 90%" Title='Achternaam' Placeholder='de Bouwer'/>
                        <TextField bind:Value={CreateCharacterForm.Birthdate} style="width: 90%" Title='Geboortedatum' Type="date"  />

                        <p style="padding-bottom: 2vh; font-size: 1.5vh;">Karakter Type</p>

                        <div style="display: flex; justify-content: space-between; width: 32%;">
                            <Button
                                style="border-radius: 1.5vh; background-color: transparent; box-shadow: none; color: rgba(255, 255, 255, { CreateCharacterForm.Type == "Normal" ? 1.0 : 0.5})"
                                on:click={() => CreateCharacterForm.Type = "Normal"}
                            >Normaal</Button>
                            <Button
                                style="border-radius: 1.5vh; background-color: transparent; box-shadow: none; color: rgba(255, 255, 255, { CreateCharacterForm.Type == "Lifer" ? 1.0 : 0.5})"
                                on:click={() => CreateCharacterForm.Type = "Lifer"}
                            >Prison Lifer</Button>
                        </div>

                        <div style="margin: 2vh 0;">
                            <Button Color="success" on:click={ProcessNewCharacter}>Aanmaken</Button>
                            <Button Color="warning" on:click={CloseCreateForm}>Terug</Button>
                        </div>
                    {/if}
                </div>
            {/if}

            <!-- Probably should do some raycast magic? Instead of having 6 divs -->
            <!-- Eitherway, I don't really see a reason to make it harder then it needs to be -->
            <!-- Works fine on widescreen, at least in chrome -->
            {#if !CurrentCharacter.Delete && !CreateCharacterForm.IsCreating}
                <div class="characters" style="position: relative; display: flex; width: 152vh; margin: 0 auto;">
                    <div
                        on:keyup
                        on:click={() => SetCurrent(1)}
                        on:dblclick={() => PlayCharacter(1) }
                        on:mouseenter={() => SetCurrentHover(1) }
                        on:mouseleave={() => SetCurrentHover(false) }
                        class="character-hover-slot-one"
                    ></div>

                    <div
                        on:keyup
                        on:click={() => SetCurrent(2)}
                        on:dblclick={() => PlayCharacter(2) }
                        on:mouseenter={() => SetCurrentHover(2) }
                        on:mouseleave={() => SetCurrentHover(false) }
                        class="character-hover-slot-two"
                    ></div>

                    <div
                        on:keyup
                        on:click={() => SetCurrent(3)}
                        on:dblclick={() => PlayCharacter(3) }
                        on:mouseenter={() => SetCurrentHover(3) }
                        on:mouseleave={() => SetCurrentHover(false) }
                        class="character-hover-slot-three"
                    ></div>

                    <div
                        on:keyup
                        on:click={() => SetCurrent(4)}
                        on:dblclick={() => PlayCharacter(4) }
                        on:mouseenter={() => SetCurrentHover(4) }
                        on:mouseleave={() => SetCurrentHover(false) }
                        class="character-hover-slot-four"
                    ></div>

                    <div
                        on:keyup
                        on:click={() => SetCurrent(5)}
                        on:dblclick={() => PlayCharacter(5) }
                        on:mouseenter={() => SetCurrentHover(5) }
                        on:mouseleave={() => SetCurrentHover(false) }
                        class="character-hover-slot-five"
                    ></div>

                    <div
                        on:keyup
                        on:click={() => SetCurrent(6)}
                        on:dblclick={() => PlayCharacter(6) }
                        on:mouseenter={() => SetCurrentHover(6) }
                        on:mouseleave={() => SetCurrentHover(false) }
                        class="character-hover-slot-six"
                    ></div>
                </div>

                <div class="character-buttons">
                    <div class="character-buttons__btn" data-tooltip="Back" on:keyup on:click={() => { CurrentCharacter.Selected = false; SetView("menu"); }}><i class="fas fa-arrow-left"></i></div>
                    {#if CurrentCharacter.Selected}
                        <div class="character-buttons__btn" data-tooltip="Create new Character" on:keyup on:click={OpenCreateForm}><i class="fas fa-plus"></i></div>
                    {/if}
                </div>
            {/if}
        </div>
    {/if}
</AppWrapper>

<style>
    .title-screen, .menu-screen {
        position: absolute;
        inset: 0;
        color: white;
        font-family: 'Barlow Semi Condensed', sans-serif;
        font-style: italic;
        font-weight: 800;
        text-transform: uppercase;
        user-select: none;
    }

    .title-screen {
        background:
            linear-gradient(rgba(255,255,255,.05) 1px, transparent 1px) 0 0 / 5vw 5vw,
            linear-gradient(90deg, rgba(255,255,255,.05) 1px, transparent 1px) 0 0 / 5vw 5vw,
            radial-gradient(ellipse at center, rgba(0,20,30,.15), rgba(0,10,20,.6));
    }

    .title-logo {
        position: absolute;
        top: 43vh;
        width: 100%;
        display: flex;
        justify-content: center;
        align-items: flex-end;
        line-height: .8;
        font-style: normal;
        text-transform: none;
    }
    .title-logo .pixel { font-family: 'Silkscreen', monospace; font-weight: 400; font-size: 13vh; letter-spacing: -.4vh; }
    .title-logo .rp { font-family: 'Barlow Semi Condensed'; font-weight: 800; font-size: 17vh; margin-left: 1.2vh; }

    .title-beta {
        position: absolute;
        top: 63vh;
        width: 100%;
        text-align: center;
        font-size: 2.4vh;
        text-shadow: 0 0 1vh rgba(0,0,0,.6);
    }

    .title-start {
        position: absolute;
        top: 86.5vh;
        left: 50%;
        transform: translateX(-50%);
        width: 32.3vw;
        height: 4.4vh;
        display: flex;
        justify-content: center;
        align-items: center;
        background: white;
        color: black;
        font-size: 1.5vh;
        cursor: pointer;
    }

    .key {
        display: inline-flex;
        justify-content: center;
        align-items: center;
        min-width: 2.2vh;
        height: 2.2vh;
        padding: 0 .3vh;
        margin: 0 .7vh;
        border-radius: .3vh;
        background: white;
        color: black;
        font-size: 1.2vh;
        font-style: normal;
    }
    .key.dark { background: #1c1c1c; color: white; }

    .version {
        position: absolute;
        right: .8vh;
        bottom: .5vh;
        font-size: 1.2vh;
        font-weight: 400;
        font-style: normal;
    }

    .menu-screen { background: linear-gradient(rgba(10,18,26,.55), rgba(10,18,26,.85)); }

    .menu-panels {
        position: absolute;
        inset: 0 0 auto 0;
        height: 71vh;
        -webkit-box-reflect: below 0 linear-gradient(transparent 75%, rgba(0,0,0,.18));
    }

    .menu-panel-glow { position: absolute; inset: 0; pointer-events: none; transition: filter .2s; }
    .menu-panel-glow.active { z-index: 1; filter: drop-shadow(0 0 .15vh #3ee8ff) drop-shadow(0 0 .6vh #19c6f0); }

    .menu-panel {
        position: absolute;
        top: 0;
        height: 100%;
        pointer-events: auto;
        cursor: pointer;
        background: #16222c center / cover no-repeat;
        filter: grayscale(1) brightness(.35);
        transition: filter .2s;
    }
    .active > .menu-panel { filter: none; }

    .panel-0 { left: 0; width: 36.2%; clip-path: polygon(0 0, 100% 0, 74% 100%, 0 100%); }
    .panel-1 { left: 27.2%; width: 44.4%; clip-path: polygon(21.2% 0, 100% 0, 79.1% 100%, 0 100%); }
    .panel-2 { left: 62.7%; width: 37.3%; clip-path: polygon(24.9% 0, 100% 0, 100% 100%, 0 100%); }

    .menu-caption {
        position: absolute;
        bottom: 2.6vh;
        font-size: 1.9vh;
        white-space: nowrap;
        text-shadow: 0 0 1vh rgba(0,0,0,.8);
        transform: translateX(-50%);
    }
    .panel-0 .menu-caption { left: 37%; }
    .panel-1 .menu-caption { left: 39.5%; }
    .panel-2 .menu-caption { left: 50%; }

    .menu-buttons {
        position: absolute;
        top: 75.8vh;
        left: 3vw;
        right: 4.5vw;
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1.9vw;
    }

    .menu-button {
        height: 6.7vh;
        display: flex;
        justify-content: center;
        align-items: center;
        background: rgba(15,18,22,.85);
        font-size: 2vh;
        cursor: pointer;
    }
    .menu-button.active { background: white; color: black; }

    .menu-options {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 30vw;
        padding: 2vh;
        display: flex;
        flex-direction: column;
        gap: 1.2vh;
        background: rgba(10,14,18,.95);
        border: .15vh solid #3ee8ff;
        z-index: 2;
    }
    .menu-options > p { font-size: 2.4vh; text-align: center; }

    .menu-hints {
        position: absolute;
        right: 6vh;
        bottom: 3.4vh;
        display: flex;
        align-items: center;
        font-size: 1.4vh;
    }
    .menu-hints i { margin: 0 1.2vh; opacity: .6; }

    .characters-extra {
        position: absolute;
        left: 0;
        right: 0;
        bottom: 2vh;

        margin: 0 auto;

        width: 25vh;

        background-color: rgb(23 24 31);
        border-radius: 0.66vh;
        padding: 1vh;

        z-index: 997;
    }

    .characters-wrapper {
        position: absolute;
        top: 0;
        left: 0;

        width: 100vw;
        height: 100vh;
    }

    .character-current, .character-delete, .character-create {
        z-index: 5;

        position: relative;

        display: flex;
        flex-direction: column;
        align-items: center;

        border-radius: 0.66vh;

        padding: 1vh;

        color: white;

        font-family: Roboto;
        font-size: 2.5vh;

        width: 36%;

        margin: 0 auto;
        margin-top: 5vh;

        background-color: rgb(23 24 31);
    }

    .character-current > hr,
    .character-delete > hr,
    .character-create > hr {
        margin: 1vh 0;
        width: 90%;
    }

    .character-current > p,
    .character-delete > p,
    .character-create > p {
        text-align: center;
        padding: 1.5vh 0;
        max-width: 90%;
    }

    .character-hover-slot-one {
        z-index: 0;
        position: absolute;
        top: 15vh; left: -.5vh;
        width: 22vh; height: 55vh;
    }

    .character-hover-slot-two {
        z-index: 0;
        position: absolute;
        top: 13vh; left: 28vh;
        width: 20vh; height: 52vh;
    }

    .character-hover-slot-three {
        z-index: 0;
        position: absolute;
        top: 10vh; left: 53vh;
        width: 20vh; height: 52vh;
    }

    .character-hover-slot-four {
        z-index: 0;
        position: absolute;
        top: 10vh; left: 76.5vh;
        width: 20vh; height: 52vh;
    }

    .character-hover-slot-five {
        z-index: 0;
        position: absolute;
        top: 11vh; left: 100vh;
        width: 20.5vh; height: 52vh;
    }

    .character-hover-slot-six {
        z-index: 0;
        position: absolute;
        top: 11vh; left: 125vh;
        width: 23vh; height: 55vh;
    }

    .character-buttons {
        position: absolute;
        bottom: 9vh;

        width: 100vw;

        display: flex;
        justify-content: center;
    }

    .character-buttons__btn {
        margin: 1vh;

        border-radius: 50%;

        width: 4vh;
        height: 4vh;

        display: flex;
        justify-content: center;
        align-items: center;

        color: white;
        font-size: 1.5vh;

        background-color: rgb(23 24 31);
    }

    .creation-gender {
        display: flex;
        justify-content: space-around;
        width: 60%;
        margin-bottom: 5vh;
    }

    .creation-gender > img {
        width: auto;
        height: 30vh;
        -webkit-user-drag: none;
    }

    .creation-gender > img.highlight {
        filter: drop-shadow(0 0 .5vh #00aaf8bf);
    }
</style>