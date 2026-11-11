-- Work orders, mechanic side: keeps the order list in sync, adds an interact prompt per item on the
-- customer's vehicle for the mechanic who accepted it, and applies items on the vehicle owner's client.
FW = FW or exports['fw-core']:GetCoreObject()

MyOrderBusinesses = {}   -- Businesses (that take orders) I work at
OrdersByBusiness = {}    -- [Business] = { order, ... }

local MyCid = nil
local Busy = false
local VehicleInteractions = {} -- [OrderId] = { Id = interactionId, Vehicle = entity, Key = string }

-- ── Helpers ────────────────────────────────────────────────────────────────

local LastMembershipFetch = 0

-- Uses the cached list (called every frame by interact); refreshes in the background when it's empty.
function IsOrderMechanic(Business)
    for _, Name in ipairs(MyOrderBusinesses) do
        if Name == Business then return true end
    end

    if MyCid and GetGameTimer() - LastMembershipFetch > 15000 then
        LastMembershipFetch = GetGameTimer()
        CreateThread(function()
            MyOrderBusinesses = FW.SendCallback('fw-bennys:Server:Orders:GetMyBusinesses') or {}
        end)
    end
    return false
end

function GetOrderMechanicState()
    return MyCid, MyOrderBusinesses
end

function GetOrderById(Id)
    for _, List in pairs(OrdersByBusiness) do
        for _, Order in ipairs(List) do
            if Order.Id == Id then return Order end
        end
    end
end

local function TrimPlate(Plate)
    return (Plate or ''):gsub('%s+', '')
end

function FindOrderVehicle(NetId, Plate)
    if NetId and NetId ~= 0 and NetworkDoesNetworkIdExist(NetId) then
        local Vehicle = NetToVeh(NetId)
        if Vehicle ~= 0 and DoesEntityExist(Vehicle) and (not Plate or TrimPlate(GetVehicleNumberPlateText(Vehicle)) == TrimPlate(Plate)) then
            return Vehicle
        end
    end

    if not Plate then return nil end
    for _, Vehicle in ipairs(GetGamePool('CVehicle')) do
        if TrimPlate(GetVehicleNumberPlateText(Vehicle)) == TrimPlate(Plate) then
            return Vehicle
        end
    end
end

