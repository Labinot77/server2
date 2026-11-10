-- MLO houses (client): physical doors (interact + door system), PolyZone furniture streaming, stash / wardrobe.
-- Uses from _cl_main.lua: HasKeyToHouseId, CanRealtor, OpenDoorAnim, HasOverdueDebts, SetMloCurrentHouse
local FW = exports['fw-core']:GetCoreObject()

local MloZones = {}       -- [Key] = PolyZone
local DoorHashes = {}     -- [Key] = { Front = { hash, ... }, Back = { ... } }
local AccessCache = {}    -- [HouseId] = { Value, Expires }
local DecorDoorOpen = {}  -- [HouseId] = { [DecorId] = true }

local InsideKey, InsideHouseId = nil, nil
local Spawned = {}        -- [DecorId] = { Entity, Sig, InteractId, Type, Rot }
local InteriorInteractions = {}
local LoadGeneration = 0  -- bumps on every unload, so a slow model load can't spawn into a house we already left

-- // Helpers \\ --

function GetMloHouseId(Key)
    if Config.Houses == nil then return nil end
    for k, v in pairs(Config.Houses) do
        if v and v.Mlo == Key then return k end
    end
end

function GetMloInsideHouseId() return InsideHouseId end
function GetMloZone(Key) return MloZones[Key] end
function GetMloDecorEntity(DecorId) return Spawned[DecorId] and Spawned[DecorId].Entity or nil end

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

function HousingLoadModel(Model)
    local Hash = type(Model) == 'string' and GetHashKey(Model) or Model
    if not IsModelInCdimage(Hash) then return false end
    RequestModel(Hash)
    local Timeout = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Timeout do Citizen.Wait(10) end
    return HasModelLoaded(Hash) and Hash or false
end

function HasMloAccess(HouseId)
    local Cached = AccessCache[HouseId]
    if Cached and Cached.Expires > GetGameTimer() then return Cached.Value end

    local House = Config.Houses and Config.Houses[HouseId]
    local Value = House ~= nil and (HasKeyToHouseId(HouseId) or (not House.Owned and CanRealtor())) or false
    AccessCache[HouseId] = { Value = Value, Expires = GetGameTimer() + 1000 }
    return Value
end

local function GetDecorType(Decor)
    if Decor.Type then return Decor.Type end
    local Item = Config.DecorByModel[Decor.Model]
    return Item and Item.Type or 'furniture'
end

-- // Doors (real MLO doors) \\ --

local function GetDoorLocked(House, DoorKey)
    if not House then return true end
    if House.DoorLocks and House.DoorLocks[DoorKey] ~= nil then return House.DoorLocks[DoorKey] end
    return true
end

local function ApplyDoorLocks(House)
    if not House or not House.Mlo or not DoorHashes[House.Mlo] then return end
    for DoorKey, Hashes in pairs(DoorHashes[House.Mlo]) do
        local Locked = GetDoorLocked(House, DoorKey)
        for _, Hash in ipairs(Hashes) do
            if Locked then DoorSystemSetOpenRatio(Hash, 0.0, false, false) end
            DoorSystemSetDoorState(Hash, Locked and 1 or 0, false, true)
        end
    end
end

local function RegisterMloDoors()
    for Key in pairs(Config.MLOHouses) do
        DoorHashes[Key] = {}
        for _, Door in ipairs(GetMloDoorList(Key)) do
            DoorHashes[Key][Door.Key] = {}
            for Index, Entry in ipairs(Door.Data.Doors or {}) do
                local Hash = GetHashKey(('fw-housing:%s:%s:%d'):format(Key, Door.Key, Index))
                local Model = type(Entry.Model) == 'string' and GetHashKey(Entry.Model) or Entry.Model
                if not IsDoorRegisteredWithSystem(Hash) then
                    AddDoorToSystem(Hash, Model, Entry.Coords.x, Entry.Coords.y, Entry.Coords.z, false, false, false)
                end
                DoorSystemSetAutomaticRate(Hash, 1.0, false, false)
                DoorSystemSetDoorState(Hash, 1, false, true) -- locked until the server tells us otherwise
                table.insert(DoorHashes[Key][Door.Key], Hash)
            end
        end
    end
