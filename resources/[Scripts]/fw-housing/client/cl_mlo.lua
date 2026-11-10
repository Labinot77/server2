-- MLO houses (client): physical doors, interior zone, decoration streaming, stash/wardrobe.
local FW = exports['fw-core']:GetCoreObject()

MloInsideHouseId = nil -- global: read by _cl_main.lua / cl_decorate.lua

local MloZones = {}   -- [Key] = PolyZone
local MloDoors = {}   -- [Key] = { DoorSystemId, ... }
local MloDecor = {}   -- [HouseId] = { Entities = { [DecorId] = Entity }, Snapshot = string }
local DoorStatesApplied = false

-- // Helpers \\ --

function GetMloHouseId(Key)
    if Config.Houses == nil then return nil end
    for k, v in pairs(Config.Houses) do
        if v and v.Mlo == Key then return k end
    end
end

function GetMloZone(Key) return MloZones[Key] end

function GetMloDecorEntity(HouseId, DecorId)
    return MloDecor[HouseId] and MloDecor[HouseId].Entities[DecorId] or nil
end

local function RotationToDirection(Rot)
    local Z, X = math.rad(Rot.z), math.rad(Rot.x)
    local Num = math.abs(math.cos(X))
    return vector3(-math.sin(Z) * Num, math.cos(Z) * Num, math.sin(X))
end

function HousingRaycast(Distance, IgnoreEntity, Flags)
    local CamCoords = GetGameplayCamCoord()
    local Dest = CamCoords + RotationToDirection(GetGameplayCamRot(2)) * Distance
    local Ray = StartExpensiveSynchronousShapeTestLosProbe(CamCoords.x, CamCoords.y, CamCoords.z, Dest.x, Dest.y, Dest.z, Flags or -1, IgnoreEntity or PlayerPedId(), 4)
    local _, Hit, EndCoords, Normal, Entity = GetShapeTestResult(Ray)
    return Hit == 1, EndCoords, Entity, Normal
end

local function LoadModel(Model)
    local Hash = type(Model) == 'string' and GetHashKey(Model) or Model
    if not IsModelInCdimage(Hash) then return false end
    RequestModel(Hash)
    local Timeout = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Timeout do Citizen.Wait(10) end
    return HasModelLoaded(Hash) and Hash or false
end
HousingLoadModel = LoadModel

local function CanUseMloDoor(House)
    if House == nil then return false end
    if HasKeyToHouseId(House.Id) then return true end
    return not House.Owned and CanRealtor()
end

-- // Doors \\ --

local function RegisterMloDoors()
    for Key, Mlo in pairs(Config.MLOHouses) do
        MloDoors[Key] = {}
        for Index, Door in ipairs(Mlo.Doors or {}) do
            local DoorId = GetHashKey(('fw-housing:%s:%d'):format(Key, Index))
            if not IsDoorRegisteredWithSystem(DoorId) then
                local Model = type(Door.Model) == 'string' and GetHashKey(Door.Model) or Door.Model
                AddDoorToSystem(DoorId, Model, Door.Coords.x, Door.Coords.y, Door.Coords.z, false, false, false)
            end
            DoorSystemSetAutomaticRate(DoorId, 1.0, false, false)
            DoorSystemSetDoorState(DoorId, 1, false, true) -- locked until we know better
            MloDoors[Key][Index] = DoorId
        end
    end
end

local function ApplyDoorState(House)
    if not House or not House.Mlo then return end
    for _, DoorId in ipairs(MloDoors[House.Mlo] or {}) do
        DoorSystemSetDoorState(DoorId, House.Locked and 1 or 0, false, true)
    end
end

local function ToggleMloLock(HouseId, Forced)
    local House = Config.Houses[HouseId]
    if not House then return end

    if not Forced and not CanUseMloDoor(House) then
        return FW.Functions.Notify("You don't have keys to this house.", "error")
    end

    if not Forced and HasOverdueDebts(House.Adress) then
        return FW.Functions.Notify("This house has overdue maintenance fees, pay them first.", "error")
    end

    Citizen.CreateThread(OpenDoorAnim)
    TriggerEvent("fw-misc:Client:PlaySound", 'general.doorKeys')

    FW.Functions.TriggerCallback("fw-housing:Server:LockProperty", function(Success)
        if Success then
            FW.Functions.Notify(House.Locked and "House unlocked." or "House locked.", House.Locked and "success" or "error")
        end
    end, HouseId, Forced == true)
end

local function GetNearestMloDoor()
    if Config.Houses == nil then return end
    local Coords = GetEntityCoords(PlayerPedId())
    local Best, BestDist, BestKey = nil, 1.75, nil

    for Key, Mlo in pairs(Config.MLOHouses) do
        for _, Door in ipairs(Mlo.Doors or {}) do
            local Dist = #(Coords - Door.Coords)
            if Dist < BestDist then
                Best, BestDist, BestKey = Door, Dist, Key
            end
        end
    end

    if BestKey then return GetMloHouseId(BestKey), Best end
