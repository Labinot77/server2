local animalModelHashes = {}
do
    local raw = LoadResourceFile(GetCurrentResourceName(), "data/animalModels.json")
    local models = raw and json.decode(raw) or {}
    for name in pairs(models) do
        animalModelHashes[GetHashKey(name)] = true
    end
end


local function GetTargetEntity(ped)
    if GetResourceState("np-target") == "started" then
        local ok, entity = pcall(function() return exports["np-target"]:GetCurrentEntity() end)
        if ok and entity and entity ~= 0 then return entity end
    end
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
    return vehicle ~= 0 and vehicle or nil
end

local function GetTargetCoords(ped)
    if GetResourceState("np-target") == "started" then
        local ok, coords = pcall(function() return exports["np-target"]:GetCurrentTargetCoords() end)
        if ok and coords then return coords end
    end
    return GetEntityCoords(ped)
end

exports("isAnimalModel", function(model)
    return animalModelHashes[model] == true
end)

local function LoadAnimDict(animDict)
    while true do
        if HasAnimDictLoaded(animDict) then
            break
        end
        RequestAnimDict(animDict)
        Wait(0)
    end
end
RegisterCommand("emotes", function()
    TriggerEvent("emotes:OpenMenu")
end)
local dogAnims = {}
dogAnims.dogsit = function(ped)
    TaskStartScenarioInPlace(ped, "WORLD_DOG_SITTING_ROTTWEILER", -1, true)
end
dogAnims.bark = function(ped)
    local animDict = "creatures@rottweiler@amb@world_dog_barking@idle_a"
    local animName = "idle_a"
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 1.0, 1.0, GetAnimDuration(animDict, animName), 0, 0, false, false, false)
end
dogAnims.bark2 = function(ped)
    local animDict = "creatures@rottweiler@melee@streamed_taunts@"
    local animName = "taunt_02"
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 1.0, 1.0, GetAnimDuration(animDict, animName), 0, 0, false, false, false)
end
dogAnims.bark3 = function(ped)
    local animDict = "creatures@rottweiler@melee@streamed_taunts@"
    local animName = "taunt_01"
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 1.0, 1.0, GetAnimDuration(animDict, animName), 0, 0, false, false, false)
end
dogAnims.bark4 = function(ped)
    TaskStartScenarioInPlace(ped, "WORLD_DOG_BARKING_SHEPHERD", -1, true)
end
dogAnims.bark5 = function(ped)
    local animDict = "creatures@rottweiler@melee@streamed_taunts@"
    local animName = "taunt_01"
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 1.0, 1.0, GetAnimDuration(animDict, animName), 48, 0, false, false, false)
end
dogAnims.beg = function(ped)
    local animDict = "creatures@rottweiler@tricks@"
    LoadAnimDict(animDict)
    local sequence = OpenSequenceTask()
    TaskPlayAnim(0, animDict, "beg_enter", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "beg_loop", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "beg_loop", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "beg_exit", 8.0, -8.0, -1, 4096, 0, false, false, false)
    CloseSequenceTask(sequence)
    TaskPerformSequence(ped, sequence)
    ClearSequenceTask()
end
dogAnims.paw = function(ped)
    local animDict = "creatures@rottweiler@tricks@"
    LoadAnimDict(animDict)
    local sequence = OpenSequenceTask()
    TaskPlayAnim(0, animDict, "sit_enter", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "paw_right_enter", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "paw_right_loop", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "paw_right_loop", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "paw_right_exit", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "sit_exit", 8.0, -8.0, -1, 4096, 0, false, false, false)
    CloseSequenceTask(sequence)
    TaskPerformSequence(ped, sequence)
    ClearSequenceTask()
end
dogAnims.pet = function(ped)
    local animDict = "creatures@rottweiler@tricks@"
    local animName = "petting_chop"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, animName, 1.0, 4.0, GetAnimDuration(animDict, animName), 0, 0, false, false, false)
    end
