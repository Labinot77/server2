const MaxTime = (((1000 * 60) * 60) * 24) * 28;

// ============================================================================
//  Item data
// ============================================================================
const GetItemData = (ItemName, CustomType, ItemInfo) => {
    var ItemData = {...ItemsList[ItemName]};
    if (CustomType) {
        const CustomItemType = CustomTypes[ItemName] && CustomTypes[ItemName][CustomType] || {}
        if (CustomItemType.Label) ItemData.Label = CustomItemType.Label;
        if (CustomItemType.Image) ItemData.Image = CustomItemType.Image;
        if (CustomItemType.Description) ItemData.Description = CustomItemType.Description;
        if (CustomItemType.IsExternImage) ItemData.IsExternImage = CustomItemType.IsExternImage;
        if (CustomItemType.Price) ItemData.Price = CustomItemType.Price;
        if (CustomItemType.Craft) ItemData.Craft = CustomItemType.Craft;
    }

    if (ItemInfo) {
        if (ItemInfo._Label) ItemData.Label = ItemInfo._Label;
        if (ItemInfo._Description) ItemData.Description = ItemInfo._Description;
        if (ItemInfo._Image) {
            ItemData.Image = ItemInfo._Image
            ItemData.IsExternImage = true;
        };
    }

    return ItemData;
};

const GetItemImage = (ItemName, CustomType, ItemInfo) => {
    const ItemData = GetItemData(ItemName, CustomType, ItemInfo);
    if (ItemData.IsExternImage) return ItemData.Image;
    return `./img/items/${ItemData.Image}`;
};

const CalculateQuality = (ItemName, CreateDate) => {
    var StartDate = new Date(CreateDate).getTime();
    var DecayRate = ItemsList[ItemName].DecayRate;
    var TimeExtra = MaxTime * DecayRate;
    var Quality = 100 - Math.ceil(((Date.now() - StartDate) / TimeExtra) * 100);

    if (DecayRate == 0) Quality = 100;
    if (Quality <= 0) Quality = 0;
    if (Quality >= 99.0) Quality = 100; // because lua uses seconds, and not milliseconds its never 100%, so we'll just pretend it is.

    var QualityClass = 'inventory-slot-quality';
    if (Quality <= 0) QualityClass = 'inventory-slot-quality broken';

    return {
        Percentage: Quality,
        Class: QualityClass,
    };
};

const GetQualityColor = (Percentage) => {
    if (Percentage > 75) return '#5FF03C';
    if (Percentage > 50) return '#74C242';
    if (Percentage > 25) return '#DEB837';
    return '#CC2727';
};

const InventoryLog = (Text) => {
    $('.inventory-wrapper > .logs').prepend(`${Text}<br/>`);
    const Logs = $('.inventory-wrapper > .logs');
    clearTimeout(Logs.data('timer'));
    Logs.data('timer', setTimeout(() => Logs.empty(), 6000));
};

// ============================================================================
//  Layout rules (mirror of config/_sh_config.lua — the server re-validates)
// ============================================================================
const GetEquipSlot = (Slot) => Layout.EquipSlots.find(v => v.Slot == Number(Slot));
const IsEquipSlot = (Slot) => GetEquipSlot(Slot) !== undefined;

const GetSlotSection = (Slot) => {
    Slot = Number(Slot);
    for (const Section of SectionOrder) {
        const Range = Layout.SlotLayout[Section];
        if (Range && Slot >= Range[0] && Slot <= Range[1]) return Section;
    }
    return false;
};

const CanItemGoInSlot = (ItemName, Slot) => {
    const EquipSlot = GetEquipSlot(Slot);
    if (!EquipSlot) return true;
    return EquipSlot.Items.includes(ItemName);
};

const GetEquipSlotForItem = (ItemName) => {
    const EquipSlot = Layout.EquipSlots.find(v => v.Items.includes(ItemName));
    return EquipSlot ? EquipSlot.Slot : false;
};

const GetBackpackData = (Items) => {
    const Item = Items && Items[Layout.BackpackSlot];
    if (!Item) return false;
    return Layout.Backpacks.find(v => v.Name == Item.Item) || false;
};

