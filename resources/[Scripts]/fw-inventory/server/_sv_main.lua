FW = exports['fw-core']:GetCoreObject()

function string.startsWith(Text, Value)
    return string.find(Text, '^' .. Value) ~= nil
end

-- Code
OpenInventories, WeaponBuyers = {}, {}
ProcessingPlayers = {}

FW.Commands.Add("inventory:reset", "Reset a inventory busy state.", {
    { name = "invname", help = "Inventory name? (For Player use /inventory:reset:ply)" }
}, true, function(Source, Args)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    OpenInventories[Args[1]] = false
    Player.Functions.Notify('Inventory [' .. Args[1] .. '] gereset.', "success")
end, 'admin')

FW.Commands.Add("inventory:reset:ply", "Reset a PLAYER inventory busy state.", {
    { name = "id", help = "Player ID" }
}, true, function(Source, Args)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    local Target = FW.Functions.GetPlayer(tonumber(Args[1]))
    if Target then
        OpenInventories['ply-' .. Target.PlayerData.citizenid] = false
        Player.Functions.Notify('Inventory [ply-' .. Target.PlayerData.citizenid .. '] gereset.', "success")
    end
end, 'admin')

Citizen.CreateThread(function()
    -- Fetch all ItemTypes from DB.
    FetchCustomTypes()

    Citizen.SetTimeout(10000, function()
        -- Calculate prices with tax
        for Item, Types in pairs(Shared.CustomTypes) do
            for k, v in pairs(Types) do
                if v.Price and v.Price > 0 then
                    v.Price = FW.Shared.CalculateTax('Goods', v.Price)
                end
            end
        end
    
        -- Calculate prices with tax
        for k, v in pairs(Shared.Items) do
            if v.Price and v.Price > 0 then
                v.Price = FW.Shared.CalculateTax('Goods', v.Price)
            end
        end
    end)

    -- Ground drops: restore saved ones (Config.PersistentDrops) or wipe them like before.
    if Config.PersistentDrops then
        exports['ghmattimysql']:execute("DELETE FROM `player_inventories` WHERE `inventory` LIKE '%temp%'")
        LoadPersistentDrops()
    else
        exports['ghmattimysql']:execute("DELETE FROM `player_inventories` WHERE `inventory` LIKE '%drop%' OR `inventory` LIKE '%temp%'")
    end

    -- Delete decayed items.
    local MaxTime = (((1000 * 60) * 60) * 24) * 28
    while true do
        Citizen.Wait(4)
        local TimeNow = os.time() * 1000
        for k, v in pairs(Shared.Items) do
            if v.FullDecay and v.DecayRate > 0.0 then -- Some item's we don't want to delete after its broken.
                exports['ghmattimysql']:execute("DELETE FROM `player_inventories` WHERE `item_name` = @ItemName AND @DeleteTime > createdate", {
                    ['@ItemName'] = v.Name,
                    ['@DeleteTime'] = TimeNow - (MaxTime * v.DecayRate),
                })
            end
            Citizen.Wait(100)
        end
        Citizen.Wait((1000 * 60) * 10)
    end
end)

FW.Functions.CreateCallback('fw-inventory:Server:GetCustomTypes', function(Source, Cb)
    Cb(Shared.CustomTypes)
end)

FW.Functions.CreateCallback('fw-inventory:Server:IsProcessing', function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    Cb(ProcessingPlayers[Player.PlayerData.citizenid])
end)

FW.Functions.CreateCallback('fw-inventory:Server:CanBuyWeapon', function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    Cb(not WeaponBuyers[Player.PlayerData.citizenid])
end)

FW.Functions.CreateCallback('fw-inventory:Server:GetPlyItems', function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    Cb(GetInventoryItems('ply-' .. Player.PlayerData.citizenid))
end)

FW.Functions.CreateCallback('fw-inventory:Server:RefreshInventory', function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    Player.Functions.RefreshInventory()
    Cb(true)
end)

-- Frees every inventory this player still has locked (closed, reopened, or left).
function ReleaseInventoryLocks(Source, Except)
    for k, v in pairs(OpenInventories) do
        if v == Source and k ~= Except then
            OpenInventories[k] = false
        end
    end
end

