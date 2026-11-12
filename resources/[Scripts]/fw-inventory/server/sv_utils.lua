-- // General Functions \\ --
function CalculateQuality(ItemName, CreateDate)
    local TimeAllowed = 1000 * 60 * 40320 -- 28 days
    local DecayRate = Shared.Items[ItemName].DecayRate
    local TimeExtra = TimeAllowed * DecayRate
    local Quality = 100 - math.ceil((((os.time() * 1000) - CreateDate) / TimeExtra) * 100)

    if DecayRate == 0 then Quality = 100 end
    if Quality < 0 then Quality = 0 end

    return Quality
end
exports("CalculateQuality", CalculateQuality)

function GetItemData(ItemName, CustomType)
    if CustomType and CustomType:len() > 0 then
        local Retval = DeepCopyTable(Shared.Items[ItemName])
        local TypeData = Shared.CustomTypes[ItemName][CustomType]

        if TypeData.Label then Retval.Label = TypeData.Label end
        if TypeData.Image then Retval.Image = TypeData.Image end
        if TypeData.Description then Retval.Description = TypeData.Description end
        if TypeData.IsExternImage then Retval.IsExternImage = TypeData.IsExternImage end
        if TypeData.Price then Retval.Price = TypeData.Price end
        if TypeData.Cract then Retval.Cract = TypeData.Cract end

        return Retval
    else
        return Shared.Items[ItemName]
    end
end
exports("GetItemData", GetItemData)

function GenerateItemInfo(InvName, Item, CustomType)
    local Info = {}

    local SerialPrefix = string.startsWith(InvName, 'ply-') and InvName:sub(5) or FW.Shared.RandomInt(4)
    if string.startsWith(Item, 'weapon_') then
        Info = {
            Serial = SerialPrefix .. '-' .. FW.Shared.RandomStr(4) .. '-' .. FW.Shared.RandomInt(3),
            Ammo = 0
        }
    elseif Item == 'business-bag' then
        Info = {
            BagId = 'bag-' .. os.time() .. FW.Shared.RandomInt(6)
        }
    elseif Item == 'farming-seedbag' then
        Info = {
            BagId = 'seed-bag-' .. os.time() .. FW.Shared.RandomInt(6)
        }
    elseif Item == 'producebasket' then
        Info = {
            BagId = 'produce-basket-' .. os.time() .. FW.Shared.RandomInt(6)
        }
    elseif Item == 'id_card' then
        local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if not Player then return {} end

        Info = {
            citizenid = Player.PlayerData.citizenid,
            firstname = Player.PlayerData.charinfo.firstname,
            lastname = Player.PlayerData.charinfo.lastname,
            birthdate = Player.PlayerData.charinfo.birthdate,
            gender = Player.PlayerData.charinfo.gender,
            nationality = Player.PlayerData.charinfo.nationality,
        }
    elseif Item == 'driver_license' then
        local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if not Player then return {} end

        Info = {
            citizenid = Player.PlayerData.citizenid,
            firstname = Player.PlayerData.charinfo.firstname,
            lastname = Player.PlayerData.charinfo.lastname,
            birthdate = Player.PlayerData.charinfo.birthdate,
            type = "A1-A2-A | AM-B | C1-C-CE",
        }
    elseif Item == 'scuba-gear' then
        Info = {
            air = 100
        }
    elseif Item == 'crackpipe' then
        Info = { Uses = 0 }
    elseif Item == 'methpipe' then
        Info = { Uses = 0, _Purities = {} }
    elseif Item == 'methcured' then
        Info = { _Purity = 100 }
    elseif Item == '1gmeth' then
        Info = { Purity = math.random(1, 100) }
    elseif Item == 'burnerphone' then
        Info = { PhoneNumber = FW.Player.CreatePhoneNumber(true) }
    elseif Item == 'customjoint' and CustomType == 'insideout' then
        Info = { Uses = 1 }
    elseif Item == 'customjoint' and CustomType == 'cone' then
        Info = { Uses = 2 }
    elseif Item == 'customjoint' and CustomType == 'splitter' then
        Info = { Uses = 2 }
    elseif Item == 'customjoint' and CustomType == 'cross' then
        Info = { Uses = 3 }
    elseif Item == 'customjoint' and CustomType == 'tulp' then
        Info = { Uses = 4 }
    elseif Item == 'customjoint' and CustomType == 'windmill' then
        Info = { Uses = 5 }
    elseif Item == 'notepad' then
        Info = { _Uses = 10 }
    end

    return Info
