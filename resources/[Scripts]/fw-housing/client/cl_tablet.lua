-- House tablet: fw-dui desktop on the house's tablet (Config.Storage.Tablet, fixed spot from /housecreator) with the
-- "House" app (html/house.html, server/sv_tablet.lua). Players nearby see the screen too (mirror, balances hidden).
-- The tablet in use is swapped to a screen copy (_dui_01 / _dui_02): cl_mlo.lua respawns our local prop for fw-dui.
local FW = exports['fw-core']:GetCoreObject()
local DUI = exports['fw-dui']
local SCREEN, APP = 'house_tablet', 'house'
local Tablet = { Open = false, HouseId = nil }

function IsHouseTabletOpen() return Tablet.Open end

local function Send(Action, Data)
    local Mirror = Data
    if Action == 'data' then -- watchers don't see the owner's bank accounts
        Mirror = {}
        for K, V in pairs(Data) do Mirror[K] = V end
        Mirror.Accounts = {}
    end
    DUI:SendApp(SCREEN, APP, Action, Data, Mirror)
end

local function Refresh()
    local Data = FW.SendCallback('fw-housing:Server:Tablet:Get', Tablet.HouseId)
    if not Tablet.Open then return end
    if not Data then return CloseHouseTablet() end
    Send('data', Data)
end

function CloseHouseTablet()
    if not Tablet.Open then return end
    Tablet.Open, Tablet.HouseId = false, nil
    DUI:StopFocus()
    DUI:Release(SCREEN)
end

function OpenHouseTablet(HouseId, Entity)
    if Tablet.Open or not Entity or not DoesEntityExist(Entity) then return end
    Tablet.Open, Tablet.HouseId = true, HouseId
    CreateThread(function()
        TaskTurnPedToFaceEntity(PlayerPedId(), Entity, 600)
        local Shown, Result = DUI:Show(SCREEN, Entity)
        if not Shown then
            Tablet.Open, Tablet.HouseId = false, nil
            return FW.Functions.Notify(Result == 'full' and "Both tablet screens nearby are in use, try again in a moment." or "The tablet couldn't be loaded.", "error")
        end
        DUI:SetApps(SCREEN, { { id = APP, label = 'House', icon = 'fas fa-home', color = 'linear-gradient(160deg, #9be15d, #4f8a2b)',
            width = Config.HouseApp.Window.Width, height = Config.HouseApp.Window.Height,
            url = ('nui://%s/html/house.html'):format(GetCurrentResourceName()) } }, APP)
        Send('init', { resource = GetCurrentResourceName() })
        DUI:Focus(SCREEN, { Mouse = true })
        Refresh()
    end)
end

-- Leaving the zone / house gone: put it down.
CreateThread(function()
    while true do
        Wait(1000)
        if Tablet.Open and GetMloInsideHouseId() ~= Tablet.HouseId then CloseHouseTablet() end
    end
end)

-- // fw-dui \\ --

local function RegisterScreen()
    DUI:RegisterScreen(SCREEN, { Models = { Config.Storage.Tablet }, Distance = 8.0, Mirror = true, MirrorKeys = true, Desktop = true })
end
CreateThread(function() if GetResourceState('fw-dui') == 'started' then RegisterScreen() end end)
AddEventHandler('onClientResourceStart', function(Resource) if Resource == 'fw-dui' then RegisterScreen() end end)

AddEventHandler('fw-dui:Client:Closed', function(Name) if Name == SCREEN then CloseHouseTablet() end end)

-- // App -> client \\ --

RegisterNUICallback('house', function(Data, Cb)
    Cb('ok')
    local Action = Data and Data.Action
    if Action == 'close' then return CloseHouseTablet() end
    if not Tablet.Open then return end
    if Action == 'sound' then return PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true) end
    if Action == 'refresh' then return Refresh() end
    if Action ~= 'action' then return end

    local R = FW.SendCallback('fw-housing:Server:Tablet:Action', Tablet.HouseId, Data.Do, Data.Data)
    if not R or not Tablet.Open then return end
    if R.Data then Send('data', R.Data) end
    if R.Msg then Send('toast', { text = R.Msg, ok = R.Ok }) end
    PlaySoundFrontend(-1, R.Ok and 'SELECT' or 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() then CloseHouseTablet() end
end)
