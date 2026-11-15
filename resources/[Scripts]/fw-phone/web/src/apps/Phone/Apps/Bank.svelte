<script>
    import { onMount } from "svelte";
    import { CopyToClipboard, FormatPhone, GetContactsSelect, GetTimeLabel, SendEvent } from "../../../utils/Utils";
    import { PlayerData } from "../phone.stores";
    import AppWrapper from "../components/AppWrapper.svelte";
    import Icon from "../components/Icon.svelte";

    const Nav = [["home", "home"], ["transfer", "send"], ["history", "note"]];
    const Money = N => "$" + Number(N || 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

    let Tab = "home", Card = 0, Query = "";
    let Accounts = [], Transactions = [], Contacts = [];
    let Target = "", Amount = "", Comment = "", Err = "", Busy = false;

    $: Cards = [
        ...Accounts.map(A => ({ Tag: A.Type == "Standaard" ? "Personal" : A.Type, Label: A.Name, Amount: A.Balance, Sub: A.Owner, Id: A.AccountId, Frozen: !A.Active })),
        { Tag: "Cash", Label: "Cash on hand", Amount: $PlayerData.Cash, Sub: "Wallet", Id: false },
    ];
    $: Current = Cards[Card % Cards.length];
    $: Account = Accounts[Math.min(Card, Accounts.length - 1)];
    $: Filtered = Transactions.filter(T => !Query || `${T.AccountName} ${T.Message} ${T.TransactionType}`.toLowerCase().includes(Query.toLowerCase()));

    const LoadTransactions = Id => Id && SendEvent("Bank/GetTransactions", { AccountId: Id }, (Ok, Data) => Ok && (Transactions = Data || []));
    const Load = () => SendEvent("Bank/GetAccounts", {}, (Ok, Data) => {
        if (!Ok || !Array.isArray(Data)) return;
        Accounts = Data;
        LoadTransactions(Current?.Id || Accounts[0]?.AccountId);
    });

    const Step = D => {
        Card = (Card + D + Cards.length) % Cards.length;
        if (Current.Id) LoadTransactions(Current.Id);
    };

    const Transfer = () => {
        Err = "";
        if (!Target.trim() || !(+Amount > 0)) return (Err = "Enter a recipient and a valid amount");
        Busy = true;
        SendEvent("Bank/Transfer", { AccountId: Account.AccountId, Target: Target.trim(), Amount: +Amount, Comment }, (Ok, Res) => {
            Busy = false;
            if (!Ok || !Res?.Success) return (Err = Res?.Msg || "Transfer failed");
            Target = Amount = Comment = "";
            Tab = "home";
            Load();
        });
    };

    onMount(async () => { Load(); Contacts = (await GetContactsSelect()).slice(0, 6); });
</script>

<AppWrapper class="bk">
    <div class="top">
        <div class="head">
            <div class="logo"><Icon Name="bank" /><span>FLEECA<br />BANK</span></div>
            {#if Tab == "transfer"}
                <h2>Transfer</h2>
            {:else}
                <div class="search"><Icon Name="search" /><input placeholder="Search" bind:value={Query} /></div>
            {/if}
        </div>

        {#if Tab == "home" && Current}
            <div class="card">
                <small>{Current.Tag}{Current.Frozen ? " · Frozen" : ""}</small>
                <span>{Current.Label}</span>
                <b>{Money(Current.Amount)}</b>
                <small>{Current.Sub}</small>
                {#if Current.Id}
                    <small class="copy" data-tooltip="Copy" on:keyup on:click={() => CopyToClipboard(Current.Id)}>Account ID: {Current.Id} <Icon Name="copy" /></small>
                {:else}
                    <small>Not in the bank</small>
                {/if}
            </div>
            <div class="dots">
                <button on:click={() => Step(-1)}><Icon Name="chev" /></button>
                {#each Cards as _, I}<i class:on={I == Card % Cards.length} />{/each}
                <button on:click={() => Step(1)}><Icon Name="chevr" /></button>
            </div>
        {/if}
    </div>

    <div class="body">
        {#if Tab == "transfer"}
            <div class="card2">
                <p class="lbl">Send money from {Account?.Name || "your account"}</p>
                <input class="in" placeholder="Phone number or account ID" bind:value={Target} />
                <input class="in" type="number" min="1" placeholder="Amount" bind:value={Amount} />
                <input class="in" maxlength="100" placeholder="Comment (optional)" bind:value={Comment} />
                <p class="err">{Err}</p>
                <button class="btn" disabled={Busy || !Account} on:click={Transfer}><Icon Name="send" />Send money</button>
            </div>
            <p class="h">Quick send</p>
            {#each Contacts as C}
                <div class="row" on:keyup on:click={() => Target = C.Value}>
                    <div class="ic">{C.Text.slice(0, 2).toUpperCase()}</div>
                    <div class="grow"><b>{C.Text}</b><small>{FormatPhone(C.Value)}</small></div>
                </div>
            {:else}
                <p class="none">No contacts yet</p>
            {/each}
        {:else}
            <p class="h">{Tab == "home" ? "Latest Transactions" : "Transactions"}</p>
            {#each Tab == "home" ? Filtered.slice(0, 4) : Filtered as T (T.Id)}
                <div class="row">
                    <div class="ic"><Icon Name="bank" /></div>
                    <div class="grow"><b>{T.AccountName || T.TransactionType}</b><small>{T.Message || T.TransactionType}</small></div>
                    <div class="am"><b class:pos={!T.IsNegative}>{T.IsNegative ? "-" : "+"} {Money(T.Amount)}</b><small>{GetTimeLabel(T.Timestamp)}</small></div>
                </div>
            {:else}
                <p class="none">{Query ? "No transactions found" : "No transactions yet"}</p>
            {/each}
            {#if Tab == "home" && Filtered.length > 4}
                <button class="all" on:click={() => Tab = "history"}>See All →</button>
            {/if}
        {/if}
    </div>

    <div class="nav">
        {#each Nav as [Key, Ic]}
            <button class:on={Tab == Key} on:click={() => { Tab = Key; Query = ""; }}><Icon Name={Ic} /></button>
        {/each}
    </div>
</AppWrapper>

<style>
    /* Codera bank, px converted to the phone's vh units */
    :global(.phone-app-wrapper.bk) { --phone-bg: #eef2f6; display: flex; flex-direction: column; color: #1b1f24; font-family: Poppins, Inter, sans-serif; }
    .bk :global(.ic) { width: 1.26vh; height: 1.26vh; }
    p { margin: 0; }
    button { border: 0; background: none; cursor: pointer; font-family: inherit; color: inherit; padding: 0; }
    input { font-family: inherit; outline: none; }

    .top { flex: none; padding: 3.7vh 1.18vh 1vh; background: linear-gradient(180deg, #1556c0, #2b78e0); color: white; }
    .head { display: flex; align-items: center; gap: 0.84vh; margin-bottom: 1vh; }
    .head h2 { margin: 0; font-size: 1.26vh; font-weight: 600; }
    .logo { display: flex; align-items: center; gap: 0.5vh; padding: 0.5vh 1vh 0.5vh 0.76vh; border-radius: 99vh; background: white; color: #0f3f95; flex: none; }
    .logo span { font-size: 0.63vh; font-weight: 800; line-height: 1.05; letter-spacing: 0.07vh; }
    .search { position: relative; flex: 1; min-width: 0; color: #d6e6ff; }
    .search :global(.ic) { position: absolute; left: 0.93vh; top: 50%; transform: translateY(-50%); width: 1vh; height: 1vh; }
    .search input { width: 100%; box-sizing: border-box; height: 2.53vh; border: 0; border-radius: 99vh; background: rgba(255, 255, 255, 0.16); color: white; padding: 0 1vh 0 2.5vh; font-size: 0.93vh; }
    .search input::placeholder { color: #d6e6ff; }

    .card { padding: 1.18vh 1.35vh; border-radius: 1.18vh; background: linear-gradient(160deg, #1b63cf, #1456b8); border: 0.08vh solid rgba(255, 255, 255, 0.12); box-shadow: 0 0.67vh 1.7vh rgba(8, 36, 92, 0.28); }
    .card small { display: flex; align-items: center; gap: 0.4vh; font-size: 0.84vh; font-weight: 500; color: #cfe0fb; }
    .card span { display: block; margin-top: 0.17vh; font-size: 1vh; font-weight: 600; }
    .card b { display: block; margin: 0.17vh 0 0.5vh; font-size: 2.5vh; font-weight: 700; letter-spacing: -0.04vh; }
    .copy { cursor: pointer; }
    .copy :global(.ic) { width: 0.9vh; height: 0.9vh; }
    .dots { display: flex; align-items: center; justify-content: center; gap: 0.5vh; margin-top: 0.84vh; }
    .dots button { width: 1.5vh; height: 1.5vh; display: grid; place-items: center; color: white; }
    .dots i { width: 0.5vh; height: 0.5vh; border-radius: 50%; background: rgba(255, 255, 255, 0.45); }
    .dots i.on { width: 1.5vh; border-radius: 0.34vh; background: white; }

    .body { flex: 1; min-height: 0; overflow-y: auto; padding: 1.18vh 1.18vh 1vh; color: #1b1f24; }
    .body::-webkit-scrollbar { display: none; }
    .h { margin: 0.17vh 0.17vh 0.84vh; font-size: 1.18vh; font-weight: 700; }
    .row { display: flex; align-items: center; gap: 0.84vh; margin-bottom: 0.67vh; padding: 0.84vh 1vh; border-radius: 0.67vh; background: white; border: 0.08vh solid #e1e7ee; cursor: pointer; }
    .row:hover { border-color: #a9c9f5; }
    .ic { width: 2.53vh; height: 2.53vh; border-radius: 0.6vh; background: #e8eef7; display: grid; place-items: center; color: #1f3f6e; font-size: 0.84vh; font-weight: 700; flex: none; }
    .grow { flex: 1; min-width: 0; }
    .row b { display: block; font-size: 1vh; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .row small { display: block; font-size: 0.84vh; color: #7c8791; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .am { text-align: right; flex: none; }
    .am b.pos { color: #1a9d5c; }
    .all { display: block; width: 100%; padding: 0.84vh; border-radius: 0.67vh; background: white; border: 0.08vh solid #e1e7ee; font-size: 0.93vh; font-weight: 500; color: #6b7580; }
    .none { padding: 1.85vh 0.67vh; text-align: center; font-size: 0.97vh; color: #7c8791; }

    .card2 { margin-bottom: 1.18vh; padding: 1.18vh; border-radius: 0.84vh; background: white; border: 0.08vh solid #e1e7ee; }
    .lbl { margin-bottom: 0.84vh; font-size: 1vh; font-weight: 600; }
    .in { width: 100%; box-sizing: border-box; height: 3vh; margin-bottom: 0.67vh; padding: 0 0.93vh; border: 0.08vh solid #d9e0e8; border-radius: 0.67vh; background: white; color: #1b1f24; font-size: 1vh; }
    .in:focus { border-color: #2b78e0; box-shadow: 0 0 0 0.25vh rgba(43, 120, 224, 0.15); }
    .in::-webkit-inner-spin-button { display: none; }
    .err { min-height: 1.18vh; margin: 0 0.17vh 0.5vh; font-size: 0.89vh; color: #e5484d; }
    .btn { width: 100%; height: 3.2vh; display: flex; align-items: center; justify-content: center; gap: 0.6vh; border-radius: 0.67vh; background: #1f6fe0; color: white; font-size: 1vh; font-weight: 600; }
    .btn:disabled { opacity: 0.6; }

    .nav { flex: none; display: flex; justify-content: space-around; padding: 0.67vh 0.84vh 2.9vh; background: white; border-top: 0.08vh solid #e1e7ee; }
    .nav button { width: 3vh; height: 3vh; border-radius: 50%; display: grid; place-items: center; color: #4a5560; }
    .nav button :global(.ic) { width: 1.43vh; height: 1.43vh; }
    .nav button.on { background: #dbe9fc; color: #1f6fe0; }
</style>