end
exports("GenerateItemInfo", GenerateItemInfo)

function GetTotalItemsWeight(InvName)
    if string.startsWith(InvName, 'ply-') then
        local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if not Player then return 0.0 end

        local TotalWeight = 0.0
        for k, v in pairs(Player.PlayerData.inventory) do
            if v then
                if v.CustomType and Shared.CustomTypes[v.Item] and Shared.CustomTypes[v.Item][v.CustomType] and Shared.CustomTypes[v.Item][v.CustomType].Weight then
                    TotalWeight = TotalWeight + (Shared.CustomTypes[v.Item][v.CustomType].Weight * v.Amount)
                else
                    TotalWeight = TotalWeight + (Shared.Items[v.Item].Weight * v.Amount)
                end
            end
        end

        return TotalWeight
    end
    return 0.0
end
exports("GetTotalItemsWeight", GetTotalItemsWeight)

function FindSlot(InvName, Item, CustomType, MatchItem)
    local Items = {}

    if string.startsWith(InvName, 'ply-') then
        local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if not Player then return false end
        Items = Player.PlayerData.inventory

        -- Looking for an existing item (remove/decay): search every slot.
        if MatchItem then
            for i = 1, Config.MaxPlayerSlots, 1 do
                local SlotData = Items[i]
                if SlotData ~= nil and SlotData.Item == Item and SlotData.CustomType == CustomType then
                    return i
                end
            end
            return
        end

        return FindPlayerSlot(Items, Item, CustomType)
    else
        Items = GetInventoryItems(InvName)
    end

    for i = 1, Config.MaxPlayerSlots, 1 do
        local SlotData = Items[i]
        if (not MatchItem and SlotData == nil) or (SlotData ~= nil and SlotData.Item == Item and SlotData.CustomType == CustomType and (MatchItem or not Shared.Items[SlotData.Item].NonStack)) then
            return i
        end
    end
end
exports("FindSlot", FindSlot)

-- Picks a free/stackable slot in a player inventory, respecting the layout:
-- 1. Body slot reserved for this item (ID card, phone, ...) if AutoPlace and empty.
-- 2. Pockets.
-- 3. Unlocked backpack slots.
-- Accessory slots are never auto-filled, items there are only equipped on purpose.
function FindPlayerSlot(Items, Item, CustomType)
    local ItemData = Shared.Items[Item]
    if not ItemData then return end

    local EquipSlot = GetEquipSlotForItem(Item)
    if EquipSlot and Config.EquipSlots[EquipSlot].AutoPlace and Items[EquipSlot] == nil then
        return EquipSlot
    end

    local function CanUse(i)
        local SlotData = Items[i]
        if not ValidatePlayerSlot(Items, i, Item, 1) then return false end
        if SlotData == nil then return true end
        return SlotData.Item == Item and SlotData.CustomType == CustomType and not ItemData.NonStack
    end

    -- Prefer stacking onto an existing stack first, then an empty slot.
    local Ranges = { Config.SlotLayout.Pockets, Config.SlotLayout.Backpack }
    for _, Range in ipairs(Ranges) do
        for i = Range[1], Range[2] do
            if Items[i] ~= nil and CanUse(i) then return i end
        end
    end

    for _, Range in ipairs(Ranges) do
        for i = Range[1], Range[2] do
            if Items[i] == nil and CanUse(i) then return i end
        end
    end
end
exports("FindPlayerSlot", FindPlayerSlot)