end

local function ToggleMloDoor(Key, DoorKey)
    local HouseId = GetMloHouseId(Key)
    local House = HouseId and Config.Houses[HouseId]
    if not House then return end

    local WasLocked = GetDoorLocked(House, DoorKey)
    if WasLocked and House.Owned and HasOverdueDebts(House.Adress) then
        return FW.Functions.Notify("This house has overdue maintenance fees, pay them first.", "error")
    end

    Citizen.CreateThread(OpenDoorAnim)
    TriggerEvent("fw-misc:Client:PlaySound", 'general.doorKeys')

    local Result = FW.SendCallback("fw-housing:Server:Mlo:ToggleDoor", HouseId, DoorKey)
    if Result and Result.Success then
        FW.Functions.Notify(Result.Locked and "Door locked." or "Door unlocked.", Result.Locked and "error" or "success")
    end
end

local function KnockMloDoor(Key, DoorKey)
    local HouseId = GetMloHouseId(Key)
    if not HouseId then return end

    Citizen.CreateThread(function()
        local Dict = 'timetable@jimmy@doorknock@'
        RequestAnimDict(Dict)
        local Timeout = GetGameTimer() + 2000
        while not HasAnimDictLoaded(Dict) and GetGameTimer() < Timeout do Citizen.Wait(10) end
        TaskPlayAnim(PlayerPedId(), Dict, 'knockdoor_idle', 8.0, 8.0, 2500, 16, 0, false, false, false)
    end)

    TriggerServerEvent("fw-housing:Server:Mlo:Knock", HouseId, DoorKey)
end

local function CreateDoorInteractions()
    for Key in pairs(Config.MLOHouses) do
        for _, Door in ipairs(GetMloDoorList(Key)) do
            local DoorKey = Door.Key
            local Name = DoorKey == 'Front' and 'front door' or 'back door'

            local function State()
                local HouseId = GetMloHouseId(Key)
                if not HouseId then return nil end
                return Config.Houses[HouseId], HouseId
            end

            exports['interact']:AddInteraction({
                name = ('fw-housing:%s:%s'):format(Key, DoorKey),
                coords = Door.Data.Coords,
                distance = 4.0,
                interactDst = 1.6,
                options = {
                    {
                        label = 'Unlock ' .. Name,
                        canInteract = function()
                            local House, HouseId = State()
                            return House ~= nil and GetDoorLocked(House, DoorKey) and HasMloAccess(HouseId)
                        end,
                        action = function() Citizen.CreateThread(function() ToggleMloDoor(Key, DoorKey) end) end,
                    },
                    {
                        label = 'Lock ' .. Name,
                        canInteract = function()
                            local House, HouseId = State()
                            return House ~= nil and not GetDoorLocked(House, DoorKey) and HasMloAccess(HouseId)
                        end,
                        action = function() Citizen.CreateThread(function() ToggleMloDoor(Key, DoorKey) end) end,
                    },
                    {
                        label = 'Knock',
                        canInteract = function()
                            local House, HouseId = State()
                            return House ~= nil and GetDoorLocked(House, DoorKey) and not HasMloAccess(HouseId)
                        end,
                        action = function() KnockMloDoor(Key, DoorKey) end,
                    },
                },
            })
        end
    end
end

-- // Decorations (streamed by the PolyZone) \\ --

local function DecorSig(v)
    return ('%s|%.3f|%.3f|%.3f|%.2f|%.2f|%.2f'):format(v.Model, v.Coords.x, v.Coords.y, v.Coords.z, v.Rot.x, v.Rot.y, v.Rot.z)
end

local function ApplyDecorDoor(DecorId)
    local S = Spawned[DecorId]
    if not S or S.Type ~= 'door' or not DoesEntityExist(S.Entity) then return end
    local Open = InsideHouseId and DecorDoorOpen[InsideHouseId] and DecorDoorOpen[InsideHouseId][DecorId]
    -- Door props pivot on their hinge, so a 90 degree turn opens them.
    SetEntityRotation(S.Entity, S.Rot.x, S.Rot.y, S.Rot.z + (Open and 90.0 or 0.0), 2, true)
