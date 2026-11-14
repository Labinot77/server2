<script>
    import * as MSG from "./_messages";
    import { onMount } from "svelte";
    import { ExtractImageUrls, FormatPhone, GetContactsSelect, OnEvent, SendEvent } from "../../../utils/Utils";
    import { PlayerData, CurrentChat } from "../phone.stores";
    import AppWrapper from "../components/AppWrapper.svelte";
    import Icon from "../components/Icon.svelte";

    let Chats = [], Contacts = [];
    let View = $CurrentChat ? "thread" : "list"; // list | thread | compose | group | info
    let Query = "", Text = "", ToNumber = "";
    let ShowEmoji = false, ShowPhoto = false, PhotoUrl = "";
    let GroupName = "", GroupNumber = "", GroupSel = [], GroupErr = "";

    $: Me = Chats[0]?.from_phone || $PlayerData.PhoneNumber;
    $: Filtered = Chats
        .filter(C => !Query || C.name.toLowerCase().includes(Query.toLowerCase()) || C.to_phone.includes(Query))
        .sort((A, B) => (B.messages[0]?.Timestamp || 0) - (A.messages[0]?.Timestamp || 0));
    $: Chat = $CurrentChat;
    $: Unread = C => C.group ? 0 : C.messages.filter(M => M.Sender != Me && M.Unread === 1).length;
    $: ValidPhoto = /^https?:\/\/\S+$/.test(PhotoUrl.trim());

    const SetChats = Data => {
        Chats = Object.values(Data || {});
        if ($CurrentChat) CurrentChat.set(Chats.find(C => C.to_phone == $CurrentChat.to_phone) || { ...$CurrentChat, messages: $CurrentChat.messages || [] });
    };

    const Load = () => SendEvent("Messages/GetChats", {}, (Ok, Data) => Ok && SetChats(Data));
    OnEvent("Messages/SetChats", Data => SetChats(Data.Chats));
    onMount(async () => { Load(); Contacts = await GetContactsSelect(); });

    const MarkRead = () => Chat && !Chat.group && SendEvent("Messages/SetChatRead", { ToPhone: Chat.to_phone, FromPhone: Me });

    const Open = Phone => {
        const Found = Chats.find(C => C.to_phone == Phone);
        CurrentChat.set(Found || { from_phone: Me, to_phone: Phone, name: Contacts.find(C => C.Value == Phone)?.Text || FormatPhone(Phone), messages: [] });
        Text = ""; ShowEmoji = ShowPhoto = false; PhotoUrl = "";
        View = "thread";
        MarkRead();
    };

    const Back = () => {
        if (View == "info") return (View = "thread");
        if (View == "thread") MarkRead();
        CurrentChat.set(false);
        View = "list";
    };

    const Send = (Extra = {}) => {
        const [Attachments, Message] = ExtractImageUrls(Text.trim());
        if (ValidPhoto) Attachments.push(PhotoUrl.trim());
        if (!Message.trim() && !Attachments.length && !Extra.Loc) return;
        SendEvent("Messages/SendMessage", { Phone: Chat.to_phone, Message: Message.trim(), Attachments, ...Extra });
        Text = ""; PhotoUrl = ""; ShowPhoto = ShowEmoji = false;
    };

    const ShareLocation = () => SendEvent("Messages/GetLocation", {}, (Ok, Loc) => Ok && Loc && SendEvent("Messages/SendMessage", { Phone: Chat.to_phone, Message: "", Attachments: [], Loc }));
    const Waypoint = Loc => SendEvent("Messages/SetWaypoint", { Loc });

    const NewGroup = () => { GroupName = GroupNumber = GroupErr = ""; GroupSel = []; View = "group"; };
    const ToggleMember = N => GroupSel = GroupSel.includes(N) ? GroupSel.filter(X => X != N) : [...GroupSel, N];
    const CreateGroup = () => {
        const Numbers = [...GroupSel, ...GroupNumber.replace(/[^\d,]/g, "").split(",").filter(Boolean)];
        if (!GroupName.trim() || !Numbers.length) return (GroupErr = "Enter a name and pick at least one member");
        SendEvent("Messages/CreateGroup", { Name: GroupName.trim(), Numbers }, (Ok, Res) => {
            if (!Ok || !Res?.Success) return (GroupErr = Res?.Msg || "Could not create the group");
            SendEvent("Messages/GetChats", {}, (Ok2, Data) => { if (Ok2) SetChats(Data); Open(Res.Key); });
        });
    };
    const LeaveGroup = () => SendEvent("Messages/LeaveGroup", { Phone: Chat.to_phone }, () => { CurrentChat.set(false); View = "list"; Load(); });

    // Oldest first, with a day separator and (in groups) the sender's name when it changes.
    $: Thread = (Chat?.messages || []).slice().reverse().map((M, I, A) => {
        const Prev = A[I - 1], NewDay = !Prev || new Date(Prev.Timestamp).toDateString() != new Date(M.Timestamp).toDateString();
        return { ...M, Mine: M.Sender == Me, Day: NewDay && MSG.DayLabel(M.Timestamp), Tag: Chat.group && M.Sender != Me && (NewDay || Prev.Sender != M.Sender) };
    });
