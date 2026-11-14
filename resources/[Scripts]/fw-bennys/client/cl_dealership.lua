-- Dealership app on the business computer (html/dealership.html): pick the showroom cars, pull a vehicle
-- out of stock and sell it (fw-businesses sale flow: the buyer accepts on their phone). Checks: server/sv_dealership.lua.

local DUI = exports['fw-dui']
local APP = Config.Laptop.Apps.Dealership.id
local Current = nil -- pulled-out vehicle { Business, Shop, Model, Entity }

local function Send(Action, Data, MirrorData) DUI:SendApp(LAPTOP_SCREEN, APP, Action, Data, MirrorData) end

local function Toast(Text, Ok)
    Send('toast', { text = Text, type = Ok and 'success' or 'error' })
    PlaySoundFrontend(-1, Ok and 'SELECT' or 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

local function GetShop(Business) return Config.Orders.Businesses[Business] and Config.Orders.Businesses[Business].Shop end

local function Push(View)
    if not View or View.Denied then return Send('lock', { text = "You don't have access to this app" }) end
    View.Current = Current and Current.Model or false
    Send('view', View)
end

-- ── Shown by cl_laptop.lua ─────────────────────────────────────────────────

function DealershipLock()
    Send('lock', {}, false)
end

function DealershipLoad(Business)
    if not GetShop(Business) then return end
    CreateThread(function()
        local View = FW.SendCallback('fw-bennys:Server:Dealership:Get', Business)
        if GetLaptopBusiness() == Business then Push(View) end
    end)
end

-- ── Actions ────────────────────────────────────────────────────────────────

local function PullOut(Business, Model)
    if Current then return Toast('Sell or return the current vehicle first') end
    local Pos = FW.SendCallback('fw-bennys:Server:Dealership:PullOut', Business, Model)
    if not Pos then return Toast('Out of stock') end

    local Plate = 'MOSLEY' .. math.random(10, 99)
    local NetId = FW.SendCallback('FW:server:spawn:vehicle', Model, { x = Pos.x, y = Pos.y, z = Pos.z, a = Pos.w }, false, Plate)
    local Deadline = GetGameTimer() + 10000
    while not NetworkDoesEntityExistWithNetworkId(NetId) and GetGameTimer() < Deadline do Wait(100) end
    local Vehicle = NetToVeh(NetId)
    if not DoesEntityExist(Vehicle) then
        FW.SendCallback('fw-bennys:Server:Dealership:Return')
        return Toast("The vehicle couldn't be spawned")
    end

    Current = { Business = Business, Shop = GetShop(Business), Model = Model, Entity = Vehicle }
    TriggerServerEvent('fw-businesses:Server:AutoCare:LoadParts', Plate)
    exports['fw-vehicles']:SetVehicleKeys(Plate, true, false)
    exports['fw-vehicles']:SetFuelLevel(Vehicle, 100.0)
    FW.Functions.SetVehiclePlate(Vehicle, Plate)

    local Preset = FW.SendCallback('fw-businesses:Server:VehicleShop:GetPreset', Current.Shop, Model)
    if Preset and next(Preset) then FW.VSync.ApplyVehicleMods(Vehicle, Preset) end

    Toast('Vehicle is waiting outside', true)
    DealershipLoad(Business)
end

local function Return(Business)
    if not Current then return end
    FW.SendCallback('fw-bennys:Server:Dealership:Return', Business)
    if DoesEntityExist(Current.Entity) then FW.VSync.DeleteVehicle(Current.Entity) end
    Current = nil
    Toast('Vehicle returned to stock', true)
    DealershipLoad(Business)
end

-- Price + comment to the cash register, the customer pays there (taxes on top, see Config.Dealership).
local function Run(Business, Name, ...)
    local Result = FW.SendCallback('fw-bennys:Server:Dealership:' .. Name, Business, ...) or {}
    if Result.Message then Toast(Result.Message, Result.Success) end
    if Result.View or Result.Denied then Push(Result.View or Result) end
end

local function Sell(Business, Data)
    if not Current or not DoesEntityExist(Current.Entity) then return Toast('Pull out a vehicle first') end
    Run(Business, 'SendRegister', tonumber(Data.Price), Data.Comment, VehToNet(Current.Entity))
end

local function SetSpot(Business, Data) Run(Business, 'SetSpot', tonumber(Data.Spot), Data.Model) end

local Handlers = {
    refresh = DealershipLoad,
    sound = function() PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true) end,
    setSpot = SetSpot,
    pullOut = function(Business, Data) PullOut(Business, Data.Model) end,
    returnVehicle = Return,
    sell = Sell,
    cancelOrder = function(Business) Run(Business, 'CancelRegister') end,
}

RegisterNUICallback('dealership', function(Data, Cb)
    Cb('ok')
    local Business = GetLaptopBusiness()
    local Handler = Data and Handlers[Data.Action]
    if not Business or not Handler then return end -- watchers' copies of the page post too: ignored
    CreateThread(function() Handler(Business, Data) end)
end)

-- Sold: fw-businesses tells the seller the vehicle is gone.
RegisterNetEvent('fw-phone:Client:Cars:SetTestDrive', function(Data)
    if Data or not Current then return end
    local Business = Current.Business
    Current = nil
    if GetLaptopBusiness() == Business then DealershipLoad(Business) end
end)

-- ── Cash register (Config.Dealership.RegisterModel inside a dealership's Area) ──

local function GetRegisterBusiness(Entity)
    local Coords = GetEntityCoords(Entity)
    for Business, Data in pairs(Config.Orders.Businesses) do
        if Data.Shop and #(Coords - Data.Area.Center) <= Data.Area.Radius then return Business, Data.Shop end
    end
end

local function GetOrder(Entity)
    local Business, Shop = GetRegisterBusiness(Entity)
    return Business, Business and GlobalState['dealership_register_' .. Shop]
end

CreateThread(function()
    while GetResourceState('interact') ~= 'started' do Wait(500) end
    exports['interact']:AddModelInteraction({
        modelData = { { model = Config.Dealership.RegisterModel, offset = vec3(0.0, 0.0, 0.2) } },
        distance = 3.0,
        interactDst = 1.5,
        name = 'dealership_register',
        options = {
            {
                name = 'dealership_register_pay',
                label = 'Pay Vehicle',
                canInteract = function(Entity) return select(2, GetOrder(Entity)) ~= nil end,
                action = function(Entity)
                    local Business, Order = GetOrder(Entity)
                    if not Order then return end
                    FW.Functions.OpenMenu({ MainMenuItems = {
                        { Icon = 'info-circle', Title = Order.Name, Desc = ('$%s incl. tax | %s'):format(Order.Total, Order.Comment), Data = { Event = '', Type = '' } },
                        { Icon = 'credit-card', Title = 'Pay with Bank', CloseMenu = true, Data = { Event = 'fw-bennys:Server:Dealership:Pay', Type = 'Server', PaymentType = 'Bank', Business = Business } },
                        { Icon = 'money-bill', Title = 'Pay with Cash', CloseMenu = true, Data = { Event = 'fw-bennys:Server:Dealership:Pay', Type = 'Server', PaymentType = 'Cash', Business = Business } },
                    } })
                end,
            },
        },
    })
end)
