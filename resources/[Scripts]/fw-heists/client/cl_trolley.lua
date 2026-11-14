local RobbingTrolley = false
-- Grab speed: every Space press adds Step (counted once per Cooldown ms), up to Max x normal, and it
-- slowly drops back to normal (Decay per frame) when you stop pressing.
local Speed = { Step = 0.1, Max = 1.6, Cooldown = 180, Decay = 0.0025 }
local Trollies = {}
local TrolleyTypes = {
    Cash = GetHashKey('ch_prop_ch_cash_trolly_01c'),
    Gold = GetHashKey('ch_prop_gold_trolly_01c')
}

function SpawnTrolley(Id, Type, Coords)
    if not TrolleyTypes[Type] then
        return print("Invalid Trolley Type.")
    end

    if Trollies[Id] and DoesEntityExist(Trollies[Id].Object) then
        print("Already exists, creating new.")
        DeleteTrolley(Id)
    end

    print("Creating trolley: ", Id, Type, Coords, TrolleyTypes[Type])

    exports['fw-assets']:RequestModelHash(TrolleyTypes[Type])
    local TrolleyObject = CreateObject(TrolleyTypes[Type], Coords.x, Coords.y, Coords.z, true, false, false)
    SetEntityHeading(TrolleyObject, Coords.w)
    PlaceObjectOnGroundProperly(TrolleyObject)

    Trollies[Id] = {
        Type = Type,
        Object = TrolleyObject,
    }
end

-- A trolley another client spawned (networked): make it grabbable here too (cl_fleeca_advanced.lua).
function RegisterTrolley(Id, Type, Object)
    if Trollies[Id] and Trollies[Id].Object == Object then return end
    Trollies[Id] = { Type = Type, Object = Object }
end

function DeleteTrolley(Id)
    NetworkRequestControlOfEntity(Trollies[Id].Object)
    while not NetworkHasControlOfEntity(Trollies[Id].Object) do
        Citizen.Wait(1)
    end

    DeleteEntity(Trollies[Id].Object)
    Trollies[Id] = {}
end

