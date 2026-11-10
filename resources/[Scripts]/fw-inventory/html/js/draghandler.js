let DragData = {
    IsDragging: false,
    FromInv: false,
    FromSlot: false,
};

const ResetDrag = () => {
    $('.drag-item').css('opacity', '0.0').empty();
    $('body').removeClass('inv-dragging');
    $('.equip-target').removeClass('equip-target');
    DragData.IsDragging = false;
};

const FlashSlot = (Element, Good) => {
    const Class = Good ? 'drop-ok' : 'drop-bad';
    $(Element).removeClass('drop-ok drop-bad').addClass(Class);
    setTimeout(() => $(Element).removeClass(Class), 350);
};

const GetInvSpecificItems = (InvName) => {
    for (let i = 0; i < SpecificItemsInv.length; i++) {
        const Data = SpecificItemsInv[i];
        if (InvName.indexOf(Data.Inv) > -1) {
            return Data.Items
        };
    };

    return undefined;
};

const CanBuyWeapon = () => {
    return new Promise(async (Res) => {
        $.post("https://fw-inventory/CanBuyWeapon", JSON.stringify({}), function(CanBuy){
            Res(CanBuy)
        });
    });
};

const HasCraftingItems = (ItemName, CustomType, Amount) => {
    return new Promise(async (Res) => {
        $.post("https://fw-inventory/HasCraftingItems", JSON.stringify({ItemName, CustomType, Amount}), function(Retval){
            Res(Retval)
        });
    });
};

const HasInsertInto = (FromItem, ToItem) => {
    if (FromItem == undefined || FromItem.Item == undefined || ItemsList[FromItem.Item] == undefined) return [ false, false ];
    if (ToItem == undefined || ToItem.Item == undefined || ItemsList[ToItem.Item] == undefined) return [ false, false ];

    const InsertIntoFrom = ItemsList[FromItem.Item].InsertInto
    if (!InsertIntoFrom) return [ false, false ];

    const InsertIntoTo = ItemsList[ToItem.Item].InsertInto
    const IsReversed = InsertIntoTo && InsertIntoTo.includes(FromItem.Item);
    return [InsertIntoFrom.includes(ToItem.Item) || IsReversed, IsReversed]
}

$(document).on('mousemove', 'body', function(e) {
    if (!DragData.IsDragging) return;

    $('.drag-item').css({
        left: e.pageX - $('.drag-item').width() / 2,
        top: e.pageY - $('.drag-item').height() / 2,
    })
});

