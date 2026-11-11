<div class="key-hints">
    <div class="hint">
        <span class="key icon"><i class="fas fa-arrows-alt"></i></span>
        <span>Move</span>
    </div>
    <span class="divider">/</span>
    <div class="hint">
        <span class="key">Q</span><span class="slash">/</span><span class="key">E</span>
        <span>Switch Filter</span>
    </div>
    <span class="divider">/</span>
    <div class="hint">
        <span class="key icon"><i class="fas fa-level-down-alt fa-rotate-90"></i></span>
        <span>Select</span>
    </div>
    <span class="divider">/</span>
    <div class="hint">
        <span class="key wide">Esc</span>
        <span>Close</span>
    </div>
</div>

<style>
    .key-hints {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 1.1vh;
        padding: 1.4vh 1vh;
        background: linear-gradient(to top, rgba(0, 0, 0, 0.65), rgba(0, 0, 0, 0.25));
        font-size: 1.2vh;
        font-weight: 700;
        font-style: italic;
        text-transform: uppercase;
        white-space: nowrap;
    }

    .hint {
        display: flex;
        align-items: center;
        gap: 0.7vh;
    }

    .key {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        min-width: 2.2vh;
        height: 2.2vh;
        padding: 0 0.4vh;
        background: var(--text);
        color: #111;
        border-radius: 0.2vh;
        font-style: normal;
        font-size: 1.2vh;
    }

    .key.wide {
        padding: 0 0.7vh;
    }

    .key.icon {
        font-size: 1.1vh;
    }

    .slash,
    .divider {
        color: var(--text-muted);
        font-style: normal;
    }
</style>
