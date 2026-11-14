import { get } from "svelte/store";
import { FormatPhone, SendEvent } from "../../../utils/Utils";
import { PlayerData } from "../phone.stores";

export const EMOJIS = ["😀", "😂", "😅", "😍", "😎", "🤔", "😭", "😡", "👍", "👎", "🙏", "🔥", "💯", "🎉", "❤️", "💀", "👀", "🚗", "💰", "📍"];

export const IsGroup = Phone => /^g\d+$/.test(Phone || "");
export const IsMessageSender = Msg => Msg.Sender == get(PlayerData).PhoneNumber;
export const Initials = Name => String(Name || "?").trim().slice(0, 2).toUpperCase();

export const LastText = (Chat, Me) => {
    const Msg = Chat.messages[0];
    if (!Msg) return "No messages yet";
    const Body = Msg.Message || (Msg.Loc ? "Shared location" : Msg.Attachments?.length ? "Photo" : "");
    if (Msg.Sender == Me) return `You: ${Body}`;
    return Chat.group ? `${Msg.SenderName}: ${Body}` : Body;
};

const Pad = N => String(N).padStart(2, "0");
export const Time = Ts => { const D = new Date(Ts), H = D.getHours(); return `${H % 12 || 12}:${Pad(D.getMinutes())} ${H >= 12 ? "PM" : "AM"}`; };
export const ShortDay = Ts => new Date(Ts).toDateString() == new Date().toDateString() ? Time(Ts) : `${new Date(Ts).getDate()}/${new Date(Ts).getMonth() + 1}`;
export const DayLabel = Ts => {
    const D = new Date(Ts).toDateString();
    if (D == new Date().toDateString()) return "Today";
    if (D == new Date(Date.now() - 864e5).toDateString()) return "Yesterday";
    return new Date(Ts).toLocaleDateString("en-GB");
};

export const ChatSub = Chat => Chat.group ? `${Chat.group.Members.length} Members` : FormatPhone(Chat.to_phone);
export const CallContact = Phone => SendEvent("Contacts/Call", { Phone });
