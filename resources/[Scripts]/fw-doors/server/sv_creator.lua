FW = FW or exports['fw-core']:GetCoreObject()
Config = Config or {}
Config.Creator = Config.Creator or {}
Config.Creator.Permissions = Config.Creator.Permissions or { 'admin', 'god' }
Config.Creator.MaxAimDistance = Config.Creator.MaxAimDistance or 10.0
Config.Creator.NearbyRadius = Config.Creator.NearbyRadius or 15.0

-- Door creator: persistent storage + admin events.
-- Doors added in-game are saved to data/doors.json and appended AFTER the doors in
-- config.lua on every start, so config door indices never shift.
-- Edits to config.lua doors are stored as overrides (keyed by Info).

local RESOURCE = GetCurrentResourceName()
local FILE = 'data/doors.json'

local Store = { doors = {}, overrides = {} }
local CustomIndex = {} -- Info -> position in Store.doors

local OVERRIDE_FIELDS = { 'Locked', 'IsGate', 'CanDetcord', 'IsLockpickable', 'Disabled', 'Access' }

-- // Helpers \\ --

local function ToVec(C)
    if type(C) == 'vector3' then return C end
    return vector3(C.x + 0.0, C.y + 0.0, C.z + 0.0)
end

local function FromVec(V)
    return { x = math.floor(V.x * 100 + 0.5) / 100, y = math.floor(V.y * 100 + 0.5) / 100, z = math.floor(V.z * 100 + 0.5) / 100 }
end