const GetUnlockedBackpackSlots = (Items) => {
    const BagData = GetBackpackData(Items);
    if (!BagData) return 0;
    const Range = Layout.SlotLayout.Backpack;
    const MaxBagSlots = Range[1] - Range[0] + 1;
    return Math.min(BagData.Slots || MaxBagSlots, MaxBagSlots);
};

const IsBackpackSlotUnlocked = (Items, Slot) => {
    Slot = Number(Slot);
    if (GetSlotSection(Slot) != 'Backpack') return true;
    return Slot < Layout.SlotLayout.Backpack[0] + GetUnlockedBackpackSlots(Items);
};

const IsBackpackEmpty = (Items) => {
    const Range = Layout.SlotLayout.Backpack;
    for (let i = Range[0]; i <= Range[1]; i++) if (Items[i]) return false;
    return true;
};

const GetPlayerMaxWeight = (Items) => {
    const BagData = GetBackpackData(Items);
    return Layout.MaxPlayerWeight + (BagData ? (BagData.Weight || 0) : 0);
};

const ValidatePlayerSlot = (Items, Slot, ItemName, Amount) => {
    Slot = Number(Slot);
    if (!Slot || Slot < 1 || Slot > Layout.MaxPlayerSlots) return [false, 'Ongeldige slot.'];

    if (!CanItemGoInSlot(ItemName, Slot)) return [false, `Dit kan niet in het ${GetEquipSlot(Slot).Label} vak.`];
    if (IsEquipSlot(Slot) && Amount > 1) return [false, 'Je kan maar 1 item uitrusten.'];
    if (!IsBackpackSlotUnlocked(Items, Slot)) return [false, 'Je hebt geen (grotere) rugzak om.'];
    if (GetSlotSection(Slot) == 'Backpack' && Layout.Backpacks.find(v => v.Name == ItemName)) return [false, 'Je kan geen rugzak in een rugzak stoppen.'];

    return [true];
};

// 'player' | 'other'  ->  data / element / rules
const GetContainerItems = (Container) => Container == 'player' ? MyInventory : OtherInvData.Items;
const GetContainerBox = (Container) => $(`.inventory-box[inventory-name="${Container}"]`);
const IsPlayerContainer = (Container) => Container == 'player' || (Container == 'other' && !!OtherInvData.IsPlayer);
const GetContainerMaxSlots = (Container) => Container == 'player' ? Layout.MaxPlayerSlots : OtherInvData.Slots;
const GetContainerMaxWeight = (Container) => {
    if (IsPlayerContainer(Container)) return GetPlayerMaxWeight(GetContainerItems(Container));
    return OtherInvData.Weight;
};

const CanRemoveBackpack = (Items, LeavesInventory) => {
    if (!IsBackpackEmpty(Items)) return [false, 'Maak eerst je rugzak leeg.'];

    let Remaining = 0.0;
    for (const [Slot, Item] of Object.entries(Items)) {
        if (!Item) continue;
        if (LeavesInventory && Number(Slot) == Layout.BackpackSlot) continue;
        Remaining += Item.Amount * GetItemData(Item.Item, Item.CustomType).Weight;
    }
    if (Remaining > Layout.MaxPlayerWeight) return [false, 'Je draagt te veel om je rugzak af te doen.'];

    return [true];
};

