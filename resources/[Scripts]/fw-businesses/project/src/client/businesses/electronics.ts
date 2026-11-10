import { Delay, exp } from "../../shared/utils";
import { FW, GetCurrentClock } from "../client";
import { HasRolePermission, IsBusinessOnLockdown, IsPlayerInBusiness } from "../utils";

onNet("fw-businesses:Client:Electronics:Counter", (Data: {Type: string}) => {
    if (exp['fw-inventory'].CanOpenInventory()) {
        FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Stash', `${Data.Type}_counter`, 10, 200)
    }
});

onNet("fw-businesses:Client:Electronics:Storage", async (Data: {
    Business: string;
    Type: string;
}) => {
    if (!await HasRolePermission(Data.Business, "StashAccess")) return;

    if (await IsBusinessOnLockdown(Data.Business)) {
        return FW.Functions.Notify("Bedrijf is in lockdown..", "error");
    };

    if (exp['fw-inventory'].CanOpenInventory()) {
        FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Stash', `${Data.Type}_stash`, 40, 2000)
    }
});

onNet("fw-businesses:Client:Electronics:Craft", async (Data: {
    Business: string;
    Type: string;
}) => {
    if (!await HasRolePermission(Data.Business, "CraftAccess")) return;

    if (await IsBusinessOnLockdown(Data.Business)) {
        return FW.Functions.Notify("Bedrijf is in lockdown..", "error");
    };

    if (exp['fw-inventory'].CanOpenInventory()) {
        FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Crafting', Data.Type)
    };
});

onNet("fw-businesses:Client:Electronics:Scrap", async (Data: {
    Business: string;
    Type: string;
}) => {
    if (!exp['fw-inventory'].CanOpenInventory()) return;
    if (!await HasRolePermission(Data.Business, "CraftAccess")) return;

    if (await IsBusinessOnLockdown(Data.Business)) {
        return FW.Functions.Notify("Bedrijf is in lockdown..", "error");
    };

    const Result = await FW.SendCallback("fw-businesses:Server:Electronics:GetScrapItems", Data.Business);
    if (!Result || Result.length == 0) return FW.Functions.Notify("Je hebt geen electronica opzak..", "error");

    let ContextItems = [];
    for (let i = 0; i < Result.length; i++) {
        const {Label, Slot, Parts, Materials} = Result[i];

        ContextItems.push({
            Title: Label,
            Desc: `Slot ${Slot}`,
            SecondMenu: [
                {
                    Title: `<div style="display: flex; justify-content: space-between"><span>Scrappen</span><span>▨ ${Parts}</span></div>`,
                    Icon: "hammer",
                    Data: {
                        Event: "fw-businesses:Server:Electronics:ScrapElectronic",
                        Type: "Server",
                        Business: Data.Business,
                        Parts, Slot
                    }
                },
                {
                    Disabled: Materials < 40,
                    Title: Materials < 40 ? "Repareren" : `Repareren (${Materials} electronica)`,
                    Desc: Materials < 40 ? `De ${Label.toLowerCase()} doet het nog..` : false,
                    Icon: "wrench",
                    Data: {
                        Event: "fw-businesses:Server:Electronics:RepairElectronic",
                        Type: "Server",
                        Business: Data.Business,
                        Materials, Slot
                    }
                }
            ]
        })
    };

    FW.Functions.OpenMenu({MainMenuItems: ContextItems})
});

onNet("fw-businesses:Client:Electronics:AddMusicEntry", async (Data: {
    Business: string;
}) => {
    if (!await HasRolePermission(Data.Business, 'CraftAccess')) return;

    if (await IsBusinessOnLockdown(Data.Business)) {
        return FW.Functions.Notify("Bedrijf is in lockdown..", "error");
    };

    const Result = await exp['fw-ui'].CreateInput([
        { Label: 'SoundCloud Track Id (e.g: 1242868615)', Name: 'TapeId', Type: 'number' },
        { Label: 'Artiest', Icon: 'fas fa-user-music', Name: 'Artist' },
        { Label: 'Titel', Icon: 'fas fa-user-edit', Name: 'Title' },
    ]);

    if (!Result) return;
    if (Result.TapeId.trim().length === 0 || Result.TapeId == '') return;
    if (Result.Artist.trim().length === 0 || Result.Artist == '') return;
    if (Result.Title.trim().length === 0 || Result.Title == '') return;

    FW.TriggerServer("fw-businesses:Server:Electronics:AddMusicEntry", {Business: Data.Business, ...Result})
});

