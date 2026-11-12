-- // Equipment (Body / Clothing / Backpack) \\ --
-- Slot layout + rules live in config/_sh_config.lua (Config.SlotLayout / Config.EquipSlots / Config.Backpacks).
-- Visual effects (props, clothing) are applied client-side in client/cl_equipment.lua,
-- which reacts to every change in the equipment slots.

local function GetPlayerFromInv(InvName)
    if type(InvName) ~= 'string' or not string.startsWith(InvName, 'ply-') then return false end
    local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
    if Player then return Player end

    -- Offline (or test) player inventory: still enforce the layout rules, read from the DB.
    return { Offline = true, PlayerData = { inventory = GetInventoryItems(InvName) } }
end

local function TotalWeightOf(Inventory, ExcludeSlot)
    local Total = 0.0
    for Slot, v in pairs(Inventory) do
        if v and Slot ~= ExcludeSlot then
            local ItemData = Shared.Items[v.Item]
            local TypeData = v.CustomType and Shared.CustomTypes and Shared.CustomTypes[v.Item] and Shared.CustomTypes[v.Item][v.CustomType]
            local Weight = (TypeData and TypeData.Weight) or (ItemData and ItemData.Weight) or 0
            Total = Total + (Weight * v.Amount)
        end
    end
    return Total
end

-- Rules that apply when the backpack slot changes.
local function CanRemoveBackpack(Inventory, LeavesInventory)
    if not IsBackpackEmpty(Inventory) then
        return false, "Maak eerst je rugzak leeg."
    end

    -- Without the bag bonus, the rest still has to fit.
    local Remaining = TotalWeightOf(Inventory, LeavesInventory and Config.BackpackSlot or nil)
    if Remaining > Config.MaxPlayerWeight then
        return false, "Je draagt te veel om je rugzak af te doen."
    end

    return true
end

-- Validates an item movement coming from the NUI before it touches the database.
-- Data.FromInv / Data.ToInv are already resolved to 'ply-<cid>' names.
-- Returns true, or false + reason. May clamp Data.Amount for equip slots.
function ValidateItemMovement(Type, Data)
    local FromPlayer, ToPlayer = GetPlayerFromInv(Data.FromInv), GetPlayerFromInv(Data.ToInv)
    local FromSlot, ToSlot = tonumber(Data.FromSlot), tonumber(Data.ToSlot)

    if Type == "Move" then
        if ToPlayer then
            local ToInventory = ToPlayer.PlayerData.inventory

            if IsEquipSlot(ToSlot) then
                Data.Amount = 1 -- Equip slots hold exactly one item.
                local Occupied = ToInventory[ToSlot]
                if Occupied and not (Data.FromInv == Data.ToInv and FromSlot == ToSlot) then
                    return false, "Dit vak is al bezet."
                end
            end

            local Valid, Reason = ValidatePlayerSlot(ToInventory, ToSlot, Data.FromItem, Data.Amount)
            if not Valid then return false, Reason end
        end

        if FromPlayer and FromSlot == Config.BackpackSlot and not (Data.FromInv == Data.ToInv and FromSlot == ToSlot) then
            local Valid, Reason = CanRemoveBackpack(FromPlayer.PlayerData.inventory, Data.FromInv ~= Data.ToInv)
            if not Valid then return false, Reason end
        end

        return true
    elseif Type == "Swap" then
        -- FromItem -> ToSlot (ToInv), ToItem -> FromSlot (FromInv)
        if ToPlayer then
            local Valid, Reason = ValidatePlayerSlot(ToPlayer.PlayerData.inventory, ToSlot, Data.FromItem, Data.FromAmount)
            if not Valid then return false, Reason end
        end

        if FromPlayer then
            local Valid, Reason = ValidatePlayerSlot(FromPlayer.PlayerData.inventory, FromSlot, Data.ToItem, Data.ToAmount)
            if not Valid then return false, Reason end
        end

        -- Swapping the equipped backpack out (for anything) needs an empty backpack.
        if (FromPlayer and FromSlot == Config.BackpackSlot) or (ToPlayer and ToSlot == Config.BackpackSlot) then
            local Owner = (FromPlayer and FromSlot == Config.BackpackSlot) and FromPlayer or ToPlayer
            if not IsBackpackEmpty(Owner.PlayerData.inventory) then
                return false, "Maak eerst je rugzak leeg."
            end
        end

        return true
    end

    return true
end