end

-- // Decorations \\ --

local function UnloadMloDecor(HouseId)
    if not MloDecor[HouseId] then return end
    for _, Entity in pairs(MloDecor[HouseId].Entities) do
        if DoesEntityExist(Entity) then DeleteEntity(Entity) end
    end
    MloDecor[HouseId] = nil
end

local function LoadMloDecor(HouseId)
    local House = Config.Houses[HouseId]
    if not House then return end

    local Decorations = House.Decorations or {}
    local Snapshot = json.encode(Decorations)
    if MloDecor[HouseId] and MloDecor[HouseId].Snapshot == Snapshot then return end

    UnloadMloDecor(HouseId)
    MloDecor[HouseId] = { Entities = {}, Snapshot = Snapshot }

    for Index, v in ipairs(Decorations) do
        local Hash = LoadModel(v.Model)
        if Hash and v.Coords and v.Rot then
            local Obj = CreateObjectNoOffset(Hash, v.Coords.x, v.Coords.y, v.Coords.z, false, false, false)
            SetEntityRotation(Obj, v.Rot.x, v.Rot.y, v.Rot.z, 2, true)
            FreezeEntityPosition(Obj, true)
            SetModelAsNoLongerNeeded(Hash)
            MloDecor[HouseId].Entities[v.Id or Index] = Obj
        else
            print(("^3[fw-housing]^7 Failed to spawn decoration '%s' in %s"):format(tostring(v.Model), House.Adress))
        end
    end
end

RegisterNetEvent("fw-housing:Client:SyncHouse")
AddEventHandler("fw-housing:Client:SyncHouse", function(HouseId, Data)
    if Data == nil then
        UnloadMloDecor(HouseId)
        return
    end

    if not Data.Mlo then return end
    ApplyDoorState(Data)

    if MloDecor[HouseId] then
        LoadMloDecor(HouseId)
    end
end)

-- // Entering (spawn selection) \\ --

function EnterMloHouse(House, Forced)
    local Mlo = Config.MLOHouses[House.Mlo]
    if not Forced or not Mlo or not Mlo.Spawn then return end

    -- Spawned at this house: put the player inside instead of on the porch.
    SetEntityCoords(PlayerPedId(), Mlo.Spawn.x, Mlo.Spawn.y, Mlo.Spawn.z)
    SetEntityHeading(PlayerPedId(), Mlo.Spawn.w)
    SetGameplayCamRelativeHeading(0.0)
end

-- // Inside loop (stash + wardrobe) \\ --

local function StartMloInsideLoop(HouseId)
    Citizen.CreateThread(function()
        while MloInsideHouseId == HouseId do
            local House = Config.Houses[HouseId]
            if not House then break end

            local Sleep = 500
            local MyCoords = GetEntityCoords(PlayerPedId())
            local HasKeys = HasKeyToHouseId(HouseId) or (not House.Owned and CanRealtor())

            if HasKeys and House.Locations.Stash then
                local StashCoords = vector3(House.Locations.Stash.x, House.Locations.Stash.y, House.Locations.Stash.z)
                local Dist = #(MyCoords - StashCoords)

                if Dist <= 1.0 then
                    Sleep = 0
                    DrawText3D(StashCoords, "~g~[E]~s~ Stash")

                    if IsControlJustReleased(0, 38) then
                        local IsLockdown = House.Owned and (exports['fw-cityhall']:IsLockdownActive("housing-" .. House.Owner) or exports['fw-cityhall']:IsLockdownActive("housing-" .. House.DbId))
                        local PlayerData = FW.Functions.GetPlayerData()

                        if IsLockdown and PlayerData.job.name ~= "police" and PlayerData.job.name ~= "judge" then
                            FW.Functions.Notify("This house is in lockdown!", "error")
                        else
                            local StashCfg = Config.MLOHouses[House.Mlo].Stash or {}
                            TriggerEvent("fw-misc:Client:PlaySound", 'general.stashOpen')
                            FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Stash', 'housing-' .. House.Name, StashCfg.Slots or 30, StashCfg.Weight or 750)
                        end
                    end
                elseif Dist <= 3.0 then
                    Sleep = 0
                    DrawText3D(StashCoords, "Stash")
                end
            end

            if HasKeys and House.Locations.Wardrobe then
                local WardrobeCoords = vector3(House.Locations.Wardrobe.x, House.Locations.Wardrobe.y, House.Locations.Wardrobe.z)
                local Dist = #(MyCoords - WardrobeCoords)

                if Dist <= 1.0 then
                    Sleep = 0
                    DrawText3D(WardrobeCoords, "~g~[E]~s~ Wardrobe / ~g~[G]~s~ Sleep")

                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('fw-clothes:Client:OpenOutfits', true)
                    end

                    if IsControlJustPressed(0, 47) then
                        TriggerServerEvent('fw-apartments:Server:Logout')
                    end
                elseif Dist <= 3.0 then
                    Sleep = 0
                    DrawText3D(WardrobeCoords, "Wardrobe / Sleep")
                end
            end

            Citizen.Wait(Sleep)
        end
    end)
