-- // Driving Feel / Handling \\ --
-- Smooth throttle, realistic handling tweaks, better rollback & handbrake turns.
-- All settings live in Config.Handling (config.lua).

local DrivingVehicle = nil
local TweakedVehicle, TweakOriginals = nil, {}

-- // Helpers \\ --

local function Lerp(A, B, T)
    return A + (B - A) * T
end

local function Clamp(Value, Min, Max)
    if Value < Min then return Min end
    if Value > Max then return Max end
    return Value
end

local function EaseInOut(T)
    return T * T * (3.0 - 2.0 * T)
end

local function IsNitrousActive()
    return HasVehicleNosActive ~= nil and HasVehicleNosActive()
end

local function GetDrivenVehicle()
    local Ped = PlayerPedId()
    if not IsPedInAnyVehicle(Ped, false) then return nil end

    local Vehicle = GetVehiclePedIsIn(Ped, false)
    if Vehicle == 0 or GetPedInVehicleSeat(Vehicle, -1) ~= Ped then return nil end
    if Config.Handling.IgnoredClasses[GetVehicleClass(Vehicle)] then return nil end

    return Vehicle
end

-- // Handling Tweaks \\ --
-- Values are multiplied from the vehicle's own handling, so every car keeps its character.
-- Originals are restored when leaving the vehicle or when the resource stops (no compounding).

local function RestoreTweaks()
    if TweakedVehicle and DoesEntityExist(TweakedVehicle) then
        for Field, Value in pairs(TweakOriginals) do
            SetVehicleHandlingFloat(TweakedVehicle, "CHandlingData", Field, Value)
        end
    end

    TweakedVehicle, TweakOriginals = nil, {}
end

local function ApplyTweaks(Vehicle)
    local Tweaks = Config.Handling.Tweaks
    if not Tweaks or not Tweaks.Enabled then return end
    if Tweaks.CarsOnly and not IsThisModelACar(GetEntityModel(Vehicle)) then return end

    RestoreTweaks()

    TweakedVehicle = Vehicle
    for Field, Multiplier in pairs(Tweaks.Fields) do
        local Original = GetVehicleHandlingFloat(Vehicle, "CHandlingData", Field)
        TweakOriginals[Field] = Original
        SetVehicleHandlingFloat(Vehicle, "CHandlingData", Field, Original * Multiplier)
    end
end

-- // Smooth Throttle \\ --

local function DriveLoop(Vehicle)
    local Cfg = Config.Handling.SmoothThrottle
    local ClassRamp = (Cfg.ClassRamp and Cfg.ClassRamp[GetVehicleClass(Vehicle)]) or 1.0

    local Pedal = 0.0
    local LastGear = GetVehicleCurrentGear(Vehicle)
    local ShiftTimer = 0.0

    while DrivingVehicle == Vehicle do
        Citizen.Wait(0)

        if not DoesEntityExist(Vehicle) then break end
        if IsNitrousActive() or not GetIsVehicleEngineRunning(Vehicle) then
            Pedal = 0.0
            goto Continue
        end

        do
            local Dt = GetFrameTime()
            local Speed = GetEntitySpeed(Vehicle)
            local ForwardSpeed = GetEntitySpeedVector(Vehicle, true).y
            local Target = math.abs(GetVehicleThrottleOffset(Vehicle))

            -- Pedal travel: slow & progressive from a standstill, snappier when already rolling
            local SpeedFactor = Clamp(Speed / Cfg.HighSpeed, 0.0, 1.0)
            local RampUp = math.max(Cfg.RampUp * ClassRamp * Lerp(1.0, Cfg.HighSpeedFactor, SpeedFactor), 0.01)
            local RampDown = math.max(Cfg.RampDown, 0.01)

            if Target > Pedal then
                Pedal = math.min(Target, Pedal + Dt / RampUp)
            else
                Pedal = math.max(Target, Pedal - Dt / RampDown)
            end

            local Torque = 1.0
            if Target > 0.01 then
                local Progress = Clamp(Pedal / Target, 0.0, 1.0)
                Torque = Lerp(Cfg.MinTorque, 1.0, EaseInOut(Progress))
            end

            -- Launch: tame first-gear wheelspin at walking speed
            local Gear = GetVehicleCurrentGear(Vehicle)
            if Cfg.LaunchControl and Gear <= 1 and ForwardSpeed >= 0.0 and Speed < Cfg.LaunchSpeed then
                Torque = Torque * Lerp(Cfg.LaunchTorque, 1.0, Speed / Cfg.LaunchSpeed)
            end

            -- Gear change: short torque dip on upshifts
            if Cfg.ShiftDip then
                if Gear > LastGear and LastGear >= 1 then
                    ShiftTimer = Cfg.ShiftDipTime
                end
                if ShiftTimer > 0.0 then
                    Torque = Torque * Lerp(Cfg.ShiftDipTorque, 1.0, 1.0 - (ShiftTimer / Cfg.ShiftDipTime))
                    ShiftTimer = ShiftTimer - Dt
                end
            end
            LastGear = Gear

            -- Native resets every frame, so only call it when we actually reduce power
            if Torque < 0.999 then
                SetVehicleEngineTorqueMultiplier(Vehicle, Torque)
            end
        end

        ::Continue::
    end