-- // Direct slot helpers (used by Equip/Unequip exports) \\ --
local function NotifyChangedSlots(Player, Slots)
    for _, Slot in pairs(Slots) do
        Player.Functions.RefreshInvSlot(Slot)
        TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Slot)
    end
    TriggerClientEvent("fw-assets:Client:Attach:Items", Player.PlayerData.source)
end

local function MoveWholeSlot(InvName, FromSlot, ToSlot)
    exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = @ToSlot WHERE `inventory` = @Inv AND `slot` = @FromSlot", {
        ['@Inv'] = InvName,
        ['@FromSlot'] = FromSlot,
        ['@ToSlot'] = ToSlot,
    })
end

local function SwapWholeSlots(InvName, SlotA, SlotB)
    -- Park A on a temp slot so the two UPDATEs don't collide.
    MoveWholeSlot(InvName, SlotA, -1)
    MoveWholeSlot(InvName, SlotB, SlotA)
    MoveWholeSlot(InvName, -1, SlotB)
end

-- Equips the item in FromSlot into its matching equip slot (swaps if occupied).
function EquipItem(Source, FromSlot)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return false end

    FromSlot = tonumber(FromSlot)
    local Inventory = Player.PlayerData.inventory
    local Item = Inventory[FromSlot]
    if not Item then return false end

    local EquipSlot = GetEquipSlotForItem(Item.Item)
    if not EquipSlot then return false end
    if EquipSlot == FromSlot then return true end

    local InvName = 'ply-' .. Player.PlayerData.citizenid
    local Current = Inventory[EquipSlot]

    if EquipSlot == Config.BackpackSlot and Current then
        local Valid, Reason = CanRemoveBackpack(Inventory, false)
        if not Valid then
            Player.Functions.Notify(Reason, "error")
            return false
        end
    end

    if Item.Amount > 1 then
        -- Split one off the stack into the equip slot.
        if Current then
            Player.Functions.Notify(("Je %s vak is al bezet."):format(Config.EquipSlots[EquipSlot].Label), "error")
            return false
        end
        exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = @ToSlot WHERE `inventory` = @Inv AND `slot` = @FromSlot LIMIT 1", {
            ['@Inv'] = InvName, ['@FromSlot'] = FromSlot, ['@ToSlot'] = EquipSlot,
        })
    elseif Current then
        SwapWholeSlots(InvName, FromSlot, EquipSlot)
    else
        MoveWholeSlot(InvName, FromSlot, EquipSlot)
    end

    NotifyChangedSlots(Player, { FromSlot, EquipSlot })
    return true
end
exports("EquipItem", EquipItem)

-- Sets the item in an equip slot: Info = put this item there (replacing whatever was there), false = empty the slot.
function SetEquippedClothing(Source, ItemName, Info)
    local Player = FW.Functions.GetPlayer(Source)
    local Slot = GetEquipSlotForItem(ItemName)
    if not Player or not Slot then return false end

    local Current = Player.PlayerData.inventory[Slot]
    if Current and Info and Current.Item == ItemName and Current.Info and Current.Info.Prop == Info.Prop and Current.Info.Texture == Info.Texture then
        return true -- Already equipped.
    end

    if Current then Player.Functions.RemoveItem(Current.Item, 1, Slot, false) end
    return not Info or Player.Functions.AddItem(ItemName, 1, Slot, Info, false)
end
exports("SetEquippedClothing", SetEquippedClothing)

-- Moves whatever is in an equip slot back into pockets/backpack.
function UnequipSlot(Source, Slot)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return false end

    Slot = tonumber(Slot)
    if not IsEquipSlot(Slot) then return false end

    local Inventory = Player.PlayerData.inventory
    local Item = Inventory[Slot]
    if not Item then return false end

    if Slot == Config.BackpackSlot then
        local Valid, Reason = CanRemoveBackpack(Inventory, false)
        if not Valid then
            Player.Functions.Notify(Reason, "error")
            return false
        end
    end

    -- Look for room without the equip slot itself (and without the bag if we take it off).
    local Lookup = {}
    for k, v in pairs(Inventory) do Lookup[k] = v end
    Lookup[Slot] = nil

    local ToSlot = false
    for i = Config.SlotLayout.Pockets[1], Config.SlotLayout.Backpack[2] do
        if Lookup[i] == nil and ValidatePlayerSlot(Lookup, i, Item.Item, Item.Amount) then
            ToSlot = i
            break
        end
    end

    if not ToSlot then
        Player.Functions.Notify("Je hebt geen ruimte in je zakken.", "error")
        return false
    end

    MoveWholeSlot('ply-' .. Player.PlayerData.citizenid, Slot, ToSlot)
    NotifyChangedSlots(Player, { Slot, ToSlot })
    return ToSlot
