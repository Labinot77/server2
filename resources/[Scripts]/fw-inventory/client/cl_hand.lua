-- // Hand mode (ported from ox_inventory startPlaceMode) \\ --
-- "Give" in the inventory context menu puts the item in your hand:
--   [N]  aim mode -> place it exactly where you look ([Enter]/[LMB] confirm, scroll to rotate, [Shift] fine rotate)
--   [RMB]/[LMB] native GTA throw (like a grenade): the item rides an invisible WEAPON_BALL projectile
--   [E]  when you're looking at a player - give it to them (interact prompt)
--   [Esc] cancel (item stays in your inventory)
-- The item only leaves the inventory once it's placed / has landed (server: fw-inventory:Server:PlaceItem).

Config.PlaceMaxDistance = 5.0
Config.GiveDistance = 2.5        -- max distance between you and the player you give to
Config.GiveAimDistance = 6.0     -- how far the camera ray looks for a player

local GiveTarget, GiveRequest = false, false   -- ped currently aimed at / ped chosen via interact
local GiveInteractions = {}                    -- [ped] = interaction id

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

-- // Give: find the player you're looking at \\ --
-- 1) camera ray (world, vehicles, peds, objects) -> first thing hit must be a player ped
-- 2) head-to-head ray (world + objects only) -> nothing between you and them (no giving through walls/doors)
local function ShapeTest(From, To, Flags, Ignore)
    local Handle = StartExpensiveSynchronousShapeTestLosProbe(From.x, From.y, From.z, To.x, To.y, To.z, Flags, Ignore, 7)
    local _, Hit, HitCoords, _, Entity = GetShapeTestResult(Handle)
    return (Hit == 1 or Hit == true), HitCoords, Entity
end

local function GetCameraDirection()
    local Rot = GetGameplayCamRot(2)
    local Rx, Rz = math.rad(Rot.x), math.rad(Rot.z)
    return vector3(-math.sin(Rz) * math.abs(math.cos(Rx)), math.cos(Rz) * math.abs(math.cos(Rx)), math.sin(Rx))
end

local function FindGiveTarget(Ped)
    local From = GetGameplayCamCoord()
    local To = From + GetCameraDirection() * Config.GiveAimDistance
    local Hit, _, Entity = ShapeTest(From, To, 1 | 2 | 4 | 8 | 16, Ped)
    if not Hit or not Entity or Entity == 0 or GetEntityType(Entity) ~= 1 then return false end
    if Entity == Ped or not IsPedAPlayer(Entity) or IsEntityDead(Entity) then return false end

    if #(GetEntityCoords(Ped) - GetEntityCoords(Entity)) > Config.GiveDistance then return false end

    local MyHead = GetPedBoneCoords(Ped, 31086, 0.0, 0.0, 0.0)
    local TheirHead = GetPedBoneCoords(Entity, 31086, 0.0, 0.0, 0.0)
    local Blocked, BlockCoords = ShapeTest(MyHead, TheirHead, 1 | 16, Ped)
    if Blocked and #(BlockCoords - TheirHead) > 0.35 then return false end

    return Entity
end

local ThrowWeapon, ThrowModel = `WEAPON_BALL`, `w_am_baseball`

local function SetThrowWeapon(Ped, State)
    if State then
        GiveWeaponToPed(Ped, ThrowWeapon, 1, false, true)
        SetCurrentPedWeapon(Ped, ThrowWeapon, true)
    else
        RemoveWeaponFromPed(Ped, ThrowWeapon)
        SetCurrentPedWeapon(Ped, `WEAPON_UNARMED`, true)
    end
end

-- The ball the game just launched (the one in our hand is gone at this point).
local function FindProjectile(Ped)
    local Ends = GetGameTimer() + 1000
    repeat
        local Obj = GetClosestObjectOfType(GetEntityCoords(Ped), 4.0, ThrowModel, false, false, false)
        if Obj ~= 0 then return Obj end
        Citizen.Wait(0)
    until GetGameTimer() > Ends
end