-- // Getters \\ --
function GetInventoryItems(InvName)
    local Promise = promise:new()

    exports['ghmattimysql']:execute("SELECT count(item_name) as amount, item_name, custom_type, id, info, slot, MIN(createdate) as createdate FROM `player_inventories` WHERE `inventory` = @InvName group by slot", {
        ['@InvName'] = InvName
    }, function(Result)
        local Retval = {[0] = false}
        for k, v in pairs(Result) do
            local ItemData = Shared.Items[v.item_name]
            Retval[tonumber(v.slot)] = {
                Item = v.item_name,
                CustomType = v.custom_type,
                Amount = tonumber(v.amount),
                Info = json.decode(v.info),
                CreateDate = tonumber(v.createdate),
                Slot = tonumber(v.slot),
            }
        end

        Promise:resolve(Retval)
    end)

    return Citizen.Await(Promise)
end
exports("GetInventoryItems", GetInventoryItems)

function GetInventoryItemsUnproccessed(InvName)
    local Result = exports['ghmattimysql']:executeSync("SELECT * FROM `player_inventories` WHERE `inventory` = @InvName", {
        ['@InvName'] = InvName
    })

    return Result
end
exports("GetInventoryItemsUnproccessed", GetInventoryItemsUnproccessed)

function GetInventoryItemBySlot(InvName, Slot)
    local Result = exports['ghmattimysql']:executeSync("SELECT count(item_name) as amount, item_name, custom_type, id, info, slot, MIN(createdate) as createdate FROM `player_inventories` WHERE `inventory` = @InvName AND `slot` = @Slot", {
        ['@InvName'] = InvName,
        ['@Slot'] = Slot
    })

    if Result[1] == nil or Result[1].item_name == nil then
        return nil
    end

    local ItemData = Shared.Items[Result[1].item_name]
    return {
        Item = Result[1].item_name,
        CustomType = Result[1].custom_type,
        Amount = tonumber(Result[1].amount),
        Info = json.decode(Result[1].info),
        CreateDate = tonumber(Result[1].createdate),
        Slot = tonumber(Result[1].slot),
    }
end
exports("GetInventoryItemBySlot", GetInventoryItemBySlot)

-- // Setters \\ --
function SetInventoryItemKV(InvName, Item, Slot, Key, Value)
    if not Shared.Items[Item] then return end
    if not Slot then return end

    if not string.startsWith(InvName, 'ply-') then
        print("^1[INVENTORY/SetInventoryItemKV]: NOT COMPATIBLE WITH NON-PLAYER INVENTORIES!")
        return false
    end

    local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
    if not Player then return false end

    local ItemData = Player.PlayerData.inventory[Slot]
    if not ItemData then return false end

    ItemData.Info[Key] = Value
    local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET info = @Info WHERE `inventory` = @Inv AND `item_name` = @Item AND `slot` = @Slot LIMIT 1", {
        ['@Info'] = json.encode(ItemData.Info),
        ['@Inv'] = InvName,
        ['@Item'] = Item,
        ['@Slot'] = Slot,
    })

    return Result.affectedRows > 0
end
exports("SetInventoryItemKV", SetInventoryItemKV)

function SetInventoryItemMultipleKV(InvName, Item, Slot, Data)
    for k, v in pairs(Data) do
        local IsDone = SetInventoryItemKV(InvName, Item, Slot, k, v)
        Citizen.Wait(100) -- Wait a little bit, else it might overwrite old data.
    end

    return true
end
exports("SetInventoryItemMultipleKV", SetInventoryItemMultipleKV)

