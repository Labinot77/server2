--[[
    fw-mainmenu
    Custom map built from GTA's own pause-map textures, with the "Filter / Locations" list and the GPS route.

    Opened from:
      * np-quickmenu (MAP button)               -> ESC goes back to the quick menu
      * the default GTA pause menu (click map)  -> ESC goes back to the pause menu
      * exports['fw-mainmenu']:OpenMap()

    Events (client):
      fw-mainmenu:Client:OnMapToggle (open: boolean)
      fw-mainmenu:Client:OnMapClosed (openedFrom: 'quickmenu' | 'pause' | 'export', toGame: boolean)
]]

local MapOpen = false
local OpenedFrom = nil       -- 'quickmenu' | 'pause' | 'export'
local PauseMenuVersion = nil
local Cooldown = 0
local Debug = Config.Debug

local function Log(Fmt, ...)
    if Debug then print(('[fw-mainmenu] ' .. Fmt):format(...)) end
end

-- ---------------------------------------------------------------------
-- Blip categories
-- ---------------------------------------------------------------------
local SpriteLookup = {}
for _, Section in ipairs(Config.Sections) do
    for _, Entry in ipairs(Section.Entries) do
        for _, Sprite in ipairs(Entry.Sprites or {}) do
            SpriteLookup[Sprite] = SpriteLookup[Sprite] or { Colored = {} }
            if Entry.Colors and #Entry.Colors > 0 then
                for _, Color in ipairs(Entry.Colors) do SpriteLookup[Sprite].Colored[Color] = Entry.Id end
            elseif not SpriteLookup[Sprite].Generic then
                SpriteLookup[Sprite].Generic = Entry.Id
            end
        end
    end
end

local function GetCategory(Sprite, Color)
    local Lookup = SpriteLookup[Sprite]
    if not Lookup then return nil end
    return Lookup.Colored[Color] or Lookup.Generic
end