$(document).on('mousedown', '.inventory-box-slot', function(e) {
    if (e.button === 1 || e.button == 2) return false;
    if (DragData.IsDragging) return;
    if ($(this).hasClass('drag-item')) return;

    const FromContainer = $(this).closest('.inventory-box').attr('inventory-name') != 'player' ? 'other' : 'player';
    const FromInv = FromContainer == 'other' ? OtherInvData.Name : 'player';
    const FromSlot = $(this).attr('data-slot');

    const SlotData = GetContainerItems(FromContainer)[Number(FromSlot)];

    if (!SlotData) return;
    if (SlotData.Amount == 0) return;

    // The weapon in the attachments panel stays put while it's open.
    if (AttachmentPanel && FromContainer == 'player' && Number(FromSlot) == AttachmentPanel.Slot) {
        return InventoryLog('[Error]: Sluit eerst de attachments van dit wapen.');
    }

    // The magazine in the loader stays put while the loader is open.
    if (MagazineLoader && FromContainer == 'player' && Number(FromSlot) == MagazineLoader.Slot) {
        return InventoryLog('[Error]: Dit magazijn zit in de lader.');
    }

    // Quick move: Ctrl (AMOUNT) / Shift (half) to the other inventory.
    if (e.button === 0 && (window.event.ctrlKey || window.event.shiftKey)) {
        const ToContainer = FromContainer == 'player' ? 'other' : 'player';
        const ToInv = ToContainer == 'player' ? 'player' : OtherInvData.Name;

        if (FromInv == 'Crafting') return;
        if (OtherInvData.Type == 'None' || !OtherInvData.Name || OtherInvData.Name == 'None') return;

        if (ToContainer != 'player' && (OtherInvData.Type == 'Store' || OtherInvData.Type == 'Crafting')) {
            return InventoryLog("[Error]: Je kan hier geen items naar toe slepen.")
        };

        if (ToContainer != 'player' && OtherInvData.Type == 'Bag' && ItemsList[SlotData.Item].IsBag) {
            return InventoryLog("[Error]: Dit is geen Escape from Tarkov.")
        };

        const InvSpecificItems = GetInvSpecificItems(ToInv);
        if (InvSpecificItems && !InvSpecificItems.includes(SlotData.Item)) {
            return InventoryLog('[Error]: Je kan deze item niet in deze inventory plaatsen.')
        };

        const ToSlot = FindTargetSlot(ToContainer, SlotData);
        if (!ToSlot || ToSlot > GetContainerMaxSlots(ToContainer)) return InventoryLog("[Error]: Inventory is vol.");

        let MoveAmount = Number($('#inventory-move-amount').val()) || SlotData.Amount;
        if (window.event.shiftKey) MoveAmount = Math.ceil(SlotData.Amount / 2);
        if (MoveAmount > SlotData.Amount) MoveAmount = SlotData.Amount;
        if (MoveAmount <= 0 || MoveAmount == undefined) return InventoryLog("[Error]: Je moet een aantal invullen.");

        const ToItem = GetContainerItems(ToContainer)[ToSlot];

        const [IsValid, Reason, ClampedAmount] = ValidateMovement(FromContainer, ToContainer, FromSlot, ToSlot, SlotData, ToItem, MoveAmount, 'Move');
        if (!IsValid) { FlashSlot(this, false); return InventoryLog(`[Error]: ${Reason}`); }
        MoveAmount = ClampedAmount;

        const ToInvWeight = CalculateTotalInvWeight(GetContainerItems(ToContainer));
        const FromItemData = GetItemData(SlotData.Item, SlotData.CustomType);
        if ((FromItemData.Weight * MoveAmount) + ToInvWeight > GetContainerMaxWeight(ToContainer)) {
            return InventoryLog(ToContainer == 'player' ? "[Error]: Je bent te overgewicht." : "[Error]: Inventory is vol.");
        };

        UpdateInventorySlot(GetContainerBox(FromContainer), GetContainerBox(ToContainer), Number(FromSlot), ToSlot, SlotData, ToItem, MoveAmount, "Move")

        $.post(`https://fw-inventory/MoveItem`, JSON.stringify({
            FromInv: FromContainer != 'player' && OtherInvData.Type == 'Store' ? 'Store' : FromInv,
            ToInv: ToInv,
            FromSlot: Number(FromSlot),
            ToSlot: Number(ToSlot),
            Amount: MoveAmount,
            FromItem: SlotData.Item,
            ToItem: ToItem?.Item,
            FromType: SlotData.CustomType,
            ToType: ToItem?.CustomType,
            Store: OtherInvData.Store,
            Crafting: OtherInvData.Crafting,
        }));

        return;
    };

    DragData.IsDragging = true;
    DragData.FromInv = FromContainer != 'player' && OtherInvData.Type == 'Store' ? 'Store' : FromInv;
    DragData.FromContainer = FromContainer;
    DragData.FromSlot = Number(FromSlot);

    $('body').addClass('inv-dragging');

    // Highlight where this item can be equipped.
    // Bullets that fit the open magazine loader.
    const LoaderMag = GetLoaderMagazine();
    if (LoaderMag && FromContainer == 'player' && SlotData.Item == 'bullets' && SlotData.CustomType == LoaderMag.CustomType) {
        $('.mag-load-slot').addClass('equip-target');
    }

    if (AttachmentPanel && FromContainer == 'player') HighlightAttachmentTarget(SlotData);

    const EquipSlot = GetEquipSlotForItem(SlotData.Item);
    if (EquipSlot) {
        GetSlotElement('player', EquipSlot).addClass('equip-target');
        if (OtherInvData.IsPlayer) GetSlotElement('other', EquipSlot).addClass('equip-target');
    }

    $('.drag-item').html($(this).html());
    $('.drag-item').find('.inventory-slot-bind').remove();

    const MoveAmount = $('#inventory-move-amount').val();

    if (MoveAmount > 0 && MoveAmount <= SlotData.Amount) {
        $('.drag-item').find(".inventory-slot-info > .inventory-slot-quantity").text(`${MoveAmount}x`);
        $('.drag-item').find(".inventory-slot-info > .inventory-slot-weight").text(`${(ItemsList[SlotData.Item].Weight * MoveAmount).toFixed(1)}`);
    };

    $('.drag-item').css('opacity', '0.75');

    $('.drag-item').css({
        left: e.pageX - $('.drag-item').width() / 2,
        top: e.pageY - $('.drag-item').height() / 2,
    });
});