end
dogAnims.dump = function(ped)
    local animDict = "creatures@rottweiler@move"
    LoadAnimDict(animDict)
    local sequence = OpenSequenceTask()
    TaskPlayAnim(0, animDict, "dump_enter", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "dump_loop", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "dump_exit", 8.0, -8.0, -1, 4096, 0, false, false, false)
    CloseSequenceTask(sequence)
    TaskPerformSequence(ped, sequence)
    ClearSequenceTask()
end
dogAnims.pee = function(ped)
    local animDict = "creatures@rottweiler@move"
    LoadAnimDict(animDict)
    local sequence = OpenSequenceTask()
    TaskPlayAnim(0, animDict, "pee_right_enter", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "pee_right_idle", 8.0, -8.0, -1, 4096, 0, false, false, false)
    TaskPlayAnim(0, animDict, "pee_right_exit", 8.0, -8.0, -1, 4096, 0, false, false, false)
    CloseSequenceTask(sequence)
    TaskPerformSequence(ped, sequence)
    ClearSequenceTask()
end
dogAnims.indicateahead = function(ped)
    local animDict = "creatures@rottweiler@indication@"
    local animName = "indicate_ahead"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, animName, 1.0, 4.0, GetAnimDuration(animDict, animName), 0, 0, false, false, false)
    end
end
dogAnims.kennel = function(ped)
    local animDict = "creatures@rottweiler@amb@sleep_in_kennel@"
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, "sleep_in_kennel", 1000.0, -8.0, -1, 1, 0, false, false, false)
end
dogAnims.laydown = function(ped)
    local animDict = "creatures@rottweiler@move"
    local animName = "dying"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
