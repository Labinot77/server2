<script>
    import AppWrapper from "../../components/AppWrapper.svelte";
    import { OnEvent } from "../../utils/Utils";
    import { HudVisible, Player } from "./hud.store.js";

    import Cash from "./layers/Cash.svelte";
    import Minimap from "./layers/Minimap.svelte";
    import Status from "./layers/Status.svelte";
    import CenterStatus from "./layers/CenterStatus.svelte";
    import Weapon from "./layers/Weapon.svelte";
    import Vehicle from "./layers/Vehicle.svelte";
    import Chat from "./layers/Chat.svelte";
    import Safezone from "./layers/Safezone.svelte";
    import Settings from "./layers/Settings.svelte";

    OnEvent("Hud", "SetVisibility", (Data) => HudVisible.set(Data));
    OnEvent("Hud", "SetPlayerData", (Data) => Player.set(Data));
</script>

<AppWrapper AppName="Hud" Focused={false}>
    <Cash/>
    <Minimap/>
    <Vehicle/>
    <Status/>
    <CenterStatus/>
    <Weapon/>
    <Chat/>
    <Safezone/>
    <Settings/>
</AppWrapper>