end

local function StartDriving(Vehicle)
    DrivingVehicle = Vehicle
    ApplyTweaks(Vehicle)

    if Config.Handling.SmoothThrottle and Config.Handling.SmoothThrottle.Enabled then
        Citizen.CreateThread(function()
            DriveLoop(Vehicle)
        end)
    end
end

local function StopDriving()
    DrivingVehicle = nil
    RestoreTweaks()
end

-- // Driver Watcher \\ --

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(250)

        if Config.Handling.Enabled then
            local Vehicle = GetDrivenVehicle()
            if Vehicle ~= DrivingVehicle then
                if DrivingVehicle then StopDriving() end
                if Vehicle then StartDriving(Vehicle) end
            end
        elseif DrivingVehicle then
            StopDriving()
        end
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    StopDriving()
end)

-- // Better Rollback & Handbrake Turns \\ --
-- Ported from kq_rollback by KuzQuality (https://kuzquality.com/)

Citizen.CreateThread(function()
    local UsedForce = 0

    while true do
        local Sleep = 3000

        if Config.Handling.Enabled and DrivingVehicle and DoesEntityExist(DrivingVehicle) then
            local Vehicle = DrivingVehicle
            Sleep = 250

            local Speed = GetEntitySpeedVector(Vehicle, true).y
            if Speed < 20 then
                Sleep = 100
                local Throttle = GetVehicleThrottleOffset(Vehicle)

                if Speed < 0 and (Throttle == 0.0 or UsedForce > 0) then
                    if Config.Handling.Rollback.Enabled then
                        -- Clutch in so the car can roll back freely
                        SetVehicleClutch(Vehicle, 1.0)

                        -- Push the car back a bit more, like gravity would on a slope
                        if UsedForce < Config.Handling.Rollback.Duration then
                            UsedForce = UsedForce + 1
                            ApplyForceToEntity(Vehicle, 0, vector3(0, math.max(-6, Speed * Config.Handling.Rollback.Strength), 0), 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 0)
                        end
                        Sleep = 1
                    end
                else
                    if Config.Handling.HandbrakeTurns.Enabled then
                        local Steering = GetVehicleSteeringAngle(Vehicle)
                        if Throttle == 0.0 and Speed < 15 and Speed > 2 and GetVehicleHandbrake(Vehicle) and math.abs(Steering) > 0.5 then
                            -- Sideways force to swing the rear around quicker
                            ApplyForceToEntity(Vehicle, 1, vector3(Steering * Speed * Config.Handling.HandbrakeTurns.Strength, 0.0, 0), 0.0, -3.0, 0, 0, 1, 1, 0, 0)
                        end
                    end
                    if UsedForce > 0 then
                        UsedForce = math.max(0, UsedForce - 10)
                    end
                end
            end
        else
            UsedForce = 0
        end

        Citizen.Wait(Sleep)
    end
end)
