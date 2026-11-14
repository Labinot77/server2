-- // Ground items \\ --
-- Every slot of a 'Drop-<id>' inventory is rendered as its own world prop (client/cl_drops.lua)
-- with an interact point to pick it up. Items that were placed or thrown keep the exact spot
-- they landed on (Drop.Props[slot]); items dragged into the ground inventory are laid out
-- around the drop centre.

Config.DropSlots = 40
Config.DropMergeDistance = 1.5   -- Placing within this range of an existing drop adds to that drop.
Config.PlaceMaxDistance = 8.0    -- Server side sanity checks (client limit is lower).
Config.ThrowMaxDistance = 45.0
Config.PickupDistance = 3.0

Config.DropOpenDistance = 3.0     -- Server check: max distance to an item of the drop you open.

-- Drop ids must stay unique across restarts once drops are saved, so they're handed out
-- from a counter instead of #Config.Drops (which also breaks on sparse tables).
Config.NextDropId = 1
function NewDropId()
    local Id = Config.NextDropId
    Config.NextDropId = Id + 1
    return Id
end

local function DropIdFromName(InvName)
    if type(InvName) ~= 'string' or InvName:sub(1, 5) ~= 'Drop-' then return false end
    return tonumber(InvName:sub(6))
end
exports("DropIdFromName", DropIdFromName)

-- Compact, client-safe view of a drop.
local function SerializeDrop(Drop)
    local Slots = {}
    for Slot, Item in pairs(Drop.Items or {}) do
        if type(Slot) == 'number' and Slot > 0 and Item then
            Slots[Slot] = { Item = Item.Item, CustomType = Item.CustomType, Amount = Item.Amount }
        end
    end

    return {
        Name = Drop.Name,
        Coords = Drop.Coords,
        ItemCount = Drop.ItemCount or 0,
        Slots = Slots,
        Props = Drop.Props or {},
    }
end

-- Re-reads a drop from the database and pushes it to every client.
function SyncDrop(DropId)
    DropId = tonumber(DropId)
    local Drop = DropId and Config.Drops[DropId]
    if not Drop then return end

    Drop.Props = Drop.Props or {}
    Drop.Items = GetInventoryItems(Drop.Name)

    local Count = 0
    for Slot, Item in pairs(Drop.Items) do
        if type(Slot) == 'number' and Slot > 0 and Item then Count = Count + 1 end
    end

    -- Forget placement data of slots that are empty now.
    for Slot in pairs(Drop.Props) do
        if not Drop.Items[Slot] then Drop.Props[Slot] = nil end
    end

    Drop.ItemCount = Count
    if Config.PersistentDrops then SaveDrop(DropId) end
    TriggerClientEvent("fw-inventory:Client:SetDropData", -1, DropId, SerializeDrop(Drop))
end
exports("SyncDrop", SyncDrop)

function SyncDropByName(InvName)
    local DropId = DropIdFromName(InvName)
    if DropId then SyncDrop(DropId) end
end

-- Keeps a placed item's spot when it's moved to another slot inside the same drop.
function MoveDropProps(InvName, FromSlot, ToSlot, IsSwap)
    local Drop = Config.Drops[DropIdFromName(InvName) or -1]
    if not Drop or not Drop.Props then return end

    FromSlot, ToSlot = tonumber(FromSlot), tonumber(ToSlot)
    if IsSwap then
        Drop.Props[FromSlot], Drop.Props[ToSlot] = Drop.Props[ToSlot], Drop.Props[FromSlot]
    elseif Drop.Props[FromSlot] and not Drop.Props[ToSlot] then
        Drop.Props[ToSlot] = Drop.Props[FromSlot]
    end
end

