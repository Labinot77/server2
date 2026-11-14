-- Bugger: the green heist laptop. Place it anywhere, scan the WiFi around it and hack the branch network
-- (only after the power box is cut open). Success = network down + the backdoor code for the staff door keypad.
-- Server: server/sv_fleeca_advanced.lua (Wifis / StartHack / FinishHack / PlaceLaptop / TakeLaptop).
local Cfg = Config.FleecaAdvanced
local DUI = exports['fw-dui']
local LAPTOP = 'fleeca_laptop'
local App = { id = 'bugger', label = 'Bugger', icon = 'fas fa-bug', color = 'linear-gradient(160deg, #20c997, #087f5b)',
    url = ('nui://%s/html/fleeca/bugger.html'):format(GetCurrentResourceName()), width = 62, height = 68 }

local Session = nil -- { Entity, NetId, Hacking = FleecaId }
local Placing = false

local function Notify(Text, Type) FW.Functions.Notify(Text, Type or 'primary') end
local function Send(Action, Data) DUI:SendApp(LAPTOP, App.id, Action, Data, Data) end -- mirrored to watchers

CreateThread(function() DUI:RegisterScreen(LAPTOP, { Models = { Cfg.Models.Laptop }, Mirror = true, Desktop = true }) end)

local function LoadModel(Hash)
    RequestModel(Hash)
    local Deadline = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Deadline do Wait(10) end
end

local function Anim()
    RequestAnimDict('pickup_object')
    while not HasAnimDictLoaded('pickup_object') do Wait(10) end
    TaskPlayAnim(PlayerPedId(), 'pickup_object', 'putdown_low', 8.0, -8.0, 1000, 48, 0, false, false, false)
    Wait(800)
end

-- Where the camera looks, if it's a flat surface within reach.
local function Aim(Ped)
    local From, R = GetGameplayCamCoord(), math.rad(1) * GetGameplayCamRot(2)
    local Dir = vector3(-math.sin(R.z) * math.abs(math.cos(R.x)), math.cos(R.z) * math.abs(math.cos(R.x)), math.sin(R.x))
    local To = From + Dir * 8.0
    local _, Hit, Pos, Normal = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(From.x, From.y, From.z, To.x, To.y, To.z, 17, Ped, 4))
    return Hit == 1 and Normal.z > 0.7 and #(Pos - GetEntityCoords(Ped)) <= 2.5 and Pos or nil
end

