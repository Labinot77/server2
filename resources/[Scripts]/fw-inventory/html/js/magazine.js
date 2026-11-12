// ============================================================================
//  Magazines: drag bullets onto a magazine to load it. The slot counts up (8/12, 9/12, ...) under a
//  progress ring. Click the magazine (or close the inventory) to stop; the rounds loaded so far stay in.
//  Right-click -> Unload takes the bullets out again.
// ============================================================================
let MagLoad = false; // { Slot, BulletSlot, Current, Capacity, Amount, Base, PerBullet, Duration, Start, Timer }

const GetMagazineConfig = (Type) => (Layout.Magazines || {})[Type] || { Label: Type, Capacity: 0 };
const GetMagazineBullets = (Item) => Math.max(0, Math.floor(Number(Item && Item.Info && Item.Info.Bullets) || 0));
const IsMagazineLoading = (Slot) => MagLoad && MagLoad.Slot == Slot;
const IsBulletsLoading = (Slot) => MagLoad && MagLoad.BulletSlot == Slot;

// From draghandler.js: bullets dropped on a magazine.
const LoadBulletsOnMagazineSlot = (BulletSlot, MagSlot) => {
    const Bullets = MyInventory[BulletSlot], Magazine = MyInventory[MagSlot];
    const El = GetSlotElement('player', MagSlot);
    if (MagLoad) return InventoryLog('[Error]: Je bent al een magazijn aan het laden.');

    const Conf = GetMagazineConfig(Magazine.CustomType);
    if (Bullets.CustomType != Magazine.CustomType) {
        FlashSlot(El, false);
        return InventoryLog(`[Error]: Dit magazijn past alleen ${Conf.Label} kogels.`);
    }

    const Free = Conf.Capacity - GetMagazineBullets(Magazine);
    if (Free <= 0) { FlashSlot(El, false); return InventoryLog('[Error]: Dit magazijn is al vol.'); }

    let Amount = Number($('#inventory-move-amount').val());
    if (!(Amount > 0) || Amount > Bullets.Amount) Amount = Bullets.Amount;

    MagLoad = { Slot: Number(MagSlot), BulletSlot: Number(BulletSlot) };
    $.post("https://fw-inventory/LoadMagazine", JSON.stringify({ MagSlot: MagLoad.Slot, BulletSlot: MagLoad.BulletSlot, Amount: Math.min(Amount, Free) }));
};

const LoadedSoFar = () => Math.max(0, Math.min(MagLoad.Amount, Math.floor((Date.now() - MagLoad.Start - MagLoad.Base) / Math.max(1, MagLoad.PerBullet))));

// A ring on the magazine and on the bullets, running down as the remaining bullets go in.
// Redrawn every tick, so it survives the slots being re-rendered.
const LoaderSvg = '<svg class="mag-loader" viewBox="0 0 36 36"><circle class="mag-loader-track" cx="18" cy="18" r="15"/><circle class="mag-loader-arc" cx="18" cy="18" r="15" pathLength="100" stroke-dasharray="100 100"/></svg>';

const SetLoadRing = (El, Remaining) => {
    El.addClass('mag-loading');
    if (!El.find('.mag-loader').length) El.append(LoaderSvg);
    El.find('.mag-loader-arc').attr('stroke-dashoffset', (100 * (1 - Remaining)).toFixed(2));
};

const ClearLoadRing = (Slot) => GetSlotElement('player', Slot).removeClass('mag-loading').find('.mag-loader').remove();

const DrawMagLoad = () => {
    const Loaded = LoadedSoFar();
    const Remaining = 1 - Math.min(1, (Date.now() - MagLoad.Start) / MagLoad.Duration);
    const MagEl = GetSlotElement('player', MagLoad.Slot), BulletEl = GetSlotElement('player', MagLoad.BulletSlot);

    MagEl.find('.mag-qty').text(`${MagLoad.Current + Loaded}/${MagLoad.Capacity}`).removeClass('empty');
    const Bullets = MyInventory[MagLoad.BulletSlot];
    if (Bullets) BulletEl.find('.inventory-slot-quantity').text(`X${Bullets.Amount - Loaded}`);

    SetLoadRing(MagEl, Remaining);
    SetLoadRing(BulletEl, Remaining);
};

const OnMagazineProgress = (Data) => {
    if (!MagLoad) return;

    if (Data.Duration) {
        Object.assign(MagLoad, { Current: Data.Current, Capacity: Data.Capacity, Amount: Data.Amount, Base: Data.Base, PerBullet: Data.PerBullet, Duration: Data.Duration, Start: Date.now() });
        MagLoad.Timer = setInterval(DrawMagLoad, 50);
        return DrawMagLoad();
    }

    // Done / stopped / refused. Show what went in right away; the server's slot update confirms it.
    const Magazine = MyInventory[MagLoad.Slot];
    if (MagLoad.Timer) {
        clearInterval(MagLoad.Timer);
        if (Magazine && Magazine.Item == 'magazine') Magazine.Info = { ...Magazine.Info, Bullets: MagLoad.Current + LoadedSoFar() };
    }
    const Bullets = MyInventory[MagLoad.BulletSlot];
    if (MagLoad.Timer && Bullets) Bullets.Amount = Math.max(0, Bullets.Amount - LoadedSoFar());
    const { Slot, BulletSlot } = MagLoad;
    MagLoad = false;
    ClearLoadRing(Slot);
    ClearLoadRing(BulletSlot);
    RenderSlot('player', Slot);
    RenderSlot('player', BulletSlot);
};

window.addEventListener('message', (event) => {
    if (event.data.Action == 'MagazineProgress') OnMagazineProgress(event.data);
});

// Click the loading magazine to stop.
const StopMagazineLoad = () => { if (MagLoad && MagLoad.Timer) $.post("https://fw-inventory/CancelMagazineLoad"); };

// Right-click -> Unload (AMOUNT field, else everything).
const UnloadMagazine = (Slot) => {
    const Bullets = GetMagazineBullets(MyInventory[Slot]);
    let Amount = Number($('#inventory-move-amount').val());
    if (!(Amount > 0) || Amount > Bullets) Amount = Bullets;
    $.post("https://fw-inventory/UnloadMagazine", JSON.stringify({ MagSlot: Slot, Amount }));
};
