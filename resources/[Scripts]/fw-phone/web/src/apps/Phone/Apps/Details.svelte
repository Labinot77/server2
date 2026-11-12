<script>
    import { onMount } from "svelte";
    import { LicensesLocale } from "../../../config";
    import { FormatCurrency, FormatPhone, SendEvent } from "../../../utils/Utils";
    import { PlayerData } from "../phone.stores";

    import AppWrapper from "../components/AppWrapper.svelte";
    import AppHeader from "../components/AppHeader.svelte";

    let MyLicenses = {};

    onMount(() => {
        SendEvent("Details/GetLicenses", {}, (Success, Data) => {
            if (Success) MyLicenses = Data;
        });
    });

    $: Info = [
        ["id-card", "CID", $PlayerData?.Cid, "#0a84ff"],
        ["university", "Bank Number", $PlayerData?.BankId, "#30d158"],
        ["mobile-alt", "Phone Number", FormatPhone($PlayerData?.PhoneNumber || ""), "#5e5ce6"],
    ];

    $: Money = [
        ["wallet", "Cash", $PlayerData?.Cash, "#acd680"],
        ["piggy-bank", "Bank", $PlayerData?.Bank, "#53cee5"],
        ["dice-three", "Casino", $PlayerData?.Casino, "#fd4083"],
    ];

    $: Licenses = Object.entries(MyLicenses).filter(([Type, Has]) => Type != "weapon" || Has);
</script>

<AppWrapper>
    <AppHeader Title="Details" />

    <div class="details">
        <div class="group">
            {#each Info as [Icon, Label, Value, Color]}
                <div class="row">
                    <span><i class="fas fa-{Icon}" style="color: {Color}" /> {Label}</span>
                    <span class="muted">{Value ?? "-"}</span>
                </div>
            {/each}
        </div>

        <div class="money">
            {#each Money as [Icon, Label, Value, Color]}
                <div class="money-card">
                    <i class="fas fa-{Icon}" style="color: {Color}" />
                    <p class="muted">{Label}</p>
                    <p class="amount">{FormatCurrency.format(Value || 0)}</p>
                </div>
            {/each}
        </div>

        <p class="label">Licenses</p>
        <div class="group">
            {#each Licenses as [Type, Has]}
                <div class="row">
                    <span>{LicensesLocale[Type] || Type}</span>
                    <i class="fas fa-{Has ? "check-circle" : "times-circle"}" style="color: var(--phone-{Has ? "green" : "red"})" />
                </div>
            {/each}
        </div>
    </div>
</AppWrapper>

<style>
    p { margin: 0; }
    .muted { color: var(--phone-muted); }

    .details {
        height: calc(100% - 10vh);
        padding: 0 5% 3vh;
        overflow-y: auto;
    }

    .details::-webkit-scrollbar { display: none; }

    .group {
        padding: 0.4vh 1.2vh;
        border-radius: var(--phone-radius);
        background: var(--phone-card);
    }

    .row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        min-height: 3.6vh;
        font-size: 1.35vh;
        border-bottom: 0.1vh solid var(--phone-line);
    }

    .row:last-child { border-bottom: none; }
    .row i { width: 2vh; margin-right: 0.6vh; text-align: center; }

    .money {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 0.8vh;
        margin-top: 1.2vh;
    }

    .money-card {
        padding: 1vh;
        border-radius: var(--phone-radius);
        background: var(--phone-card);
        font-size: 1.1vh;
    }

    .money-card > i { font-size: 1.8vh; margin-bottom: 0.8vh; }
    .amount { margin-top: 0.2vh; font-size: 1.3vh; font-weight: 700; overflow: hidden; text-overflow: ellipsis; }

    .label {
        margin: 1.8vh 0 0.6vh 1vh;
        font-size: 1.1vh;
        text-transform: uppercase;
        letter-spacing: 0.05vh;
        color: var(--phone-muted);
    }
</style>
