<script>
    export let Title = "";
    export let Checked = false;
    export let className = "";
</script>

<div class="ui-switch {className}" on:keyup on:click={() => (Checked = !Checked)}>
    <span>{Title}</span>
    <div class="ui-switch-track" class:on={Checked}><div class="ui-switch-thumb" /></div>
</div>

<style>
    .ui-switch {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1vh;
        width: 100%;
        margin-bottom: 1vh;
        font-size: 1.35vh;
        color: white;
        cursor: pointer;
    }

    .ui-switch-track {
        flex-shrink: 0;
        position: relative;
        width: 4.2vh;
        height: 2.5vh;
        border-radius: 1.25vh;
        background: rgba(120, 120, 128, 0.36);
        transition: background 200ms;
    }

    .ui-switch-track.on { background: var(--phone-green); }

    .ui-switch-thumb {
        position: absolute;
        top: 0.2vh;
        left: 0.2vh;
        width: 2.1vh;
        height: 2.1vh;
        border-radius: 50%;
        background: white;
        box-shadow: 0 0.2vh 0.4vh rgba(0, 0, 0, 0.3);
        transition: transform 200ms;
    }

    .ui-switch-track.on > .ui-switch-thumb { transform: translateX(1.7vh); }
</style>
