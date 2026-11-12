<script>
    export let Icon = false;
    export let Title = "";
    export let Description = "";
    export let DescriptionHtml = false;
    export let Aux = "";
    export let Notification = false;

    export let HasActions = false;
    export let HasDrawer = false;

    let ShowDrawer = false;
    const ToggleDrawer = (event) => {
        const PhoneCardDrawer = document.querySelector('.phone-card-drawer');
        if (event.target === PhoneCardDrawer || (PhoneCardDrawer && PhoneCardDrawer.contains(event.target))) return;
        ShowDrawer = !ShowDrawer;
    }
</script>

{#if !HasDrawer}
    <div class="phone-card-component" on:keyup on:click>
        {#if Notification}
            <div class="phone-card-notification phone-card-notification__{Notification}"></div>
        {/if}

        <div class="phone-card-container">
            {#if Icon}
                <div class="phone-card-icon">
                    <i class="fas fa-{Icon}" />
                </div>
            {/if}
            <div class="phone-card-details">
                <div class="phone-card-text">
                    {#if Array.isArray(Title)}
                        {#each Title as item}
                            <p>{item}</p>
                        {/each}
                    {:else}
                        <p>{Title}</p>
                    {/if}
                </div>
                <div class="phone-card-text">
                    {#if Array.isArray(Description)}
                        {#each Description as item}
                            {#if DescriptionHtml}
                                <p>{@html item}</p>
                            {:else}
                                <p>{item}</p>
                            {/if}
                        {/each}
                    {:else}
                        {#if DescriptionHtml}
                            <p>{@html Description}</p>
                        {:else}
                            <p>{Description}</p>
                        {/if}
                    {/if}
                </div>
                
            </div>
            {#if Aux}
                <div class="phone-car-details phone-card-details-aux">
                    <div class="phone-card-text">
                        <p>{Aux}</p>
                    </div>
                </div>
            {/if}

            {#if HasActions && $$slots.default}
                <div class="phone-card-actions">
                    <slot />
                    <!-- <i data-tooltip="Yeet" class="tooltip fas fa-user-slash" /> -->
                </div>
            {/if}
        </div>
    </div>
{:else}
    <div class="phone-card-component" on:keyup on:click={ToggleDrawer}>
        {#if Notification}
            <div class="phone-card-notification phone-card-notification__{Notification}"></div>
        {/if}

        <div class="phone-card-container">
            {#if Icon}
                <div class="phone-card-icon">
                    <i class="fas fa-{Icon}" />
                </div>
            {/if}
            <div class="phone-card-details">
                <div class="phone-card-text">
                    {#if Array.isArray(Title)}
                        {#each Title as item}
                            <p>{item}</p>
                        {/each}
                    {:else}
                        <p>{Title}</p>
                    {/if}
                </div>
                <div class="phone-card-text">
                    {#if Array.isArray(Description)}
                        {#each Description as item}
                            <p>{item}</p>
                        {/each}
                    {:else}
                        <p>{Description}</p>
                    {/if}
                </div>
                
            </div>
            {#if Aux}
                <div class="phone-car-details phone-card-details-aux">
                    <div class="phone-card-text">
                        <p>{Aux}</p>
                    </div>
                </div>
            {/if}

        </div>

        {#if ShowDrawer}
            <div class="phone-card-drawer">
                <slot />
            </div>
        {/if}
    </div>
{/if}

<style>
    :global(.phone-card-component) {
        position: relative;
        padding: 1vh 1.1vh;
        margin-bottom: 0.8vh;
        border-radius: var(--phone-radius);
        background: var(--phone-card);
        color: white;
        transition: background 150ms;
    }

    :global(.phone-card-component:hover) { background: var(--phone-card-hover); }

    :global(.phone-card-notification) {
        position: absolute;
        top: 0.9vh;
        right: 0.9vh;
        width: 0.8vh;
        height: 0.8vh;
        border-radius: 50%;
        background: var(--phone-accent);
    }

    :global(.phone-card-notification__green) { background: var(--phone-green); }
    :global(.phone-card-notification__red) { background: var(--phone-red); }

    :global(.phone-card-container) {
        display: flex;
        align-items: center;
        width: 100%;
    }

    :global(.phone-card-icon) {
        flex-shrink: 0;
        display: grid;
        place-items: center;
        width: 3.6vh;
        height: 3.6vh;
        margin-right: 1vh;
        border-radius: 1vh;
        background: linear-gradient(160deg, #3b8cff, #1f5fd1);
        font-size: 1.6vh;
        box-shadow: inset 0 0.1vh 0 rgba(255, 255, 255, 0.2);
    }

    :global(.phone-card-details) {
        position: relative;
        display: flex;
        flex-direction: column;
        justify-content: center;
        gap: 0.2vh;
        flex: 1 1;
        overflow: hidden;
    }

    :global(.phone-card-details .phone-card-text) {
        display: flex;
        justify-content: space-between;
    }

    :global(.phone-card-details .phone-card-text > p) {
        display: -webkit-box;
        -webkit-line-clamp: 1;
        -webkit-box-orient: vertical;
        margin: 0;
        font-size: 1.25vh;
        color: var(--phone-muted);
        text-overflow: ellipsis;
        overflow: hidden;
    }

    :global(.phone-card-details .phone-card-text:first-child > p) {
        font-size: 1.4vh;
        font-weight: 600;
        color: white;
    }

    :global(.phone-card-details-aux) {
        display: flex;
        align-items: center;
        margin-left: 0.8vh;
        font-size: 1.25vh;
        color: var(--phone-muted);
    }

    :global(.phone-card-actions) {
        display: none;
        position: absolute;
        inset: 0;
        justify-content: center;
        align-items: center;
        gap: 1.4vh;
        border-radius: var(--phone-radius);
        background: rgba(14, 15, 18, 0.88);
    }

    :global(.phone-card-component:hover .phone-card-actions) { display: flex; }

    :global(.phone-card-actions > i) {
        margin: 0;
        font-size: 1.7vh;
        color: white;
        cursor: pointer;
    }

    :global(.phone-card-actions > i:hover) { color: var(--phone-accent); }

    :global(.phone-card-drawer) {
        display: flex;
        flex-direction: column;
        padding: 0.9vh 0.4vh 0;
        color: var(--phone-muted);
    }

    :global(.phone-card-drawer-item) {
        display: flex;
        align-items: center;
        padding: 0.6vh 0;
        border-bottom: 0.1vh solid var(--phone-line);
        font-size: 1.25vh;
    }

    :global(.phone-card-drawer-item:last-child) { border-bottom: none; }

    :global(.phone-card-drawer-item > i) {
        width: 2vh;
        margin-right: 0.8vh;
        text-align: center;
        color: white;
    }
</style>
