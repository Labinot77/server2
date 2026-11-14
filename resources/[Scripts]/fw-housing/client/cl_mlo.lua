-- MLO houses (client): PolyZone furniture streaming, surface colours, stash / wardrobe. Doors are handled by fw-doors.
-- Uses from _cl_main.lua: HasKeyToHouseId, CanRealtor, OpenDoorAnim, HasOverdueDebts, SetMloCurrentHouse
local FW = exports['fw-core']:GetCoreObject()

local MloZones = {}       -- [Key] = PolyZone
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
function GetMloWall(DecorId) return Spawned[DecorId] and Spawned[DecorId].WallObj end
function GetMloDecorIdByEntity(Entity)
    for Id, S in pairs(Spawned) do
        if S.Entity == Entity then return Id end
        for _, P in ipairs(S.WallObj and S.WallObj.Pieces or {}) do
            if P.Entity == Entity then return Id end
        end
    end
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

function HousingLoadModel(Model)
    local Hash = type(Model) == 'string' and GetHashKey(Model) or Model
    if not IsModelInCdimage(Hash) then return false end
    RequestModel(Hash)
    local Timeout = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Timeout do Citizen.Wait(10) end
    return HasModelLoaded(Hash) and Hash or false
end

-- Perm: 'Doors' | 'Stash' | 'Decorate' (owner always). Unowned houses: realtors.
function HasMloAccess(HouseId, Perm)
    local House = Config.Houses and Config.Houses[HouseId]
    if not House then return false end
    if not House.Owned then return CanRealtor() end
    local Cid = FW.Functions.GetPlayerData().citizenid
    if House.Owner == Cid then return true end
    if not HasKeyToHouseId(HouseId) then return false end
    local A = Perm and House.MloData and House.MloData.Access and House.MloData.Access[Cid]
    return not A or A[Perm] ~= false
end

function IsMloOwner(HouseId)
    local House = Config.Houses and Config.Houses[HouseId]
    return House ~= nil and House.Owned and House.Owner == FW.Functions.GetPlayerData().citizenid
end

-- fw-menu checks
exports("CanDecorateMlo", function() return InsideHouseId ~= nil and HasMloAccess(InsideHouseId, 'Decorate') end)
exports("IsMloOwnerInside", function() return InsideHouseId ~= nil and IsMloOwner(InsideHouseId) end)

local function GetDecorType(Decor)
    if Decor.Type then return Decor.Type end
    local Item = Config.DecorByModel[Decor.Model]
    return Item and Item.Type or 'furniture'
end

-- // Surface colours (runtime texture replaces, local to this client) \\ --

local SurfaceTxd, Replaced = nil, {}

local function ColorTexture(Hex)
    local Name = 'c' .. Hex:sub(2)
    SurfaceTxd = SurfaceTxd or CreateRuntimeTxd('fw_housing_surfaces')
    if not Replaced[Name] then
        local R, G, B = tonumber(Hex:sub(2, 3), 16), tonumber(Hex:sub(4, 5), 16), tonumber(Hex:sub(6, 7), 16)
        local Tex = CreateRuntimeTexture(SurfaceTxd, Name, 4, 4)
        for X = 0, 3 do for Y = 0, 3 do SetRuntimeTexturePixel(Tex, X, Y, R, G, B, 255) end end
        CommitRuntimeTexture(Tex)
        Replaced[Name] = true
    end
    return Name
end

function ApplySurfaces(House)
    local Cfg = House and House.Mlo and (Config.MLOHouses[House.Mlo] or {}).Surfaces
    if not Cfg then return end
    local Colors = House.MloData and House.MloData.Surfaces or {}
    for _, Surface in ipairs({ 'Walls', 'Floor', 'Ceiling' }) do
        for _, Tex in ipairs(Cfg[Surface] or {}) do
            RemoveReplaceTexture(Cfg.Txd, Tex)
            if Colors[Surface] then AddReplaceTexture(Cfg.Txd, Tex, 'fw_housing_surfaces', ColorTexture(Colors[Surface])) end
        end
    end
    local T = Config.Walls.Texture
    RemoveReplaceTexture(T[1], T[2])
    if Colors.Walls then AddReplaceTexture(T[1], T[2], 'fw_housing_surfaces', ColorTexture(Colors.Walls)) end