dogAnims.carsit = function(ped)
    local animDict = "creatures@rottweiler@in_vehicle@std_car"
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if 0 == vehicle then
        return
    end
    local vehicleLayoutHash = GetVehicleLayoutHash(vehicle)
    if -1965057835 == vehicleLayoutHash or 919485892 == vehicleLayoutHash or -1838563680 == vehicleLayoutHash or 1768419516 == vehicleLayoutHash or 1576485197 == vehicleLayoutHash or 929009548 == vehicleLayoutHash or -497732145 == vehicleLayoutHash or -1659990386 == vehicleLayoutHash or -662028469 == vehicleLayoutHash or 1939145032 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@van"
    end
    if -2066252141 == vehicleLayoutHash or 1105669833 == vehicleLayoutHash or 542797648 == vehicleLayoutHash or 68566729 == vehicleLayoutHash or -1887744178 == vehicleLayoutHash or -782720499 == vehicleLayoutHash or -1150063973 == vehicleLayoutHash or 1630950849 == vehicleLayoutHash or -463340997 == vehicleLayoutHash or 2033852426 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@low_car"
    end
    if 434478421 == vehicleLayoutHash or 1816176348 == vehicleLayoutHash or 1710903184 == vehicleLayoutHash or 1663892749 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@4x4"
    end
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, "sit", 1000.0, -1000.0, -1, 33, 0, false, false, false)
end
dogAnims.carenter = function(ped)
    local animDict = "creatures@rottweiler@in_vehicle@std_car"
    local targetEntity = GetTargetEntity(ped)
    local vehicle = IsModelAVehicle(GetEntityModel(targetEntity))
    vehicle = targetEntity or vehicle
    if not vehicle or not targetEntity then
        vehicle = 0
    end
    if 0 == vehicle then
        return
    end
    local vehicleLayoutHash = GetVehicleLayoutHash(vehicle)
    if -1965057835 == vehicleLayoutHash or 919485892 == vehicleLayoutHash or -1838563680 == vehicleLayoutHash or 1768419516 == vehicleLayoutHash or 1576485197 == vehicleLayoutHash or 929009548 == vehicleLayoutHash or -497732145 == vehicleLayoutHash or -1659990386 == vehicleLayoutHash or -662028469 == vehicleLayoutHash or 1939145032 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@van"
    end
    if -2066252141 == vehicleLayoutHash or 1105669833 == vehicleLayoutHash or 542797648 == vehicleLayoutHash or 68566729 == vehicleLayoutHash or -1887744178 == vehicleLayoutHash or -782720499 == vehicleLayoutHash or -1150063973 == vehicleLayoutHash or 1630950849 == vehicleLayoutHash or -463340997 == vehicleLayoutHash or 2033852426 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@low_car"
    end
    if 434478421 == vehicleLayoutHash or 1816176348 == vehicleLayoutHash or 1710903184 == vehicleLayoutHash or 1663892749 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@4x4"
    end
    LoadAnimDict(animDict)
    local boneName = nil
    local doorIndex = nil
    local seat = nil
    local rotZ = 0.0
    local currentTargetCoords = GetTargetCoords(ped)
    local distance = #(currentTargetCoords - GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "seat_pside_f")))
    local distance2 = #(currentTargetCoords - GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "seat_pside_r")))
    local distance3 = #(currentTargetCoords - GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "seat_dside_r")))
    if distance < distance2 and distance < distance3 then
        boneName = "seat_pside_f"
        doorIndex = 1
        seat = 0
    elseif distance2 < distance3 then
        boneName = "seat_pside_r"
        doorIndex = 3
        seat = IsVehicleSeatFree(vehicle, 3) and 3 or 2
    else
        boneName = "seat_dside_r"
        doorIndex = 2

        if not IsVehicleSeatFree(vehicle, 3) then
            seat = 1
        end
        rotZ = 200.0
    end
    if 0 ~= GetPedInVehicleSeat(vehicle, seat) then
        return
    end
    Sync.SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    SetPedCanRagdoll(ped, false)
    Wait(300)
    local scene = NetworkCreateSynchronisedScene(0, 0, 0, 0, 0, rotZ, 2, false, false, 1065353216, 0, 1.3)
    NetworkAttachSynchronisedSceneToEntity(scene, vehicle, GetEntityBoneIndexByName(vehicle, boneName))
    NetworkAddPedToSynchronisedScene(ped, scene, animDict, "get_in", 1000.0, -8.0, 4.0, 0, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
    Wait(2000)
    TaskWarpPedIntoVehicle(ped, vehicle, seat)
    Wait(100)
    ForcePedAiAndAnimationUpdate(ped, true, true)
    TaskPlayAnim(ped, animDict, "sit", 8.0, -8.0, -1, 1, 0, false, false, false)
    Sync.SetVehicleDoorShut(vehicle, doorIndex, false)
    Wait(1000)
    SetPedCanRagdoll(ped, true)
end
dogAnims.carleave = function(ped)
    local animDict = "creatures@rottweiler@in_vehicle@std_car"
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if 0 == vehicle then
        return
    end
    local vehicleLayoutHash = GetVehicleLayoutHash(vehicle)
    if -1965057835 == vehicleLayoutHash or 919485892 == vehicleLayoutHash or -1838563680 == vehicleLayoutHash or 1768419516 == vehicleLayoutHash or 1576485197 == vehicleLayoutHash or 929009548 == vehicleLayoutHash or -497732145 == vehicleLayoutHash or -1659990386 == vehicleLayoutHash or -662028469 == vehicleLayoutHash or 1939145032 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@van"
    end
    if -2066252141 == vehicleLayoutHash or 1105669833 == vehicleLayoutHash or 542797648 == vehicleLayoutHash or 68566729 == vehicleLayoutHash or -1887744178 == vehicleLayoutHash or -782720499 == vehicleLayoutHash or -1150063973 == vehicleLayoutHash or 1630950849 == vehicleLayoutHash or -463340997 == vehicleLayoutHash or 2033852426 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@low_car"
    end
    if 434478421 == vehicleLayoutHash or 1816176348 == vehicleLayoutHash or 1710903184 == vehicleLayoutHash or 1663892749 == vehicleLayoutHash then
        animDict = "creatures@rottweiler@in_vehicle@4x4"
    end
    LoadAnimDict(animDict)
    local boneName = nil
    local doorIndex = nil
    local rotZ = 0.0
    local pedInVehicleSeat = GetPedInVehicleSeat(vehicle, 0)
    local pedInVehicleSeat2 = GetPedInVehicleSeat(vehicle, 2)
    local pedInVehicleSeat3 = GetPedInVehicleSeat(vehicle, 3)
    if pedInVehicleSeat == ped then
        boneName = "seat_pside_f"
        doorIndex = 1
    elseif pedInVehicleSeat2 == ped or pedInVehicleSeat3 == ped and 0 == pedInVehicleSeat2 then
        boneName = "seat_pside_r"
        doorIndex = 3
    else
        boneName = "seat_dside_r"
        doorIndex = 2
        rotZ = 200.0
    end
    SetPedCanRagdoll(ped, false)
    Sync.SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    local scene = NetworkCreateSynchronisedScene(0, 0, 0, 0, 0, rotZ, 2, false, false, 1065353216, 0, 1.3)
    NetworkAttachSynchronisedSceneToEntity(scene, vehicle, GetEntityBoneIndexByName(vehicle, boneName))
    NetworkAddPedToSynchronisedScene(ped, scene, animDict, "get_out", 1000.0, -8.0, 4.0, 0, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
    TaskLeaveVehicle(ped, vehicle, 16)
    ForcePedAiAndAnimationUpdate(ped, true, true)
    Wait(1500)
    ForcePedAiAndAnimationUpdate(ped, true, true)
    Sync.SetVehicleDoorShut(vehicle, doorIndex, false)
    ClearPedTasks(ped)
    Wait(4000)
    SetPedCanRagdoll(ped, true)
end
local smallDogAnims = {}
smallDogAnims.dogsit = function(ped)
    TaskStartScenarioInPlace(ped, "WORLD_DOG_SITTING_SMALL", -1, true)
end
smallDogAnims.bark = function(ped)
    local animDict = "creatures@pug@amb@world_dog_barking@idle_a"
    local animName = "idle_a"
    LoadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 1.0, 1.0, GetAnimDuration(animDict, animName), 0, 0, false, false, false)
end
smallDogAnims.laydown = function(ped)
    local animDict = "creatures@pug@move"
    local animName = "dying"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
local catAnims = {}
catAnims.catsleep = function(ped)
    local animDict = "creatures@cat@amb@world_cat_sleeping_ground@enter"
    local animName = "enter"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
catAnims.catsit = function(ped)
    local animDict = "creatures@cat@amb@world_cat_sleeping_ledge@idle_a"
    local animName = "idle_a"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
catAnims.catstretch = function(ped)
    local animDict = "creatures@cat@amb@peyote@enter"
    local animName = "enter"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
local bigCatAnims = {}
bigCatAnims.bigcatpace = function(ped)
    local animDict = "anim@scripted@island@hs4_scope_cctv_p1@panther@"
    local animName = "pace_v2"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
bigCatAnims.bigcatrest = function(ped)
    TaskStartScenarioInPlace(ped, "WORLD_MOUNTAIN_LION_REST", -1, true)
end
bigCatAnims.bigcatrest2 = function(ped)
    local animDict = "anim@scripted@island@hs4_scope_cctv_p1@panther@"
    local animName = "rest_base"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
bigCatAnims.bigcatrest3 = function(ped)
    local animDict = "anim@scripted@island@hs4_scope_cctv_p1@panther@"
    local animName = "rest_front"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
bigCatAnims.bigcatrest4 = function(ped)
    local animDict = "anim@scripted@island@hs4_scope_cctv_p1@panther@"
    local animName = "rest_left"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
bigCatAnims.bigcatrest5 = function(ped)
    local animDict = "creatures@cougar@amb@world_cougar_rest@idle_a"
    local animName = "idle_a"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
bigCatAnims.bigcatvehicle = function(ped)
    local animDict = "creatures@retriever@amb@world_dog_sitting@idle_a"
    local animName = "idle_a"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
bigCatAnims.bigcatattack = function(ped)
    local animDict = "creatures@cougar@melee@streamed_core@"
    local animName = "ground_attack_0"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
        Wait(2800)
        ClearPedTasks(ped)
    end
end
bigCatAnims.bigcatdead = function(ped)
    local animDict = "creatures@cougar@move"
    local animName = "dead_right"
    if IsPedArmed(ped, 7) then
        TriggerEvent("actionbar:setEmptyHanded")
    end
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
bigCatAnims.laydown = function(ped)
    local animDict = "creatures@cougar@move"
    local animName = "dying"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
local coyoteAnims = {}
coyoteAnims.coyoterest = function(ped)
    TaskStartScenarioInPlace(ped, "WORLD_COYOTE_REST", -1, true)
end
coyoteAnims.coyotehowl = function(ped)
    TaskStartScenarioInPlace(ped, "WORLD_COYOTE_HOWL", -1, true)
end
coyoteAnims.laydown = function(ped)
    local animDict = "creatures@coyote@move"
    local animName = "dying"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end
local deerAnims = {}
deerAnims.deergraze = function(ped)
    TaskStartScenarioInPlace(ped, "WORLD_DEER_GRAZING", -1, true)
end
deerAnims.laydown = function(ped)
    local animDict = "creatures@deer@move"
    local animName = "dying"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, animName, 1.0, -1, -1, 2, 0, false, false, false)
    end
