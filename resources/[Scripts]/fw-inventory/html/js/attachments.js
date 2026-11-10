// ============================================================================
//  Weapon attachments — right-click a weapon -> Attachments (shown under GROUND)
//   Magazine slot: the magazine that's in the gun (Info.Mag / Info.Ammo)
//   Other slots  : Config.AttachmentSlots that have an attachment fitting this weapon
//   Drag a magazine/attachment onto its slot -> attach (swaps with what's there)
//   Drag a slot onto your inventory          -> detach
// ============================================================================

let AttachmentPanel = false; // { Slot }

const GetWeaponMagType = (WeaponName) => (Layout.WeaponMagTypes || {})[WeaponName] || false;

const GetAttachmentData = (ItemName) => (Layout.WeaponAttachments || []).find(v => v.Item == ItemName);

// What fits the open weapon: { Kinds: { Muzzle: true }, Items: { silencer: true } }, asked from Lua
// (DoesWeaponTakeWeaponComponent needs the game, the NUI can't check it).
const AttachmentFits = (ItemName) => {
    const Data = GetAttachmentData(ItemName);
    const Fits = AttachmentPanel && AttachmentPanel.Fits;
    return Data && Fits && Fits.Items && Fits.Items[ItemName] ? Data : false;
};

const KindFits = (Kind) => {
    const Fits = AttachmentPanel && AttachmentPanel.Fits;
    return !!(Fits && Fits.Kinds && Fits.Kinds[Kind]);
};

// Magazine (magazine guns) + every attachment slot; slots the weapon can't take render locked.
const GetWeaponAttachmentSlots = (WeaponName) => {
    const Slots = [];
    if (GetWeaponMagType(WeaponName)) Slots.push({ Kind: 'Magazine', Label: 'Magazine', Icon: 'bolt' });
    for (const Slot of (Layout.AttachmentSlots || [])) Slots.push(Slot);
    return Slots;
};

// Firearms only (melee weapons and attachment items like the silencer are flagged Weapon too).
const HasAttachmentOptions = (WeaponName) => String(WeaponName).startsWith('weapon_') && !!GetWeaponMagType(WeaponName);

const GetPanelWeapon = () => {
    if (!AttachmentPanel) return false;
    const Item = MyInventory[AttachmentPanel.Slot];
    return (Item && ItemsList[Item.Item] && ItemsList[Item.Item].Weapon) ? Item : false;
};

const CloseAttachmentsPanel = () => {
    AttachmentPanel = false;
    $('.ox-attachments').hide();
    $('.inventory-box-slot.att-active').removeClass('att-active');
};

const OpenAttachmentsPanel = (Slot) => {
    if (typeof CloseMagazinePanel == 'function') CloseMagazinePanel();
    const Weapon = MyInventory[Number(Slot)];
    if (!Weapon) return;

    AttachmentPanel = { Slot: Number(Slot), Fits: { Kinds: {}, Items: {} } };
    RefreshAttachmentsPanel();

    $.post("https://fw-inventory/GetWeaponAttachmentFits", JSON.stringify({ Weapon: Weapon.Item }), function(Fits) {
        if (!AttachmentPanel || AttachmentPanel.Slot != Number(Slot)) return;
        if (typeof Fits == 'string') { try { Fits = JSON.parse(Fits); } catch (e) { Fits = false; } }
        if (Fits && typeof Fits == 'object') AttachmentPanel.Fits = { Kinds: Fits.Kinds || {}, Items: Fits.Items || {} };
        RefreshAttachmentsPanel();
    });
};

const RefreshAttachmentsPanel = () => {
    if (!AttachmentPanel) return;

    const Weapon = GetPanelWeapon();
    if (!Weapon) return CloseAttachmentsPanel();

    const Info = Weapon.Info || {};
    const Attached = (Info.Attachments && typeof Info.Attachments == 'object') ? Info.Attachments : {};
    const Row = $('.ox-attachments .att-row').empty();

    $('.att-title').text(`${GetItemData(Weapon.Item, Weapon.CustomType, Weapon.Info).Label} Attachments`);

    for (const Slot of GetWeaponAttachmentSlots(Weapon.Item)) {
        let Inner = `<span class="material-symbols-outlined emptyicon">${Slot.Icon}</span><div class="emptylabel">${Slot.Label}</div>`;
        let Empty = true;
        const Locked = Slot.Kind != 'Magazine' && !KindFits(Slot.Kind) && !Attached[Slot.Kind];
        if (Locked) Inner = `<span class="material-symbols-outlined emptyicon">lock</span><div class="emptylabel">${Slot.Label}</div>`;

        if (Slot.Kind == 'Magazine' && Info.Mag && Layout.Magazines[Info.Mag]) {
            Empty = false;
            const Ammo = Math.max(0, Math.floor(Number(Info.Ammo) || 0));
            Inner += `
                <div class="inventory-slot-image" style="background-image: url(${GetItemImage('magazine', Info.Mag)})"></div>
                <div class="inventory-slot-info"><span class="inventory-slot-quantity mag-qty${Ammo == 0 ? ' empty' : ''}">${Ammo}/${Layout.Magazines[Info.Mag].Capacity}</span></div>
                <div class="inventory-slot-name">${GetItemData('magazine', Info.Mag).Label}</div>`;
        } else if (Attached[Slot.Kind] && ItemsList[Attached[Slot.Kind].Item]) {
            Empty = false;
            const A = Attached[Slot.Kind];
            Inner += `
                <div class="inventory-slot-image" style="background-image: url(${GetItemImage(A.Item, A.CustomType, A.Info)})"></div>
                <div class="inventory-slot-name">${GetItemData(A.Item, A.CustomType, A.Info).Label}</div>`;
        }

        Row.append(`<div class="att-slot${Empty ? ' empty' : ''}${Locked ? ' locked' : ''}" data-kind="${Slot.Kind}" title="${Locked ? 'Dit wapen heeft hier geen plek voor' : Slot.Label}">${Inner}</div>`);
    }

    $('.inventory-box-slot.att-active').removeClass('att-active');
    GetSlotElement('player', AttachmentPanel.Slot).addClass('att-active');
    $('.ox-attachments').show();
};

