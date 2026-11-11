-- ============================================================================
-- fw-ui Eye bridge
-- Shows the options from settings.EyeEntries (copied from fw-ui Config.EyeEntries) as interact
-- points on nearby vehicles and peds, and fires them exactly like fw-ui does:
--   Client: TriggerEvent(EventName, EventParams, entity)
--   Server: TriggerServerEvent(EventName, EventParams, netId)
-- ============================================================================
local api = require 'client.api'
local settings = require 'config.settings'

local eye = settings.Eye
local entries = settings.EyeEntries

if not eye or not eye.enabled or not entries then return end

-- fw-core object, used by several Enabled() functions (FW.Functions.GetPlayerData, FW.SendCallback, ...)
CreateThread(function()
    while not FW do
        local ok, core = pcall(function() return exports['fw-core']:GetCoreObject() end)
        if ok and core then FW = core else Wait(500) end
    end
end)

-- The entity whose options are being checked. Same role as PeekingEntity in fw-ui.
EyeEntity = nil

-- Same as fw-ui's helper, so the copied Enabled() functions work unchanged.
function GetBoneDistanceFromVehicle(EntityType, BoneName)
    local entity = EyeEntity
    if entity and DoesEntityExist(entity) and GetEntityType(entity) == EntityType then
        local bone = GetEntityBoneIndexByName(entity, BoneName)
        local boneCoords = GetWorldPositionOfEntityBone(entity, bone)
        return #(boneCoords - GetEntityCoords(cache.ped))
    end

    return 99999.0
end

-- Same class mapping as fw-ui/client/cl_peek.lua
local function getVehicleCategory(vehicle)
    local class = GetVehicleClass(vehicle)
    if class == 8 then return 'motorcycle' end
    if class == 14 then return 'watercraft' end
    if class == 15 or class == 16 then return 'aircraft' end
    if class == 21 then return 'train' end
    return 'vehicles'
end

-- ----------------------------------------------------------------------------
-- Enabled() results are evaluated in a background thread and cached, so the render thread never
-- runs exports / server callbacks every frame.
-- ----------------------------------------------------------------------------
local results = {}  -- [entity] = { [eyeOption] = bool }
local registered = {} -- [entity] = { id = interactionId, category = string }
local dirty = false

local function fire(option, entity)
    if (option.EventType or 'Client'):lower() == 'client' then
        TriggerEvent(option.EventName, option.EventParams, entity)
    else
        local netId = entity and NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or nil
        TriggerServerEvent(option.EventName, option.EventParams, netId)
    end

    -- Re-check right away so options like Start/Stop Selling swap without delay.
    results[entity] = nil
    dirty = true
end

local converted = {} -- [category] = interact options
for category, entry in pairs(entries) do
    local skip = {}
    for _, name in ipairs(eye.skip and eye.skip[category] or {}) do skip[name] = true end

    local list = {}
    for _, option in ipairs(entry.Options or {}) do
        if not skip[option.Name] then
            list[#list + 1] = {
                name = ('eye:%s:%s'):format(category, option.Name),
                label = option.Label,
                canInteract = function(entity)
                    local cached = results[entity]
                    return cached ~= nil and cached[option] == true
                end,
                action = function(entity)
                    fire(option, entity)
                end,
            }
            list[#list].eye = option
        end
    end

    converted[category] = list
end

local function evaluate(entity, category)
    local cached = {}
    EyeEntity = entity
    for _, opt in ipairs(converted[category]) do
        local ok, enabled = pcall(opt.eye.Enabled, entity)
        cached[opt.eye] = ok and enabled and true or false
    end
    EyeEntity = nil
    results[entity] = cached
end

local function register(entity, category, distance, interactDst)
    local options = converted[category]
    if not options or #options == 0 then return end

    local id = api.addEntityPoint({
        name = ('eye:%s:%s'):format(category, entity),
        entity = entity,
        options = options,
        distance = distance,
        interactDst = interactDst,
    })

    if id then
        registered[entity] = { id = id, category = category, distance = distance }
    end
end

local function unregister(entity)
    local data = registered[entity]
    if data and api.hasInteraction(data.id) then
        api.removeInteraction(data.id)
    end
    registered[entity] = nil
    results[entity] = nil
end

-- Scan for vehicles / peds to put Eye points on.
CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)

        local vehicles = GetGamePool('CVehicle')
        for i = 1, #vehicles do
            local vehicle = vehicles[i]
            if not registered[vehicle] and #(playerCoords - GetEntityCoords(vehicle)) <= eye.vehicleScanRadius then
                local min, max = GetModelDimensions(GetEntityModel(vehicle))
                local size = max - min
                local reach = math.max(size.x, size.y) * 0.5 + eye.vehicleReach
                register(vehicle, getVehicleCategory(vehicle), reach + 1.0, reach)
            end
        end

        local peds = GetGamePool('CPed')
        for i = 1, #peds do
            local ped = peds[i]
            if ped ~= cache.ped and not registered[ped] and #(playerCoords - GetEntityCoords(ped)) <= eye.pedScanRadius then
                register(ped, 'peds', eye.pedDistance, eye.pedInteractDst)
            end
        end

        for entity, data in pairs(registered) do
            if not DoesEntityExist(entity) or not api.hasInteraction(data.id) then
                unregister(entity)
            else
                local radius = data.category == 'peds' and eye.pedScanRadius or eye.vehicleScanRadius
                if #(playerCoords - GetEntityCoords(entity)) > radius + 5.0 then
                    unregister(entity)
                end
            end
        end

        Wait(eye.scanInterval)
    end
end)

-- Re-check Enabled() for the points the player is close enough to see.
CreateThread(function()
    local waited = 0
    while true do
        if not dirty and waited < eye.refreshInterval then
            Wait(50)
            waited += 50
        else
            dirty, waited = false, 0
            local playerCoords = GetEntityCoords(cache.ped)
            -- Snapshot: Enabled() may yield (FW.SendCallback) while the scan thread edits `registered`.
            local snapshot = {}
            for entity, data in pairs(registered) do snapshot[entity] = data end

            for entity, data in pairs(snapshot) do
                if registered[entity] and DoesEntityExist(entity) and #(playerCoords - GetEntityCoords(entity)) <= data.distance then
                    evaluate(entity, data.category)
                else
                    results[entity] = nil
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for entity in pairs(registered) do unregister(entity) end
end)
