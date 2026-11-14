<script>
    export let Title = "";
</script>

<div class="app-header">
    <h1>{Title}</h1>
    <slot />
</div>

<style>
    .app-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        min-height: 4vh;
        padding: 3.9vh 1vh 0.7vh 1.5vh;
        font-size: 1.6vh;
    }

    h1 {
        margin: 0;
        font-size: 1.6vh;
        font-weight: 700;
    }
</style>