AddEventHandler("playerDropped", function(Reason)
    ReleaseInventoryLocks(source)
end)

FW.RegisterServer("fw-inventory:Server:OpenInventory", function(Source, InvType, InvName, MaxSlots, MaxWeight)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    local MaxSlots = MaxSlots or 40
    local MaxWeight = MaxWeight or 250.0
    local OtherData = { Type = 'None', Name = 'None', Slots = 0, Weight = 0, Items = {} }

    if OpenInventories['ply-' .. Player.PlayerData.citizenid] then
        return Player.Functions.Notify("Lijkt erop dat iemand al in je zakken zit..", "error")
    end

    -- A ground inventory can only be opened while standing at it (stops remote looting).
    if InvType == 'Drop' and InvName and InvName:sub(1, 5) == 'Drop-' then
        local DropId = tonumber(InvName:sub(6))
        if not DropId or not IsPlayerNearDrop(Source, DropId) then
            InvName = false
        end
    end

    if not InvName then
        local DropId = NewDropId()
        CreateNewDrop(DropId, GetEntityCoords(GetPlayerPed(Source)))

        InvName = 'Drop-' .. DropId

        OtherData.Type = 'Drop'
        OtherData.Name = 'Drop-' .. DropId
        OtherData.Slots = 40
        OtherData.Weight = 250.0
        OtherData.Items = {}
    elseif InvType == 'Store' then
        if not Config.Stores[InvName] then return end

        local StoreItems = {[0] = false}
        for k, v in pairs(Config.Stores[InvName].Items) do
            table.insert(StoreItems, {
                Item = v.Item,
                CustomType = v.CustomType,
                Amount = v.Amount,
                Info = {},
                CreateDate = os.time() * 1000,
                Slot = k,
            })
        end

        OtherData.Type = 'Store'
        OtherData.Name = Config.Stores[InvName].Label
        OtherData.Store = InvName
        OtherData.Slots = #StoreItems
        OtherData.Weight = 0.0
        OtherData.Items = StoreItems
    elseif InvType == 'Crafting' then
        if not Config.CraftingBenches[InvName] then return end

        local CraftItems = {[0] = false}
        local CraftingRep = Player.PlayerData.metadata.craftingrep
        CraftingRep = CraftingRep or 0
        for k, v in pairs(Config.CraftingBenches[InvName]) do
            -- Locked recipes are sent too so the UI can show what unlocks next; the server still refuses them.
            if CraftingRep >= (v.RequiredRep or 0) or Config.ShowLockedRecipes then
                table.insert(CraftItems, {
                    Locked = CraftingRep < (v.RequiredRep or 0),
                    RequiredRep = v.RequiredRep or 0,
                    Item = v.Item,
                    CustomType = v.CustomType,
                    Amount = v.Amount,
                    Info = {},
                    CreateDate = os.time() * 1000,
                    Slot = k, -- index in Config.CraftingBenches[bench] (the NUI sends this back as FromSlot)
                    Multiplier = v.Multiplier or 1,
                })
            end
        end

        OtherData.Type = 'Crafting'
        OtherData.Name = 'Crafting'
        OtherData.Crafting = InvName
        OtherData.CraftingRep = CraftingRep
        OtherData.Slots = #CraftItems
        OtherData.Weight = 0.0
        OtherData.Items = CraftItems
    -- elseif InvType == 'Drop' then
    --     if OpenInventories[InvName] then
    --         TriggerClientEvent("fw-inventory:Client:LoadInventory", Source, { Type = 'None', Name = 'None', Slots = 0, Weight = 0, Items = {} })
    --         return
    --     end

    --     OtherData.Type = InvType
    --     OtherData.Name = InvName
    --     OtherData.Slots = MaxSlots
    --     OtherData.Weight = MaxWeight
    --     OtherData.Items = Config.Drops[tonumber(InvName:sub(6))].Items
    else
        -- Locked by someone else -> busy. Locked by this player (e.g. pressed E twice) -> just reopen it.
        if OpenInventories[InvName] and OpenInventories[InvName] ~= Source then
            TriggerClientEvent("fw-inventory:Client:LoadInventory", Source, { Type = 'None', Name = 'None', Slots = 0, Weight = 0, Items = {} })
            return
        end

        local Items = GetInventoryItems(InvName)
        OtherData.Type = InvType
        OtherData.Name = InvName
        OtherData.Slots = MaxSlots
        OtherData.Weight = MaxWeight
        OtherData.Items = Items

        -- Searching/robbing another player: show the same Pockets/Backpack/Body/Accessories layout.
        if string.startsWith(InvName, 'ply-') then
            OtherData.IsPlayer = true
            OtherData.Slots = Config.MaxPlayerSlots
            OtherData.Weight = GetMaxPlayerWeight(Items)

            local Target = FW.Functions.GetPlayerByCitizenId(InvName:sub(5))
            if Target then
                OtherData.Cash = Target.PlayerData.money.cash
                OtherData.Label = Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname
            elseif IsTestRobInventory(InvName) then
                OtherData.Cash = GetTestRobCash()
                OtherData.Label = Config.TestRob.Label
            end
        end
    end

    -- Anything else this player still had open (a previous open that never got closed) is freed.
    ReleaseInventoryLocks(Source, InvName)

    if InvName ~= 'Store' and InvName ~= 'Crafting' then
        OpenInventories[InvName] = Source
    end

    Player.Functions.RefreshInventory()

    TriggerClientEvent("fw-inventory:Client:LoadInventory", Source, OtherData)
end)

