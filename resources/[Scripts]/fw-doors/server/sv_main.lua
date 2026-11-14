FW = exports['fw-core']:GetCoreObject()
-- Code

Citizen.CreateThread(function()
    -- Set connected to keys instead of info.
    local function GetDoorIndexByInfo(Info)
        for k, v in pairs(Config.Doors) do
            if v.Info == Info then
                return k
            end
        end
    end

    for k, v in pairs(Config.Doors) do
        if v.Connected ~= nil and next(v.Connected) then
            local NewConnected = {}

            for i, j in pairs(v.Connected) do
                NewConnected[#NewConnected + 1] = GetDoorIndexByInfo(j)
            end

            Config.Doors[k].Connected = NewConnected
        end
    end
end)

-- // Events \\ --

-- Runtime doors (fw-housing) only open for the CitizenIds in their access list.
local function CanUse(Source, Door)
    if not Door.Runtime then return true end
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return false end
    for _, Cid in ipairs(Door.Access.CitizenId) do
        if Cid == Player.PlayerData.citizenid then return true end
    end
    return false
end

local function Changed(DoorId)
    local Door = Config.Doors[DoorId]
    TriggerClientEvent('fw-doors:Client:Sync:Doors', -1, DoorId, Door)
    TriggerEvent('fw-doors:Server:DoorChanged', Door.Info, Door.Locked == 1)
end

RegisterServerEvent('fw-doors:Server:ToggleLockState')
AddEventHandler('fw-doors:Server:ToggleLockState', function(DoorId)
    if Config.Doors[DoorId] ~= nil and CanUse(source, Config.Doors[DoorId]) then
        local CurrentLockState = Config.Doors[DoorId].Locked
        if CurrentLockState == 1 then
            Config.Doors[DoorId].Locked = 0
        else
            Config.Doors[DoorId].Locked = 1
        end
        Changed(DoorId)
    end
end)

RegisterServerEvent('fw-doors:Server:SetLockState')
AddEventHandler('fw-doors:Server:SetLockState', function(DoorId, NewState)
    if Config.Doors[DoorId] ~= nil and CanUse(source, Config.Doors[DoorId]) then
        Config.Doors[DoorId].Locked = NewState
        Changed(DoorId)
    end
end)


RegisterServerEvent('fw-doors:Server:SetLockStateById')
AddEventHandler('fw-doors:Server:SetLockStateById', function(Id, NewState)
    for k, v in pairs(Config.Doors) do
        if v.Info == Id then
            if not CanUse(source, v) then return end
            Config.Doors[k].Locked = NewState
            Changed(k)
            break
        end
    end
end)

-- // Callbacks \\ --
FW.Functions.CreateCallback('fw-doors:Server:GetDoorConfig', function(Source, Cb)
    Cb(Config.Doors)
end)

-- // Runtime door API (not saved to doors.json) \\ --
-- exports['fw-doors']:SetRuntimeDoor({ Info, Model, Coords, Locked = true, CitizenIds = {}, Connected = { Info, ... } })

local function GetIdByInfo(Info)
    for k, v in pairs(Config.Doors) do
        if v.Info == Info then return k end
    end
end

exports('SetRuntimeDoor', function(Data)
    local Id = GetIdByInfo(Data.Info) or #Config.Doors + 1
    local Old = Config.Doors[Id]
    Config.Doors[Id] = {
        Info = Data.Info, Model = Data.Model, Coords = Data.Coords,
        Locked = Old and not Old.Disabled and Old.Locked or (Data.Locked == false and 0 or 1),
        IsGate = false, CanDetcord = false, IsLockpickable = Data.Lockpickable == true, Disabled = false,
        Connected = {}, Runtime = true,
        Access = { Job = {}, CitizenId = Data.CitizenIds or {}, Business = {}, Gangs = {} },
    }
    for _, Info in ipairs(Data.Connected or {}) do
        local Other = GetIdByInfo(Info)
        if Other and Other ~= Id then table.insert(Config.Doors[Id].Connected, Other) end
    end
    TriggerClientEvent('fw-doors:Client:Creator:Register', -1, Id, Config.Doors[Id])
    return Id
end)

exports('SetDoorAccess', function(Info, CitizenIds)
    local Id = GetIdByInfo(Info)
    if not Id then return end
    Config.Doors[Id].Access.CitizenId = CitizenIds
    TriggerClientEvent('fw-doors:Client:Creator:Register', -1, Id, Config.Doors[Id])
end)

exports('SetDoorLocked', function(Info, Locked)
    local Id = GetIdByInfo(Info)
    if not Id or (Config.Doors[Id].Locked == 1) == Locked then return end
    Config.Doors[Id].Locked = Locked and 1 or 0
    Changed(Id)
end)

exports('IsDoorLocked', function(Info)
    local Id = GetIdByInfo(Info)
    return Id and Config.Doors[Id].Locked == 1
end)

-- Turns off every runtime door whose Info starts with Prefix (house deleted / doors changed). SetRuntimeDoor turns them back on.
exports('DisableDoorsByPrefix', function(Prefix)
    for Id, Door in pairs(Config.Doors) do
        if Door.Runtime and Door.Info:sub(1, #Prefix) == Prefix and not Door.Disabled then
            Door.Disabled, Door.Locked, Door.Access.CitizenId = true, 0, {}
            TriggerClientEvent('fw-doors:Client:Creator:Register', -1, Id, Door)
        end
    end
end)
