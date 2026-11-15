-- MLO houses (client): PolyZone furniture streaming, surface colours, storage crates / wardrobes, garage. Doors: fw-doors.
-- Uses from _cl_main.lua: HasKeyToHouseId, CanRealtor, OpenDoorAnim, HasOverdueDebts, SetMloCurrentHouse
local FW = exports['fw-core']:GetCoreObject()

local MloZones = {}       -- [Key] = PolyZone
local DecorDoorOpen = {}  -- [HouseId] = { [DecorId] = true }

local InsideKey, InsideHouseId = nil, nil
local Spawned = {}        -- [DecorId] = { Entity, Sig, InteractId, Type, Rot }
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

-- Owned MLO house (with keys) the player is in or within Config.MLOGarage.MaxDistanceFromZone of.
local function GetGarageHouseId()
    local C = GetEntityCoords(PlayerPedId())
    for HouseId, House in pairs(Config.Houses or {}) do
        if House.Mlo and House.Owned and Config.MLOHouses[House.Mlo] and HasKeyToHouseId(HouseId)
            and (IsPointInMloZone(House.Mlo, C) or GetDistanceToMloZoneEdge(House.Mlo, C) <= Config.MLOGarage.MaxDistanceFromZone) then
            return HouseId
        end
    end
end
exports("CanPlaceMloGarage", function() return GetGarageHouseId() ~= nil end)

-- F1 menu: parks the house garage where the player (or their vehicle) is. The server validates the spot.
RegisterNetEvent("fw-housing:Client:Mlo:PlaceGarage", function()
    local HouseId = GetGarageHouseId()
    if not HouseId then return FW.Functions.Notify("You're not at a house you have keys to.", "error") end
    TriggerServerEvent("fw-housing:Server:Mlo:SetGarage", HouseId)
end)

local function GetDecorType(Decor)
    local Item = GetDecorItem(Decor.Model)
    if Item and (Item.Type == 'crate' or Item.Type == 'wardrobe') then return Item.Type end
    return Decor.Type or Item and Item.Type or 'furniture'
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