</script>

<AppWrapper class="msg">
    {#if View == "thread" && Chat}
        <div class="head">
            <button class="rnd" on:click={Back}><Icon Name="arrowl" /></button>
            <div class="hav">{MSG.Initials(Chat.name)}</div>
            <div class="ht"><b>{Chat.name}</b><small>{MSG.ChatSub(Chat)}</small></div>
            {#if Chat.group}
                <button class="rnd" data-tooltip="Group info" on:click={() => View = "info"}><Icon Name="info" /></button>
            {:else}
                <button class="rnd" data-tooltip="Call" on:click={() => MSG.CallContact(Chat.to_phone)}><Icon Name="phone" /></button>
            {/if}
        </div>

        <div class="thread" style="bottom: {ShowEmoji ? 16 : ShowPhoto ? 11.6 : 7}vh">
            {#each Thread.slice().reverse() as M}
                <div class="bw" class:me={M.Mine}>
                    {#if M.Tag}<span class="bsn">{M.SenderName}</span>{/if}
                    {#if M.Loc}
                        <div class="locard" class:me={M.Mine} on:keyup on:click={() => Waypoint(M.Loc)} data-tooltip="Set waypoint">
                            <svg viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#0f5a65"/><path d="M0 72 L38 44 L68 62 L112 22 L160 56 L160 90 L0 90Z" fill="#0c4b55"/><path d="M-5 26 C38 4 72 38 100 70 S150 96 172 80" stroke="#8fbfc2" stroke-width="9" fill="none" opacity=".8"/><g transform="translate(86 40)"><path d="M0 13C-8 3-8-11 0-11S8 3 0 13z" fill="#e53935"/><circle cy="-4" r="3.2" fill="#7b1f1f"/></g></svg>
                            <div class="lcf"><Icon Name="pin" /><span>Shared location</span><time>{MSG.Time(M.Timestamp)}</time></div>
                        </div>
                    {:else}
                        <div class="bubble" class:me={M.Mine}>
                            {#each M.Attachments || [] as Url}<img src={Url} alt="" />{/each}
                            {M.Message}<time>{MSG.Time(M.Timestamp)}</time>
                        </div>
                    {/if}
                </div>
                {#if M.Day}<div class="dsep">{M.Day}</div>{/if}
            {:else}
                <div class="empty"><Icon Name="message" /><p>Say hi!</p></div>
            {/each}
        </div>

        <div class="composer">
            {#if ShowPhoto}
                <div class="photo">
                    {#if ValidPhoto}<img src={PhotoUrl.trim()} alt="" />{/if}
                    <input class="field" placeholder="Paste an image URL..." bind:value={PhotoUrl} />
                </div>
            {/if}
            {#if ShowEmoji}
                <div class="emojis">{#each MSG.EMOJIS as E}<button on:click={() => Text += E}>{E}</button>{/each}</div>
            {/if}
            <div class="crow">
                <div class="cpill">
                    <input maxlength="500" placeholder="Type a message..." bind:value={Text} on:keydown={e => e.key == "Enter" && Send()} />
                    <button class:on={ShowEmoji} on:click={() => { ShowEmoji = !ShowEmoji; ShowPhoto = false; }}><Icon Name="smile" /></button>
                    <button class:on={ShowPhoto} data-tooltip="Photo" on:click={() => { ShowPhoto = !ShowPhoto; ShowEmoji = false; }}><Icon Name="image" /></button>
                    <button data-tooltip="Share location" on:click={ShareLocation}><Icon Name="pin" /></button>
                </div>
                <button class="send" on:click={() => Send()}><Icon Name="send" /></button>
            </div>
        </div>
    {:else if View == "info" && Chat?.group}
        <div class="head">
            <button class="rnd" on:click={Back}><Icon Name="arrowl" /></button>
            <div class="ht"><b>{Chat.name}</b><small>{Chat.group.Members.length} Members</small></div>
        </div>
        <div class="body">
            {#each Chat.group.Members as M}
                <div class="row static"><div class="mav">{MSG.Initials(M.name)}</div><div class="grow"><b>{M.name}</b><small>{FormatPhone(M.number)}</small></div></div>
            {/each}
            <button class="btn danger" on:click={LeaveGroup}>Leave group</button>
        </div>
    {:else if View == "compose" || View == "group"}
        <div class="head">
            <button class="rnd" on:click={Back}><Icon Name="arrowl" /></button>
            <div class="ht"><b>{View == "group" ? "New group" : "New message"}</b></div>
        </div>
        <div class="body">
            {#if View == "group"}
                <p class="mlabel">Group name</p>
                <input class="field" maxlength="40" bind:value={GroupName} />
                <p class="mlabel">Add numbers (comma separated)</p>
                <input class="field" placeholder="Phone numbers" bind:value={GroupNumber} />
                {#if GroupErr}<p class="err">{GroupErr}</p>{/if}
                <button class="btn" on:click={CreateGroup}>Create group</button>
            {:else}
                <p class="mlabel">To</p>
                <div class="crow">
                    <input class="field" placeholder="Phone number" bind:value={ToNumber} on:keydown={e => e.key == "Enter" && ToNumber.trim() && Open(ToNumber.replace(/\D/g, ""))} />
                    <button class="send" on:click={() => ToNumber.trim() && Open(ToNumber.replace(/\D/g, ""))}><Icon Name="arrowl" class="flip" /></button>
                </div>
            {/if}
            <p class="mlabel">Contacts</p>
            {#each Contacts as C}
                <div class="row" on:keyup on:click={() => View == "group" ? ToggleMember(C.Value) : Open(C.Value)}>
                    <div class="mav">{MSG.Initials(C.Text)}</div>
                    <div class="grow"><b>{C.Text}</b><small>{FormatPhone(C.Value)}</small></div>
                    {#if View == "group"}<div class="toggle" class:on={GroupSel.includes(C.Value)} />{/if}
                </div>
            {:else}
                <div class="empty"><Icon Name="user" /><p>No contacts</p></div>
            {/each}
        </div>
    {:else}
        <div class="head"><h2>CHATS</h2></div>
        <div class="body">
            <div class="cbar">
                <span>{Chats.length} Chat{Chats.length == 1 ? "" : "s"}</span>
                <div>
                    <button data-tooltip="New group" on:click={NewGroup}><Icon Name="users" /></button>
                    <button data-tooltip="New message" on:click={() => { ToNumber = ""; View = "compose"; }}><Icon Name="plus" /></button>
                </div>
            </div>
            <div class="msearch"><Icon Name="search" /><input placeholder="Search" bind:value={Query} /></div>
            <p class="mlabel">Chat Contacts</p>
            {#each Filtered as C (C.to_phone)}
                <div class="row" on:keyup on:click={() => Open(C.to_phone)}>
                    <div class="mav">{#if C.group}<Icon Name="users" />{:else}{MSG.Initials(C.name)}{/if}</div>
                    <div class="grow"><b>{C.name}</b><small>{MSG.LastText(C, Me)}</small></div>
                    <div class="meta">
                        {C.messages[0] ? MSG.ShortDay(C.messages[0].Timestamp) : ""}
                        {#if Unread(C)}<span class="pill">{Unread(C) > 99 ? "99+" : Unread(C)}</span>{/if}
                    </div>
                </div>
            {:else}
                <div class="empty"><Icon Name="message" /><p>{Query ? "No chats found" : "No conversations yet"}</p></div>
            {/each}
        </div>
    {/if}
</AppWrapper>

<style>
    /* Codera messages, scaled from px to the phone's vh units */
    :global(.phone-app-wrapper.msg) { --phone-bg: #222427; font-family: Poppins, Inter, sans-serif; }
    .msg :global(.ic) { width: 1.1vh; height: 1.1vh; }
    :global(.ic.flip) { transform: rotate(180deg); }
    button { border: 0; background: none; color: inherit; cursor: pointer; font-family: inherit; padding: 0; }
    input { font-family: inherit; color: #f3f4f6; outline: none; border: 0; background: transparent; }

    .head { display: flex; align-items: center; gap: 0.76vh; padding: 3.9vh 1vh 0.84vh; border-bottom: 0.08vh solid rgba(255, 255, 255, 0.07); }
    .head h2 { margin: 0 0 0 0.3vh; font-size: 2.1vh; font-weight: 800; letter-spacing: 0.04vh; }
    .rnd { width: 2.36vh; height: 2.36vh; border-radius: 50%; background: #3b3e43; display: grid; place-items: center; flex: none; }
    .hav { width: 2.87vh; height: 2.87vh; border-radius: 50%; background: #3b3e43; display: grid; place-items: center; font-size: 1.1vh; font-weight: 600; color: #cfd3da; flex: none; }
    .ht { flex: 1; min-width: 0; }
    .ht b, .row b { display: block; font-size: 1.05vh; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .ht small, .row small { display: block; font-size: 0.89vh; color: #9aa0aa; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

    .body { position: absolute; top: 7.6vh; bottom: 2.6vh; left: 0; right: 0; overflow-y: auto; padding: 0.84vh; }
    .body::-webkit-scrollbar, .thread::-webkit-scrollbar { display: none; }

    .cbar { display: flex; align-items: center; justify-content: space-between; background: #1f2124; border-radius: 0.67vh; padding: 0.42vh 0.84vh; font-size: 0.93vh; margin-bottom: 0.84vh; }
    .cbar div { display: flex; gap: 0.5vh; }
    .cbar button { width: 1.85vh; height: 1.85vh; display: grid; place-items: center; border-radius: 50%; }
    .cbar button:hover { background: rgba(255, 255, 255, 0.14); }
    .msearch { display: flex; align-items: center; gap: 0.67vh; background: #3b3e43; border-radius: 0.84vh; padding: 0 1vh; margin-bottom: 1vh; color: #9aa0aa; }
    .msearch:focus-within { box-shadow: 0 0 0 0.13vh #d5dbe3; }
    .msearch input { flex: 1; padding: 0.84vh 0; font-size: 1vh; }
    .mlabel { font-size: 0.89vh; color: #9aa0aa; margin: 0.6vh 0.34vh 0.5vh; }

    .row { display: flex; align-items: center; gap: 0.84vh; background: rgba(255, 255, 255, 0.07); border-radius: 0.67vh; padding: 0.76vh 1vh; margin-bottom: 0.34vh; cursor: pointer; }
    .row:hover { background: rgba(255, 255, 255, 0.12); }
    .row.static { cursor: default; }
    .grow { flex: 1; min-width: 0; }
    .mav { width: 2.2vh; display: grid; place-items: center; font-size: 0.89vh; font-weight: 700; color: #cdd1d8; flex: none; }
    .meta { display: flex; flex-direction: column; align-items: flex-end; gap: 0.25vh; font-size: 0.84vh; color: #cdd1d8; }
    .pill { background: #cfe8f5; color: #16384a; border-radius: 0.76vh; padding: 0.08vh 0.6vh; font-size: 0.84vh; font-weight: 600; }
    .empty { display: flex; flex-direction: column; align-items: center; gap: 0.84vh; color: #9aa0aa; padding: 4.7vh 1.7vh; font-size: 1.05vh; }
    .empty :global(.ic) { width: 3.5vh; height: 3.5vh; opacity: 0.6; }

    .thread { position: absolute; top: 7.6vh; bottom: 7vh; left: 0; right: 0; overflow-y: auto; padding: 0.4vh 0.84vh; display: flex; flex-direction: column-reverse; gap: 0.34vh; }
    .bw { display: flex; flex-direction: column; align-items: flex-start; max-width: 85%; }
    .bw.me { align-self: flex-end; align-items: flex-end; }
    .bsn { font-size: 0.8vh; color: #cdd1d8; margin: 0.5vh 0 0.17vh 0.34vh; }
    .bubble { background: #3d4045; border-radius: 1.26vh; padding: 0.6vh 0.93vh; font-size: 0.97vh; line-height: 1.35; word-break: break-word; user-select: text; }
    .bubble.me { background: #a9d5f2; color: #10202c; }
    .bubble img { display: block; max-width: 100%; border-radius: 0.93vh; margin-bottom: 0.34vh; }
    .bubble time { margin-left: 0.6vh; font-size: 0.72vh; opacity: 0.6; white-space: nowrap; }
    .dsep { align-self: center; font-size: 0.76vh; color: #9aa0aa; margin: 0.67vh 0 0.34vh; }

    .locard { width: 14.8vh; border-radius: 0.84vh; overflow: hidden; background: #2a2d30; cursor: pointer; }
    .locard svg { display: block; width: 100%; height: 8.8vh; }
    .lcf { display: flex; align-items: center; gap: 0.5vh; padding: 0.6vh 0.76vh; font-size: 0.8vh; font-weight: 600; background: #2a2d30; }
    .lcf :global(.ic) { color: #4da3ff; }
    .lcf time { margin-left: auto; font-size: 0.76vh; opacity: 0.65; }
    .locard.me .lcf { background: #a9d5f2; color: #10202c; }
    .locard.me .lcf :global(.ic) { color: #1b6fa5; }

    .composer { position: absolute; left: 0; right: 0; bottom: 2.6vh; padding: 0.67vh 0.84vh; display: flex; flex-direction: column; gap: 0.5vh; }
    .crow { display: flex; align-items: center; gap: 0.67vh; }
    .cpill { flex: 1; min-width: 0; display: flex; align-items: center; background: #3b3e43; border-radius: 1vh; padding: 0 0.5vh 0 0.34vh; }
    .cpill input { flex: 1; min-width: 0; padding: 0.84vh 0.67vh; font-size: 1vh; }
    .cpill button { width: 2vh; height: 2.5vh; display: grid; place-items: center; color: #9aa0aa; }
    .cpill button:hover, .cpill button.on { color: #8cc8ff; }
    .send { width: 2.87vh; height: 2.87vh; border-radius: 50%; background: #56708f; color: #dfe9f5; display: grid; place-items: center; flex: none; }
    .emojis { display: flex; flex-wrap: wrap; gap: 0.17vh; max-height: 8vh; overflow-y: auto; background: #2b2e32; border-radius: 1vh; padding: 0.34vh; }
    .emojis button { width: 2.87vh; height: 2.87vh; font-size: 1.6vh; border-radius: 0.76vh; }
    .emojis button:hover { background: #3b3e43; }
    .photo { display: flex; align-items: center; gap: 0.67vh; background: #2b2e32; border-radius: 1vh; padding: 0.5vh; }
    .photo img { height: 4.2vh; border-radius: 0.6vh; }

    .field { width: 100%; box-sizing: border-box; background: #3b3e43; border-radius: 1vh; padding: 0.84vh 1vh; font-size: 1vh; }
    .field:focus { box-shadow: 0 0 0 0.13vh #4f8cff; }
    .btn { width: 100%; margin-top: 1vh; padding: 0.93vh; border-radius: 1.1vh; background: #4f8cff; color: white; font-weight: 600; font-size: 1.05vh; }
    .btn.danger { background: rgba(255, 77, 79, 0.16); color: #ff4d4f; }
    .err { color: #ff4d4f; font-size: 0.93vh; margin: 0.6vh 0.34vh 0; }
    .toggle { position: relative; width: 2.5vh; height: 1.43vh; border-radius: 0.76vh; background: #3b3e43; flex: none; transition: 0.2s; }
    .toggle::after { content: ""; position: absolute; top: 0.21vh; left: 0.21vh; width: 1vh; height: 1vh; border-radius: 50%; background: #eceef1; transition: 0.2s; }
    .toggle.on { background: #2ecc71; }
    .toggle.on::after { left: 1.3vh; }
</style>
