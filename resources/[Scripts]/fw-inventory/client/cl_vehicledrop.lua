-- ============================================================================
--  Drop (right-click -> Drop)
--  On foot: the item is put down at your feet.
--  In a vehicle (port of coderadev/ox_inventory): your arm reaches out of the window on your side,
--  the item falls next to the car and lands on the ground there.
-- ============================================================================
local IsDropping = false

local function WorldToLocal(Vehicle, Pos)
    return GetOffsetFromEntityGivenWorldCoords(Vehicle, Pos.x, Pos.y, Pos.z)
end

-- Distance from the middle of the car to its side (body or front wheel, whichever sticks out more).
local function GetVehicleSideEdge(Vehicle, Left)
    local Min, Max = GetModelDimensions(GetEntityModel(Vehicle))
    local Edge = math.max(math.abs(Left and Min.x or Max.x), 0.85)
    local Bone = GetEntityBoneIndexByName(Vehicle, Left and 'wheel_lf' or 'wheel_rf')
    if Bone and Bone ~= -1 then
        local Wheel = WorldToLocal(Vehicle, GetWorldPositionOfEntityBone(Vehicle, Bone))
        Edge = math.max(Edge, math.abs(Wheel.x) + 0.2)
    end
    return Edge
end

local function GetPedSeat(Ped, Vehicle)
    for Seat = -1, GetVehicleMaxNumberOfPassengers(Vehicle) - 1 do
        if GetPedInVehicleSeat(Vehicle, Seat) == Ped then return Seat end
    end
    return -1
end

-- Driver and rear-left drop on the left, everyone else on the right.
local function IsLeftSeat(Seat) return Seat == -1 or Seat % 2 == 1 end

-- Ground spot just outside your door.
local function GetVehicleDropCoords(Ped, Vehicle, Seat)
    local Left = IsLeftSeat(Seat)
    local Side = Left and -1.0 or 1.0
    local PedLocal = WorldToLocal(Vehicle, GetEntityCoords(Ped))
    local Landing = GetOffsetFromEntityInWorldCoords(Vehicle, Side * (GetVehicleSideEdge(Vehicle, Left) + 0.65), PedLocal.y, 0.0)

    local Handle = StartExpensiveSynchronousShapeTestLosProbe(Landing.x, Landing.y, Landing.z + 2.0, Landing.x, Landing.y, Landing.z - 6.0, 1 | 16, Vehicle, 4)
    local _, Hit, EndCoords = GetShapeTestResult(Handle)
    local GroundZ = (Hit == true or Hit == 1) and EndCoords.z or nil

    if not GroundZ then
        local Found, Z = GetGroundZFor_3dCoord(Landing.x, Landing.y, Landing.z + 1.0, false)
        GroundZ = Found and Z or (GetEntityCoords(Vehicle).z - math.max(GetEntityHeightAboveGround(Vehicle), 0.0))
    end

    return vector3(Landing.x, Landing.y, GroundZ)
end

