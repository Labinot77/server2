-- Business laptop. fw-dui shows its computer desktop on the laptop in use (texture, camera, cursor; models with
-- screen copies get a free copy per location, so two laptops in one shop both work); this file puts the apps on it: "Work Orders" (html/laptop.html, live orders of the laptop's business)
-- and "Management" (html/management.html, see cl_management.lua).
-- Mirror: players nearby also see what the user does on it.
-- Laptops are fw-admin placed props inside a business Area (server/sv_orders.lua -> LoadLaptops).
FW = FW or exports['fw-core']:GetCoreObject()

local SCREEN = 'bennys_laptop'
local DUI = exports['fw-dui']

local Laptop = { Open = false, Entity = nil, Business = nil, PropId = nil, Shown = nil, ShownBusiness = nil, Preview = false }
local Laptops = {} -- [placed prop id] = { Id, Model, Coords, Business }
local ViewOrders = {} -- [Business] = orders, for players who aren't members

LAPTOP_SCREEN = SCREEN
local APP = Config.Laptop.Apps.Orders.id
local function Send(Action, Data, MirrorData) DUI:SendApp(SCREEN, APP, Action, Data, MirrorData) end

-- Apps of a business (Config.Orders.Businesses[...].Apps), a computer's own Apps go first.
function GetBusinessApps(Business)
    local Data = Config.Orders.Businesses[Business]
    return Data and Data.Apps or { 'Orders', 'Management' }
end

-- The apps on this laptop's desktop (Open = app id to show right away). Every player gets the same dock,
-- so watchers' screens match; the Management app itself locks for players without access.
local function SetApps(Business, Open, Apps)
    if not Business then return DUI:SetApps(SCREEN, {}) end
    local Label = Config.Orders.Businesses[Business] and Config.Orders.Businesses[Business].Label or Business
    local List = {}
    for _, Key in ipairs(Apps or GetBusinessApps(Business)) do
        local App = {}
        for K, V in pairs(Config.Laptop.Apps[Key]) do App[K] = V end
        App.label = App.label:format(Label)
        App.url = ('nui://%s/html/%s'):format(GetCurrentResourceName(), App.page)
        List[#List + 1] = App
    end
    DUI:SetApps(SCREEN, List, Open)
end

-- For cl_management.lua: the business of the laptop in use (nil when not using one).
function GetLaptopBusiness()
    return Laptop.Open and Laptop.Business or nil
end

local function GetLaptopForEntity(Entity)
    local Id = GetResourceState('fw-admin') == 'started' and exports['fw-admin']:GetPropIdByEntity(Entity)
    if Id and Laptops[Id] then return Laptops[Id] end
    local Coords = GetEntityCoords(Entity)
    for _, Entry in pairs(Laptops) do -- MLO computers: by position
        if Entry.Static and #(Entry.Coords - Coords) < 2.5 then return Entry end
    end
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

-- What a laptop shows while nobody uses it: the desktop, the player opens the app from the dock
-- (an empty desktop if the laptop isn't in a business Area). The app runs in the background with live orders.
local function ShowIdle(Entity)
    local Entry = GetLaptopForEntity(Entity)
    Laptop.Shown, Laptop.ShownBusiness = Entity, Entry and Entry.Business
    SetApps(Entry and Entry.Business, nil, Entry and Entry.Apps)
    ManagementLock()
    DealershipLock()
    if Entry then ShowDashboard(Entry.Business) end
end

-- ── Session ────────────────────────────────────────────────────────────────

function CloseLaptop()
    if not Laptop.Open then return end
    Laptop.Open = false

    Send('close')
    DUI:StopFocus()
    SetApps(Laptop.Business, nil, Laptop.Apps) -- back to the desktop (app windows closed), the app keeps its live orders
    ManagementLock()
    DealershipLock()
    DUI:Release(SCREEN) -- the range check takes over
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('fw-bennys:Server:Laptop:Release', Laptop.PropId) -- free for the next player
    Laptop.Entity, Laptop.Business, Laptop.PropId, Laptop.Apps = nil, nil, nil, nil
end

function OpenLaptop(Entity, Business)
    if Laptop.Open or not DoesEntityExist(Entity) then return end
    local Entry = GetLaptopForEntity(Entity)
    if not Entry then return end

    -- One player per laptop (server lock, see LaptopBlockReason).
    Laptop.Open = true
    -- Server lock and screen load at the same time: one round trip instead of two.
    local Claim = promise.new()
    CreateThread(function() Claim:resolve(FW.SendCallback('fw-bennys:Server:Laptop:Claim', Entry.Id)) end)

    local Ped = PlayerPedId()
    TaskTurnPedToFaceEntity(Ped, Entity, 600)

    local Shown, ScreenEntity = DUI:Show(SCREEN, Entity)
    if not Citizen.Await(Claim) then
        if Shown then DUI:Release(SCREEN) end
        Laptop.Open = false
        return FW.Functions.Notify("Someone else is using this laptop.", "error")
    end
    Laptop.Entity, Laptop.Business, Laptop.PropId, Laptop.Preview, Laptop.Apps = Entity, Business, Entry.Id, false, Entry.Apps

    if not Shown then
        Laptop.Open = false
        TriggerServerEvent('fw-bennys:Server:Laptop:Release', Laptop.PropId)
        if ScreenEntity == 'full' then return FW.Functions.Notify("Both laptop screens here are in use, try again in a moment.", "error") end
        return FW.Functions.Notify("The laptop couldn't be loaded.", "error")
    end
    Entity = ScreenEntity -- the screen copy when fw-dui swapped the laptop
    Laptop.Entity = Entity
    if Laptop.Shown ~= Entity or Laptop.ShownBusiness ~= Business then
        Laptop.Shown, Laptop.ShownBusiness = Entity, Business
        SetApps(Business, nil, Laptop.Apps)
        ShowDashboard(Business)
    end

    if not Laptop.Open then return end
    exports['fw-assets']:RequestAnimationDict('anim@heists@prison_heiststation@cop_reactions')
    TaskPlayAnim(Ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0, false, false, false)

    DUI:Focus(SCREEN, { Mouse = true, Sensitivity = Config.Laptop.CursorSensitivity })
    if HasApp(Entity, 'Dealership') then DealershipLoad(Business) end
    ManagementLoad(Business) -- after Focus, so players watching see it too
end

-- ── fw-dui ─────────────────────────────────────────────────────────────────

local function RegisterScreen()
    local Models = {}
    for Model in pairs(Config.Laptop.Models) do Models[#Models + 1] = Model end
    DUI:RegisterScreen(SCREEN, {
        Models = Models,
        Distance = Config.Laptop.RenderDistance,
        Placed = true,
        Mirror = true,
        MirrorKeys = true, -- nothing secret typed here, watchers see the real text
        SameInterior = true,
        Desktop = true,
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
-- Mirrored: players watching a laptop in use get the user's page, list included.
AddEventHandler('fw-bennys:Client:Laptop:Orders', function(Business, List)
    if Laptop.ShownBusiness == Business then Send('orders', List) end
end)

RegisterNetEvent('fw-bennys:Client:Laptop:View', function(Business, List)
    ViewOrders[Business] = List
    if Laptop.ShownBusiness == Business then Send('orders', List) end
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
            local Messages = { accept = 'Order accepted', release = 'Order released', decline = 'Order declined', complete = 'Order completed' }
            Send('toast', { text = Messages[Action], type = 'success' })
            PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            Send('toast', { text = Result and Result.Message or 'Something went wrong', type = 'error' })
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
            Send('toast', { text = 'Waypoint set to the vehicle', type = 'success' })
        else
            Send('toast', { text = 'Vehicle is not nearby', type = 'error' })
        end
        return Cb('ok')
    end

    if Action == 'sound' then
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end

    Cb('ok')
end)

-- ── Interact on the laptop props ───────────────────────────────────────────

local function Open(Entity)
    local Entry = GetLaptopForEntity(Entity)
    if Entry then CreateThread(function() OpenLaptop(Entity, Entry.Business) end) end
end

-- The business of this laptop has App on its dock.
function HasApp(Entity, App)
    local Entry = GetLaptopForEntity(Entity)
    if not Entry then return false end
    for _, Key in ipairs(Entry.Apps or GetBusinessApps(Entry.Business)) do
        if Key == App then return true end
    end
    return false
end

local Registered = {} -- [Model] = true (interact's AddModelInteraction appends, so register once)

local function SetLaptops(List)
    Laptops = {}
    for _, Entry in ipairs(List or {}) do
        Laptops[Entry.Id] = {
            Id = Entry.Id,
            Model = Entry.Model,
            Business = Entry.Business,
            Static = Entry.Static,
            Apps = Entry.Apps,
            Coords = vector3(Entry.Coords.x, Entry.Coords.y, Entry.Coords.z),
        }
    end
end

RegisterNetEvent('fw-bennys:Client:Laptop:SetLaptops', SetLaptops)

-- Why the prompt is (not) shown, as a reason string; nil = can interact.
-- Another player has a session on this laptop (server id), nil = free or it's me.
local function GetLaptopUser(Id)
    local User = GlobalState[('bennys_laptop_%s'):format(Id)]
    if User and User ~= GetPlayerServerId(PlayerId()) then return User end
end

-- Dead, talking on the radio or a progress bar running (fw-progressbar or fw-ui).
local function IsPlayerBusy()
    local PlayerData = FW.Functions.GetPlayerData()
    if IsEntityDead(PlayerPedId()) or (PlayerData and PlayerData.metadata and PlayerData.metadata.isdead) then return 'dead' end
    if GetResourceState('fw-voice') == 'started' and exports['fw-voice']:TalkingOnRadio() then return 'talking on the radio' end
    for _, Resource in ipairs({ 'fw-progressbar', 'fw-ui' }) do
        if GetResourceState(Resource) == 'started' and exports[Resource]:GetTaskBarStatus() then return 'a progress bar is running' end
    end
end

function LaptopBlockReason(Entity)
    if Laptop.Open then return 'laptop already open' end
    local Busy = IsPlayerBusy()
    if Busy then return Busy end
    local Entry = GetLaptopForEntity(Entity)
    if not Entry then return 'not a placed laptop (admin panel) inside a business Area' end
    if GetLaptopUser(Entry.Id) then return 'someone else is using this laptop' end
    if not IsOrderMechanic(Entry.Business) then return 'not a member of ' .. Entry.Business .. ' (client cache)' end
    return nil
end

function LaptopCanInteract(Entity)
    return LaptopBlockReason(Entity) == nil
end

-- Laptop models + their fw-dui screen copies (the laptop in use is swapped to a copy).
local function GetLaptopModels()
    local List = {}
    for Model in pairs(Config.Laptop.Models) do
        List[#List + 1] = Model
        for _, Variant in ipairs(GetResourceState('fw-dui') == 'started' and DUI:GetVariants(Model) or {}) do
            List[#List + 1] = Variant
        end
    end
    return List
end

-- Computers can't be shot or broken (map props and fw-dui screen copies alike).
CreateThread(function()
    while true do
        local Hashes, Coords = {}, GetEntityCoords(PlayerPedId())
        for _, Model in ipairs(GetLaptopModels()) do Hashes[joaat(Model)] = true end
        for _, Obj in ipairs(GetGamePool('CObject')) do
            if Hashes[GetEntityModel(Obj)] and #(GetEntityCoords(Obj) - Coords) < 50.0 then
                SetEntityInvincible(Obj, true)
                SetEntityCanBeDamaged(Obj, false)
                SetDisableFragDamage(Obj, true)
            end
        end
        Wait(1000)
    end
end)

local function RegisterInteractions()
    if GetResourceState('interact') ~= 'started' then return end

    for _, Model in ipairs(GetLaptopModels()) do
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
                            canInteract = function(Entity) return LaptopCanInteract(Entity) and HasApp(Entity, 'Orders') end,
                            action = Open,
                        },
                        {
                            name = 'bennys_laptop_computer',
                            label = 'Use Computer',
                            canInteract = function(Entity) return LaptopCanInteract(Entity) and not HasApp(Entity, 'Orders') end,
                            action = Open,
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
    for _, Model in ipairs(GetLaptopModels()) do
        local Entity = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, Radius, joaat(Model), false, false, false)
        if Entity ~= 0 then return Entity, Model end
    end
end

-- ── /workorders: open the nearest laptop without interact (fallback + testing) ──

RegisterCommand('workorders', function()
    local Entity = FindNearestLaptop(2.5)
    if not Entity then return FW.Functions.Notify("No laptop nearby.", "error") end

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
        FW.Functions.Notify("Laptop debug printed in F8", "primary")
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
    if not Entity then return FW.Functions.Notify("No laptop nearby.", "error") end

    CreateThread(function()
        local Shown, ScreenEntity = DUI:Show(SCREEN, Entity)
        if not Shown then return end
        Laptop.Preview, Laptop.Shown, Laptop.ShownBusiness = true, ScreenEntity, nil
        SetApps('Preview', true)
        Send('init', { resource = GetCurrentResourceName(), business = 'Preview', label = 'Preview', me = { cid = '', name = 'Preview' }, calibrate = true })
        FW.Functions.Notify("Laptop preview on (/bennyslaptop to turn it off)", "primary")
    end)
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() then CloseLaptop() end
end)