FW.RegisterServer("fw-inventory:Server:DoItemMovement", function(Source, Type, Data)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    -- print(json.encode(Data, {indent=2}))

    if Data.FromInv == 'player' then Data.FromInv = 'ply-' .. Player.PlayerData.citizenid end
    if Data.ToInv == 'player' then Data.ToInv = 'ply-' .. Player.PlayerData.citizenid end

    -- Pockets / Backpack / Body / Accessories rules (see sv_equipment.lua).
    local IsValid, Reason = ValidateItemMovement(Type, Data)
    if not IsValid then
        Player.Functions.Notify(Reason or "Dat kan niet.", "error")
        -- The NUI already moved the item optimistically; force a clean state.
        TriggerClientEvent("fw-inventory:Client:ForceClose", Source)
        return
    end

    if Type == "Move" then
        if Data.FromInv == "Store" then
            local StoreData = Config.Stores[Data.Store]
            if StoreData == nil then return end

            local StoreItem = Config.Stores[Data.Store].Items[Data.FromSlot]
            if StoreItem == nil then return end

            local Price = Shared.Items[StoreItem.Item].Price
            if StoreItem.CustomType and Shared.CustomTypes[StoreItem.Item] and Shared.CustomTypes[StoreItem.Item][StoreItem.CustomType].Price then
                Price = Shared.CustomTypes[StoreItem.Item][StoreItem.CustomType].Price
            end

            if Player.Functions.RemoveMoney("cash", Price * Data.Amount) then
                if Player.Functions.AddItem(StoreItem.Item, Data.Amount, Data.ToSlot, false, false, StoreItem.CustomType) then
                    TriggerEvent("fw-logs:Server:Log", 'store', "Item Purchased", ("User: [%s] - %s - %s %s\nItem: %s\nAmount: %sx\nStore: %s"):format(Player.PlayerData.source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Data.FromItem, Data.Amount, Data.Store), "green")
                    TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Data.ToSlot)

                    local _, Deduction = FW.Shared.DeductTax("Goods", Price)
                    exports['fw-financials']:AddMoneyToAccount('1001', "1", "1", Deduction * Data.Amount, '', '', true) -- Tax to the state
                else
                    TriggerEvent("fw-logs:Server:Log", 'store', "Purchase Failed", ("User: [%s] - %s - %s %s\nItem: %s\nAmount: %sx\nStore: %s"):format(Player.PlayerData.source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Data.FromItem, Data.Amount, Data.Store), "green")
                end

                if Shared.Items[StoreItem.Item].Weapon and Data.Store == 'Ammunation' then
                    WeaponBuyers[Player.PlayerData.citizenid] = true
                end
            end
        elseif Data.FromInv == "Crafting" then
            -- The recipe must exist on this bench, match the item, and be unlocked for this player.
            local Bench = Config.CraftingBenches[Data.Crafting]
            local Recipe = Bench and Bench[tonumber(Data.FromSlot)]
            if not Recipe or Recipe.Item ~= Data.FromItem or (Recipe.CustomType or "") ~= (Data.FromType or "") then return end
            if (Player.PlayerData.metadata.craftingrep or 0) < (Recipe.RequiredRep or 0) then return end
            Data.Amount = math.max(1, math.min(math.floor(tonumber(Data.Amount) or 1), Recipe.Amount or 1))

            local ItemData = Shared.Items[Data.FromItem]
            local ItemCrafts = ItemData.Craft
            if Data.FromType and #Data.FromType > 0 and Shared.CustomTypes[Data.FromItem] and Shared.CustomTypes[Data.FromItem][Data.FromType] and Shared.CustomTypes[Data.FromItem][Data.FromType].Craft then
                ItemCrafts = Shared.CustomTypes[Data.FromItem][Data.FromType].Craft
            end

            local hasAllCraftItems = true
            for k, v in pairs(ItemCrafts) do
                local hasThisItem = Player.Functions.HasEnoughOfItem(v.Item, (v.Amount * Data.Amount), v.CustomType)
                if not hasThisItem then
                    hasAllCraftItems = false
                    break
                end
            end

            if not hasAllCraftItems then
                return
            end

            for k, v in pairs(ItemCrafts) do
                didRemoveItems = Player.Functions.RemoveItemByName(v.Item, (v.Amount * Data.Amount), false, v.CustomType)
            end
            local ItemInfo = false
            if Data.FromItem and string.startsWith(Data.FromItem, 'weapon_') then
                local SerialPrefix = Player.PlayerData.citizenid
                ItemInfo = {
                    Serial = SerialPrefix .. '-' .. FW.Shared.RandomStr(4) .. '-' .. FW.Shared.RandomInt(3),
                    Ammo = 0
                }
            end
            if Player.Functions.AddItem(Data.FromItem, Data.Amount * (Recipe.Multiplier or 1), Data.ToSlot, ItemInfo, false, Data.FromType) then
                if Recipe.AddRep then
                    Player.Functions.SetMetaData('craftingrep', Player.PlayerData.metadata.craftingrep + (Recipe.AddRep * Data.Amount))
                end
                TriggerEvent("fw-logs:Server:Log", 'crafting', "Item Crafted", ("User: [%s] - %s - %s %s\nItem: %s\nAmount: %sx\nTable: %s"):format(Player.PlayerData.source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Data.FromItem, Data.Amount, Data.Crafting), "green")
                TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Data.ToSlot)
                -- Materials were removed by name from any slot: refresh the whole player panel.
                TriggerClientEvent("fw-inventory:Client:RefreshPlayerInventory", Player.PlayerData.source)
            else
                TriggerEvent("fw-logs:Server:Log", 'crafting', "Craft Failed", ("User: [%s] - %s - %s %s\nItem: %s\nAmount: %sx\nTable: %s"):format(Player.PlayerData.source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Data.FromItem, Data.Amount, Data.Crafting), "error")
            end
        else
            ProcessingPlayers[Player.PlayerData.citizenid] = true
            local Result = exports['ghmattimysql']:execute("UPDATE player_inventories SET `slot` = @ToSlot, inventory = @ToInv WHERE `slot` = @FromSlot AND `inventory` = @FromInv AND `item_name` = @Item LIMIT " .. Data.Amount, {
                ['@ToSlot'] = Data.ToSlot,
                ['@ToInv'] = Data.ToInv,
                ['@FromSlot'] = Data.FromSlot,
                ['@FromInv'] = Data.FromInv,
                ['@Item'] = Data.FromItem
            }, function()
                Citizen.SetTimeout(10, function()
                    TriggerEvent("fw-logs:Server:Log", 'moveitem', "Item Moved", ("User: [%s] - %s - %s %s\nItem: %s [%s]\nInventory: %s [%s] -> %s [%s]"):format(Player.PlayerData.source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Data.FromItem, Data.Amount, Data.FromInv, Data.FromSlot, Data.ToInv, Data.ToSlot), "blue")

                    -- Refresh Slots
                    if Data.FromInv == 'ply-' .. Player.PlayerData.citizenid then
                        Player.Functions.RefreshInvSlot(Data.FromSlot)

                        if Shared.Items[Data.FromItem].HasProp then
                            TriggerClientEvent("fw-assets:Client:Attach:Items", Source)
                        end
                        TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Data.FromSlot)
                    end

                    if Data.ToInv == 'ply-' .. Player.PlayerData.citizenid then
                        Player.Functions.RefreshInvSlot(Data.ToSlot)

                        if Shared.Items[Data.FromItem].HasProp then
                            TriggerClientEvent("fw-assets:Client:Attach:Items", Source)
                        end
                        TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, Data.ToSlot)
                    end

                    -- Refresh Drops (every ground item is its own prop, see sv_drops.lua)
                    if Data.FromInv == Data.ToInv then MoveDropProps(Data.FromInv, Data.FromSlot, Data.ToSlot, false) end
                    SyncDropByName(Data.FromInv)
                    if Data.ToInv ~= Data.FromInv then SyncDropByName(Data.ToInv) end

                    -- If 'Other Player', refresh Targets slots.
                    if string.startsWith(Data.FromInv, 'ply-') and Data.FromInv:sub(5) ~= Player.PlayerData.citizenid then
                        local Target = FW.Functions.GetPlayerByCitizenId(Data.FromInv:sub(5))

                        if Target then
                            Target.Functions.RefreshInvSlot(Data.FromSlot)
                            TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Target.PlayerData.source, Data.FromSlot)

                            if Shared.Items[Data.FromItem].Weapon then
                                TriggerClientEvent("fw-inventory:Client:CheckWeapon", Target.PlayerData.source, Data.FromItem)
                            end

                            if Shared.Items[Data.FromItem].HasProp then
                                TriggerClientEvent("fw-assets:Client:Attach:Items", Target.PlayerData.source)
                            end
                        end
                    end

                    if string.startsWith(Data.ToInv, 'ply-') and Data.ToInv:sub(5) ~= Player.PlayerData.citizenid then
                        local Target = FW.Functions.GetPlayerByCitizenId(Data.ToInv:sub(5))

                        if Target then
                            Target.Functions.RefreshInvSlot(Data.ToSlot)
                            TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Target.PlayerData.source, Data.ToSlot)

                            if Data.ToItem then
                                if Shared.Items[Data.ToItem].Weapon then
                                    TriggerClientEvent("fw-inventory:Client:CheckWeapon", Target.PlayerData.source, Data.ToItem)
                                end

                                if Shared.Items[Data.ToItem].HasProp then
                                    TriggerClientEvent("fw-assets:Client:Attach:Items", Target.PlayerData.source)
                                end
                            end
                        end
                    end

                    ProcessingPlayers[Player.PlayerData.citizenid] = false
                end)
            end)
        end
    elseif Type == "Swap" then
        TriggerEvent("fw-logs:Server:Log", 'moveitem', "Item Swapped", ("User: [%s] - %s - %s %s\nItem: %s -> %s\nInventory: %s [%s] -> %s [%s]"):format(Player.PlayerData.source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Data.FromItem, Data.ToItem, Data.FromInv, Data.FromSlot, Data.ToInv, Data.ToSlot), "pink")

        -- Set FromSlot > ToSlot
        exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = @ToSlot, inventory = @ToInv WHERE `slot` = @FromSlot AND `inventory` = @FromInv AND `item_name` = @Item AND `custom_type` = @Type LIMIT " .. Data.FromAmount, {
            ['@ToSlot'] = Data.ToSlot,
            ['@ToInv'] = Data.ToInv,
            ['@FromSlot'] = Data.FromSlot,
            ['@FromInv'] = Data.FromInv,
            ['@Item'] = Data.FromItem,
            ['@Type'] = Data.FromType,
        })

        exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = @ToSlot, inventory = @ToInv WHERE `slot` = @FromSlot AND `inventory` = @FromInv AND `item_name` = @Item AND `custom_type` = @Type LIMIT " .. Data.ToAmount, {
            ['@ToSlot'] = Data.FromSlot,
            ['@ToInv'] = Data.FromInv,
            ['@FromSlot'] = Data.ToSlot,
            ['@FromInv'] = Data.ToInv,
            ['@Item'] = Data.ToItem,
            ['@Type'] = Data.ToType,
        })

        Player.Functions.RefreshInvSlot(Data.FromSlot)
        Player.Functions.RefreshInvSlot(Data.ToSlot)

        if Data.FromInv == Data.ToInv then MoveDropProps(Data.FromInv, Data.FromSlot, Data.ToSlot, true) end
        SyncDropByName(Data.FromInv)
        if Data.ToInv ~= Data.FromInv then SyncDropByName(Data.ToInv) end

        if (string.startsWith(Data.FromInv, 'ply-') or string.startsWith(Data.ToInv, 'ply-')) and Data.FromInv ~= Data.ToInv then
            local Target = FW.Functions.GetPlayerByCitizenId(Data.ToInv:sub(5))
            if Target then
                if Target.PlayerData.source == Source then return end

                if Data.FromInv == 'ply-' .. Player.PlayerData.citizenid then
                    Target.Functions.RefreshInvSlot(Data.FromSlot)
                    TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Target.PlayerData.source, Data.FromSlot)

                    if Shared.Items[Data.FromItem].Weapon then
                        TriggerClientEvent("fw-inventory:Client:CheckWeapon", Target.PlayerData.source, Data.FromItem)
                    end

                    if Shared.Items[Data.FromItem].HasProp then
                        TriggerClientEvent("fw-assets:Client:Attach:Items", Target.PlayerData.source)
                    end
                end

                if Data.ToInv == 'ply-' .. Player.PlayerData.citizenid then
                    Target.Functions.RefreshInvSlot(Data.ToSlot)
                    TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Target.PlayerData.source, Data.ToSlot)

                    if Shared.Items[Data.ToItem].Weapon then
                        TriggerClientEvent("fw-inventory:Client:CheckWeapon", Target.PlayerData.source, Data.ToItem)
                    end

                    if Shared.Items[Data.ToItem].HasProp then
                        TriggerClientEvent("fw-assets:Client:Attach:Items", Target.PlayerData.source)
                    end
                end
            end
        end
    end
