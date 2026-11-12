<script>
    export let Label = "";
    export let Icon = "question";
    export let Color = ["#5a5d66", "#2c2e33"];
    export let Glyph = "white";
    export let Tooltip = "";
    export let HasUnread = false;
</script>

<div class="app" data-tooltip={Tooltip || null} on:keyup on:click>
    <div class="app-icon" style="background: linear-gradient(160deg, {Color[0]}, {Color[1]}); color: {Glyph}">
        <i class="fas fa-{Icon}" />
        {#if HasUnread}<div class="app-unread" />{/if}
    </div>
    <p>{Label}</p>
</div>

<style>
    .app {
        display: flex;
        flex-direction: column;
        align-items: center;
        cursor: pointer;
    }

    .app-icon {
        position: relative;
        width: 4.6vh;
        height: 4.6vh;
        border-radius: 1.2vh;
        display: grid;
        place-items: center;
        font-size: 2.1vh;
        box-shadow: 0 0.3vh 0.8vh rgba(0, 0, 0, 0.35), inset 0 0.1vh 0 rgba(255, 255, 255, 0.25);
        transition: transform 120ms ease;
    }

    .app:hover .app-icon { transform: scale(1.07); }

    .app-unread {
        position: absolute;
        top: -0.4vh;
        right: -0.4vh;
        width: 1.2vh;
        height: 1.2vh;
        border-radius: 50%;
        background: #ff3b30;
        border: 0.15vh solid white;
    }

    p {
        margin: 0.45vh 0 0;
        font-size: 1vh;
        font-weight: 500;
        white-space: nowrap;
        text-shadow: 0 0.1vh 0.3vh rgba(0, 0, 0, 0.8);
    }
</style>
