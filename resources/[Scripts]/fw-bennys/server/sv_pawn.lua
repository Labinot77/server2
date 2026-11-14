-- Pawn shop logistics (config/sh_pawn.lua). Offer -> accept (fee, items checked in the Safe) -> fulfill (items
-- packed into boxes in the Drop-off storage) -> begin delivery -> runners deliver boxes -> cash out.
FW = FW or exports['fw-core']:GetCoreObject()

local DB, INV = exports['ghmattimysql'], exports['fw-inventory']
local P = Config.Pawn
local Key = P.Business:gsub('%W', ''):lower()
local SAFE, DROP = 'pawn_safe_' .. Key, 'pawn_dropoff_' .. Key

local Offers, Orders, OfferId = {}, {}, 0 -- Orders = accepted orders + shipments (pawn_orders)
local CategoryKeys, RouteKeys, Labels = {}, {}, {} -- Labels: config label per item (safe list)
for K, Cat in pairs(P.Categories) do
    CategoryKeys[#CategoryKeys + 1] = K
    for _, Def in ipairs(Cat.Items) do Labels[Def.Item] = Def.Label end
end
for K in pairs(P.Routes) do RouteKeys[#RouteKeys + 1] = K end
table.sort(CategoryKeys)
table.sort(RouteKeys)

local function Rand(R) return math.random(R[1], R[2]) end
local function Fail(Message) return { Success = false, Message = Message } end
local function Token(Id) return ('#%d#'):format(Id) end -- in a box's info, marks its shipment

local function Image(Item)
    local Data = INV:GetItemData(Item)
    return Data and Data.Image
end

-- ── Safe ───────────────────────────────────────────────────────────────────

local function SafeCounts()
    local Counts = {}
    for _, Row in ipairs(DB:executeSync("SELECT `item_name`, COUNT(*) AS `amount` FROM `player_inventories` WHERE `inventory` = ? GROUP BY `item_name`", { SAFE }) or {}) do
        Counts[Row.item_name] = tonumber(Row.amount)
    end
    return Counts
end

local function IsReady(Order, Counts)
    for _, Line in ipairs(Order.Items) do
        if (Counts[Line.Item] or 0) < Line.Need then return false end
    end
    return true
end

local function RemoveBoxes(Id)
    DB:executeSync("DELETE FROM `player_inventories` WHERE `inventory` = ? AND `item_name` = ? AND `info` LIKE ?", { DROP, P.BoxItem, '%' .. Token(Id) .. '%' })
end

-- ── Offers ─────────────────────────────────────────────────────────────────

local function NewOffer()
    local Category = CategoryKeys[math.random(#CategoryKeys)]
    local RouteKey = RouteKeys[math.random(#RouteKeys)]
    local Cat, Route = P.Categories[Category], P.Routes[RouteKey]

    local Pool, Items, Payout, Criminal = { table.unpack(Cat.Items) }, {}, 0, false
    for _ = 1, math.min(#Pool, Rand(Cat.Lines)) do
        local Def = table.remove(Pool, math.random(#Pool))
        local Line = { Item = Def.Item, Label = Def.Label, Image = Image(Def.Item), Need = Rand(Def.Need), Price = math.floor(Rand(Def.Price) * Route.Multiplier) }
        Payout = Payout + Line.Need * Line.Price
        Criminal = Criminal or Def.Illegal == true
        Items[#Items + 1] = Line
    end

    OfferId = OfferId + 1
    return {
        Id = OfferId, Category = Category, Label = Cat.Label, Tag = Cat.Tag, Route = RouteKey, Criminal = Criminal,
        Items = Items, Payout = Payout, Fee = math.floor(Payout * P.Offers.Fee), Expires = os.time() + Rand(P.Offers.Lifetime) * 60,
    }
end

local function RefillOffers()
    local Count = 0
    for Id, Offer in pairs(Offers) do
        if Offer.Expires <= os.time() then Offers[Id] = nil else Count = Count + 1 end
    end
    for _ = Count + 1, P.Offers.Count do
        local Offer = NewOffer()
        Offers[Offer.Id] = Offer
    end
end

-- ── Orders (database) ──────────────────────────────────────────────────────

local function Encode(Order)
    local Data = {}
    for K, V in pairs(Order) do
        if K ~= 'Id' and K ~= 'Status' then Data[K] = V end
    end
    return json.encode(Data)
end

local function Save(Order)
    Order.UpdatedAt = os.time()
    DB:execute("UPDATE `pawn_orders` SET `status` = ?, `data` = ?, `updated_at` = ? WHERE `id` = ?", { Order.Status, Encode(Order), Order.UpdatedAt, Order.Id })
end

local function Insert(Order)
    Order.CreatedAt, Order.UpdatedAt = os.time(), os.time()
    local Result = DB:executeSync("INSERT INTO `pawn_orders` (`business`, `status`, `data`, `created_at`, `updated_at`) VALUES (?, ?, ?, ?, ?)", { P.Business, Order.Status, Encode(Order), Order.CreatedAt, Order.UpdatedAt })
    Order.Id = type(Result) == 'table' and (Result.insertId or Result[1] and Result[1].insertId) or Result
    if Order.Id then Orders[Order.Id] = Order end
    return Order.Id
end

-- Drop-offs of shipments on the road, for the runners' delivery prompts.
local function Dropoffs()
    local List = {}
    for _, Order in pairs(Orders) do
        if Order.Status == 'transit' then List[#List + 1] = { Id = Order.Id, Label = Order.Dropoff.Label, Coords = Order.Dropoff.Coords } end
    end
    return List
end

-- Everyone: drop-off prompts; open Pawn apps reload their view.
local function Changed()
    TriggerClientEvent('fw-bennys:Client:Pawn:Changed', -1, Dropoffs())
end

local function Stats()
    local S = { Completed = 0, Cancelled = 0, Boxes = 0, Revenue = 0, Fees = 0, Open = 0 }
    for _, Order in pairs(Orders) do
        S.Fees = S.Fees + (Order.Fee or 0)
        S.Boxes = S.Boxes + (Order.Delivered or 0)
        S.Revenue = S.Revenue + (Order.Paid or 0)
        if Order.Status == 'completed' then S.Completed = S.Completed + 1
        elseif Order.Status == 'cancelled' or Order.Status == 'expired' then S.Cancelled = S.Cancelled + 1
        else S.Open = S.Open + 1 end
    end
    return S
end

local function BuildView()
    RefillOffers()
    local Counts, Wanted = SafeCounts(), {}
    local View = { Offers = {}, Active = {}, Shipments = {}, Safe = { Items = {}, Total = 0, Wanted = 0 }, Stats = Stats(), Time = os.time(), Business = P.Business }

    for _, Offer in pairs(Offers) do
        Offer.Ready = IsReady(Offer, Counts)
        for _, Line in ipairs(Offer.Items) do Wanted[Line.Item] = true end
        View.Offers[#View.Offers + 1] = Offer
    end
    for _, Order in pairs(Orders) do
        if Order.Status == 'active' then
            Order.Ready = IsReady(Order, Counts)
            for _, Line in ipairs(Order.Items) do Wanted[Line.Item] = true end
            View.Active[#View.Active + 1] = Order
        elseif Order.Status == 'packed' or Order.Status == 'transit' then
            View.Shipments[#View.Shipments + 1] = Order
        end
    end
    for Item, Amount in pairs(Counts) do
        local Data = INV:GetItemData(Item)
        View.Safe.Items[#View.Safe.Items + 1] = { Item = Item, Label = Labels[Item] or Data and Data.Label or Item, Image = Data and Data.Image, Amount = Amount, Wanted = Wanted[Item] == true }
        View.Safe.Total = View.Safe.Total + Amount
        if Wanted[Item] then View.Safe.Wanted = View.Safe.Wanted + Amount end
    end

    local ById = function(A, B) return A.Id < B.Id end
    table.sort(View.Offers, function(A, B) return A.Expires < B.Expires end)
    table.sort(View.Active, ById)
    table.sort(View.Shipments, ById)
    table.sort(View.Safe.Items, function(A, B) return A.Amount > B.Amount end)
    return View
end

-- ── Business account ───────────────────────────────────────────────────────

local function Account()
    local Row = DB:executeSync("SELECT `business_account` FROM `phone_businesses` WHERE `business_name` = ?", { P.Business })[1]
    return Row and Row.business_account ~= '' and Row.business_account or nil
end

-- ── Actions (Pawn app) ─────────────────────────────────────────────────────

local Actions = {}

function Actions.accept(Player, Data)
    local Offer = Offers[tonumber(Data.Id)]
    if not Offer or Offer.Expires <= os.time() then return Fail('This offer is no longer available') end
    if not IsReady(Offer, SafeCounts()) then return Fail('The safe is missing items for this order') end

    local Acc, Cid = Account(), Player.PlayerData.citizenid
    if not Acc or not exports['fw-financials']:RemoveMoneyFromAccount(Cid, Acc, Acc, Offer.Fee, 'WITHDRAW', ('Pawn order fee: %s'):format(Offer.Label), false) then
        return Fail('Not enough money on the business account for the accept fee')
    end

    Offers[Offer.Id] = nil
    local Order = {
        Status = 'active', Category = Offer.Category, Label = Offer.Label, Tag = Offer.Tag, Route = Offer.Route, Criminal = Offer.Criminal,
        Items = Offer.Items, Payout = Offer.Payout, Fee = Offer.Fee, AcceptedBy = ('%s %s'):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname),
    }
    if not Insert(Order) then return Fail('The order could not be saved') end
    return { Success = true, Message = 'Order accepted' }
end

-- Takes the items out of the safe and packs one box per item line into the drop-off storage.
function Actions.fulfill(Player, Data)
    local Order = Orders[tonumber(Data.Id)]
    if not Order or Order.Status ~= 'active' then return Fail('Order not found') end
    if not IsReady(Order, SafeCounts()) then return Fail('The safe is missing items for this order') end

    local Used = DB:executeSync("SELECT COUNT(DISTINCT `slot`) AS `slots` FROM `player_inventories` WHERE `inventory` = ?", { DROP })[1]
    if (tonumber(Used and Used.slots) or 0) + #Order.Items > P.DropOff.Slots then return Fail('The drop-off storage is full') end

    for _, Line in ipairs(Order.Items) do
        INV:RemoveItemFromInventoryByName(SAFE, Line.Item, Line.Need)
    end
    for I, Line in ipairs(Order.Items) do
        INV:AddItemToInventory(DROP, P.BoxItem, 1, nil, {
            Shipment = Token(Order.Id), Box = ('%d/%d'):format(I, #Order.Items), Contents = ('%dx %s'):format(Line.Need, Line.Label), Order = Order.Label,
        })
    end

    Order.Status, Order.Boxes, Order.Delivered, Order.CashedOut, Order.Paid = 'packed', #Order.Items, 0, 0, 0
    Order.Expires = os.time() + P.Routes[Order.Route].Packed * 60
    return { Success = true, Message = ('%d box(es) packed in the drop-off storage'):format(Order.Boxes) }
end

function Actions.deliver(_, Data)
    local Order = Orders[tonumber(Data.Id)]
    if not Order or Order.Status ~= 'packed' then return Fail('Shipment not found') end

    local Route = P.Routes[Order.Route]
    local Spot = Route.Dropoffs[math.random(#Route.Dropoffs)]
    Order.Status, Order.Dropoff = 'transit', { Label = Spot.Label, Coords = { x = Spot.Coords.x, y = Spot.Coords.y, z = Spot.Coords.z } }
    Order.Expires = os.time() + Route.Transit * 60
    return { Success = true, Message = ('Delivery started: %s'):format(Spot.Label) }
end

function Actions.cashout(Player, Data)
    local Order = Orders[tonumber(Data.Id)]
    if not Order or Order.Status ~= 'transit' then return Fail('Shipment not found') end
    if Order.Delivered <= Order.CashedOut then return Fail('No delivered boxes to cash out') end

    local Amount = Order.Delivered == Order.Boxes and Order.Payout - Order.Paid or math.floor(Order.Payout * (Order.Delivered - Order.CashedOut) / Order.Boxes)
    local Acc = Account()
    if not Acc or not exports['fw-financials']:AddMoneyToAccount(Player.PlayerData.citizenid, Acc, Acc, Amount, 'DEPOSIT', ('Pawn shipment #%d: %s'):format(Order.Id, Order.Label), false) then
        return Fail('The business account could not be paid')
    end

    Order.Paid, Order.CashedOut = Order.Paid + Amount, Order.Delivered
    if Order.Delivered == Order.Boxes then Order.Status = 'completed' end
    return { Success = true, Message = ('$%d paid to the business account'):format(Amount) }
end

function Actions.cancel(_, Data)
    local Order = Orders[tonumber(Data.Id)]
    if not Order or (Order.Status ~= 'active' and Order.Status ~= 'packed' and Order.Status ~= 'transit') then return Fail('Order not found') end
    RemoveBoxes(Order.Id) -- boxes runners still carry are worthless now
    Order.Status = 'cancelled'
    return { Success = true, Message = 'Order cancelled' }
end

local function GetAccess(Source)
    return GetBusinessAccess(Source, P.Business)
end

FW.Functions.CreateCallback('fw-bennys:Server:Pawn:View', function(Source, Cb)
    if not GetAccess(Source) then return Cb(false) end
    Cb(BuildView())
end)

FW.Functions.CreateCallback('fw-bennys:Server:Pawn:Action', function(Source, Cb, Action, Data)
    local Player, Handler = FW.Functions.GetPlayer(Source), Actions[Action]
    if not Player or not Handler or not GetAccess(Source) then return Cb(Fail('No access')) end
    if #(GetEntityCoords(GetPlayerPed(Source)) - P.Monitor.Coords) > 6.0 then return Cb(Fail('You are too far from the computer')) end

    local Order = Action ~= 'accept' and type(Data) == 'table' and Orders[tonumber(Data.Id)]
    local Result = Handler(Player, type(Data) == 'table' and Data or {})
    if Result.Success then
        if Order then Save(Order) end
        TriggerEvent('fw-logs:Server:Log', 'bennysMenu', 'Pawn ' .. Action, ('User: [%s] %s\nId: %s\n%s'):format(Source, Player.PlayerData.citizenid, tostring(Data and Data.Id), Result.Message or ''), 'green')
        Changed()
    end
    Cb(Result)
end)

-- Safe needs StashAccess, the drop-off storage is open to every member.
FW.Functions.CreateCallback('fw-bennys:Server:Pawn:Storage', function(Source, Cb, Which)
    local Access = GetAccess(Source)
    local Storage = Which == 'Safe' and P.Safe or P.DropOff
    if not Access or (Which == 'Safe' and not Access.Perms.StashAccess) then return Cb(false) end
    if #(GetEntityCoords(GetPlayerPed(Source)) - Storage.Coords) > 3.0 then return Cb(false) end
    Cb({ Name = Which == 'Safe' and SAFE or DROP, Slots = Storage.Slots, Weight = Storage.Weight })
end)

-- ── Runner: deliver a box at the drop-off ──────────────────────────────────

FW.Functions.CreateCallback('fw-bennys:Server:Pawn:DeliverBox', function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return Cb(Fail('')) end
    local Coords, Inv = GetEntityCoords(GetPlayerPed(Source)), 'ply-' .. Player.PlayerData.citizenid

    for _, Order in pairs(Orders) do
        local D = Order.Status == 'transit' and Order.Dropoff.Coords
        if D and #(Coords - vector3(D.x, D.y, D.z)) < 10.0 then
            local Row = DB:executeSync("SELECT `slot` FROM `player_inventories` WHERE `inventory` = ? AND `item_name` = ? AND `info` LIKE ? LIMIT 1", { Inv, P.BoxItem, '%' .. Token(Order.Id) .. '%' })[1]
            if Row and INV:RemoveItemFromInventory(Inv, P.BoxItem, 1, Row.slot) then
                Order.Delivered = Order.Delivered + 1
                Save(Order)
                Player.Functions.AddMoney('cash', P.Runner.PerBox, 'pawn-delivery')
                Changed()
                return Cb({ Success = true, Message = ('Box delivered (%d/%d), +$%d'):format(Order.Delivered, Order.Boxes, P.Runner.PerBox), Alert = Order.Criminal and math.random() < P.AlertChance })
            end
        end
    end
    Cb(Fail("You don't carry a box for this drop-off"))
end)

FW.Functions.CreateCallback('fw-bennys:Server:Pawn:Dropoffs', function(_, Cb) Cb(Dropoffs()) end)

-- ── Startup + expiry ───────────────────────────────────────────────────────

CreateThread(function()
    DB:executeSync([[
        CREATE TABLE IF NOT EXISTS `pawn_orders` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `business` VARCHAR(64) NOT NULL,
            `status` VARCHAR(16) NOT NULL,
            `data` LONGTEXT NOT NULL,
            `created_at` INT NOT NULL,
            `updated_at` INT NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `business_status` (`business`, `status`)
        )
    ]])

    -- Open orders + the last 30 days (stats).
    for _, Row in ipairs(DB:executeSync("SELECT * FROM `pawn_orders` WHERE `business` = ? AND (`status` IN ('active', 'packed', 'transit') OR `updated_at` > ?)", { P.Business, os.time() - 2592000 }) or {}) do
        local Order = json.decode(Row.data) or {}
        Order.Id, Order.Status = Row.id, Row.status
        Orders[Row.id] = Order
    end

    -- Business + bank account (like Mosley's), when missing.
    local Biz = Config.Orders.Businesses[P.Business]
    if Biz and Biz.Account and not DB:executeSync("SELECT 1 FROM `phone_businesses` WHERE `business_name` = ?", { P.Business })[1] then
        DB:executeSync("INSERT INTO `phone_businesses` (`business_owner`, `business_name`, `business_account`, `business_employees`, `business_ranks`) VALUES ('1001', ?, ?, '[]', '[]')", { P.Business, Biz.Account })
        DB:executeSync("INSERT INTO `player_financials` (`citizenid`, `name`, `accountid`, `balance`, `type`, `authorized`, `active`, `monitored`) VALUES ('1001', ?, ?, 0, 'Bedrijfsrekening', '[]', 1, 0)", { P.Business, Biz.Account })
        print(('[fw-bennys] Created business %s'):format(P.Business))
    end

    RefillOffers()
    Changed()

    while true do
        Wait(60000)
        local Expired = false
        for _, Order in pairs(Orders) do
            if (Order.Status == 'packed' or Order.Status == 'transit') and Order.Expires and Order.Expires <= os.time() then
                RemoveBoxes(Order.Id)
                Order.Status, Expired = 'expired', true
                Save(Order)
            end
        end
        RefillOffers()
        if Expired then Changed() end
    end
end)