end

local function DespawnDecor(DecorId)
    local S = Spawned[DecorId]
    if not S then return end
    if S.InteractId then exports['interact']:RemoveInteraction(S.InteractId) end
    if DoesEntityExist(S.Entity) then DeleteEntity(S.Entity) end
    Spawned[DecorId] = nil
end

local function SpawnDecor(HouseId, Decor, Generation)
    if not Decor.Coords or not Decor.Rot then return end

    local Hash = HousingLoadModel(Decor.Model)
    if Generation ~= LoadGeneration or InsideHouseId ~= HouseId or Spawned[Decor.Id] then return end
    if not Hash then
        return print(("^3[fw-housing]^7 Failed to spawn decoration '%s' (#%s)"):format(tostring(Decor.Model), tostring(Decor.Id)))
    end

    local Obj = CreateObjectNoOffset(Hash, Decor.Coords.x, Decor.Coords.y, Decor.Coords.z, false, false, false)
    SetEntityRotation(Obj, Decor.Rot.x, Decor.Rot.y, Decor.Rot.z, 2, true)
    FreezeEntityPosition(Obj, true)
    SetModelAsNoLongerNeeded(Hash)

    local Type = GetDecorType(Decor)
    Spawned[Decor.Id] = { Entity = Obj, Sig = DecorSig(Decor), Type = Type, Rot = vector3(Decor.Rot.x, Decor.Rot.y, Decor.Rot.z) }

    if Type == 'door' then
        local Min, Max = GetModelDimensions(Hash)
        local DecorId = Decor.Id
        local function IsOpen() return DecorDoorOpen[HouseId] and DecorDoorOpen[HouseId][DecorId] == true end

        Spawned[DecorId].InteractId = exports['interact']:AddLocalEntityInteraction({
            entity = Obj,
            offset = vector3((Min.x + Max.x) / 2, (Min.y + Max.y) / 2, (Min.z + Max.z) / 2),
            distance = 3.0,
            interactDst = 1.6,
            options = {
                { label = 'Open door', canInteract = function() return not IsOpen() end, action = function() TriggerServerEvent("fw-housing:Server:Decor:ToggleDoor", HouseId, DecorId) end },
                { label = 'Close door', canInteract = function() return IsOpen() end, action = function() TriggerServerEvent("fw-housing:Server:Decor:ToggleDoor", HouseId, DecorId) end },
            },
        })
        ApplyDecorDoor(DecorId)
    end
end

-- Only (re)spawns what changed, so placing one object doesn't make the whole house flicker.
local function SyncDecor(HouseId)
    local House = Config.Houses[HouseId]
    if not House or InsideHouseId ~= HouseId then return end

    local Wanted = {}
    for _, v in ipairs(House.Decorations or {}) do
        if v.Id then Wanted[v.Id] = v end
    end

    for DecorId, S in pairs(Spawned) do
        if not Wanted[DecorId] or DecorSig(Wanted[DecorId]) ~= S.Sig then DespawnDecor(DecorId) end
    end

    local Generation = LoadGeneration
    for DecorId, v in pairs(Wanted) do
        if not Spawned[DecorId] then SpawnDecor(HouseId, v, Generation) end
    end
end

local function UnloadDecor()
    LoadGeneration = LoadGeneration + 1
    for DecorId in pairs(Spawned) do DespawnDecor(DecorId) end
    Spawned = {}
end

-- // Stash + wardrobe \\ --

local function ClearInteriorInteractions()
    for _, Id in ipairs(InteriorInteractions) do exports['interact']:RemoveInteraction(Id) end
    InteriorInteractions = {}
end