-- // Add Items \\ --
function AddItemToInventory(InvName, Item, Amount, Slot, Info, CustomType)
    if Shared.Items[Item] == nil then return end
    if CustomType and #CustomType > 0 and (Shared.CustomTypes[Item] == nil or Shared.CustomTypes[Item][CustomType] == nil) then return end
    if not CustomType then CustomType = "" end
    if not Amount or Amount <= 0 then Amount = 1 end
    if not Slot then Slot = FindSlot(InvName, Item, CustomType) end
    if not Info then Info = GenerateItemInfo(InvName, Item, CustomType) end

    if not Slot then return end

    local TotalWeight = GetTotalItemsWeight(InvName)
    local MaxWeight = Config.MaxPlayerWeight
    if string.startsWith(InvName, 'ply-') then
        local Owner = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if Owner then MaxWeight = GetMaxPlayerWeight(Owner.PlayerData.inventory) end
    end

    if string.startsWith(InvName, 'ply-') and TotalWeight + (Shared.Items[Item].Weight * Amount) > MaxWeight then
        
        local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if Player then
            local ClosestDropId, ClosestDrop = false, false
            local PlyCoords = GetEntityCoords(GetPlayerPed(Player.PlayerData.source))
            for k, v in pairs(Config.Drops) do
                if not ClosestDropId then
                    ClosestDropId, ClosestDrop = k, #(v.Coords - PlyCoords)
                end
                
                if #(v.Coords - PlyCoords) < ClosestDrop then
                    ClosestDropId, ClosestDrop = k, #(v.Coords - PlyCoords)
                end
            end
            
            if not ClosestDropId or ClosestDrop > 1.5 then
                ClosestDropId = NewDropId()
                CreateNewDrop(ClosestDropId, PlyCoords)
            end

            InvName = 'Drop-' .. ClosestDropId
            Slot = FindSlot(InvName, Item, CustomType, MatchItem)
            if not Slot then
                return false
            end

            Player.Functions.Notify("Items zijn op de grond gevallen..", "error")
        else
            return false
        end
    end

    local Items = "(@Inventory, @Item, @CustomType, @Slot, @Info, @CreateDate)"
    if Amount > 1 then
        for i = 2, Amount, 1 do
            Items = Items .. ', (@Inventory, @Item, @CustomType, @Slot, @Info, @CreateDate)'
        end
    end

    local Result = exports['ghmattimysql']:executeSync('INSERT INTO player_inventories (inventory, item_name, custom_type, slot, info, createdate) VALUES ' .. Items, {
        ['@Inventory'] = InvName,
        ['@Item'] = Item,
        ['@CustomType'] = CustomType,
        ['@Amount'] = Amount,
        ['@Slot'] = Slot,
        ['@Info'] = json.encode(Info),
        ['@CreateDate'] = os.time() * 1000,
    })

    -- Ground items are rendered per slot, push the new state to everyone.
    if InvName:sub(1, 5) == 'Drop-' then
        SyncDropByName(InvName)
    end

    if string.startsWith(InvName, 'ply-') then
        local Player = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if not Player then return Result.affectedRows > 0 end

        Player.Functions.RefreshInvSlot(Slot)
        TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Slot)

        if Shared.Items[Item].HasProp then
            TriggerClientEvent("fw-assets:Client:Attach:Items", Player.PlayerData.source)
        end
    end

    return Result.affectedRows > 0
end
exports("AddItemToInventory", AddItemToInventory)

-- // Remove Items \\ --
-- Item scripts often remove "1 sandwich" without a slot after it was used. Remember which slot was used,
-- so that one is taken instead of whichever stack the database returns first.
local LastUsed = {}
function SetLastUsedSlot(InvName, Item, CustomType, Slot)
    LastUsed[InvName] = { Item = Item, CustomType = CustomType or "", Slot = Slot, Time = os.time() }
end

function GetPreferredSlot(InvName, Item, CustomType)
    local Used = LastUsed[InvName]
    if Used and Used.Item == Item and Used.CustomType == (CustomType or "") and os.time() - Used.Time <= 60 then
        return Used.Slot
    end
end

function RemoveItemFromInventory(InvName, Item, Amount, Slot, CustomType)
    if not Shared.Items[Item] then return end
    if CustomType and #CustomType > 0 and (Shared.CustomTypes[Item] == nil or Shared.CustomTypes[Item][CustomType] == nil) then return end
    if not CustomType then CustomType = "" end
    if not Amount or Amount <= 0 then Amount = 1 end
    if not Slot then
        local Preferred = GetPreferredSlot(InvName, Item, CustomType)
        local Items = Preferred and GetInventoryItems(InvName)
        Slot = (Items and Items[Preferred] and Items[Preferred].Item == Item and (Items[Preferred].CustomType or "") == CustomType and Preferred) or FindSlot(InvName, Item, CustomType, true)
    end
    if not Slot then return end

    local Result = exports['ghmattimysql']:executeSync("DELETE FROM player_inventories WHERE inventory = @Inventory AND item_name = @Item AND custom_type = @CustomType AND slot = @Slot LIMIT " .. Amount, {
        ['@Inventory'] = InvName,
        ['@Item'] = Item,
        ['@CustomType'] = CustomType,
        ['@Slot'] = Slot,
    })

    if string.startsWith(InvName, 'ply-') then
        local Target = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if Target then
            Target.Functions.RefreshInvSlot(Slot)

            if Shared.Items[Item].HasProp then
                TriggerClientEvent("fw-assets:Client:Attach:Items", Target.PlayerData.source)
            end
        end
    end

    return Result.affectedRows > 0