local function ClearGiveInteractions()
    for TargetPed, Id in pairs(GiveInteractions) do
        pcall(function() exports.interact:RemoveInteraction(Id) end)
    end
    GiveInteractions = {}
end

-- One interact point on every nearby player; it only shows on the one you're aiming at.
local function RefreshGiveInteractions(Ped, Label)
    local MyCoords = GetEntityCoords(Ped)
    local Nearby = {}

    for _, PlayerIdx in ipairs(GetActivePlayers()) do
        local TargetPed = GetPlayerPed(PlayerIdx)
        if TargetPed ~= Ped and DoesEntityExist(TargetPed) and #(MyCoords - GetEntityCoords(TargetPed)) < 12.0 then
            Nearby[TargetPed] = true
            if not GiveInteractions[TargetPed] then
                local Ok, Id = pcall(function()
                    return exports.interact:AddLocalEntityInteraction({
                        entity = TargetPed,
                        offset = vec3(0.0, 0.0, 0.25),
                        distance = Config.GiveDistance + 1.5,
                        interactDst = Config.GiveDistance,
                        name = 'fw-inventory:give',
                        options = {
                            {
                                label = ('Geef %s'):format(Label),
                                action = function(Entity) GiveRequest = Entity or TargetPed end,
                                canInteract = function(Entity) return IsHoldingItem and GiveTarget ~= false and GiveTarget == (Entity or TargetPed) end,
                            },
                        },
                    })
                end)
                if Ok and Id then GiveInteractions[TargetPed] = Id end
            end
        end
    end

    for TargetPed, Id in pairs(GiveInteractions) do
        if not Nearby[TargetPed] then
            pcall(function() exports.interact:RemoveInteraction(Id) end)
            GiveInteractions[TargetPed] = nil
        end
    end
end

