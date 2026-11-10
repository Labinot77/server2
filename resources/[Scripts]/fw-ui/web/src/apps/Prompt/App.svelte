<script>
    import { OnEvent } from "../../utils/Utils";
    import AppWrapper from '../../components/AppWrapper.svelte';
    import { cubicOut } from 'svelte/easing';
    import { flip } from 'svelte/animate';

    // Prompt
    let ShowPrompt = false;
    let PromptText = "";
    let PromptColor = "primary";

    OnEvent("Prompt", "SetInteraction", (Data) => {
        ShowPrompt = true;
        PromptText = Data.Text.replaceAll(`[`, `<span>[`).replaceAll(`]`, `]</span>`);
        PromptColor = Data.Type;
    });

    OnEvent("Prompt", "HideInteraction", () => {
        ShowPrompt = false;
    });

    const Icons = { success: '✓', inform: '!', error: '×' };
    const MinDuration = 500;
    const MaxDuration = 30000;
    const DefaultDuration = 4000;
    const ExitMs = 320;

    let Notifications = [];

    // Maps old/misspelled types to the new ones ("primary" -> "inform")
    const NormalizeType = (Raw) => {
        const Type = String(Raw || 'inform').toLowerCase();
        if (Type === 'sucess') return 'success';
        if (Type === 'primary') return 'inform';
        return Icons[Type] ? Type : 'inform';
    };

    const ClampDuration = (Raw) => {
        const Duration = Number(Raw) || DefaultDuration;
        return Math.max(MinDuration, Math.min(Duration, MaxDuration));
    };

    // Slide in/out from the right, matching the original design
    const SlideRight = (node, { duration = 280 } = {}) => ({
        duration,
        easing: cubicOut,
        css: (t) => `transform: translateX(${(1 - t) * 115}%); opacity: ${t};`
    });

    OnEvent("Prompt", "AddNotification", (Data) => {
        AddNotification({
            Id: Data.Id,
            Text: Data.Message,
            Color: Data.Type,
            Duration: Data.TimeOut,
        });
    });

    const CreatePromptId = () => `${Date.now()}-${Math.floor(Math.random() * 9999)}`;

    const AddNotification = (Data) => {
        if (!Data.Id) Data.Id = CreatePromptId();

        const Type = NormalizeType(Data.Color);
        const Text = String(Data.Text ?? '');

        // Replace an existing notification with the same id or identical content
        const ExistingIndex = Notifications.findIndex(Val => Val.Id == Data.Id || (Val.Text == Text && Val.Color == Type));
        if (ExistingIndex > -1) DeleteNotification(Notifications[ExistingIndex].Id);

        Notifications = [
            ...Notifications,
            {
                Id: Data.Id,
                Text,
                Color: Type,
                Timeout: setTimeout(() => DeleteNotification(Data.Id), ClampDuration(Data.Duration))
            }
        ];
    };

    const DeleteNotification = (PromptId) => {
        const Existing = Notifications.find(Val => Val.Id == PromptId);
        if (!Existing) return;
        if (Existing.Timeout) clearTimeout(Existing.Timeout);
        Notifications = Notifications.filter(Val => Val.Id != PromptId);
    };
</script>

<AppWrapper AppName="Prompt" Focused={false} style="z-index: 999;">
    <div class="notify-container">
        {#each Notifications as Data (Data.Id)}
            <div
                class="notification {Data.Color}"
                in:SlideRight={{ duration: 280 }}
                out:SlideRight={{ duration: ExitMs }}
                animate:flip={{ duration: 200 }}
            >
                <div class="icon-box">
                    <span class="icon">{Icons[Data.Color]}</span>
                </div>
                <div class="message-box">
                    <span class="message">{Data.Text}</span>
                </div>
            </div>
        {/each}
    </div>

    <div class="prompt-wrapper">
        <div class="prompt {PromptColor}" class:move-in={ShowPrompt}>
            {@html PromptText}
        </div>
    </div>
</AppWrapper>

<style>
    @import url('https://fonts.googleapis.com/css2?family=Roboto+Condensed:wght@500;600&display=swap');

    /* ---------- Prompt (unchanged) ---------- */
    .prompt-wrapper {
        position: absolute;
        top: 47.6%;
        left: 0;
        transform: translateY(-50%);
    }

    .prompt {
        position: absolute;
        transform: translateX(-150%);

        padding: 1.5vh;

        width: max-content;
        height: max-content;

        transition: transform 1000ms cubic-bezier(0, 0, 0.2, 1) 0ms;

        margin: 0;

        font-style: normal;
        font-family: Arial, Helvetica, sans-serif;
        font-weight: 600;
        font-variant: small-caps;
        letter-spacing: -0.01vh;
        text-transform: none;
        text-decoration: none;
        font-size: 1.5vh;

        color: white;
        background-color: #0288d1;
        border-radius: 0.3vh;
    }

    :global(.prompt > span) {
        text-shadow: rgb(55 71 79) -0.1vh 0.1vh 0, rgb(55 71 79) 0.1vh 0.1vh 0, rgb(55 71 79) 0.1vh -0.1vh 0, rgb(55 71 79) -0.1vh -0.1vh 0;
    }

    .prompt.move-in { transform: translateX(6.5%); }
    .prompt.move-out { transform: translateX(-150%); }

    .prompt.error { background-color: #ee3939; }
    .prompt.success { background-color: #3bb041; }
    .prompt.primary { background-color: #2196f3; }

        /* ---------- Notifications ---------- */
    .notify-container {
        position: absolute;
        top: 3.2vh;
        right: 1.2vw;
        width: min(24vw, 440px);

        display: flex;
        flex-direction: column;
        gap: 6px;

        pointer-events: none;
        font-family: 'Roboto Condensed', Arial, sans-serif;
        user-select: none;
    }

    .notification {
        --accent: #12dff1;
        --text: #f4f4f4;

        display: grid;
        grid-template-columns: 46px 1fr;
        min-height: 46px;
    }

    .notification.success { --accent: #43df78; }
    .notification.inform  { --accent: #13dff2; }
    .notification.error   { --accent: #ff4e55; }

    .icon-box, .message-box {
        position: relative;
        overflow: hidden;
        background: rgba(14, 14, 14, 0.8);
    }

    .icon-box {
        display: grid;
        place-items: center;
    }

    .message-box {
        margin-left: 3px;
        display: flex;
        align-items: center;
        padding: 8px 16px;
    }

    .icon {
        color: var(--accent);
        font-size: 30px;
        line-height: 1;
        font-weight: 600;
        text-shadow: 0 0 7px var(--accent), 0 0 14px color-mix(in srgb, var(--accent) 55%, transparent);
    }

    .message {
        position: relative;
        z-index: 1;
        color: var(--text);
        font-size: clamp(13px, 0.95vw, 19px);
        font-weight: 500;
        letter-spacing: .1px;
        text-shadow: 0 2px 2px rgba(0, 0, 0, .75);
        overflow-wrap: anywhere;
    }

    @media (max-width: 1100px) {
        .notify-container { width: min(40vw, 420px); }
        .notification { grid-template-columns: 42px 1fr; min-height: 42px; }
        .icon { font-size: 27px; }
    }
</style>