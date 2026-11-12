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
        align-items: flex-end;
        justify-content: space-between;
        padding: 4vh 6% 1.2vh;
        font-size: 1.8vh;
    }

    h1 {
        margin: 0;
        font-size: 2.8vh;
        font-weight: 700;
        letter-spacing: -0.03vh;
    }
</style>
