-- Dealership app (html/dealership.html): showroom spots, pulling cars out of stock and selling them through the
-- business' cash register (Config.Dealership). Uses the fw-businesses vehicle shop logic (placements, stock,
-- registration). Needs VehicleSales (owner always).
FW = FW or exports['fw-core']:GetCoreObject()

local DB = exports['ghmattimysql']
local PulledOut = {} -- [Source] = { Shop, Model }
local Registers = {} -- [Business] = { Seller, Shop, Model, Name, Price, Taxes, Total, Comment, NetId }

local function RegisterKey(Business) return 'dealership_register_' .. Config.Orders.Businesses[Business].Shop end

local function GetShop(Source, Business)
    local Data = Config.Orders.Businesses[Business]
    local Access = Data and Data.Shop and GetBusinessAccess(Source, Business)
    return Access and Access.Perms.VehicleSales and Data.Shop or nil
end

local function GetCatalog(Shop)
    local List = {}
    for _, Row in ipairs(DB:executeSync("SELECT `vehicle`, `stock` FROM `server_vehicles` WHERE `shop` = ?", { Shop }) or {}) do
        local Shared = FW.Shared.HashVehicles[GetHashKey(Row.vehicle)]
        if Shared then
            List[#List + 1] = { Model = Row.vehicle, Name = Shared.Name, Price = Shared.Price, Stock = math.max(0, tonumber(Row.stock) or 0) }
        end
    end
    table.sort(List, function(A, B) return A.Name < B.Name end)
    return List
end

local function FindVehicle(Shop, Model)
    for _, V in ipairs(GetCatalog(Shop)) do
        if V.Model == Model then return V end
    end
end

local function GetTaxes(Price)
    local List, Total = {}, Price
    for _, Name in ipairs(Config.Dealership.Taxes) do
        local Rate = FW.Shared.CalculateTax(Name, 100) - 100 -- live fw-core rate (%)
        local Amount = math.ceil(Price * Rate / 100)
        List[#List + 1] = { Label = Name, Rate = Rate, Amount = Amount }
        Total = Total + Amount
    end
    return List, Total
end

local function BuildView(Business, Shop)
    local Spots = {}
    for I, Spot in ipairs(exports['fw-businesses']:GetVehicleShopPlacements(Shop) or {}) do Spots[I] = Spot.Vehicle or false end
    local Order = Registers[Business]
    return {
        Catalog = GetCatalog(Shop), Spots = Spots, Taxes = (GetTaxes(0)),
        Order = Order and { Name = Order.Name, Price = Order.Price, Total = Order.Total, Comment = Order.Comment } or false,
    }
end

local function SetOrder(Business, Order)
    Registers[Business] = Order
    GlobalState[RegisterKey(Business)] = Order and { Name = Order.Name, Total = Order.Total, Comment = Order.Comment } or nil
end

local function Result(Message, Success, Business, Shop)
    return { Success = Success, Message = Message, View = Success and BuildView(Business, Shop) or nil }
end

-- ── Setup: business, bank account and catalog when missing ─────────────────

CreateThread(function()
    Wait(1000)
    for Business, Data in pairs(Config.Orders.Businesses) do
        if Data.Shop and Data.Account and not DB:executeSync("SELECT 1 FROM `phone_businesses` WHERE `business_name` = ?", { Business })[1] then
            DB:executeSync("INSERT INTO `phone_businesses` (`business_owner`, `business_name`, `business_account`, `business_employees`, `business_ranks`) VALUES ('1001', ?, ?, '[]', '[]')", { Business, Data.Account })
            DB:executeSync("INSERT INTO `player_financials` (`citizenid`, `name`, `accountid`, `balance`, `type`, `authorized`, `active`, `monitored`) VALUES ('1001', ?, ?, 0, 'Bedrijfsrekening', '[]', 1, 0)", { Business, Data.Account })
            print(('[fw-bennys] Created business %s'):format(Business))
        end
        if Data.Shop and Data.Catalog and not DB:executeSync("SELECT 1 FROM `server_vehicles` WHERE `shop` = ? LIMIT 1", { Data.Shop })[1] then
            for Model, Stock in pairs(Data.Catalog) do
                DB:executeSync("INSERT INTO `server_vehicles` (`shop`, `vehicle`, `stock`, `preset`) VALUES (?, ?, ?, '[]')", { Data.Shop, Model, Stock })
            end
            print(('[fw-bennys] Created the %s catalog'):format(Data.Shop))
        end
    end
end)

-- ── App ────────────────────────────────────────────────────────────────────

FW.Functions.CreateCallback('fw-bennys:Server:Dealership:Get', function(Source, Cb, Business)
    local Shop = GetShop(Source, Business)
    Cb(Shop and BuildView(Business, Shop) or { Denied = true })
end)

-- Spot is 1-based here, 0-based in fw-businesses.
FW.Functions.CreateCallback('fw-bennys:Server:Dealership:SetSpot', function(Source, Cb, Business, Spot, Model)
    local Shop = GetShop(Source, Business)
    if not Shop then return Cb({ Denied = true }) end
    Spot = tonumber(Spot) or 0
    local Count = #(exports['fw-businesses']:GetVehicleShopPlacements(Shop) or {})
    if Spot < 1 or Spot > Count or not FindVehicle(Shop, Model) then return Cb(Result('Invalid spot or vehicle.')) end

    TriggerEvent('fw-businesses:Server:ChangeVehicle', Shop, Spot - 1, Model)
    Cb(Result('Showroom updated.', true, Business, Shop))
end)

-- Takes one from stock (same as a PDM test drive), returns where to spawn it.
FW.Functions.CreateCallback('fw-bennys:Server:Dealership:PullOut', function(Source, Cb, Business, Model)
    local Shop = GetShop(Source, Business)
    local Vehicle = Shop and FindVehicle(Shop, Model)
    if not Vehicle or Vehicle.Stock < 1 then return Cb(false) end

    PulledOut[Source] = { Shop = Shop, Model = Model }
    TriggerEvent('fw-businesses:Server:VehicleShop:TestDrive', Shop, Model, false)
    Cb(exports['fw-config']:GetModuleConfig('bus-vehicleshop').ShopData[Shop].TestPos)
end)

FW.Functions.CreateCallback('fw-bennys:Server:Dealership:Return', function(Source, Cb, Business)
    local Out = PulledOut[Source]
    if Out then
        PulledOut[Source] = nil
        TriggerEvent('fw-businesses:Server:VehicleShop:TestDrive', Out.Shop, Out.Model, true)
        if Registers[Business] and Registers[Business].Seller == Source then SetOrder(Business, nil) end
    end
    Cb(Out ~= nil)
end)

-- The pulled-out car goes on the cash register: price + taxes, the customer pays there.
FW.Functions.CreateCallback('fw-bennys:Server:Dealership:SendRegister', function(Source, Cb, Business, Price, Comment, NetId)
    local Shop = GetShop(Source, Business)
    if not Shop then return Cb({ Denied = true }) end
    local Out = PulledOut[Source]
    if not Out or Out.Shop ~= Shop then return Cb(Result('Pull out a vehicle first.')) end
    if Registers[Business] then return Cb(Result('The register already has an open order.')) end
    Price = math.floor(tonumber(Price) or 0)
    if Price < 1 or Price > 100000000 then return Cb(Result('Invalid price.')) end

    local Taxes, Total = GetTaxes(Price)
    SetOrder(Business, {
        Seller = Source, Shop = Shop, Model = Out.Model, Name = FindVehicle(Shop, Out.Model).Name, Price = Price, Taxes = Taxes, Total = Total,
        Comment = tostring(Comment or ''):sub(1, 60), NetId = tonumber(NetId),
    })
    Cb(Result('Sent to the cash register.', true, Business, Shop))
end)

FW.Functions.CreateCallback('fw-bennys:Server:Dealership:CancelRegister', function(Source, Cb, Business)
    local Shop = GetShop(Source, Business)
    if not Shop then return Cb({ Denied = true }) end
    if not Registers[Business] then return Cb(Result('No open order.')) end
    SetOrder(Business, nil)
    Cb(Result('Order cancelled.', true, Business, Shop))
end)

-- ── Cash register (customer) ───────────────────────────────────────────────

RegisterNetEvent('fw-bennys:Server:Dealership:Pay', function(Data)
    local Source = source
    local Business = type(Data) == 'table' and Data.Business
    local Order = Business and Registers[Business]
    local Player = FW.Functions.GetPlayer(Source)
    if not Order or not Player then return end
    local Area = Config.Orders.Businesses[Business].Area
    if #(GetEntityCoords(GetPlayerPed(Source)) - Area.Center) > Area.Radius then return end
    if not FW.Functions.GetPlayer(Order.Seller) then
        SetOrder(Business, nil)
        return Player.Functions.Notify("This order is no longer valid.", "error")
    end

    local Account = DB:executeSync("SELECT `business_account` FROM `phone_businesses` WHERE `business_name` = ?", { Business })[1]
    Account = Account and Account.business_account
    if not Account then return end

    local Label = ('%s: %s'):format(Order.Name, Order.Comment)
    local Paid = Data.PaymentType == 'Cash' and Player.Functions.RemoveMoney('cash', Order.Total)
        or Data.PaymentType == 'Bank' and exports['fw-financials']:RemoveMoneyFromAccount(Player.PlayerData.citizenid, Account, Player.PlayerData.charinfo.account, Order.Total, 'PURCHASE', 'Betaling zakelijke dienstverlening: ' .. Label, false)
    if not Paid then return Player.Functions.Notify("You don't have enough money..", "error") end

    SetOrder(Business, nil)
    PulledOut[Order.Seller] = nil

    exports['fw-financials']:AddMoneyToAccount(Player.PlayerData.citizenid, Player.PlayerData.charinfo.account, Account, Order.Price, 'PURCHASE', 'Betaling zakelijke dienstverlening: ' .. Label, false)
    for _, Tax in ipairs(Order.Taxes) do
        if Tax.Amount > 0 then exports['fw-financials']:AddMoneyToAccount('1001', '1', '1', Tax.Amount, 'TAX', ('%s. (%s: %s)'):format(Tax.Label, Business, Order.Name), false) end
    end

    exports['fw-businesses']:RegisterSoldVehicle(Source, Order.Seller, Order.Shop, Order.Model, Order.Price, Order.NetId)
    Player.Functions.Notify(("Paid $%s, enjoy your %s!"):format(Order.Total, Order.Name), "success")
    TriggerClientEvent('FW:Notify', Order.Seller, ("%s paid at the register."):format(Order.Name), "success")
end)

-- Sold through the phone (fw-businesses sale flow): the vehicle can't be returned to stock anymore.
RegisterNetEvent('fw-businesses:Server:VehicleShop:Purchase', function(Data)
    if type(Data) == 'table' and Data.Seller then PulledOut[Data.Seller] = nil end
end)

AddEventHandler('playerDropped', function()
    local Source = source
    PulledOut[Source] = nil
    for Business, Order in pairs(Registers) do
        if Order.Seller == Source then SetOrder(Business, nil) end
    end
end)
