<script>
    import Button from "../../../lib/Button/Button.svelte";

    export let Breadcrumb = "San Andreas Parking";
    export let Title = "Garage";
    export let Subtitle = "Get vehicles from the garage";
    export let Count = 0;
    export let Total = 0;
    export let OnExit = () => {};
</script>

<div class="garage-header">
    <div class="garage-header-left">
        <p class="garage-breadcrumb">{Breadcrumb}</p>
        <div class="garage-title-row">
            <div class="garage-icon-badge">P</div>
            <div>
                <p class="garage-title">{Title}</p>
                <p class="garage-subtitle">{Subtitle}</p>
            </div>
        </div>
    </div>

    <div class="garage-header-right">
    {#if Count !== 0 && Total !== 0}
        <div class="garage-count-pill">
            <span class="garage-dot"></span>
            <span>{Count}/{Total}</span>
        </div>
        {/if}
        <div class="garage-header-buttons">
            <Button Color="default" on:click={OnExit}>Exit</Button>
        </div>
    </div>
</div>

<style>
    .garage-header {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        padding: 2vh 2.2vh 1.6vh;
        border-bottom: 0.1vh solid rgba(94, 196, 184, 0.14);
    }

    .garage-breadcrumb {
        font-size: 1.3vh;
        color: #4fd8c4;
        margin: 0 0 0.6vh 0;
        font-family: Roboto;
    }

    .garage-title-row {
        display: flex;
        align-items: center;
        gap: 1.2vh;
    }

    .garage-icon-badge {
        width: 3.6vh;
        height: 3.6vh;
        border-radius: 0.8vh;
        background: rgba(79, 216, 196, 0.1);
        border: 0.1vh solid rgba(94, 196, 184, 0.14);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 1.5vh;
        color: #4fd8c4;
        flex-shrink: 0;
        font-family: Roboto;
    }

    .garage-title {
        font-size: 2.2vh;
        font-weight: 700;
        color: white;
        margin: 0;
        line-height: 1.1;
        font-family: Roboto;
    }

    .garage-subtitle {
        font-size: 1.3vh;
        color: #5e8a86;
        margin: 0.2vh 0 0 0;
        font-family: Roboto;
    }

    .garage-header-right {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 1vh;
    }

    .garage-count-pill {
        display: flex;
        align-items: center;
        gap: 0.6vh;
        font-size: 1.3vh;
        color: #5e8a86;
        font-family: Roboto;
    }

    .garage-dot {
        width: 0.7vh;
        height: 0.7vh;
        border-radius: 50%;
        background: #4fd8c4;
        display: inline-block;
    }

    .garage-header-buttons {
        display: flex;
        gap: 0.6vh;
    }
</style>