-- // Hand mode (ported from ox_inventory startPlaceMode) \\ --
-- "Give" in the inventory context menu puts the item in your hand:
--   [N]  aim mode -> place it exactly where you look ([Enter]/[LMB] confirm, scroll to rotate, [Shift] fine rotate)
--   [E]  throw it
--   [Esc]/[Backspace] cancel (item stays in your inventory)
-- The item only leaves the inventory once it's placed / has landed (server: fw-inventory:Server:PlaceItem).

Config.PlaceMaxDistance = 5.0

IsHoldingItem = false

local function Hint(Mode)
    SendNUIMessage({ Action = "PlaceHint", Mode = Mode or false })
end

local function SetInteractDisabled(State)
    pcall(function() exports.interact:Disable(State) end)
end

local function RayFromCamera(Distance)
    local Rot = GetGameplayCamRot(2)
    local Pos = GetGameplayCamCoord()
    local Rx, Rz = math.rad(Rot.x), math.rad(Rot.z)
    local Dir = vector3(-math.sin(Rz) * math.abs(math.cos(Rx)), math.cos(Rz) * math.abs(math.cos(Rx)), math.sin(Rx))
    local Dest = Pos + Dir * Distance
    local Handle = StartShapeTestLosProbe(Pos.x, Pos.y, Pos.z, Dest.x, Dest.y, Dest.z, 1 | 16 | 256, PlayerPedId(), 4)

    local Retval, Hit, EndCoords
    repeat
        Citizen.Wait(0)
        Retval, Hit, EndCoords = GetShapeTestResult(Handle)
    until Retval ~= 1

    if Hit == true or Hit == 1 then return EndCoords end
end

local BlockedControls = { 14, 15, 16, 17, 24, 25, 37, 44, 81, 99, 140, 141, 142, 177, 200, 241, 242, 174, 175 }

local function CanHold()
    local Ped = PlayerPedId()
    local PlayerData = FW.Functions.GetPlayerData()
    return not (PlayerData.metadata.isdead or PlayerData.metadata.ishandcuffed or IsPedInAnyVehicle(Ped, false) or IsPedFalling(Ped) or IsPedSwimming(Ped) or IsPedFatallyInjured(Ped))
end