// Which attachment slot (kind) an inventory item goes into for the open weapon.
const GetTargetKind = (Item) => {
    const Weapon = GetPanelWeapon();
    if (!Weapon || !Item) return false;
    if (Item.Item == 'magazine') return Item.CustomType == GetWeaponMagType(Weapon.Item) ? 'Magazine' : false;
    const Fits = AttachmentFits(Item.Item);
    return Fits ? Fits.Kind : false;
};

// Highlight the matching slot while dragging (called from draghandler.js).
const HighlightAttachmentTarget = (Item) => {
    const Kind = GetTargetKind(Item);
    if (Kind) $(`.att-slot[data-kind="${Kind}"]`).addClass('equip-target');
};

// --- Attach: drop on a slot -------------------------------------------------
$(document).on('mouseup', '.att-slot', function(e) {
    if (!DragData.IsDragging || DragData.FromContainer == 'attachment' || DragData.FromContainer == 'magazine') return;

    const Weapon = GetPanelWeapon();
    const FromItem = DragData.FromContainer == 'player' ? MyInventory[DragData.FromSlot] : false;
    const FromSlot = DragData.FromSlot;
    ResetDrag();

    if (!Weapon) return;
    if (!FromItem) return InventoryLog('[Error]: Het item moet in je eigen inventory zitten.');

    const Kind = GetTargetKind(FromItem);
    if (!Kind || Kind != $(this).attr('data-kind')) {
        FlashSlot(this, false);
        if (FromItem.Item == 'magazine') return InventoryLog(`[Error]: Dit wapen neemt alleen ${GetMagazineConfig(GetWeaponMagType(Weapon.Item)).Label} magazijnen.`);
        const Data = GetAttachmentData(FromItem.Item);
        if (Data && Data.Kind == $(this).attr('data-kind')) return InventoryLog(`[Error]: Deze ${ItemsList[FromItem.Item].Label} past niet op dit wapen.`);
        if ($(this).hasClass('locked')) return InventoryLog('[Error]: Dit wapen heeft hier geen plek voor.');
        return InventoryLog('[Error]: Dit past hier niet.');
    }

    FlashSlot(this, true);
    $.post("https://fw-inventory/AttachToWeapon", JSON.stringify({ WeaponSlot: AttachmentPanel.Slot, ItemSlot: FromSlot }));
});

// --- Detach: drag a filled slot out ---------------------------------------
$(document).on('mousedown', '.att-slot', function(e) {
    if (e.button !== 0 || DragData.IsDragging || $(this).hasClass('empty')) return;

    DragData.IsDragging = true;
    DragData.FromContainer = 'attachment';
    DragData.FromInv = 'attachment';
    DragData.FromSlot = AttachmentPanel.Slot;
    DragData.AttachmentKind = $(this).attr('data-kind');

    $('body').addClass('inv-dragging');
    $('.drag-item').html($(this).html()).find('.emptyicon, .emptylabel').remove();
    $('.drag-item').css({ opacity: 0.75, left: e.pageX - $('.drag-item').width() / 2, top: e.pageY - $('.drag-item').height() / 2 });
});

// Called from draghandler.js when an attachment drag ends on a slot.
const FinishAttachmentDetach = (ToContainer, ToSlot) => {
    const Kind = DragData.AttachmentKind;
    const WeaponSlot = DragData.FromSlot;
    ResetDrag();

    if (ToContainer != 'player') return InventoryLog('[Error]: Leg het eerst in je eigen inventory.');
    $.post("https://fw-inventory/DetachFromWeapon", JSON.stringify({ WeaponSlot, Kind, ToSlot }));
};