local function CleanList(List)
    local Out = {}
    if type(List) ~= 'table' then return Out end
    for _, V in ipairs(List) do
        if V ~= nil and tostring(V) ~= '' then Out[#Out + 1] = V end
    end
    return Out
end

local function CleanAccess(A)
    A = type(A) == 'table' and A or {}
    return {
        Job = CleanList(A.Job),
        CitizenId = CleanList(A.CitizenId),
        Business = CleanList(A.Business),
        Gangs = CleanList(A.Gangs),
    }
end

local function DoorIndexByInfo(Info)
    for K, V in pairs(Config.Doors) do
        if V.Info == Info then return K end
    end
end

local function IsAdmin(Source)
    for _, Perm in ipairs(Config.Creator.Permissions) do
        if FW.Functions.HasPermission(Source, Perm) then return true end
    end
    return IsPlayerAceAllowed(Source, 'command')
end

local function Save()
    local Ok = SaveResourceFile(RESOURCE, FILE, json.encode(Store, { indent = true }), -1)
    if not Ok then print('^1[fw-doors]^7 Failed to write ' .. FILE) end
end

local function RebuildIndex()
    CustomIndex = {}
    for I, D in ipairs(Store.doors) do CustomIndex[D.Info] = I end
end

local function Broadcast(DoorId)
    TriggerClientEvent('fw-doors:Client:Creator:Register', -1, DoorId, Config.Doors[DoorId])
end

-- // Load (runs while the resource starts, before sv_main converts Connected) \\ --

do
    local Raw = LoadResourceFile(RESOURCE, FILE)
    local Ok, Data = pcall(json.decode, Raw or '')
    if Ok and type(Data) == 'table' then
        Store.doors = type(Data.doors) == 'table' and Data.doors or {}
        Store.overrides = type(Data.overrides) == 'table' and Data.overrides or {}
    end
    RebuildIndex()

    -- Overrides for config.lua doors.
    for Info, O in pairs(Store.overrides) do
        local Id = DoorIndexByInfo(Info)
        if Id then
            for _, F in ipairs(OVERRIDE_FIELDS) do
                if O[F] ~= nil then Config.Doors[Id][F] = O[F] end
            end
        end
    end

    -- Custom doors, appended. Connected stays as Info strings; sv_main converts them.
    for _, D in ipairs(Store.doors) do
        Config.Doors[#Config.Doors + 1] = {
            Info = D.Info,
            Coords = ToVec(D.Coords),
            Model = D.Model,
            Locked = D.Locked or 0,
            IsGate = D.IsGate or false,
            CanDetcord = D.CanDetcord or false,
            IsLockpickable = D.IsLockpickable or false,
            Disabled = D.Disabled or false,
            Connected = CleanList(D.Connected),
            Access = CleanAccess(D.Access),
            Custom = true,
        }
    end

    if #Store.doors > 0 then
        print(('^2[fw-doors]^7 Loaded %d custom door(s) from %s'):format(#Store.doors, FILE))
    end
end

-- // Apply settings coming from the menu \\ --

local function ApplySettings(DoorId, S)
    local Door = Config.Doors[DoorId]
    Door.Locked = S.Locked and 1 or 0
    Door.IsGate = S.IsGate == true
    Door.CanDetcord = S.CanDetcord == true
    Door.IsLockpickable = S.IsLockpickable == true
    Door.Access = CleanAccess(S.Access)

    if Door.Custom then
        local Entry = Store.doors[CustomIndex[Door.Info]]
        if Entry then
            Entry.Locked, Entry.IsGate, Entry.CanDetcord = Door.Locked, Door.IsGate, Door.CanDetcord
            Entry.IsLockpickable, Entry.Access = Door.IsLockpickable, Door.Access
        end
    else
        local O = Store.overrides[Door.Info] or {}
        O.Locked, O.IsGate, O.CanDetcord = Door.Locked, Door.IsGate, Door.CanDetcord
        O.IsLockpickable, O.Access = Door.IsLockpickable, Door.Access
        Store.overrides[Door.Info] = O
    end
end

local function SetDisabled(DoorId, Disabled)
    local Door = Config.Doors[DoorId]
    Door.Disabled = Disabled
    if Door.Custom then
        local Entry = Store.doors[CustomIndex[Door.Info]]
        if Entry then Entry.Disabled = Disabled end
    else
        local O = Store.overrides[Door.Info] or {}
        O.Disabled = Disabled
        Store.overrides[Door.Info] = O
    end
end

local function Notify(Source, Msg, Type)
    TriggerClientEvent('FW:Notify', Source, Msg, Type or 'success')
end

-- // Events \\ --

-- Doors: { { Model, Coords }, ... } (1 or 2), Settings: { Info, Locked, IsGate, CanDetcord, IsLockpickable, Access }
RegisterNetEvent('fw-doors:Server:Creator:Add', function(Doors, Settings)
    local Src = source
    if not IsAdmin(Src) then return end
    if type(Doors) ~= 'table' or #Doors < 1 or #Doors > 2 or type(Settings) ~= 'table' then return end

    local Base = tostring(Settings.Info or ''):upper():gsub('[^%w_]', '_')
    if Base == '' then return Notify(Src, 'Door needs a name (Info).', 'error') end

    local Names = {}
    for I = 1, #Doors do
        Names[I] = #Doors == 1 and Base or ('%s_%d'):format(Base, I)
        if DoorIndexByInfo(Names[I]) then
            return Notify(Src, ('A door named %s already exists.'):format(Names[I]), 'error')
        end
        if tonumber(Doors[I].Model) == nil or type(Doors[I].Coords) ~= 'table' and type(Doors[I].Coords) ~= 'vector3' then
            return Notify(Src, 'Invalid door data.', 'error')
        end
    end

    local NewIds = {}
    for I, D in ipairs(Doors) do
        local Coords = ToVec(D.Coords)
        local Entry = {
            Info = Names[I],
            Coords = FromVec(Coords),
            Model = tonumber(D.Model),
            Locked = Settings.Locked and 1 or 0,
            IsGate = Settings.IsGate == true,
            CanDetcord = Settings.CanDetcord == true,
            IsLockpickable = Settings.IsLockpickable == true,
            Disabled = false,
            Connected = {},
            Access = CleanAccess(Settings.Access),
        }
        if #Doors == 2 then Entry.Connected = { Names[I == 1 and 2 or 1] } end

        Store.doors[#Store.doors + 1] = Entry

        local Id = #Config.Doors + 1
        Config.Doors[Id] = {
            Info = Entry.Info, Coords = ToVec(Entry.Coords), Model = Entry.Model, Locked = Entry.Locked,
            IsGate = Entry.IsGate, CanDetcord = Entry.CanDetcord, IsLockpickable = Entry.IsLockpickable,
            Disabled = false, Connected = {}, Access = Entry.Access, Custom = true,
        }
        NewIds[I] = Id
    end

    if #NewIds == 2 then
        Config.Doors[NewIds[1]].Connected = { NewIds[2] }
        Config.Doors[NewIds[2]].Connected = { NewIds[1] }
    end

    RebuildIndex()
    Save()
    for _, Id in ipairs(NewIds) do Broadcast(Id) end

    Notify(Src, ('Saved %s'):format(table.concat(Names, ' + ')))
    print(('^2[fw-doors]^7 %s added door(s): %s'):format(GetPlayerName(Src), table.concat(Names, ', ')))
end)

RegisterNetEvent('fw-doors:Server:Creator:Edit', function(DoorId, Settings)
    local Src = source
    if not IsAdmin(Src) or not Config.Doors[DoorId] or type(Settings) ~= 'table' then return end

    local Ids = { DoorId }
    for _, C in ipairs(Config.Doors[DoorId].Connected or {}) do
        if Config.Doors[C] then Ids[#Ids + 1] = C end
    end

    for _, Id in ipairs(Ids) do ApplySettings(Id, Settings) end
    Save()
    for _, Id in ipairs(Ids) do Broadcast(Id) end
    Notify(Src, ('Updated %s'):format(Config.Doors[DoorId].Info))
end)

RegisterNetEvent('fw-doors:Server:Creator:SetDisabled', function(DoorId, Disabled)
    local Src = source
    if not IsAdmin(Src) or not Config.Doors[DoorId] then return end

    SetDisabled(DoorId, Disabled == true)
    Save()
    Broadcast(DoorId)
    Notify(Src, ('%s %s'):format(Config.Doors[DoorId].Info, Disabled and 'disabled' or 'enabled'))
end)

-- Only for doors made in-game. Removed from the file; stays disabled until restart.
RegisterNetEvent('fw-doors:Server:Creator:Delete', function(DoorId)
    local Src = source
    local Door = Config.Doors[DoorId]
    if not IsAdmin(Src) or not Door then return end
    if not Door.Custom then return Notify(Src, 'Doors from config.lua can only be disabled.', 'error') end

    local Ids = { DoorId }
    for _, C in ipairs(Door.Connected or {}) do
        if Config.Doors[C] and Config.Doors[C].Custom then Ids[#Ids + 1] = C end
    end

    for _, Id in ipairs(Ids) do
        local Pos = CustomIndex[Config.Doors[Id].Info]
        if Pos then table.remove(Store.doors, Pos) RebuildIndex() end
        Config.Doors[Id].Disabled = true
    end

    Save()
    for _, Id in ipairs(Ids) do Broadcast(Id) end
    Notify(Src, ('Deleted %s'):format(Door.Info))
end)

FW.Functions.CreateCallback('fw-doors:Server:Creator:IsAdmin', function(Source, Cb)
    Cb(IsAdmin(Source))
end)
