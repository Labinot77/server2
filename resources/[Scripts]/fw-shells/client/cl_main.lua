-- Streams the saved shells (local props within Config.SpawnDistance), their removed collisions and door passages.
local FW = exports['fw-core']:GetCoreObject()
Shells, EditingId = {}, nil -- EditingId: shell open in the builder (its live copy stays despawned)
local Spawned, Passages, Missing = {}, {}, {}

function LoadModel(Model)
    local Hash = type(Model) == 'string' and GetHashKey(Model) or Model
    if not IsModelInCdimage(Hash) then
        if not Missing[Model] then Missing[Model] = true print(('[fw-shells] model %s is not streamed'):format(Model)) end
        return false
    end
    RequestModel(Hash)
    local Timeout = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Timeout do Wait(10) end
    return HasModelLoaded(Hash) and Hash
end

function WallToWorld(W, X, Y, Z)
    local R = math.rad(W.Heading)
    local Cos, Sin = math.cos(R), math.sin(R)
    return vector3(W.Pos.x + X * Cos - Y * Sin, W.Pos.y + X * Sin + Y * Cos, W.Pos.z + Z)
end

-- World coords > offset along the wall from its centre (X) and through it (Y).
function WallOffset(W, Coords)
    local R = math.rad(W.Heading)
    local Dx, Dy = Coords.x - W.Pos.x, Coords.y - W.Pos.y
    return Dx * math.cos(R) + Dy * math.sin(R), -Dx * math.sin(R) + Dy * math.cos(R)
end

-- Returns { [entity] = wall index }.
function SpawnShell(Shell)
    local Ents = {}
    for I, W in ipairs(Shell.Walls) do
        for _, P in ipairs(BuildShellWall(W)) do
            local Hash = LoadModel(P.Model)
            if Hash then
                local C = WallToWorld(W, P.X, P.Y, P.Z)
                local E = CreateObjectNoOffset(Hash, C.x, C.y, C.z, false, false, P.Kind == 'door')
                SetEntityRotation(E, P.Pitch, 0.0, W.Heading + P.Yaw, 2, true)
                if P.Kind ~= 'door' then FreezeEntityPosition(E, true) end -- doors swing, fw-doors locks them
                if P.Kind == 'glass' then
                    SetEntityVisible(E, false, false) -- keeps its collision
                elseif P.Kind ~= 'door' then
                    SetObjectTextureVariation(E, P.Kind == 'frame' and (Shell.FrameTint or Config.FrameTint) or (Shell.Tint or Config.Tint))
                end
                SetModelAsNoLongerNeeded(Hash)
                Ents[E] = I
            end
        end
    end
    return Ents
end

function DeleteShell(Ents)
    for E in pairs(Ents or {}) do if DoesEntityExist(E) then DeleteEntity(E) end end
end

-- On = remove the collision (or hide the prop). Map props restream, so this runs every second while loaded.
function ApplyRemoved(List, On)
    for _, R in ipairs(List or {}) do
        local C = R.Coords
        if R.Hide then
            if On then CreateModelHide(C.x, C.y, C.z, 0.5, R.Model, true) else RemoveModelHide(C.x, C.y, C.z, 0.5, R.Model, false) end
        else
            local E = GetClosestObjectOfType(C.x, C.y, C.z, 0.5, R.Model, false, false, false)
            if E ~= 0 then SetEntityCollision(E, not On, not On) end
        end
    end
end

function GetShellCenter(Shell)
    local X, Y, Z, N = 0.0, 0.0, 0.0, #Shell.Walls
    for _, W in ipairs(Shell.Walls) do X, Y, Z = X + W.Pos.x, Y + W.Pos.y, Z + W.Pos.z end
    return N > 0 and vector3(X / N, Y / N, Z / N) or nil
end

local function Despawn(Id)
    if not Spawned[Id] then return end
    DeleteShell(Spawned[Id])
    ApplyRemoved(Shells[Id] and Shells[Id].Removed, false)
    Spawned[Id], Passages[Id] = nil, nil
end

RegisterNetEvent('fw-shells:Client:Set', function(Id, Shell)
    Despawn(Id)
    Shells[Id] = Shell
end)

CreateThread(function()
    Shells = FW.SendCallback('fw-shells:Server:GetAll') or {}
    while true do
        local Ped = GetEntityCoords(PlayerPedId())
        for Id, S in pairs(Shells) do
            local C = GetShellCenter(S)
            local Near = C and Id ~= EditingId and #(Ped - C) < Config.SpawnDistance
            if Near and not Spawned[Id] then
                Spawned[Id], Passages[Id] = SpawnShell(S), {}
                for _, W in ipairs(S.Walls) do
                    for _, H in ipairs(W.Holes) do if H.Passage then Passages[Id][#Passages[Id] + 1] = { W = W, H = H } end end
                end
            elseif not Near then
                Despawn(Id)
            end
            if Spawned[Id] then ApplyRemoved(S.Removed, true) end
        end
        Wait(1000)
    end
end)

-- // Pass-through doors: for walls whose collision can't be removed (static map collision) \\ --

local function GoThrough(W, H)
    local Ped = PlayerPedId()
    local Hinge = WallToWorld(W, H.Flip and H.X + H.W / 2 or H.X - H.W / 2, 0.0, 0.0)
    local Found, Door = DoorSystemFindExistingDoor(Hinge.x, Hinge.y, Hinge.z, GetHashKey(H.Model))
    if Found and DoorSystemGetDoorState(Door) == 1 then return FW.Functions.Notify('The door is locked.', 'error') end

    local _, Side = WallOffset(W, GetEntityCoords(Ped))
    local To = WallToWorld(W, H.X, Side > 0 and -0.8 or 0.8, 0.0)
    DoScreenFadeOut(200)
    Wait(250)
    SetEntityCoords(Ped, To.x, To.y, To.z, false, false, false, false)
    SetEntityHeading(Ped, (W.Heading + (Side > 0 and 180.0 or 0.0)) % 360)
    Wait(100)
    DoScreenFadeIn(200)
end

CreateThread(function()
    while true do
        local Sleep, C = 500, GetEntityCoords(PlayerPedId())
        for _, List in pairs(Passages) do
            for _, P in ipairs(List) do
                if #(C - WallToWorld(P.W, P.H.X, 0.0, 1.0)) < 1.5 then
                    Sleep = 0
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Go through')
                    EndTextCommandDisplayHelp(0, false, false, -1)
                    if IsControlJustPressed(0, 38) then GoThrough(P.W, P.H) end
                end
            end
        end
        Wait(Sleep)
    end
end)

AddEventHandler('onResourceStop', function(Res)
    if Res ~= GetCurrentResourceName() then return end
    for Id in pairs(Spawned) do Despawn(Id) end
end)

exports('GetShells', function() return Shells end)
