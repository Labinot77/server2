-- Work-order laptop. fw-dui shows laptop.html on the nearest placed laptop (range, texture, camera, cursor);
-- this file fills it with the live dashboard of the laptop's business (everyone nearby sees it).
-- Mirror: players nearby also see what the user does on it.
-- Laptops are fw-admin placed props inside a business Area (server/sv_orders.lua -> LoadLaptops).
FW = FW or exports['fw-core']:GetCoreObject()

local SCREEN = 'bennys_laptop'
local DUI = exports['fw-dui']

local Laptop = { Open = false, Entity = nil, Business = nil, Shown = nil, ShownBusiness = nil, Preview = false }
local Laptops = {} -- [placed prop id] = { Id, Model, Coords, Business }
local ViewOrders = {} -- [Business] = orders, for players who aren't members

local function Send(Action, Data) DUI:Send(SCREEN, Action, Data) end

local function GetLaptopForEntity(Entity)
    local Id = GetResourceState('fw-admin') == 'started' and exports['fw-admin']:GetPropIdByEntity(Entity)
    return Id and Laptops[Id]
end

-- Dashboard header + cached orders of Business, then fresh ones from the server.
local function ShowDashboard(Business)
    local PlayerData = FW.Functions.GetPlayerData()
    Send('init', {
        resource = GetCurrentResourceName(),
        business = Business,
        label = Config.Orders.Businesses[Business] and Config.Orders.Businesses[Business].Label or Business,
        me = { cid = PlayerData.citizenid, name = ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname) },
    })
    Send('orders', OrdersByBusiness[Business] or ViewOrders[Business] or {})

    CreateThread(function()
        local List = FW.SendCallback('fw-bennys:Server:Orders:View', Business)
        if List then
            ViewOrders[Business] = List
            if Laptop.ShownBusiness == Business then Send('orders', List) end
        end
    end)
end

