<script>
    // Port of codera-hud web/js/chat.js + chat.css (message list, command suggestions, sent history).
    // Always mounted from Hud/App.svelte so messages survive the HUD hiding/showing.
    import { tick } from "svelte";
    import { OnEvent, SendEvent as _SendEvent } from "../../../utils/Utils";
    import { MyPreferences } from "../../Preferences/preferences.store.js";
    import { ChatOpen, ChatInputWidth, HudVisible } from "../hud.store.js";
    import { Layout } from "../layout.js";

    const SendEvent = (Event, Data, Callback) => _SendEvent(Event, Data, Callback, "fw-hud");

    const Defaults = { MaxLength: 120, MaxHistory: 50, VisibleWhenClosed: 6, FadeAfter: 8000, FadeDuration: 400, InputWidth: 340 };
    const MaxSuggestions = 8;
    const MaxSentHistory = 50;
    // Must match the .codera-chat__bar close transition in the style block.
    const BarCloseMs = 320;

    let Settings = { ...Defaults };
    let Open = false;        // input is open
    let Mounted = false;     // container is in the layout
    let BarOpen = false;     // bar has the open class (delayed one frame on first mount so it can animate)
    let MountCloseTimer = null;

    let Messages = [];       // { Id, Author, Message, Type, Color, Fading }
    let NextId = 1;
    const FadeTimers = new Map();

    let Commands = [];
    let Active = [];
    let Index = 0;
    let SentHistory = [];
    let HistoryIndex = -1;
    let HistoryDraft = "";

    let Value = "";
    let InputElement;

    $: Visible = Open ? Messages : Messages.slice(-Settings.VisibleWhenClosed);
    $: HideMessages = Active.length > 0;
    $: ChatOpen.set(Open);
    $: ChatInputWidth.set(Settings.InputWidth);

    const UpdateMounted = async () => {
        const ShouldStay = Open || Messages.length > 0;
        const WasMounted = Mounted;

        if (ShouldStay) {
            if (MountCloseTimer) { clearTimeout(MountCloseTimer); MountCloseTimer = null; }
            Mounted = true;
        };

        if (Open && !WasMounted) {
            // First mount: paint the closed state first, then flip to open so the bar slides in.
            BarOpen = false;
            await tick();
            requestAnimationFrame(() => requestAnimationFrame(() => { BarOpen = Open; }));
        } else {
            BarOpen = Open;
        };

        if (ShouldStay || MountCloseTimer) return;

        // Closing: keep it mounted just long enough for the bar's closing animation.
        MountCloseTimer = setTimeout(() => {
            MountCloseTimer = null;
            if (!Open && Messages.length == 0) Mounted = false;
        }, BarCloseMs);
    };

    const RemoveMessage = (Id) => {
        Messages = Messages.filter((Val) => Val.Id != Id);
        const Timer = FadeTimers.get(Id);
        if (Timer) { clearTimeout(Timer); FadeTimers.delete(Id); }
        UpdateMounted();
    };

    const ScheduleFade = (Id) => {
        const FadeTimer = setTimeout(() => {
            if (Open) return; // messages stay put while composing

            const Entry = Messages.find((Val) => Val.Id == Id);
            if (!Entry) return;

            Entry.Fading = true;
            Messages = Messages;

            FadeTimers.set(Id, setTimeout(() => RemoveMessage(Id), Settings.FadeDuration));
        }, Settings.FadeAfter);

        FadeTimers.set(Id, FadeTimer);
    };

    const ClearFadeTimers = () => {
        FadeTimers.forEach((Timer) => clearTimeout(Timer));
        FadeTimers.clear();
    };

    const AddMessage = (Author, Message, Type, Color) => {
        const Id = NextId++;
        Messages = [...Messages, { Id, Author, Message, Type: Type || "default", Color, Fading: false }];

        if (Messages.length > Settings.MaxHistory) {
            const Removed = Messages[0];
            Messages = Messages.slice(1);
            const Timer = FadeTimers.get(Removed.Id);
            if (Timer) { clearTimeout(Timer); FadeTimers.delete(Removed.Id); }
        };

        UpdateMounted();
        if (!Open) ScheduleFade(Id);
    };

    const ResetInput = () => {
        Value = "";
        Active = [];
        Index = 0;
        HistoryIndex = -1;
        HistoryDraft = "";
    };

    const OpenChat = async (NewSettings) => {
        Settings = { ...Defaults, ...(NewSettings || {}) };
        Open = true;

        // Messages don't fade while composing.
        ClearFadeTimers();
        Messages.forEach((Entry) => { Entry.Fading = false; });
        Messages = Messages;

        ResetInput();
        await UpdateMounted();
        await tick();
        InputElement?.focus();
    };

    const CloseChat = () => {
        Open = false;
        InputElement?.blur();
        ResetInput();
        UpdateMounted();
        Messages.forEach((Entry) => ScheduleFade(Entry.Id));
    };

    const SuggestionSyntax = (Command) => {
        if (Command.help) return Command.help;
        if (Array.isArray(Command.params) && Command.params.length) {
            return `/${Command.name} ${Command.params.map((Param) => `[${Param.name}]`).join(" ")}`;
        };
        return `/${Command.name}`;
    };

    const UpdateSuggestions = () => {
        const Match = /^\/(\S*)$/.exec(Value);

        if (!Match) {
            if (Active.length) { Active = []; Index = 0; }
            return;
        };

        const Prefix = Match[1].toLowerCase();
        Active = Commands
            .filter((Command) => Command.name.toLowerCase().startsWith(Prefix))
            .sort((A, B) => A.name.localeCompare(B.name))
            .slice(0, MaxSuggestions);
        Index = 0;
    };

    const CompleteSuggestion = () => {
        const Chosen = Active[Index];
        if (!Chosen) return false;

        Value = `/${Chosen.name} `;
        Active = [];
        Index = 0;
        return true;
    };

    const BrowseHistory = async (Direction) => {
        if (!SentHistory.length) return;

        if (Direction == "up") {
            if (HistoryIndex == -1) {
                HistoryDraft = Value;
                HistoryIndex = SentHistory.length - 1;
            } else if (HistoryIndex > 0) {
                HistoryIndex -= 1;
            };
            Value = SentHistory[HistoryIndex];
        } else {
            if (HistoryIndex == -1) return;

            if (HistoryIndex < SentHistory.length - 1) {
                HistoryIndex += 1;
                Value = SentHistory[HistoryIndex];
            } else {
                HistoryIndex = -1;
                Value = HistoryDraft;
            };
        };

        await tick();
        InputElement?.setSelectionRange(Value.length, Value.length);
        UpdateSuggestions();
    };

    const Send = () => {
        const Message = Value.trim();

        // Don't clutter history with an exact repeat of the last thing sent.
        if (Message && SentHistory[SentHistory.length - 1] != Message) {
            SentHistory = [...SentHistory, Message].slice(-MaxSentHistory);
        };

        SendEvent("Chat/Send", { Message });
        CloseChat();
    };

    const Cancel = () => {
        SendEvent("Chat/Close", {});
        CloseChat();
    };

    const OnKeyDown = (Event) => {
        if (Active.length && (Event.key == "ArrowDown" || Event.key == "ArrowUp")) {
            Event.preventDefault();
            Index = (Index + (Event.key == "ArrowDown" ? 1 : -1) + Active.length) % Active.length;
        } else if (!Active.length && (Event.key == "ArrowUp" || Event.key == "ArrowDown")) {
            Event.preventDefault();
            BrowseHistory(Event.key == "ArrowUp" ? "up" : "down");
        } else if (Active.length && Event.key == "Tab") {
            Event.preventDefault();
            CompleteSuggestion();
        } else if (Event.key == "Enter") {
            Event.preventDefault();
            if (Active.length) return CompleteSuggestion();
            Send();
        } else if (Event.key == "Escape") {
            Event.preventDefault();
            Cancel();
        };
    };

    const OnInput = () => {
        // Typing cancels history browsing.
        HistoryIndex = -1;
        UpdateSuggestions();
    };

    // Hud/ChatOpen, ChatMessage, ChatClear, ChatCommands (sent from fw-hud handlers/chat.ts)
    OnEvent("Hud", "ChatOpen", (Data) => OpenChat(Data.Settings));
    OnEvent("Hud", "ChatMessage", (Data) => {
        if (Data.Settings) Settings = { ...Defaults, ...Data.Settings };
        AddMessage(Data.Author, Data.Message, Data.Type, Data.Color);
    });
    OnEvent("Hud", "ChatClear", () => {
        ClearFadeTimers();
        Messages = [];
        UpdateMounted();
    });
    OnEvent("Hud", "ChatCommands", (Data) => {
        Commands = Array.isArray(Data.Commands) ? Data.Commands : [];
        UpdateSuggestions();
    });