end)

FW.RegisterServer("fw-inventory:Server:UpdateInventory", function(Source, InvData)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    -- Free everything this player had open, not only InvData.Name: after a double open the
    -- client may only know about the last one (e.g. 'None'), which used to leave stashes locked.
    if InvData and InvData.Name and OpenInventories[InvData.Name] == Source then OpenInventories[InvData.Name] = false end
    ReleaseInventoryLocks(Source)

    -- lazy fix. Probably should improve/rework drops later.
    -- if string.startsWith(InvData.Name, 'Drop') then
    --     for k, v in pairs(Config.Drops) do
    --         if v.Name == InvData.Name then
    --             if #v.Items == 0 then
    --                 v.Coords = vector3(0.0, 0.0, 0.0)
    --                 TriggerClientEvent("fw-inventory:Client:SetDropData", -1, k, Config.Drops[k])
    --             end
    --             break
    --         end
    --     end
    -- end
end)

FW.RegisterServer("fw-inventory:Server:UseItem", function(Source, Slot, IgnoreShowbox)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    local Item = Player.PlayerData.inventory[Slot]
    if Item == nil then return end

    local ItemData = Shared.Items[Item.Item]
    if not ItemData then return end

    if CalculateQuality(Item.Item, Item.CreateDate) < 1.0 then
        return Player.Functions.Notify("Item is kapot..", "error")
    end

    if ItemData.Weapon then
        TriggerClientEvent("fw-inventory:Client:UseWeapon", Source, Item)
        Player.Functions.DecayItem(Item.Item, Slot, 0.1)
    else
        if not IgnoreShowbox then
            TriggerClientEvent('fw-inventory:Client:ShowActionBox', Source, 'Gebruikt', Item.Item, 1, Item.CustomType)
        end
        Citizen.SetTimeout(IgnoreShowbox and 250 or 750, function()
            TriggerClientEvent("fw-inventory:Client:OnItemUsed", Source, Item, ItemData)

            if not FW.Functions.CanUseItem(Item.Item) then return end
            FW.Functions.UseItem(Source, Item)
        end)
    end
end)

