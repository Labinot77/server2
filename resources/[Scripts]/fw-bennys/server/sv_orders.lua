-- Work orders: created when a customer pays at an order zone, handled by the business' mechanics.
FW = FW or exports['fw-core']:GetCoreObject()

local DB = exports['ghmattimysql']
local Orders = {}          -- [Id] = order (pending + accepted + recent history)
local BusinessCache = {}   -- [Business] = { Members = { [Cid] = true }, Expires = os.time() }

-- ── Helpers ────────────────────────────────────────────────────────────────

local function Notify(Source, Text, Type)
    TriggerClientEvent('FW:Notify', Source, Text, Type or 'primary')
end

local function GetMembers(Business)
    local Cached = BusinessCache[Business]
    if Cached and Cached.Expires > os.time() then return Cached.Members end

    local Members = {}
    local Result = DB:executeSync("SELECT `business_owner`, `business_employees` FROM `phone_businesses` WHERE `business_name` = ?", { Business })
    if Result and Result[1] then
        if Result[1].business_owner then Members[Result[1].business_owner] = true end
        for _, Employee in ipairs(json.decode(Result[1].business_employees or '[]') or {}) do
            if Employee.Cid then Members[Employee.Cid] = true end
        end
    end

    BusinessCache[Business] = { Members = Members, Expires = os.time() + 30 }
    return Members
end

-- Called by sv_management.lua after hiring / firing, so membership updates right away.
function ClearBusinessCache(Business) BusinessCache[Business] = nil end

local function IsMember(Source, Business)
    if not Config.Orders.Businesses[Business] then return false end
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return false end
    return GetMembers(Business)[Player.PlayerData.citizenid] == true
end

local function PlayerName(Player)
    local Info = Player.PlayerData.charinfo
    return ('%s %s'):format(Info.firstname, Info.lastname)
end

local function Decode(Row)
    return {
        Id = Row.id,
        Business = Row.business,
        Status = Row.status,
        CustomerCid = Row.customer_cid,
        CustomerName = Row.customer_name,
        Plate = Row.plate,
        Model = Row.model,
        NetId = Row.net_id,
        Items = json.decode(Row.items or '[]') or {},
        Total = Row.total,
        Method = Row.method,
        MechanicCid = Row.mechanic_cid,
        MechanicName = Row.mechanic_name,
        CreatedAt = Row.created_at,
        UpdatedAt = Row.updated_at,
    }
end

local function Save(Order)
    Order.UpdatedAt = os.time()
    DB:execute("UPDATE `bennys_orders` SET `status` = ?, `items` = ?, `mechanic_cid` = ?, `mechanic_name` = ?, `updated_at` = ? WHERE `id` = ?", {
        Order.Status, json.encode(Order.Items), Order.MechanicCid, Order.MechanicName, Order.UpdatedAt, Order.Id,
    })
end