local function GetInstallInfo(Slot)
    for _, Entry in ipairs(Config.Orders.InstallTime) do
        if Slot:sub(1, #Entry.Prefix) == Entry.Prefix then return Entry end
    end
    return { Time = 7500, Label = 'Installing' }
end

local function RefreshOrders()
    if not MyCid then
        local PlayerData = FW.Functions.GetPlayerData()
        MyCid = PlayerData and PlayerData.citizenid or nil
    end
    if not MyCid then return end
    MyOrderBusinesses = FW.SendCallback('fw-bennys:Server:Orders:GetMyBusinesses') or {}

    local Fresh = {}
    for _, Business in ipairs(MyOrderBusinesses) do
        Fresh[Business] = FW.SendCallback('fw-bennys:Server:Orders:Get', Business) or {}
    end
    OrdersByBusiness = Fresh
end

-- ── Repair (used by checkout outside order zones, and by order items) ──────

function RepairBennysVehicle(Vehicle, WithProgress)
    if not DoesEntityExist(Vehicle) then return end

    local BodyHealth = GetVehicleBodyHealth(Vehicle)
    local EngineHealth = GetVehicleEngineHealth(Vehicle)
    local MissingBodyHealth = 1000.0 - BodyHealth
    local MissingEngineHealth = 1000.0 - EngineHealth

    if not WithProgress then
        SetVehicleEngineHealth(Vehicle, 1000.0)
        SetVehiclePetrolTankHealth(Vehicle, 1000.0)
        SetVehicleDeformationFixed(Vehicle)
        SetVehicleBodyHealth(Vehicle, 1000.0)
        FW.VSync.SetVehicleFixed(Vehicle)
        return
    end

    SetVehicleHandbrake(Vehicle, true)

    if MissingEngineHealth > 50 then
        local Finished = FW.Functions.CompactProgressbar(5000 + (MissingEngineHealth / 50), "Motor repareren...", false, false, {disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true}, {}, {}, {}, false)
        if Finished then
            SetVehicleEngineHealth(Vehicle, EngineHealth + MissingEngineHealth)
            SetVehiclePetrolTankHealth(Vehicle, 1000.0)
        end
    end

    if MissingBodyHealth > 50 then
        local Finished = FW.Functions.CompactProgressbar(5000 + (MissingBodyHealth / 50), "Body repareren...", false, false, {disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true}, {}, {}, {}, false)
        if Finished then
            SetVehicleDeformationFixed(Vehicle)
            SetVehicleBodyHealth(Vehicle, BodyHealth + MissingBodyHealth)
        end
    end

    if GetVehicleBodyHealth(Vehicle) >= 900 and GetVehicleEngineHealth(Vehicle) >= 900 then
        FW.VSync.SetVehicleFixed(Vehicle)
    end

    SetVehicleHandbrake(Vehicle, false)
end

AddEventHandler('fw-bennys:Client:RepairVehicle', function(Vehicle)
    RepairBennysVehicle(Vehicle, true)
end)

-- ── Installing (mechanic) ──────────────────────────────────────────────────

local function InstallItem(OrderId, Index)
    if Busy then return end
    local Order = GetOrderById(OrderId)
    local Item = Order and Order.Items[Index]
    if not Item or Item.Installed then return end

    local Vehicle = FindOrderVehicle(Order.NetId, Order.Plate)
    if not Vehicle then return FW.Functions.Notify("Voertuig niet gevonden..", "error") end

    Busy = true
    local Ped = PlayerPedId()
    TaskTurnPedToFaceEntity(Ped, Vehicle, 1000)
    Wait(800)

    local Info = GetInstallInfo(Item.Slot)
    local IsPaint = Item.Slot:sub(1, 5) == 'Color' or Item.Slot == 'TyreSmoke' or Item.Slot == 'NeonColor'
    local Animation = IsPaint
        and { animDict = 'switch@franklin@lamar_tagging_wall', anim = 'lamar_tagging_wall_loop_lamar', flags = 49 }
        or { animDict = 'mini@repair', anim = 'fixing_a_player', flags = 1 }

    local NetId = NetworkGetNetworkIdFromEntity(Vehicle)
    TriggerEvent('fw-misc:Client:PlaySoundEntity', IsPaint and 'vehicle.garageRespray' or 'vehicle.garageWrench', NetId, true, nil)

    local Label = ('%s %s%s...'):format(Info.Label, Item.Label, Item.Option ~= '' and (' (' .. Item.Option .. ')') or '')
    local Finished = FW.Functions.CompactProgressbar(Info.Time, Label, false, true, {disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true}, Animation, {}, {}, false)
    ClearPedTasks(Ped)

    if not Finished then
        Busy = false
        return
    end

    local Result = FW.SendCallback('fw-bennys:Server:Orders:InstallItem', OrderId, Index)
    Busy = false

    if not Result or not Result.Success then
        return FW.Functions.Notify(Result and Result.Message or "Installeren mislukt..", "error")
    end

    FW.Functions.Notify(Result.Finished and ("Order #%d is afgerond!"):format(OrderId) or ("%s geïnstalleerd."):format(Item.Label), "success")
end

-- Hand the order back to the pool; installed items stay installed for the next mechanic.
function UnassignOrder(OrderId)
    local Result = FW.SendCallback('fw-bennys:Server:Orders:Action', 'release', OrderId)
    if Result and Result.Success then
        FW.Functions.Notify(("Je bent niet meer toegewezen aan order #%d. Een andere monteur kan verder."):format(OrderId), "primary")
    else
        FW.Functions.Notify(Result and Result.Message or "Er ging iets mis..", "error")
    end
end

-- One interaction per accepted order of mine, with an option per item that isn't installed yet.
local function RemoveVehicleInteraction(OrderId)
    local Entry = VehicleInteractions[OrderId]
    if not Entry then return end
    if GetResourceState('interact') == 'started' then exports['interact']:RemoveInteraction(Entry.Id) end
    VehicleInteractions[OrderId] = nil
end

local function SyncVehicleInteractions()
    if GetResourceState('interact') ~= 'started' then return end

    local Wanted = {}
    for _, List in pairs(OrdersByBusiness) do
        for _, Order in ipairs(List) do
            if Order.Status == 'accepted' and Order.MechanicCid == MyCid then
                local Vehicle = FindOrderVehicle(Order.NetId, Order.Plate)
                if Vehicle then
                    local Options, Key = {}, tostring(Vehicle)
                    for Index, Item in ipairs(Order.Items) do
                        if not Item.Installed then
                            Key = Key .. ':' .. Index
                            local ItemIndex = Index
                            Options[#Options + 1] = {
                                name = ('bennys_order_%d_%d'):format(Order.Id, Index),
                                label = ('Install %s%s'):format(Item.Label, Item.Option ~= '' and (' - ' .. Item.Option) or ''),
                                canInteract = function() return not Busy end,
                                action = function()
                                    CreateThread(function() InstallItem(Order.Id, ItemIndex) end)
                                end,
                            }
                        end
                    end

                    if #Options > 0 then
                        Options[#Options + 1] = {
                            name = ('bennys_order_%d_unassign'):format(Order.Id),
                            label = ('Unassign me from order #%d'):format(Order.Id),
                            canInteract = function() return not Busy end,
                            action = function()
                                CreateThread(function() UnassignOrder(Order.Id) end)
                            end,
                        }
                        Wanted[Order.Id] = true
                        local Existing = VehicleInteractions[Order.Id]
                        if not Existing or Existing.Key ~= Key or Existing.Vehicle ~= Vehicle then
                            RemoveVehicleInteraction(Order.Id)
                            local Id = exports['interact']:AddLocalEntityInteraction({
                                entity = Vehicle,
                                offset = vec3(0.0, 0.0, 0.35),
                                distance = 8.0,
                                interactDst = 3.2,
                                name = ('bennys_order_%d'):format(Order.Id),
                                options = Options,
                            })
                            VehicleInteractions[Order.Id] = { Id = Id, Vehicle = Vehicle, Key = Key }
                        end
                    end
                end
            end
        end
    end

    for OrderId in pairs(VehicleInteractions) do
        if not Wanted[OrderId] then RemoveVehicleInteraction(OrderId) end
    end
end

-- ── Applying (vehicle owner) ───────────────────────────────────────────────

local function SendModsSnapshot(OrderId, Vehicle)
    -- Wait for SetVehicleMod etc. to settle before reading everything back.
    Wait(400)
    if not DoesEntityExist(Vehicle) then return end
    TriggerServerEvent('fw-bennys:Server:Orders:SaveMods', OrderId, FW.VSync.GetVehicleMods(Vehicle))
end

RegisterNetEvent('fw-bennys:Client:Orders:ApplyItem', function(OrderId, NetId, Slot, Value, Plate)
    local Vehicle = FindOrderVehicle(NetId, Plate)
    if not Vehicle then return end

    if Slot == 'Repair' then
        RepairBennysVehicle(Vehicle, false)
    else
        exports[GetCurrentResourceName()]:ApplyOrderItem(Vehicle, Slot, Value)
    end

    -- The server saves the full snapshot to player_vehicles (by the order's plate).
    SendModsSnapshot(OrderId, Vehicle)
end)

RegisterNetEvent('fw-bennys:Client:Orders:Snapshot', function(OrderId, NetId, Plate)
    local Vehicle = FindOrderVehicle(NetId, Plate)
    if Vehicle then SendModsSnapshot(OrderId, Vehicle) end
end)

-- ── Sync ───────────────────────────────────────────────────────────────────

RegisterNetEvent('fw-bennys:Client:Orders:Updated', function(Business, List)
    OrdersByBusiness[Business] = List
    TriggerEvent('fw-bennys:Client:Laptop:Orders', Business, List)
    SyncVehicleInteractions()
end)

RegisterNetEvent('FW:Client:OnPlayerLoaded', function()
    Wait(2000)
    MyCid = FW.Functions.GetPlayerData().citizenid
    RefreshOrders()
end)

RegisterNetEvent('FW:Client:OnPlayerUnload', function()
    MyCid = nil
    MyOrderBusinesses, OrdersByBusiness = {}, {}
    for OrderId in pairs(VehicleInteractions) do RemoveVehicleInteraction(OrderId) end
end)

CreateThread(function()
    -- Resource restarted while logged in.
    Wait(2500)
    local PlayerData = FW.Functions.GetPlayerData()
    if PlayerData and PlayerData.citizenid then
        MyCid = PlayerData.citizenid
        RefreshOrders()
    end

    local LastRefresh = GetGameTimer()
    while true do
        if not MyCid then
            local PlayerData = FW.Functions.GetPlayerData()
            if PlayerData and PlayerData.citizenid then
                MyCid = PlayerData.citizenid
                RefreshOrders()
            end
        end
        -- Vehicles stream in/out, so re-check interactions every second; membership every minute.
        if MyCid and #MyOrderBusinesses > 0 then SyncVehicleInteractions() end
        if MyCid and GetGameTimer() - LastRefresh > 60000 then
            LastRefresh = GetGameTimer()
            RefreshOrders()
        end
        Wait(1000)
    end
end)