end

local bearAnims = {}
bearAnims.sit = function(ped)
    local animDict = "bear@animation"
    local animName = "bearsquat"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 2, 0.0, false, false, false)
    end
end
bearAnims.salute = function(ped)
    local animDict = "bear@animation"
    local animName = "bearsalute"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 2, 0.0, false, false, false)
    end
end
bearAnims.dance = function(ped)
    local animDict = "bear@animation"
    local animName = "beardance"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 1, 0.0, false, false, false)
    end
end
bearAnims.yes = function(ped)
    local animDict = "bear@animation"
    local animName = "bearnod"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 1, 0.0, false, false, false)
    end
end
bearAnims.no = function(ped)
    local animDict = "bear@animation"
    local animName = "bearnopers"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 1, 0.0, false, false, false)
    end
end
bearAnims.wave = function(ped)
    local animDict = "bear@animation"
    local animName = "bearwave"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 0, 0.0, false, false, false)
    end
end
bearAnims.fall = function(ped)
    local animDict = "bear@animation"
    local animName = "bearfalling"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 2, 0.0, false, false, false)
    end
end
bearAnims.getup = function(ped)
    local animDict = "creatures@deer@getup"
    local animName = "getup_l"
    if IsEntityPlayingAnim(ped, animDict, animName, 3) then
        ClearPedSecondaryTask(ped)
    else
        LoadAnimDict(animDict)
        TaskPlayAnim(PlayerPedId(), animDict, animName, 2.0, 2.0, -1, 0, 0.0, false, false, false)
    end
