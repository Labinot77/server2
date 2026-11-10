<script>
    export let Icon = "heart";
    export let Label = "";
    export let Value = 0;
    export let Low = 20;
</script>

<div class="bar">
    <div class="bar-label">
        <i class="fas fa-{Icon}"></i>
        <span>{Label}</span>
    </div>
    <div class="bar-track">
        <div class="bar-fill" class:low={Value < Low} style="width: {Value}%"></div>
    </div>
</div>

<style>
    .bar {
        position: relative;
        isolation: isolate;
        display: flex;
        width: 10.65vh;
        height: 3.05vh;
        overflow: hidden;
        background: rgba(15, 15, 15, 0.8);
    }

    .bar-label {
        position: relative;
        z-index: 2;
        display: flex;
        width: 100%;
        height: 100%;
        align-items: center;
        justify-content: center;
        gap: 0.56vh;
        color: #fff;
        font-family: 'Barlow Semi Condensed', Arial, sans-serif;
        font-size: 1.39vh;
        font-style: italic;
        font-weight: 800;
        letter-spacing: 0.05vh;
        mix-blend-mode: difference;
    }

    .bar-track {
        position: absolute;
        inset: 0;
        z-index: 1;
    }

    .bar-fill {
        height: 100%;
        background: #fff;
        transition: width 0.3s ease, background-color 0.2s ease;
    }

    .bar-fill.low { background: #e74c3c; }
</style>