local function OpenStash(HouseId)
    local House = Config.Houses[HouseId]
    if not House then return end

    local IsLockdown = House.Owned and (exports['fw-cityhall']:IsLockdownActive("housing-" .. House.Owner) or exports['fw-cityhall']:IsLockdownActive("housing-" .. House.DbId))
    local PlayerData = FW.Functions.GetPlayerData()
    if IsLockdown and PlayerData.job.name ~= "police" and PlayerData.job.name ~= "judge" then
        return FW.Functions.Notify("This house is in lockdown!", "error")
    end

    local StashCfg = Config.MLOHouses[House.Mlo].Stash or {}
    TriggerEvent("fw-misc:Client:PlaySound", 'general.stashOpen')
    FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Stash', 'housing-' .. House.Name, StashCfg.Slots or 30, StashCfg.Weight or 750)
end

local function CreateInteriorInteractions(HouseId)
    ClearInteriorInteractions()
    local House = Config.Houses[HouseId]
    if not House or not House.Locations then return end

    local function Access() return HasMloAccess(HouseId) end

    if House.Locations.Stash then
        local C = House.Locations.Stash
        InteriorInteractions[#InteriorInteractions + 1] = exports['interact']:AddInteraction({
            name = 'fw-housing:stash:' .. HouseId,
            coords = vector3(C.x, C.y, C.z), distance = 4.0, interactDst = 1.5,
            options = { { label = 'Stash', canInteract = Access, action = function() OpenStash(HouseId) end } },
        })
    end

    if House.Locations.Wardrobe then
        local C = House.Locations.Wardrobe
        InteriorInteractions[#InteriorInteractions + 1] = exports['interact']:AddInteraction({
            name = 'fw-housing:wardrobe:' .. HouseId,
            coords = vector3(C.x, C.y, C.z), distance = 4.0, interactDst = 1.5,
            options = {
                { label = 'Wardrobe', canInteract = Access, action = function() TriggerEvent('fw-clothes:Client:OpenOutfits', true) end },
                { label = 'Sleep', canInteract = Access, action = function() TriggerServerEvent('fw-apartments:Server:Logout') end },
            },
        })
    end
end

-- // Entering / leaving the zone \\ --

local function LeaveCurrent()
    if InsideHouseId then
        UnloadDecor()
        ClearInteriorInteractions()
        SetMloCurrentHouse(nil)
    end
    InsideHouseId = nil
end

-- Called when the player is (or becomes) inside a zone. Safe to call repeatedly.
local function RefreshInside()
    if not InsideKey then return LeaveCurrent() end

    local HouseId = GetMloHouseId(InsideKey)
    if not HouseId then return end -- houses not loaded yet, the watchdog below retries
    if InsideHouseId == HouseId then return end

    LeaveCurrent()
    InsideHouseId = HouseId
    SetMloCurrentHouse(Config.Houses[HouseId])

    DecorDoorOpen[HouseId] = FW.SendCallback("fw-housing:Server:Decor:GetDoorStates", HouseId) or {}
    if InsideHouseId ~= HouseId then return end -- left while waiting on the server

    CreateInteriorInteractions(HouseId)
    SyncDecor(HouseId)
end

local function OnZoneChange(Key, IsInside)
    if IsInside then
        InsideKey = Key
    elseif InsideKey == Key then
        InsideKey = nil
    end
    RefreshInside()
end

-- // Events \\ --

RegisterNetEvent("fw-housing:Client:SyncHouse")
AddEventHandler("fw-housing:Client:SyncHouse", function(HouseId, Data)
    AccessCache[HouseId] = nil

    if Data == nil then
        if InsideHouseId == HouseId then LeaveCurrent() end
        return
    end

    if not Data.Mlo then return end
    ApplyDoorLocks(Data)

    if InsideHouseId == HouseId then
        SetMloCurrentHouse(Data)
        CreateInteriorInteractions(HouseId)
        SyncDecor(HouseId)
    elseif InsideKey == Data.Mlo then
        RefreshInside()
    end
end)

RegisterNetEvent("fw-housing:Client:Mlo:SetDoorLock")
AddEventHandler("fw-housing:Client:Mlo:SetDoorLock", function(HouseId, DoorKey, Locked)
    local House = Config.Houses and Config.Houses[HouseId]
    if not House then return end

    House.DoorLocks = House.DoorLocks or { Front = true, Back = true }
    House.DoorLocks[DoorKey] = Locked
    if DoorKey == 'Front' then House.Locked = Locked end
    ApplyDoorLocks(House)
end)