onNet("fw-businesses:Client:Electronics:ManageMusicEntries", async (Data: {
    Business: string;
}) => {
    if (!await HasRolePermission(Data.Business, 'CraftAccess')) return;

    if (await IsBusinessOnLockdown(Data.Business)) {
        return FW.Functions.Notify("Bedrijf is in lockdown..", "error");
    };

    const Tapes = await FW.SendCallback("fw-businesses:Server:Electronics:GetMusicEntries")
    if (Tapes.length === 0) return FW.Functions.Notify("Geen tracks gevonden..", "error");

    const ContextItems = [];

    for (let i = 0; i < Tapes.length; i++) {
        const TapeData = Tapes[i];

        ContextItems.push({
            Title: `(${TapeData.id}) ${TapeData.tape_title}`,
            Desc: `Track Id: ${TapeData.tape_id}; Artist: ${TapeData.tape_artist}`,
            SecondMenu: [
                {
                    Icon: "trash",
                    Title: "Track Verwijderen",
                    Data: {
                        Event: "fw-businesses:Server:Electronics:RemoveMusicEntry",
                        Type: "Server",
                        TrackId: TapeData.id,
                        Business: Data.Business,
                    }
                }
            ]
        })
    }

    FW.Functions.OpenMenu({MainMenuItems: ContextItems, Width: "35vh"})
});

onNet("fw-businesses:Client:Electronics:CreateMusicTape", async (Data: {
    Business: string;
}) => {
    if (!await HasRolePermission(Data.Business, 'CraftAccess')) return;

    if (await IsBusinessOnLockdown(Data.Business)) {
        return FW.Functions.Notify("Bedrijf is in lockdown..", "error");
    };

    const Tapes = await FW.SendCallback("fw-businesses:Server:Electronics:GetMusicEntries")
    if (Tapes.length === 0) return FW.Functions.Notify("Geen tracks gevonden..", "error");

    const Tracks = Tapes.map(({id, tape_artist, tape_title}: {[key: string]: any}) => {
        return { Text: `${tape_artist} - ${tape_title}`, Value: id }
    });

    const Result = await exp['fw-ui'].CreateInput([
        { Label: 'Track', Name: 'TrackId', Choices: Tracks },
        { Label: 'Aantal', Name: 'Copies', Type: "number" },
    ]);

    if (!Result) return;
    if (Result.TrackId === '') return;
    if (Result.Copies == 0 || Result.Copies == '' || Number(Result.Copies) <= 0) return;

    const Duration = 1500 * Number(Result.Copies)
    const Success = await FW.Functions.CompactProgressbar(Duration, 'Cassettebandjes maken...', false, true, { disableMovement: true, disableCarMovement: true, disableMouse: false, disableCombat: true }, { animDict: "anim@amb@business@coc@coc_unpack_cut@", anim: "fullcut_cycle_v6_cokecutter", flags: 0 }, {}, {}, false)
    StopAnimTask(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0)
    if (!Success) return;

    FW.TriggerServer("fw-businesses:Server:Electronics:CreateCassetteTapes", {Business: Data.Business, ...Result})
})

// zones
onNet("fw-config:configLoaded", (pConfig: string) => {
    if (!exp['fw-config'].IsConfigReady() || pConfig != "bus-electronics") return;
    loadElectronicsZone();
});

onNet("fw-config:configReady", () => {
    loadElectronicsZone();
});

const electronicsInteractions: number[] = [];

// Use coords if the zone has them; otherwise build them from the old center/minZ/maxZ,
// so the bus-electronics JSON works without being edited.
const getZoneCoords = (zone: any) => zone.coords ?? {
    x: zone.center.x,
    y: zone.center.y,
    z: zone.minZ !== undefined && zone.maxZ !== undefined
        ? (zone.minZ + zone.maxZ) / 2
        : zone.center.z,
};

