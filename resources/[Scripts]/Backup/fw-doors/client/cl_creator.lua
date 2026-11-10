-- Door creator menu: /doormenu
-- Aim at a door, press E, fill in the form, done. Saved server-side to data/doors.json.

local Selecting = false

-- // Sync from server (new / edited / disabled doors) \\ --

RegisterNetEvent('fw-doors:Client:Creator:Register', function(DoorId, DoorData)
    if type(DoorData) ~= 'table' then return end
    Config.Doors[DoorId] = DoorData
    if DoorHud and DoorHud.Invalidate then DoorHud.Invalidate(DoorId) end

    if DoorData.Disabled then
        if IsDoorRegisteredWithSystem(DoorId) then
            DoorSystemSetDoorState(DoorId, 0, false, true)
            RemoveDoorFromSystem(DoorId)
        end
        return
    end

    if not IsDoorRegisteredWithSystem(DoorId) then
        local Model = type(DoorData.Model) == 'string' and GetHashKey(DoorData.Model) or DoorData.Model
        AddDoorToSystem(DoorId, Model, DoorData.Coords, false, false, false)
    end

    if DoorData.IsGate then DoorSystemSetAutomaticDistance(DoorId, 8.0, false, true) end
    DoorSystemSetAutomaticRate(DoorId, 1.0, false, false)
    DoorSystemSetDoorState(DoorId, DoorData.Locked, false, true)
    DoorSystemSetHoldOpen(DoorId, DoorData.IsGate)

    -- Re-read access / state for the door the player is looking at.
    if DoorId == CurrentDoor then
        Listening = false
        Wait(50)
        if CurrentDoor == DoorId then ListenForKeypress(DoorId) end
    end
end)

-- // Helpers \\ --

local function RotToDir(Rot)
    local X, Z = math.rad(Rot.x), math.rad(Rot.z)
    local Num = math.abs(math.cos(X))
    return vector3(-math.sin(Z) * Num, math.cos(Z) * Num, math.sin(X))
end

local function AimedObject()
    local CamPos = GetGameplayCamCoord()
    local Dest = CamPos + RotToDir(GetGameplayCamRot(2)) * Config.Creator.MaxAimDistance
    local Ray = StartShapeTestLosProbe(CamPos.x, CamPos.y, CamPos.z, Dest.x, Dest.y, Dest.z, -1, PlayerPedId(), 4)
    local Result, Hit, _, _, Entity = GetShapeTestResult(Ray)
    while Result == 1 do
        Wait(0)
        Result, Hit, _, _, Entity = GetShapeTestResult(Ray)
    end
    if Hit == 1 and Entity ~= 0 and GetEntityType(Entity) == 3 then return Entity end
end

