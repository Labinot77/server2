FW = exports['fw-core']:GetCoreObject()
LoggedIn = false

-- [Id] = { Id, Model, Coords, Rotation, Frozen, Collision, Entity }
local Props = {}
local IsPlacing = false

-- Helpers

local function LoadModel(Model)
    local Hash = type(Model) == 'number' and Model or GetHashKey(Model)
    if not IsModelInCdimage(Hash) or not IsModelValid(Hash) then return false end

    RequestModel(Hash)
    local Timeout = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) do
        if GetGameTimer() > Timeout then return false end
        Citizen.Wait(10)
    end
    return Hash
end

local function RotationToDirection(Rot)
    local X, Z = math.rad(Rot.x), math.rad(Rot.z)
    local Num = math.abs(math.cos(X))
    return vector3(-math.sin(Z) * Num, math.cos(Z) * Num, math.sin(X))
end

local function RaycastFromCamera(Distance, Ignore)
    local CamCoords = GetGameplayCamCoord()
    local Direction = RotationToDirection(GetGameplayCamRot(2))
    local Dest = CamCoords + (Direction * Distance)

    -- Synchronous so it doesn't yield inside the per-frame placement loop
    local Ray = StartExpensiveSynchronousShapeTestLosProbe(CamCoords.x, CamCoords.y, CamCoords.z, Dest.x, Dest.y, Dest.z, 1 + 16, Ignore or PlayerPedId(), 4)
    local _, Hit, EndCoords = GetShapeTestResult(Ray)

    return Hit == 1, EndCoords
end

local function SpawnProp(Prop)
    if Prop.Entity and DoesEntityExist(Prop.Entity) then return end

    local Hash = LoadModel(Prop.Model)
    if not Hash then return print(("[fw-props] Invalid model for prop #%s: %s"):format(Prop.Id, Prop.Model)) end

    local Entity = CreateObjectNoOffset(Hash, Prop.Coords.x, Prop.Coords.y, Prop.Coords.z, false, false, false)
    SetEntityRotation(Entity, Prop.Rotation.x, Prop.Rotation.y, Prop.Rotation.z, 2, true)
    FreezeEntityPosition(Entity, Prop.Frozen)
    SetEntityCollision(Entity, Prop.Collision, Prop.Collision)
    SetEntityInvincible(Entity, true)
    SetModelAsNoLongerNeeded(Hash)

    Prop.Entity = Entity
end

local function DespawnProp(Prop)
    if Prop.Entity and DoesEntityExist(Prop.Entity) then
        DeleteEntity(Prop.Entity)
    end
    Prop.Entity = nil
end

local function ClearAllProps()
    for _, Prop in pairs(Props) do DespawnProp(Prop) end
    Props = {}
end

local function SetProps(List)
    ClearAllProps()
    for _, Prop in pairs(List or {}) do
        Props[Prop.Id] = Prop
    end
end

-- Streaming: only spawn props near the player

Citizen.CreateThread(function()
    while true do
        if LoggedIn then
            local Coords = GetEntityCoords(PlayerPedId())
            for _, Prop in pairs(Props) do
                local InRange = #(Coords - Prop.Coords) < Config.SpawnDistance
                if InRange and not Prop.Entity then
                    SpawnProp(Prop)
                elseif not InRange and Prop.Entity then
                    DespawnProp(Prop)
                end
            end
        end
        Citizen.Wait(1000)
    end
end)

-- Loading

local function FetchProps()
    SetProps(FW.SendCallback("fw-props:Server:GetProps"))
end

RegisterNetEvent('FW:Client:OnPlayerLoaded', function()
    LoggedIn = true
    FetchProps()
end)

RegisterNetEvent('FW:Client:OnPlayerUnload', function()
    LoggedIn = false
    ClearAllProps()
end)

AddEventHandler('onResourceStart', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    Citizen.Wait(1000)
    if FW.Functions.GetPlayerData() and FW.Functions.GetPlayerData().citizenid then
        LoggedIn = true
        FetchProps()
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    ClearAllProps()
end)

RegisterNetEvent('fw-props:Client:SetProps', function(List)
    SetProps(List)
end)

RegisterNetEvent('fw-props:Client:AddProp', function(Prop)
    if Props[Prop.Id] then DespawnProp(Props[Prop.Id]) end
    Props[Prop.Id] = Prop
end)

RegisterNetEvent('fw-props:Client:RemoveProp', function(Id)
    if Props[Id] then
        DespawnProp(Props[Id])
        Props[Id] = nil
    end
end)

-- Placing

