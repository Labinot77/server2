-- // Ground items \\ --
-- Every item on the ground is its own prop with its own interact point ("Oppakken ...").
-- Standing on top of one (Config.DropOpenDistance) and opening the inventory shows that
-- drop in the GROUND panel.

Config.DropRenderDistance = 35.0
Config.DropOpenDistance = 1.5
Config.DropInteract = { Distance = 4.0, InteractDst = 1.5 }

local Spawned = {} -- [DropId] = { [Slot] = { Entity, Interaction, Sig } }
local PickupCooldown = false

-- // Models (ported from ox_inventory resolveItemModel) \\ --
local ModelCache = {}

local function ValidModel(Hash)
    return Hash and Hash ~= 0 and IsModelValid(Hash) and IsModelInCdimage(Hash)
end

local function TryModel(Model)
    if not Model then return end
    local Hash = type(Model) == 'number' and Model or GetHashKey(Model)
    if ValidModel(Hash) then return Hash end
end

function ResolveItemModel(ItemName)
    if ModelCache[ItemName] then return ModelCache[ItemName] end

    local Name = ItemName:lower()
    local Hash = TryModel(Config.DropPropsOverride[Name]) or TryModel(Config.DropProps[Name])

    if not Hash and Name:find('^weapon_') then
        Hash = TryModel(GetWeapontypeModel(GetHashKey(Name:upper())))
    end

    Hash = Hash or TryModel(Name)

    if not Hash then
        for _, Guess in ipairs(Config.DropPropsGuess) do
            if Name:find(Guess[1], 1, true) then
                Hash = TryModel(Guess[2])
                if Hash then break end
            end
        end
    end

    Hash = Hash or GetHashKey(Config.DropPropDefault)
    ModelCache[ItemName] = Hash
    return Hash
end
exports("ResolveItemModel", ResolveItemModel)

function LoadModelTimeout(Hash, Timeout)
    if not ValidModel(Hash) then return false end
    RequestModel(Hash)
    local Started = GetGameTimer()
    while not HasModelLoaded(Hash) do
        if GetGameTimer() - Started > (Timeout or 2500) then return false end
        Citizen.Wait(10)
    end
    return true
end

function LoadAnimDictTimeout(Dict)
    RequestAnimDict(Dict)
    local Started = GetGameTimer()
    while not HasAnimDictLoaded(Dict) and GetGameTimer() - Started < 2000 do Citizen.Wait(10) end
    return HasAnimDictLoaded(Dict)
end

-- // Line of sight \\ --
-- Ray from the player's head to the item. Ground props have no collision, so anything the
-- ray hits before reaching the item (wall, floor, door, prop) means it's out of sight.
local LosCache = {} -- [key] = { Time, Result }