end
local animalGroups = {}
animalGroups.dogs = {
    anims = dogAnims,
    models = {
        [1126154828] = true,
        [882848737] = true,
        [-1788665315] = true,
        [1318032802] = true,
        [351016938] = true,
        [-1113802996] = true,
        [-1799381006] = true,
        [623651616] = true,
        [298079245] = true,
        [-768232100] = true,
    },
}
animalGroups.smallDogs = {
    anims = smallDogAnims,
    models = {
        [-1384627013] = true,
        [-143182569] = true,
        [1832265812] = true,
        [-1458693400] = true,
        [1125994524] = true,
    },
}
animalGroups.cats = { anims = catAnims, models = { [1462895032] = true, [-2094420314] = true } }
animalGroups.bigcats = {
    anims = bigCatAnims,
    models = { [-417505688] = true, [307287994] = true, [1198333244] = true },
}
animalGroups.deerlikeModels = { anims = deerAnims, models = { [-664053099] = true, [-1759481309] = true } }
exports("GetAnimalEmotes", function()
    local entityModel = GetEntityModel(PlayerPedId())
    if not animalModelHashes[entityModel] then
        return false
    end
    for _, group in pairs(animalGroups) do
        if group.models[entityModel] then
            local emotes = {}
            for animName, action in pairs(group.anims) do
                local emote = {}
                local nextIndex = #emotes + 1
                emote.id = animName
                emote.label = animName
                emote.category = "animals"
                emote.action = action
                emotes[nextIndex] = emote
            end
            return emotes
        end
    end
    return false
end)
