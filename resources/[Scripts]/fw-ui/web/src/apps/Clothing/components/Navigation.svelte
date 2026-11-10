<script>
    import Icon from "./Icon.svelte";
    import { LocalImage } from "../images";

    export let Tabs = [];
    export let Active = 0;
    export let Select = (Index) => {};
    export let Money = { Cash: 0, Bank: 0 };
    export let ShowMoney = true;

    const Format = (N) => Number(N || 0).toLocaleString("en-US");
</script>

<div class="topbar">
    <div class="tabs">
        {#if Tabs.length > 1}
            <div class="keycap left"><img src={LocalImage("keys/keyboard_q.png")} alt="Q" /></div>
        {/if}

        <div class="tab-list">
            {#each Tabs as Tab, Index}
                <button class="tab" class:active={Active == Index} on:click={() => Select(Index)}>{Tab}</button>
            {/each}
        </div>

        {#if Tabs.length > 1}
            <div class="keycap right"><img src={LocalImage("keys/keyboard_e.png")} alt="E" /></div>
        {/if}
    </div>

    {#if ShowMoney}
        <div class="economy">
            <div class="money cash"><span style="font-size: 22px; line-height: 1;">$</span><span style="margin-top: 2px;">{Format(Money.Cash)}</span></div>
            <div class="money bank"><Icon Name="bank" Size={20} /><span style="margin-top: 2px;">{Format(Money.Bank)}</span></div>
        </div>
    {/if}
</div>

<style>
    .topbar {
        position: absolute; top: 24px; left: 48px; right: 48px;
        display: flex; justify-content: space-between; align-items: flex-start;
    }

    .tabs { display: flex; align-items: center; gap: 4px; }
    .tab-list { display: flex; gap: 2px; }

    .tab {
        padding: 6px 20px; font-size: 19px; font-weight: 700; font-style: italic; letter-spacing: 0.025em;
        text-transform: uppercase; background: rgba(20, 22, 27, 0.9) !important; color: white !important; transition: background .15s;
    }
    .tab:hover { background: #3f3f46 !important; }
    .tab.active { background: white !important; color: black !important; }

    .keycap { background: #1a1c23; padding: 4px 8px; display: flex; align-items: center; justify-content: center; box-shadow: 0 10px 15px rgba(0,0,0,.3); }
    .keycap.left { border-right: 1px solid #3f3f46; }
    .keycap.right { border-left: 1px solid #3f3f46; margin-left: 4px; }
    .keycap img { width: 24px; height: 24px; object-fit: contain; pointer-events: none; }

    .economy { display: flex; gap: 6px; font-weight: 700; font-style: italic; font-size: 24px; letter-spacing: 0.025em; box-shadow: 0 25px 50px rgba(0,0,0,.4); }
    .money { display: flex; align-items: center; gap: 6px; padding: 6px 16px; min-width: 110px; justify-content: center; color: black; }
    .money.cash { background: var(--cash); }
    .money.bank { background: var(--bank); gap: 8px; }
</style>