end

local function SetInsideMlo(HouseId)
    if MloInsideHouseId == HouseId then return end

    MloInsideHouseId = HouseId
    if HouseId then
        SetHousingCurrentHouse(Config.Houses[HouseId])
        StartMloInsideLoop(HouseId)
    else
        SetHousingCurrentHouse(nil)
    end
end

-- // Setup \\ --

Citizen.CreateThread(function()
    for Key, Mlo in pairs(Config.MLOHouses) do
        MloZones[Key] = PolyZone:Create(Mlo.Zone.points, {
            name = 'fw-housing-mlo-' .. Key,
            minZ = Mlo.Zone.minZ,
            maxZ = Mlo.Zone.maxZ,
            debugPoly = Mlo.Zone.debug == true,
        })
    end

    RegisterMloDoors()

    -- Zone tracking + decoration streaming
    while true do
        if Config.Houses ~= nil then
            if not DoorStatesApplied then
                DoorStatesApplied = true
                for _, House in pairs(Config.Houses) do ApplyDoorState(House) end
            end

            local Coords = GetEntityCoords(PlayerPedId())
            local InsideId = nil

            for Key, Mlo in pairs(Config.MLOHouses) do
                local HouseId = GetMloHouseId(Key)
                if HouseId then
                    local Dist = #(Coords - Mlo.Center)
                    if Dist <= Config.MLODecorLoadDistance then
                        LoadMloDecor(HouseId)
                    elseif Dist > Config.MLODecorLoadDistance + 10.0 then
                        UnloadMloDecor(HouseId)
                    end

                    if MloZones[Key]:isPointInside(Coords) then
                        InsideId = HouseId
                    end
                end
            end

            SetInsideMlo(InsideId)
        end

        Citizen.Wait(500)
    end
end)

-- Door prompt + [E] to (un)lock
Citizen.CreateThread(function()
    while true do
        local HouseId = GetNearestMloDoor()
        if HouseId then
            local Shown = nil
            while HouseId and HouseId == GetNearestMloDoor() do
                local House = Config.Houses[HouseId]
                local HasAccess = CanUseMloDoor(House)
                local Text = (HasAccess and "[E] %s" or "%s"):format(House.Locked and "Locked" or "Unlocked")

                if Shown ~= Text then
                    Shown = Text
                    exports['fw-ui']:ShowInteraction(Text, House.Locked and 'error' or 'success')
                end

                if HasAccess and IsControlJustReleased(0, 38) then
                    ToggleMloLock(HouseId)
                    Citizen.Wait(750)
                end

                Citizen.Wait(0)
            end
            exports['fw-ui']:HideInteraction()
        end

        Citizen.Wait(300)
    end
end)

-- Lockpicking a locked MLO front door (advanced lockpick, same as fw-doors)
RegisterNetEvent("fw-items:Client:UseLockpick")
AddEventHandler("fw-items:Client:UseLockpick", function(IsAdvanced)
    local HouseId = GetNearestMloDoor()
    if not HouseId then return end

    local House = Config.Houses[HouseId]
    if not House.Locked then return FW.Functions.Notify("The door is already open.", "error") end
    if not IsAdvanced then return FW.Functions.Notify("You won't get far with this lockpick..", "error") end

    local Outcome = exports['fw-ui']:StartSkillTest(math.random(3, 6), { 5, 10 }, { 500, 950 }, true)
    if not Outcome then
        exports['fw-assets']:RemoveLockpickChance(IsAdvanced)
        return
    end

    ToggleMloLock(HouseId, true)
end)

RegisterCommand("decorate", function()
    TriggerEvent("fw-housing:Client:OpenFurniture")
end, false)

-- /mlodoor (admin): prints door info for sh_mlo.lua
RegisterNetEvent("fw-housing:Client:Mlo:DoorInfo")
AddEventHandler("fw-housing:Client:Mlo:DoorInfo", function()
    local Ped = PlayerPedId()
    local PlyCoords, Heading = GetEntityCoords(Ped), GetEntityHeading(Ped)
    print(("Entrance = vector4(%.2f, %.2f, %.2f, %.2f),"):format(PlyCoords.x, PlyCoords.y, PlyCoords.z, Heading))

    local Hit, _, Entity = HousingRaycast(10.0, Ped, -1)
    if not Hit or not Entity or Entity == 0 or GetEntityType(Entity) ~= 3 then
        return FW.Functions.Notify("Look at a door. Your position was printed in F8.", "error")
    end

    local Coords = GetEntityCoords(Entity)
    print(("{ Model = %d, Coords = vector3(%.2f, %.2f, %.2f) },"):format(GetEntityModel(Entity), Coords.x, Coords.y, Coords.z))
    FW.Functions.Notify("Door info printed in F8 (console).", "success")
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    for HouseId in pairs(MloDecor) do UnloadMloDecor(HouseId) end
    for _, Zone in pairs(MloZones) do Zone:destroy() end
end)
