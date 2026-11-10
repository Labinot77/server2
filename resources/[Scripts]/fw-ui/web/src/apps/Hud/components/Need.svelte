<script>
    export let Type = "Food"; // "Food" | "Water"
    export let Value = 0;
</script>

<div class="need {Type}">
    <div class="need-track"><div class="need-fill" style="width: {Value}%"></div></div>

    <div class="need-icon">
        {#if Type == "Food"}
            <svg viewBox="0 0 32 32" aria-hidden="true">
                <path d="M11.2 11.4h13.6a1.8 1.8 0 0 1 1.8 1.8v.7H9.4v-.7a1.8 1.8 0 0 1 1.8-1.8Zm-2 5h17.6a1.5 1.5 0 0 1 0 3H9.2a1.5 1.5 0 0 1 0-3Zm1.3 5.5h15l-1.1 4.2a2.2 2.2 0 0 1-2.1 1.6h-8.6a2.2 2.2 0 0 1-2.1-1.6l-1.1-4.2Z" fill="#fff"></path>
                <path d="M5.2 5v8.2M3.2 5v4.3c0 1.2.9 2.1 2 2.1s2-.9 2-2.1V5M5.2 11.4v16.3" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"></path>
                <path d="M15.2 8.8c.4-2 2-3.5 4-3.8" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round"></path>
            </svg>
        {:else}
            <svg viewBox="0 0 32 32" aria-hidden="true">
                <path d="M9 9h15l-1.6 18.2a2 2 0 0 1-2 1.8h-7.8a2 2 0 0 1-2-1.8L9 9Z" fill="#fff"></path>
                <path d="m17.5 10 2-7h5.2" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path>
                <path d="M12.1 14.5c2.9-1.4 6.1 1.7 9.8.1" fill="none" stroke="#171717" stroke-width="1.6" stroke-linecap="round"></path>
            </svg>
        {/if}
    </div>
</div>

<style>
    .need {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.37vh;
    }

    .need-track {
        width: calc(100% - 0.74vh);
        height: 0.5vh;
        overflow: hidden;
        background: rgba(15, 15, 15, 0.8);
    }

    .need-fill {
        height: 100%;
        background: #fff;
        transition: width 0.3s ease;
    }

    /* slanted inner ends, mirrored for the two meters */
    .Food .need-track, .Food .need-fill { clip-path: polygon(0 0, 100% 0, 100% 100%, 0.5vh 100%); }
    .Water .need-track, .Water .need-fill { clip-path: polygon(0 0, 100% 0, calc(100% - 0.5vh) 100%, 0 100%); }

    .need-icon {
        display: flex;
        width: 2.2vh;
        height: 2.2vh;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        background: rgba(15, 15, 15, 0.55);
        box-shadow: 0 0.09vh 0.28vh rgba(0, 0, 0, 0.35);
    }

    .Food .need-icon { transform: translateX(0.37vh); }
    .Water .need-icon { transform: translateX(-0.37vh); }

    .need-icon svg {
        width: 1.67vh;
        height: 1.67vh;
        opacity: 0.9;
        filter: drop-shadow(0 0 0.28vh rgba(0, 0, 0, 0.8));
    }
</style>