end

local function ClearSurfaces(House)
    local Cfg = House and House.Mlo and (Config.MLOHouses[House.Mlo] or {}).Surfaces
    if not Cfg then return end
    for _, Surface in ipairs({ 'Walls', 'Floor', 'Ceiling' }) do
        for _, Tex in ipairs(Cfg[Surface] or {}) do RemoveReplaceTexture(Cfg.Txd, Tex) end
    end
    RemoveReplaceTexture(Config.Walls.Texture[1], Config.Walls.Texture[2])
end

-- // Walls: invisible anchor (bottom centre) + kit pieces laid out from it \\ --

function LayoutWall(Obj)
    local R = GetEntityRotation(Obj.Anchor, 2)
    for _, P in ipairs(Obj.Pieces) do
        local C = GetOffsetFromEntityInWorldCoords(Obj.Anchor, P.X, 0.0, P.Z)
        SetEntityCoordsNoOffset(P.Entity, C.x, C.y, C.z, false, false, false)
        SetEntityRotation(P.Entity, R.x, R.y, R.z, 2, true)
    end
end

function CreateWall(W, Pos, Rot)
    local Hash = HousingLoadModel(Config.Walls.Anchor)
    if not Hash then return end
    local Obj = { Wall = W, Pieces = {}, Anchor = CreateObjectNoOffset(Hash, Pos.x, Pos.y, Pos.z, false, false, false) }
    SetEntityVisible(Obj.Anchor, false, false)
    SetEntityCollision(Obj.Anchor, false, false)
    FreezeEntityPosition(Obj.Anchor, true)
    SetEntityRotation(Obj.Anchor, Rot.x, Rot.y, Rot.z, 2, true)
    for _, P in ipairs(BuildWallPieces(W)) do
        local PieceHash = HousingLoadModel(P.Model)
        if PieceHash then
            local E = CreateObjectNoOffset(PieceHash, Pos.x, Pos.y, Pos.z, false, false, false)
            FreezeEntityPosition(E, true)
            SetModelAsNoLongerNeeded(PieceHash)
            Obj.Pieces[#Obj.Pieces + 1] = { Entity = E, X = P.X, Z = P.Z }
        end
    end
    LayoutWall(Obj)
    return Obj
end

function DeleteWall(Obj)
    if not Obj then return end
    for _, P in ipairs(Obj.Pieces) do if DoesEntityExist(P.Entity) then DeleteEntity(P.Entity) end end
    if DoesEntityExist(Obj.Anchor) then DeleteEntity(Obj.Anchor) end
end

-- // Decorations (streamed by the PolyZone) \\ --

local function DecorSig(v)
    return ('%s|%.3f|%.3f|%.3f|%.2f|%.2f|%.2f|%s'):format(v.Model, v.Coords.x, v.Coords.y, v.Coords.z, v.Rot.x, v.Rot.y, v.Rot.z, v.Wall and json.encode(v.Wall) or '')
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
    if S.WallObj then DeleteWall(S.WallObj) elseif DoesEntityExist(S.Entity) then DeleteEntity(S.Entity) end
    Spawned[DecorId] = nil
end

local function SpawnDecor(HouseId, Decor, Generation)
    if not Decor.Coords or not Decor.Rot then return end

    if Decor.Type == 'wall' then
        local Obj = Decor.Wall and CreateWall(Decor.Wall, Decor.Coords, Decor.Rot)
        if not Obj then return end
        if Generation ~= LoadGeneration or InsideHouseId ~= HouseId or Spawned[Decor.Id] then return DeleteWall(Obj) end
        Spawned[Decor.Id] = { Entity = Obj.Anchor, WallObj = Obj, Sig = DecorSig(Decor), Type = 'wall' }
        return
    end

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
local DecorPaused = false -- the decorate editor owns the entities while open

local function SyncDecor(HouseId)
    if DecorPaused then return end
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

function SetMloDecorPaused(State)
    DecorPaused = State
    if not State and InsideHouseId then SyncDecor(InsideHouseId) end
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

    local StashCfg = (Config.MLOHouses[House.Mlo] or {}).Stash or {}
    TriggerEvent("fw-misc:Client:PlaySound", 'general.stashOpen')
    FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Stash', 'housing-' .. House.Name, StashCfg.Slots or 30, StashCfg.Weight or 750)
end

local function CreateInteriorInteractions(HouseId)
    ClearInteriorInteractions()
    local House = Config.Houses[HouseId]
    if not House or not House.Locations then return end

    local function Access() return HasMloAccess(HouseId, 'Stash') end

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
        ClearSurfaces(Config.Houses[InsideHouseId])
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
    ApplySurfaces(Config.Houses[HouseId])
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
    if Data == nil then
        if InsideHouseId == HouseId then LeaveCurrent() end
        return
    end

    if not Data.Mlo then return end

    if InsideHouseId == HouseId then
        SetMloCurrentHouse(Data)
        CreateInteriorInteractions(HouseId)
        ApplySurfaces(Data)
        SyncDecor(HouseId)
    elseif InsideKey == Data.Mlo then
        RefreshInside()
    end
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
    print("^5[fw-housing]^7 Paste into FrontDoor / BackDoor Doors:")
    print(("{ Model = %d, Coords = vector3(%.3f, %.3f, %.3f) },"):format(GetEntityModel(Entity), C.x, C.y, C.z))
    FW.Functions.Notify("Door info printed in F8.", "success")
end)