local function BuildLegend()
    local Sections = {}
    for _, Section in ipairs(Config.Sections) do
        local Entries = {}
        for _, Entry in ipairs(Section.Entries) do
            Entries[#Entries + 1] = { Id = Entry.Id, Label = Entry.Label, Icon = Entry.Icon, Tint = Entry.Tint }
        end
        Sections[#Sections + 1] = { Id = Section.Id, Label = Section.Label, Entries = Entries }
    end
    return Sections
end

local ScanSprites = nil      -- sprites to scan on refresh (filled by the full scan on open)

local function CollectBlips(Full)
    local Blips, Waypoint = {}, nil
    local MainBlip = GetMainPlayerBlipId()

    local Sprites = {}
    if Full or not ScanSprites then
        for Sprite = 1, 900 do Sprites[#Sprites + 1] = Sprite end
        Full = true
    else
        Sprites = ScanSprites
    end
    local Seen = {}

    for _, Sprite in ipairs(Sprites) do
        if not Config.IgnoredSprites[Sprite] then
            local Blip = GetFirstBlipInfoId(Sprite)
            if Full and DoesBlipExist(Blip) then Seen[#Seen + 1] = Sprite end
            while DoesBlipExist(Blip) do
                local Display = GetBlipInfoIdDisplay(Blip)
                if Blip ~= MainBlip and Display ~= 0 and Display ~= 5 and Display ~= 9 and GetBlipAlpha(Blip) > 0 then
                    local Coords = GetBlipInfoIdCoord(Blip)
                    if Sprite == 8 then
                        Waypoint = { x = Coords.x, y = Coords.y }
                    else
                        local Color = GetBlipColour(Blip)
                        Blips[#Blips + 1] = { x = Coords.x, y = Coords.y, s = Sprite, c = Color, cat = GetCategory(Sprite, Color) }
                    end
                end
                Blip = GetNextBlipInfoId(Sprite)
            end
        end
    end

    if Full then
        -- refresh scans: the waypoint, every sprite seen now and every configured sprite
        local Set = { [8] = true }
        for _, S in ipairs(Seen) do Set[S] = true end
        for S in pairs(SpriteLookup) do Set[S] = true end
        ScanSprites = {}
        for S in pairs(Set) do ScanSprites[#ScanSprites + 1] = S end
    end

    if not Waypoint then
        local W = GetFirstBlipInfoId(8)
        if DoesBlipExist(W) then local C = GetBlipInfoIdCoord(W); Waypoint = { x = C.x, y = C.y } end
    end

    return Blips, Waypoint
end

local function GetPlayerInfo()
    local Ped = PlayerPedId()
    local Coords = GetEntityCoords(Ped)
    local Vehicle = GetVehiclePedIsIn(Ped, false)
    local Heading = Vehicle ~= 0 and GetEntityHeading(Vehicle) or GetEntityHeading(Ped)
    return { x = Coords.x, y = Coords.y, h = Heading }
end

local function SetHud(Visible)
    if not Config.HideHud then return end
    pcall(function() exports['fw-hud']:SetHudVisibleState(Visible) end)
end

-- ---------------------------------------------------------------------
-- GPS route: GTA calculates the route to the waypoint; points along it are sampled.
-- GET_POS_ALONG_GPS_TYPE_ROUTE has undocumented arguments, so the working combination is detected once.
-- ---------------------------------------------------------------------
local RouteCombos = { { true, 0 }, { false, 0 }, { true, 1 }, { false, 1 }, { true, 2 }, { false, 2 } }
local RouteMode = nil

local function TryRoutePos(P1, Slot, Distance)
    local Ok, A, B = pcall(GetPosAlongGpsTypeRoute, P1, Distance + 0.0, Slot)
    if not Ok then return nil end
    local Hit, Pos = nil, nil
    if type(A) == 'boolean' or type(A) == 'number' then Hit, Pos = A, B else Pos = A end
    if type(Pos) ~= 'vector3' or (Pos.x == 0.0 and Pos.y == 0.0) then return nil end
    if Hit == false or Hit == 0 then return nil end
    return Pos
end

local function DetectRouteMode()
    for _, C in ipairs(RouteCombos) do
        local A, B = TryRoutePos(C[1], C[2], 30.0), TryRoutePos(C[1], C[2], 250.0)
        if A and B and #(A.xy - B.xy) > 5.0 then return C end
    end
    return nil
end

local function GetWaypointCoords()
    local W = GetFirstBlipInfoId(8)
    if not DoesBlipExist(W) then return nil end
    return GetBlipInfoIdCoord(W)
end

local function StraightRoute(Target)
    local P = GetEntityCoords(PlayerPedId())
    return { points = { { Target.x, Target.y } }, length = #(P.xy - Target.xy), straight = true }
end

local function GetRoute()
    if not Config.ShowRoute or not IsWaypointActive() then return nil end
    local Target = GetWaypointCoords()
    if not Target then return nil end

    RouteMode = RouteMode or DetectRouteMode()
    if not RouteMode then return StraightRoute(Target) end -- GTA's route can't be read (yet)

    local Points, Length, Prev, Stuck = {}, 0.0, nil, 0
    for I = 0, Config.RouteMaxPoints do
        local Pos = TryRoutePos(RouteMode[1], RouteMode[2], I * Config.RouteStep)
        if not Pos then break end
        if Prev then
            local Step = #(Pos.xy - Prev.xy)
            if Step < 0.5 then Stuck = Stuck + 1 else Stuck = 0 end
            if Stuck >= 3 then break end -- reached the end of the route
            Length = Length + Step
        end
        Points[#Points + 1] = { Pos.x, Pos.y }
        Prev = Pos
        if #(Pos.xy - Target.xy) < Config.RouteStep then break end
    end
    Points[#Points + 1] = { Target.x, Target.y }

    if #Points < 3 then return StraightRoute(Target) end

    local Native = GetGpsBlipRouteLength()
    return { points = Points, length = (Native and Native > 0) and Native or Length }
end

-- ---------------------------------------------------------------------
-- Open / close
-- ---------------------------------------------------------------------
local function WaypointHex()
    local C = Config.WaypointColor
    if not C then return false end
    return ('#%02x%02x%02x'):format(C[1], C[2], C[3])
end

local RouteFastUntil = 0   -- after setting a waypoint, re-read the route quickly until GTA has calculated it

local function HasBack()
    return OpenedFrom == 'quickmenu' or (OpenedFrom == 'pause' and Config.ReturnToPauseMenu)
end

-- OpenMap(fromPause?, source?)  source: 'quickmenu' | 'pause' | nil (export)
function OpenMap(FromPause, Source)
    if MapOpen then return end
    MapOpen = true
    OpenedFrom = Source or (FromPause == true and 'pause') or 'export'
    Log('opening map (from %s)', OpenedFrom)

    local Blips, Waypoint = CollectBlips(true)
    SendNUIMessage({
        action = 'open',
        legend = BuildLegend(),
        blips = Blips,
        waypoint = Waypoint,
        route = GetRoute(),
        waypointColor = WaypointHex(),
        player = GetPlayerInfo(),
        back = HasBack(),
    })
    SetNuiFocus(true, true)
    SetHud(false)
    TriggerEvent('fw-mainmenu:Client:OnMapToggle', true)

    -- GTA only updates the GPS route while the radar is drawn; it's hidden behind this page anyway
    Citizen.CreateThread(function()
        while MapOpen do
            DisplayRadar(true)
            Citizen.Wait(0)
        end
    end)

    Citizen.CreateThread(function()
        local NextBlips = GetGameTimer() + Config.BlipUpdateInterval
        local NextRoute = GetGameTimer() + Config.RouteUpdateInterval
        while MapOpen do
            SendNUIMessage({ action = 'player', player = GetPlayerInfo() })

            local Now = GetGameTimer()
            if Now >= NextBlips then
                NextBlips = Now + Config.BlipUpdateInterval
                local NewBlips, NewWaypoint = CollectBlips()
                SendNUIMessage({ action = 'blips', blips = NewBlips, waypoint = NewWaypoint })
            end
            if Now >= NextRoute then
                local Route = GetRoute()
                SendNUIMessage({ action = 'route', route = Route })
                -- poll fast right after a new waypoint until the real road route is there
                if Now < RouteFastUntil and (not Route or Route.straight) then
                    NextRoute = Now + 200
                else
                    NextRoute = Now + Config.RouteUpdateInterval
                    if Route and not Route.straight then RouteFastUntil = 0 end
                end
            end

            Citizen.Wait(Config.PlayerUpdateInterval)
        end
    end)
end

function CloseMap(ToGame)
    if not MapOpen then return end
    MapOpen = false
    Cooldown = GetGameTimer() + 600
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    SetHud(true)
    TriggerEvent('fw-mainmenu:Client:OnMapToggle', false)

    local From = OpenedFrom
    OpenedFrom = nil
    ToGame = ToGame == true
    Log('closing map (from %s, toGame=%s)', tostring(From), tostring(ToGame))

    if From == 'pause' and Config.ReturnToPauseMenu and not ToGame then
        Citizen.CreateThread(function()
            Citizen.Wait(50)
            ActivateFrontendMenu(PauseMenuVersion or GetHashKey('FE_MENU_VERSION_MP_PAUSE'), false, -1)
        end)
    end

    -- np-quickmenu (or anything else that opened the map) reopens itself on this
    TriggerEvent('fw-mainmenu:Client:OnMapClosed', From, ToGame)
end

function IsMapOpen() return MapOpen end

-- ---------------------------------------------------------------------
-- NUI callbacks
-- ---------------------------------------------------------------------
RegisterNUICallback('close', function(Data, Cb)
    CloseMap(Data and Data.toGame)
    Cb('ok')
end)

RegisterNUICallback('setWaypoint', function(Data, Cb)
    if Data and Data.x and Data.y then
        SetNewWaypoint(Data.x + 0.0, Data.y + 0.0)
        PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
        RouteFastUntil = GetGameTimer() + 4000
    end
    Cb('ok')
end)

RegisterNUICallback('removeWaypoint', function(_, Cb)
    SetWaypointOff()
    PlaySoundFrontend(-1, 'CANCEL', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
    SendNUIMessage({ action = 'route', route = nil })
    Cb('ok')
end)

-- zone + street for the location box (bottom-left)
RegisterNUICallback('locate', function(Data, Cb)
    if not Data or not Data.x then return Cb({}) end
    local Zone = GetLabelText(GetNameOfZone(Data.x + 0.0, Data.y + 0.0, 0.0))
    if Zone == 'NULL' then Zone = '' end
    local StreetHash = GetStreetNameAtCoord(Data.x + 0.0, Data.y + 0.0, 0.0)
    Cb({ zone = Zone, street = StreetHash ~= 0 and GetStreetNameFromHashKey(StreetHash) or '' })
end)

RegisterNUICallback('sound', function(Data, Cb)
    local Sounds = { nav = 'NAV_UP_DOWN', toggle = 'SELECT' }
    local Sound = Sounds[Data and Data.name or '']
    if Sound then PlaySoundFrontend(-1, Sound, 'HUD_FRONTEND_DEFAULT_SOUNDSET', false) end
    Cb('ok')
end)

-- ---------------------------------------------------------------------
-- Default GTA pause menu: detect "clicked into the map" on the MAP tab
-- (np-quickmenu replaces ESC, so this only matters when it isn't running)
-- ---------------------------------------------------------------------
local function JustPressed(Control)
    return IsControlJustPressed(0, Control) or IsDisabledControlJustPressed(0, Control)
        or IsControlJustPressed(2, Control) or IsDisabledControlJustPressed(2, Control)
end

local function Inside(X, Y, L, R, T, B)
    return X >= L and X <= R and Y >= T and Y <= B
end

local function IsMapScreen(Id)
    for _, V in ipairs(Config.MapScreenIds) do
        if V == Id then return true end
    end
    return false
end

local function HijackMap(Reason)
    if MapOpen or GetGameTimer() < Cooldown then return end
    Log('%s -> opening custom map', Reason)
    PauseMenuVersion = GetCurrentFrontendMenuVersion()
    OpenMap(true, 'pause')   -- the page is drawn above GTA's menu, so show it first...
    SetFrontendActive(false) -- ...then close the menu behind it
end

Citizen.CreateThread(function()
    local L = Config.Layout
    local WasPaused, Tab = false, 0

    while true do
        if IsPauseMenuActive() and not MapOpen then
            Citizen.Wait(0)

            if not WasPaused then
                WasPaused, Tab = true, 0 -- the pause menu always opens on the MAP tab
                Log('pause menu opened (version %s)', GetCurrentFrontendMenuVersion())
            end

            if HasMenuLayoutChangedEventOccurred() then
                local Previous, Current = GetMenuLayoutChangedEventDetails()
                Log('layout changed: previous=%s current=%s', tostring(Previous), tostring(Current))
                if #Config.MapScreenIds > 0 and IsMapScreen(Current) then
                    HijackMap('map screen id ' .. tostring(Current))
                end
            end

            if not MapOpen then
                if JustPressed(205) then Tab = Tab and (Tab - 1) % Config.PauseTabCount; Log('Q -> tab %s', tostring(Tab)) end
                if JustPressed(206) then Tab = Tab and (Tab + 1) % Config.PauseTabCount; Log('E -> tab %s', tostring(Tab)) end

                if JustPressed(237) then -- left click
                    local X, Y = GetControlNormal(2, 239), GetControlNormal(2, 240)
                    if Inside(X, Y, 0.0, 1.0, L.TabBarTop, L.TabBarBottom) then
                        Tab = Inside(X, Y, L.MapTabLeft, L.MapTabRight, L.TabBarTop, L.TabBarBottom) and 0 or nil
                        Log('click on tab bar (%.3f, %.3f) -> tab %s', X, Y, tostring(Tab))
                    elseif Tab == 0 and Inside(X, Y, L.ContentLeft, L.ContentRight, L.ContentTop, L.ContentBottom) then
                        HijackMap(('click in map (%.3f, %.3f)'):format(X, Y))
                    else
                        Log('click (%.3f, %.3f) tab %s - ignored', X, Y, tostring(Tab))
                    end
                elseif Tab == 0 and JustPressed(201) then -- enter on the MAP tab
                    HijackMap('enter on MAP tab')
                end
            end
        else
            WasPaused = false
            Citizen.Wait(150)
        end
    end
end)

-- Blue waypoint / GPS route in GTA's own HUD as well (HUD_COLOUR_WAYPOINT = 142)
Citizen.CreateThread(function()
    local C = Config.WaypointColor
    if C then ReplaceHudColourWithRgba(142, C[1], C[2], C[3], 255) end
end)

RegisterCommand('mapmenudebug', function()
    Debug = not Debug
    print(('[fw-mainmenu] debug %s'):format(Debug and 'ON - info is printed here' or 'OFF'))
    if Debug and IsWaypointActive() then
        for _, C in ipairs(RouteCombos) do
            local A, B = TryRoutePos(C[1], C[2], 30.0), TryRoutePos(C[1], C[2], 250.0)
            print(('[fw-mainmenu] route probe (%s, %d): 30m=%s 250m=%s'):format(tostring(C[1]), C[2],
                A and ('%.0f,%.0f'):format(A.x, A.y) or 'nil', B and ('%.0f,%.0f'):format(B.x, B.y) or 'nil'))
        end
        RouteMode = nil
        local R = GetRoute()
        print(('[fw-mainmenu] route: nativeLength=%s mode=%s points=%s straight=%s'):format(tostring(GetGpsBlipRouteLength()),
            RouteMode and (tostring(RouteMode[1]) .. ',' .. RouteMode[2]) or 'none', R and #R.points or 0, tostring(R and R.straight)))
    end
end, false)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    if MapOpen then SetNuiFocus(false, false); SetHud(true) end
end)

exports('IsMapOpen', IsMapOpen)
exports('OpenMap', OpenMap)
exports('CloseMap', CloseMap)
