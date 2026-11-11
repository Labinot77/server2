-- Stance sync. Wheel offset / camber natives only last a frame and are local, so the stance lives in a
-- replicated state bag on the vehicle ('bennysStance', set by Benny's and by fw-core when the vehicle
-- spawns with saved mods) and every client applies it to the vehicles around them each frame.
--
-- bennysStance = { SpacersFront, SpacersRear, CamberFront, CamberRear, Width, Suspension } (any subset)

local STATE_KEY = 'bennysStance'
local RANGE = 120.0

local Active = {} -- [Vehicle] = stance

local function ApplyStance(Vehicle, S)
    if S.SpacersFront then
        SetVehicleWheelXOffset(Vehicle, 0, -S.SpacersFront)
        SetVehicleWheelXOffset(Vehicle, 1, S.SpacersFront)
    end
    if S.SpacersRear then
        SetVehicleWheelXOffset(Vehicle, 2, -S.SpacersRear)
        SetVehicleWheelXOffset(Vehicle, 3, S.SpacersRear)
    end
    if S.CamberFront then
        SetVehicleWheelYRotation(Vehicle, 0, -S.CamberFront)
        SetVehicleWheelYRotation(Vehicle, 1, S.CamberFront)
    end
    if S.CamberRear then
        SetVehicleWheelYRotation(Vehicle, 2, -S.CamberRear)
        SetVehicleWheelYRotation(Vehicle, 3, S.CamberRear)
    end
    if S.Width then SetVehicleWheelWidth(Vehicle, S.Width) end
    if S.Suspension then SetVehicleSuspensionHeight(Vehicle, S.Suspension) end
end

-- While the Benny's menu previews stance changes it applies them itself, so skip that vehicle.
local function GetCustomizingVehicle()
    return exports[GetCurrentResourceName()]:GetPreviewingStanceVehicle() or 0
end

-- Slow: find vehicles nearby that have a stance.
CreateThread(function()
    while true do
        local Coords = GetEntityCoords(PlayerPedId())
        local Found = {}
        for _, Vehicle in ipairs(GetGamePool('CVehicle')) do
            if #(GetEntityCoords(Vehicle) - Coords) <= RANGE then
                local Stance = Entity(Vehicle).state[STATE_KEY]
                if type(Stance) == 'table' and next(Stance) then
                    Found[Vehicle] = Stance
                end
            end
        end
        Active = Found
        Wait(500)
    end
end)

-- Fast: apply every frame.
CreateThread(function()
    while true do
        if next(Active) then
            local Customizing = GetCustomizingVehicle()
            for Vehicle, Stance in pairs(Active) do
                if Vehicle ~= Customizing and DoesEntityExist(Vehicle) then
                    ApplyStance(Vehicle, Stance)
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Pick up changes straight away instead of waiting for the next scan.
AddStateBagChangeHandler(STATE_KEY, nil, function(BagName, _, Value)
    local Vehicle = GetEntityFromStateBagName(BagName)
    if Vehicle == 0 then return end
    if type(Value) == 'table' and next(Value) then
        Active[Vehicle] = Value
    else
        Active[Vehicle] = nil
    end
end)
