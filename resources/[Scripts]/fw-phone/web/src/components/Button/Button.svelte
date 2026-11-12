<script>
    import Ripple from '@smui/ripple';

    export var Color = 'primary';
</script>

<div {...$$restProps} on:keyup on:click use:Ripple={{ surface: true, active: true }} class="ui-button {Color} {$$restProps?.class}">
    <slot></slot>
</div>

<style>
    .ui-button {
        position: relative;
        float: left;
        width: max-content;
        margin: 0.5vh;
        padding: 0.8vh 1.4vh;
        border-radius: 1vh;
        background: var(--phone-accent);
        color: white;
        font-family: Roboto;
        font-weight: 600;
        font-size: 1.25vh;
        user-select: none;
        cursor: pointer;
        transition: filter 150ms;
    }

    .ui-button:hover { filter: brightness(1.12); }
    .ui-button.default { background: rgba(255, 255, 255, 0.14); }
    .ui-button.error { background: var(--phone-red); }
    .ui-button.warning { background: var(--phone-orange); }
    .ui-button.success { background: var(--phone-green); }
    .ui-button.disabled { background: rgba(255, 255, 255, 0.08); color: rgba(255, 255, 255, 0.3); cursor: not-allowed; filter: none; }
</style>