function StartHoldMode(Slot, Amount)
    if IsHoldingItem then return end
    if not CanHold() then return FW.Functions.Notify("Dat kan nu niet.", "error") end

    Slot = tonumber(Slot)
    local Item = FW.Functions.GetPlayerData().inventory[Slot]
    if not Item then return end

    Amount = math.max(1, math.min(tonumber(Amount) or Item.Amount, Item.Amount))

    -- Quick client check, the server validates again.
    if Slot == Config.BackpackSlot and not IsBackpackEmpty(FW.Functions.GetPlayerData().inventory) then
        return FW.Functions.Notify("Maak eerst je rugzak leeg.", "error")
    end

    IsHoldingItem = true
    IsInventoryBusy = true
    SetInteractDisabled(true)

    local Ped = PlayerPedId()

    -- Holstering the weapon that's being dropped.
    if GetSelectedPedWeapon(Ped) == GetHashKey(Item.Item) then
        TriggerEvent('fw-inventory:Client:ResetWeapon')
        Citizen.Wait(250)
    end

    local Model = ResolveItemModel(Item.Item)
    if not LoadModelTimeout(Model) then
        Model = GetHashKey(Config.DropPropDefault)
        LoadModelTimeout(Model)
    end

    local Prop = CreateObject(Model, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(Model)
    SetEntityCollision(Prop, false, false)
    AttachEntityToEntity(Prop, Ped, GetPedBoneIndex(Ped, 28422), 0.05, 0.0, -0.085, 90.0, 90.0, 0.0, false, false, false, true, 2, true)

    if LoadAnimDictTimeout('pickup_object') then
        TaskPlayAnim(Ped, 'pickup_object', 'pickup_low', 8.0, -8.0, 900, 49, 0, false, false, false)
    end
    Citizen.Wait(700)

    local Mode, Target, Valid = 'hand', nil, false
    local Heading = GetEntityHeading(Ped)
    local Result
    Hint(Mode)

    while IsHoldingItem do
        Citizen.Wait(0)

        DisablePlayerFiring(PlayerId(), true)
        for _, Control in ipairs(BlockedControls) do DisableControlAction(0, Control, true) end
        BlockWeaponWheelThisFrame()

        -- Item was moved/removed meanwhile (robbed, used, ...).
        local Current = FW.Functions.GetPlayerData().inventory[Slot]
        if not Current or Current.Item ~= Item.Item then break end

        if not CanHold() or not DoesEntityExist(Prop) then break end
        if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then break end

        if Mode == 'hand' then
            if IsControlJustReleased(0, 38) then -- E
                Result = 'throw'
                break
            elseif IsControlJustReleased(0, 306) then -- N
                Mode = 'place'
                DetachEntity(Prop, true, true)
                SetEntityCollision(Prop, false, false)
                SetEntityAlpha(Prop, 190, false)
                FreezeEntityPosition(Prop, true)
                ClearPedTasks(Ped)
                Hint(Mode)
            end
        else
            local Hit = RayFromCamera(15.0)
            if Hit then
                Valid = #(Hit - GetEntityCoords(Ped)) <= Config.PlaceMaxDistance
                Target = Hit
                SetEntityCoordsNoOffset(Prop, Hit.x, Hit.y, Hit.z, false, false, false)
                SetEntityHeading(Prop, Heading)
                SetEntityAlpha(Prop, Valid and 190 or 70, false)
            else
                Valid = false
            end

            local Step = IsControlPressed(0, 21) and 1.5 or 7.5 -- Shift = fine
            if IsDisabledControlJustPressed(0, 15) or IsDisabledControlJustPressed(0, 17) or IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 99) or IsDisabledControlPressed(0, 175) then Heading = Heading + Step end
            if IsDisabledControlJustPressed(0, 14) or IsDisabledControlJustPressed(0, 16) or IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 81) or IsDisabledControlPressed(0, 174) then Heading = Heading - Step end

            if IsControlJustReleased(0, 191) or IsDisabledControlJustReleased(0, 24) then -- Enter / LMB
                if Valid and Target then
                    Result = 'place'
                    break
                else
                    FW.Functions.Notify("Je kan het niet zo ver weg plaatsen.", "error")
                end
            end
        end
    end

    IsHoldingItem = false
    Hint(false)

    local DropCoords, DropHeading, Thrown

    if Result == 'place' then
        DropCoords, DropHeading = Target, Heading
    elseif Result == 'throw' and DoesEntityExist(Prop) then
        Thrown = true
        DetachEntity(Prop, true, true)
        if LoadAnimDictTimeout('melee@thrown@streamed_core') then
            TaskPlayAnim(Ped, 'melee@thrown@streamed_core', 'plyr_takedown_front', -8.0, 8.0, 600, 49, 0, false, false, false)
        end
        Citizen.Wait(450)

        local From = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 0.6, 1.0)
        local Fwd = GetEntityForwardVector(Ped)
        SetEntityCoords(Prop, From.x, From.y, From.z, false, false, false, false)
        SetEntityCollision(Prop, true, true)
        FreezeEntityPosition(Prop, false)
        SetEntityDynamic(Prop, true)
        ActivatePhysics(Prop)
        SetEntityVelocity(Prop, Fwd.x * 9.0, Fwd.y * 9.0, 4.0)

        local Started, Still = GetGameTimer(), 0
        while GetGameTimer() - Started < 6000 do
            Citizen.Wait(100)
            if not DoesEntityExist(Prop) then break end

            if GetGameTimer() - Started > 600 and #GetEntityVelocity(Prop) < 0.2 then
                Still = Still + 1
                if Still >= 3 then break end
            else
                Still = 0
            end
        end

        local Landed = DoesEntityExist(Prop) and GetEntityCoords(Prop) or GetEntityCoords(Ped)
        if Landed.z < GetEntityCoords(Ped).z - 6.0 then
            Landed = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 1.0, -1.0)
        end

        DropCoords = Landed
        DropHeading = DoesEntityExist(Prop) and GetEntityHeading(Prop) or 0.0
    end

    -- Keep the thrown prop visible a moment so it doesn't blink before the synced one spawns.
    if Thrown and DoesEntityExist(Prop) then
        FreezeEntityPosition(Prop, true)
        local Local = Prop
        Citizen.SetTimeout(1200, function() if DoesEntityExist(Local) then DeleteEntity(Local) end end)
    elseif DoesEntityExist(Prop) then
        DeleteEntity(Prop)
    end

    ClearPedTasks(Ped)
    SetInteractDisabled(false)

    Citizen.SetTimeout(250, function() IsInventoryBusy = false end)

    if not DropCoords then return end
    FW.TriggerServer('fw-inventory:Server:PlaceItem', Slot, Amount, DropCoords, DropHeading or 0.0, Thrown == true)
end
exports("StartHoldMode", StartHoldMode)
exports("IsHoldingItem", function() return IsHoldingItem end)

-- NUI: context menu -> Give
RegisterNUICallback("HoldItem", function(Data, Cb)
    Cb("Ok")
    if CurrentInventory then CloseInventory() end
    Citizen.CreateThread(function()
        Citizen.Wait(150)
        StartHoldMode(Data.Slot, Data.Amount)
    end)
end)
