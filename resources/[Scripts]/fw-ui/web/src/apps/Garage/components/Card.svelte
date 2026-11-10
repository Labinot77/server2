<script>
    export let Plate;
    export let Name;
    export let State; // "Stored" | "Out" | "Depot"
    export let Image = null;
    export let Selected = false;
    export let OnSelect = () => {};

    $: StatusLabel = State === "Depot" ? "Impounded" : State;
</script>

<button
    class="garage-card"
    class:selected={Selected}
    on:click={() => OnSelect(Plate)}
>
    <div class="garage-card-thumb">
        <div class="garage-card-thumb-inner">
            {#if Image}
                <img src={Image} alt={Name} />
            {:else}
                <div class="garage-card-icon">
                    <i class="fas fa-car"></i>
                </div>
            {/if}
            <div class="garage-card-plate">{Plate}</div>
        </div>
    </div>

    <div class="garage-card-info">
        <p class="garage-card-name" title={Name}>{Name}</p>
        <span
            class="garage-card-status"
            class:out={State === "Out"}
            class:depot={State === "Depot"}
        >{StatusLabel}</span>
    </div>
</button>

<style>
    .garage-card {
        display: flex;
        flex-direction: column;
        text-align: left;
        background: #102a2e;
        border: 0.1vh solid rgba(94, 196, 184, 0.14);
        border-radius: 1vh;
        overflow: hidden;
        cursor: pointer;
        padding: 0;
        font-family: Roboto;
        transition: border-color 0.15s ease;
    }

    .garage-card:hover {
        border-color: rgba(79, 216, 196, 0.4);
    }

    .garage-card.selected {
        border-color: #4fd8c4;
        box-shadow: inset 0 0 0 0.1vh #4fd8c4;
    }

    .garage-card-thumb {
        position: relative;
        width: 100%;
        padding-bottom: 62.5%; /* 10/16 = 0.625, equivalent to aspect-ratio: 16/10 */
        background: linear-gradient(135deg, #163a3e, #102a2e);
        overflow: hidden;
    }

    .garage-card-thumb-inner {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        display: -webkit-box;
        display: -ms-flexbox;
        display: flex;
        -webkit-box-align: center;
        -ms-flex-align: center;
        align-items: center;
        -webkit-box-pack: center;
        -ms-flex-pack: center;
        justify-content: center;
    }

    .garage-card-icon {
        width: 100%;
        height: 100%;
        display: -webkit-box;
        display: -ms-flexbox;
        display: flex;
        -webkit-box-align: center;
        -ms-flex-align: center;
        align-items: center;
        -webkit-box-pack: center;
        -ms-flex-pack: center;
        justify-content: center;
        color: #5e8a86;
        font-size: 3vh;
    }

    .garage-card-thumb img {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        object-fit: cover;
    }

    .garage-card-plate {
        position: absolute;
        top: 0.8vh;
        left: 0.8vh;
        background: #f4f4f0;
        color: #1a2c2c;
        font-size: 1vh;
        font-weight: 700;
        letter-spacing: 0.04em;
        padding: 0.2vh 0.6vh;
        border-radius: 0.3vh;
        border: 0.1vh solid #c9c9c0;
    }

    .garage-card-info {
        padding: 1vh 1.2vh 1.2vh;
        display: flex;
        flex-direction: column;
        gap: 0.4vh;
    }

    .garage-card-name {
        font-size: 1.3vh;
        font-weight: 600;
        color: white;
        margin: 0;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .garage-card-status {
        font-size: 1.1vh;
        color: #4fd8c4;
    }

    .garage-card-status.out {
        color: #e0b454;
    }

    .garage-card-status.depot {
        color: #e0654f;
    }
</style>