local function Help(Text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(Text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function FindExistingDoor(Entity)
    local Id = GetTargetDoorId(Entity)
    if Id and Config.Doors[Id] then return Id end

    local Pos, Model = GetEntityCoords(Entity), GetEntityModel(Entity)
    for K, V in pairs(Config.Doors) do
        local VModel = type(V.Model) == 'string' and GetHashKey(V.Model) or V.Model
        if V.Coords and VModel and #(V.Coords - Pos) < 0.5 and (VModel == Model or VModel % 0x100000000 == Model % 0x100000000) then
            return K
        end
    end
end

-- Aim mode. Returns { Entity, Model, Coords } or nil when cancelled.
local function SelectDoor(Prompt, Exclude)
    if Selecting then return end
    Selecting = true
    local Picked, Last

    while Selecting do
        Wait(0)
        DisableControlAction(0, 24, true) -- attack
        DisableControlAction(0, 25, true) -- aim
        DisableControlAction(0, 38, true) -- E (so doors don't toggle)

        local Entity = AimedObject()
        if Last and Last ~= Entity then SetEntityDrawOutline(Last, false) Last = nil end

        if Entity and Entity ~= Exclude then
            SetEntityDrawOutline(Entity, true)
            SetEntityDrawOutlineColor(80, 200, 255, 255)
            Last = Entity

            local Existing = FindExistingDoor(Entity)
            local Pos = GetEntityCoords(Entity)
            DrawMarker(2, Pos.x, Pos.y, Pos.z + 1.2, 0, 0, 0, 180.0, 0, 0, 0.2, 0.2, 0.2, 80, 200, 255, 180, false, true, 2, false, nil, nil, false)

            Help(('%s~n~~b~Model~s~ %d%s~n~~INPUT_PICKUP~ Select   ~INPUT_CELLPHONE_CANCEL~ Cancel'):format(
                Prompt, GetEntityModel(Entity), Existing and ('~n~~o~Already a door:~s~ ' .. tostring(Config.Doors[Existing].Info)) or ''))

            if IsDisabledControlJustReleased(0, 38) then
                Picked = { Entity = Entity, Model = GetEntityModel(Entity), Coords = Pos, Existing = Existing }
                Selecting = false
            end
        else
            Help(Prompt .. '~n~Aim at a door object.~n~~INPUT_CELLPHONE_CANCEL~ Cancel')
        end

        if IsControlJustReleased(0, 177) then Selecting = false end
    end

    if Last then SetEntityDrawOutline(Last, false) end
    return Picked
end

local function Split(Str, Numeric)
    local Out = {}
    for Raw in tostring(Str or ''):gmatch('[^,]+') do
        local Part = Raw:gsub('^%s+', ''):gsub('%s+$', '')
        if Part ~= '' then Out[#Out + 1] = (Numeric and tonumber(Part)) or Part end
    end
    return Out
end

local function Join(List) return table.concat(List or {}, ', ') end

-- Form. Defaults = door table (for edit) or nil (new).
local function AskSettings(Defaults, SuggestedName)
    local D = Defaults or { Locked = 1, CanDetcord = true, Access = { Job = { 'police' } } }
    local A = D.Access or {}
    local Fields = {}

    if not Defaults then
        Fields[#Fields + 1] = { Label = 'Door name / Info (e.g. MRPD_FRONT)', Icon = 'fas fa-tag', Name = 'Info', Value = SuggestedName }
    end

    Fields[#Fields + 1] = { Label = 'Jobs (comma separated)', Icon = 'fas fa-briefcase', Name = 'Job', Value = Join(A.Job) }
    Fields[#Fields + 1] = { Label = 'Citizen IDs (comma separated)', Icon = 'fas fa-id-card', Name = 'CitizenId', Value = Join(A.CitizenId) }
    Fields[#Fields + 1] = { Label = 'Businesses (comma separated)', Icon = 'fas fa-building', Name = 'Business', Value = Join(A.Business) }
    Fields[#Fields + 1] = { Label = "Gang IDs (comma separated, 'all' = every gang)", Icon = 'fas fa-users', Name = 'Gangs', Value = Join(A.Gangs) }
    Fields[#Fields + 1] = { _Type = 'Checkbox', Label = 'Locked', Name = 'Locked', Value = D.Locked == 1 }
    Fields[#Fields + 1] = { _Type = 'Checkbox', Label = 'Gate (8m range, auto-open)', Name = 'IsGate', Value = D.IsGate == true }
    Fields[#Fields + 1] = { _Type = 'Checkbox', Label = 'Lockpickable', Name = 'IsLockpickable', Value = D.IsLockpickable == true }
    Fields[#Fields + 1] = { _Type = 'Checkbox', Label = 'Can be detcorded', Name = 'CanDetcord', Value = D.CanDetcord == true }

    Wait(100)
    local R = exports['fw-ui']:CreateInput(Fields)
    if not R then return end

    return {
        Info = R.Info,
        Locked = R.Locked == true,
        IsGate = R.IsGate == true,
        IsLockpickable = R.IsLockpickable == true,
        CanDetcord = R.CanDetcord == true,
        Access = {
            Job = Split(R.Job),
            CitizenId = Split(R.CitizenId),
            Business = Split(R.Business),
            Gangs = Split(R.Gangs, true),
        },
    }
end

local function SuggestName(Coords)
    return ('%s_%d'):format(GetNameOfZone(Coords.x, Coords.y, Coords.z), GetGameTimer() % 10000)
end

local function DoorMenuItems(DoorId)
    local Door = Config.Doors[DoorId]
    local Items = {
        { Icon = 'pen', Title = 'Edit access & settings', Desc = 'Applies to connected doors too.', Data = { Event = 'fw-doors:Client:Creator:Edit', Type = 'Client', DoorId = DoorId } },
        { Icon = 'lock', Title = 'Toggle lock', Data = { Event = 'fw-doors:Client:Creator:Toggle', Type = 'Client', DoorId = DoorId } },
        { Icon = Door.Disabled and 'toggle-on' or 'toggle-off', Title = Door.Disabled and 'Enable door' or 'Disable door', Data = { Event = 'fw-doors:Client:Creator:Disable', Type = 'Client', DoorId = DoorId, Disabled = not Door.Disabled } },
    }
    if Door.Custom then
        Items[#Items + 1] = { Icon = 'trash', Title = 'Delete door', Desc = 'Removes it from data/doors.json.', Data = { Event = 'fw-doors:Client:Creator:Delete', Type = 'Client', DoorId = DoorId } }
    end
    return Items
end

-- // Menu \\ --

RegisterNetEvent('fw-doors:Client:Creator:Open', function()
    local Pos = GetEntityCoords(PlayerPedId())
    local Near = {}
    for K, V in pairs(Config.Doors) do
        if V.Coords then
            local Dist = #(Pos - V.Coords)
            if Dist <= Config.Creator.NearbyRadius then Near[#Near + 1] = { Id = K, Dist = Dist } end
        end
    end
    table.sort(Near, function(A, B) return A.Dist < B.Dist end)

    local NearItems = {}
    for _, N in ipairs(Near) do
        local V = Config.Doors[N.Id]
        NearItems[#NearItems + 1] = {
            Icon = V.Disabled and 'ban' or (V.Locked == 1 and 'lock' or 'lock-open'),
            Title = ('%s%s'):format(V.Info or ('#' .. N.Id), V.Custom and ' <small>(in-game)</small>' or ''),
            Desc = ('#%d · %.1fm · %s%s'):format(N.Id, N.Dist, V.Locked == 1 and 'Locked' or 'Unlocked', V.Disabled and ' · DISABLED' or ''),
            SecondMenu = DoorMenuItems(N.Id),
        }
    end

    local Items = {
        { Icon = 'door-closed', Title = 'Door Creator', Desc = 'Aim at a door and press E to select it.', Data = { Event = '', Type = '' }, CloseMenu = false },
        { Icon = 'plus', Title = 'Add single door', Data = { Event = 'fw-doors:Client:Creator:AddSingle', Type = 'Client' } },
        { Icon = 'columns', Title = 'Add double door', Desc = 'Select both halves; they lock together.', Data = { Event = 'fw-doors:Client:Creator:AddDouble', Type = 'Client' } },
        { Icon = 'crosshairs', Title = 'Edit door I aim at', Data = { Event = 'fw-doors:Client:Creator:EditAimed', Type = 'Client' } },
    }

    if #NearItems > 0 then
        Items[#Items + 1] = { Icon = 'list', Title = ('Doors nearby (%d)'):format(#NearItems), Desc = ('Within %dm'):format(Config.Creator.NearbyRadius), SecondMenu = NearItems }
    else
        Items[#Items + 1] = { Icon = 'list', Title = 'Doors nearby (0)', Desc = 'No doors within range.', Data = { Event = '', Type = '' }, CloseMenu = false }
    end

    FW.Functions.OpenMenu({ MainMenuItems = Items })
end)

RegisterNetEvent('fw-doors:Client:Creator:AddSingle', function()
    Wait(100)
    local Door = SelectDoor('~b~Add door~s~')
    if not Door then return end
    if Door.Existing then return FW.Functions.Notify(('That is already door %s.'):format(Config.Doors[Door.Existing].Info), 'error') end

    local S = AskSettings(nil, SuggestName(Door.Coords))
    if not S then return end
    TriggerServerEvent('fw-doors:Server:Creator:Add', { { Model = Door.Model, Coords = Door.Coords } }, S)
end)

RegisterNetEvent('fw-doors:Client:Creator:AddDouble', function()
    Wait(100)
    local A = SelectDoor('~b~Double door~s~ - select the FIRST half')
    if not A then return end
    if A.Existing then return FW.Functions.Notify(('That is already door %s.'):format(Config.Doors[A.Existing].Info), 'error') end

    Wait(250)
    local B = SelectDoor('~b~Double door~s~ - select the SECOND half', A.Entity)
    if not B then return end
    if B.Existing then return FW.Functions.Notify(('That is already door %s.'):format(Config.Doors[B.Existing].Info), 'error') end

    local S = AskSettings(nil, SuggestName(A.Coords))
    if not S then return end
    TriggerServerEvent('fw-doors:Server:Creator:Add', {
        { Model = A.Model, Coords = A.Coords },
        { Model = B.Model, Coords = B.Coords },
    }, S)
end)

RegisterNetEvent('fw-doors:Client:Creator:EditAimed', function()
    Wait(100)
    local Door = SelectDoor('~b~Edit door~s~')
    if not Door then return end
    if not Door.Existing then return FW.Functions.Notify('That object is not a door yet. Use "Add door".', 'error') end
    TriggerEvent('fw-doors:Client:Creator:Edit', { DoorId = Door.Existing })
end)

RegisterNetEvent('fw-doors:Client:Creator:Edit', function(Data)
    local Door = Config.Doors[Data.DoorId]
    if not Door then return end
    local S = AskSettings(Door)
    if not S then return end
    TriggerServerEvent('fw-doors:Server:Creator:Edit', Data.DoorId, S)
end)

RegisterNetEvent('fw-doors:Client:Creator:Toggle', function(Data)
    local Door = Config.Doors[Data.DoorId]
    if not Door then return end
    TriggerServerEvent('fw-doors:Server:ToggleLockState', Data.DoorId)
    for _, C in ipairs(Door.Connected or {}) do TriggerServerEvent('fw-doors:Server:ToggleLockState', C) end
end)

RegisterNetEvent('fw-doors:Client:Creator:Disable', function(Data)
    TriggerServerEvent('fw-doors:Server:Creator:SetDisabled', Data.DoorId, Data.Disabled)
end)

RegisterNetEvent('fw-doors:Client:Creator:Delete', function(Data)
    TriggerServerEvent('fw-doors:Server:Creator:Delete', Data.DoorId)
end)