local function Help(Text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(Text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

-- Ghost laptop follows the aim: scroll rotates, E places, Backspace / right click cancels. Returns coords + heading.
local function Place()
    local Ped, Hash = PlayerPedId(), joaat(Cfg.Models.Laptop)
    LoadModel(Hash)
    local Ghost = CreateObject(Hash, GetEntityCoords(Ped), false, false, false)
    SetEntityAlpha(Ghost, 160, false)
    SetEntityCollision(Ghost, false, false)
    FreezeEntityPosition(Ghost, true)
    local Heading, Result = GetEntityHeading(Ped) + 180.0, nil

    while true do
        for _, C in ipairs({ 14, 15, 16, 17, 24, 25, 37, 38, 177, 200 }) do DisableControlAction(0, C, true) end
        local Pos = Aim(Ped)
        if IsDisabledControlPressed(0, 14) then Heading = Heading - 5.0 end
        if IsDisabledControlPressed(0, 15) then Heading = Heading + 5.0 end
        SetEntityVisible(Ghost, Pos ~= nil, false)
        if Pos then
            SetEntityCoords(Ghost, Pos.x, Pos.y, Pos.z, false, false, false, false)
            SetEntityHeading(Ghost, Heading)
        end
        Help(Pos and '~INPUT_PICKUP~ Place laptop~n~~INPUT_WEAPON_WHEEL_NEXT~ Rotate~n~~INPUT_FRONTEND_RRIGHT~ Cancel' or 'Aim at a flat surface close by~n~~INPUT_FRONTEND_RRIGHT~ Cancel')
        if Pos and IsDisabledControlJustPressed(0, 38) then Result = vector4(Pos.x, Pos.y, Pos.z, Heading) break end
        if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 200) or IsEntityDead(Ped) then break end
        Wait(0)
    end
    DeleteEntity(Ghost)
    SetModelAsNoLongerNeeded(Hash)
    return Result
end

RegisterNetEvent('fw-heists:Client:HeistLaptopUsed', function(Type)
    if Type ~= Cfg.Items.LaptopType or Placing or Session or IsPedInAnyVehicle(PlayerPedId(), false) then return end
    local _, Bank = GetCurrentFleeca()
    if Bank and not Bank.Advanced and #(Bank.Vault - GetEntityCoords(PlayerPedId())) <= 1.5 then return end -- old vault hack (cl_fleeca.lua)
    Placing = true
    local At = Place()
    if At and FW.SendCallback('fw-heists:Server:FleecaAdv:PlaceLaptop') then
        Anim()
        local Hash = joaat(Cfg.Models.Laptop)
        LoadModel(Hash)
        local Obj = CreateObject(Hash, At.x, At.y, At.z, true, true, false)
        SetEntityHeading(Obj, At.w)
        FreezeEntityPosition(Obj, true)
        SetEntityAsMissionEntity(Obj, true, true)
        SetModelAsNoLongerNeeded(Hash)
        Entity(Obj).state:set('fleecaLaptop', GetPlayerServerId(PlayerId()), true)
    end
    Placing = false
end)

-- ── Session ────────────────────────────────────────────────────────────────

local function Close()
    if not Session then return end
    if Session.Hacking then FW.SendCallback('fw-heists:Server:FleecaAdv:FinishHack', Session.Hacking, false) end
    Session = nil
    DUI:StopFocus()
    DUI:Release(LAPTOP)
end

local function Open(Entity)
    if Session then return end
    local Shown, Reason = DUI:Show(LAPTOP, Entity)
    if not Shown then return Notify(Reason == 'busy' and 'Someone is already using this laptop.' or "The laptop won't boot.", 'error') end
    Session = { Entity = Entity, NetId = NetworkGetNetworkIdFromEntity(Entity) }
    TaskTurnPedToFaceEntity(PlayerPedId(), Entity, 600)
    Wait(600)
    DUI:SetApps(LAPTOP, { App })
    DUI:Focus(LAPTOP, { Mouse = true })
end

local function Take(Entity)
    if Session and Session.Entity == Entity then Close() end
    Anim()
    TriggerServerEvent('fw-heists:Server:FleecaAdv:TakeLaptop', NetworkGetNetworkIdFromEntity(Entity))
end

AddEventHandler('fw-dui:Client:Shown', function(Name)
    if Name == LAPTOP and not Session then DUI:SetApps(LAPTOP, { App }) end -- watchers: same desktop
end)

AddEventHandler('fw-dui:Client:Closed', function(Name)
    if Name == LAPTOP then Close() end
end)

local Fails = {
    busy = 'Another device is already attacking this network.', locked = 'Handshake rejected: the network is still behind its firewall.',
    compromised = 'This network is already compromised.', blocked = 'Not enough officers on duty.', fake = 'Handshake failed: WPA3 encryption too strong.',
}

local Actions = {
    scan = function()
        local List = {}
        for _, W in ipairs(FW.SendCallback('fw-heists:Server:FleecaAdv:Wifis', Session.NetId) or {}) do
            List[#List + 1] = { id = W.Id, ssid = W.Ssid, signal = W.Signal, state = W.State }
        end
        local Fakes = { table.unpack(Cfg.FakeWifis) }
        for i = 1, math.random(4, 6) do
            local Ssid = table.remove(Fakes, math.random(#Fakes))
            if not Ssid then break end
            List[#List + 1] = { id = 'f' .. i, ssid = Ssid, signal = math.random(1, 4), state = 'secured' }
        end
        for i = #List, 2, -1 do local j = math.random(i) List[i], List[j] = List[j], List[i] end
        Send('networks', { list = List })
    end,
    hack = function(Data)
        local Id = tonumber(Data.id)
        if not Id then Wait(1500) return Send('failed', { reason = Fails.fake }) end
        local Result = FW.SendCallback('fw-heists:Server:FleecaAdv:StartHack', Id, Session.NetId)
        if Result ~= true then return Send('failed', { reason = Fails[Result] or 'Connection lost.' }) end
        Session.Hacking = Id
        Send('hack', { seed = math.random(1, 99999), rounds = Cfg.Hack.Rounds, time = Cfg.Hack.Time, cols = Cfg.Hack.Cols, rows = Cfg.Hack.Rows })
    end,
}

RegisterNUICallback('fleecaBugger', function(Data, Cb)
    Cb('ok')
    if Session and Actions[Data.Action] then CreateThread(function() Actions[Data.Action](Data) end) end
end)

-- GridBreaker (nested in Bugger) reports the minigame result.
RegisterNUICallback('fleecaLaptop', function(Data, Cb)
    Cb('ok')
    local Id = Session and Session.Hacking
    if not Id or Data.Action ~= 'result' then return end
    Session.Hacking = nil
    CreateThread(function()
        local Result = FW.SendCallback('fw-heists:Server:FleecaAdv:FinishHack', Id, Data.Success == true)
        if not Result then return Send('failed', { reason = 'Trace detected, connection terminated.' }) end
        Send('backdoor', { code = Result.Code, ssid = Config.Fleeca[Id].Advanced.Wifi })
        TriggerServerEvent('fw-mdw:Server:SendAlert:FleecaBank', GetEntityCoords(PlayerPedId()))
        StartCoordsChecker(Config.Fleeca[Id].Center, 100.0, function() FW.TriggerServer('fw-heists:Server:Fleeca:LeftArea', Id) end)
        if RefreshStep then RefreshStep(Id) end
    end)
end)

CreateThread(function()
    local Mine = function(E)
        local Owner = Entity(E).state.fleecaLaptop
        return Owner and (Owner == GetPlayerServerId(PlayerId()) or GetPlayerFromServerId(Owner) == -1)
    end
    exports['interact']:AddModelInteraction({
        modelData = { { model = Cfg.Models.Laptop, offset = vec3(0.0, 0.0, 0.2) } }, distance = 3.0, interactDst = 1.3,
        options = {
            { name = 'bugger_use', label = 'Use laptop', canInteract = function(E) return not Session and Entity(E).state.fleecaLaptop ~= nil end,
                action = function(E) CreateThread(function() Open(E) end) end },
            { name = 'bugger_take', label = 'Take laptop', canInteract = function(E) return not Session and Mine(E) end,
                action = function(E) CreateThread(function() Take(E) end) end },
        },
    })
end)

AddEventHandler('onResourceStop', function(Res) if Res == GetCurrentResourceName() and Session then DUI:Release(LAPTOP) end end)
