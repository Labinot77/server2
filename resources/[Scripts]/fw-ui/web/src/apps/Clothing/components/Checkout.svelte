<script>
    import Icon from "./Icon.svelte";
    import { Tax } from "../../../stores";

    export let Total = 0;
    export let IsFree = false;
    export let Money = { Cash: 0, Bank: 0 };
    export let Modal = false; // false | "payment" | "exit"
    export let CanDiscard = true;
    export let Confirm = () => {};
    export let Pay = (Type) => {};
    export let Discard = () => {};
    export let CloseModal = () => {};

    const Format = (N) => `$${Number(N || 0).toLocaleString("en-US")}`;
    $: Free = IsFree || Total <= 0;
</script>

<div class="total-box">
    <div class="total-head">
        <span style="font-weight: 700; font-size: 18px; letter-spacing: 0.05em; font-style: italic;">TOTAL COST</span>
        <div style="display: flex; align-items: center; gap: 4px; font-weight: 700; font-size: 20px;">
            <span>{Free ? "FREE" : Format(Total)}</span>
            {#if !Free}<span style="font-size: 12px; opacity: 0.8; margin-top: 4px;">INCL. {$Tax?.Clothes ?? 0}% TAX</span>{/if}
        </div>
    </div>
    <button class="confirm" on:click={Confirm}>CONFIRM</button>
</div>

{#if Modal}
    <div class="modal enter">
        <div style="display: flex; flex-direction: column; gap: 4px; border-bottom: 1px solid rgba(255,255,255,.1); padding-bottom: 12px;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <span class="bebas italic" style="font-size: 26px; letter-spacing: 0.05em;">{Modal == "exit" ? "LEAVE STORE?" : "PAYMENT METHOD"}</span>
                <button class="x" on:click={CloseModal}>✕</button>
            </div>
            <span style="font-size: 12px; color: #a1a1aa; letter-spacing: 0.05em;">
                {Modal == "exit" ? (CanDiscard ? "Pay for your changes or leave without them" : "Save your character to continue") : "Select your payment method"}
            </span>
        </div>

        <div class="amount-row">
            <span style="font-weight: 700; font-size: 14px; color: #d4d4d8; letter-spacing: 0.05em;">TOTAL AMOUNT</span>
            <span style="font-weight: 700; font-size: 24px;">{Free ? "FREE" : Format(Total)}</span>
        </div>

        <div style="display: flex; flex-direction: column; gap: 10px;">
            {#if Free}
                <button class="method" on:click={() => Pay("Cash")}>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div class="method-icon" style="background: #34d399;"><Icon Name="check" Size={22} Stroke={3} /></div>
                        <span class="method-name">SAVE</span>
                    </div>
                </button>
            {:else}
                <button class="method" disabled={Money.Cash < Total} on:click={() => Pay("Cash")}>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div class="method-icon" style="background: white; font-size: 20px; font-weight: 700;">$</div>
                        <div style="display: flex; flex-direction: column; align-items: flex-start;">
                            <span class="method-name">CASH</span>
                            <span class="method-sub">Available: {Format(Money.Cash)}</span>
                        </div>
                    </div>
                    {#if Money.Cash < Total}<span class="insufficient">INSUFFICIENT</span>{/if}
                </button>

                <button class="method bank" disabled={Money.Bank < Total} on:click={() => Pay("Bank")}>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div class="method-icon" style="background: var(--bank);"><Icon Name="bank" Size={20} /></div>
                        <div style="display: flex; flex-direction: column; align-items: flex-start;">
                            <span class="method-name">CARD / BANK</span>
                            <span class="method-sub">Available: {Format(Money.Bank)}</span>
                        </div>
                    </div>
                    {#if Money.Bank < Total}<span class="insufficient">INSUFFICIENT</span>{/if}
                </button>
            {/if}
        </div>

        {#if Modal == "exit" && CanDiscard}
            <button class="secondary discard" on:click={Discard}>DISCARD CHANGES</button>
        {/if}
        <button class="secondary" on:click={CloseModal}>{Modal == "exit" ? "KEEP SHOPPING" : "CANCEL"}</button>
    </div>
{/if}

<style>
    .total-box { position: absolute; bottom: 112px; right: 48px; width: 428px; display: flex; flex-direction: column; box-shadow: 0 25px 50px rgba(0,0,0,.4); }
    .total-head { color: #041418; padding: 10px 16px; display: flex; justify-content: space-between; align-items: center; background: linear-gradient(90deg, var(--accent), var(--accent-2)); }
    .confirm { padding: 10px 0; background: rgba(13, 15, 18, 0.95) !important; color: white !important; font-weight: 700; font-size: 18px; letter-spacing: 0.1em; transition: all .15s; margin-top: 4px; }
    .confirm:hover { background: white !important; color: black !important; }

    .modal { position: absolute; right: 48px; bottom: 224px; width: 428px; z-index: 100; background: rgba(17, 19, 23, 0.95); border: 1px solid rgba(255,255,255,.1); padding: 20px; display: flex; flex-direction: column; gap: 16px; box-shadow: 0 25px 50px rgba(0,0,0,.5); }
    .x { width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; color: rgba(255,255,255,.5) !important; background: rgba(255,255,255,.05) !important; font-weight: 700; }
    .x:hover { color: white !important; background: rgba(255,255,255,.1) !important; }
    .amount-row { background: #181a20; padding: 14px; display: flex; justify-content: space-between; align-items: center; border: 1px solid rgba(255,255,255,.05); }
    .method { width: 100%; padding: 14px; display: flex; align-items: center; justify-content: space-between; background: #181a20 !important; border: 1px solid rgba(255,255,255,.1) !important; transition: all .15s; text-align: left; }
    .method:hover:not(:disabled) { background: #20232b !important; border-color: white !important; }
    .method.bank:hover:not(:disabled) { border-color: var(--bank) !important; }
    .method:disabled { opacity: 0.5; cursor: not-allowed; background: rgba(24,26,32,.4) !important; }
    .method-icon { width: 40px; height: 40px; color: black; display: flex; align-items: center; justify-content: center; }
    .method-name { font-weight: 700; font-size: 16px; letter-spacing: 0.05em; }
    .method-sub { font-size: 12px; color: #a1a1aa; }
    .insufficient { font-size: 12px; font-weight: 700; color: #f87171; }
    .secondary { width: 100%; padding: 10px 0; background: #27272a !important; font-weight: 700; font-size: 14px; letter-spacing: 0.1em; transition: background .15s; }
    .secondary:hover { background: #3f3f46 !important; }
    .secondary.discard { background: rgba(127, 29, 29, .5) !important; }
    .secondary.discard:hover { background: rgba(153, 27, 27, .8) !important; }
</style>