end
exports("RemoveItemFromInventory", RemoveItemFromInventory)

function RemoveItemFromInventoryByName(InvName, Item, Amount, CustomType)
    if not CustomType then CustomType = "" end
    if not Amount or Amount <= 0 then Amount = 1 end

    -- Take from the slot that was just used first, then the remaining stacks in slot order.
    local Stacks = exports['ghmattimysql']:executeSync("SELECT `slot`, COUNT(*) AS amount FROM player_inventories WHERE inventory = @Inventory AND item_name = @Item AND custom_type = @CustomType GROUP BY `slot`", {
        ['@Inventory'] = InvName, ['@Item'] = Item, ['@CustomType'] = CustomType,
    }) or {}
    local Preferred = GetPreferredSlot(InvName, Item, CustomType)
    table.sort(Stacks, function(a, b)
        if (a.slot == Preferred) ~= (b.slot == Preferred) then return a.slot == Preferred end
        return a.slot < b.slot
    end)

    local Removed, Slots = 0, {}
    for _, Stack in ipairs(Stacks) do
        if Removed >= Amount then break end
        local Take = math.min(Amount - Removed, Stack.amount)
        local Result = exports['ghmattimysql']:executeSync("DELETE FROM player_inventories WHERE inventory = @Inventory AND item_name = @Item AND custom_type = @CustomType AND slot = @Slot LIMIT " .. Take, {
            ['@Inventory'] = InvName, ['@Item'] = Item, ['@CustomType'] = CustomType, ['@Slot'] = Stack.slot,
        })
        if Result.affectedRows > 0 then
            Removed = Removed + Result.affectedRows
            Slots[#Slots + 1] = { slot = Stack.slot }
        end
    end

    if Removed > 0 and string.startsWith(InvName, 'ply-') and Shared.Items[Item] and Shared.Items[Item].HasProp then
        local Target = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if Target then TriggerClientEvent("fw-assets:Client:Attach:Items", Target.PlayerData.source) end
    end

    return Removed > 0, Slots
end
exports("RemoveItemFromInventoryByName", RemoveItemFromInventoryByName)

function RemoveItemFromInventoryByKV(InvName, Item, Amount, Value, CustomType)
    if not Shared.Items[Item] then return end
    if CustomType and #CustomType > 0 and (Shared.CustomTypes[Item] == nil or Shared.CustomTypes[Item][CustomType] == nil) then return end
    if not CustomType then CustomType = "" end
    if not Amount or Amount <= 0 then Amount = 1 end
    if not Slot then Slot = FindSlot(InvName, Item, CustomType, true) end
    if not Slot then return end

    local Result = exports['ghmattimysql']:executeSync("DELETE FROM player_inventories WHERE inventory = @Inventory AND item_name = @Item AND custom_type = @CustomType AND info LIKE @Value LIMIT " .. Amount, {
        ['@Inventory'] = InvName,
        ['@Item'] = Item,
        ['@CustomType'] = CustomType,
        ['@Value'] = "%" .. Value .. "%",
    })

    if string.startsWith(InvName, 'ply-') then
        local Target = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if Shared.Items[Item].HasProp then
            TriggerClientEvent("fw-assets:Client:Attach:Items", Target.PlayerData.source)
        end
    end

    return Result.affectedRows > 0
end
exports("RemoveItemFromInventoryByKV", RemoveItemFromInventoryByKV)

-- // Item Decay \\ --
function DecayItemFromInventory(InvName, Item, Percentage, Slot)
    if not InvName then return end
    if not Item then return end
    if not Slot then Slot = FindSlot(InvName, Item, '', true) end
    if not Slot then return end

    if Shared.Items[Item].DecayRate <= 0.0 then return end

    local SlotData = nil
    if string.startsWith(InvName, 'ply-') then
        local Target = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if Target then
            SlotData = Target.PlayerData.inventory[Slot]
        end
    end

    if not SlotData then SlotData = GetInventoryItemBySlot(InvName, Slot) end
    
    local MaxTime = (((1000 * 60) * 60) * 24) * 28
    local OnePercent = MaxTime * (Shared.Items[Item].DecayRate / 100 * 1);
    local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET createdate = createdate - @CreateDate WHERE `inventory` = @Inv AND `item_name` = @Item AND `slot` = @Slot LIMIT 1", {
        ['@Inv'] = InvName,
        ['@Item'] = Item,
        ['@Slot'] = Slot,
        ['@CreateDate'] = (OnePercent * Percentage),
    })
    
    if not SlotData then return end
    return (SlotData.CreateDate - (OnePercent * Percentage))
