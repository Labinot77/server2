// ============================================================================
//  Magazine loader: "<Type> Magazine" + one box, shown under GROUND.
//   Drop matching bullets on the box -> timed load (progress bar in the box + animation)
//   Drag the box onto your inventory  -> unload
// ============================================================================

let MagazineLoader = false; // { Slot, Loading }

const GetMagazineConfig = (Type) => (Layout.Magazines || {})[Type] || { Label: Type, Capacity: 0 };
const GetMagazineBullets = (Item) => Math.max(0, Math.floor(Number(Item && Item.Info && Item.Info.Bullets) || 0));
const GetLoaderMagazine = () => {
    if (!MagazineLoader) return false;
    const Item = MyInventory[MagazineLoader.Slot];
    return (Item && Item.Item == 'magazine') ? Item : false;
};

const CloseMagazinePanel = () => {
    MagazineLoader = false;
    $('.ox-magazine').hide();
    $('.mag-load-slot').removeClass('loading');
    $('.inventory-box-slot.mag-active').removeClass('mag-active');
};

const OpenMagazinePanel = (Slot) => {
    if (MagazineLoader && MagazineLoader.Loading) return;
    if (typeof CloseAttachmentsPanel == 'function') CloseAttachmentsPanel();
    MagazineLoader = { Slot: Number(Slot), Loading: false };
    RefreshMagazinePanel();
};

const IsMagazineItem = (Container, Slot) => {
    const Item = Container == 'player' ? MyInventory[Slot] : false;
    return Item && Item.Item == 'magazine';
};

const RefreshMagazinePanel = () => {
    if (!MagazineLoader) return;

    const Magazine = GetLoaderMagazine();
    if (!Magazine) return CloseMagazinePanel(); // moved / dropped / given away

    const Conf = GetMagazineConfig(Magazine.CustomType);
    const Bullets = GetMagazineBullets(Magazine);
    const Box = $('.mag-load-slot');

    $('.mag-title').text(`${Conf.Label} Magazine`);
    Box.find('.inventory-slot-image').css('background-image', `url(${GetItemImage('bullets', Magazine.CustomType)})`);
    Box.find('.mag-qty').text(`${Bullets}/${Conf.Capacity}`).toggleClass('empty', Bullets == 0);
    Box.toggleClass('empty', Bullets <= 0).toggleClass('full', Bullets >= Conf.Capacity && Conf.Capacity > 0);

    $('.inventory-box-slot.mag-active').removeClass('mag-active');
    GetSlotElement('player', MagazineLoader.Slot).addClass('mag-active');

    $('.ox-magazine').show();
};

// --- Load: drop bullets on the box ----------------------------------------
$(document).on('mouseup', '.mag-load-slot', function(e) {
    if (!DragData.IsDragging || DragData.FromContainer == 'magazine') return;

    const Magazine = GetLoaderMagazine();
    const FromItem = DragData.FromContainer == 'player' ? MyInventory[DragData.FromSlot] : false;
    const BulletSlot = DragData.FromSlot;
    ResetDrag();

    if (!Magazine || MagazineLoader.Loading) return;
    if (!FromItem) return InventoryLog('[Error]: Kogels moeten in je eigen inventory zitten.');
    if (FromItem.Item != 'bullets') return InventoryLog('[Error]: Alleen kogels passen in een magazijn.');

    const Conf = GetMagazineConfig(Magazine.CustomType);
    if (FromItem.CustomType != Magazine.CustomType) {
        FlashSlot(this, false);
        return InventoryLog(`[Error]: Dit magazijn past alleen ${Conf.Label} kogels.`);
    }

    const Free = Conf.Capacity - GetMagazineBullets(Magazine);
    if (Free <= 0) { FlashSlot(this, false); return InventoryLog('[Error]: Dit magazijn is al vol.'); }

    let Amount = Number($('#inventory-move-amount').val());
    if (!(Amount > 0) || Amount > FromItem.Amount) Amount = FromItem.Amount;
    Amount = Math.min(Amount, Free);

    MagazineLoader.Loading = true;
    $(this).addClass('loading');
    $.post("https://fw-inventory/LoadMagazine", JSON.stringify({ MagSlot: MagazineLoader.Slot, BulletSlot, Amount }));
});

// From Lua: the load started / finished / got cancelled.
const OnMagazineProgress = (Data) => {
    const Box = $('.mag-load-slot');
    const Fill = Box.find('.mag-progress-fill');

    if (Data.Duration) {
        if (MagazineLoader) MagazineLoader.Loading = true;
        Box.addClass('loading');
        Box.find('.mag-qty').text(`${Data.Current}/${Data.Capacity}`);
        Fill.stop(true).css('width', '0%').animate({ width: '100%' }, {
            duration: Data.Duration,
            easing: 'linear',
            // Count the rounds going in while the bar fills.
            step: (Now) => Box.find('.mag-qty').text(`${Data.Current + Math.floor((Now / 100) * Data.Amount)}/${Data.Capacity}`),
        });
        return;
    }

    // Done or cancelled: the real count arrives with the slot update.
    Fill.stop(true).css('width', '0%');
    Box.removeClass('loading');
    if (MagazineLoader) MagazineLoader.Loading = false;
    RefreshMagazinePanel();
};

window.addEventListener('message', (event) => {
    if (event.data.Action == 'MagazineProgress') OnMagazineProgress(event.data);
    if (event.data.Action == 'OpenMagazinePanel') OpenMagazinePanel(event.data.Slot);
});

// --- Unload: drag the box out -----------------------------------------------
$(document).on('mousedown', '.mag-load-slot', function(e) {
    if (e.button !== 0 || DragData.IsDragging) return;

    const Magazine = GetLoaderMagazine();
    const Bullets = GetMagazineBullets(Magazine);
    if (!Magazine || Bullets <= 0 || MagazineLoader.Loading) return;

    let Amount = Number($('#inventory-move-amount').val());
    if (!(Amount > 0) || Amount > Bullets) Amount = Bullets;

    DragData.IsDragging = true;
    DragData.FromContainer = 'magazine';
    DragData.FromInv = 'magazine';
    DragData.FromSlot = MagazineLoader.Slot;
    DragData.MagAmount = Amount;

    $('body').addClass('inv-dragging');
    $('.drag-item').html(`
        <div class="inventory-slot-image" style="background-image: url(${GetItemImage('bullets', Magazine.CustomType)})"></div>
        <div class="inventory-slot-info"><span class="inventory-slot-quantity">${Amount}x</span></div>
        <div class="inventory-slot-name">${GetItemData('bullets', Magazine.CustomType).Label}</div>
    `).css({ opacity: 0.75, left: e.pageX - $('.drag-item').width() / 2, top: e.pageY - $('.drag-item').height() / 2 });
});

// Called from draghandler.js when a magazine drag ends on a slot.
const FinishMagazineUnload = (ToContainer, ToSlot) => {
    const Amount = DragData.MagAmount;
    const MagSlot = DragData.FromSlot;
    ResetDrag();

    if (ToContainer != 'player') return InventoryLog('[Error]: Ontlaad kogels naar je eigen inventory.');
    $.post("https://fw-inventory/UnloadMagazine", JSON.stringify({ MagSlot, Amount, ToSlot }));
};