// Returns [IsValid, Reason, Amount] — Amount may be clamped to 1 for equip slots.
const ValidateMovement = (FromContainer, ToContainer, FromSlot, ToSlot, FromItem, ToItem, Amount, MoveType) => {
    FromSlot = Number(FromSlot); ToSlot = Number(ToSlot);
    const FromIsPlayer = IsPlayerContainer(FromContainer), ToIsPlayer = IsPlayerContainer(ToContainer);
    const FromItems = GetContainerItems(FromContainer), ToItems = GetContainerItems(ToContainer);
    const SameSlot = FromContainer == ToContainer && FromSlot == ToSlot;

    if (MoveType == 'Move') {
        if (ToIsPlayer) {
            if (IsEquipSlot(ToSlot)) {
                Amount = 1;
                if (ToItem && !SameSlot) return [false, 'Dit vak is al bezet.'];
            }
            const [Valid, Reason] = ValidatePlayerSlot(ToItems, ToSlot, FromItem.Item, Amount);
            if (!Valid) return [false, Reason];
        }

        if (FromIsPlayer && FromSlot == Layout.BackpackSlot && !SameSlot) {
            const [Valid, Reason] = CanRemoveBackpack(FromItems, FromContainer != ToContainer);
            if (!Valid) return [false, Reason];
        }
    } else {
        if (ToIsPlayer) {
            const [Valid, Reason] = ValidatePlayerSlot(ToItems, ToSlot, FromItem.Item, FromItem.Amount);
            if (!Valid) return [false, Reason];
        }
        if (FromIsPlayer && ToItem) {
            const [Valid, Reason] = ValidatePlayerSlot(FromItems, FromSlot, ToItem.Item, ToItem.Amount);
            if (!Valid) return [false, Reason];
        }

        const OwnerItems = (FromIsPlayer && FromSlot == Layout.BackpackSlot) ? FromItems : ((ToIsPlayer && ToSlot == Layout.BackpackSlot) ? ToItems : false);
        if (OwnerItems && !IsBackpackEmpty(OwnerItems)) return [false, 'Maak eerst je rugzak leeg.'];
    }

    return [true, '', Amount];
};

// ============================================================================
//  Slot finding
// ============================================================================
const FindSlot = (Items, Slots, SlotData) => {
    for (let i = 1; i <= Slots; i++) {
        const Item = Items[i];
        if (!Item || (Item && Item.Item == SlotData.Item && Item.CustomType == SlotData.CustomType && !ItemsList[SlotData.Item].NonStack)) {
            return i
        };
    };
    return false
}

// Same order as the server: own body slot (ID/phone/...) -> pockets -> unlocked backpack.
const FindPlayerSlot = (Items, SlotData) => {
    const ItemData = ItemsList[SlotData.Item];
    const EquipSlot = GetEquipSlotForItem(SlotData.Item);
    if (EquipSlot && GetSlotSection(EquipSlot) == 'Body' && !GetEquipSlot(EquipSlot).IsBackpack && !Items[EquipSlot]) return EquipSlot;

    const Ranges = [Layout.SlotLayout.Pockets, Layout.SlotLayout.Backpack];
    const CanUse = (i) => ValidatePlayerSlot(Items, i, SlotData.Item, 1)[0];

    for (const Range of Ranges) for (let i = Range[0]; i <= Range[1]; i++) {
        const Item = Items[i];
        if (Item && CanUse(i) && Item.Item == SlotData.Item && Item.CustomType == SlotData.CustomType && !ItemData.NonStack) return i;
    }
    for (const Range of Ranges) for (let i = Range[0]; i <= Range[1]; i++) {
        if (!Items[i] && CanUse(i)) return i;
    }
    return false;
};

const FindTargetSlot = (Container, SlotData) => {
    if (IsPlayerContainer(Container)) return FindPlayerSlot(GetContainerItems(Container), SlotData);
    return FindSlot(GetContainerItems(Container), GetContainerMaxSlots(Container), SlotData);
};

// ============================================================================
//  Weights
// ============================================================================
const CalculateTotalInvWeight = (Items) => {
    let Retval = 0.0;

    Items = Object.values(Items);
    for (let i = 0; i < Items.length; i++) {
        const Item = Items[i];
        if (Item && ItemsList[Item.Item]) Retval = Retval + (Item.Amount * ItemsList[Item.Item].Weight);
    }

    return Retval;
};

const UpdateInventoryWeights = (InvContainer) => {
    const Inventory = GetContainerBox(InvContainer);
    const Weight = CalculateTotalInvWeight(GetContainerItems(InvContainer));
    const Max = GetContainerMaxWeight(InvContainer) || 1;
    const Percentage = Math.min((Weight * 100) / Max, 100);

    Inventory.find('.weight-now').first().text(Weight.toFixed(1));
    Inventory.find('.weight-max').first().text(Number(Max).toFixed(1));
    Inventory.find('.inventory-box-header-weight').first().toggleClass('overweight', Weight > Max);

    const Fill = Inventory.find('.weightbar-fill').first();
    Fill.toggleClass('heavy', Percentage >= 75 && Percentage < 95).toggleClass('full', Percentage >= 95);
    Fill.stop(true, true).animate({ width: `${Percentage}%` }, 250);
};