RegisterNetEvent("fw-heists:Client:Trolley:Grab")
AddEventHandler("fw-heists:Client:Trolley:Grab", function(Data, Entity)
    if RobbingTrolley then
        return
    end

    local Coords = GetEntityCoords(Entity)
    local TrolleyId, TrolleyType = 0, nil

    for k, v in pairs(Trollies) do
        if v.Object == Entity or #(GetEntityCoords(v.Object) - Coords) < 1.0 then
            TrolleyId, TrolleyType = k, v.Type
            break
        end
    end

    if TrolleyId == 0 or TrolleyType == nil then
        return print("Invalid Trolly or Trolly Type")
    end

    if DataManager.Get("trolley-" .. TrolleyId, 0) ~= 0 then

        return FW.Functions.Notify("Dit kan je nu niet doen..", "error")
    end
    
    DataManager.Set("trolley-" .. TrolleyId, 1)
    RobbingTrolley = true

    local PropsCache = {}
    local PlyCoords = GetEntityCoords(PlayerPedId())
    local BagProp, GrabProp = "hei_p_m_bag_var22_arm_s", "hei_prop_heist_cash_pile"

    if not IsWearingHandshoes() and math.random(1, 100) <= 85 then
        TriggerServerEvent("fw-police:Server:CreateEvidence", "Fingerprint")
    end

    if GetEntityModel(Entity) == TrolleyTypes.Gold then
        GrabProp = 'ch_prop_gold_bar_01a'
    end

    exports['fw-assets']:RequestModelHash(BagProp)
    exports['fw-assets']:RequestModelHash(GrabProp)
    exports['fw-assets']:RequestAnimationDict('anim@heists@ornate_bank@grab_cash')

    local GrabObject = CreateObject(GetHashKey(GrabProp), PlyCoords, true)
    FreezeEntityPosition(GrabObject, true)
    SetEntityInvincible(GrabObject, true)
    SetEntityNoCollisionEntity(GrabObject, PlayerPedId())
    SetEntityVisible(GrabObject, false, false)
    AttachEntityToEntity(GrabObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)

    table.insert(PropsCache, GrabObject)

    local StartedGrabbing = GetGameTimer()
    Citizen.CreateThread(function()
        while GetGameTimer() - StartedGrabbing < 37000 do
            Citizen.Wait(4)
            DisableControlAction(0, 73, true)
            if HasAnimEventFired(PlayerPedId(), GetHashKey("CASH_APPEAR")) then
                if not IsEntityVisible(GrabObject) then
                    SetEntityVisible(GrabObject, true, false)
                end
            end
            if HasAnimEventFired(PlayerPedId(), GetHashKey("RELEASE_CASH_DESTROY")) then
                if IsEntityVisible(GrabObject) then
                    SetEntityVisible(GrabObject, false, false)
                end
            end
        end
    end)

    NetworkRequestControlOfEntity(Entity)
    while not NetworkHasControlOfEntity(Entity) do
        Citizen.Wait(1)
    end

    local BagObject = CreateObject(GetHashKey(BagProp), GetEntityCoords(PlayerPedId()), true, false, false)
    table.insert(PropsCache, BagObject)

    local GrabAnimationOne = NetworkCreateSynchronisedScene(GetEntityCoords(Entity), GetEntityRotation(Entity), 2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(PlayerPedId(), GrabAnimationOne, "anim@heists@ornate_bank@grab_cash", "intro", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(BagObject, GrabAnimationOne, "anim@heists@ornate_bank@grab_cash", "bag_intro", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(GrabAnimationOne)
    Citizen.Wait(1500)

    local GrabAnimationTwo = NetworkCreateSynchronisedScene(GetEntityCoords(Entity), GetEntityRotation(Entity), 2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(PlayerPedId(), GrabAnimationTwo, "anim@heists@ornate_bank@grab_cash", "grab", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(BagObject, GrabAnimationTwo, "anim@heists@ornate_bank@grab_cash", "bag_grab", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(Entity, GrabAnimationTwo, "anim@heists@ornate_bank@grab_cash", "cart_cash_dissapear", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(GrabAnimationTwo)

    -- Space grabs faster. The rate goes to everyone (server relay), so the synced scene stays the same speed for all.
    -- X stops early: you keep what you grabbed so far (Grabbed = scene phase).
    local BASE, Rate, Sent, Deadline, LastPress, Grabbed = 1.3, 1.0, 1.0, GetGameTimer() + 60000, 0, 1.0
    SendNUIMessage({ action = 'hints', hints = { { key = 'space', label = 'Grab faster' }, { key = 'X', label = 'Stop grabbing' } } })
    while GetGameTimer() < Deadline do
        Citizen.Wait(0)
        DisableControlAction(0, 22, true)
        if IsDisabledControlJustPressed(0, 22) and GetGameTimer() - LastPress >= Speed.Cooldown then
            LastPress = GetGameTimer()
            Rate = math.min(Rate + Speed.Step, Speed.Max)
        end
        Rate = math.max(1.0, Rate - Speed.Decay)

        local Scene = NetworkGetLocalSceneFromNetworkId(GrabAnimationTwo)
        if IsDisabledControlJustPressed(0, 73) then
            Grabbed = Scene ~= -1 and GetSynchronizedScenePhase(Scene) or math.min(1.0, (GetGameTimer() - StartedGrabbing) / 37000)
            break
        end
        if Scene ~= -1 then
            SetSynchronizedSceneRate(Scene, BASE * Rate)
            if math.abs(Rate - Sent) >= 0.15 or (Rate == 1.0 and Sent ~= 1.0) then
                Sent = Rate
                TriggerServerEvent('fw-heists:Server:Trolley:Rate', GrabAnimationTwo, BASE * Rate)
            end
            if GetSynchronizedScenePhase(Scene) >= 0.99 then break end
        elseif GetGameTimer() - StartedGrabbing > 37000 then
            break -- scene not running locally: old fixed duration
        end
    end
    SendNUIMessage({ action = 'hints' })

    local GrabAnimationThree = NetworkCreateSynchronisedScene(GetEntityCoords(Entity), GetEntityRotation(Entity), 2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(PlayerPedId(), GrabAnimationThree, "anim@heists@ornate_bank@grab_cash", "exit", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(BagObject, GrabAnimationThree, "anim@heists@ornate_bank@grab_cash", "bag_exit", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(GrabAnimationThree)
    Citizen.Wait(1800)

    for k, v in pairs(PropsCache) do
        DeleteEntity(v)
    end
    
    DataManager.Set("trolley-" .. TrolleyId, 2)
    FW.TriggerServer("fw-heists:Server:Trolley:PayoutGrab", TrolleyId, Trollies[TrolleyId], Grabbed)

    Citizen.SetTimeout(250, function()
        DeleteTrolley(TrolleyId)
        RobbingTrolley = false
    end)
end)

RegisterNetEvent("fw-ui:Ready")
AddEventHandler("fw-ui:Ready", function()
    exports['fw-ui']:AddEyeEntry(GetHashKey("ch_prop_ch_cash_trolly_01c"), {
        Type = 'Model',
        Model = 'ch_prop_ch_cash_trolly_01c',
        SpriteDistance = 5.0,
        Distance = 1.3,
        Options = {
            {
                Name = 'heist_trolly',
                Icon = 'fas fa-hand-holding-usd',
                Label = 'Meenemen!',
                EventType = 'Client',
                EventName = 'fw-heists:Client:Trolley:Grab',
                EventParams = {},
                Enabled = function(Entity)
                    return true
                end,
            },
        }
    })
    exports['fw-ui']:AddEyeEntry(GetHashKey("ch_prop_gold_trolly_01c"), {
        Type = 'Model',
        Model = 'ch_prop_gold_trolly_01c',
        SpriteDistance = 5.0,
        Distance = 1.3,
        Options = {
            {
                Name = 'heist_trolly',
                Icon = 'fas fa-hand-holding-usd',
                Label = 'Meenemen!',
                EventType = 'Client',
                EventName = 'fw-heists:Client:Trolley:Grab',
                EventParams = {},
                Enabled = function(Entity)
                    return true
                end,
            },
        }
    })
end)
RegisterNetEvent("fw-heists:Client:Trolley:Rate", function(NetScene, Rate)
    local Scene = NetworkGetLocalSceneFromNetworkId(NetScene)
    if Scene ~= -1 then SetSynchronizedSceneRate(Scene, Rate) end
end)
