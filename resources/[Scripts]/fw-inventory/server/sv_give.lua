-- // Give the item in your hand to another player \\ --
-- Client (cl_hand.lua) finds the player with a camera ray + a head-to-head line-of-sight ray and
-- uses the interact prompt on them. The server has no world collision, so here: distance, item,
-- inventory rules (slots / backpack / equip slots) and the receiver's weight.

Config.GiveMaxDistance = 4.0 -- server tolerance (client uses Config.GiveDistance = 2.5)

local function Notify(Player, Text, Type) Player.Functions.Notify(Text, Type or "error") end

FW.RegisterServer("fw-inventory:Server:GiveHeldItem", function(Source, TargetSource, Slot, Amount)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    TargetSource = tonumber(TargetSource)
    local Target = TargetSource and FW.Functions.GetPlayer(TargetSource)
    if not Target or TargetSource == Source then return Notify(Player, "Geen speler gevonden.") end

    local MyCoords = GetEntityCoords(GetPlayerPed(Source))
    local TheirCoords = GetEntityCoords(GetPlayerPed(TargetSource))
    if #(MyCoords - TheirCoords) > Config.GiveMaxDistance then
        return Notify(Player, "Deze persoon staat te ver weg.")
    end

    local MyInv, TheirInv = 'ply-' .. Player.PlayerData.citizenid, 'ply-' .. Target.PlayerData.citizenid
    if OpenInventories[MyInv] or OpenInventories[TheirInv] then
        return Notify(Player, "Dat kan nu niet.")
    end

    Slot = tonumber(Slot)
    local Item = Slot and Player.PlayerData.inventory[Slot]
    if not Item then return end
    Amount = math.max(1, math.min(math.floor(tonumber(Amount) or Item.Amount), Item.Amount))

    -- Room + weight on the receiver.
    local ItemData = Shared.Items[Item.Item]
    local TypeData = Item.CustomType and Shared.CustomTypes and Shared.CustomTypes[Item.Item] and Shared.CustomTypes[Item.Item][Item.CustomType]
    local Weight = ((TypeData and TypeData.Weight) or ItemData.Weight) * Amount
    if GetTotalItemsWeight(TheirInv) + Weight > GetMaxPlayerWeight(Target.PlayerData.inventory) then
        Notify(Target, "Je kan dit niet meer dragen.")
        return Notify(Player, "Deze persoon kan dit niet meer dragen.")
    end

    local TheirItems = Target.PlayerData.inventory
    local ToSlot = FindPlayerSlot(TheirItems, Item.Item, Item.CustomType)
    if ToSlot and IsEquipSlot(ToSlot) and Amount > 1 then
        local Lookup = {}
        for k, v in pairs(TheirItems) do Lookup[k] = v end
        Lookup[ToSlot] = { Item = '__reserved', Amount = 1 }
        ToSlot = FindPlayerSlot(Lookup, Item.Item, Item.CustomType)
    end
    if not ToSlot then
        return Notify(Player, "Deze persoon heeft geen ruimte.")
    end

    -- Same rules as dragging it there (backpack must be empty, equip slot rules, ...).
    local Valid, Reason = ValidateItemMovement("Move", {
        FromInv = MyInv, ToInv = TheirInv, FromSlot = Slot, ToSlot = ToSlot, FromItem = Item.Item, Amount = Amount,
    })
    if not Valid then return Notify(Player, Reason or "Dat kan niet.") end

    local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = @ToSlot, `inventory` = @ToInv WHERE `inventory` = @FromInv AND `slot` = @FromSlot AND `item_name` = @Item LIMIT " .. Amount, {
        ['@ToSlot'] = ToSlot,
        ['@ToInv'] = TheirInv,
        ['@FromInv'] = MyInv,
        ['@FromSlot'] = Slot,
        ['@Item'] = Item.Item,
    })
    if not Result or Result.affectedRows == 0 then return end

    TriggerEvent("fw-logs:Server:Log", 'moveitem', "Item Given", ("User: [%s] - %s - %s %s\nItem: %s [%s]\nTo: [%s] - %s - %s %s [%s]"):format(
        Source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Item.Item, Result.affectedRows,
        TargetSource, Target.PlayerData.citizenid, Target.PlayerData.charinfo.firstname, Target.PlayerData.charinfo.lastname, ToSlot), "blue")

    Player.Functions.RefreshInvSlot(Slot)
    Target.Functions.RefreshInvSlot(ToSlot)
    TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Source, Slot)
    TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", TargetSource, ToSlot)

    TriggerClientEvent("fw-inventory:Client:ShowActionBox", Source, "Gegeven", Item.Item, Result.affectedRows, Item.CustomType)
    TriggerClientEvent("fw-inventory:Client:ShowActionBox", TargetSource, "Ontvangen", Item.Item, Result.affectedRows, Item.CustomType)
    TriggerClientEvent("fw-inventory:Client:ReceiveGiveAnim", TargetSource, Source)

    if ItemData.Weapon then TriggerClientEvent("fw-inventory:Client:CheckWeapon", Source, Item.Item) end
    if ItemData.HasProp then
        TriggerClientEvent("fw-assets:Client:Attach:Items", Source)
        TriggerClientEvent("fw-assets:Client:Attach:Items", TargetSource)
    end
end)