// ============================================================================
//  Rendering
// ============================================================================
const GetSlotElement = (Container, Slot) => GetContainerBox(Container).find(`.inventory-box-slot[data-slot="${Slot}"]`);

const BuildSlotHtml = (Container, Slot, Item) => {
    Slot = Number(Slot);
    const IsPlayer = IsPlayerContainer(Container);
    const IsStore = Container != 'player' && OtherInvData.Type == 'Store';
    let Html = '';

    if (Container == 'player' && Slot <= 5) Html += `<div class="inventory-slot-bind">${Slot}</div>`;

    if (!Item || !ItemsList[Item.Item]) {
        if (IsPlayer && IsEquipSlot(Slot)) {
            const EquipSlot = GetEquipSlot(Slot);
            Html += `<span class="material-symbols-outlined emptyicon">${EquipSlot.Icon}</span><div class="emptylabel">${EquipSlot.Label}</div>`;
        } else if (IsPlayer && !IsBackpackSlotUnlocked(GetContainerItems(Container), Slot)) {
            Html += `<span class="material-symbols-outlined lockicon">lock</span>`;
        }
        return Html;
    }

    const ItemData = GetItemData(Item.Item, Item.CustomType, Item.Info);
    const Weight = (ItemData.Weight * Item.Amount).toFixed(1);

    if (IsStore) {
        return Html + `
            <div class="inventory-slot-price">€${ItemData.Price}</div>
            <div class="inventory-slot-image" style="background-image: url(${GetItemImage(Item.Item, Item.CustomType, Item.Info)})"></div>
            <div class="inventory-slot-info"><span class="inventory-slot-quantity">${Item.Amount}x</span><span class="inventory-slot-weight">${Weight}</span></div>
            <div class="inventory-slot-name">${ItemData.Label}</div>
        `;
    }

    const QualityData = CalculateQuality(Item.Item, Item.CreateDate);

    // Magazines show how full they are instead of "1x".
    let Quantity = `<span class="inventory-slot-quantity">${Item.Amount}x</span>`;
    if (Item.Item == 'magazine' && Layout.Magazines && Layout.Magazines[Item.CustomType]) {
        const Bullets = Math.max(0, Math.floor(Number(Item.Info && Item.Info.Bullets) || 0));
        Quantity = `<span class="inventory-slot-quantity mag-qty${Bullets == 0 ? ' empty' : ''}">${Bullets}/${Layout.Magazines[Item.CustomType].Capacity}</span>`;
    }

    return Html + `
        <div class="inventory-slot-image" style="background-image: url(${GetItemImage(Item.Item, Item.CustomType, Item.Info)})"></div>
        <div class="inventory-slot-info">${Quantity}<span class="inventory-slot-weight">${Weight}</span></div>
        <div class="inventory-slot-name">${ItemData.Label}</div>
        <div class="${QualityData.Class}" style="width: ${QualityData.Percentage}%; background: ${GetQualityColor(QualityData.Percentage)}"></div>
    `;
};

const RenderSlot = (Container, Slot) => {
    const Element = GetSlotElement(Container, Slot);
    if (!Element.length) return;

    const Item = GetContainerItems(Container)[Number(Slot)];
    const IsPlayer = IsPlayerContainer(Container);

    Element.html(BuildSlotHtml(Container, Slot, Item));
    Element.toggleClass('has-item', !!(Item && ItemsList[Item.Item]));
    Element.toggleClass('locked', !!(IsPlayer && !IsBackpackSlotUnlocked(GetContainerItems(Container), Slot)));
};

const SlotElementHtml = (Slot, ExtraClass = '') => `<div data-slot="${Slot}" class="inventory-box-slot ${ExtraClass}"></div>`;

const RangeSlots = (Range) => {
    const Retval = [];
    for (let i = Range[0]; i <= Range[1]; i++) Retval.push(i);
    return Retval;
};