local PlaceControls = { 24, 25 }
local BlockedControls = { 14, 15, 16, 17, 37, 44, 81, 99, 140, 141, 142, 177, 200, 241, 242, 174, 175 }

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
    SetThrowWeapon(Ped, true)

    local Mode, Target, Valid = 'hand', nil, false
    local Heading = GetEntityHeading(Ped)
    local Result, GivePed
    local ItemData = Shared.Items[Item.Item]
    local GiveLabel = (ItemData and ItemData.Label or Item.Item) .. (Amount > 1 and (' (%sx)'):format(Amount) or '')
    local NextInteractRefresh = 0
    GiveTarget, GiveRequest = false, false
    Hint(Mode)

    while IsHoldingItem do
        Citizen.Wait(0)

        for _, Control in ipairs(BlockedControls) do DisableControlAction(0, Control, true) end
        BlockWeaponWheelThisFrame()

        -- Item was moved/removed meanwhile (robbed, used, ...).
        local Current = FW.Functions.GetPlayerData().inventory[Slot]
        if not Current or Current.Item ~= Item.Item then break end

        if not CanHold() or not DoesEntityExist(Prop) then break end
        if IsDisabledControlJustPressed(0, 200) then break end -- Esc only (177 also fires on RMB)

        if Mode == 'hand' then
            -- Hide the ball, our item prop is what you see in the hand.
            local Held = GetCurrentPedWeaponEntityIndex(Ped)
            if Held ~= 0 and IsEntityVisible(Held) then SetEntityVisible(Held, false, false) end

            if IsPedShooting(Ped) or GetAmmoInPedWeapon(Ped, ThrowWeapon) == 0 then
                Result = 'throw'
                break
            end

            -- Who are we looking at? Interact (and its [E] prompt) is only on while aiming at a player,
            -- so [E] gives instead of throws and no other prompt can steal the key meanwhile.
            if GetGameTimer() > NextInteractRefresh then
                RefreshGiveInteractions(Ped, GiveLabel)
                NextInteractRefresh = GetGameTimer() + 1000
            end

            local NewTarget = FindGiveTarget(Ped)
            if NewTarget ~= GiveTarget then
                GiveTarget = NewTarget
                SetInteractDisabled(GiveTarget == false)
                Hint(GiveTarget and 'give' or 'hand')
            end

            if GiveRequest then
                -- Re-check at the moment of giving.
                if FindGiveTarget(Ped) == GiveRequest then
                    GivePed = GiveRequest
                    Result = 'give'
                    break
                end
                GiveRequest = false
            end

            if IsControlJustReleased(0, 306) then -- N
                Mode = 'place'
                GiveTarget = false
                SetThrowWeapon(Ped, false)
                SetInteractDisabled(true)
                DetachEntity(Prop, true, true)
                SetEntityCollision(Prop, false, false)
                SetEntityAlpha(Prop, 190, false)
                FreezeEntityPosition(Prop, true)
                ClearPedTasks(Ped)
                Hint(Mode)
            end
        else
            DisablePlayerFiring(PlayerId(), true)
            for _, Control in ipairs(PlaceControls) do DisableControlAction(0, Control, true) end

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
    SetThrowWeapon(Ped, false)
    ClearGiveInteractions()
    GiveTarget, GiveRequest = false, false

    if Result == 'give' and GivePed then
        local ServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(GivePed))
        TaskTurnPedToFaceEntity(Ped, GivePed, 500)
        if LoadAnimDictTimeout('mp_common') then
            TaskPlayAnim(Ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 1600, 49, 0, false, false, false)
        end
        Citizen.Wait(900)
        if DoesEntityExist(Prop) then DeleteEntity(Prop) end
        ClearPedTasks(Ped)
        SetInteractDisabled(false)
        Citizen.SetTimeout(250, function() IsInventoryBusy = false end)
        FW.TriggerServer('fw-inventory:Server:GiveHeldItem', ServerId, Slot, Amount)
        return
    end

    local DropCoords, DropHeading, Thrown

    if Result == 'place' then
        DropCoords, DropHeading = Target, Heading
    elseif Result == 'throw' and DoesEntityExist(Prop) then
        Thrown = true
        local Projectile = FindProjectile(Ped)
        if Projectile then
            SetEntityVisible(Projectile, false, false)
            AttachEntityToEntity(Prop, Projectile, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        else
            Projectile = Prop -- fallback: drop it in front of you
            DetachEntity(Prop, true, true)
            SetEntityCollision(Prop, true, true)
            ActivatePhysics(Prop)
        end

        local Started, Still = GetGameTimer(), 0
        while GetGameTimer() - Started < 6000 do
            Citizen.Wait(100)
            if not DoesEntityExist(Projectile) then break end

            if GetGameTimer() - Started > 600 and #GetEntityVelocity(Projectile) < 0.2 then
                Still = Still + 1
                if Still >= 3 then break end
            else
                Still = 0
            end
        end

        local Landed = DoesEntityExist(Projectile) and GetEntityCoords(Projectile) or GetEntityCoords(Ped)
        if Landed.z < GetEntityCoords(Ped).z - 6.0 then
            Landed = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 1.0, -1.0)
        end

        DropCoords = Landed
        DropHeading = DoesEntityExist(Prop) and GetEntityHeading(Prop) or 0.0

        if Projectile ~= Prop and DoesEntityExist(Projectile) then
            DetachEntity(Prop, true, false)
            SetEntityCoords(Prop, Landed.x, Landed.y, Landed.z, false, false, false, false)
            SetEntityAsMissionEntity(Projectile, true, true)
            DeleteEntity(Projectile)
        end
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

-- Receiving end of a give: short take animation facing the giver.
RegisterNetEvent("fw-inventory:Client:ReceiveGiveAnim")
AddEventHandler("fw-inventory:Client:ReceiveGiveAnim", function(FromSource)
    local Ped = PlayerPedId()
    if IsPedInAnyVehicle(Ped, false) then return end

    local FromPlayer = GetPlayerFromServerId(FromSource)
    if FromPlayer ~= -1 then TaskTurnPedToFaceEntity(Ped, GetPlayerPed(FromPlayer), 500) end

    if LoadAnimDictTimeout('mp_common') then
        TaskPlayAnim(Ped, 'mp_common', 'givetake1_b', 8.0, -8.0, 1600, 49, 0, false, false, false)
    end
end)
