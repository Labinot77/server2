-- Chop Shop prop needs game build 3095+, fall back to the base game key otherwise
local KeyProp = IsModelInCdimage(`m23_2_prop_m32_carkey_fob_01a`) and `m23_2_prop_m32_carkey_fob_01a` or `p_car_keys_01`
local Jacked = {}

local function LoadDict(Dict)
    RequestAnimDict(Dict)
    while not HasAnimDictLoaded(Dict) do Citizen.Wait(10) end
end

local function WaitFor(Check, Timeout)
    local End = GetGameTimer() + Timeout
    while not Check() and GetGameTimer() < End do Citizen.Wait(50) end
end

-- Without control the owner's AI overrides our tasks (NPC climbs back in) and the
-- population cleanup can delete the car, so take control and make both mission entities.
local function TakeControl(Entity)
    WaitFor(function() NetworkRequestControlOfEntity(Entity) return NetworkHasControlOfEntity(Entity) end, 2000)
    SetEntityAsMissionEntity(Entity, true, true)
    return NetworkHasControlOfEntity(Entity)
end

local function ThrowKeys(Driver, Vehicle)
    if not TakeControl(Driver) or not TakeControl(Vehicle) then Jacked[Vehicle] = nil return end
    local Ped = PlayerPedId()

    SetBlockingOfNonTemporaryEvents(Driver, true)
    SetPedFleeAttributes(Driver, 0, false)
    ClearPedTasks(Driver)

    -- Stop and get out (door stays open)
    TaskVehicleTempAction(Driver, Vehicle, 6, 2500)
    WaitFor(function() return GetEntitySpeed(Vehicle) < 1.0 end, 3000)
    TaskLeaveVehicle(Driver, Vehicle, 256)
    WaitFor(function() return not IsPedInAnyVehicle(Driver, false) end, 5000)
    FW.VSync.SetVehicleDoorsLocked(Vehicle, 1)

    -- Face the player, hands up
    TaskTurnPedToFaceEntity(Driver, Ped, 800)
    Citizen.Wait(800)
    LoadDict("missminuteman_1ig_2")
    TaskPlayAnim(Driver, "missminuteman_1ig_2", "handsup_base", 8.0, -8.0, 1500, 49, 0, false, false, false)
    Citizen.Wait(1500)

    -- Reach into pocket, take out the keys (local visual prop)
    LoadDict("reaction@intimidation@1h")
    TaskPlayAnim(Driver, "reaction@intimidation@1h", "intro", 8.0, -8.0, 1400, 48, 0, false, false, false)
    Citizen.Wait(900)

    RequestModel(KeyProp)
    while not HasModelLoaded(KeyProp) do Citizen.Wait(10) end
    local Prop = CreateObject(KeyProp, GetEntityCoords(Driver), false, false, false)
    SetModelAsNoLongerNeeded(KeyProp)
    AttachEntityToEntity(Prop, Driver, GetPedBoneIndex(Driver, 57005), 0.12, 0.03, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    Citizen.Wait(500)

    -- Throw towards the player
    LoadDict("anim@heists@narcotics@trash")
    TaskPlayAnim(Driver, "anim@heists@narcotics@trash", "throw_b", 8.0, -8.0, 1200, 48, 0, false, false, false)
    Citizen.Wait(550)
    DetachEntity(Prop, true, true)
    SetEntityCollision(Prop, true, true)
    ActivatePhysics(Prop)
    local Dir = GetEntityForwardVector(Driver)
    SetEntityVelocity(Prop, Dir.x * 4.0, Dir.y * 4.0, 2.5)

    -- The tiny key model can fall through the map, so don't trust where it ends up:
    -- take its x/y (clamped to 4m from the driver) and snap it to the ground.
    Citizen.Wait(700)
    local From, Pos = GetEntityCoords(Driver), GetEntityCoords(Prop)
    local Flat = vector3(Pos.x - From.x, Pos.y - From.y, 0.0)
    if #Flat > 4.0 or #Flat < 0.5 then Flat = vector3(Dir.x, Dir.y, 0.0) * 1.5 end
    local Landing = From + Flat
    local Found, GroundZ = GetGroundZFor_3dCoord(Landing.x, Landing.y, From.z + 1.0, false)
    Landing = vector3(Landing.x, Landing.y, Found and GroundZ or From.z - 0.95)

    FreezeEntityPosition(Prop, true)
    SetEntityCoords(Prop, Landing.x, Landing.y, Landing.z, false, false, false, false)

    -- The real ground item spawns here; drop the local prop once it has synced
    TriggerServerEvent("fw-vehicles:Server:KeysDropped", VehToNet(Vehicle), Landing, GetEntityHeading(Prop))
    Citizen.SetTimeout(2500, function() if DoesEntityExist(Prop) then DeleteEntity(Prop) end end)

    -- Keep hands up, then run
    TaskPlayAnim(Driver, "missminuteman_1ig_2", "handsup_base", 8.0, -8.0, 4000, 49, 0, false, false, false)
    Citizen.Wait(4000)
    TaskSmartFleePed(Driver, Ped, 100.0, -1, false, false)
    SetPedKeepTask(Driver, true)
    SetPedAsNoLongerNeeded(Driver)
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
