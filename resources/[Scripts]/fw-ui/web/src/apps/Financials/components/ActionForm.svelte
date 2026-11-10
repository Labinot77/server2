<script>
    import { createEventDispatcher } from "svelte";
    import { SendEvent as _SendEvent } from "../../../utils/Utils";
    import { FormatMoney } from "../format";
    const SendEvent = (Event, Parameters, Callback) => _SendEvent(Event, Parameters, Callback, "fw-financials");

    // 'Deposit' | 'Withdraw' | 'Transfer'
    export let Mode = 'Deposit';
    export let Account = {};
    export let Cash = 0;

    const Dispatch = createEventDispatcher();

    let Amount = '';
    let Comment = '';
    let Target = '';
    let Loading = false;
    let Error = '';

    const Copy = {
        Deposit: { Title: 'Deposit cash', Hint: 'Move cash from your pocket into this account.', Button: 'Deposit' },
        Withdraw: { Title: 'Withdraw cash', Hint: 'Take cash out of this account.', Button: 'Withdraw' },
        Transfer: { Title: 'Transfer money', Hint: 'Send money to another account or citizen.', Button: 'Transfer' },
    };

    // Reset when switching between Deposit / Withdraw / Transfer
    $: Mode, Reset();
    const Reset = () => { Amount = ''; Comment = ''; Target = ''; Error = ''; };

    $: Value = Math.floor(Number(Amount));
    $: Source = Mode == 'Deposit' ? Cash : Account.Balance;
    $: Valid = Value > 0 && (Mode != 'Transfer' || String(Target).trim() != '');

    const Submit = () => {
        if (!Valid || Loading) return;

        if (Mode != 'Deposit' && Value > Account.Balance) return Error = 'Insufficient funds in this account.';
        if (Mode == 'Deposit' && Value > Cash) return Error = 'You do not have that much cash on hand.';

        Error = '';
        Loading = true;

        const Payload = { AccountId: Account.AccountId, Amount: Value, Comment };
        if (Mode == 'Transfer') Payload.Target = String(Target).trim();

        SendEvent(`Financials/${Mode}`, Payload, (Success, Data) => {
            Loading = false;

            // Transfer answers with a plain boolean, the others with { Cash }
            if (!Success || Data === false) return Error = `${Mode} failed. Check the details and try again.`;

            Dispatch('done', { Mode, Cash: Data?.Cash, AccountId: Account.AccountId });
            Reset();
        });
    };
</script>

<form class="form" on:submit|preventDefault={Submit}>
    <div class="form-head">
        <h2>{Copy[Mode].Title}</h2>
        <p>{Copy[Mode].Hint}</p>
    </div>

    <div class="form-meta">
        <span>{Mode == 'Deposit' ? 'Cash on hand' : 'Available balance'}</span>
        <strong>{FormatMoney(Source)}</strong>
    </div>

    <label>
        <span>Amount</span>
        <div class="field">
            <i>$</i>
            <input type="number" min="1" step="1" placeholder="0" bind:value={Amount} autocomplete="off" />
        </div>
    </label>

    {#if Mode == 'Transfer'}
        <label>
            <span>Recipient (Citizen ID or account number)</span>
            <div class="field">
                <i>#</i>
                <input type="text" placeholder="e.g. 12345678" bind:value={Target} autocomplete="off" />
            </div>
        </label>
    {/if}

    <label>
        <span>Comment</span>
        <div class="field">
            <i>//</i>
            <input type="text" maxlength="100" placeholder="Optional" bind:value={Comment} autocomplete="off" />
        </div>
    </label>

    {#if Error}<p class="error">{Error}</p>{/if}

    <button type="submit" disabled={!Valid || Loading}>
        {Loading ? 'Processing…' : Copy[Mode].Button}
    </button>
</form>

<style>
    .form {
        display: flex;
        flex-direction: column;
        gap: calc(18 * var(--u));
        width: calc(560 * var(--u));
        max-width: 100%;
        padding: calc(30 * var(--u)) calc(30 * var(--u)) 0;
    }

    .form-head h2 {
        margin: 0;
        font-size: calc(28 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        color: #fff;
    }

    .form-head p {
        margin: calc(4 * var(--u)) 0 0;
        font-size: calc(17 * var(--u));
        color: rgba(255, 255, 255, 0.5);
    }

    .form-meta {
        display: flex;
        justify-content: space-between;
        align-items: baseline;
        padding: calc(14 * var(--u)) calc(18 * var(--u));
        border-radius: calc(8 * var(--u));
        background: rgba(255, 255, 255, 0.04);
        font-size: calc(17 * var(--u));
        color: rgba(255, 255, 255, 0.55);
    }

    .form-meta strong {
        font-size: calc(24 * var(--u));
        font-weight: 700;
        color: #fff;
    }

    label {
        display: flex;
        flex-direction: column;
        gap: calc(8 * var(--u));
    }

    label > span {
        font-size: calc(14 * var(--u));
        font-weight: 600;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        color: rgba(255, 255, 255, 0.55);
    }

    .field {
        display: flex;
        align-items: center;
        gap: calc(12 * var(--u));
        height: calc(46 * var(--u));
        padding: 0 calc(16 * var(--u));
        border: 1px solid rgba(255, 255, 255, 0.07);
        border-radius: calc(8 * var(--u));
        background: rgba(255, 255, 255, 0.04);
        transition: border-color 150ms;
    }

    .field:focus-within {
        border-color: #22a54b;
    }

    .field i {
        font-style: normal;
        font-weight: 700;
        color: #22a54b;
    }

    input {
        flex: 1;
        min-width: 0;
        border: 0;
        outline: 0;
        background: transparent;
        font: inherit;
        font-size: calc(19 * var(--u));
        color: #fff;
    }

    input::placeholder {
        color: rgba(255, 255, 255, 0.28);
    }

    input[type="number"]::-webkit-inner-spin-button {
        display: none;
    }

    .error {
        margin: 0;
        font-size: calc(16 * var(--u));
        color: #ff6b6b;
    }

    button {
        height: calc(50 * var(--u));
        border: 0;
        border-radius: calc(8 * var(--u));
        background: #22a54b;
        font: inherit;
        font-size: calc(18 * var(--u));
        font-weight: 700;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        color: #fff;
        cursor: pointer;
        transition: background 150ms, opacity 150ms;
    }

    button:hover:not(:disabled) {
        background: #2cbf5a;
    }

    button:disabled {
        opacity: 0.35;
        cursor: not-allowed;
    }
</style>
