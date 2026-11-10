-- Vehicles whose trunk is at the FRONT (mid/rear engine). Their "boot" bone is
-- in the wrong place, so they get a front interaction instead.
FrunkVehicles = {
  [`ninef`] = true,
  [`ninef2`] = true,
  [`adder`] = true,
  [`vagner`] = true,
  [`t20`] = true,
  [`infernus`] = true,
  [`zentorno`] = true,
  [`reaper`] = true,
  [`comet2`] = true,
  [`comet3`] = true,
  [`comet6`] = true,
  [`comet7`] = true,
  [`jester`] = true,
  [`jester2`] = true,
  [`cheetah`] = true,
  [`cheetah2`] = true,
  [`prototipo`] = true,
  [`turismor`] = true,
  [`pfister811`] = true,
  [`ardent`] = true,
  [`nero`] = true,
  [`nero2`] = true,
  [`tempesta`] = true,
  [`vacca`] = true,
  [`bullet`] = true,
  [`osiris`] = true,
  [`entityxf`] = true,
  [`turismo2`] = true,
  [`fmj`] = true,
  [`re7b`] = true,
  [`tyrus`] = true,
  [`italigtb`] = true,
  [`penetrator`] = true,
  [`monroe`] = true,
  [`stingergt`] = true,
  [`surfer`] = true,
  [`surfer2`] = true,
  [`gp1`] = true,
  [`autarch`] = true,
  [`tyrant`] = true,
  [`tenf`] = true,   -- 10F
  [`tenf2`] = true,  -- 10F Widebody
}

-- Optional per-model nudge (local offset) if the point looks off for a car.
FrunkOffsets = {
  [`tenf`] = vec3(0.0, -0.1, 0.1),
    [`comet6`] = vec3(0.0, 0, -0.3),
    [`comet7`] = vec3(0, 0, -0.05),

}

-- Global on purpose: config/settings.lua calls this from its canInteract checks.
function IsFrunkVehicle(entity)
  return FrunkVehicles[GetEntityModel(entity)] == true
end

local SCAN_INTERVAL = 1500
local SCAN_RADIUS = 25.0
local DROP_RADIUS = 40.0
local FRUNK_DOOR = 4 -- hood door index (rear trunk is 5)
local registered = {} -- [vehicle] = true

local function isUnlocked(entity)
  return GetVehicleDoorLockStatus(entity) < 2
end

local function isFrunkOpen(entity)
  return GetVehicleDoorAngleRatio(entity, FRUNK_DOOR) > 0.0 or IsVehicleDoorDamaged(entity, FRUNK_DOOR)
end

local function frunkOptions()
  return {
    {
      name = 'interact:trunk',
      label = 'Open Trunk',
      canInteract = function(entity)
        return isUnlocked(entity)
      end,
      action = function(entity)
        TriggerEvent('fw-inventory:Client:OpenTrunk', {}, entity)
      end,
    },
    {
      name = 'interact:enter_trunk',
      label = 'Enter Trunk',
      canInteract = function(entity)
        return isFrunkOpen(entity)
      end,
      action = function(entity)
        TriggerEvent('fw-assets:client:getin:trunk', {}, entity)
      end,
    },
    {
      name = 'interact:cornering',
      label = 'Start Selling',
      canInteract = function(entity)
        return exports['fw-inventory']:HasEnoughOfItem('weed-bag', 5)
          and not exports['fw-misc']:IsCorneringActive()
      end,
      action = function(entity)
        TriggerEvent('fw-misc:Client:StartCornering', { Type = 'weed' }, entity)
      end,
    },
    {
      name = 'interact:stop_cornering',
      label = 'Stop Selling',
      canInteract = function(entity)
        return exports['fw-misc']:IsCorneringActive('weed')
          and exports['fw-misc']:IsCorneringVehicle(entity)
      end,
      action = function(entity)
        TriggerEvent('fw-misc:Client:StopCornering', { Type = 'weed' }, entity)
      end,
    },
  }
end

local function registerFrunk(vehicle)
  local model = GetEntityModel(vehicle)
  local extra = FrunkOffsets[model] or vec3(0.0, 0.0, 0.0)

  -- Front-centre of the car from the model's bounding box (local space)
  local min, max = GetModelDimensions(model)
  local offset = vec3(0.0, max.y - 0.3, (min.z + max.z) / 2.0) + extra

  exports.interact:AddLocalEntityInteraction({
    entity = vehicle,
    offset = offset,
    distance = 3.0,
    interactDst = 1.5,
    options = frunkOptions(),
  })

  registered[vehicle] = true
end

CreateThread(function()
  while true do
    local playerCoords = GetEntityCoords(PlayerPedId())

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
      if not registered[vehicle] and IsFrunkVehicle(vehicle) then
        if #(playerCoords - GetEntityCoords(vehicle)) < SCAN_RADIUS then
          registerFrunk(vehicle)
        end
      end
    end

for vehicle in pairs(registered) do
    if not DoesEntityExist(vehicle) then
        -- The garage or another resource already deleted the vehicle.
        registered[vehicle] = nil
    elseif #(playerCoords - GetEntityCoords(vehicle)) > DROP_RADIUS then
        -- Remove the interaction only for an entity that still exists.
        local success, err = pcall(function()
            exports.interact:RemoveInteractionByEntity(vehicle)
        end)

        if not success then
            print(('[frunk] Failed to remove interaction: %s'):format(tostring(err)))
        end

        registered[vehicle] = nil
    end
end

    Wait(SCAN_INTERVAL)
  end
end)

