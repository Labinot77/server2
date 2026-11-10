local FW = exports['fw-core']:GetCoreObject()

local DELETE_KEY = 178

local Action = {}
local isDoingAction = false
local wasCancelled = false
local isAnim = false
local isProp = false
local isPropTwo = false
local propEntity = nil
local propTwoEntity = nil
local runProgThread = false

local function AttachProp(data)
    RequestModel(data.model)
    local hash = GetHashKey(data.model)
    while not HasModelLoaded(hash) do Wait(0) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local entity = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)

    local bone = data.bone or 60309
    local pos = data.coords or { x = 0.0, y = 0.0, z = 0.0 }
    local rot = data.rotation or { x = 0.0, y = 0.0, z = 0.0 }

    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, bone), pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 0, true)
    return entity
end

local function RemoveProp(entity)
    if not entity or not DoesEntityExist(entity) then return end
    NetworkRequestControlOfEntity(entity)
    SetEntityAsMissionEntity(entity, true, true)
    DetachEntity(entity, true, true)
    DeleteEntity(entity)
end

local function DisableActions()
    local disables = Action.controlDisables or {}

    if disables.disableMouse then
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 106, true)
    end

    if disables.disableMovement then
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 36, true)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 75, true)
        DisableControlAction(27, 75, true)
    end

    if disables.disableCarMovement then
        DisableControlAction(0, 63, true)
        DisableControlAction(0, 64, true)
        DisableControlAction(0, 71, true)
        DisableControlAction(0, 72, true)
        DisableControlAction(0, 75, true)
    end

    if disables.disableCombat then
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(1, 37, true)
        DisableControlAction(0, 47, true)
        DisableControlAction(0, 58, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 143, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
        DisableControlAction(0, 257, true)
    end
end

local function ActionCleanup()
    local ped = PlayerPedId()
    local anim = Action.animation

    if anim then
        if anim.task or (anim.animDict and anim.anim) then
            ClearPedSecondaryTask(ped)
            if anim.animDict and anim.anim then StopAnimTask(ped, anim.animDict, anim.anim, 1.0) end
        else
            ClearPedTasks(ped)
        end
    end

    EnableControlAction(0, 24, true)
    EnableControlAction(0, 25, true)
    DisablePlayerFiring(PlayerId(), false)

    RemoveProp(propEntity)
    RemoveProp(propTwoEntity)
    propEntity, propTwoEntity = nil, nil
    isProp, isPropTwo = false, false
    runProgThread = false
end

local function ActionStart()
    runProgThread = true

    CreateThread(function()
        while runProgThread do
            if isDoingAction then
                local ped = PlayerPedId()
                local anim = Action.animation

                if anim and anim.animDict and anim.anim and not IsEntityPlayingAnim(ped, anim.animDict, anim.anim, 3) then
                    isAnim = false
                end

                if not isAnim then
                    if anim then
                        if anim.task then
                            TaskStartScenarioInPlace(ped, anim.task, 0, true)
                        elseif anim.animDict and anim.anim then
                            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                                exports['fw-assets']:RequestAnimationDict(anim.animDict)
                                TaskPlayAnim(ped, anim.animDict, anim.anim, 3.0, 3.0, -1, anim.flags or 1, 0, false, false, false)
                            end
                        end
                    end
                    isAnim = true
                end

                if not isProp and Action.prop and Action.prop.model then
                    propEntity = AttachProp(Action.prop)
                    isProp = true
                end

                if not isPropTwo and Action.propTwo and Action.propTwo.model then
                    propTwoEntity = AttachProp(Action.propTwo)
                    isPropTwo = true
                end

                DisableActions()
            end

            Wait(0)
        end
    end)
end

local function Cancel()
    isDoingAction = false
    wasCancelled = true

    ActionCleanup()
    SendUIMessage("Progressbar", "Cancel", {})
end

local function Finish()
    isDoingAction = false
    ActionCleanup()
end

local function Process(action, start, tick, finish)
    print("Progressbar: Process called with action:", action.label, "duration:", action.duration)
    if IsEntityDead(PlayerPedId()) and not action.useWhileDead then
        return FW.Functions.Notify("Cant do that!", "error")
    end

    if isDoingAction then
        return FW.Functions.Notify("You are already doing something!", "error")
    end

    Action = action
    isDoingAction = true
    wasCancelled = false
    isAnim = false
    isProp = false
    isPropTwo = false

    ActionStart()

    SendUIMessage("Progressbar", "Progress", {
        Duration = Action.duration,
        Label = Action.label,
    })

    CreateThread(function()
        if start then start() end

        while isDoingAction do
            Wait(1)

            if tick then tick() end

            if IsControlJustPressed(0, DELETE_KEY) and Action.canCancel then
                TriggerEvent("progressbar:client:cancel")
            end

            if IsEntityDead(PlayerPedId()) and not Action.useWhileDead then
                TriggerEvent("progressbar:client:cancel")
            end

            if Action.cancelOnRagdoll and (IsPedRagdoll(PlayerPedId()) or IsPedFalling(PlayerPedId())) then
                TriggerEvent("progressbar:client:cancel")
            end
        end

        if finish then finish(wasCancelled) end
    end)
end

-- UI finished animating
RegisterNUICallback("Progressbar/Finish", function(_, cb)
    Finish()
    cb("Ok")
end)

-- Events (unchanged names, so existing TriggerEvent calls keep working)
RegisterNetEvent("progressbar:client:ToggleBusyness", function(bool) isDoingAction = bool end)
RegisterNetEvent("progressbar:client:progress", function(action, finish) Process(action, nil, nil, finish) end)
RegisterNetEvent("progressbar:client:ProgressWithStartEvent", function(action, start, finish) Process(action, start, nil, finish) end)
RegisterNetEvent("progressbar:client:ProgressWithTickEvent", function(action, tick, finish) Process(action, nil, tick, finish) end)
RegisterNetEvent("progressbar:client:ProgressWithStartAndTick", function(action, start, tick, finish) Process(action, start, tick, finish) end)
RegisterNetEvent("progressbar:client:cancel", Cancel)

-- Exports
exports("Progress", function(action, finish) Process(action, nil, nil, finish) end)
exports("ProgressWithStartEvent", function(action, start, finish) Process(action, start, nil, finish) end)
exports("ProgressWithTickEvent", function(action, tick, finish) Process(action, nil, tick, finish) end)
exports("ProgressWithStartAndTick", function(action, start, tick, finish) Process(action, start, tick, finish) end)
exports("GetTaskBarStatus", function() return isDoingAction end)