local function AskForProp(Model)
    local Choices = {}
    for _, v in ipairs(Config.QuickProps) do Choices[#Choices + 1] = v end

    local YesNo = {
        { Text = 'Yes', Value = 'yes' },
        { Text = 'No', Value = 'no' },
    }

    local Fields = {
        { Label = 'Model (free text)', Icon = 'fas fa-cube', Name = 'Model', Type = 'text', Value = Model or '' },
    }
    if #Choices > 0 then
        Fields[#Fields + 1] = { Label = 'Or pick one', Icon = 'fas fa-list', Name = 'Quick', Type = 'text', Choices = Choices }
    end
    Fields[#Fields + 1] = { Label = 'Frozen', Icon = 'fas fa-snowflake', Name = 'Frozen', Type = 'text', Choices = YesNo }
    Fields[#Fields + 1] = { Label = 'Collision', Icon = 'fas fa-car-crash', Name = 'Collision', Type = 'text', Choices = YesNo }

    local Result = exports['fw-ui']:CreateInput(Fields)

    if not Result then return nil end

    local Picked = (Result.Model and Result.Model ~= '' and Result.Model) or Result.Quick
    if not Picked or Picked == '' then return nil end

    return {
        Model = Picked,
        Frozen = Result.Frozen ~= 'no',
        Collision = Result.Collision ~= 'no',
    }
end

local function HelpText()
    return "[E] Place  [Scroll] Rotate  [SHIFT] Fine  [PgUp/PgDn] Height  [Q] Pitch  [BACKSPACE] Cancel"
end

local function StartPlacing(Options)
    local Hash = LoadModel(Options.Model)
    if not Hash then
        return FW.Functions.Notify(("Invalid model: %s"):format(Options.Model), "error")
    end

    IsPlacing = true

    local Ped = PlayerPedId()
    local StartCoords = GetEntityCoords(Ped)
    local Ghost = CreateObjectNoOffset(Hash, StartCoords.x, StartCoords.y, StartCoords.z, false, false, false)
    SetEntityAlpha(Ghost, 170, false)
    SetEntityCollision(Ghost, false, false)
    FreezeEntityPosition(Ghost, true)
    SetModelAsNoLongerNeeded(Hash)

    local Heading, Pitch, HeightOffset = GetEntityHeading(Ped), 0.0, 0.0
    local Placed = false
    exports['fw-ui']:ShowInteraction(HelpText())

    while IsPlacing do
        Citizen.Wait(0)

        -- Block controls that clash with the placement keys
        DisableControlAction(0, 14, true)  -- scroll weapon down
        DisableControlAction(0, 15, true)  -- scroll weapon up
        DisableControlAction(0, 16, true)
        DisableControlAction(0, 17, true)
        DisableControlAction(0, 24, true)  -- attack
        DisableControlAction(0, 25, true)  -- aim
        DisableControlAction(0, 37, true)  -- weapon wheel
        DisableControlAction(0, 44, true)  -- cover (Q)
        DisableControlAction(0, 38, true)  -- E
        DisableControlAction(0, 140, true) -- melee
        DisableControlAction(0, 177, true) -- backspace

        local Hit, Coords = RaycastFromCamera(Config.PlaceDistance, Ghost)
        if Hit then
            local Step = IsDisabledControlPressed(0, 21) and Config.RotateStepFine or Config.RotateStep

            if IsDisabledControlJustPressed(0, 15) then Heading = Heading + Step end
            if IsDisabledControlJustPressed(0, 14) then Heading = Heading - Step end
            if IsDisabledControlJustPressed(0, 44) then Pitch = (Pitch + 90.0) % 360.0 end
            if IsControlJustPressed(0, 10) then HeightOffset = HeightOffset + Config.HeightStep end -- PAGE UP
            if IsControlJustPressed(0, 11) then HeightOffset = HeightOffset - Config.HeightStep end -- PAGE DOWN

            SetEntityCoordsNoOffset(Ghost, Coords.x, Coords.y, Coords.z + HeightOffset, false, false, false)
            if HeightOffset == 0.0 and Pitch == 0.0 then
                PlaceObjectOnGroundProperly(Ghost)
            end
            SetEntityRotation(Ghost, Pitch, 0.0, Heading, 2, true)
        end

        if IsDisabledControlJustPressed(0, 38) and Hit then
            Placed = true
            IsPlacing = false
        elseif IsDisabledControlJustPressed(0, 177) then
            IsPlacing = false
        end
    end

    exports['fw-ui']:HideInteraction()

    if Placed and DoesEntityExist(Ghost) then
        local Coords, Rotation = GetEntityCoords(Ghost), GetEntityRotation(Ghost, 2)
        TriggerServerEvent("fw-props:Server:PlaceProp", {
            Model = Options.Model,
            Coords = { x = Coords.x, y = Coords.y, z = Coords.z },
            Rotation = { x = Rotation.x, y = Rotation.y, z = Rotation.z },
            Frozen = Options.Frozen,
            Collision = Options.Collision,
        })
    else
        FW.Functions.Notify("Placement cancelled.", "error")
    end

    if DoesEntityExist(Ghost) then DeleteEntity(Ghost) end
end

RegisterNetEvent("fw-props:Client:StartPlacing", function(Model)
    if IsPlacing then return FW.Functions.Notify("You are already placing a prop.", "error") end

    local Options = AskForProp(Model)
    if not Options then return end

    StartPlacing(Options)
end)

-- Deleting

RegisterNetEvent("fw-props:Client:DeleteNearest", function()
    local Coords = GetEntityCoords(PlayerPedId())
    local ClosestId, ClosestDist = nil, Config.DeleteDistance

    for Id, Prop in pairs(Props) do
        local Dist = #(Coords - Prop.Coords)
        if Dist < ClosestDist then
            ClosestId, ClosestDist = Id, Dist
        end
    end

    if not ClosestId then
        return FW.Functions.Notify("No placed prop nearby.", "error")
    end

    TriggerServerEvent("fw-props:Server:DeleteProp", ClosestId)
end)

-- Exports for other resources

exports('GetPlacedProps', function() return Props end)
exports('GetPropEntity', function(Id) local Prop = Props[Id] return Prop and Prop.Entity end)
exports('GetPropIdByEntity', function(Entity)
    for Id, Prop in pairs(Props) do
        if Prop.Entity == Entity then return Id end
    end
end)
exports('IsPlacingProp', function() return IsPlacing end)