// Updates the BACKPACK header + lock state of every backpack slot.
const RefreshBackpackState = (Container = 'player') => {
    const Items = GetContainerItems(Container);
    const BagData = GetBackpackData(Items);
    const Unlocked = GetUnlockedBackpackSlots(Items);

    if (Container == 'player') {
        const Block = GetContainerBox('player').find('.ox-backpack');
        Block.toggleClass('equipped', !!BagData);
        Block.find('.ox-backpack-state .material-symbols-outlined').text(BagData ? 'backpack' : 'lock');
        Block.find('.ox-backpack-text').text(BagData ? `${Unlocked} slots · +${Number(BagData.Weight || 0).toFixed(0)}kg` : 'No backpack');
    } else {
        GetContainerBox('other').find('.other-section[data-section="Backpack"] .ox-backpack-text').text(BagData ? `${Unlocked} slots` : 'No backpack');
    }

    for (const Slot of RangeSlots(Layout.SlotLayout.Backpack)) RenderSlot(Container, Slot);
    UpdateInventoryWeights(Container);
};

const BuildPlayerInventory = () => {
    const Inventory = GetContainerBox('player');
    for (const Section of SectionOrder) {
        const Grid = Inventory.find(`.inventory-box-slots[data-section="${Section}"]`).empty();
        for (const Slot of RangeSlots(Layout.SlotLayout[Section])) {
            Grid.append(SlotElementHtml(Slot, IsEquipSlot(Slot) ? 'equip-slot' : ''));
            RenderSlot('player', Slot);
        }
    }
    RefreshBackpackState('player');
};

const SectionTitles = { Pockets: 'Pockets', Backpack: 'Backpack', Body: 'Body', Accessories: 'Accessories' };

const BuildOtherPlayerInventory = (Grid) => {
    Grid.addClass('is-player');
    for (const Section of SectionOrder) {
        const Block = $(`<div class="other-section" data-section="${Section}">
            <div class="ox-sub-header"><span class="ox-sub-title">${SectionTitles[Section]}</span>${Section == 'Backpack' ? `<span class="ox-weight"><span class="ox-backpack-text"></span></span>` : ''}</div>
            <div class="other-section-slots"></div>
        </div>`);
        const Slots = Block.find('.other-section-slots');
        for (const Slot of RangeSlots(Layout.SlotLayout[Section])) Slots.append(SlotElementHtml(Slot, IsEquipSlot(Slot) ? 'equip-slot' : ''));
        Grid.append(Block);
    }
    for (let i = 1; i <= Layout.MaxPlayerSlots; i++) RenderSlot('other', i);
    RefreshBackpackState('other');
};

const BuildInventory = (InvContainer, InvType, Items, MaxSlots) => {
    if (InvContainer == 'player') return BuildPlayerInventory();

    const Inventory = GetContainerBox('other');
    const Grid = Inventory.find('.inventory-box-slots').empty().removeClass('is-player inventory-craft-slots');

    const Names = { 'Player': 'Player', 'Store': 'Store', 'Drop': 'Ground', 'Other Player': 'Player', 'None': 'Ground' };
    Inventory.find('.inventory-box-header-name').text(OtherInvData.Label || Names[InvType] || InvType);

    const IsStore = OtherInvData.Type == 'Store', IsCrafting = OtherInvData.Type == 'Crafting';
    Inventory.find('.inventory-box-header-weight, .inventory-box-header-weightbar').toggle(!IsStore && !IsCrafting);
    Inventory.find('.inventory-box-cash').hide();

    if (IsStore) {
        Inventory.find('.inventory-box-cash').html('Je hebt <span>€0</span> om te spenderen');
        $.post("https://fw-inventory/FetchMoney", JSON.stringify({}), function(Cash){
            PlayerCash = Cash;
            Inventory.find('.inventory-box-cash > span').text(Cash.toLocaleString('nl-NL', { style: 'currency', currency: 'EUR' })).parent().show();
        });
    }

    // Searching / robbing a player: show the cash they carry.
    if (OtherInvData.IsPlayer && OtherInvData.Cash !== undefined) SetOtherCash(OtherInvData.Cash);

    if (OtherInvData.IsPlayer) {
        BuildOtherPlayerInventory(Grid);
        return;
    }

    UpdateInventoryWeights('other');

    if (IsCrafting) {
        Grid.addClass('inventory-craft-slots');
        for (let i = 1; i <= MaxSlots; i++) {
            const Item = Items[i];
            if (!Item) continue;
            const ItemData = GetItemData(Item.Item, Item.CustomType);

            let RequirementsHtml = ``;
            for (let j = 0; j < ItemData.Craft.length; j++) {
                const Craftable = ItemData.Craft[j];
                const CraftableItem = GetItemData(Craftable.Item, Craftable.CustomType)
                RequirementsHtml += `<div class="inventory-craft-slot-requirements">
                    <img src="./img/items/${CraftableItem.Image}" class="inventory-craft-requirement"></img>
                    <span>${CraftableItem.Label}:</span>
                    <span>${Craftable.Amount}</span>
                </div>`;
            };

            Grid.append(`<div class="inventory-craft-slot">
                <div data-slot="${i}" class="inventory-box-slot has-item">${BuildSlotHtml('other', i, Item)}</div>
                <div class="inventory-craft-requirements">${RequirementsHtml}</div>
            </div>`);
        }
        return;
    }

    for (let i = 1; i <= MaxSlots; i++) {
        Grid.append(SlotElementHtml(i));
        RenderSlot('other', i);
    }
};