-- Late joiners / resource restart: send every drop that still has items.
FW.Functions.CreateCallback('fw-inventory:Server:GetDrops', function(Source, Cb)
    local Retval = {}
    for DropId, Drop in pairs(Config.Drops) do
        if Drop.ItemCount and Drop.ItemCount > 0 then
            Retval[#Retval + 1] = { Id = DropId, Data = SerializeDrop(Drop) }
        end
    end
    Cb(Retval)
end)

local function FindFreeDropSlot(DropId)
    local Drop = Config.Drops[DropId]
    local Items = Drop.Items or GetInventoryItems(Drop.Name)
    for i = 1, Config.DropSlots do
        if not Items[i] then return i end
    end
    return false
end

-- Nearest drop around Coords that still has a free slot, or a new one.
local function GetDropForPlacement(Coords)
    local BestId, BestDist = false, Config.DropMergeDistance
    for DropId, Drop in pairs(Config.Drops) do
        if Drop.Coords and Drop.ItemCount and Drop.ItemCount > 0 then
            local Dist = #(vector3(Drop.Coords.x, Drop.Coords.y, Drop.Coords.z) - Coords)
            if Dist <= BestDist and not OpenInventories[Drop.Name] and FindFreeDropSlot(DropId) then
                BestId, BestDist = DropId, Dist
            end
        end
    end

    if BestId then return BestId end

    local NewId = NewDropId()
    CreateNewDrop(NewId, Coords)
    return NewId
end

-- // Place / throw from the hand \\ --
-- Locks every pile it could merge into, so two players placing on the same pile can't take the same slot.
RegisterLocked("fw-inventory:Server:PlaceItem", function(Source, Slot, Amount, Coords)
    local Names = {}
    if type(Coords) ~= 'vector3' then return Names end
    for _, Drop in pairs(Config.Drops) do
        if Drop.Coords and #(vector3(Drop.Coords.x, Drop.Coords.y, Drop.Coords.z) - Coords) <= Config.DropMergeDistance + 0.5 then
            Names[#Names + 1] = Drop.Name
        end
    end
    return Names
end, function(Source, Slot, Amount, Coords, Heading, Thrown)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    Slot, Amount, Heading = tonumber(Slot), tonumber(Amount), tonumber(Heading) or 0.0
    if not Slot or type(Coords) ~= 'vector3' then return end

    local InvName = 'ply-' .. Player.PlayerData.citizenid
    if OpenInventories[InvName] then
        return Player.Functions.Notify("Iemand zit in je zakken..", "error")
    end

    local Item = Player.PlayerData.inventory[Slot]
    if not Item then return end

    local PedCoords = GetEntityCoords(GetPlayerPed(Source))
    local MaxDistance = Thrown and Config.ThrowMaxDistance or Config.PlaceMaxDistance
    if #(PedCoords - Coords) > MaxDistance then
        TriggerEvent("fw-logs:Server:Log", 'anticheat', "__Possible__ Cheater", ("User: [%s] - %s\nTried to place %s %.1fm away."):format(Source, Player.PlayerData.citizenid, Item.Item, #(PedCoords - Coords)), "orange")
        return
    end

    Amount = math.max(1, math.min(math.floor(Amount or Item.Amount), Item.Amount))

    local DropId = GetDropForPlacement(Coords)
    local DropName = 'Drop-' .. DropId

    -- Same rules as dragging it out of the inventory (backpack must be empty, ...).
    local Valid, Reason = ValidateItemMovement("Move", {
        FromInv = InvName, ToInv = DropName, FromSlot = Slot, ToSlot = 1, FromItem = Item.Item, Amount = Amount,
    })
    if not Valid then return Player.Functions.Notify(Reason or "Dat kan niet.", "error") end

    Config.Drops[DropId].Items = GetInventoryItems(DropName)
    local ToSlot = FindFreeDropSlot(DropId)
    if not ToSlot then return Player.Functions.Notify("Hier ligt al te veel.", "error") end

    local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = @ToSlot, `inventory` = @ToInv WHERE `inventory` = @FromInv AND `slot` = @FromSlot AND `item_name` = @Item LIMIT " .. Amount, {
        ['@ToSlot'] = ToSlot,
        ['@ToInv'] = DropName,
        ['@FromInv'] = InvName,
        ['@FromSlot'] = Slot,
        ['@Item'] = Item.Item,
    })
    if not Result or Result.affectedRows == 0 then return end

    Config.Drops[DropId].Props = Config.Drops[DropId].Props or {}
    Config.Drops[DropId].Props[ToSlot] = { Coords = Coords, Heading = Heading, Exact = not Thrown }

    TriggerEvent("fw-logs:Server:Log", 'moveitem', Thrown and "Item Thrown" or "Item Placed", ("User: [%s] - %s - %s %s\nItem: %s [%s]\nInventory: %s [%s] -> %s [%s]"):format(Source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Item.Item, Amount, InvName, Slot, DropName, ToSlot), "blue")

    Player.Functions.RefreshInvSlot(Slot)
    TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Source, Slot)
    if Shared.Items[Item.Item].Weapon then TriggerClientEvent("fw-inventory:Client:CheckWeapon", Source, Item.Item) end
    if Shared.Items[Item.Item].HasProp then TriggerClientEvent("fw-assets:Client:Attach:Items", Source) end

    SyncDrop(DropId)
end)

-- // Spawn an item straight onto the ground (scripts: NPC drops, loot, ...) \\ --
function SpawnItemDrop(Coords, Item, Amount, Info, Heading)
    local DropId = GetDropForPlacement(Coords)
    local DropName = 'Drop-' .. DropId
    Config.Drops[DropId].Items = GetInventoryItems(DropName)

    local Slot = FindFreeDropSlot(DropId)
    if not Slot or not AddItemToInventory(DropName, Item, Amount or 1, Slot, Info) then return false end

    Config.Drops[DropId].Props = Config.Drops[DropId].Props or {}
    Config.Drops[DropId].Props[Slot] = { Coords = Coords, Heading = Heading or 0.0, Exact = false }
    SyncDrop(DropId)
    return true
end
exports("SpawnItemDrop", SpawnItemDrop)

-- // Pick up a single ground item \\ --
RegisterLocked("fw-inventory:Server:PickupDropItem", function(Source, DropId)
    return { 'Drop-' .. tostring(tonumber(DropId)) }
end, function(Source, DropId, Slot)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end

    DropId, Slot = tonumber(DropId), tonumber(Slot)
    local Drop = DropId and Config.Drops[DropId]
    if not Drop or not Slot then return end

    if OpenInventories[Drop.Name] then
        return Player.Functions.Notify("Iemand anders doorzoekt dit al.", "error")
    end

    local Item = GetInventoryItemBySlot(Drop.Name, Slot)
    if not Item then return SyncDrop(DropId) end

    -- Distance to the item itself (placed/thrown) or to the drop centre.
    local Spot = Drop.Props and Drop.Props[Slot] and Drop.Props[Slot].Coords or Drop.Coords
    local PedCoords = GetEntityCoords(GetPlayerPed(Source))
    if #(PedCoords - vector3(Spot.x, Spot.y, Spot.z)) > Config.PickupDistance then return end

    local ItemData = Shared.Items[Item.Item]
    local TypeData = Item.CustomType and Shared.CustomTypes and Shared.CustomTypes[Item.Item] and Shared.CustomTypes[Item.Item][Item.CustomType]
    local Weight = ((TypeData and TypeData.Weight) or ItemData.Weight) * Item.Amount
    if GetTotalItemsWeight('ply-' .. Player.PlayerData.citizenid) + Weight > GetMaxPlayerWeight(Player.PlayerData.inventory) then
        return Player.Functions.Notify("Je bent te overgewicht.", "error")
    end

    local ToSlot = FindPlayerSlot(Player.PlayerData.inventory, Item.Item, Item.CustomType)
    if not ToSlot then return Player.Functions.Notify("Je hebt geen ruimte.", "error") end

    -- A stack only fits in an equip slot if it's a single item.
    if IsEquipSlot(ToSlot) and Item.Amount > 1 then
        local Lookup = {}
        for k, v in pairs(Player.PlayerData.inventory) do Lookup[k] = v end
        Lookup[ToSlot] = { Item = '__reserved', Amount = 1 }
        ToSlot = FindPlayerSlot(Lookup, Item.Item, Item.CustomType)
        if not ToSlot then return Player.Functions.Notify("Je hebt geen ruimte.", "error") end
    end

    local Result = exports['ghmattimysql']:executeSync("UPDATE player_inventories SET `slot` = @ToSlot, `inventory` = @ToInv WHERE `inventory` = @FromInv AND `slot` = @FromSlot", {
        ['@ToSlot'] = ToSlot,
        ['@ToInv'] = 'ply-' .. Player.PlayerData.citizenid,
        ['@FromInv'] = Drop.Name,
        ['@FromSlot'] = Slot,
    })
    if not Result or Result.affectedRows == 0 then return SyncDrop(DropId) end

    TriggerEvent("fw-logs:Server:Log", 'moveitem', "Item Picked Up", ("User: [%s] - %s - %s %s\nItem: %s [%s]\nInventory: %s [%s] -> ply [%s]"):format(Source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Item.Item, Item.Amount, Drop.Name, Slot, ToSlot), "blue")

    Player.Functions.RefreshInvSlot(ToSlot)
    TriggerClientEvent("fw-inventory:Client:UpdateInvSlot", Source, ToSlot)
    TriggerClientEvent("fw-inventory:Client:ShowActionBox", Source, "Opgepakt", Item.Item, Item.Amount, Item.CustomType)
    if ItemData.HasProp then TriggerClientEvent("fw-assets:Client:Attach:Items", Source) end

    SyncDrop(DropId)
end)

-- // Server-side proximity \\ --
-- The server has no world collision, so it can't raycast. The client does the line-of-sight
-- check; here we make sure nobody can open/loot a drop they're not standing at.
function IsPlayerNearDrop(Source, DropId, MaxDistance)
    local Drop = Config.Drops[DropId]
    if not Drop or not Drop.Coords then return false end

    local PedCoords = GetEntityCoords(GetPlayerPed(Source))
    MaxDistance = MaxDistance or Config.DropOpenDistance

    local C = Drop.Coords
    if #(PedCoords - vector3(C.x, C.y, C.z)) <= MaxDistance then return true end

    for _, Props in pairs(Drop.Props or {}) do
        local P = Props.Coords
        if P and #(PedCoords - vector3(P.x, P.y, P.z)) <= MaxDistance then return true end
    end

    -- Auto laid-out items sit within ~1m of the centre.
    return #(PedCoords - vector3(C.x, C.y, C.z)) <= MaxDistance + 1.0
end

-- // Persistence (Config.PersistentDrops) \\ --
-- Item rows already live in player_inventories ('Drop-<id>'); this table keeps where the drop
-- is and where each placed/thrown item lies.
local function EncodeDropProps(Props)
    local List = {}
    for Slot, P in pairs(Props or {}) do
        if P and P.Coords then
            List[#List + 1] = { s = Slot, x = P.Coords.x, y = P.Coords.y, z = P.Coords.z, h = P.Heading or 0.0, e = P.Exact and 1 or 0 }
        end
    end
    return json.encode(List)
end

local function DecodeDropProps(Text)
    local Props = {}
    local Ok, List = pcall(json.decode, Text or '[]')
    if not Ok or type(List) ~= 'table' then return Props end
    for _, P in ipairs(List) do
        if P.s and P.x then
            Props[tonumber(P.s)] = { Coords = vector3(P.x + 0.0, P.y + 0.0, P.z + 0.0), Heading = (P.h or 0.0) + 0.0, Exact = P.e == 1 }
        end
    end
    return Props
end

function SaveDrop(DropId)
    local Drop = Config.Drops[DropId]
    if not Drop then return end

    if (Drop.ItemCount or 0) <= 0 then
        exports['ghmattimysql']:executeSync("DELETE FROM `inventory_drops` WHERE `id` = @Id", { ['@Id'] = DropId })
        return
    end

    local C = Drop.Coords
    exports['ghmattimysql']:executeSync([[
        INSERT INTO `inventory_drops` (`id`, `coords`, `props`, `updated_at`) VALUES (@Id, @Coords, @Props, @Time)
        ON DUPLICATE KEY UPDATE `coords` = @Coords, `props` = @Props, `updated_at` = @Time
    ]], {
        ['@Id'] = DropId,
        ['@Coords'] = json.encode({ x = C.x, y = C.y, z = C.z }),
        ['@Props'] = EncodeDropProps(Drop.Props),
        ['@Time'] = os.time(),
    })
end

-- Called once on resource start (from _sv_main.lua) instead of wiping every drop.
function LoadPersistentDrops()
    exports['ghmattimysql']:executeSync([[
        CREATE TABLE IF NOT EXISTS `inventory_drops` (
            `id` INT NOT NULL,
            `coords` LONGTEXT NOT NULL,
            `props` LONGTEXT NOT NULL,
            `updated_at` INT NOT NULL,
            PRIMARY KEY (`id`)
        )
    ]])

    -- Expired drops: items + drop row.
    if Config.DropLifetimeHours and Config.DropLifetimeHours > 0 then
        local Expired = exports['ghmattimysql']:executeSync("SELECT `id` FROM `inventory_drops` WHERE `updated_at` < @Time", {
            ['@Time'] = os.time() - math.floor(Config.DropLifetimeHours * 3600),
        }) or {}
        for _, Row in pairs(Expired) do
            exports['ghmattimysql']:executeSync("DELETE FROM `player_inventories` WHERE `inventory` = @Inv", { ['@Inv'] = 'Drop-' .. Row.id })
            exports['ghmattimysql']:executeSync("DELETE FROM `inventory_drops` WHERE `id` = @Id", { ['@Id'] = Row.id })
        end
        if #Expired > 0 then print(("[fw-inventory] Removed %s expired ground drops."):format(#Expired)) end
    end

    local Rows = exports['ghmattimysql']:executeSync("SELECT * FROM `inventory_drops`") or {}
    local Known, MaxId = {}, 0

    for _, Row in pairs(Rows) do
        local Ok, C = pcall(json.decode, Row.coords)
        if Ok and type(C) == 'table' and C.x then
            Config.Drops[Row.id] = {
                Name = 'Drop-' .. Row.id,
                Coords = vector3(C.x + 0.0, C.y + 0.0, C.z + 0.0),
                ItemCount = 0,
                Items = {[0] = false},
                Props = DecodeDropProps(Row.props),
            }
            Known['Drop-' .. Row.id] = true
        end
        MaxId = math.max(MaxId, Row.id)
    end

    -- Item rows of drops we have no position for (old/non-persistent drops) can't be shown: remove them.
    local Inventories = exports['ghmattimysql']:executeSync("SELECT DISTINCT `inventory` FROM `player_inventories` WHERE `inventory` LIKE 'Drop-%'") or {}
    for _, Row in pairs(Inventories) do
        local Id = tonumber(tostring(Row.inventory):sub(6))
        if Id then MaxId = math.max(MaxId, Id) end
        if not Known[Row.inventory] then
            exports['ghmattimysql']:executeSync("DELETE FROM `player_inventories` WHERE `inventory` = @Inv", { ['@Inv'] = Row.inventory })
        end
    end

    Config.NextDropId = MaxId + 1

    -- Rebuild item lists/counts (also drops rows that turned out empty).
    local Loaded = 0
    for DropId in pairs(Known) do
        local Id = tonumber(DropId:sub(6))
        SyncDrop(Id)
        if Config.Drops[Id] and Config.Drops[Id].ItemCount > 0 then Loaded = Loaded + 1 end
    end

    print(("[fw-inventory] Loaded %s saved ground drops."):format(Loaded))
end

-- Glovebox only while seated in that car; a drop only while standing at it.
-- An empty drop (just created when the inventory opened) follows the player, so items land where they are now.
local function Trim(Text) return (tostring(Text or ''):gsub('^%s+', ''):gsub('%s+$', '')) end

function ValidateWorldAccess(Source, Data)
    local Ped = GetPlayerPed(Source)
    for _, InvName in ipairs({ Data.FromInv, Data.ToInv }) do
        if type(InvName) == 'string' and InvName:sub(1, 8) == 'glovebox' then
            local Vehicle = GetVehiclePedIsIn(Ped, false)
            if Vehicle == 0 or Trim(GetVehicleNumberPlateText(Vehicle)) ~= Trim(InvName:sub(9)) then
                return false, "Je zit niet meer in het voertuig."
            end
        end

        local DropId = DropIdFromName(InvName)
        local Drop = DropId and Config.Drops[DropId]
        if Drop and InvName == Data.ToInv and (Drop.ItemCount or 0) == 0 then
            Drop.Coords = GetEntityCoords(Ped)
            TriggerClientEvent("fw-inventory:Client:SetDropData", -1, DropId, Drop)
        elseif Drop and not IsPlayerNearDrop(Source, DropId) then
            return false, "Je bent te ver weg."
        end
    end
    return true
end

-- // Ground panel above a stash / trunk \\ --
-- Shown for shared inventories (stash, trunk, ...) while on foot; not for the ground itself,
-- gloveboxes, stores, benches or another player's pockets.
function ShowsGroundWith(Source, InvType, InvName)
    if not IsSharedInventory(InvName) or InvType == 'Drop' or InvName:sub(1, 5) == 'Drop-' then return false end
    if InvName:sub(1, 8) == 'glovebox' then return false end
    return GetVehiclePedIsIn(GetPlayerPed(Source), false) == 0
end

-- The pile you're standing at (the fullest nearby one), else an empty spot here (reused, or new).
function GetGroundDropName(Source)
    local Coords = GetEntityCoords(GetPlayerPed(Source))
    local Best, BestDist, Empty
    for DropId, Drop in pairs(Config.Drops) do
        if Drop.Coords then
            local Dist = #(vector3(Drop.Coords.x, Drop.Coords.y, Drop.Coords.z) - Coords)
            if Dist <= Config.DropOpenDistance then
                if (Drop.ItemCount or 0) > 0 then
                    if not BestDist or Dist < BestDist then Best, BestDist = DropId, Dist end
                elseif not Empty then
                    Empty = DropId
                end
            end
        end
    end

    local DropId = Best or Empty
    if not DropId then
        DropId = NewDropId()
        CreateNewDrop(DropId, Coords)
    end
    return 'Drop-' .. DropId
end
