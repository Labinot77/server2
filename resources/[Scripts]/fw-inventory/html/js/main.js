$(document).ready(function(){
    $.post("https://fw-inventory/LoadInventory");

    window.addEventListener('message', event => {
        switch (event.data.Action) {
            case "SetItemsList":
                console.log(`[INVENTORY]: ItemsList loaded!`)
                ItemsList = event.data.Items;
                CustomTypes = event.data.CustomTypes;
                if (event.data.Layout) {
                    Layout = event.data.Layout;
                    MaxPlayerSlots = Layout.MaxPlayerSlots;
                    MaxPlayerWeight = Layout.MaxPlayerWeight;
                }
                break;
            case "SetCustomTypes":
                console.log(`[INVENTORY]: CustomTypes loaded!`)
                CustomTypes = event.data.CustomTypes;
                break;
            case "UpdateSlot":
                MyInventory[event.data.SlotId] = event.data.Data;
                RenderSlot('player', event.data.SlotId);

                // Backpack equipped/unequipped from outside the UI (use item, robbed, ...).
                if (event.data.SlotId == Layout.BackpackSlot) RefreshBackpackState('player');
                UpdateInventoryWeights('player');
                break;
            case "SetPlayerLimits":
                if (InventoryOpen) RefreshBackpackState('player');
                break;
            case "OpenInventory":
                InventoryOpen = true;
                OtherInvData = event.data.OtherData;
                MyInventory = event.data.Inventory;
                HasWeaponsLicense = event.data.HasLicense;
                if (event.data.PlayerName) $('#ox-player-name').text(event.data.PlayerName);

                BuildInventory('player', 'Player', MyInventory, MaxPlayerSlots);
                BuildInventory('other', OtherInvData.Type, OtherInvData.Items, OtherInvData.Slots);

                $('.actions-wrapper > .inventory-actions > #steal-money').remove();
                if (OtherInvData.Type == 'Other Player') {
                    $('.actions-wrapper > .inventory-actions').append(`<button class="inventory-actions-btn${OtherInvData.Cash === 0 ? ' disabled' : ''}" id="steal-money">Geld Stelen</button>`)
                }

                $('.inventory-wrapper').fadeIn(100);
                break;
            case "CloseInventory":
                InventoryOpen = false;
                ResetDrag();
                CloseContextMenu();
                CloseSplitModal();
                $('.inventory-slot-hover').css({ opacity: 0 });
                $('.inventory-wrapper').fadeOut(100);
                break;
            case "InventoryHotbar":
                if (event.data.Visible) {
                    $('.inventory-hotbar').stop(true, true).empty();
                    for (let i = 1; i <= 5; i++) {
                        const Item = event.data.Items[i];
    
                        if (Item && ItemsList[Item.Item]) {
                            const ItemData = GetItemData(Item.Item, Item.CustomType);
                            $('.inventory-hotbar').append(`<div class="inventory-hotbar-slot">
                                <div class="inventory-slot-bind" style="font-size: 6vh">${i}</div>
                                <div class="inventory-slot-name">${ItemData.Label} ${Item.Info && Item.Info.Ammo ? `- ${Item.Info.Ammo}` : ''}</div>
                                <div class="inventory-slot-image" style="background-image: url(${GetItemImage(Item.Item, Item.CustomType, Item.Info)})"></div>
                            </div>`);
                        } else {
                            $('.inventory-hotbar').append(`<div class="inventory-hotbar-slot">
                                <div class="inventory-slot-bind" style="font-size: 6vh">${i}</div>
                                <div class="inventory-slot-name"></div>
                            </div>`);
                        }
                    }

                    $('.inventory-hotbar').show();
                } else {
                    $('.inventory-hotbar').fadeOut(2000);
                };
                break;
            case "SetOtherCash":
                if (OtherInvData) OtherInvData.Cash = event.data.Cash;
                SetOtherCash(event.data.Cash);
                break;
            case "PlaceHint": // handled in contextmenu.js
                break;
            case "InventoryBox":
                InventoryBox(event.data.Text, event.data.Item, event.data.Amount, event.data.CustomType)
                break;
            default:
                console.log(`[INVENTORY]: Invalid Action: '${event.data.Action}'`)
                console.log(`[INVENTORY]: Payload:\n${JSON.stringify(event.data, undefined, 2)}`)
                break;
        };
    });
});

const CloseInventory = () => {
    InventoryOpen = false;

    $.post("https://fw-inventory/CloseInventory")
    $('.inventory-wrapper').fadeOut(100);

    ResetDrag();
    CloseContextMenu();
    CloseSplitModal();
    $('.inventory-slot-hover').css('opacity', '0.0');
};

// $(document).on('click', '#inventory-wrapper', function (e) {
//     // Check if the clicked element is exactly #inventory-wrapper and not a child element
//     if (e.target.id === "inventory-wrapper") {
//         $.post("https://fw-inventory/CloseInventory", JSON.stringify({}));
//     }
// });


$(document).on("click", '#steal-money', function(e){
    $.post("https://fw-inventory/StealMoney", JSON.stringify({}));
});

$(document).on("keydown", function(e){
    if (window.event.ctrlKey && e.keyCode == 67) {
        CopyToClipboard($(".inventory-slot-hover > .inventory-hover-info").text());
    }
});

$(document).on({
    mouseenter: function(){ $('.inventory-help-menu').fadeIn(150); },
    mouseleave: function(){ $('.inventory-help-menu').fadeOut(150); },
}, '#inventory-action-help');

$(document).on("keydown", 'body', function(e){
    if (!window.event.ctrlKey && e.keyCode == 67) {
        $("#inventory-move-amount").val('');
    }
});

document.onkeyup = function(Data) {
    if (Data.which == 27 && IsOverlayOpen()) {
        CloseContextMenu();
        CloseSplitModal();
        return;
    }

    if (Data.which == 27 && InventoryOpen) {
        CloseInventory()
    };
};

$(document).on('click', '#inventory-close', function(Event) {
    Event.preventDefault();
    CloseInventory()
});

$(document).on('mouseup', '#inventory-use', function(e){
    if (!DragData.IsDragging) return;
    if (DragData.FromInv != 'player') return;

    const Slot = DragData.FromSlot;
    CloseInventory();
    setTimeout(() => {
        $.post("https://fw-inventory/UseItem", JSON.stringify({ Slot }));
    }, 250);
});

$(document).on({
    mouseover: function (e){
        var FromInv = $(this).closest('.inventory-box').attr('inventory-name');
        var Text = GenerateItemInfo(FromInv == 'player' ? 'player' : OtherInvData.Name, $(this).attr("data-slot"));
        if (!Text) return;

        const Hover = $('.inventory-slot-hover');
        Hover.html(Text);

        // Right of the slot, flipped to the left / clamped when it would leave the screen.
        const ItemOffset = $(this).offset(), SlotWidth = $(this).outerWidth();
        let LeftOffset = ItemOffset.left + SlotWidth + 8;
        if (LeftOffset + Hover.outerWidth() > $(window).width() - 10) LeftOffset = ItemOffset.left - Hover.outerWidth() - 8;
        let TopOffset = Math.min(ItemOffset.top, $(window).height() - Hover.outerHeight() - 10);

        Hover.css({ opacity: 1, top: Math.max(10, TopOffset), left: Math.max(10, LeftOffset) });
    },
    mouseleave: function (e){
        $('.inventory-slot-hover').css({opacity: '0.0'});
    }
}, ".inventory-box-slot");