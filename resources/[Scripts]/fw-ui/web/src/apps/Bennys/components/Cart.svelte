<script>
    import { createEventDispatcher } from "svelte";
    import { fly } from "svelte/transition";
    import { FormatPrice } from "../bennys.utils";

    export let Cart = [];
    export let Icons = {};
    export let SubHeader = "";

    const Dispatch = createEventDispatcher();
    $: Total = Cart.reduce((Sum, Item) => Sum + Item.Price, 0);
</script>

<div class="cart">
    <div class="cart-header">
        <p><i class="fas fa-shopping-cart"></i> Shopping Cart</p>
        <span>{SubHeader}</span>
    </div>

    <div class="cart-items">
        {#each Cart as Item (Item.Slot)}
            <div class="cart-item" transition:fly={{ x: 30, duration: 160 }}>
                <div class="cart-thumb">
                    {#if typeof Item.Value === "string" && Item.Value.startsWith("#")}
                        <span class="cart-swatch" style="background-color: {Item.Value}"></span>
                    {:else}
                        <i class={Icons[Item.Slot] || "fas fa-wrench"}></i>
                    {/if}
                </div>
                <div class="cart-text">
                    <p class="cart-label">{Item.Label}</p>
                    <p class="cart-meta">
                        {#if Item.Option}<span>{Item.Option}</span>{/if}
                        <span class="cart-price">{FormatPrice(Item.Price)}</span>
                    </p>
                </div>
                <button class="cart-remove" on:click={() => Dispatch("remove", Item)}>
                    <i class="fal fa-times"></i>
                </button>
            </div>
        {:else}
            <div class="cart-empty">
                <i class="fal fa-info-circle"></i>
                <p>Cart is empty</p>
            </div>
        {/each}
    </div>
</div>

<div class="payment">
    <div class="payment-total">
        <div>
            <p class="payment-label">Payment</p>
            <p class="payment-sub">Total Price</p>
        </div>
        <p class="payment-value">{"$" + Math.round(Total).toLocaleString("en-US")} <span>+ Tax</span></p>
    </div>
    <div class="payment-buttons">
        <button disabled={Cart.length === 0} on:click={() => Dispatch("checkout", "Bank")}>Pay via Banking Card</button>
        <button disabled={Cart.length === 0} on:click={() => Dispatch("checkout", "Cash")}>Pay via Cash</button>
    </div>
</div>

<style>
    .cart {
        position: absolute;
        top: 4vh;
        right: 3.5vh;
        width: 28vh;

        font-family: "Barlow Semi Condensed", sans-serif;
        color: white;
    }

    .cart-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        height: 3.6vh;
        padding: 0 1.2vh;

        background: white;
        color: var(--bennys-ink);
    }

    .cart-header > p {
        font-size: 1.6vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
    }

    .cart-header > p > i { margin-right: 0.5vh; }

    .cart-header > span {
        font-size: 1.1vh;
        font-weight: 600;
        color: rgba(11, 13, 16, 0.6);
    }

    .cart-items {
        max-height: 56vh;
        overflow-y: auto;
        overflow-x: hidden;
        background: var(--bennys-panel);
    }

    .cart-item {
        display: flex;
        align-items: center;
        gap: 1vh;
        padding: 0.7vh 0.9vh;
        border-bottom: 0.1vh solid rgba(255, 255, 255, 0.06);
    }

    .cart-thumb {
        display: flex;
        align-items: center;
        justify-content: center;
        flex: 0 0 3.3vh;
        height: 3.3vh;

        font-size: 1.4vh;
        background: rgba(255, 255, 255, 0.07);
    }

    .cart-swatch { width: 1.9vh; height: 1.9vh; border-radius: 50%; border: 0.15vh solid rgba(255, 255, 255, 0.8); }

    .cart-text { flex: 1; min-width: 0; }

    .cart-label {
        font-size: 1.3vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .cart-meta {
        display: flex;
        gap: 0.6vh;
        font-size: 1.1vh;
        font-weight: 500;
        color: var(--bennys-muted);
    }

    .cart-meta > span:first-child:not(.cart-price) {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .cart-price { color: var(--bennys-accent); font-weight: 700; white-space: nowrap; }

    .cart-remove {
        all: unset;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        flex: 0 0 2.2vh;
        height: 2.2vh;

        font-size: 1.3vh;
        color: var(--bennys-muted);
        border: 0.1vh solid rgba(255, 255, 255, 0.18);
        transition: all 120ms ease;
    }

    .cart-remove:hover { color: var(--bennys-ink); background: var(--bennys-accent); border-color: var(--bennys-accent); }

    .cart-empty {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 0.6vh;
        height: 12vh;

        font-size: 1.2vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        color: var(--bennys-muted);
    }

    .cart-empty > i { font-size: 2vh; }

    .payment {
        position: absolute;
        right: 3.5vh;
        bottom: 7vh;
        width: 28vh;

        font-family: "Barlow Semi Condensed", sans-serif;
        color: white;
    }

    .payment-total {
        display: flex;
        align-items: flex-end;
        justify-content: space-between;
        padding: 1vh 1.2vh;
        background: var(--bennys-panel);
        border-top: 0.2vh solid var(--bennys-accent);
    }

    .payment-label {
        font-size: 1.7vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        line-height: 1;
    }

    .payment-sub { font-size: 1.1vh; font-weight: 500; color: var(--bennys-muted); }

    .payment-value {
        font-size: 2.1vh;
        font-weight: 800;
        font-style: italic;
        color: var(--bennys-accent);
        line-height: 1;
    }

    .payment-value > span { font-size: 1.2vh; }

    .payment-buttons {
        display: flex;
        gap: 0.4vh;
        margin-top: 0.4vh;
    }

    .payment-buttons > button {
        all: unset;
        cursor: pointer;
        flex: 1;
        height: 3.6vh;
        text-align: center;

        font-size: 1.2vh;
        font-weight: 800;
        font-style: italic;
        text-transform: uppercase;
        color: var(--bennys-ink);
        background: white;
        transition: background 120ms ease;
    }

    .payment-buttons > button:hover:not(:disabled) { background: var(--bennys-accent); }
    .payment-buttons > button:disabled { cursor: default; opacity: 0.45; }

    ::-webkit-scrollbar { width: 0.4vh; }
    ::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.3); }
</style>
