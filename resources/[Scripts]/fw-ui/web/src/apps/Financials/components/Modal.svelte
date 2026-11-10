<div class="financials-input-wrapper">
    <div class="financials-input-container" style={$$restProps.style}>
        <slot/>
    </div>
</div>

<style>
    .financials-input-wrapper {
        position: absolute;
        inset: 0;
        z-index: 100;
        background-color: rgba(0, 0, 0, 0.6);
        backdrop-filter: blur(3px);
    }

    .financials-input-container {
        position: relative;
        top: 50%;
        left: 0;
        right: 0;
        transform: translateY(-50%);
        clear: both;
        overflow-y: auto;
        margin: 0 auto;
        width: calc(520 * var(--u));
        height: max-content;
        max-height: 70%;
        padding: calc(24 * var(--u)) calc(32 * var(--u));
        box-sizing: border-box;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: calc(8 * var(--u));
        background-color: #0d0d0d;
        font-family: 'Barlow Semi Condensed', Roboto, sans-serif;
    }

    .financials-input-container::-webkit-scrollbar {
        display: none
    }

    :global(.financials-input-title) {
        margin-bottom: calc(24 * var(--u));
        width: 100%
    }

    :global(.financials-input-title>p) {
        color: white;
        font-size: calc(26 * var(--u));
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0;
        margin: 0;
        text-align: center
    }

    :global(.financials-input-container > .financials-input-buttons) {
        display: flex;
        justify-content: space-between;
        height: 4vh;
        width: 100%;
        margin-top: 3.5vh
    }
</style>