const ClearInventorySlot = (Inventory, Slot) => {
    RenderSlot(Inventory.attr("inventory-name"), Slot);
};

// Optimistic UI update after a drag / quick move. Works on the data first, then re-renders the two slots.
const UpdateInventorySlot = (FromInv, ToInv, FromSlotId, ToSlotId, FromItem, ToItem, Amount, Type) => {
    const FromContainer = FromInv.attr("inventory-name"), ToContainer = ToInv.attr("inventory-name");
    const FromItems = GetContainerItems(FromContainer), ToItems = GetContainerItems(ToContainer);
    const FromIsShop = FromContainer != 'player' && (OtherInvData.Type == 'Store' || OtherInvData.Type == 'Crafting');

    if (Type == "Swap") {
        FromItems[FromSlotId] = ToItem;
        ToItems[ToSlotId] = FromItem;
    } else {
        const Moving = Math.min(Amount, FromItem.Amount);

        if (!FromIsShop) {
            if (Moving >= FromItem.Amount) {
                FromItems[FromSlotId] = null;
            } else {
                FromItems[FromSlotId] = { ...FromItem, Amount: FromItem.Amount - Moving };
            }
        }

        if (ToItem) {
            ToItems[ToSlotId] = { ...ToItem, Amount: ToItem.Amount + Moving };
        } else {
            ToItems[ToSlotId] = { ...FromItem, Amount: Moving };
        }
    }

    RenderSlot(FromContainer, FromSlotId);
    RenderSlot(ToContainer, ToSlotId);

    // Backpack equipped/unequipped -> lock state + max weight change.
    if (FromSlotId == Layout.BackpackSlot && IsPlayerContainer(FromContainer)) RefreshBackpackState(FromContainer);
    if (ToSlotId == Layout.BackpackSlot && IsPlayerContainer(ToContainer)) RefreshBackpackState(ToContainer);

    UpdateInventoryWeights(FromContainer);
    if (FromContainer != ToContainer) UpdateInventoryWeights(ToContainer);
};

const RandomString = (Length) => {
    var Retval = '';
    var Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    for (var i = 0; i < Length; i++) Retval += Chars.charAt(Math.floor(Math.random() * Chars.length));
    return Retval;
};

const InventoryBox = (Text, Item, Amount, CustomType) => {
    var ItemData = ItemsList[Item];
    if (ItemData == undefined) return;

    var Id = RandomString(8);
    var Image = GetItemImage(Item, CustomType);
    ItemData = GetItemData(Item, CustomType);

    $('.inventory-boxbar').append(`<div id="box-${Id}" class="inventory-boxbar-slot">
        <div class="inventory-slot-image" style="background-image: url(${Image})"></div>
        <div class="inventory-slot-text">${Text} ${Amount ? `${Amount}x` : ``}</div>
        <div class="inventory-slot-name">${ItemData.Label}</div>
    </div>`);
    $(`.inventory-boxbar-slot#box-${Id}`).fadeIn(250);

    setTimeout(() => {
        $(`.inventory-boxbar-slot#box-${Id}`).fadeOut(500, () => {
            $(`.inventory-boxbar-slot#box-${Id}`).remove();
        });
    }, 2500);
};

