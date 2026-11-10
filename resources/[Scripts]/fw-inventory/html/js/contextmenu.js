// ============================================================================
//  Right-click context menu: SPLIT / GIVE (ox_inventory style)
//   Split -> modal, moves N of the stack into the first empty slot of the same inventory.
//   Give  -> closes the inventory and puts the item in your hand (client/cl_hand.lua):
//            N = place, E = throw, Esc = cancel.
// ============================================================================

let ContextData = false; // { Container, Slot }
let SplitData = false;   // { Container, Slot }

const IsShopContainer = (Container) => Container != 'player' && (OtherInvData.Type == 'Store' || OtherInvData.Type == 'Crafting');
const ContainerInvName = (Container) => Container == 'player' ? 'player' : OtherInvData.Name;

const CloseContextMenu = () => {
    $('.inv-options').hide();
    $('.inventory-box-slot.ctx-active').removeClass('ctx-active');
    ContextData = false;
};

const CloseSplitModal = () => {
    $('#split-modal').hide();
    SplitData = false;
};

const IsOverlayOpen = () => $('.inv-options').is(':visible') || $('#split-modal').is(':visible');

// First EMPTY slot in the same inventory (a split must not merge back into a stack).
const FindEmptySlot = (Container, Item) => {
    const Items = GetContainerItems(Container);

    if (IsPlayerContainer(Container)) {
        for (const Range of [Layout.SlotLayout.Pockets, Layout.SlotLayout.Backpack]) {
            for (let i = Range[0]; i <= Range[1]; i++) {
                if (!Items[i] && ValidatePlayerSlot(Items, i, Item.Item, 1)[0]) return i;
            }
        }
        return false;
    }

    for (let i = 1; i <= GetContainerMaxSlots(Container); i++) {
        if (!Items[i]) return i;
    }
    return false;
};

const GetHoldAmount = (Item) => {
    const Amount = Number($('#inventory-move-amount').val());
    return (Amount > 0 && Amount <= Item.Amount) ? Amount : Item.Amount;
};

const BuildContextOptions = (Container, Slot, Item) => {
    const Options = [];
    const CanSplit = !IsShopContainer(Container) && Item.Amount > 1;

    Options.push({ Id: 'split', Label: 'Split', Icon: 'call_split', Disabled: !CanSplit });
    if (Container == 'player') Options.push({ Id: 'give', Label: 'Give', Icon: 'back_hand' });

    return Options;
};

const OpenContextMenu = (Element, Container, Slot, MouseX, MouseY) => {
    const Item = GetContainerItems(Container)[Slot];
    if (!Item || !ItemsList[Item.Item]) return;
    if (IsShopContainer(Container)) return;

    const ItemData = GetItemData(Item.Item, Item.CustomType, Item.Info);
    const Quality = CalculateQuality(Item.Item, Item.CreateDate);
    const Menu = $('.inv-options');

    Menu.find('.ctx-type').text(GetItemTypeLabel(Container, Slot, ItemData));
    Menu.find('.ctx-name').text(ItemData.Label);
    Menu.find('.ctx-weight b').text(`${(ItemData.Weight * Item.Amount).toFixed(1)}`);
    Menu.find('.ctx-dur b').text(Quality.Percentage).css('color', GetQualityColor(Quality.Percentage));

    const List = Menu.find('.inv-options-list').empty();
    for (const Option of BuildContextOptions(Container, Slot, Item)) {
        List.append(`<div class="inv-option-item${Option.Disabled ? ' disabled' : ''}" data-option="${Option.Id}">
            <span class="material-symbols-outlined">${Option.Icon}</span>${Option.Label}
        </div>`);
    }

    ContextData = { Container, Slot };
    $('.inventory-box-slot.ctx-active').removeClass('ctx-active');
    $(Element).addClass('ctx-active');
    $('.inventory-slot-hover').css({ opacity: 0 });

    Menu.show();
    const Left = Math.min(MouseX + 6, $(window).width() - Menu.outerWidth() - 10);
    const Top = Math.min(MouseY + 6, $(window).height() - Menu.outerHeight() - 10);
    Menu.css({ left: Left, top: Top });
};

$(document).on('contextmenu', '.inventory-box-slot', function(e) {
    e.preventDefault();
    if (DragData.IsDragging || $(this).hasClass('drag-item')) return false;

    const Container = $(this).closest('.inventory-box').attr('inventory-name') != 'player' ? 'other' : 'player';
    OpenContextMenu(this, Container, Number($(this).attr('data-slot')), e.pageX, e.pageY);
    return false;
});

$(document).on('contextmenu', function(e) { e.preventDefault(); });

// Click outside closes the menu.
$(document).on('mousedown', function(e) {
    if (!$('.inv-options').is(':visible')) return;
    if ($(e.target).closest('.inv-options').length) return;
    CloseContextMenu();
});