-- Orders shown on the laptop: everything open, plus the latest finished ones.
local function GetBusinessOrders(Business)
    local Open, History = {}, {}
    for _, Order in pairs(Orders) do
        if Order.Business == Business then
            if Order.Status == 'pending' or Order.Status == 'accepted' then
                Open[#Open + 1] = Order
            else
                History[#History + 1] = Order
            end
        end
    end

    table.sort(Open, function(A, B) return A.Id < B.Id end)
    table.sort(History, function(A, B) return A.UpdatedAt > B.UpdatedAt end)
    for I = Config.Orders.HistoryCount + 1, #History do History[I] = nil end

    for _, Order in ipairs(History) do Open[#Open + 1] = Order end
    return Open
end

-- Push the current list to every online member of the business; everyone else gets it for the laptop screen only.
local function Broadcast(Business)
    local List = GetBusinessOrders(Business)
    local Members = GetMembers(Business)
    for _, Data in pairs(FW.GetPlayers()) do
        local Player = FW.Functions.GetPlayer(Data.ServerId)
        if Player and Members[Player.PlayerData.citizenid] then
            TriggerClientEvent('fw-bennys:Client:Orders:Updated', Data.ServerId, Business, List)
        elseif Player then
            TriggerClientEvent('fw-bennys:Client:Laptop:View', Data.ServerId, Business, List)
        end
    end
end

local function NotifyCustomer(Order, Text, Type)
    local Customer = FW.Functions.GetPlayerByCitizenId(Order.CustomerCid)
    if Customer then Notify(Customer.PlayerData.source, Text, Type) end
end

local function AllInstalled(Order)
    for _, Item in ipairs(Order.Items) do
        if not Item.Installed then return false end
    end
    return true
end

local function GetOrderVehicle(Order)
    if Order.NetId and Order.NetId ~= 0 then
        local Vehicle = NetworkGetEntityFromNetworkId(Order.NetId)
        if Vehicle ~= 0 and DoesEntityExist(Vehicle) and GetEntityType(Vehicle) == 2 then
            return Vehicle
        end
    end

    -- Net id changed (vehicle respawned) -> find it by plate.
    for _, Vehicle in ipairs(GetAllVehicles()) do
        if DoesEntityExist(Vehicle) and GetVehicleNumberPlateText(Vehicle):gsub('%s+', '') == Order.Plate:gsub('%s+', '') then
            Order.NetId = NetworkGetNetworkIdFromEntity(Vehicle)
            return Vehicle
        end
    end
end

-- ── Stance ─────────────────────────────────────────────────────────────────

local STANCE_LIMITS = {
    SpacersFront = { 0.3, 1.5 }, SpacersRear = { 0.3, 1.5 },
    CamberFront = { 0.0, 0.5 }, CamberRear = { 0.0, 0.5 },
    Width = { 0.3, 1.5 }, Suspension = { -0.2, 0.2 },
}

-- Only known keys, clamped to sane values. Returns nil when empty.
local function CleanStance(Stance)
    if type(Stance) ~= 'table' then return nil end
    local Clean, Any = {}, false
    for Key, Limit in pairs(STANCE_LIMITS) do
        local Value = tonumber(Stance[Key])
        if Value then
            Clean[Key] = math.max(Limit[1], math.min(Limit[2], Value))
            Any = true
        end
    end
    return Any and Clean or nil
end

local function SetVehicleStance(Vehicle, Stance)
    if Vehicle and Vehicle ~= 0 and DoesEntityExist(Vehicle) then
        Entity(Vehicle).state:set('bennysStance', Stance, true)
    end
end

-- fw-core calls this after applying saved mods: the stance is taken from the database, not the client.
RegisterNetEvent('fw-bennys:Server:SyncStance', function(NetId, Plate)
    local Vehicle = NetworkGetEntityFromNetworkId(tonumber(NetId) or 0)
    if Vehicle == 0 or not DoesEntityExist(Vehicle) or type(Plate) ~= 'string' then return end

    Plate = Plate:gsub('^%s*(.-)%s*$', '%1')
    if GetVehicleNumberPlateText(Vehicle):gsub('%s+', '') ~= Plate:gsub('%s+', '') then return end

    local Result = DB:executeSync("SELECT `mods` FROM `player_vehicles` WHERE `plate` = ? LIMIT 1", { Plate })
    local Mods = Result and Result[1] and json.decode(Result[1].mods or '{}') or {}
    SetVehicleStance(Vehicle, CleanStance(Mods.Stance))
end)

-- ── Saving mods ────────────────────────────────────────────────────────────

local PendingSaves = {} -- [OrderId] = { Owner, Mechanic, Final, Expires }

-- Ask the vehicle's network owner for a snapshot of its mods (on Complete / after each install).
local function RequestModsSnapshot(Order, Mechanic, Final)
    local Vehicle = GetOrderVehicle(Order)
    if not Vehicle then
        if Mechanic then Notify(Mechanic, "Vehicle not found, the mods could not be saved.", 'error') end
        return false
    end

    local Owner = NetworkGetEntityOwner(Vehicle)
    if not Owner or Owner <= 0 then Owner = Mechanic end
    if not Owner then return false end

    PendingSaves[Order.Id] = { Owner = Owner, Mechanic = Mechanic, Final = Final, Expires = os.time() + 60 }
    TriggerClientEvent('fw-bennys:Client:Orders:Snapshot', Owner, Order.Id, Order.NetId, Order.Plate)
    return true
end

RegisterNetEvent('fw-bennys:Server:Orders:SaveMods', function(OrderId, Mods)
    local Source = source
    local Order = Orders[tonumber(OrderId)]
    local Pending = PendingSaves[tonumber(OrderId)]
    if not Order or not Pending or Pending.Owner ~= Source or Pending.Expires < os.time() then return end -- only the client we asked
    if type(Mods) ~= 'table' or next(Mods) == nil then return end
    -- Kept (not cleared) so a second quick install's snapshot, which includes everything, is saved too.
    local Final = Pending.Final
    Pending.Final = false

    -- Stance comes from the vehicle's state bag; validate it and keep the bag in sync.
    Mods.Stance = CleanStance(Mods.Stance)
    if Mods.Stance then SetVehicleStance(GetOrderVehicle(Order), Mods.Stance) end

    -- Plates in player_vehicles are stored trimmed; GTA pads them to 8 characters.
    local Plate = Order.Plate:gsub('^%s*(.-)%s*$', '%1')
    local Result = DB:executeSync("UPDATE `player_vehicles` SET `mods` = ? WHERE `plate` = ?", { json.encode(Mods), Plate })
    local Saved = Result and (Result.affectedRows or Result.changedRows or 0) > 0

    if not Saved then
        -- affectedRows is 0 when nothing changed too, so check the vehicle exists.
        local Exists = DB:executeSync("SELECT 1 FROM `player_vehicles` WHERE `plate` = ? LIMIT 1", { Plate })
        Saved = Exists and Exists[1] ~= nil
    end

    print(('[fw-bennys] Order #%d mods %s for %s'):format(Order.Id, Saved and 'saved' or 'NOT saved (not an owned vehicle)', Plate))

    if Final then
        local Text = Saved and ("Order #%d completed, the mods are saved."):format(Order.Id)
            or ("Order #%d completed, but %s is not an owned vehicle: the mods were not saved."):format(Order.Id, Plate)
        if Pending.Mechanic then Notify(Pending.Mechanic, Text, Saved and 'success' or 'error') end
        TriggerEvent('fw-logs:Server:Log', 'bennysMenu', 'Order Completed', ("Order: #%d\nPlate: %s\nCustomer: %s\nMechanic: %s\nSaved: %s\nMods: ```json\n%s```"):format(Order.Id, Plate, Order.CustomerName, tostring(Order.MechanicName), tostring(Saved), json.encode(Mods)), 'green')
    end
end)

-- ── Startup ────────────────────────────────────────────────────────────────

CreateThread(function()
    DB:executeSync([[
        CREATE TABLE IF NOT EXISTS `bennys_orders` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `business` VARCHAR(64) NOT NULL,
            `status` VARCHAR(16) NOT NULL DEFAULT 'pending',
            `customer_cid` VARCHAR(64) NOT NULL,
            `customer_name` VARCHAR(128) NOT NULL,
            `plate` VARCHAR(16) NOT NULL,
            `model` VARCHAR(64) NOT NULL,
            `net_id` INT NOT NULL DEFAULT 0,
            `items` LONGTEXT NOT NULL,
            `total` INT NOT NULL DEFAULT 0,
            `method` VARCHAR(16) NOT NULL DEFAULT 'Cash',
            `mechanic_cid` VARCHAR(64) NULL DEFAULT NULL,
            `mechanic_name` VARCHAR(128) NULL DEFAULT NULL,
            `created_at` INT NOT NULL,
            `updated_at` INT NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `business_status` (`business`, `status`)
        )
    ]])

    -- Open orders + recent history (last 3 days).
    local Rows = DB:executeSync("SELECT * FROM `bennys_orders` WHERE `status` IN ('pending', 'accepted') OR `updated_at` > ?", { os.time() - 259200 }) or {}
    for _, Row in ipairs(Rows) do
        Orders[Row.id] = Decode(Row)
    end
    print(('[fw-bennys] Loaded %d work orders'):format(#Rows))
end)

-- ── Customer: create order ─────────────────────────────────────────────────

RegisterNetEvent('fw-bennys:Server:Orders:Create', function(Business, Receipt, NetId)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if not Player or not Config.Orders.Businesses[Business] then return end
    if type(Receipt) ~= 'table' or type(Receipt.Items) ~= 'table' or #Receipt.Items == 0 or #Receipt.Items > 100 then return end

    local Vehicle = NetworkGetEntityFromNetworkId(NetId or 0)
    if Vehicle == 0 or not DoesEntityExist(Vehicle) then
        return Notify(Source, "Vehicle not found.", 'error')
    end

    -- One open order per vehicle.
    local Plate = GetVehicleNumberPlateText(Vehicle):gsub('^%s*(.-)%s*$', '%1')
    for _, Order in pairs(Orders) do
        if Order.Plate == Plate and (Order.Status == 'pending' or Order.Status == 'accepted') then
            return Notify(Source, ("There is already an open order for this vehicle (#%d)."):format(Order.Id), 'error')
        end
    end

    -- TODO: take payment (Receipt.Method) here. Prices are recalculated client side for now.
    local Items, Total = {}, 0
    for _, Item in ipairs(Receipt.Items) do
        local Price = math.max(0, math.floor(tonumber(Item.Price) or 0))
        Total = Total + Price
        Items[#Items + 1] = {
            Slot = tostring(Item.Slot),
            Label = tostring(Item.Label or Item.Slot),
            Option = tostring(Item.Option or ''),
            Value = Item.Value,
            Price = Price,
            Installed = false,
        }
    end

    local Now = os.time()
    local Order = {
        Business = Business,
        Status = 'pending',
        CustomerCid = Player.PlayerData.citizenid,
        CustomerName = PlayerName(Player),
        Plate = Plate,
        Model = tostring(Receipt.Model or 'Unknown'),
        NetId = NetId,
        Items = Items,
        Total = Total,
        Method = Receipt.Method == 'Bank' and 'Bank' or 'Cash',
        CreatedAt = Now,
        UpdatedAt = Now,
    }

    local Id = DB:executeSync("INSERT INTO `bennys_orders` (`business`, `status`, `customer_cid`, `customer_name`, `plate`, `model`, `net_id`, `items`, `total`, `method`, `created_at`, `updated_at`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", {
        Order.Business, Order.Status, Order.CustomerCid, Order.CustomerName, Order.Plate, Order.Model, Order.NetId, json.encode(Order.Items), Order.Total, Order.Method, Now, Now,
    })
    Order.Id = type(Id) == 'table' and (Id.insertId or Id[1] and Id[1].insertId) or Id
    if not Order.Id then
        local Row = DB:executeSync("SELECT `id` FROM `bennys_orders` WHERE `customer_cid` = ? ORDER BY `id` DESC LIMIT 1", { Order.CustomerCid })
        Order.Id = Row and Row[1] and Row[1].id
    end
    if not Order.Id then return Notify(Source, "The order could not be created.", 'error') end

    Orders[Order.Id] = Order
    print(('[fw-bennys] Order #%d created for %s (%s) at %s - $%d'):format(Order.Id, Order.CustomerName, Order.Plate, Business, Total))

    Notify(Source, ("Order #%d was sent to %s. A mechanic will get to work on it."):format(Order.Id, Business), 'success')

    local Members = GetMembers(Business)
    for _, Data in pairs(FW.GetPlayers()) do
        local Member = FW.Functions.GetPlayer(Data.ServerId)
        if Member and Members[Member.PlayerData.citizenid] then
            Notify(Data.ServerId, ("New work order #%d: %s (%s)"):format(Order.Id, Order.Model, Order.Plate), 'primary')
        end
    end

    Broadcast(Business)
end)

-- ── Mechanic: laptop ───────────────────────────────────────────────────────

-- Businesses (that take orders) the player works at.
FW.Functions.CreateCallback('fw-bennys:Server:Orders:GetMyBusinesses', function(Source, Cb)
    local List = {}
    for Business in pairs(Config.Orders.Businesses) do
        if IsMember(Source, Business) then List[#List + 1] = Business end
    end
    Cb(List)
end)

-- Read-only list for the laptop screen, anyone near a laptop can see it.
FW.Functions.CreateCallback('fw-bennys:Server:Orders:View', function(Source, Cb, Business)
    if not Config.Orders.Businesses[Business] then return Cb(false) end
    Cb(GetBusinessOrders(Business))
end)

FW.Functions.CreateCallback('fw-bennys:Server:Orders:Get', function(Source, Cb, Business)
    if not IsMember(Source, Business) then return Cb(false) end
    Cb(GetBusinessOrders(Business))
end)

FW.Functions.CreateCallback('fw-bennys:Server:Orders:Action', function(Source, Cb, Action, Id)
    local Player = FW.Functions.GetPlayer(Source)
    local Order = Orders[tonumber(Id)]
    if not Player or not Order then return Cb({ Success = false, Message = 'Order not found' }) end
    if not IsMember(Source, Order.Business) then return Cb({ Success = false, Message = 'No access' }) end

    local Cid = Player.PlayerData.citizenid
    local Mine = Order.MechanicCid == Cid

    if Action == 'accept' then
        if Order.Status ~= 'pending' then return Cb({ Success = false, Message = 'This order was already taken' }) end
        Order.Status = 'accepted'
        Order.MechanicCid = Cid
        Order.MechanicName = PlayerName(Player)
        Order.ReleasedBy = nil
        NotifyCustomer(Order, ("Your order #%d was taken by %s."):format(Order.Id, Order.MechanicName), 'success')
    elseif Action == 'release' then
        -- Unassign: installed items stay installed, so another mechanic continues where this one left off.
        if Order.Status ~= 'accepted' or not Mine then return Cb({ Success = false, Message = 'This is not your order' }) end
        Order.Status = 'pending'
        Order.MechanicCid = nil
        Order.MechanicName = nil
        Order.ReleasedBy = PlayerName(Player)

        local Done = 0
        for _, Item in ipairs(Order.Items) do if Item.Installed then Done = Done + 1 end end

        local Members = GetMembers(Order.Business)
        for _, Data in pairs(FW.GetPlayers()) do
            local Member = FW.Functions.GetPlayer(Data.ServerId)
            if Data.ServerId ~= Source and Member and Members[Member.PlayerData.citizenid] then
                Notify(Data.ServerId, ("Order #%d (%s) is available again - %d/%d installed."):format(Order.Id, Order.Plate, Done, #Order.Items), 'primary')
            end
        end
    elseif Action == 'decline' then
        if Order.Status ~= 'pending' and not (Order.Status == 'accepted' and Mine) then return Cb({ Success = false, Message = 'This order cannot be declined' }) end
        Order.Status = 'cancelled'
        Order.MechanicCid = Order.MechanicCid or Cid
        Order.MechanicName = Order.MechanicName or PlayerName(Player)
        -- TODO: refund the customer for items that were not installed.
        NotifyCustomer(Order, ("Your order #%d at %s was cancelled."):format(Order.Id, Order.Business), 'error')
    elseif Action == 'complete' then
        if Order.Status ~= 'accepted' or not Mine then return Cb({ Success = false, Message = 'This is not your order' }) end
        if not AllInstalled(Order) then return Cb({ Success = false, Message = 'Not everything is installed yet' }) end
        Order.Status = 'completed'
        NotifyCustomer(Order, ("Your vehicle (%s) is ready! Order #%d is completed."):format(Order.Plate, Order.Id), 'success')
        RequestModsSnapshot(Order, Source, true)
    else
        return Cb({ Success = false, Message = 'Onbekende actie' })
    end

    Save(Order)
    Broadcast(Order.Business)
    Cb({ Success = true })
end)

-- ── Mechanic: install an item ──────────────────────────────────────────────

FW.Functions.CreateCallback('fw-bennys:Server:Orders:InstallItem', function(Source, Cb, Id, Index)
    local Player = FW.Functions.GetPlayer(Source)
    local Order = Orders[tonumber(Id)]
    Index = tonumber(Index)
    if not Player or not Order or not Index then return Cb({ Success = false, Message = 'Order not found' }) end
    if Order.Status ~= 'accepted' or Order.MechanicCid ~= Player.PlayerData.citizenid then return Cb({ Success = false, Message = 'This is not your order' }) end

    local Item = Order.Items[Index]
    if not Item then return Cb({ Success = false, Message = 'Part not found' }) end
    if Item.Installed then return Cb({ Success = false, Message = 'Already installed' }) end

    local Vehicle = GetOrderVehicle(Order)
    if not Vehicle then return Cb({ Success = false, Message = 'Vehicle not found' }) end

    local Distance = #(GetEntityCoords(GetPlayerPed(Source)) - GetEntityCoords(Vehicle))
    if Distance > Config.Orders.MaxInstallDistance then return Cb({ Success = false, Message = 'You are too far from the vehicle' }) end

    Item.Installed = true
    Item.InstalledBy = PlayerName(Player)

    -- Mods only sync when set by the entity owner, so the owner's client applies it.
    local Finished = AllInstalled(Order)

    -- The owner applies it and sends back a snapshot of all mods, which is saved (see SaveMods below).
    local Owner = NetworkGetEntityOwner(Vehicle)
    if not Owner or Owner <= 0 then Owner = Source end
    PendingSaves[Order.Id] = { Owner = Owner, Mechanic = Source, Final = Finished, Expires = os.time() + 60 }
    TriggerClientEvent('fw-bennys:Client:Orders:ApplyItem', Owner, Order.Id, Order.NetId, Item.Slot, Item.Value, Order.Plate)

    if Finished then
        Order.Status = 'completed'
        NotifyCustomer(Order, ("Your vehicle (%s) is ready! Order #%d is completed."):format(Order.Plate, Order.Id), 'success')
    end

    Save(Order)
    Broadcast(Order.Business)

    TriggerEvent('fw-logs:Server:Log', 'bennysMenu', 'Order Item Installed', ("Mechanic: [%s] %s - %s\nOrder: #%d (%s)\nItem: %s %s"):format(Source, Player.PlayerData.citizenid, PlayerName(Player), Order.Id, Order.Plate, Item.Label, Item.Option), 'green')
    Cb({ Success = true, Finished = Finished })
end)

-- Cache refresh when a business changes employees.
RegisterNetEvent('fw-businesses:Server:RefreshBusinesses', function() BusinessCache = {} end)

-- ── Laptops (from placed_props) ────────────────────────────────────────────

local Laptops = {} -- { { Id, Model, Coords, Business } }

local function ParseVector(Value)
    local Data = type(Value) == 'string' and json.decode(Value) or Value
    if type(Data) ~= 'table' then return nil end
    local X, Y, Z = tonumber(Data.x or Data[1]), tonumber(Data.y or Data[2]), tonumber(Data.z or Data[3])
    if not X or not Y or not Z then return nil end
    return vector3(X, Y, Z)
end

function LoadLaptops()
    local Models = {}
    for Model in pairs(Config.Laptop.Models) do Models[#Models + 1] = Model end
    if #Models == 0 then Laptops = {} return end

    local Placeholders = ('?'):rep(#Models, ', ')
    local Rows = DB:executeSync(('SELECT `id`, `model`, `coords` FROM `placed_props` WHERE `model` IN (%s)'):format(Placeholders), Models) or {}

    local List = {}
    for _, Row in ipairs(Rows) do
        local Coords = ParseVector(Row.coords)
        if Coords then
            -- Assign to the business whose area the laptop is placed in.
            local Assigned = false
            for Business, Data in pairs(Config.Orders.Businesses) do
                if Data.Area and #(Coords - Data.Area.Center) <= Data.Area.Radius then
                    List[#List + 1] = { Id = Row.id, Model = Row.model, Coords = Coords, Business = Business }
                    Assigned = true
                    break
                end
            end
            if not Assigned then
                print(('[fw-bennys] placed_props #%s (%s) at %.2f, %.2f, %.2f is not inside any Config.Orders.Businesses Area'):format(Row.id, Row.model, Coords.x, Coords.y, Coords.z))
            end
        else
            print(('[fw-bennys] placed_props #%s (%s) has unreadable coords: %s'):format(Row.id, Row.model, tostring(Row.coords)))
        end
    end

    Laptops = List
    print(('[fw-bennys] Loaded %d work-order laptop(s) from placed_props'):format(#List))
    TriggerClientEvent('fw-bennys:Client:Laptop:SetLaptops', -1, Laptops)
end

CreateThread(function()
    Wait(1000)
    LoadLaptops()
end)

local LastLaptopLoad = 0
FW.Functions.CreateCallback('fw-bennys:Server:Laptop:GetLaptops', function(Source, Cb, Reload)
    -- Clients ask for a reload when they see a laptop prop that isn't known yet (placed after start).
    if Reload and os.time() - LastLaptopLoad >= 10 then
        LastLaptopLoad = os.time()
        LoadLaptops()
    end
    Cb(Laptops)
end)

-- Call after placing/removing a laptop prop: TriggerEvent('fw-bennys:Server:Laptop:Reload')
AddEventHandler('fw-bennys:Server:Laptop:Reload', LoadLaptops)
-- fw-admin fires this after a prop is placed / deleted / reloaded, so new laptops work right away.
AddEventHandler('fw-admin:Server:PropsChanged', LoadLaptops)
RegisterCommand('bennysreloadlaptops', function(Source)
    if Source ~= 0 and not IsPlayerAceAllowed(Source, 'command') then return end
    LoadLaptops()
end, false)
