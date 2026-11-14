-- Pawn shop (config/sh_pawn.lua): the Pawn Order app on the shop computer (html/pawn.html), the Safe and
-- Drop-off storage prompts, and the runners' delivery prompts at freight drop-offs.
FW = FW or exports['fw-core']:GetCoreObject()

local DUI = exports['fw-dui']
local APP = Config.Laptop.Apps.Pawn.id
local P = Config.Pawn
local Dropoffs = {} -- [Id] = { Interaction, Blip }
local Delivering, RouteId, Runner = false, nil, false

local function Send(Action, Data, MirrorData) DUI:SendApp(LAPTOP_SCREEN, APP, Action, Data, MirrorData) end
local function Sound(Name) PlaySoundFrontend(-1, Name, 'HUD_FRONTEND_DEFAULT_SOUNDSET', true) end

-- GPS route to a shipment's drop-off blip (nil = none).
local function RouteTo(Id)
    RouteId = Id
    for SpotId, Spot in pairs(Dropoffs) do SetBlipRoute(Spot.Blip, SpotId == Id) end
end

-- ── App (called by cl_laptop.lua) ──────────────────────────────────────────

function PawnLock() Send('lock', {}, false) end

function PawnLoad(Business)
    if Business ~= P.Business then return end
    CreateThread(function()
        local View = FW.SendCallback('fw-bennys:Server:Pawn:View')
        if GetLaptopBusiness() ~= Business then return end
        Send(View and 'view' or 'lock', View or { text = "You don't have access to this app" })
    end)
end

RegisterNUICallback('pawn', function(Data, Cb)
    Cb('ok')
    local Business, Action = GetLaptopBusiness(), Data and Data.Action
    if Business ~= P.Business or not Action then return end -- watchers' copies post too: ignored

    if Action == 'sound' then return Sound('NAV_UP_DOWN') end
    if Action == 'refresh' then return PawnLoad(Business) end
    if Action == 'gps' then
        RouteTo(Data.Id)
        return Send('toast', { text = 'GPS set', type = 'success' })
    end

    CreateThread(function()
        local Result = FW.SendCallback('fw-bennys:Server:Pawn:Action', Action, { Id = Data.Id }) or {}
        Sound(Result.Success and 'SELECT' or 'ERROR')
        if Result.Message then Send('toast', { text = Result.Message, type = Result.Success and 'success' or 'error' }) end
        if Result.Success and Action == 'deliver' then RouteId = Data.Id end -- routed when its blip arrives
        PawnLoad(Business)
    end)
end)

-- ── Safe + drop-off storage ────────────────────────────────────────────────

local function OpenStorage(Which)
    if not exports['fw-inventory']:CanOpenInventory() then return end
    local Storage = FW.SendCallback('fw-bennys:Server:Pawn:Storage', Which)
    if not Storage then return FW.Functions.Notify('No access..', 'error') end
    FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Stash', Storage.Name, Storage.Slots, Storage.Weight)
end

CreateThread(function()
    while GetResourceState('interact') ~= 'started' do Wait(500) end
    local IsMember = function() return IsOrderMechanic(P.Business) end
    for _, Entry in ipairs({ { 'Safe', 'Open Safe', P.Safe }, { 'DropOff', 'Drop-off Storage', P.DropOff } }) do
        exports['interact']:AddInteraction({
            name = 'pawn_' .. Entry[1], coords = Entry[3].Coords, distance = 4.0, interactDst = 1.5,
            options = { { label = Entry[2], canInteract = IsMember, action = function() CreateThread(function() OpenStorage(Entry[1]) end) end } },
        })
    end
end)

-- ── Runner: deliver boxes at the drop-off ──────────────────────────────────

local function DeliverBox()
    if Delivering then return end
    Delivering = true
    local Done = FW.Functions.CompactProgressbar(P.DeliverTime, 'Delivering box...', false, true, { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true }, {}, {}, {}, false)
    if Done then
        local Result = FW.SendCallback('fw-bennys:Server:Pawn:DeliverBox') or {}
        FW.Functions.Notify(Result.Message or 'Something went wrong', Result.Success and 'success' or 'error')
        if Result.Alert then TriggerServerEvent('fw-mdw:Server:SendAlert:Oxy', GetEntityCoords(PlayerPedId()), FW.Functions.GetStreetLabel()) end
    end
    Delivering = false
end

local function SetDropoffs(List)
    if GetResourceState('interact') ~= 'started' then return end
    for _, Spot in pairs(Dropoffs) do
        exports['interact']:RemoveInteraction(Spot.Interaction)
        RemoveBlip(Spot.Blip)
    end
    Dropoffs = {}
    for _, Spot in ipairs(List or {}) do
        local Coords = vector3(Spot.Coords.x, Spot.Coords.y, Spot.Coords.z)
        local Blip = AddBlipForCoord(Coords.x, Coords.y, Coords.z)
        SetBlipSprite(Blip, P.Blip.Sprite)
        SetBlipColour(Blip, P.Blip.Color)
        SetBlipScale(Blip, P.Blip.Scale)
        SetBlipAsShortRange(Blip, false)
        SetBlipDisplay(Blip, 0) -- shown by the thread below
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Pawn Drop-off: ' .. Spot.Label)
        EndTextCommandSetBlipName(Blip)

        Dropoffs[Spot.Id] = { Blip = Blip, Interaction = exports['interact']:AddInteraction({
            name = 'pawn_dropoff_' .. Spot.Id, coords = vector3(Spot.Coords.x, Spot.Coords.y, Spot.Coords.z), distance = 8.0, interactDst = 2.5,
            options = { {
                label = 'Deliver Box (' .. Spot.Label .. ')',
                canInteract = function() return not Delivering and exports['fw-inventory']:HasEnoughOfItem(P.BoxItem, 1) end,
                action = function() CreateThread(DeliverBox) end,
            } },
        }) }
    end
    if RouteId and Dropoffs[RouteId] then RouteTo(RouteId) end
end

-- Blips: business members, and runners once they carried a box (until no shipment is on the road).
CreateThread(function()
    while true do
        if next(Dropoffs) then
            Runner = Runner or exports['fw-inventory']:HasEnoughOfItem(P.BoxItem, 1)
            local Show = Runner or IsOrderMechanic(P.Business)
            for Id, Spot in pairs(Dropoffs) do
                SetBlipDisplay(Spot.Blip, Show and 2 or 0)
                if Show and Id == RouteId then SetBlipRoute(Spot.Blip, true) end
            end
        else
            Runner, RouteId = false, nil
        end
        Wait(2000)
    end
end)

RegisterNetEvent('fw-bennys:Client:Pawn:Changed', function(List)
    SetDropoffs(List)
    local Business = GetLaptopBusiness()
    if Business == P.Business then PawnLoad(Business) end
end)

CreateThread(function()
    while GetResourceState('interact') ~= 'started' do Wait(500) end
    while not FW.Functions.GetPlayerData() or not FW.Functions.GetPlayerData().citizenid do Wait(1000) end
    SetDropoffs(FW.SendCallback('fw-bennys:Server:Pawn:Dropoffs'))
end)