RegisterNetEvent("fw-housing:Client:Decor:SetDoorOpen")
AddEventHandler("fw-housing:Client:Decor:SetDoorOpen", function(HouseId, DecorId, Open)
    DecorDoorOpen[HouseId] = DecorDoorOpen[HouseId] or {}
    DecorDoorOpen[HouseId][DecorId] = Open or nil
    if InsideHouseId == HouseId then ApplyDecorDoor(DecorId) end
end)

-- Spawn selection / forced enter: put the player inside the MLO instead of teleporting to a shell.
function EnterMloHouse(House)
    local Mlo = Config.MLOHouses[House.Mlo]
    if not Mlo then return end
    local Spawn = Mlo.Spawn or vector4(Mlo.Center.x, Mlo.Center.y, Mlo.Zone.minZ + 1.0, 0.0)
    SetEntityCoords(PlayerPedId(), Spawn.x, Spawn.y, Spawn.z)
    SetEntityHeading(PlayerPedId(), Spawn.w)
    SetGameplayCamRelativeHeading(0.0)
end

-- /mlodoor (admin): prints door info for sh_mlo.lua
RegisterNetEvent("fw-housing:Client:Mlo:DoorInfo")
AddEventHandler("fw-housing:Client:Mlo:DoorInfo", function()
    local Ped = PlayerPedId()
    local PlyCoords = GetEntityCoords(Ped)
    print(("^5[fw-housing]^7 Your position: vector4(%.2f, %.2f, %.2f, %.2f)"):format(PlyCoords.x, PlyCoords.y, PlyCoords.z, GetEntityHeading(Ped)))

    local Hit, _, Entity = HousingRaycast(10.0, Ped, 16)
    if not Hit or not Entity or Entity == 0 or GetEntityType(Entity) ~= 3 then
        return FW.Functions.Notify("Look at a door. Your position was printed in F8.", "error")
    end

    local C = GetEntityCoords(Entity)
    print("^5[fw-housing]^7 Paste into FrontDoor / BackDoor:")
    print(("Coords = vector3(%.2f, %.2f, %.2f),"):format(C.x, C.y, C.z))
    print(("Doors = { { Model = %d, Coords = vector3(%.2f, %.2f, %.2f) } },"):format(GetEntityModel(Entity), C.x, C.y, C.z))
    FW.Functions.Notify("Door info printed in F8.", "success")
end)

-- // Setup \\ --

Citizen.CreateThread(function()
    RegisterMloDoors()
    CreateDoorInteractions()

    for Key, Mlo in pairs(Config.MLOHouses) do
        MloZones[Key] = PolyZone:Create(Mlo.Zone.points, {
            name = 'fw-housing-mlo-' .. Key,
            minZ = Mlo.Zone.minZ,
            maxZ = Mlo.Zone.maxZ,
            debugPoly = Mlo.Zone.debug == true,
        })

        -- Inside the zone = furniture loaded, outside = furniture deleted.
        MloZones[Key]:onPlayerInOut(function(IsInside)
            OnZoneChange(Key, IsInside)
        end, 500)
    end

    -- Waits for the house list (and re-applies door states once it arrives).
    local Applied = false
    while true do
        if Config.Houses ~= nil and next(Config.Houses) ~= nil then
            if not Applied then
                Applied = true
                for _, House in pairs(Config.Houses) do ApplyDoorLocks(House) end
            end
            if InsideKey and not InsideHouseId then RefreshInside() end
        end
        Citizen.Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    UnloadDecor()
    for _, Zone in pairs(MloZones) do Zone:destroy() end
    for _, Doors in pairs(DoorHashes) do
        for _, Hashes in pairs(Doors) do
            for _, Hash in ipairs(Hashes) do
                if IsDoorRegisteredWithSystem(Hash) then RemoveDoorFromSystem(Hash) end
            end
        end
    end
end)