end
exports("UnequipSlot", UnequipSlot)

-- Use-item behaviour: equipped -> unequip, otherwise equip.
function ToggleEquipItem(Source, Slot)
    if IsEquipSlot(Slot) then
        return UnequipSlot(Source, Slot)
    end
    return EquipItem(Source, Slot)
end
exports("ToggleEquipItem", ToggleEquipItem)

-- Returns the item in an equip slot (by slot id or by slot label, e.g. 'Hat').
function GetEquippedItem(Source, SlotOrLabel)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return false end

    local Slot = tonumber(SlotOrLabel)
    if not Slot then
        for k, v in pairs(Config.EquipSlots) do
            if v.Label == SlotOrLabel or v.Clothing == SlotOrLabel then Slot = k break end
        end
    end

    return Slot and Player.PlayerData.inventory[Slot] or false
end
exports("GetEquippedItem", GetEquippedItem)

exports("GetEquipSlotByClothing", function(ComponentId)
    for Slot, v in pairs(Config.EquipSlots) do
        if v.Clothing == ComponentId then return Slot end
    end
    return false
end)

function GetPlayerMaxWeight(Source)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return Config.MaxPlayerWeight end
    return GetMaxPlayerWeight(Player.PlayerData.inventory)
end
exports("GetPlayerMaxWeight", GetPlayerMaxWeight)

-- // Layout migration \\ --
-- Old inventories used slots 1-40 as one big grid. After this update slots 16-35 are the
-- backpack and 36-40 are body slots, so on login we move anything that is now in a slot it
-- isn't allowed in (locked backpack slot, wrong body/accessory slot) to a valid free slot.
-- Whatever doesn't fit stays where it is: it's still visible (red outline) and can be dragged out.
function RelocateInvalidItems(Player)
    local InvName = 'ply-' .. Player.PlayerData.citizenid
    local Work = {}
    for k, v in pairs(Player.PlayerData.inventory) do
        if type(k) == 'number' and k > 0 and v then Work[k] = v end
    end

    local Moved = 0
    for Slot = Config.SlotLayout.Clothing[2] - 1, Config.SlotLayout.Body[2], -1 do
        local Item, Next = Work[Slot], Slot + 1
        if Item and not CanItemGoInSlot(Item.Item, Slot) and CanItemGoInSlot(Item.Item, Next) and not Work[Next] then
            MoveWholeSlot(InvName, Slot, Next)
            Work[Next], Work[Slot] = Item, nil
            Moved = Moved + 1
        end
    end

    for Slot = 1, Config.MaxPlayerSlots do
        local Item = Work[Slot]
        if Item and not ValidatePlayerSlot(Work, Slot, Item.Item, Item.Amount) then
            Work[Slot] = nil

            local Target = false
            local EquipSlot = GetEquipSlotForItem(Item.Item)
            if EquipSlot and Config.EquipSlots[EquipSlot].AutoPlace and Item.Amount == 1 and not Work[EquipSlot] then
                Target = EquipSlot
            else
                for i = Config.SlotLayout.Pockets[1], Config.SlotLayout.Backpack[2] do
                    if not Work[i] and ValidatePlayerSlot(Work, i, Item.Item, Item.Amount) then
                        Target = i
                        break
                    end
                end
            end

            if Target then
                MoveWholeSlot(InvName, Slot, Target)
                Work[Target] = Item
                Moved = Moved + 1
            else
                Work[Slot] = Item -- No room, leave it.
            end
        end
    end

    if Moved > 0 then
        Player.Functions.RefreshInventory()
    end
    return Moved
end

FW.RegisterServer("fw-inventory:Server:FixLayout", function(Source)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end
    RelocateInvalidItems(Player)
end)

-- Wearable/equipable items: using them toggles the equip slot.
Citizen.CreateThread(function()
    -- Body items that have no other use.
    for _, ItemName in pairs({ 'pdwatch', 'keyring', 'backpack' }) do
        FW.Functions.CreateUsableItem(ItemName, function(Source, Item)
            ToggleEquipItem(Source, Item.Slot)
        end)
    end
end)

-- True when a working (not broken) phone sits in the player's BODY phone slot.
function HasPhoneEquipped(Source, ItemName)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return false end

    local Equipped, Item = IsPhoneEquipped(Player.PlayerData.inventory, ItemName)
    if not Equipped then return false end
    return CalculateQuality(Item.Item, Item.CreateDate) > 1.0
end
exports("HasPhoneEquipped", HasPhoneEquipped)