-- What a laptop shows while nobody uses it: the live dashboard (locked screen if it isn't in a business Area).
local function ShowIdle(Entity)
    local Entry = GetLaptopForEntity(Entity)
    Laptop.Shown, Laptop.ShownBusiness = Entity, Entry and Entry.Business
    if Entry then return ShowDashboard(Entry.Business) end
    Send('idle', { text = 'Locked' })
end

-- ── Session ────────────────────────────────────────────────────────────────

function CloseLaptop()
    if not Laptop.Open then return end
    Laptop.Open = false

    Send('close')
    DUI:StopFocus()
    DUI:Release(SCREEN) -- the dashboard stays on screen, the range check takes over
    ClearPedTasks(PlayerPedId())
    Laptop.Entity, Laptop.Business = nil, nil
end

function OpenLaptop(Entity, Business)
    if Laptop.Open or not DoesEntityExist(Entity) then return end
    Laptop.Open, Laptop.Entity, Laptop.Business, Laptop.Preview = true, Entity, Business, false

    local Ped = PlayerPedId()
    TaskTurnPedToFaceEntity(Ped, Entity, 600)

    if not DUI:Show(SCREEN, Entity) then
        Laptop.Open = false
        return FW.Functions.Notify("Laptop kon niet worden geladen..", "error")
    end
    if Laptop.Shown ~= Entity or Laptop.ShownBusiness ~= Business then
        Laptop.Shown, Laptop.ShownBusiness = Entity, Business
        ShowDashboard(Business)
    end

    Wait(600)
    if not Laptop.Open then return end
    exports['fw-assets']:RequestAnimationDict('anim@heists@prison_heiststation@cop_reactions')
    TaskPlayAnim(Ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0, false, false, false)

    DUI:Focus(SCREEN, { Mouse = true, Sensitivity = Config.Laptop.CursorSensitivity })
end

-- ── fw-dui ─────────────────────────────────────────────────────────────────

local function RegisterScreen()
    local Models = {}
    for Model in pairs(Config.Laptop.Models) do Models[#Models + 1] = Model end
    DUI:RegisterScreen(SCREEN, {
        Url = ('nui://%s/html/laptop.html'):format(GetCurrentResourceName()),
        Models = Models,
        Distance = Config.Laptop.RenderDistance,
        Placed = true,
        Mirror = true,
    })
end

AddEventHandler('fw-dui:Client:Shown', function(Name, Entity)
    if Name ~= SCREEN or Laptop.Open then return end
    ShowIdle(Entity)
end)

AddEventHandler('fw-dui:Client:Hidden', function(Name)
    if Name == SCREEN then Laptop.Shown, Laptop.ShownBusiness = nil, nil end
end)

AddEventHandler('fw-dui:Client:Closed', function(Name)
    if Name == SCREEN then CloseLaptop() end
end)

-- Stopped watching another player on a laptop: reset to the dashboard.
AddEventHandler('fw-dui:Client:WatchEnded', function(Name, Entity)
    if Name == SCREEN and not Laptop.Open and DoesEntityExist(Entity) then ShowIdle(Entity) end
end)

AddEventHandler('onClientResourceStart', function(Resource)
    if Resource == 'fw-dui' then RegisterScreen() end
end)

CreateThread(function()
    if GetResourceState('fw-dui') == 'started' then RegisterScreen() end
end)

-- Live updates for whatever the screen shows (members via cl_orders.lua, everyone else via Laptop:View).
-- Not mirrored: every watcher gets the same list from the server.
AddEventHandler('fw-bennys:Client:Laptop:Orders', function(Business, List)
    if Laptop.ShownBusiness == Business then DUI:Send(SCREEN, 'orders', List, false) end
end)

RegisterNetEvent('fw-bennys:Client:Laptop:View', function(Business, List)
    ViewOrders[Business] = List
    if Laptop.ShownBusiness == Business then DUI:Send(SCREEN, 'orders', List, false) end
end)

-- ── Page -> client ─────────────────────────────────────────────────────────

RegisterNUICallback('laptop', function(Data, Cb)
    local Action = Data and Data.Action
    if Action == 'close' then
        Cb('ok')
        return CloseLaptop()
    end

    if not Laptop.Open then return Cb('ok') end
    local Business = Laptop.Business

    if Action == 'refresh' then
        local List = FW.SendCallback('fw-bennys:Server:Orders:Get', Business)
        if List then
            OrdersByBusiness[Business] = List
            Send('orders', List)
        end
        return Cb('ok')
    end

    if Action == 'accept' or Action == 'release' or Action == 'decline' or Action == 'complete' then
        local Result = FW.SendCallback('fw-bennys:Server:Orders:Action', Action, Data.Id)
        if Result and Result.Success then
            local Messages = { accept = 'Order geaccepteerd', release = 'Order vrijgegeven', decline = 'Order geannuleerd', complete = 'Order afgerond' }
            Send('toast', { text = Messages[Action], type = 'success' })
            PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            Send('toast', { text = Result and Result.Message or 'Er ging iets mis', type = 'error' })
            PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        end
        return Cb('ok')
    end

    if Action == 'locate' then
        local Order = GetOrderById(Data.Id)
        local Vehicle = Order and FindOrderVehicle(Order.NetId, Order.Plate)
        if Vehicle then
            local Coords = GetEntityCoords(Vehicle)
            SetNewWaypoint(Coords.x, Coords.y)
            Send('toast', { text = 'Waypoint gezet naar het voertuig', type = 'success' })
        else
            Send('toast', { text = 'Voertuig niet in de buurt', type = 'error' })
        end
        return Cb('ok')
    end

    if Action == 'sound' then
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end

    Cb('ok')
end)

-- ── Interact on the laptop props ───────────────────────────────────────────

local Registered = {} -- [Model] = true (interact's AddModelInteraction appends, so register once)

local function SetLaptops(List)
    Laptops = {}
    for _, Entry in ipairs(List or {}) do
        Laptops[Entry.Id] = {
            Id = Entry.Id,
            Model = Entry.Model,
            Business = Entry.Business,
            Coords = vector3(Entry.Coords.x, Entry.Coords.y, Entry.Coords.z),
        }
    end
end

RegisterNetEvent('fw-bennys:Client:Laptop:SetLaptops', SetLaptops)

-- Why the prompt is (not) shown, as a reason string; nil = can interact.
function LaptopBlockReason(Entity)
    if Laptop.Open then return 'laptop already open' end
    local Entry = GetLaptopForEntity(Entity)
    if not Entry then return 'not a placed laptop (admin panel) inside a business Area' end
    if not IsOrderMechanic(Entry.Business) then return 'not a member of ' .. Entry.Business .. ' (client cache)' end
    return nil
end

function LaptopCanInteract(Entity)
    return LaptopBlockReason(Entity) == nil
end

local function RegisterInteractions()
    if GetResourceState('interact') ~= 'started' then return end

    for Model in pairs(Config.Laptop.Models) do
        if not Registered[Model] then
            if not IsModelValid(joaat(Model)) then
                print(('[fw-bennys] Laptop model %s is not valid (not streamed?), skipping interaction'):format(Model))
            else
                Registered[Model] = true
                exports['interact']:AddModelInteraction({
                    modelData = { { model = Model, offset = vec3(0.0, 0.0, 0.15) } },
                    distance = 3.0,
                    interactDst = 1.4,
                    name = 'bennys_laptop_' .. Model,
                    options = {
                        {
                            name = 'bennys_laptop_orders',
                            label = 'Work Orders',
                            canInteract = function(Entity) return LaptopCanInteract(Entity) end,
                            action = function(Entity)
                                local Entry = GetLaptopForEntity(Entity)
                                if Entry then CreateThread(function() OpenLaptop(Entity, Entry.Business) end) end
                            end,
                        },
                    },
                })
            end
        end
    end
end

CreateThread(function()
    while GetResourceState('interact') ~= 'started' do Wait(500) end
    while not FW.Functions.GetPlayerData() or not FW.Functions.GetPlayerData().citizenid do Wait(1000) end
    RegisterInteractions()
    SetLaptops(FW.SendCallback('fw-bennys:Server:Laptop:GetLaptops', false))
end)

local function FindNearestLaptop(Radius)
    local Coords = GetEntityCoords(PlayerPedId())
    for Model in pairs(Config.Laptop.Models) do
        local Entity = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, Radius, joaat(Model), false, false, false)
        if Entity ~= 0 then return Entity, Model end
    end
end

-- ── /workorders: open the nearest laptop without interact (fallback + testing) ──

RegisterCommand('workorders', function()
    local Entity = FindNearestLaptop(2.5)
    if not Entity then return FW.Functions.Notify("Geen laptop in de buurt..", "error") end

    local Reason = LaptopBlockReason(Entity)
    if Reason then return FW.Functions.Notify("Laptop: " .. Reason, "error") end
    CreateThread(function() OpenLaptop(Entity, GetLaptopForEntity(Entity).Business) end)
end)

-- ── Debug: /bennysdebug explains why the laptop prompt does or doesn't show ───

RegisterCommand('bennysdebug', function()
    CreateThread(function()
        local Lines = {}
        local function Add(Text, ...) Lines[#Lines + 1] = Text:format(...) end

        SetLaptops(FW.SendCallback('fw-bennys:Server:Laptop:GetLaptops', true) or {})
        local Mine = FW.SendCallback('fw-bennys:Server:Orders:GetMyBusinesses') or {}
        local Cid, Cached = GetOrderMechanicState()

        Add('interact: %s | fw-dui: %s | fw-admin: %s', GetResourceState('interact'), GetResourceState('fw-dui'), GetResourceState('fw-admin'))
        Add('client cache: cid=%s businesses=%s', tostring(Cid), #Cached > 0 and table.concat(Cached, ', ') or 'EMPTY')
        Add('my order businesses: %s', #Mine > 0 and table.concat(Mine, ', ') or 'NONE (not owner/employee in phone_businesses)')
        for _, Entry in pairs(Laptops) do
            Add('  placed prop #%s %s @ %.2f, %.2f, %.2f -> %s', Entry.Id, Entry.Model, Entry.Coords.x, Entry.Coords.y, Entry.Coords.z, Entry.Business)
        end
        for Model in pairs(Config.Laptop.Models) do
            Add('model %s: valid=%s registered=%s', Model, tostring(IsModelValid(joaat(Model))), tostring(Registered[Model] == true))
        end

        local Entity = FindNearestLaptop(10.0)
        if Entity then
            Add('nearest laptop: entity %d, prop id %s, on screen: %s', Entity, tostring(exports['fw-admin']:GetPropIdByEntity(Entity)), tostring(DUI:GetEntity(SCREEN) == Entity))
            Add('  prompt: %s', LaptopBlockReason(Entity) or 'SHOULD SHOW (look at the laptop, within ~1.5m)')
        else
            Add('nearest laptop: none within 10m')
        end

        print('[fw-bennys] ---- laptop debug ----')
        for _, Line in ipairs(Lines) do print(Line) end
        FW.Functions.Notify("Benny's laptop debug geprint in F8", "primary")
    end)
end)

-- ── Preview: /bennyslaptop shows the page with a calibration overlay on the nearest laptop ──

RegisterCommand('bennyslaptop', function()
    if Laptop.Open then return end
    if Laptop.Preview then
        Laptop.Preview = false
        DUI:Release(SCREEN)
        if Laptop.Shown then ShowIdle(Laptop.Shown) end
        return
    end

    local Entity = FindNearestLaptop(5.0)
    if not Entity then return FW.Functions.Notify("Geen laptop in de buurt..", "error") end

    CreateThread(function()
        if not DUI:Show(SCREEN, Entity) then return end
        Laptop.Preview, Laptop.Shown, Laptop.ShownBusiness = true, Entity, nil
        Send('init', { resource = GetCurrentResourceName(), business = 'Preview', label = 'Preview', me = { cid = '', name = 'Preview' }, calibrate = true })
        FW.Functions.Notify("Laptop preview aan (/bennyslaptop om uit te zetten)", "primary")
    end)
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() then CloseLaptop() end
end)