</script>

{#if Mounted && $HudVisible && !$MyPreferences['BlackBars.Show']}
    <div class="chat-anchor" data-layout="player" use:Layout={"player"}>
        <div class="codera-chat is-mounted" class:is-open={BarOpen} style:--chat-input-width="{Settings.InputWidth / 10.8}vh">
            <div class="codera-chat__messages" style:visibility={HideMessages ? "hidden" : ""}>
                {#each Visible as Entry (Entry.Id)}
                    <div
                        class="codera-chat__message"
                        class:codera-chat__message--me={Entry.Type == "me"}
                        class:codera-chat__message--ooc={Entry.Type == "ooc"}
                        class:codera-chat__message--error={Entry.Type == "error"}
                        class:is-fading={Entry.Fading}
                    >
                        {#if Entry.Author}
                            <span class="codera-chat__message-author" style:color={Entry.Color}>{Entry.Author}:</span>
                        {/if}
                        <span class="codera-chat__message-text">{Entry.Message}</span>
                    </div>
                {/each}
            </div>

            <div class="codera-chat__suggestions" class:has-items={Active.length > 0}>
                {#each Active as Command, Key}
                    <div class="codera-chat__suggestion" class:is-selected={Key == Index}>
                        <span class="codera-chat__suggestion-name">/{Command.name}</span>
                        <span class="codera-chat__suggestion-desc">{SuggestionSyntax(Command)}</span>
                    </div>
                {/each}
            </div>

            <div class="codera-chat__bar" role="presentation" on:click={() => InputElement?.focus()}>
                <div class="codera-chat__bar-inner">
                    <i class="fas fa-comment-dots codera-chat__icon" aria-hidden="true"></i>
                    <input
                        type="text"
                        class="codera-chat__input"
                        autocomplete="off"
                        spellcheck="false"
                        maxlength={Settings.MaxLength}
                        bind:this={InputElement}
                        bind:value={Value}
                        on:keydown={OnKeyDown}
                        on:input={OnInput}
                    />
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    /* Sits where .player-hud sits (left 1.5vw / bottom 4vh) and shares its layout transform. */
    .chat-anchor {
        position: absolute;
        left: 1.5vw;
        bottom: 4vh;
        height: 3.24vh;
        pointer-events: none;
    }

    .codera-chat {
        position: relative;
        display: flex;
        align-items: center;
        height: 3.241vh;
    }
    @keyframes codera-chat-mount-in {from { opacity: 0; transform: translateY(0.556vh); }
    to { opacity: 1; transform: translateY(0); }
    }
    .codera-chat.is-mounted {
        animation: codera-chat-mount-in 0.22s cubic-bezier(0.16, 1, 0.3, 1) both;
    }
    .codera-chat__messages {
        position: absolute;
        bottom: calc(100% + 0.741vh);
        left: 0;
        display: flex;
        flex-direction: column;
        gap: 0.37vh;
        width: max-content;
        max-width: 60vw;
        pointer-events: none;
    }
    .codera-chat__message {
        display: inline-flex;
        max-width: 100%;
        padding: 0.556vh 0.926vh;
        border-radius: 0.37vh;
        background: rgba(15, 15, 15, 0.82);
        color: #fff;
        font-family: "Inter", sans-serif;
        font-size: 1.204vh;
        line-height: 1.3;
        text-shadow: 0 0.093vh 0.185vh rgba(0, 0, 0, 0.6);
        opacity: 1;
        transition: opacity 0.4s ease;
        word-break: break-word;
        animation: codera-chat-message-in 0.18s ease both;
    }
    @keyframes codera-chat-message-in {from { opacity: 0; transform: translateY(0.37vh); }
    to { opacity: 1; transform: translateY(0); }
    }
    .codera-chat__message.is-fading {
        opacity: 0;
    }
    .codera-chat__message--me {
        background: rgba(15, 15, 15, 0.82);
        color: #c9a7ff;
        font-style: italic;
    }
    .codera-chat__message--me .codera-chat__message-text {
        color: #c9a7ff;
    }
    .codera-chat__message--ooc .codera-chat__message-author {
        color: #9aa0a6;
    }
    .codera-chat__message--ooc .codera-chat__message-text {
        color: rgba(255, 255, 255, 0.75);
        font-style: italic;
    }
    .codera-chat__message-author {
        margin-right: 0.37vh;
        font-weight: 700;
    }
    .codera-chat__suggestions {
        position: absolute;
        bottom: calc(100% + 0.741vh);
        left: 0;
        z-index: 1;
        display: none;
        flex-direction: column;
        gap: 0.185vh;
        width: max-content;
        min-width: var(--chat-input-width, 31.481vh);
        max-width: 60vw;
        pointer-events: none;
    }
    .codera-chat.is-open .codera-chat__suggestions.has-items {
        display: flex;
    }
    .codera-chat__suggestion {
        display: flex;
        align-items: baseline;
        gap: 0.926vh;
        padding: 0.741vh 1.296vh;
        background: rgba(15, 15, 15, 0.82);
        border-left: 0.278vh solid transparent;
        animation: codera-chat-message-in 0.15s ease both;
    }
    .codera-chat__suggestion.is-selected {
        background: rgba(15, 40, 43, 0.92);
        border-left-color: #2dd4e3;
    }
    .codera-chat__suggestion-name {
        flex: 0 0 auto;
        color: #2dd4e3;
        font-family: "Barlow Semi Condensed", "Inter", sans-serif;
        font-style: italic;
        font-weight: 800;
        font-size: 1.296vh;
        text-transform: uppercase;
        letter-spacing: 0.028vh;
        text-shadow: 0 0.093vh 0.185vh rgba(0, 0, 0, 0.6);
    }
    .codera-chat__suggestion-desc {
        flex: 1 1 auto;
        min-width: 0;
        color: rgba(255, 255, 255, 0.85);
        font-family: "Inter", sans-serif;
        font-size: 1.204vh;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        text-shadow: 0 0.093vh 0.185vh rgba(0, 0, 0, 0.6);
    }
    .codera-chat__bar {
        display: flex;
        align-items: center;
        height: 100%;
        width: 0;
        margin-right: 0;
        overflow: hidden;
        border-radius: 2.222vh;
        background: rgba(15, 15, 15, 0.8);
        box-shadow: 0 0.278vh 0.463vh rgba(0, 0, 0, 0.5);
        opacity: 0;
        transform: translateY(0.37vh);
        transition:
            width 0.32s cubic-bezier(0.16, 1, 0.3, 1),
            margin-right 0.32s cubic-bezier(0.16, 1, 0.3, 1),
            opacity 0.22s ease-out,
            transform 0.3s cubic-bezier(0.16, 1, 0.3, 1),
            box-shadow 0.15s ease;
    }
    .codera-chat__bar:focus-within {
        box-shadow: 0 0.278vh 0.463vh rgba(0, 0, 0, 0.5), 0 0 0 0.185vh rgba(255, 255, 255, 0.25);
    }
    .codera-chat.is-open .codera-chat__bar {
        width: var(--chat-input-width, 31.481vh);
        margin-right: 0.556vh;
        opacity: 1;
        transform: translateY(0);
    }
    .codera-chat__bar-inner {
        display: flex;
        flex: 0 0 auto;
        align-items: center;
        gap: 0.741vh;
        width: var(--chat-input-width, 31.481vh);
        height: 100%;
        padding: 0 1.296vh;
    }
    .codera-chat__icon {
        flex: 0 0 auto;
        color: #fff;
        font-size: 1.389vh;
        text-shadow: 0 0.093vh 0.185vh rgba(0, 0, 0, 0.6);
    }
    .codera-chat__input {
        flex: 1 1 auto;
        min-width: 0;
        border: 0;
        outline: none;
        background: transparent;
        color: #fff;
        font-family: "Inter", sans-serif;
        font-size: 1.204vh;
    }
    .codera-chat__input::placeholder {
        color: rgba(255, 255, 255, 0.4);
    }

    .codera-chat__bar { pointer-events: auto; }

    .codera-chat__message--error {
        color: #ff6b6b;
    }

    .codera-chat__message--error .codera-chat__message-text {
        color: #ff6b6b;
    }
</style>