end
exports("DecayItemFromInventory", DecayItemFromInventory)

function IncreaseQualityItemFromInventory(InvName, Item, Percentage, Slot)
    if not InvName then return end
    if not Item then return end
    if not Slot then Slot = FindSlot(InvName, Item, CustomType, true) end
    if not Slot then return end

    if Shared.Items[Item].DecayRate <= 0.0 then return end

    local SlotData = nil
    if string.startsWith(InvName, 'ply-') then
        local Target = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        if Target then
            SlotData = Target.PlayerData.inventory[Slot]
        end
    end

    if not SlotData then SlotData = GetInventoryItemBySlot(InvName, Slot) end
    
    local MaxTime = (((1000 * 60) * 60) * 24) * 28
    local OnePercent = MaxTime * (Shared.Items[Item].DecayRate / 100 * 1);
    local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET createdate = createdate + @CreateDate WHERE `inventory` = @Inv AND `item_name` = @Item AND `slot` = @Slot LIMIT 1", {
        ['@Inv'] = InvName,
        ['@Item'] = Item,
        ['@Slot'] = Slot,
        ['@CreateDate'] = (OnePercent * Percentage),
    })
    
    if not SlotData then return end
    return (SlotData.CreateDate + (OnePercent * Percentage))
end
exports("IncreaseQualityItemFromInventory", IncreaseQualityItemFromInventory)

-- // Others \\ --
function ClearInventory(InvName)
    exports['ghmattimysql']:executeSync("DELETE FROM player_inventories WHERE inventory = @Inventory", {
        ['@Inventory'] = InvName
    })
    return true
end
exports("ClearInventory", ClearInventory)

function ClearInventoryItemSlot(InvName, Slot)
    local Result = exports['ghmattimysql']:executeSync("DELETE FROM player_inventories WHERE inventory = @InvName AND slot = @Slot", {
        ['@InvName'] = InvName,
        ['@Slot'] = Slot,
    })

    return Result.affectedRows > 0
end
exports("ClearInventoryItemSlot", ClearInventoryItemSlot)

function SetInventoryItemSlot(InvName, Item, Amount, Slot, Info, CustomType)
    local Result = ClearInventoryItemSlot(InvName, Slot)
    return AddItemToInventory(InvName, Item, Amount, Slot, Info, CustomType)
end
exports("SetInventoryItemSlot", SetInventoryItemSlot)

function SetInventoryName(FromInv, ToInv)
    local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `inventory` = @ToInv WHERE `inventory` = @FromInv", {
        ['@FromInv'] = FromInv,
        ['@ToInv'] = ToInv,
    })
    return Result.affectedRows > 0
end
exports("SetInventoryName", SetInventoryName)
-- ============================================================================
--  Shared inventories: check a move against what's really in the database
-- ============================================================================
local function SlotStacks(InvName, Slot)
    return exports['ghmattimysql']:executeSync("SELECT item_name, custom_type, COUNT(*) AS amount FROM player_inventories WHERE inventory = @Inv AND slot = @Slot GROUP BY item_name, custom_type", {
        ['@Inv'] = InvName, ['@Slot'] = Slot,
    }) or {}
