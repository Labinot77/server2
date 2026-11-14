local KeyProp = `m23_2_prop_m32_carkey_fob_01a`
local Jacked, DroppedKeys, ShowingPrompt = {}, {}, false

local function LoadDict(Dict)
    RequestAnimDict(Dict)
    while not HasAnimDictLoaded(Dict) do Citizen.Wait(10) end
end

local function WaitFor(Check, Timeout)
    local End = GetGameTimer() + Timeout
    while not Check() and GetGameTimer() < End do Citizen.Wait(50) end
end

local function ThrowKeys(Driver, Vehicle)
    local Plate = GetVehicleNumberPlateText(Vehicle)
    NetworkRequestControlOfEntity(Driver)
    SetBlockingOfNonTemporaryEvents(Driver, true)

    -- Stop and get out
    TaskVehicleTempAction(Driver, Vehicle, 6, 2500)
    WaitFor(function() return GetEntitySpeed(Vehicle) < 1.0 end, 3000)
    TaskLeaveVehicle(Driver, Vehicle, 256)
    WaitFor(function() return not IsPedInAnyVehicle(Driver, false) end, 5000)
    FW.VSync.SetVehicleDoorsLocked(Vehicle, 1)

    -- Face the player, hands up
    TaskTurnPedToFaceEntity(Driver, PlayerPedId(), 800)
    Citizen.Wait(800)
    LoadDict("missminuteman_1ig_2")
    TaskPlayAnim(Driver, "missminuteman_1ig_2", "handsup_base", 8.0, -8.0, 1500, 49, 0, false, false, false)
    Citizen.Wait(1500)

    -- Reach into pocket, take out keys
    LoadDict("reaction@intimidation@1h")
    TaskPlayAnim(Driver, "reaction@intimidation@1h", "intro", 8.0, -8.0, 1400, 48, 0, false, false, false)
    Citizen.Wait(900)

    RequestModel(KeyProp)
    while not HasModelLoaded(KeyProp) do Citizen.Wait(10) end
    local Prop = CreateObject(KeyProp, GetEntityCoords(Driver), true, true, false)
    AttachEntityToEntity(Prop, Driver, GetPedBoneIndex(Driver, 57005), 0.12, 0.03, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    Citizen.Wait(500)

    -- Throw towards the player
    LoadDict("anim@heists@narcotics@trash")
    TaskPlayAnim(Driver, "anim@heists@narcotics@trash", "throw_b", 8.0, -8.0, 1200, 48, 0, false, false, false)
    Citizen.Wait(550)
    DetachEntity(Prop, true, true)
    local Dir = GetEntityForwardVector(Driver)
    SetEntityVelocity(Prop, Dir.x * 4.0, Dir.y * 4.0, 2.5)
    SetModelAsNoLongerNeeded(KeyProp)

    WaitFor(function() return GetEntitySpeed(Prop) < 0.05 end, 3000)
    FreezeEntityPosition(Prop, true)
    TriggerServerEvent("fw-vehicles:Server:KeysDropped", ObjToNet(Prop), Plate)

    -- Keep hands up, then run
    TaskPlayAnim(Driver, "missminuteman_1ig_2", "handsup_base", 8.0, -8.0, 4000, 49, 0, false, false, false)
    Citizen.Wait(4000)
    SetBlockingOfNonTemporaryEvents(Driver, false)
    TaskSmartFleePed(Driver, PlayerPedId(), 100.0, -1, false, false)
    SetPedKeepTask(Driver, true)
end

-- Gunpoint detection
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(250)
        local Ped = PlayerPedId()
        if LoggedIn and IsPedArmed(Ped, 4) and not IsPedInAnyVehicle(Ped, false) then
            local Aiming, Target = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if Aiming and Target ~= 0 then
                local Vehicle = IsEntityAVehicle(Target) and Target or (IsEntityAPed(Target) and GetVehiclePedIsIn(Target, false) or 0)
                local Driver = Vehicle ~= 0 and GetPedInVehicleSeat(Vehicle, -1) or 0

                if Driver ~= 0 and not Jacked[Vehicle] and not IsPedAPlayer(Driver) and not IsPedDeadOrDying(Driver, true)
                    and #(GetEntityCoords(Ped) - GetEntityCoords(Vehicle)) < 12.0 and GetEntitySpeed(Vehicle) < 10.0 then
                    Jacked[Vehicle] = true
                    Citizen.CreateThread(function() ThrowKeys(Driver, Vehicle) end)
                end
            end
        end
    end
end)

-- Pickup
RegisterNetEvent("fw-vehicles:Client:SetDroppedKeys")
AddEventHandler("fw-vehicles:Client:SetDroppedKeys", function(NetId, State)
    DroppedKeys[NetId] = State
end)

Citizen.CreateThread(function()
    while true do
        local Sleep, Near = 500, nil
        local Coords = GetEntityCoords(PlayerPedId())

        for NetId in pairs(DroppedKeys) do
            local Prop = NetworkDoesEntityExistWithNetworkId(NetId) and NetToObj(NetId) or 0
            if Prop ~= 0 and #(Coords - GetEntityCoords(Prop)) < 1.5 then Near = NetId break end
        end

        if Near then
            Sleep = 0
            if not ShowingPrompt then exports['fw-ui']:ShowInteraction("[E] Sleutels oppakken") ShowingPrompt = true end
            if IsControlJustReleased(0, 38) then
                LoadDict("anim@mp_snowball")
                TaskPlayAnim(PlayerPedId(), "anim@mp_snowball", "pickup_snowball", 8.0, -8.0, 1200, 48, 0, false, false, false)
                Citizen.Wait(700)
                TriggerServerEvent("fw-vehicles:Server:PickupKeys", Near)
                DroppedKeys[Near] = nil
            end
        elseif ShowingPrompt then
            exports['fw-ui']:HideInteraction()
            ShowingPrompt = false
        end

        Citizen.Wait(Sleep)
    end
end)
