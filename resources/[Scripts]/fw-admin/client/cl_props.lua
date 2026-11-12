-- Placed props (was fw-props): streamed near the player, placed / deleted from the admin panel.
-- Exports for other resources: GetPlacedProps(), GetPropEntity(Id), GetPropIdByEntity(Entity), IsPlacingProp(),
-- SetPropModel(Id, Model) (local only, used by fw-dui to swap a prop to its screen copy)

local Props = {} -- [Id] = { Id, Model, Coords, Rotation, Frozen, Collision, Entity, LocalModel }
local Active, IsPlacing = false, false

-- ── Helpers ────────────────────────────────────────────────────────────────

local function LoadModel(Model)
    local Hash = type(Model) == 'number' and Model or GetHashKey(Model)
    if not IsModelInCdimage(Hash) or not IsModelValid(Hash) then return false end

    RequestModel(Hash)
    local Timeout = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) do
        if GetGameTimer() > Timeout then return false end
        Wait(10)
    end
    return Hash
end

local function RaycastFromCamera(Distance, Ignore)
    local CamCoords, Rot = GetGameplayCamCoord(), GetGameplayCamRot(2)
    local X, Z = math.rad(Rot.x), math.rad(Rot.z)
    local Direction = vector3(-math.sin(Z) * math.abs(math.cos(X)), math.cos(Z) * math.abs(math.cos(X)), math.sin(X))
    local Dest = CamCoords + Direction * Distance

    -- Synchronous so it doesn't yield inside the per-frame placement loop
    local Ray = StartExpensiveSynchronousShapeTestLosProbe(CamCoords.x, CamCoords.y, CamCoords.z, Dest.x, Dest.y, Dest.z, 1 + 16, Ignore or PlayerPedId(), 4)
    local _, Hit, EndCoords = GetShapeTestResult(Ray)
    return Hit == 1, EndCoords
end

-- ── Streaming ──────────────────────────────────────────────────────────────

local function SpawnProp(Prop)
    if Prop.Entity and DoesEntityExist(Prop.Entity) then return end

    local Model = Prop.LocalModel or Prop.Model
    local Hash = LoadModel(Model)
    if not Hash then return print(("[fw-admin] Invalid model for prop #%s: %s"):format(Prop.Id, Model)) end

    local Entity = CreateObjectNoOffset(Hash, Prop.Coords.x, Prop.Coords.y, Prop.Coords.z, false, false, false)
    SetEntityRotation(Entity, Prop.Rotation.x, Prop.Rotation.y, Prop.Rotation.z, 2, true)
    FreezeEntityPosition(Entity, Prop.Frozen)
    SetEntityCollision(Entity, Prop.Collision, Prop.Collision)
    SetEntityInvincible(Entity, true)
    SetModelAsNoLongerNeeded(Hash)
    Prop.Entity = Entity
end

local function DespawnProp(Prop)
    if Prop.Entity and DoesEntityExist(Prop.Entity) then DeleteEntity(Prop.Entity) end
    Prop.Entity = nil
end

local function SetProps(List)
    for _, Prop in pairs(Props) do DespawnProp(Prop) end
    Props = {}
    for _, Prop in pairs(List or {}) do Props[Prop.Id] = Prop end
end

CreateThread(function()
    while true do
        if Active then
            local Coords = GetEntityCoords(PlayerPedId())
            for _, Prop in pairs(Props) do
                local InRange = #(Coords - Prop.Coords) < Config.Props.SpawnDistance
                if InRange and not Prop.Entity then
                    SpawnProp(Prop)
                elseif not InRange and Prop.Entity then
                    DespawnProp(Prop)
                end
            end
        end
        Wait(1000)
    end
end)

local function Start()
    Active = true
    SetProps(FW.SendCallback("fw-admin:Server:Props:Get"))
end

RegisterNetEvent('FW:Client:OnPlayerLoaded', Start)

RegisterNetEvent('FW:Client:OnPlayerUnload', function()
    Active = false
    SetProps({})
end)

CreateThread(function()
    Wait(1000)
    local PlayerData = FW.Functions.GetPlayerData()
    if PlayerData and PlayerData.citizenid then Start() end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource == GetCurrentResourceName() then SetProps({}) end
end)

RegisterNetEvent('fw-admin:Client:Props:Set', SetProps)

RegisterNetEvent('fw-admin:Client:Props:Add', function(Prop)
    if Props[Prop.Id] then DespawnProp(Props[Prop.Id]) end
    Props[Prop.Id] = Prop
end)

RegisterNetEvent('fw-admin:Client:Props:Remove', function(Id)
    if not Props[Id] then return end
    DespawnProp(Props[Id])
    Props[Id] = nil
end)

-- ── Placing (admin panel: Utility > Place Prop) ────────────────────────────

local HELP = "[E] Place  [Scroll] Rotate  [SHIFT] Fine  [PgUp/PgDn] Height  [Q] Pitch  [BACKSPACE] Cancel"
local BLOCKED = { 14, 15, 16, 17, 24, 25, 37, 38, 44, 140, 177 }