-- Surfaces.Txd may be several dictionaries ('a, b'): a .ytd name, or the .ydr name when the textures are embedded in the model.
local function Txds(Cfg)
    local List = {}
    for Name in tostring(Cfg.Txd or ''):gmatch('[^,%s]+') do List[#List + 1] = Name end
    return List
end

local Warned = {}
local function CheckTxds(Cfg)
    for _, Txd in ipairs(Txds(Cfg)) do
        if not Warned[Txd] and not IsModelInCdimage(GetHashKey(Txd)) then
            RequestStreamedTextureDict(Txd, false)
            SetTimeout(2000, function()
                if HasStreamedTextureDictLoaded(Txd) then return SetStreamedTextureDictAsNoLongerNeeded(Txd) end
                Warned[Txd] = true
                print(("^3[fw-housing]^7 Surfaces: texture dictionary '%s' not found. Use the .ytd name, or the .ydr name if the textures are embedded in the interior model (check in CodeWalker)."):format(Txd))
            end)
        end
    end
end

local function ReplaceSurfaces(Cfg, Colors)
    for _, Txd in ipairs(Txds(Cfg)) do
        for _, Surface in ipairs({ 'Walls', 'Floor', 'Ceiling' }) do
            for _, Tex in ipairs(Cfg[Surface] or {}) do
                RemoveReplaceTexture(Txd, Tex)
                if Colors and Colors[Surface] then AddReplaceTexture(Txd, Tex, 'fw_housing_surfaces', ColorTexture(Colors[Surface])) end
            end
        end
    end
end

-- Shell walls / floor / ceiling from the config (built walls are tinted one by one), plus the timecycle (upgrade).
local TimecycleSet = false

function ApplySurfaces(House)
    local Cfg = House and House.Mlo and (Config.MLOHouses[House.Mlo] or {}).Surfaces
    if Cfg then ReplaceSurfaces(Cfg, House.MloData and House.MloData.Surfaces or {}) CheckTxds(Cfg) end
    local Data = House and House.MloData or {}
    local Tc = Data.Upgrades and Data.Upgrades.timecycle and Data.Timecycle
    if Tc and Tc ~= '' then
        SetTimecycleModifier(Tc)
        TimecycleSet = true
    elseif TimecycleSet then
        ClearTimecycleModifier()
        TimecycleSet = false
    end
end

local function ClearSurfaces(House)
    local Cfg = House and House.Mlo and (Config.MLOHouses[House.Mlo] or {}).Surfaces
    if Cfg then ReplaceSurfaces(Cfg, nil) end
    if TimecycleSet then ClearTimecycleModifier() TimecycleSet = false end
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

-- Tint = row of the kit's tint palette (Config.SurfaceColors order), per wall.
function CreateWall(W, Pos, Rot, Tint)
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
            if Tint then SetObjectTextureVariation(E, Tint) end
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
    return ('%s|%.3f|%.3f|%.3f|%.2f|%.2f|%.2f|%s|%d'):format(v.Model, v.Coords.x, v.Coords.y, v.Coords.z, v.Rot.x, v.Rot.y, v.Rot.z, v.Wall and json.encode(v.Wall) or '', v.Tint or 0)
end

local function ApplyDecorDoor(DecorId)
    local S = Spawned[DecorId]
    if not S or S.Type ~= 'door' or not DoesEntityExist(S.Entity) then return end
    local Open = InsideHouseId and DecorDoorOpen[InsideHouseId] and DecorDoorOpen[InsideHouseId][DecorId]
    -- Door props pivot on their hinge, so a 90 degree turn opens them.
    SetEntityRotation(S.Entity, S.Rot.x, S.Rot.y, S.Rot.z + (Open and 90.0 or 0.0), 2, true)
end

-- // Storage crates (one stash each) + wardrobes \\ --

local function OpenCrate(HouseId, DecorId)
    local House = Config.Houses[HouseId]
    if not House then return end

    local IsLockdown = House.Owned and (exports['fw-cityhall']:IsLockdownActive("housing-" .. House.Owner) or exports['fw-cityhall']:IsLockdownActive("housing-" .. House.DbId))
    local PlayerData = FW.Functions.GetPlayerData()
    if IsLockdown and PlayerData.job.name ~= "police" and PlayerData.job.name ~= "judge" then
        return FW.Functions.Notify("This house is in lockdown!", "error")
    end

    local StashCfg = (Config.MLOHouses[House.Mlo] or {}).Stash or {}
    local Bonus = House.MloData and House.MloData.Upgrades and House.MloData.Upgrades.storage and Config.HouseApp.StorageBonus or { Slots = 0, Weight = 0 }
    TriggerEvent("fw-misc:Client:PlaySound", 'general.stashOpen')
    FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Stash', ('housing-%s-%s'):format(House.Name, DecorId), (StashCfg.Slots or 30) + Bonus.Slots, (StashCfg.Weight or 750) + Bonus.Weight)
end

local function StorageOptions(HouseId, DecorId, Type)
    local function Access() return HasMloAccess(HouseId, 'Stash') end
    if Type == 'crate' then
        return { { label = 'Open crate', canInteract = Access, action = function() OpenCrate(HouseId, DecorId) end } }
    end
    return {
        { label = 'Wardrobe', canInteract = Access, action = function() TriggerEvent('fw-clothes:Client:OpenOutfits', true) end },
        { label = 'Sleep', canInteract = Access, action = function() TriggerServerEvent('fw-apartments:Server:Logout') end },
    }
end

local function DespawnDecor(DecorId)
    local S = Spawned[DecorId]
    if not S then return end
    if S.InteractId then exports['interact']:RemoveInteraction(S.InteractId) end
    if S.WallObj then DeleteWall(S.WallObj) elseif DoesEntityExist(S.Entity) then DeleteEntity(S.Entity) end
    Spawned[DecorId] = nil
end

-- Interact on a prop, centred on its model.
local function EntityInteraction(Entity, Options)
    local Min, Max = GetModelDimensions(GetEntityModel(Entity))
    return exports['interact']:AddLocalEntityInteraction({
        entity = Entity,
        offset = vector3((Min.x + Max.x) / 2, (Min.y + Max.y) / 2, (Min.z + Max.z) / 2),
        distance = 3.0,
        interactDst = 1.6,
        options = Options,
    })
end

-- Interact on doors, crates and wardrobes.
local function AddDecorInteraction(DecorId)
    local S = Spawned[DecorId]
    if not S or not DoesEntityExist(S.Entity) then return end
    if S.InteractId then exports['interact']:RemoveInteraction(S.InteractId) S.InteractId = nil end

    local HouseId, Options = S.HouseId, nil
    if S.Type == 'door' then
        local function IsOpen() return DecorDoorOpen[HouseId] and DecorDoorOpen[HouseId][DecorId] == true end
        local function Toggle() TriggerServerEvent("fw-housing:Server:Decor:ToggleDoor", HouseId, DecorId) end
        Options = {
            { label = 'Open door', canInteract = function() return not IsOpen() end, action = Toggle },
            { label = 'Close door', canInteract = IsOpen, action = Toggle },
        }
    elseif S.Type == 'crate' or S.Type == 'wardrobe' then
        Options = StorageOptions(HouseId, DecorId, S.Type)
    end
    if Options then S.InteractId = EntityInteraction(S.Entity, Options) end
end

-- // House tablet: fixed spot set in the house creator (Def.Tablet = { Coords, Rot }), not furniture \\ --

local HouseTablet = nil -- { HouseId, Def, Entity, InteractId }

local function TabletInteraction()
    local T = HouseTablet
    if T.InteractId then exports['interact']:RemoveInteraction(T.InteractId) end
    T.InteractId = EntityInteraction(T.Entity, { {
        label = 'Use tablet',
        canInteract = function() return HasKeyToHouseId(T.HouseId) and not IsHouseTabletOpen() end,
        action = function() OpenHouseTablet(T.HouseId, T.Entity) end,
    } })
end

local function DespawnTablet()
    if not HouseTablet then return end
    if HouseTablet.InteractId then exports['interact']:RemoveInteraction(HouseTablet.InteractId) end
    if DoesEntityExist(HouseTablet.Entity) then DeleteEntity(HouseTablet.Entity) end
    HouseTablet = nil
end

local function SpawnTablet(HouseId)
    local House = Config.Houses[HouseId]
    local Def = House and (Config.MLOHouses[House.Mlo] or {}).Tablet
    if HouseTablet and HouseTablet.HouseId == HouseId and HouseTablet.Def == Def then return end
    DespawnTablet()
    local Hash = Def and HousingLoadModel(Config.Storage.Tablet)
    if not Hash or InsideHouseId ~= HouseId then return end
    local C, R = Def.Coords, Def.Rot
    local Obj = CreateObjectNoOffset(Hash, C.x, C.y, C.z, false, false, false)
    SetEntityRotation(Obj, R.x, R.y, R.z, 2, true)
    FreezeEntityPosition(Obj, true)
    SetModelAsNoLongerNeeded(Hash)
    HouseTablet = { HouseId = HouseId, Def = Def, Entity = Obj }
    TabletInteraction()
end

-- fw-dui swaps the tablet in use to its screen copy (and back). Our props are local, so we respawn it as that model.
exports('SwapDecorModel', function(Entity, Model)
    if not HouseTablet or HouseTablet.Entity ~= Entity then return end
    local Hash = HousingLoadModel(Model)
    if not Hash then return end
    local C, R = GetEntityCoords(Entity), GetEntityRotation(Entity, 2)
    local New = CreateObjectNoOffset(Hash, C.x, C.y, C.z, false, false, false)
    SetEntityRotation(New, R.x, R.y, R.z, 2, true)
    FreezeEntityPosition(New, true)
    SetModelAsNoLongerNeeded(Hash)
    DeleteEntity(Entity)
    HouseTablet.Entity = New
    TabletInteraction()
    return New
end)

local function RegisterSwapper()
    if GetResourceState('fw-dui') == 'started' then exports['fw-dui']:RegisterSwapper('SwapDecorModel') end
end
CreateThread(RegisterSwapper)
AddEventHandler('onClientResourceStart', function(Resource) if Resource == 'fw-dui' then RegisterSwapper() end end)

local function SpawnDecor(HouseId, Decor, Generation)
    if not Decor.Coords or not Decor.Rot then return end

    if Decor.Type == 'wall' then
        local Obj = Decor.Wall and CreateWall(Decor.Wall, Decor.Coords, Decor.Rot, Decor.Tint)
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
    if Decor.Tint then SetObjectTextureVariation(Obj, Decor.Tint) end
    FreezeEntityPosition(Obj, true)
    SetModelAsNoLongerNeeded(Hash)

    local Type = GetDecorType(Decor)
    Spawned[Decor.Id] = { Entity = Obj, Sig = DecorSig(Decor), Type = Type, HouseId = HouseId, Rot = vector3(Decor.Rot.x, Decor.Rot.y, Decor.Rot.z) }
    AddDecorInteraction(Decor.Id)
    if Type == 'door' then ApplyDecorDoor(Decor.Id) end
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

-- // Entering / leaving the zone \\ --

-- Furniture stays for UnloadDelay seconds after leaving, so walking out the door doesn't make it vanish.
local Pending = nil -- { HouseId, Token } of a scheduled unload

local function UnloadNow()
    if Pending then ClearSurfaces(Config.Houses[Pending.HouseId]) end
    Pending = nil
    UnloadDecor()
    DespawnTablet()
end

local function LeaveCurrent(Immediate)
    if InsideHouseId then
        SetMloCurrentHouse(nil)
        local Token = {}
        Pending = { HouseId = InsideHouseId, Token = Token }
        if Immediate then
            UnloadNow()
        else
            SetTimeout((Config.Decorate.UnloadDelay or 5) * 1000, function()
                if Pending and Pending.Token == Token and not InsideHouseId then UnloadNow() end
            end)
        end
    end
    InsideHouseId = nil
end

-- Called when the player is (or becomes) inside a zone. Safe to call repeatedly.
local function RefreshInside()
    if not InsideKey then return LeaveCurrent() end

    local HouseId = GetMloHouseId(InsideKey)
    if not HouseId then return end -- houses not loaded yet, the watchdog below retries
    if InsideHouseId == HouseId then return end

    LeaveCurrent(true)
    if Pending and Pending.HouseId ~= HouseId then UnloadNow() end
    Pending = nil
    InsideHouseId = HouseId
    SetMloCurrentHouse(Config.Houses[HouseId])

    DecorDoorOpen[HouseId] = FW.SendCallback("fw-housing:Server:Decor:GetDoorStates", HouseId) or {}
    if InsideHouseId ~= HouseId then return end -- left while waiting on the server

    ApplySurfaces(Config.Houses[HouseId])
    SyncDecor(HouseId)
    SpawnTablet(HouseId)
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
        if InsideHouseId == HouseId then LeaveCurrent(true) end
        return
    end

    if not Data.Mlo then return end

    if InsideHouseId == HouseId then
        SetMloCurrentHouse(Data)
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
    DespawnTablet()
    if InsideHouseId then ClearSurfaces(Config.Houses[InsideHouseId]) end
    if Combo then Combo:destroy() end
end)