$(document).on('mouseup', 'body', async function(e) {
    const Target = $(e.target).closest('.inventory-box-slot');

    // Unloading bullets from the magazine loader (magazine.js).
    if (DragData.IsDragging && DragData.FromContainer == 'magazine') {
        if (!Target.length || Target.hasClass('drag-item')) return ResetDrag();
        const MagToContainer = Target.closest('.inventory-box').attr('inventory-name') != 'player' ? 'other' : 'player';
        return FinishMagazineUnload(MagToContainer, Number(Target.attr('data-slot')));
    }

    // Taking a magazine/attachment off a weapon (attachments.js).
    if (DragData.IsDragging && DragData.FromContainer == 'attachment') {
        if (!Target.length || Target.hasClass('drag-item')) return ResetDrag();
        const AttToContainer = Target.closest('.inventory-box').attr('inventory-name') != 'player' ? 'other' : 'player';
        return FinishAttachmentDetach(AttToContainer, Number(Target.attr('data-slot')));
    }

    // Dropped outside a slot.
    if (!Target.length || Target.hasClass('drag-item')) {
        ResetDrag();
        return
    };

    const ToContainer = Target.closest('.inventory-box').attr('inventory-name') != 'player' ? 'other' : 'player';
    const ToInv = ToContainer == 'other' ? OtherInvData.Name : 'player';
    const ToSlot = Number(Target.attr('data-slot'));

    // Middle click: use (wearables toggle equip).
    if (e.button == 1 && ToContainer == 'player') {
        const ItemData = MyInventory[ToSlot];
        if (ItemData == undefined) return;

        // Magazine: show the loader right here, the inventory stays open.
        if (ItemData.Item == 'magazine') return OpenMagazinePanel(ToSlot);

        CloseInventory()
        $.post("https://fw-inventory/UseItem", JSON.stringify({ Slot: ToSlot }));

        return;
    };

    if (!DragData.IsDragging) return;

    const FromContainer = DragData.FromContainer;
    ResetDrag();

    if (ToContainer != 'player' && IgnoredIntoInvDrag.includes(OtherInvData.Name)) return;
    if (DragData.FromSlot == ToSlot && FromContainer == ToContainer) return;

    const FromItem = GetContainerItems(FromContainer)[DragData.FromSlot];
    if (!FromItem) return;

    const ToItem = GetContainerItems(ToContainer)[ToSlot];

    const FromItemData = GetItemData(FromItem.Item, FromItem.CustomType);

    if (ToContainer != 'player' && OtherInvData.Type == 'Bag' && FromItemData.IsBag) {
        return InventoryLog("[Error]: Dit is geen Escape from Tarkov.")
    };

    const InvSpecificItems = GetInvSpecificItems(ToInv);
    if (InvSpecificItems && !InvSpecificItems.includes(FromItem.Item)) {
        return InventoryLog('[Error]: Je kan deze item niet in deze inventory plaatsen.')
    }

    var MoveAmount = Number($("#inventory-move-amount").val());
    var MoveType = "Move";

    if (DragData.FromInv != 'player' && (DragData.FromInv == 'Store' || DragData.FromInv == 'Crafting') && (MoveAmount <= 0 || MoveAmount == undefined)) return InventoryLog("[Error]: Je moet een aantal invullen.");

    if (MoveAmount <= 0 || MoveAmount > FromItem.Amount) MoveAmount = FromItem.Amount;
    if (ToItem && FromItem.Item != ToItem.Item) MoveType = "Swap"; // If not the same item, swap.
    if (ToItem && FromItem.CustomType && FromItem.CustomType != ToItem.CustomType) MoveType = "Swap"; // If not the same custom type, swap.
    if (ToItem && FromItem.Item == ToItem.Item && FromItemData.NonStack) MoveType = "Swap"; // If the same item, but not stackable, swap.

    // Pockets / Backpack / Body / Accessories rules.
    const [IsValid, Reason, ClampedAmount] = ValidateMovement(FromContainer, ToContainer, DragData.FromSlot, ToSlot, FromItem, ToItem, MoveAmount, MoveType);
    if (!IsValid) {
        FlashSlot(Target, false);
        return InventoryLog(`[Error]: ${Reason}`);
    }
    if (MoveType == 'Move') MoveAmount = ClampedAmount;

    const ToInvWeight = CalculateTotalInvWeight(GetContainerItems(ToContainer));

    // Weight check.
    if (FromContainer != ToContainer) {
        if ((FromItemData.Weight * MoveAmount) + ToInvWeight > GetContainerMaxWeight(ToContainer)) {
            return InventoryLog(ToContainer == 'player' ? "[Error]: Je bent te overgewicht." : "[Error]: Inventory is vol.");
        };
    };

    // Slot check
    if (ToSlot == 0 || ToSlot > GetContainerMaxSlots(ToContainer)) return InventoryLog("[Error]: Inventory is vol.");

    if (DragData.FromInv == 'Store' && FromItemData.Price * MoveAmount > PlayerCash) return InventoryLog("[Error]: Je hebt niet genoeg cash..");

    if (DragData.FromInv == 'Crafting' && !await HasCraftingItems(FromItem.Item, FromItem.CustomType, MoveAmount)) {
        return InventoryLog("[Error]: Je hebt niet alle materialen om dit te maken.")
    };

    if (ToContainer != 'player' && (OtherInvData.Type == 'Store' || OtherInvData.Type == 'Crafting')) return;
    if (DragData.FromInv != 'player' && (OtherInvData.Type == 'Store' || OtherInvData.Type == 'Crafting') && MoveType == 'Swap') return;

    const [ HasInsert, IsReversed ] = HasInsertInto(FromItem, ToItem)
    if (DragData.FromInv == 'player' && ToInv == 'player' && HasInsert) {
        $.post(`https://fw-inventory/InsertItem`, JSON.stringify({
            FromItem: FromItem,
            ToItem: ToItem,
            IsReversed
        }));

        CloseInventory();
        return;
    }

    if (DragData.FromInv == 'player' && ToInv == 'player' && ToItem?.Item && FromItem.Item == "repairhammer") {
        $.post(`https://fw-inventory/InsertItem`, JSON.stringify({
            FromItem: FromItem,
            ToItem: ToItem,
            IsReversed: false,
        }));
        return;
    }

    FlashSlot(Target, true);
    UpdateInventorySlot(GetContainerBox(FromContainer), GetContainerBox(ToContainer), DragData.FromSlot, ToSlot, FromItem, ToItem, MoveAmount, MoveType)

    $.post(`https://fw-inventory/${MoveType}Item`, JSON.stringify({
        FromInv: DragData.FromInv,
        ToInv: ToInv,
        FromSlot: DragData.FromSlot,
        ToSlot: ToSlot,
        Amount: MoveAmount,
        FromItem: FromItem.Item,
        ToItem: ToItem?.Item,
        FromType: FromItem.CustomType,
        ToType: ToItem?.CustomType,
        Store: OtherInvData.Store,
        Crafting: OtherInvData.Crafting,
        FromAmount: FromItem.Amount,
        ToAmount: ToItem?.Amount
    }));

    if (DragData.FromInv == 'Store') {
        setTimeout(() => {
            $.post("https://fw-inventory/FetchMoney", JSON.stringify({}), function(Cash){
                PlayerCash = Cash;
                GetContainerBox('other').find('.inventory-box-cash > span').text(Cash.toLocaleString('nl-NL', { style: 'currency', currency: 'EUR' })).parent().show();
            });
        }, 500);
    }
});

