<script>
    import { onMount } from "svelte";
    import { CopyToClipboard, FormatCurrency, SendEvent } from "../../../utils/Utils";

    import AppWrapper from "../components/AppWrapper.svelte";
    import AppHeader from "../components/AppHeader.svelte";
    import Empty from "../components/Empty.svelte";

    const TypeLabels = { Standaard: "Personal" };

    let Accounts = [];
    let Loading = true;
    let Copied = "";

    const Load = () => {
        Loading = true;
        SendEvent("Bank/GetAccounts", {}, (Success, Data) => {
            Loading = false;
            if (Success && Array.isArray(Data)) Accounts = Data;
        });
    };

    const Copy = (Id) => {
        CopyToClipboard(Id);
        Copied = Id;
        setTimeout(() => (Copied = ""), 1500);
    };

    $: Total = Accounts.reduce((Sum, A) => Sum + (Number(A.Balance) || 0), 0);

    onMount(Load);
</script>

<AppWrapper>
    <AppHeader Title="Bank">
        <i class="fas fa-sync-alt refresh" class:spin={Loading} data-tooltip="Refresh" on:keyup on:click={Load} />
    </AppHeader>

    <div class="bank">
        <div class="total">
            <p>Total Balance</p>
            <h2>{FormatCurrency.format(Total)}</h2>
            <span>{Accounts.length} account{Accounts.length == 1 ? "" : "s"}</span>
        </div>

        {#if !Loading && Accounts.length == 0}
            <Empty />
        {/if}

        {#each Accounts as Account (Account.AccountId)}
            <div class="account">
                <div class="account-top">
                    <div class="account-icon"><i class="fas fa-{Account.Type == "Standaard" ? "user" : "building"}" /></div>
                    <div class="account-info">
                        <p class="account-name">{Account.Name}</p>
                        <p class="muted">{TypeLabels[Account.Type] || Account.Type} · {Account.Owner}</p>
                    </div>
                    {#if !Account.Active}<span class="frozen">Frozen</span>{/if}
                </div>
                <div class="account-bottom">
                    <p class="account-id" data-tooltip="Click to copy" on:keyup on:click={() => Copy(Account.AccountId)}>
                        <i class="fas fa-{Copied == Account.AccountId ? "check" : "copy"}" /> {Account.AccountId}
                    </p>
                    <p class="account-balance">{FormatCurrency.format(Account.Balance)}</p>
                </div>
            </div>
        {/each}
    </div>
</AppWrapper>

<style>
    p { margin: 0; }
    .muted { color: var(--phone-muted); font-size: 1.15vh; }

    .refresh { cursor: pointer; color: var(--phone-accent); }
    .spin { animation: spin 1s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }

    .bank {
        height: calc(100% - 10vh);
        padding: 0 5% 3vh;
        overflow-y: auto;
    }

    .bank::-webkit-scrollbar { display: none; }

    .total {
        margin-bottom: 1.4vh;
        padding: 1.6vh;
        border-radius: 1.6vh;
        background: linear-gradient(140deg, #2fbf71, #127a45);
        box-shadow: 0 0.8vh 2vh rgba(18, 122, 69, 0.35);
    }

    .total > p { font-size: 1.2vh; opacity: 0.85; }
    .total > h2 { margin: 0.4vh 0; font-size: 2.8vh; font-weight: 700; }
    .total > span { font-size: 1.1vh; opacity: 0.85; }

    .account {
        margin-bottom: 0.8vh;
        padding: 1.1vh;
        border-radius: var(--phone-radius);
        background: var(--phone-card);
    }

    .account-top { display: flex; align-items: center; gap: 1vh; }

    .account-icon {
        display: grid;
        place-items: center;
        width: 3.4vh;
        height: 3.4vh;
        border-radius: 1vh;
        background: rgba(47, 191, 113, 0.18);
        color: #4ade80;
        font-size: 1.5vh;
    }

    .account-info { flex: 1; min-width: 0; }
    .account-name { font-size: 1.4vh; font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

    .frozen {
        padding: 0.3vh 0.7vh;
        border-radius: 0.6vh;
        background: rgba(255, 59, 48, 0.2);
        color: var(--phone-red);
        font-size: 1vh;
        font-weight: 600;
    }

    .account-bottom {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-top: 1vh;
        padding-top: 0.9vh;
        border-top: 0.1vh solid var(--phone-line);
    }

    .account-id { font-size: 1.2vh; color: var(--phone-muted); font-family: monospace; cursor: pointer; }
    .account-balance { font-size: 1.6vh; font-weight: 700; }
</style>
