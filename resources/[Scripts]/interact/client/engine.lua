-- -- Engine interaction for autocare workers, attached to actual vehicles.

-- local DefaultOffset = vec3(0.0, 0.0, 0.0) -- added on top of the engine bone position

-- -- Per-model tweaks (local space: X side, Y forward/back, Z up/down)
-- EngineOffsets = {
--   -- [`comet7`] = vec3(0.0, 0.5, 0.2),
-- }


-- local SCAN_INTERVAL = 500
-- local SCAN_RADIUS = 25.0
-- local DROP_RADIUS = 40.0
-- local registered = {} -- [vehicle] = { id, coords, heading }
-- local isAutocare = false

-- -- Poll the (async) export; only accept a real boolean
-- CreateThread(function()
--   while true do
--     local ok, result = pcall(function()
--       return exports['fw-businesses']:IsAutocare()
--     end)
--     if ok and type(result) == 'boolean' then
--       isAutocare = result
--     end
--     Wait(5000)
--   end
-- end)

-- local function engineOptions(vehicle)
--   return {
--     {
--       name = 'interact:autocare_check_vehicle',
--       label = 'Inspect Vehicle',
--       canInteract = function()
--         return isAutocare
--       end,
--       action = function()
--         TriggerEvent('fw-businesses:Client:AutoCare:CheckVehicle', {}, vehicle)
--       end,
--     },
--   }
-- end

-- local function getEngineCoords(vehicle)
--     local model = GetEntityModel(vehicle)
--     local extra = EngineOffsets[model] or DefaultOffset
--     local localPos

--     local bone = GetEntityBoneIndexByName(vehicle, 'engine')

--     if bone ~= -1 then
--         local boneWorld = GetWorldPositionOfEntityBone(vehicle, bone)
--         localPos = GetOffsetFromEntityGivenWorldCoords(
--             vehicle,
--             boneWorld.x,
--             boneWorld.y,
--             boneWorld.z
--         )
--     else
--         local min, max = GetModelDimensions(model)
--         localPos = vec3(0.0, max.y, (min.z + max.z) / 2.0)
--     end

--     local o = localPos + extra

--     return GetOffsetFromEntityInWorldCoords(vehicle, o.x, o.y, o.z)
-- end

-- local function registerEngine(vehicle)
--   local id = exports.interact:AddInteraction({
--     coords = getEngineCoords(vehicle),
--     distance = 3.0,
--     interactDst = 1.5,
--     name = ('engine_%s'):format(vehicle),
--     options = engineOptions(vehicle),
--   })
--   registered[vehicle] = {
--     id = id,
--     coords = GetEntityCoords(vehicle),
--     heading = GetEntityHeading(vehicle),
--   }
-- end

-- local function unregisterEngine(vehicle)
--   local data = registered[vehicle]
--   if data and data.id then exports.interact:RemoveInteraction(data.id) end
--   registered[vehicle] = nil
-- end

-- CreateThread(function()
--   while true do
--     local playerCoords = GetEntityCoords(PlayerPedId())

--     if isAutocare then
--       for _, vehicle in ipairs(GetGamePool('CVehicle')) do
--         if not registered[vehicle] and #(playerCoords - GetEntityCoords(vehicle)) < SCAN_RADIUS then
--           registerEngine(vehicle)
--         end
--       end
--     end

--     for vehicle, data in pairs(registered) do
--       if not isAutocare or not DoesEntityExist(vehicle) then
--         unregisterEngine(vehicle)
--       else
--         local pos = GetEntityCoords(vehicle)
--         if #(playerCoords - pos) > DROP_RADIUS then
--           unregisterEngine(vehicle)
--         elseif #(pos - data.coords) > 0.05 or math.abs(GetEntityHeading(vehicle) - data.heading) > 1.0 then
--           unregisterEngine(vehicle)
--           registerEngine(vehicle)
--         end
--       end
--     end

--     Wait(SCAN_INTERVAL)
--   end
-- end)