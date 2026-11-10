<script>
    import { OnEvent, SetExitHandler, SendEvent as _SendEvent } from "../../utils/Utils";
    const SendEvent = (Event, Parameters, Callback) => _SendEvent(Event, Parameters, Callback, "fw-financials");

    import AppWrapper from "../../components/AppWrapper.svelte";
    import ActionForm from "./components/ActionForm.svelte";
    import Export from "./modals/Export.svelte";
    import { Cash, CurrentAccount, CurrentTransactions, IsATM, ModalData } from "./financials.store";
    import { FormatMoney, TimeAgo, TransactionKind, TransactionVerb } from "./format";

    let Visible = false;
    let Accounts = [];
    let Bills = [];

    let Tab = 'Accounts';       // 'Accounts' | 'Bills'
    let SubTab = 'History';     // 'History' | 'Deposit' | 'Withdraw' | 'Transfer'
    let Search = '';
    let Filter = 'all';         // 'all' | 'deposits' | 'withdrawals' | 'transfers'
    let Highlight = 0;
    let Limit = 50;

    const MainTabs = ['Accounts', 'Bills'];
    const Filters = [
        { Id: 'all', Label: 'All' },
        { Id: 'deposits', Label: 'Deposits' },
        { Id: 'withdrawals', Label: 'Withdrawals' },
        { Id: 'transfers', Label: 'Transfers' },
    ];

    const LoadTransactions = (AccountId) => {
        SendEvent("Financials/GetTransactions", { AccountId }, (Success, Data) => {
            if (!Success) return;
            CurrentTransactions.set(Data);
        });
    };

    const Reset = () => {
        Tab = 'Accounts';
        SubTab = 'History';
        Search = '';
        Filter = 'all';
        Highlight = 0;
        Limit = 50;
    };

    OnEvent("Financials", "SetVisibility", (Data) => {
        if (!Data.Visible) {
            Visible = false;
            ModalData.set({});
            return;
        }

        Accounts = Data.Accounts || [];
        Bills = Data.Bills || [];
        Cash.set(Data.Cash || 0);
        IsATM.set(Data.IsATM);
        CurrentTransactions.set([]);
        Reset();

        if (Accounts[0]) {
            CurrentAccount.set(Accounts[0]);
            if (Accounts[0].Permissions?.Transactions) LoadTransactions(Accounts[0].AccountId);
        }

        Visible = true;
    });

    OnEvent("Financials", "SetFinancials", (Data) => {
        Accounts = Data;

        // Keep a valid selection and pull in the latest history
        const Match = Accounts.find((Account) => Account.AccountId == $CurrentAccount?.AccountId) || Accounts[0];
        if (!Match) return;

        CurrentAccount.set(Match);
        if (Match.Permissions?.Transactions) LoadTransactions(Match.AccountId);
    });

    SetExitHandler("", "Financials/Close", () => Visible, { __resource: "fw-financials" });

    // The balance always comes from the freshest account list
    $: Selected = Accounts.find((Account) => Account.AccountId == $CurrentAccount?.AccountId) || Accounts[0] || {};
    $: CanSeeHistory = !!Selected.Permissions?.Transactions;
    $: TotalBalance = Accounts.filter((Account) => Account.Active).reduce((Sum, Account) => Sum + (Number(Account.Balance) || 0), 0);
    $: Owner = Accounts[0]?.Owner || '';

    $: SubTabs = [
        { Id: 'History' },
        ...($IsATM ? [] : [{ Id: 'Deposit', Allowed: Selected.Permissions?.Deposit }]),
        { Id: 'Withdraw', Allowed: Selected.Permissions?.Withdraw },
        { Id: 'Transfer', Allowed: Selected.Permissions?.Transfer },
    ];

    const Matches = (Transaction, Query) => {
        if (!Query) return true;
        return [Transaction.Message, Transaction.TransactionType, Transaction.Receiver, Transaction.Sender, Transaction.TransactionUUID, Transaction.Amount]
            .some((Value) => String(Value ?? '').toLowerCase().includes(Query));
    };

    $: Rows = $CurrentTransactions.filter((Transaction) =>
        (Filter == 'all' || TransactionKind(Transaction) == Filter) && Matches(Transaction, Search.trim().toLowerCase())
    );

    const SelectAccount = (Account, Index) => {
        if (!Account.Active) return;
        Highlight = Index;
        SubTab = 'History';
        Limit = 50;

        if ($CurrentAccount?.AccountId != Account.AccountId) CurrentTransactions.set([]);
        CurrentAccount.set(Account);
        if (Account.Permissions?.Transactions) LoadTransactions(Account.AccountId);
    };

    const OpenSubTab = (Tab) => {
        if (Tab.Id != 'History' && !Tab.Allowed) return;
        SubTab = Tab.Id;
    };

    const OnDone = (Event) => {
        if (Event.detail.Cash != undefined) Cash.set(Event.detail.Cash);
        SubTab = 'History';
        if (CanSeeHistory) LoadTransactions(Event.detail.AccountId);
    };

    const OnKeyDown = (Event) => {
        if (!Visible || $ModalData.Show) return;
        if (['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement?.tagName)) return;

        const Key = Event.key.toLowerCase();
        if (Key == 'q' || Key == 'e') {
            const Next = MainTabs.indexOf(Tab) + (Key == 'e' ? 1 : -1);
            Tab = MainTabs[(Next + MainTabs.length) % MainTabs.length];
        } else if (Tab == 'Accounts' && (Key == 'arrowdown' || Key == 'arrowup')) {
            Event.preventDefault();
            Highlight = Math.min(Math.max(Highlight + (Key == 'arrowdown' ? 1 : -1), 0), Accounts.length - 1);
        } else if (Tab == 'Accounts' && Key == 'enter' && Accounts[Highlight]) {
            SelectAccount(Accounts[Highlight], Highlight);
        }
    };
</script>

<svelte:window on:keydown={OnKeyDown} />

<AppWrapper AppName="Financials" Focused={Visible}>
    {#if Visible}
        <div class="root">
            <header>
                <div class="logo">FL<span>EE</span>CA</div>

                <nav>
                    <span class="key">Q</span>
                    <button class="nav-tab" class:active={Tab == 'Accounts'} on:click={() => Tab = 'Accounts'}>Accounts</button>
                    <button class="nav-tab" class:active={Tab == 'Bills'} on:click={() => Tab = 'Bills'}>
                        Bills
                        {#if Bills.length > 0}<em class="badge">{Bills.length}</em>{/if}
                    </button>
                    <span class="key">E</span>
                </nav>

                <div class="cash">
                    <small>Cash on hand</small>
                    <strong>{FormatMoney($Cash)}</strong>
                    {#if Owner}<span>Welcome, {Owner}</span>{/if}
                </div>
            </header>

            {#if Tab == 'Accounts'}
                <main>
                    <aside class="panel sidebar">
                        <h2 class="panel-title">Accounts</h2>

                        <ul>
                            {#each Accounts as Account, Index (Account.AccountId)}
                                <li>
                                    <button
                                        class="account"
                                        class:selected={Selected.AccountId == Account.AccountId}
                                        class:highlight={Highlight == Index}
                                        class:disabled={!Account.Active}
                                        on:click={() => SelectAccount(Account, Index)}
                                    >
                                        <div>
                                            <strong>{Account.Name}</strong>
                                            <span>{Account.Type} · {Account.Owner} · #{Account.AccountId}</span>
                                        </div>
                                        <b>{FormatMoney(Account.Balance)}</b>
                                    </button>
                                </li>
                            {/each}
                        </ul>

                        <div class="total">
                            <span>Total balance</span>
                            <strong>{FormatMoney(TotalBalance)}</strong>
                        </div>
                    </aside>

                    <section class="panel detail">
                        <div class="detail-head">
                            <h1>
                                {Selected.Name}
                                <small>{Selected.Type} · #{Selected.AccountId}</small>
                            </h1>
                            <div class="balance">Account balance: <strong>{FormatMoney(Selected.Balance)}</strong></div>
                        </div>

                        <div class="detail-body">
                            <div class="tabs">
                                {#each SubTabs as Item (Item.Id)}
                                    <button
                                        class="tab"
                                        class:active={SubTab == Item.Id}
                                        class:locked={Item.Id != 'History' && !Item.Allowed}
                                        on:click={() => OpenSubTab(Item)}
                                    >{Item.Id}</button>
                                {/each}
                            </div>

                            {#if SubTab == 'History'}
                                <input class="search" type="text" placeholder="Search transactions..." bind:value={Search} />

                                <div class="chips">
                                    {#each Filters as Item (Item.Id)}
                                        <button class="chip" class:active={Filter == Item.Id} on:click={() => { Filter = Item.Id; Limit = 50; }}>{Item.Label}</button>
                                    {/each}
                                    <button class="chip export" on:click={() => ModalData.set({ AccountId: Selected.AccountId, Type: "Export", Show: true })}>Export</button>
                                </div>

                                <div class="table-head">
                                    <span>Description</span>
                                    <span>Recipient</span>
                                    <span>Amount</span>
                                </div>

                                <div class="rows">
                                    {#if CanSeeHistory}
                                        {#each Rows.slice(0, Limit) as Transaction (Transaction.Id)}
                                            <div class="row">
                                                <div class="desc">
                                                    <strong>{Transaction.Message || TransactionVerb(Transaction.TransactionType, Transaction.IsNegative)}</strong>
                                                    <span>{TimeAgo(Transaction.Timestamp)} · {TransactionVerb(Transaction.TransactionType, Transaction.IsNegative)}</span>
                                                </div>
                                                <span class="recipient">{Transaction.Receiver || '–'}</span>
                                                <b class="amount">{Transaction.IsNegative ? '-' : '+'}{FormatMoney(Transaction.Amount)}</b>
                                            </div>
                                        {/each}

                                        {#if Rows.length > Limit}
                                            <button class="more" on:click={() => Limit += 50}>Load more</button>
                                        {/if}
                                    {:else}
                                        <p class="empty">You don't have access to this account's transactions.</p>
                                    {/if}
                                </div>
                            {:else}
                                <ActionForm Mode={SubTab} Account={Selected} Cash={$Cash} on:done={OnDone} />
                            {/if}
                        </div>
                    </section>
                </main>
            {:else}
                <main>
                    <section class="panel detail">
                        <div class="detail-head">
                            <h1>Bills</h1>
                            <div class="balance">Outstanding: <strong>{Bills.length}</strong></div>
                        </div>

                        <div class="detail-body">
                            <div class="table-head">
                                <span>Description</span>
                                <span>From</span>
                                <span>Amount</span>
                            </div>

                            <div class="rows">
                                {#each Bills as Bill, Index (Bill.Id ?? Index)}
                                    <div class="row">
                                        <div class="desc">
                                            <strong>{Bill.Description || Bill.Message || 'Bill'}</strong>
                                            <span>{TimeAgo(Bill.Timestamp)} · Due</span>
                                        </div>
                                        <span class="recipient">{Bill.Sender || '–'}</span>
                                        <b class="amount">{FormatMoney(Bill.Amount)}</b>
                                    </div>
                                {:else}
                                    <p class="empty">You have no outstanding bills.</p>
                                {/each}
                            </div>
                        </div>
                    </section>
                </main>
            {/if}

            <footer>
                <span class="brand">Fleeca · FDIC Insured · Member DIC</span>

                <div class="hints">
                    <span><kbd>↕</kbd> Move</span>
                    <i>/</i>
                    <span><kbd>↵</kbd> Select</span>
                    <i>/</i>
                    <span><kbd>ESC</kbd> Close</span>
                </div>
            </footer>

            {#if $ModalData.Type == 'Export' && $ModalData.Show}
                <Export />
            {/if}
        </div>
    {/if}
</AppWrapper>

<style>
    .root {
        --u: calc(100vh / 1080);
        --green: #22a54b;
        --panel: #0d0d0d;
        --line: rgba(255, 255, 255, 0.06);

        position: absolute;
        inset: 0;
        display: flex;
        flex-direction: column;
        padding: calc(48 * var(--u)) calc(62 * var(--u)) calc(34 * var(--u));
        box-sizing: border-box;
        overflow: hidden;
        font-family: 'Barlow Semi Condensed', Roboto, sans-serif;
        color: #fff;
        background:
            radial-gradient(ellipse at 50% 35%, rgba(20, 30, 22, 0.55), transparent 70%),
            rgba(6, 7, 6, 0.9);
        backdrop-filter: blur(6px);
    }

    .root :global(button) {
        font-family: inherit;
    }

    /* ---------- Header ---------- */
    header {
        position: relative;
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        height: calc(88 * var(--u));
    }

    .logo {
        font-size: calc(52 * var(--u));
        font-style: italic;
        font-weight: 800;
        line-height: 1;
        letter-spacing: -0.04em;
        text-transform: uppercase;
    }

    .logo span {
        color: var(--green);
    }

    nav {
        position: absolute;
        left: 50%;
        top: calc(8 * var(--u));
        display: flex;
        align-items: center;
        gap: calc(12 * var(--u));
        transform: translateX(-50%);
    }

    .key {
        display: grid;
        place-items: center;
        width: calc(34 * var(--u));
        height: calc(34 * var(--u));
        border: 1px solid rgba(255, 255, 255, 0.55);
        border-radius: calc(4 * var(--u));
        font-size: calc(17 * var(--u));
        font-style: italic;
        font-weight: 700;
    }

    .nav-tab {
        display: flex;
        align-items: center;
        gap: calc(8 * var(--u));
        height: calc(38 * var(--u));
        padding: 0 calc(16 * var(--u));
        border: 0;
        border-radius: calc(4 * var(--u));
        background: transparent;
        font-size: calc(17 * var(--u));
        font-weight: 700;
        letter-spacing: 0.02em;
        text-transform: uppercase;
        color: rgba(255, 255, 255, 0.9);
        cursor: pointer;
    }

    .nav-tab.active {
        background: var(--green);
        color: #fff;
    }

    .badge {
        display: grid;
        place-items: center;
        min-width: calc(18 * var(--u));
        height: calc(18 * var(--u));
        border-radius: 999px;
        background: #e5484d;
        font-size: calc(11 * var(--u));
        font-style: normal;
        font-weight: 700;
    }

    .cash {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        text-align: right;
    }

    .cash small {
        font-size: calc(14 * var(--u));
        font-weight: 700;
        letter-spacing: 0.02em;
        text-transform: uppercase;
        color: rgba(255, 255, 255, 0.85);
    }

    .cash strong {
        font-size: calc(36 * var(--u));
        font-weight: 700;
        line-height: 1.05;
    }

    .cash span {
        font-size: calc(15 * var(--u));
        color: rgba(255, 255, 255, 0.75);
    }

    /* ---------- Layout ---------- */
    main {
        flex: 1;
        display: flex;
        gap: calc(24 * var(--u));
        min-height: 0;
        margin-top: calc(2 * var(--u));
    }

    .panel {
        display: flex;
        flex-direction: column;
        min-height: 0;
        background: var(--panel);
    }

    /* ---------- Sidebar ---------- */
    .sidebar {
        width: calc(384 * var(--u));
        flex: none;
    }

    .panel-title {
        margin: 0;
        padding: calc(14 * var(--u)) calc(18 * var(--u));
        font-size: calc(24 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        background: #080808;
    }

    .sidebar ul {
        flex: 1;
        margin: 0;
        padding: 0;
        list-style: none;
        overflow-y: auto;
        scrollbar-width: none;
    }

    .account {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: calc(12 * var(--u));
        width: 100%;
        padding: calc(13 * var(--u)) calc(18 * var(--u));
        border: 0;
        border-left: calc(3 * var(--u)) solid transparent;
        background: transparent;
        text-align: left;
        color: #fff;
        cursor: pointer;
    }

    .account.highlight {
        background: rgba(255, 255, 255, 0.04);
    }

    .account.selected {
        border-left-color: var(--green);
        background: #171717;
    }

    .account.disabled {
        opacity: 0.4;
        cursor: not-allowed;
    }

    .account strong {
        display: block;
        font-size: calc(20 * var(--u));
        font-weight: 600;
    }

    .account span {
        display: block;
        font-size: calc(13 * var(--u));
        color: rgba(255, 255, 255, 0.6);
    }

    .account b {
        font-size: calc(20 * var(--u));
        font-weight: 600;
        white-space: nowrap;
    }

    .total {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: calc(18 * var(--u));
        background: #080808;
        font-size: calc(18 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
    }

    .total strong {
        font-size: calc(20 * var(--u));
    }

    /* ---------- Detail ---------- */
    .detail {
        flex: 1;
        min-width: 0;
    }

    .detail-head {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: calc(14 * var(--u)) calc(18 * var(--u));
        background: #080808;
    }

    .detail-head h1 {
        display: flex;
        align-items: baseline;
        gap: calc(10 * var(--u));
        margin: 0;
        font-size: calc(30 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
    }

    .detail-head h1 small {
        font-size: calc(14 * var(--u));
        font-weight: 600;
        color: rgba(255, 255, 255, 0.6);
    }

    .balance {
        font-size: calc(17 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
    }

    .balance strong {
        font-size: calc(26 * var(--u));
    }

    .detail-body {
        flex: 1;
        display: flex;
        flex-direction: column;
        min-height: 0;
        padding: calc(4 * var(--u)) calc(24 * var(--u)) 0;
    }

    .tabs {
        display: flex;
        gap: calc(10 * var(--u));
        padding: calc(14 * var(--u)) 0 calc(20 * var(--u));
    }

    .tab {
        height: calc(38 * var(--u));
        padding: 0 calc(20 * var(--u));
        border: 0;
        border-radius: calc(4 * var(--u));
        background: #060606;
        font-size: calc(17 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        color: #fff;
        cursor: pointer;
    }

    .tab.active {
        background: var(--green);
    }

    .tab.locked {
        opacity: 0.35;
        cursor: not-allowed;
    }

    .search {
        height: calc(44 * var(--u));
        padding: 0 calc(18 * var(--u));
        border: 1px solid var(--line);
        border-radius: calc(6 * var(--u));
        background: #181818;
        font: inherit;
        font-size: calc(19 * var(--u));
        color: #fff;
        outline: 0;
    }

    .search::placeholder {
        color: rgba(255, 255, 255, 0.45);
    }

    .search:focus {
        border-color: var(--green);
    }

    .chips {
        display: flex;
        gap: calc(10 * var(--u));
        margin: calc(18 * var(--u)) 0 calc(20 * var(--u));
    }

    .chip {
        height: calc(32 * var(--u));
        padding: 0 calc(18 * var(--u));
        border: 0;
        border-radius: 999px;
        background: #060606;
        font-size: calc(14 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        color: #fff;
        cursor: pointer;
    }

    .chip.active {
        background: var(--green);
    }

    .chip.export {
        margin-left: auto;
        background: transparent;
        border: 1px solid rgba(255, 255, 255, 0.2);
    }

    /* ---------- Table ---------- */
    .table-head,
    .row {
        display: grid;
        grid-template-columns: 1fr 30% 20%;
        align-items: center;
    }

    .table-head {
        padding: 0 calc(18 * var(--u)) calc(10 * var(--u)) calc(18 * var(--u));
        border-bottom: 1px solid var(--line);
        font-size: calc(13 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        color: rgba(255, 255, 255, 0.85);
    }

    .table-head span:last-child,
    .amount {
        text-align: right;
    }

    .rows {
        flex: 1;
        overflow-y: auto;
        scrollbar-width: none;
    }

    .rows::-webkit-scrollbar,
    .sidebar ul::-webkit-scrollbar {
        display: none;
    }

    .row {
        height: calc(66 * var(--u));
        padding: 0 calc(18 * var(--u));
        border-bottom: 1px solid var(--line);
    }

    .desc strong {
        display: block;
        font-size: calc(20 * var(--u));
        font-weight: 600;
    }

    .desc span {
        font-size: calc(13 * var(--u));
        color: rgba(255, 255, 255, 0.55);
    }

    .recipient {
        font-size: calc(18 * var(--u));
        color: rgba(255, 255, 255, 0.7);
    }

    .amount {
        padding-right: calc(8 * var(--u));
        font-size: calc(22 * var(--u));
        font-weight: 700;
    }

    .more {
        display: block;
        margin: calc(16 * var(--u)) auto;
        padding: calc(8 * var(--u)) calc(22 * var(--u));
        border: 0;
        border-radius: 999px;
        background: var(--green);
        font-size: calc(14 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        color: #fff;
        cursor: pointer;
    }

    .empty {
        margin: calc(40 * var(--u)) 0;
        text-align: center;
        font-size: calc(18 * var(--u));
        color: rgba(255, 255, 255, 0.45);
    }

    /* ---------- Footer ---------- */
    footer {
        display: flex;
        align-items: flex-end;
        justify-content: space-between;
        height: calc(54 * var(--u));
        padding-top: calc(14 * var(--u));
    }

    .brand {
        font-size: calc(12 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        color: rgba(255, 255, 255, 0.6);
    }

    .hints {
        display: flex;
        align-items: center;
        gap: calc(12 * var(--u));
        font-size: calc(21 * var(--u));
        font-style: italic;
        font-weight: 700;
        text-transform: uppercase;
    }

    .hints span {
        display: flex;
        align-items: center;
        gap: calc(10 * var(--u));
    }

    .hints i {
        color: rgba(255, 255, 255, 0.35);
    }

    kbd {
        display: grid;
        place-items: center;
        min-width: calc(38 * var(--u));
        height: calc(34 * var(--u));
        padding: 0 calc(6 * var(--u));
        box-sizing: border-box;
        border: 1px solid rgba(255, 255, 255, 0.55);
        border-radius: calc(4 * var(--u));
        background: #0a0a0a;
        font: inherit;
        font-size: calc(16 * var(--u));
    }
</style>