-- Arm out of the window holding the item, then it falls to the landing spot.
local function ThrowOutOfWindow(Ped, Model, Vehicle, Seat, Landing)
    local Left = IsLeftSeat(Seat)
    local Out = Left and -1.0 or 1.0
    local IkPart = Left and 3 or 4 -- left / right hand
    local Bone = GetPedBoneIndex(Ped, Left and 18905 or 28422)

    RequestModel(Model)
    local Timeout = GetGameTimer() + 1500
    while not HasModelLoaded(Model) and GetGameTimer() < Timeout do Citizen.Wait(0) end
    if not HasModelLoaded(Model) then return end

    local Prop = CreateObject(Model, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(Model)
    if not Prop or Prop == 0 then return end

    SetEntityCollision(Prop, false, false)
    AttachEntityToEntity(Prop, Ped, Bone, 0.05, 0.0, -0.085, 90.0, 90.0, 0.0, false, false, false, true, 2, true)

    local Edge = GetVehicleSideEdge(Vehicle, Left)
    local PedLocal = WorldToLocal(Vehicle, GetEntityCoords(Ped))
    local Began, Target = GetGameTimer(), nil

    -- Reach out (650 ms) and hold it there for a moment (250 ms).
    while GetGameTimer() - Began < 900 do
        if not DoesEntityExist(Vehicle) or not DoesEntityExist(Prop) then break end
        Target = GetOffsetFromEntityInWorldCoords(Vehicle, Out * (Edge + 0.5), PedLocal.y, PedLocal.z + 0.3)
        SetIkTarget(Ped, IkPart, 0, 0, Target.x, Target.y, Target.z, 0, 300, 300)
        Citizen.Wait(0)
    end
    if not DoesEntityExist(Prop) then return end

    local Start = GetWorldPositionOfEntityBone(Ped, Bone)
    DetachEntity(Prop, true, true)
    FreezeEntityPosition(Prop, true)
    if Target and (#(Start - Target) > 0.9 or Start.z < Landing.z + 0.15) then Start = Target end

    -- Fall: drifts out sideways, drops with gravity, tumbles a little.
    Began = GetGameTimer()
    while true do
        local T = (GetGameTimer() - Began) / 420
        if T >= 1.0 then break end
        local Drift = 1.0 - (1.0 - T) * (1.0 - T)
        SetEntityCoordsNoOffset(Prop,
            Start.x + (Landing.x - Start.x) * Drift,
            Start.y + (Landing.y - Start.y) * Drift,
            math.max(Start.z + (Landing.z - Start.z) * (T * T), Landing.z),
            false, false, false)
        SetEntityRotation(Prop, 40.0 * T, 25.0 * T, 0.0, 2, true)
        Citizen.Wait(0)
    end

    -- Keep it a moment so it doesn't blink before the synced ground prop appears.
    SetEntityCoordsNoOffset(Prop, Landing.x, Landing.y, Landing.z, false, false, false)
    Citizen.SetTimeout(1200, function() if DoesEntityExist(Prop) then DeleteEntity(Prop) end end)
end

local function DropFromVehicle(Ped, Vehicle, Slot, Amount, ItemName)
    local Seat = GetPedSeat(Ped, Vehicle)
    local Landing = GetVehicleDropCoords(Ped, Vehicle, Seat)
    ThrowOutOfWindow(Ped, ResolveItemModel(ItemName), Vehicle, Seat, Landing)
    FW.TriggerServer('fw-inventory:Server:PlaceItem', Slot, Amount, Landing, GetEntityHeading(Vehicle), true)
end

local function DropAtFeet(Ped, Slot, Amount)
    local Front = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 0.55, 0.0)
    local Found, Z = GetGroundZFor_3dCoord(Front.x, Front.y, Front.z + 0.5, false)
    local Coords = vector3(Front.x, Front.y, Found and Z or (Front.z - 0.95))
    FW.TriggerServer('fw-inventory:Server:PlaceItem', Slot, Amount, Coords, GetEntityHeading(Ped), false)

    -- Show the pile in GROUND right away.
    Citizen.SetTimeout(400, function()
        if CurrentInventory and CurrentInventory.Type ~= 'Glovebox' then SwitchOtherInventory() end
    end)
end

RegisterNUICallback("DropItem", function(Data, Cb)
    Cb("Ok")
    if IsDropping or IsHoldingItem then return end

    local Slot = tonumber(Data.Slot)
    local Item = Slot and FW.Functions.GetPlayerData().inventory[Slot]
    if not Item then return end
    local Amount = math.max(1, math.min(tonumber(Data.Amount) or Item.Amount, Item.Amount))

    local Ped = PlayerPedId()
    if IsPedFalling(Ped) then return end

    IsDropping = true
    Citizen.CreateThread(function()
        local Vehicle = GetVehiclePedIsIn(Ped, false)
        if Vehicle ~= 0 and IsSeatedInVehicle(Ped) then
            DropFromVehicle(Ped, Vehicle, Slot, Amount, Item.Item)
        else
            DropAtFeet(Ped, Slot, Amount)
        end
        IsDropping = false
    end)
end)