function HasLineOfSightTo(Pos, CacheKey)
    if not Config.DropRequireLineOfSight then return true end

    local Now = GetGameTimer()
    local Cached = CacheKey and LosCache[CacheKey]
    if Cached and Now - Cached[1] < 250 then return Cached[2] end

    local Ped = PlayerPedId()
    local From = GetPedBoneCoords(Ped, 31086, 0.0, 0.0, 0.0) -- SKEL_Head
    local To = vector3(Pos.x, Pos.y, Pos.z + 0.15)            -- just above the item, not inside the surface it lies on

    local Handle = StartExpensiveSynchronousShapeTestLosProbe(From.x, From.y, From.z, To.x, To.y, To.z, 1 | 16, Ped, 7)
    local _, Hit, HitCoords = GetShapeTestResult(Handle)

    -- Nothing in between, or the hit is right at the item (the table/floor it's on).
    local Result = not (Hit == 1 or Hit == true) or #(HitCoords - To) < 0.08

    if CacheKey then LosCache[CacheKey] = { Now, Result } end
    return Result
end
exports("HasLineOfSightTo", HasLineOfSightTo)

local function GetSpawnedPosition(DropId, Drop, Slot)
    local Data = Spawned[DropId] and Spawned[DropId][Slot]
    if Data and DoesEntityExist(Data.Entity) then return GetEntityCoords(Data.Entity) end
    return (GetDropItemPosition(Drop, Slot))
end

local function CanSeeDropItem(DropId, Slot)
    local Drop = Config.Drops[DropId]
    if not Drop or not Drop.Slots or not Drop.Slots[Slot] then return false end
    return HasLineOfSightTo(GetSpawnedPosition(DropId, Drop, Slot), DropId .. ':' .. Slot)
end

local function GetLabel(Item, CustomType)
    local ItemData = Shared.Items[Item]
    local Label = ItemData and ItemData.Label or Item
    if CustomType and #CustomType > 0 and Shared.CustomTypes and Shared.CustomTypes[Item] and Shared.CustomTypes[Item][CustomType] then
        Label = Shared.CustomTypes[Item][CustomType].Label or Label
    end
    return Label
end

-- // Positions \\ --
-- Placed/thrown items have their own spot. Items dragged into the ground inventory are
-- spread around the drop centre on a sunflower pattern so they never stack on each other.
function GetDropItemPosition(Drop, Slot)
    local Props = Drop.Props and Drop.Props[Slot]
    if Props and Props.Coords then
        return vector3(Props.Coords.x, Props.Coords.y, Props.Coords.z), Props.Heading or 0.0, Props.Exact
    end

    local Angle = math.rad(Slot * 137.5)
    local Radius = 0.3 + 0.14 * math.sqrt(Slot)
    local C = Drop.Coords
    return vector3(C.x + math.cos(Angle) * Radius, C.y + math.sin(Angle) * Radius, C.z), (Slot * 47) % 360 + 0.0, false
end

-- // Spawning \\ --
local function RemoveInteraction(Id)
    if Id then pcall(function() exports.interact:RemoveInteraction(Id) end) end
end

local function DespawnSlot(DropId, Slot)
    local DropProps = Spawned[DropId]
    local Data = DropProps and DropProps[Slot]
    if not Data then return end

    RemoveInteraction(Data.Interaction)
    if DoesEntityExist(Data.Entity) then DeleteEntity(Data.Entity) end
    DropProps[Slot] = nil
    LosCache[DropId .. ':' .. Slot] = nil
end

local function DespawnDrop(DropId)
    if not Spawned[DropId] then return end
    for Slot in pairs(Spawned[DropId]) do DespawnSlot(DropId, Slot) end
    Spawned[DropId] = nil
end

local function SlotSignature(Drop, Slot, Data)
    local P = Drop.Props and Drop.Props[Slot]
    local PropSig = P and P.Coords and ('%.2f,%.2f,%.2f,%.1f'):format(P.Coords.x, P.Coords.y, P.Coords.z, P.Heading or 0.0) or 'auto'
    return ('%s|%s|%s|%s'):format(Data.Item, Data.CustomType or '', Data.Amount or 1, PropSig)
end

local function SpawnSlot(DropId, Drop, Slot, Data)
    local Model = ResolveItemModel(Data.Item)
    if not LoadModelTimeout(Model) then
        Model = GetHashKey(Config.DropPropDefault)
        if not LoadModelTimeout(Model) then return end
    end

    -- The drop may have changed while the model loaded.
    if not Config.Drops[DropId] or Config.Drops[DropId] ~= Drop then return SetModelAsNoLongerNeeded(Model) end

    local Pos, Heading, Exact = GetDropItemPosition(Drop, Slot)
    RequestCollisionAtCoord(Pos.x, Pos.y, Pos.z)

    local Entity = CreateObject(Model, Pos.x, Pos.y, Pos.z, false, false, false)
    SetModelAsNoLongerNeeded(Model)
    if not Entity or Entity == 0 then return end

    SetEntityHeading(Entity, Heading)
    if Exact then
        SetEntityCoordsNoOffset(Entity, Pos.x, Pos.y, Pos.z, false, false, false)
    else
        PlaceObjectOnGroundProperly(Entity)
    end
    FreezeEntityPosition(Entity, true)
    SetEntityCollision(Entity, false, true)
    SetEntityInvincible(Entity, true)

    local Label = GetLabel(Data.Item, Data.CustomType)
    if (Data.Amount or 1) > 1 then Label = ('%s (%dx)'):format(Label, Data.Amount) end

    local Ok, Interaction = pcall(function()
        return exports.interact:AddLocalEntityInteraction({
            entity = Entity,
            offset = vec3(0.0, 0.0, 0.1),
            distance = Config.DropInteract.Distance,
            interactDst = Config.DropInteract.InteractDst,
            name = ('fw-inventory:drop:%s:%s'):format(DropId, Slot),
            options = {
                {
                    label = ('Oppakken %s'):format(Label),
                    action = function()
                        PickupDropItem(DropId, Slot)
                    end,
                    canInteract = function()
                        return not IsHoldingItem and not CurrentInventory and CanSeeDropItem(DropId, Slot)
                    end,
                },
            },
        })
    end)

    if not Ok then
        print(("^3[fw-inventory] interact export failed, ground item %s:%s has no pickup prompt (%s)^7"):format(DropId, Slot, tostring(Interaction)))
        Interaction = nil
    end

    Spawned[DropId] = Spawned[DropId] or {}
    Spawned[DropId][Slot] = { Entity = Entity, Interaction = Interaction, Sig = SlotSignature(Drop, Slot, Data) }
end

local function DoRefreshDrop(DropId)
    local Drop = Config.Drops[DropId]
    if not Drop or not Drop.Slots or not Drop.Coords or (Drop.ItemCount or 0) <= 0 then
        return DespawnDrop(DropId)
    end

    local C = Drop.Coords
    if #(GetEntityCoords(PlayerPedId()) - vector3(C.x, C.y, C.z)) > Config.DropRenderDistance then
        return DespawnDrop(DropId)
    end

    -- Remove slots that are gone / changed.
    for Slot, Data in pairs(Spawned[DropId] or {}) do
        local SlotData = Drop.Slots[Slot]
        if not SlotData or SlotSignature(Drop, Slot, SlotData) ~= Data.Sig or not DoesEntityExist(Data.Entity) then
            DespawnSlot(DropId, Slot)
        end
    end

    for Slot, SlotData in pairs(Drop.Slots) do
        if not (Spawned[DropId] and Spawned[DropId][Slot]) then
            SpawnSlot(DropId, Drop, Slot, SlotData)
        end
    end
end

-- Model loading yields, so the stream loop and a sync event could refresh the same drop
-- at the same time and spawn a prop twice. Serialise per drop, re-run if it changed meanwhile.
local Refreshing, Dirty = {}, {}
function RefreshDrop(DropId)
    if Refreshing[DropId] then Dirty[DropId] = true return end
    Refreshing[DropId] = true
    repeat
        Dirty[DropId] = nil
        local Ok, Err = pcall(DoRefreshDrop, DropId)
        if not Ok then print(("^1[fw-inventory] drop %s: %s^7"):format(DropId, Err)) end
    until not Dirty[DropId]
    Refreshing[DropId] = nil
end

-- Closest drop that has an item within MaxDistance of the player (used when opening the inventory).
function GetClosestDropId(MaxDistance)
    MaxDistance = MaxDistance or Config.DropOpenDistance
    local PlyPos = GetEntityCoords(PlayerPedId())
    local BestId, BestDist = false, MaxDistance

    for DropId, Drop in pairs(Config.Drops) do
        if Drop.Slots and Drop.Coords and (Drop.ItemCount or 0) > 0 then
            local C = Drop.Coords
            if #(PlyPos - vector3(C.x, C.y, C.z)) < Config.DropRenderDistance then
                for Slot in pairs(Drop.Slots) do
                    local Pos = GetSpawnedPosition(DropId, Drop, Slot)
                    -- Compare on the ground plane + a little height so items on a table still count.
                    local Dist = #(vector2(PlyPos.x, PlyPos.y) - vector2(Pos.x, Pos.y))
                    if Dist <= BestDist and math.abs(PlyPos.z - Pos.z) < 2.5 and HasLineOfSightTo(Pos) then
                        BestId, BestDist = DropId, Dist
                    end
                end
            end
        end
    end

    return BestId
end
exports("GetClosestDropId", GetClosestDropId)

-- // Pickup \\ --
function PickupDropItem(DropId, Slot)
    if PickupCooldown or IsHoldingItem or CurrentInventory then return end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end

    local PlayerData = FW.Functions.GetPlayerData()
    if PlayerData.metadata.isdead or PlayerData.metadata.ishandcuffed then return end

    -- Fresh check (canInteract can be a few frames old).
    LosCache[DropId .. ':' .. Slot] = nil
    if not CanSeeDropItem(DropId, Slot) then return end

    PickupCooldown = true
    Citizen.SetTimeout(900, function() PickupCooldown = false end)

    local Spot = Spawned[DropId] and Spawned[DropId][Slot] and Spawned[DropId][Slot].Entity
    if Spot and DoesEntityExist(Spot) then
        TaskTurnPedToFaceEntity(PlayerPedId(), Spot, 400)
    end

    if LoadAnimDictTimeout('pickup_object') then
        TaskPlayAnim(PlayerPedId(), 'pickup_object', 'pickup_low', 8.0, -8.0, 1000, 48, 0, false, false, false)
    end

    Citizen.Wait(450)
    FW.TriggerServer('fw-inventory:Server:PickupDropItem', DropId, Slot)
end
exports("PickupDropItem", PickupDropItem)

-- // Sync \\ --
RegisterNetEvent("fw-inventory:Client:SetDropData")
AddEventHandler("fw-inventory:Client:SetDropData", function(DropId, Data)
    Config.Drops[DropId] = Data
    Citizen.CreateThread(function() RefreshDrop(DropId) end)
end)

local function FetchDrops()
    Citizen.CreateThread(function()
        local Drops = FW.SendCallback('fw-inventory:Server:GetDrops') or {}
        for _, Entry in pairs(Drops) do
            Config.Drops[Entry.Id] = Entry.Data
        end
    end)
end

RegisterNetEvent('FW:Client:OnPlayerLoaded')
AddEventHandler('FW:Client:OnPlayerLoaded', FetchDrops)

AddEventHandler('onResourceStart', function(Resource)
    if Resource == GetCurrentResourceName() then
        Citizen.SetTimeout(1500, FetchDrops)
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    for DropId in pairs(Spawned) do DespawnDrop(DropId) end
end)

-- Streams props in/out as the player moves.
Citizen.CreateThread(function()
    while true do
        for DropId in pairs(Config.Drops) do
            RefreshDrop(DropId)
        end

        for DropId in pairs(Spawned) do
            if not Config.Drops[DropId] then DespawnDrop(DropId) end
        end

        Citizen.Wait(750)
    end
end)