$(document).on('click', '.inv-option-item', function(e) {
    if (!ContextData) return;
    const { Container, Slot } = ContextData;
    const Option = $(this).attr('data-option');
    CloseContextMenu();

    const Item = GetContainerItems(Container)[Slot];
    if (!Item) return;

    if (Option == 'split') return OpenSplitModal(Container, Slot);
    if (Option == 'give') return GiveItem(Slot, Item);
});

// ---------------------------------------------------------------------------
//  Give -> item in hand
// ---------------------------------------------------------------------------
const GiveItem = (Slot, Item) => {
    const Amount = GetHoldAmount(Item);

    // The Lua side closes the inventory properly, just hide the UI here.
    InventoryOpen = false;
    ResetDrag();
    $('.inventory-slot-hover').css({ opacity: 0 });
    $('.inventory-wrapper').fadeOut(100);

    $.post("https://fw-inventory/HoldItem", JSON.stringify({ Slot, Amount }));
};

// ---------------------------------------------------------------------------
//  Split
// ---------------------------------------------------------------------------
const SetSplitAmount = (Amount) => {
    if (!SplitData) return;
    const Item = GetContainerItems(SplitData.Container)[SplitData.Slot];
    if (!Item) return;

    const Max = Item.Amount - 1;
    Amount = Math.max(1, Math.min(Math.floor(Number(Amount) || 1), Max));

    $('#split-amount').val(Amount);
    $('#split-range').val(Amount).css('background-size', `${Max > 1 ? ((Amount - 1) * 100) / (Max - 1) : 100}% 100%`);
    return Amount;
};

const OpenSplitModal = (Container, Slot) => {
    const Item = GetContainerItems(Container)[Slot];
    if (!Item || Item.Amount < 2) return;

    const ItemData = GetItemData(Item.Item, Item.CustomType, Item.Info);
    SplitData = { Container, Slot };

    $('.split-img').css('background-image', `url(${GetItemImage(Item.Item, Item.CustomType, Item.Info)})`);
    $('.split-name').text(`${ItemData.Label} (${Item.Amount}x)`);
    $('#split-range').attr({ min: 1, max: Item.Amount - 1 });
    $('#split-amount').attr({ min: 1, max: Item.Amount - 1 });
    SetSplitAmount(Math.floor(Item.Amount / 2));

    $('#split-modal').css('display', 'flex');
    setTimeout(() => $('#split-amount').trigger('focus').trigger('select'), 30);
};

const DoSplit = (Container, Slot, Amount) => {
    const Item = GetContainerItems(Container)[Slot];
    if (!Item || Amount < 1 || Amount >= Item.Amount) return;
    if (IsShopContainer(Container)) return;

    const ToSlot = FindEmptySlot(Container, Item);
    if (!ToSlot) return InventoryLog('[Error]: Geen lege slot om te splitsen.');

    const [IsValid, Reason] = ValidateMovement(Container, Container, Slot, ToSlot, Item, undefined, Amount, 'Move');
    if (!IsValid) return InventoryLog(`[Error]: ${Reason}`);

    const Box = GetContainerBox(Container);
    UpdateInventorySlot(Box, Box, Slot, ToSlot, Item, undefined, Amount, 'Move');
    FlashSlot(GetSlotElement(Container, ToSlot), true);

    const InvName = ContainerInvName(Container);
    $.post(`https://fw-inventory/MoveItem`, JSON.stringify({
        FromInv: InvName,
        ToInv: InvName,
        FromSlot: Slot,
        ToSlot: ToSlot,
        Amount: Amount,
        FromItem: Item.Item,
        ToItem: undefined,
        FromType: Item.CustomType,
        ToType: undefined,
        FromAmount: Item.Amount,
    }));
};

$(document).on('input', '#split-range', function() { SetSplitAmount($(this).val()); });
$(document).on('change', '#split-amount', function() { SetSplitAmount($(this).val()); });
$(document).on('click', '#split-cancel', CloseSplitModal);
$(document).on('click', '#split-modal', function(e) { if (e.target.id == 'split-modal') CloseSplitModal(); });

$(document).on('click', '#split-confirm', function() {
    if (!SplitData) return;
    const { Container, Slot } = SplitData;
    const Amount = SetSplitAmount($('#split-amount').val());
    CloseSplitModal();
    DoSplit(Container, Slot, Amount);
});

$(document).on('keydown', '#split-amount', function(e) {
    if (e.keyCode == 13) { e.preventDefault(); $('#split-confirm').trigger('click'); }
    e.stopPropagation(); // don't clear AMOUNT with "C" etc.
});

// ---------------------------------------------------------------------------
//  Item-in-hand hint bar (from Lua: PlaceHint)
// ---------------------------------------------------------------------------
window.addEventListener('message', (event) => {
    if (event.data.Action != 'PlaceHint') return;
    const Mode = event.data.Mode;
    if (Mode) {
        $('.place-box').attr('data-mode', Mode).show();
    } else {
        $('.place-box').hide().attr('data-mode', '');
    }
});