const GetItemTypeLabel = (Container, Slot, ItemData) => {
    if (IsPlayerContainer(Container)) {
        const EquipSlot = GetEquipSlot(Slot);
        if (EquipSlot) return `Equipped · ${EquipSlot.Label}`;
    }
    if (ItemData.Weapon) return 'Weapon';
    const EquipFor = GetEquipSlotForItem(ItemData.Name);
    if (EquipFor) return `${GetEquipSlot(EquipFor).Section} · ${GetEquipSlot(EquipFor).Label}`;
    return 'Item';
};

const GenerateItemInfo = (InvName, SlotId) => {
    const Container = InvName == 'player' ? 'player' : 'other';
    const Item = GetContainerItems(Container)[SlotId];
    if (!Item || !ItemsList[Item.Item]) return false;

    const ItemData = GetItemData(Item.Item, Item.CustomType, Item.Info);
    var ItemMetadata = ``;

    $.each(Item.Info, function(Index, Value){
        if (!HiddenMetadata.includes(Index) && !Index.startsWith('_')) {
            var MetaDataIndex = Index;
            if (ItemI18n[Item.Item] && ItemI18n[Item.Item][Index]) MetaDataIndex = ItemI18n[Item.Item][Index];
            ItemMetadata += `<div><strong>${MetaDataIndex}:</strong> ${Value}</div>`;
        };
    });

    // Weapons: what's in / on them.
    if (ItemData.Weapon && Item.Info) {
        if (Item.Info.Mag && Layout.Magazines && Layout.Magazines[Item.Info.Mag]) {
            ItemMetadata += `<div><strong>Magazijn:</strong> ${Layout.Magazines[Item.Info.Mag].Label} (${Math.max(0, Math.floor(Number(Item.Info.Ammo) || 0))}/${Layout.Magazines[Item.Info.Mag].Capacity})</div>`;
        } else if (Layout.WeaponMagTypes && Layout.WeaponMagTypes[Item.Item]) {
            ItemMetadata += `<div><strong>Magazijn:</strong> geen</div>`;
        }
        if (Item.Info.Attachments && typeof Item.Info.Attachments == 'object') {
            for (const [Kind, A] of Object.entries(Item.Info.Attachments)) {
                if (A && ItemsList[A.Item]) ItemMetadata += `<div><strong>${Kind}:</strong> ${GetItemData(A.Item, A.CustomType, A.Info).Label}</div>`;
            }
        }
    }

    var Quality = CalculateQuality(Item.Item, Item.CreateDate);
    return `<div class="tt-head"><span class="tt-type">${GetItemTypeLabel(Container, SlotId, ItemData)}</span><h2>${ItemData.Label}</h2></div>`
        + `<div class="inventory-hover-info">${ItemMetadata.length > 0 ? `<div class="tt-meta">${ItemMetadata}</div>` : ''}${ItemData.Description || ''}</div>`
        + `<div class="tt-foot"><span>Qty ${Item.Amount}</span><span style="color: ${GetQualityColor(Quality.Percentage)}">Quality ${Quality.Percentage}</span><span>${(ItemData.Weight * Item.Amount).toFixed(2)}kg</span></div>`;
};

const CopyToClipboard = (Text) => {
    var TextArea = document.createElement('textarea');
    TextArea.value = Text
    TextArea.style.top = '0';
    TextArea.style.left = '0';
    TextArea.style.position = 'fixed';
    document.body.appendChild(TextArea);
    TextArea.focus();
    TextArea.select();
    try { document.execCommand('copy'); } catch (err) {}
    document.body.removeChild(TextArea);
};

const SetOtherCash = (Cash) => {
    const Box = GetContainerBox('other').find('.inventory-box-cash');
    const Formatted = Number(Cash || 0).toLocaleString('nl-NL', { style: 'currency', currency: 'EUR' });
    Box.html(`<span class="material-symbols-outlined">payments</span> Cash op zak: <span>${Formatted}</span>`).css("display", "flex");
    Box.toggleClass('is-empty', !Cash);
    $('#steal-money').toggleClass('disabled', !Cash);
};