$(document).on('wheel', (e) => {
    if ($(e.target).attr("id") != "inventory-move-amount") return;

    var Amount = $("#inventory-move-amount").val();
    if (e.originalEvent.deltaY < 0) {
        Amount++;
        if (Amount > 9999) Amount = 9999;
    } else {
        Amount--;
        if (Amount < 0) Amount = 0;
    }

    $("#inventory-move-amount").val(Amount);
    if (!DragData.IsDragging) return;

    if (DragData.FromContainer == 'attachment') return;
    if (DragData.FromContainer == 'magazine') {
        const Bullets = GetMagazineBullets(GetLoaderMagazine());
        DragData.MagAmount = (Amount > 0 && Amount <= Bullets) ? Amount : Bullets;
        $('.drag-item').find(".inventory-slot-info > .inventory-slot-quantity").text(`${DragData.MagAmount}x`);
        return;
    }

    const FromItem = GetContainerItems(DragData.FromContainer)[DragData.FromSlot]
    if (!FromItem) return;

    const ItemData = GetItemData(FromItem.Item, FromItem.CustomType);
    if (ItemData == undefined) return;
    if (Amount == 0) Amount = FromItem.Amount;

    if (Amount <= FromItem.Amount) {
        $('.drag-item').find(".inventory-slot-info > .inventory-slot-quantity").text(`${Amount}x`);
        $('.drag-item').find(".inventory-slot-info > .inventory-slot-weight").text(`${(ItemData.Weight * Amount).toFixed(1)}`);
    }
});