local function StartPlacing(Model, Frozen, Collision)
    local Hash = LoadModel(Model)
    if not Hash then return FW.Functions.Notify(("Invalid model: %s"):format(Model), "error") end

    IsPlacing = true
    local Ped = PlayerPedId()
    local Start = GetEntityCoords(Ped)
    local Ghost = CreateObjectNoOffset(Hash, Start.x, Start.y, Start.z, false, false, false)
    SetEntityAlpha(Ghost, 170, false)
    SetEntityCollision(Ghost, false, false)
    FreezeEntityPosition(Ghost, true)
    SetModelAsNoLongerNeeded(Hash)

    local Heading, Pitch, Height, Placed = GetEntityHeading(Ped), 0.0, 0.0, false
    exports['fw-ui']:ShowInteraction(HELP)

    while IsPlacing do
        Wait(0)
        for _, Control in ipairs(BLOCKED) do DisableControlAction(0, Control, true) end

        local Hit, Coords = RaycastFromCamera(Config.Props.PlaceDistance, Ghost)
        if Hit then
            local Step = IsDisabledControlPressed(0, 21) and Config.Props.RotateStepFine or Config.Props.RotateStep
            if IsDisabledControlJustPressed(0, 15) then Heading = Heading + Step end
            if IsDisabledControlJustPressed(0, 14) then Heading = Heading - Step end
            if IsDisabledControlJustPressed(0, 44) then Pitch = (Pitch + 90.0) % 360.0 end
            if IsControlJustPressed(0, 10) then Height = Height + Config.Props.HeightStep end
            if IsControlJustPressed(0, 11) then Height = Height - Config.Props.HeightStep end

            SetEntityCoordsNoOffset(Ghost, Coords.x, Coords.y, Coords.z + Height, false, false, false)
            if Height == 0.0 and Pitch == 0.0 then PlaceObjectOnGroundProperly(Ghost) end
            SetEntityRotation(Ghost, Pitch, 0.0, Heading, 2, true)
        end

        if IsDisabledControlJustPressed(0, 38) and Hit then
            Placed, IsPlacing = true, false
        elseif IsDisabledControlJustPressed(0, 177) then
            IsPlacing = false
        end
    end

    exports['fw-ui']:HideInteraction()

    if Placed then
        local Coords, Rotation = GetEntityCoords(Ghost), GetEntityRotation(Ghost, 2)
        TriggerServerEvent("fw-admin:Server:Props:Place", {
            Model = Model,
            Coords = { x = Coords.x, y = Coords.y, z = Coords.z },
            Rotation = { x = Rotation.x, y = Rotation.y, z = Rotation.z },
            Frozen = Frozen,
            Collision = Collision,
        })
    else
        FW.Functions.Notify("Placement cancelled.", "error")
    end
    DeleteEntity(Ghost)
end

RegisterNetEvent('Admin:Props:Place', function(Result)
    if IsPlacing then return FW.Functions.Notify("You are already placing a prop.", "error") end
    Result = Result or {}

    local Model = (Result.model and Result.model ~= '' and Result.model) or Result.quick
    if not Model or Model == '' then return FW.Functions.Notify("Enter or pick a model.", "error") end

    TriggerEvent('fw-admin:Client:Force:Close') -- the panel would block the placement keys
    CreateThread(function() StartPlacing(Model, Result.frozen ~= 'no', Result.collision ~= 'no') end)
end)

-- ── Deleting (admin panel: Utility > Delete Prop) ──────────────────────────

RegisterNetEvent('Admin:Props:Delete', function(Result)
    local Id = Result and tonumber(Result.id)
    if not Id then
        local Coords, Closest = GetEntityCoords(PlayerPedId()), Config.Props.DeleteDistance
        for PropId, Prop in pairs(Props) do
            local Dist = #(Coords - Prop.Coords)
            if Dist < Closest then Id, Closest = PropId, Dist end
        end
    end

    if not Id then return FW.Functions.Notify("No placed prop nearby.", "error") end
    TriggerServerEvent("fw-admin:Server:Props:Delete", Id)
end)

-- ── Exports ────────────────────────────────────────────────────────────────

exports('GetPlacedProps', function() return Props end)
exports('GetPropEntity', function(Id) return Props[Id] and Props[Id].Entity end)
exports('GetPropIdByEntity', function(Entity)
    for Id, Prop in pairs(Props) do
        if Prop.Entity == Entity then return Id end
    end
end)
exports('IsPlacingProp', function() return IsPlacing end)

-- Shows prop Id as another model on this client only (nil = back to its saved model). The new prop is
-- spawned before the old one is deleted, in the same frame, so it never blinks. Returns the new entity.
exports('SetPropModel', function(Id, Model)
    local Prop = Props[Id]
    if not Prop then return nil end
    Prop.LocalModel = Model
    if not Prop.Entity then return nil end

    if not LoadModel(Model or Prop.Model) then return Prop.Entity end
    local Old = Prop.Entity
    Prop.Entity = nil
    SpawnProp(Prop)
    if DoesEntityExist(Old) then DeleteEntity(Old) end
    return Prop.Entity
end)
