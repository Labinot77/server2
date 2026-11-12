<script>
    import { HasVpn } from "../phone.stores";
    import { SendEvent } from "../../../utils/Utils";

    import TextField from "../../../components/TextField/TextField.svelte";
    import AppWrapper from "../components/AppWrapper.svelte";
    import AppHeader from "../components/AppHeader.svelte";

    let TargetId;

    const SendPing = (Event, IsAnon) => {
        SendEvent("Pinger/SendPing", {
            IsAnon,
            Id: Number(TargetId),
        })
    };

    const SendAnonPing = () => {
        SendPing(undefined, true)
    };
</script>


<AppWrapper>
    <AppHeader Title="Pinger" />

    <div class="pinger">
        <div class="pinger-hero"><i class="fas fa-map-marker-alt" /></div>
        <p class="pinger-hint">Send your GPS location to another player by their CID.</p>

        <TextField Icon="id-card-alt" Title="CID" bind:RealValue={TargetId} Type="number" />

        <div class="pinger-button" on:keyup on:click={SendPing}><i class="fas fa-paper-plane" /> Send Ping</div>
        {#if $HasVpn}
            <div class="pinger-button anon" on:keyup on:click={SendAnonPing}><i class="fas fa-user-secret" /> Anonymous Ping</div>
        {/if}
    </div>
</AppWrapper>

<style>
    .pinger {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 1vh 8% 0;
    }

    .pinger-hero {
        display: grid;
        place-items: center;
        width: 8vh;
        height: 8vh;
        margin-bottom: 1.4vh;
        border-radius: 2.2vh;
        background: linear-gradient(160deg, #ff9a76, #f0644a);
        font-size: 3.6vh;
        box-shadow: 0 0.8vh 2vh rgba(240, 100, 74, 0.35);
    }

    .pinger-hint {
        margin: 0 0 2.4vh;
        text-align: center;
        font-size: 1.25vh;
        color: var(--phone-muted);
    }

    .pinger-button {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.8vh;
        width: 100%;
        height: 4vh;
        margin-top: 1vh;
        border-radius: 1.2vh;
        background: #f0644a;
        font-size: 1.45vh;
        font-weight: 600;
        cursor: pointer;
        transition: filter 150ms;
    }

    .pinger-button:hover { filter: brightness(1.12); }
    .pinger-button.anon { background: rgba(255, 255, 255, 0.12); }
</style>