// canInteract is checked every frame and has to answer right away.
// This runs the async check in the background, caches the result, and returns the last value.
const checkCache = new Map<string, { value: boolean; expires: number; pending: boolean }>();
const cachedCheck = (key: string, ttlMs: number, fn: () => Promise<any>): boolean => {
    let entry = checkCache.get(key);
    if (!entry) {
        entry = { value: false, expires: 0, pending: false };
        checkCache.set(key, entry);
    }
    if (!entry.pending && GetGameTimer() > entry.expires) {
        entry.pending = true;
        fn()
            .then((v) => { entry!.value = !!v; })
            .catch(() => { entry!.value = false; })
            .finally(() => {
                entry!.pending = false;
                entry!.expires = GetGameTimer() + ttlMs;
            });
    }
    return entry.value;
};

const isClockedInAt = (business: string) => {
    const { Business, ClockedIn } = GetCurrentClock();
    return ClockedIn && Business === business;
};

const makeOption = (name: string, label: string, event: string, params: any, canInteract: () => boolean) => ({
    name: `electronics:${name}`,
    label,
    canInteract,
    action: () => emit(event, params),
});

const ELECTRONICS_OPTIONS: Record<string, (zone: any) => any[]> = {
    stash: (z) => [
        makeOption('stash', 'Stash', 'fw-businesses:Client:Electronics:Storage', z.data,
            () => isClockedInAt(z.data.Business)),
    ],
    craft: (z) => [
        makeOption('craft', 'Craften', 'fw-businesses:Client:Electronics:Craft', z.data,
            () => isClockedInAt(z.data.Business)),
    ],
    scrap: (z) => [
        makeOption('scrap', 'Scrap en repareren', 'fw-businesses:Client:Electronics:Scrap', z.data,
            () => isClockedInAt(z.data.Business)),
    ],
    tray: (z) => [
        makeOption('tray', 'Toonbank', 'fw-businesses:Client:Electronics:Counter', z.data,
            () => true),
    ],
    payment: (z) => [
        makeOption('pay_payment', 'Betalen', 'fw-businesses:Client:Foodchain:GetPayments', z.data,
            () => true),
        makeOption('setup_payment', 'Bestelling Openen', 'fw-businesses:Client:Foodchain:SetupPayment',
            { RegisterId: z.data.RegisterId },
            () => isClockedInAt(z.data.Business) &&
                cachedCheck(`perm:${z.data.Business}:ChargeExternal`, 10000,
                    () => HasRolePermission(z.data.Business, "ChargeExternal"))),
    ],
    clock: (z) => [
        makeOption('clock_in', 'Inklokken', 'fw-businesses:Client:SetClock',
            { ...z.data, ClockedIn: true },
            () => !GetCurrentClock().ClockedIn &&
                cachedCheck(`member:${z.data.Business}`, 10000, () => IsPlayerInBusiness(z.data.Business))),
        makeOption('clock_out', 'Uitklokken', 'fw-businesses:Client:SetClock',
            { ...z.data, ClockedIn: false },
            () => GetCurrentClock().ClockedIn &&
                cachedCheck(`member:${z.data.Business}`, 10000, () => IsPlayerInBusiness(z.data.Business))),
    ],
    addMusic: (z) => [
        makeOption('addMusicEntry', 'Muziek Toevoegen', 'fw-businesses:Client:Electronics:AddMusicEntry',
            { ...z.data, ClockedIn: true },
            () => isClockedInAt(z.data.Business)),
    ],
    manageMusic: (z) => [
        makeOption('manageMusicEntry', 'Muziek Beheren', 'fw-businesses:Client:Electronics:ManageMusicEntries',
            { ...z.data, ClockedIn: true },
            () => isClockedInAt(z.data.Business)),
    ],
    createTape: (z) => [
        makeOption('tape', 'Maak Cassettabandje', 'fw-businesses:Client:Electronics:CreateMusicTape',
            { ...z.data, ClockedIn: true },
            () => isClockedInAt(z.data.Business)),
    ],
};

const loadElectronicsZone = async () => {
    while (!exp['fw-config'].IsConfigReady()) {
        await Delay(100);
    }

    const { zones } = await exp['fw-config'].GetModuleConfig("bus-electronics");

    for (const zone of zones) {
        const options = zone.options.flatMap((key: string) => ELECTRONICS_OPTIONS[key]?.(zone) ?? []);
        if (options.length === 0) continue;

      const id = exp['interact'].AddInteraction({
            name: zone.name,
            coords: getZoneCoords(zone),
            distance: zone.distance ?? 3.5,
            interactDst: zone.interactDst ?? 1.5,
            options,
        });

        electronicsInteractions.push(id);
    }
};