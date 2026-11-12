// Port of codera-hud client/chat.lua onto the fw-chat resource.
//
// fw-chat (resources/[Cores]/[fivem]/[gameplay]/fw-chat) stays as the SERVER side:
// sv_chat.lua keeps routing `_chat:messageEntered`, `chatMessage`, `chat:init`, /clear etc.
// Its client side is only the spam filter export; the UI is the Chat.svelte layer in fw-ui.
//
// Like your old chat, whatever the player types is run with ExecuteCommand
// (`/` optional), after the spam filter check.

import { Chat } from "../../shared/config";
import { RegisterNUICallback, SendUIMessage, SetUIFocus, exp } from "../../shared/utils";
import { FW, LoggedIn } from "../client";

interface Suggestion { name: string; help: string; params: Array<{ name: string, help?: string }>; }

let IsOpen = false;
const Suggestions: {[name: string]: Suggestion} = {};
const AllowedCommands: {[name: string]: boolean} = {};
let SuggestionTimer: ReturnType<typeof setTimeout> | null = null;

const StripSlash = (Name: string) => String(Name || "").replace(/^\//, "");

// Chat templates can contain html (<strong>{0}:</strong> {1}). The new UI only renders text.
const PlainText = (Value: any): string => String(Value ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();

const BuildCommandList = (): Suggestion[] => {
    const List: Suggestion[] = [];
    const Seen: {[name: string]: boolean} = {};

    for (const [Lower, Data] of Object.entries(Suggestions)) {
        Seen[Lower] = true;
        List.push(Data);
    };

    for (const Lower of Object.keys(AllowedCommands)) {
        if (!Seen[Lower]) List.push({ name: Lower, help: "", params: [] });
    };

    return List;
};

const SendCommands = () => {
    SendUIMessage("Hud", "ChatCommands", { Commands: BuildCommandList() });
};

// Debounced, because resources register hundreds of suggestions in a burst on startup.
const QueueCommands = () => {
    if (SuggestionTimer) return;
    SuggestionTimer = setTimeout(() => {
        SuggestionTimer = null;
        SendCommands();
    }, 250);
};

const RefreshAllowedCommands = () => {
    for (const Key of Object.keys(AllowedCommands)) delete AllowedCommands[Key];

    for (const Command of GetRegisteredCommands()) {
        if (IsAceAllowed(`command.${Command.name}`)) AllowedCommands[String(Command.name).toLowerCase()] = true;
    };

    QueueCommands();
};

const AddSuggestion = (Name: string, Help?: string, Params?: Array<{ name: string, help?: string }>) => {
    Name = StripSlash(Name);
    if (Name == "") return;

    Suggestions[Name.toLowerCase()] = { name: Name, help: Help || "", params: Params || [] };
    QueueCommands();
};

onNet("chat:addSuggestion", AddSuggestion);

onNet("chat:addSuggestions", (List: Array<{ name: string, help?: string, params?: any[] }>) => {
    if (!Array.isArray(List)) return;
    for (const Item of List) AddSuggestion(Item.name, Item.help, Item.params);
});

onNet("chat:removeSuggestion", (Name: string) => {
    delete Suggestions[StripSlash(Name).toLowerCase()];
    QueueCommands();
});

// --- Incoming messages ------------------------------------------------------

const PushMessage = (Author: string, Message: string, Type: string = "default", Color?: number[]) => {
    Message = PlainText(Message);
    if (Message == "") return;

    SendUIMessage("Hud", "ChatMessage", {
        Author: PlainText(Author),
        Message,
        Type,
        Color: Array.isArray(Color) ? `rgb(${Color[0] ?? 255}, ${Color[1] ?? 255}, ${Color[2] ?? 255})` : null,
        Settings: Chat,
    });
};

// Server: TriggerClientEvent("chatMessage", source, author, "error" | "normal" | false, text)
onNet("chatMessage", (Author: string, Type: string | false, Text: string) => {
    PushMessage(Author, Text, Type == "error" ? "error" : "default");
});

// The community standard event used by most resources.
onNet("chat:addMessage", (Message: any) => {
    if (typeof Message != "object" || Message == null) return;

    const Args: any[] = Array.isArray(Message.args) ? Message.args : [];

    if (typeof Message.template == "string" && Message.template != "") {
        const Text = Message.template.replace(/\{(\d+)\}/g, (_: string, Index: string) => String(Args[Number(Index)] ?? ""));
        return PushMessage("", Text, "default", Message.color);
    };

    if (Args.length >= 2) return PushMessage(String(Args[0]), Args.slice(1).join(" "), "default", Message.color);
    if (Args.length == 1) return PushMessage("", String(Args[0]), "default", Message.color);
});

onNet("__cfx_internal:serverPrint", (Message: string) => {
    PushMessage("", Message, "default");
});

onNet("chat:clear", () => {
    SendUIMessage("Hud", "ChatClear", {});
});

// --- Opening / sending ------------------------------------------------------

// The old `chat` resource (with its own Vue page) also opens on T. If it's still running, leave T to it,
// otherwise both chats grab the keyboard and the player ends up stuck.
const OldChatRunning = () => GetResourceState("chat") == "started" && !!GetResourceMetadata("chat", "ui_page", 0);

let OpenedAck = false;

const OpenChat = () => {
    if (IsOpen || IsPauseMenuActive()) return;

    IsOpen = true;
    OpenedAck = false;
    SetUIFocus(true, false); // keyboard only, no cursor
    SendUIMessage("Hud", "ChatOpen", { Settings: Chat });
    SendCommands();

    // Fail-safe: if the UI never confirms the input is focused, give the keyboard back.
    setTimeout(() => {
        if (IsOpen && !OpenedAck) CloseChat();
    }, 1500);
};

const CloseChat = () => {
    if (!IsOpen) return;

    IsOpen = false;
    SetUIFocus(false, false);
};

setTick(async () => {
    if (!Chat.Enabled || !LoggedIn) return await new Promise((Res) => setTimeout(Res, 450));
    if (IsOpen) return;

    if (IsControlJustReleased(0, Chat.Control) && !OldChatRunning()) OpenChat();
});

RegisterNUICallback("Chat/Opened", (Data: any, Cb: Function) => {
    OpenedAck = true;
    Cb("Ok");
});

RegisterNUICallback("Chat/Close", (Data: any, Cb: Function) => {
    CloseChat();
    Cb("Ok");
});

RegisterNUICallback("Chat/Send", (Data: { Message?: string }, Cb: Function) => {
    CloseChat();
    Cb("Ok");

    let Message = typeof Data?.Message == "string" ? Data.Message.trim() : "";
    if (Message == "") return;
    if (Message.length > Chat.MaxLength) Message = Message.substring(0, Chat.MaxLength);
    if (Message.startsWith("/")) Message = Message.substring(1);

    // Spam filter lives in fw-chat (exports['fw-chat']:GetSpamFilter()).
    const SpamFilter: {[word: string]: number} = GetResourceState("fw-chat") == "started" ? exp['fw-chat'].GetSpamFilter() || {} : {};
    const Lowered = Message.toLowerCase();
    const Matched = Object.keys(SpamFilter).find((Word) => Lowered.includes(Word));

    if (Matched && FW.Throttled(`chat-${Matched}`, SpamFilter[Matched])) {
        return FW.Functions.Notify("Je kan dit commando nog niet gebruiken..", "error");
    };

    ExecuteCommand(Message);
});


// Diagnostic: the old chat UI opens on T as well when the `chat` resource still has its Vue page.
setTimeout(() => {
    if (OldChatRunning()) {
        console.log("^1[fw-hud] The default `chat` resource is running (artifact citizen/system_resources/chat), so the old chat is used on T. Remove `ensure chat` from server.cfg, `ensure fw-chat` instead, and restart the server.^7");
    };
}, 5000);

// --- Lifecycle --------------------------------------------------------------

// Fetch the server's command list (chat:init -> sv_chat.lua -> chat:addSuggestions).
export const InitiateChat = () => {
    TriggerServerEvent("chat:init");
    RefreshAllowedCommands();
};

on("onClientResourceStart", () => setTimeout(RefreshAllowedCommands, 1000));
on("onClientResourceStop", () => setTimeout(RefreshAllowedCommands, 1000));

on("onResourceStop", (Resource: string) => {
    if (Resource != GetCurrentResourceName()) return;
    if (IsOpen) SetUIFocus(false, false);
});

// Called after a UI restart: the new UI has no suggestions yet.
export const ResyncChat = () => {
    IsOpen = false;
    QueueCommands();
};
