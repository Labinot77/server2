<script>
    export let Path = [];
    export let Navigate = (NewPath) => {};
    export let CanGoBack = true;

    const Sizes = [
        "font-size: 40px; color: white; font-weight: 700;",
        "font-size: 30px; color: rgba(255,255,255,.8); font-weight: 600;",
        "font-size: 22px; color: rgba(255,255,255,.6); font-weight: 500;",
    ];
</script>

<div class="header">
    {#if Path.length > 1 && CanGoBack}
        <button class="back-btn" title="Go Back" on:click={() => Navigate(Path.slice(0, -1))}>&lt;</button>
    {/if}

    <div class="crumbs">
        {#if Path.length == 1}
            <span class="crumb" style="font-size: 36px; color: rgba(255,255,255,.45);">{Path[0]}</span>
        {:else}
            {#each Path as Step, Idx}
                <span
                    class="crumb"
                    class:link={Idx < Path.length - 1}
                    style={Sizes[Math.min(Idx, Sizes.length - 1)]}
                    on:keyup on:click={() => Idx < Path.length - 1 && Navigate(Path.slice(0, Idx + 1))}
                >{Step}</span>
            {/each}
        {/if}
    </div>
</div>
