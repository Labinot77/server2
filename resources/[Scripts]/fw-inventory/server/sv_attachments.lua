-- // Weapon attachments \\ --
-- Right-click a weapon -> Attachments. Everything that's "in" a weapon lives on the weapon item:
--   Info.Mag          magazine type inside (false/nil = no magazine)
--   Info.Ammo         rounds in that magazine
--   Info.Attachments  { [Kind] = { Item, CustomType, Info } }   (Kind from Config.AttachmentSlots)
-- So a magazine never disappears: it's in the gun until you take it out here (or swap it with [R]).

local function Notify(Player, Text, Type) Player.Functions.Notify(Text, Type or "error") end

local function RefreshSlots(Player, Slots)
    for _, Slot in pairs(Slots) do
        if Slot then
            Player.Functions.RefreshInvSlot(Slot)
            TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Slot)
        end
    end
end

local function GetBullets(Item)
    return math.max(0, math.floor(tonumber(Item and Item.Info and Item.Info.Bullets) or 0))
end

local function GetWeapon(Player, Slot)
    local Item = Player.PlayerData.inventory[tonumber(Slot)]
    if not Item or not Shared.Items[Item.Item] or not Shared.Items[Item.Item].Weapon then return false end
    Item.Info = Item.Info or {}
    return Item
end

function GetWeaponMagType(WeaponName)
    local Data = exports['fw-weapons']:GetWeaponList(GetHashKey(WeaponName))
    return Data and GetMagazineTypeForAmmo(Data.AmmoType) or false
end

local function CopyAttachments(Weapon)
    local Retval = {}
    for Kind, Data in pairs(type(Weapon.Info.Attachments) == 'table' and Weapon.Info.Attachments or {}) do
        Retval[Kind] = Data
    end
    return Retval
end

-- Slot the detached item should go to: the one it was dropped on if usable, otherwise any.
local function ResolveTargetSlot(Player, ToSlot, ItemName, CustomType, Amount)
    local Inventory = Player.PlayerData.inventory
    ToSlot = tonumber(ToSlot)
    if ToSlot and Inventory[ToSlot] == nil and ValidatePlayerSlot(Inventory, ToSlot, ItemName, Amount or 1) then
        return ToSlot
    end

    local Found = FindPlayerSlot(Inventory, ItemName, CustomType)
    -- NonStack items (magazines, silencers) need an empty slot.
    if Found and Inventory[Found] and Shared.Items[ItemName].NonStack then Found = false end
    return Found
end

local function WeaponChanged(Player, WeaponSlot)
    TriggerClientEvent("fw-inventory:Client:WeaponModified", Player.PlayerData.source, WeaponSlot)
end

-- // Put something into / onto the weapon \\ --
FW.RegisterServer("fw-inventory:Server:AttachToWeapon", function(Source, WeaponSlot, ItemSlot)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    local Weapon = GetWeapon(Player, WeaponSlot)
    local Item = Player.PlayerData.inventory[tonumber(ItemSlot)]
    if not Weapon or not Item or Item.Slot == Weapon.Slot then return end

    if Item.Item == 'magazine' then
        local MagType = GetWeaponMagType(Weapon.Item)
        if not MagType then return Notify(Player, "Dit wapen gebruikt geen magazijnen.") end
        if Item.CustomType ~= MagType then
            return Notify(Player, ("Dit wapen neemt alleen %s magazijnen."):format(Config.Magazines[MagType].Label))
        end

        local NewAmmo = math.min(GetBullets(Item), GetMagazineCapacity(MagType))
        local OldMag, InGun = Weapon.Info.Mag, math.max(0, math.floor(tonumber(Weapon.Info.Ammo) or 0))

        if not Player.Functions.RemoveItem('magazine', 1, Item.Slot, false, Item.CustomType) then return end

        -- Swap: the magazine that was in the gun takes the freed slot.
        if OldMag and Config.Magazines[OldMag] then
            Player.Functions.AddItem('magazine', 1, Item.Slot, { Bullets = math.min(InGun, GetMagazineCapacity(OldMag)) }, false, OldMag)
        elseif InGun > 0 then
            Player.Functions.AddItem('bullets', InGun, false, {}, true, MagType)
        end

        Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Ammo', NewAmmo)
        Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Mag', MagType)
    else
        local Attachment = GetWeaponAttachment(Item.Item, Weapon.Item)
        if not Attachment then return Notify(Player, "Dit past niet op dit wapen.") end

        local Attachments = CopyAttachments(Weapon)
        local Old = Attachments[Attachment.Kind]

        if not Player.Functions.RemoveItem(Item.Item, 1, Item.Slot, false, Item.CustomType) then return end
        if Old and Old.Item then
            Player.Functions.AddItem(Old.Item, 1, Item.Slot, Old.Info or {}, false, Old.CustomType)
        end

        Attachments[Attachment.Kind] = { Item = Item.Item, CustomType = Item.CustomType, Info = Item.Info or {} }
        Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Attachments', Attachments)
    end

    RefreshSlots(Player, { Item.Slot, Weapon.Slot })
    WeaponChanged(Player, Weapon.Slot)
end)

-- // Take something out of / off the weapon \\ --
FW.RegisterServer("fw-inventory:Server:DetachFromWeapon", function(Source, WeaponSlot, Kind, ToSlot)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    local Weapon = GetWeapon(Player, WeaponSlot)
    if not Weapon then return end

    if Kind == 'Magazine' then
        local MagType = Weapon.Info.Mag
        if not MagType or not Config.Magazines[MagType] then return end

        local Bullets = math.min(math.max(0, math.floor(tonumber(Weapon.Info.Ammo) or 0)), GetMagazineCapacity(MagType))
        local Target = ResolveTargetSlot(Player, ToSlot, 'magazine', MagType)
        if not Target then return Notify(Player, "Je hebt geen ruimte.") end

        if not Player.Functions.AddItem('magazine', 1, Target, { Bullets = Bullets }, false, MagType) then return end
        Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Ammo', 0)
        Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Mag', false)

        RefreshSlots(Player, { Target, Weapon.Slot })
    else
        local Attachments = CopyAttachments(Weapon)
        local Old = Attachments[Kind]
        if not Old or not Old.Item or not Shared.Items[Old.Item] then return end

        local Target = ResolveTargetSlot(Player, ToSlot, Old.Item, Old.CustomType)
        if not Target then return Notify(Player, "Je hebt geen ruimte.") end

        if not Player.Functions.AddItem(Old.Item, 1, Target, Old.Info or {}, false, Old.CustomType) then return end
        Attachments[Kind] = nil
        Player.Functions.SetItemKV(Weapon.Item, Weapon.Slot, 'Attachments', Attachments)

        RefreshSlots(Player, { Target, Weapon.Slot })
    end

    WeaponChanged(Player, Weapon.Slot)
end)

exports("GetWeaponMagType", GetWeaponMagType)