-- // Setup \\ --

-- (Re)builds every zone from Config.MLOHouses. Inside the zone = furniture loaded, outside = furniture deleted.
-- One ComboZone (single 500 ms check) for every house, however many there are.
local Combo = nil
local function BuildZones()
    if InsideKey then OnZoneChange(InsideKey, false) end
    if Combo then Combo:destroy() end
    MloZones = {}
    local List = {}
    for Key, Mlo in pairs(Config.MLOHouses) do
        MloZones[Key] = PolyZone:Create(Mlo.Zone.points, {
            name = Key, minZ = Mlo.Zone.minZ, maxZ = Mlo.Zone.maxZ, debugPoly = Mlo.Zone.debug == true,
        })
        List[#List + 1] = MloZones[Key]
    end
    Combo = nil
    if #List == 0 then return end
    Combo = ComboZone:Create(List, { name = 'fw-housing-mlo' })
    Combo:onPlayerInOut(function(IsInside, _, Zone)
        if IsInside and Zone then OnZoneChange(Zone.name, true) elseif InsideKey then OnZoneChange(InsideKey, false) end
    end, 500)
end

local function SetDefs(Defs)
    for Key in pairs(Config.MLOHouses) do
        if not Defs[Key] then RegisterMloDef(Key, nil) end
    end
    for Key, Def in pairs(Defs) do RegisterMloDef(Key, Def) end
    BuildZones()
end

-- A house was created / edited / deleted with /housecreator.
RegisterNetEvent("fw-housing:Client:Mlo:Reload", function(Defs, Houses)
    if exports['fw-housing']:IsDecorating() then CloseMloEditor() end
    Config.Houses = Houses
    SetDefs(Defs)
end)

Citizen.CreateThread(function()
    -- Houses made in game live on the server, ask for every definition once.
    local Defs
    while not Defs do
        Defs = FW.SendCallback("fw-housing:Server:Mlo:GetDefs")
        if not Defs then Citizen.Wait(2000) end
    end
    SetDefs(Defs)

    -- Waits for the house list.
    while true do
        if InsideKey and not InsideHouseId and Config.Houses and next(Config.Houses) then RefreshInside() end
        Citizen.Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    UnloadDecor()
    if InsideHouseId then ClearSurfaces(Config.Houses[InsideHouseId]) end
    if Combo then Combo:destroy() end
end)