FW.RegisterServer("fw-inventory:Server:StealMoney", function(Source, InvData)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    local Inventory = InvData.Name
    if string.sub(Inventory, 1, 3) ~= 'ply' then return end

    -- /inventory:testrob: fake cash, nothing is actually paid out.
    if IsTestRobInventory(Inventory) then
        local Amount = GetTestRobCash()
        if Amount <= 0 then return Player.Functions.Notify("[TEST] Geen cash meer.", "error") end
        TestRobTakeCash()
        Player.Functions.Notify(("[TEST] Je zou €%s gestolen hebben (geen echt geld)."):format(Amount), "success")
        TriggerClientEvent("fw-inventory:Client:SetOtherCash", Source, 0)
        return
    end

    local Cid = Inventory:sub(5)
    local Target = FW.Functions.GetPlayerByCitizenId(Cid)
    if Target == nil then return end

    local Distance = #(GetEntityCoords(GetPlayerPed(Source)) - GetEntityCoords(GetPlayerPed(Target.PlayerData.source)))
    if Distance > 2.0 then
        if Distance > 10 then
            TriggerEvent("fw-logs:Server:Log", 'anticheat', "__Possible__ Cheater", ("User: [%s] - %s - %s %s\nTarget: [%s] - %s - %s %s\nUser tried to rob Targets money, but was too far away. *(Distance: %sm)*"):format(Source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Target.PlayerData.source, Target.PlayerData.citizenid, Target.PlayerData.charinfo.firstname, Target.PlayerData.charinfo.lastname, math.floor(Distance)), "orange")
        end

        return
    end

    local Money = Target.PlayerData.money.cash
    if Money <= 0 then return end

    if Target.Functions.RemoveMoney('cash', Money, Player.PlayerData.citizenid .. ' yoinked his money') then
        if Player.PlayerData.job.name == 'police' then
            Player.Functions.AddItem('moneybag', 1, false, { Worth = Money }, true)
        else
            Player.Functions.AddMoney('cash', Money, 'Money yoinked from ' .. Target.PlayerData.citizenid)
        end
        TriggerClientEvent("fw-inventory:Client:SetOtherCash", Source, 0)
    end
end)