end

local function ItemsWeight(Item, Amount)
    return ((Shared.Items[Item] or {}).Weight or 0) * (Amount or 0)
end

local function InventoryWeight(InvName)
    local Total = 0
    for _, Row in ipairs(exports['ghmattimysql']:executeSync("SELECT item_name, COUNT(*) AS amount FROM player_inventories WHERE inventory = @Inv GROUP BY item_name", { ['@Inv'] = InvName }) or {}) do
        Total = Total + ItemsWeight(Row.item_name, Row.amount)
    end
    return Total
end

local function InventoryWeightLimit(InvName)
    if string.startsWith(InvName, 'ply-') then
        local Target = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
        return Target and GetMaxPlayerWeight(Target.PlayerData.inventory) or false
    end
    return GetSharedMaxWeight(InvName)
end

local function FitsWeight(InvName, Gain)
    if Gain <= 0 then return true end
    local Limit = InventoryWeightLimit(InvName)
    return not Limit or InventoryWeight(InvName) + Gain <= Limit + 0.001
end

function ValidateAgainstDatabase(Source, Type, Data)
    if Data.FromInv == 'Store' or Data.FromInv == 'Crafting' then return true end
    local Changed = "Deze inventory is net veranderd, probeer het opnieuw."
    Data.FromSlot, Data.ToSlot = tonumber(Data.FromSlot), tonumber(Data.ToSlot)

    local From = SlotStacks(Data.FromInv, Data.FromSlot)
    if #From ~= 1 or From[1].item_name ~= Data.FromItem then return false, Changed end
    local FromType, Have = From[1].custom_type or "", From[1].amount
    local SameSlot = Data.FromInv == Data.ToInv and Data.FromSlot == Data.ToSlot
    local To = SameSlot and {} or SlotStacks(Data.ToInv, Data.ToSlot)

    if Type == "Move" then
        Data.Amount = math.min(math.floor(tonumber(Data.Amount) or 0), Have)
        if Data.Amount <= 0 then return false, Changed end
        -- Target must be empty, or the same stackable item.
        if #To > 1 then return false, Changed end
        if #To == 1 and (To[1].item_name ~= Data.FromItem or (To[1].custom_type or "") ~= FromType or (Shared.Items[Data.FromItem] or {}).NonStack) then
            return false, Changed
        end
        if Data.FromInv ~= Data.ToInv and not FitsWeight(Data.ToInv, ItemsWeight(Data.FromItem, Data.Amount)) then
            return false, "Dit past niet, te zwaar."
        end
    elseif Type == "Swap" then
        if FromType ~= (Data.FromType or "") then return false, Changed end
        if #To ~= 1 or To[1].item_name ~= Data.ToItem or (To[1].custom_type or "") ~= (Data.ToType or "") then return false, Changed end
        -- Always swap the whole real stacks, whatever the client thought they were.
        Data.FromAmount, Data.ToAmount = Have, To[1].amount
        if Data.FromInv ~= Data.ToInv then
            local Diff = ItemsWeight(Data.FromItem, Data.FromAmount) - ItemsWeight(Data.ToItem, Data.ToAmount)
            if not FitsWeight(Data.ToInv, Diff) or not FitsWeight(Data.FromInv, -Diff) then
                return false, "Dit past niet, te zwaar."
            end
        end
    end
    return true
end

-- A move was refused: redraw this player's screen from the database.
function ResyncViewer(Source, Data)
    local Player = FW.Functions.GetPlayer(Source)
    if Player then Player.Functions.RefreshInventory() end
    TriggerClientEvent("fw-inventory:Client:RefreshPlayerInventory", Source)
    for _, InvName in ipairs({ Data.FromInv, Data.ToInv }) do
        if type(InvName) == 'string' and InvName ~= PlayerInvName(Source) and InvName ~= 'Store' and InvName ~= 'Crafting' then
            TriggerClientEvent("fw-inventory:Client:RefreshOther", Source, InvName, GetInventoryItems(InvName))
        end
    end
end
