<script>

    // Default: hide after 3 seconds
    // If COUNTDOWN it hides after 30 seconds
    // 
    // If action is clicked, hide it UNLESS defined otherwise.
    // If told otherwise OR a timer is shown, do NOT fade out AT ALL, unless 'RemoveNotification' is called.
    // 
    // Fade State SHOULD not be handled here, instead handle it in utils.
    // 
    // ## PLEASE DO NOT TOUCH. IT WILL BREAK ##

    import { onDestroy, onMount } from "svelte";
    import { Notifications, RemoveNotification, SendEvent } from "../../../utils/Utils";

    export let Id = "";
    export let IconColor = "white";
    export let BgColor = "rgb(144, 202, 249)";
    export let Icon = "user-circle";
    export let Title = "Title";
    export let Text = "";
    export let ShowTimer = false;
    export let ShowCountdown = false;
    export let HasAccept = false;
    export let HasReject = false;
    export let Data = {};
    export let State = "in";

    // Actions
    const OnReject = () => {
        SendEvent("Notifications/Click", {Id, Accepted: false});
        if (!Data.HideOnAction) return;

        HasAccept = false, HasReject = false;
        ForceFade();
    };

    const OnAccept = () => {
        SendEvent("Notifications/Click", {Id, Accepted: true});
        if (!Data.HideOnAction) return;

        HasAccept = false, HasReject = false;
        ForceFade();
    };

    const SetState = (Value) => {
        let NewNotifications = $Notifications;
        const NotifIndex = NewNotifications.findIndex(Val => Val.Id == Id);
        if (NotifIndex == -1) return;
        NewNotifications[NotifIndex].State = Value;
        Notifications.set(NewNotifications);
    };

    // Fade In/Out
    let StateTimeout = setTimeout(() => {
        SetState("");
    }, 500);

    const FadeOut = () => {
        if (ShowTimer) return;
        if (HasAccept || HasReject && !Data.HideOnAction) return;
        if (Data.Sticky) return;

        StateTimeout = setTimeout(() => {
            SetState("out");
            setTimeout(() => {
                RemoveNotification({ Id });
            }, 500);
        }, ShowCountdown ? 30500 : 3500);
    };

    const ForceFade = () => {
        if ((HasAccept || HasReject) && !Data.HideOnAction) return;
        if ((ShowCountdown || ShowTimer) && !Data.HideOnAction) return;

        clearTimeout(StateTimeout);
        SetState("out");
        setTimeout(() => {
            RemoveNotification({ Id });
        }, 500);
    };

    // Timer
    let Prefix = "";
    let Timer = 0;
    let TimerInterval;
    if (ShowCountdown) Timer = 30;

    const FormatTime = () => {
        const Minutes = Math.floor(Timer / 60).toString().padStart(2, "0");
        const Seconds = (Timer % 60).toString().padStart(2, "0");
        return `${Minutes}:${Seconds}`;
    };

    onMount(() => {
        if (ShowTimer) {
            Prefix = FormatTime();
            TimerInterval = setInterval(() => {
                Timer = Timer + 1;
                Prefix = FormatTime();
            }, 1000);
            return;
        }

        if (ShowCountdown) {
            Prefix = FormatTime();
            TimerInterval = setInterval(() => {
                Timer = Timer - 1;
                Prefix = FormatTime();

                if (Timer <= 0 && State != "out") {
                    SetState("out");
                    setTimeout(() => {
                        RemoveNotification({ Id });
                    }, 500);
                }
            }, 1000);
        };

        FadeOut();
    });

    onDestroy(() => {
        clearInterval(TimerInterval);
    });

    $: if ((!ShowTimer && !ShowCountdown) && TimerInterval) {
        clearInterval(TimerInterval);
        Prefix = "";
    }
</script>

<div class="phone-notification phone-notification-{State}" on:keyup on:click={() => {
    if (HasAccept || HasReject) return;
    ForceFade(); 
}}>
    <div class="phone-notification-title">
        <div class="icon" style="color: {IconColor}; background-color: {BgColor};">
            <i class="{Icon}" />
        </div>
        <div class="app">
            <p>{Title}</p>
        </div>
        <p>just now</p>
    </div>
    <div class="phone-notification-message">
        <div class="text">
            <p>{Prefix}{(ShowTimer || ShowCountdown) && Text ? " - " + Text : Text}</p>
        </div>
        <div class="actions">
            {#if HasReject}
                <div on:keyup on:click={OnReject} data-tooltip="Decline" class="tooltip phone-notification-action action-reject">
                    <i class="fas fa-times-circle" />
                </div>
            {/if}
            {#if HasAccept}
                <div on:keyup on:click={OnAccept} data-tooltip="Accept" class="tooltip phone-notification-action action-accept">
                    <i class="fas fa-check-circle" />
                </div>
            {/if}
        </div>
    </div>
</div>

<style>
    /* Codera banner */
    .phone-notification {
        width: calc(100% - 1.34vh);
        padding: 0.76vh 1vh;
        border-radius: 1.35vh;
        color: white;
        cursor: pointer;
        margin-bottom: 0.5vh;
        font-family: Poppins, Inter, sans-serif;
        background: rgba(34, 36, 40, 0.9);
        backdrop-filter: blur(1.5vh);
        border: 0.08vh solid rgba(255, 255, 255, 0.07);
        box-shadow: 0 0.67vh 1.85vh rgba(0, 0, 0, 0.45);
    }

    .phone-notification-in { animation: PhoneNotifIn 0.35s cubic-bezier(0.2, 0.9, 0.2, 1) forwards; }
    .phone-notification-out { animation: PhoneNotifOut 0.3s forwards; }

    .phone-notification p { margin: 0; line-height: 1.3; }

    .phone-notification-title { display: flex; align-items: center; gap: 0.9vh; }

    .phone-notification-title > .icon {
        flex: none;
        display: grid;
        place-items: center;
        width: 2.4vh;
        height: 2.4vh;
        border-radius: 0.7vh;
        font-size: 1.15vh;
    }

    .phone-notification-title > .app { flex: 1; min-width: 0; }

    .phone-notification-title > .app > p {
        font-size: 1.14vh;
        font-weight: 600;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .phone-notification-title > p { font-size: 0.9vh; color: #c6cad1; }

    .phone-notification-message { display: flex; margin: 0.3vh 0 0 3.3vh; }
    .phone-notification-message > .text { flex: 1; min-width: 0; }

    .phone-notification-message > .text > p {
        font-size: 1.01vh;
        color: #c6cad1;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .phone-notification-message > .actions { display: flex; align-items: center; gap: 0.5vh; }
    .phone-notification-action { font-size: 1.6vh; }
    .action-accept { color: var(--phone-green); }
    .action-reject { color: var(--phone-red); }

    @keyframes PhoneNotifIn {
        from { opacity: 0; transform: translateY(-1.35vh) scale(0.96); }
        to { opacity: 1; transform: none; }
    }

    @keyframes PhoneNotifOut {
        from { opacity: 1; max-height: 6vh; }
        to { opacity: 0; transform: translateY(-1vh) scale(0.97); max-height: 0; padding: 0; margin: 0; }
    }
</style>