RegisterNetEvent("fw-inventory:Server:OnItemInsert")
AddEventHandler("fw-inventory:Server:OnItemInsert", function(FromItem, ToItem, IsReversed)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    if FromItem.Item == "repairhammer" then
        local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET createdate = @CreateDate WHERE `inventory` = @Inv AND `item_name` = @Item AND `slot` = @Slot", {
            ['@Inv'] = 'ply-' .. Player.PlayerData.citizenid,
            ['@Item'] = ToItem.Item,
            ['@Slot'] = ToItem.Slot,
            ['@CreateDate'] = os.time() * 1000,
        })

        Player.Functions.RefreshInvSlot(ToItem.Slot)
        TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Player.PlayerData.source, ToItem.Slot)
    end
end)

function CreateNewDrop(DropId, Coords)
    Config.Drops[DropId] = {
        Name = 'Drop-' .. DropId,
        Coords = Coords,
        ItemCount = 0,
        Items = {[0] = false},
        Props = {}, -- [Slot] = { Coords, Heading, Exact } for placed/thrown items
    }

    TriggerClientEvent("fw-inventory:Client:SetDropData", -1, DropId, Config.Drops[DropId])
end

function FetchCustomTypes()
    local DbTypes = exports['ghmattimysql']:executeSync("SELECT * FROM `server_customtypes`")
    for k, v in pairs(DbTypes) do
        if Shared.CustomTypes[v.item_id] == nil then
            Shared.CustomTypes[v.item_id] = {}
        end

        Shared.CustomTypes[v.item_id][v.type_id] = {
            Label = v.label,
            Description = v.description,
            Image = v.image,
            IsExternImage = v.isExternImage,
            Craft = json.decode(v.craft),
            Price = 0
        }
    end

    -- TriggerClientEvent("fw-inventory:Client:RefreshCustomTypes", -1, Shared.CustomTypes)
end

RegisterNetEvent("fw-inventory:Server:DecayItem")
AddEventHandler("fw-inventory:Server:DecayItem", function(Item, Slot, Percentage)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end
    Player.Functions.DecayItem(Item, Slot, Percentage)
end)

RegisterNetEvent("fw-inventory:Server:RefreshCustomTypes")
AddEventHandler("fw-inventory:Server:RefreshCustomTypes", function()
    FetchCustomTypes()
end)