-- Vehicles with the engine at the back; their trunk sits on a different door index.
local MID_ENGINE_VEHICLES = {
  [`ninef`] = true,
  [`adder`] = true,
  [`vagner`] = true,
  [`t20`] = true,
  [`infernus`] = true,
  [`zentorno`] = true,
  [`reaper`] = true,
  [`comet2`] = true,
  [`comet3`] = true,
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
  [`ninef2`] = true,
  [`stingergt`] = true,
  [`surfer`] = true,
  [`surfer2`] = true,
  [`gp1`] = true,
  [`autarch`] = true,
  [`tyrant`] = true,
}

local function toggleVehicleDoor(vehicle, door)
  if GetVehicleDoorLockStatus(vehicle) < 2 then
    if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
      SetVehicleDoorShut(vehicle, door, false)
    else
      SetVehicleDoorOpen(vehicle, door, false)
    end
  end
end

-- ============================================================================
-- Helpers used by the options below
-- ============================================================================
local FW
local function core()
  if not FW then FW = exports['fw-core']:GetCoreObject() end
  return FW
end

local function isOnDutyPolice()
  local data = core().Functions.GetPlayerData()
  return data.job and data.job.name == 'police' and data.job.onduty
end

local function isNotPolice()
  local data = core().Functions.GetPlayerData()
  return not data.job or data.job.name ~= 'police'
end

local function playerNearby()
  local player, distance = core().Functions.GetClosestPlayer()
  return player ~= -1 and distance <= 2.0
end

-- 'car', 'motorcycle', 'boat', 'aircraft' or 'train'
local function vehicleType(entity)
  local class = GetVehicleClass(entity)
  if class == 8 then return 'motorcycle' end
  if class == 14 then return 'boat' end
  if class == 15 or class == 16 then return 'aircraft' end
  if class == 21 then return 'train' end
  return 'car'
end

local function isCar(entity) return vehicleType(entity) == 'car' end

local function isTrunkOpen(entity)
  return GetVehicleDoorAngleRatio(entity, 5) > 0.0 or IsVehicleDoorDamaged(entity, 5)
end

-- canInteract runs every frame, so the sanitation task (a server callback) is fetched in the
-- background at most every 2 seconds instead of blocking the draw loop.
local sanitationTask, sanitationChecked, sanitationPending = nil, 0, false
local function getSanitationTaskId(job)
  if not sanitationPending and GetGameTimer() - sanitationChecked > 2000 then
    sanitationPending, sanitationChecked = true, GetGameTimer()
    CreateThread(function()
      local ok, task = pcall(core().SendCallback, 'fw-jobmanager:Server:GetGroupCurrentTask', job.CurrentJob, job.CurrentGroup.Id)
      sanitationTask = ok and task and task.TaskId or nil
      sanitationPending = false
    end)
  end
  return sanitationTask
end

local function canStealRim(entity)
  return exports['fw-inventory']:HasEnoughOfItem('screwdriver', 1)
end

local stealRimOption = {
  name = 'interact:steal_rim',
  label = 'Steal Rim',
  canInteract = canStealRim,
  action = function(entity)
    TriggerEvent('fw-vehicles:Client:StealRim', {}, entity)
  end,
}

local wheelOptions = { stealRimOption }

local towRopeOptions = {
  {
    name = 'interact:attach_rope',
    label = 'Attach Tow Rope',
    canInteract = function(entity)
      return exports['fw-inventory']:HasEnoughOfItem('tow-rope', 1)
    end,
    action = function(entity)
      TriggerEvent('fw-heists:Client:AttachRope', {}, entity)
    end,
  },
  {
    name = 'interact:detach_rope',
    label = 'Detach Tow Rope',
    canInteract = function(entity)
      return exports['fw-heists']:IsRopeAttached(entity)
    end,
    action = function(entity)
      TriggerEvent('fw-heists:Client:DetachRope', {}, entity)
    end,
  },
}

local Settings = {
  Debug = GetConvar('debug', 'false') == 'true' and true or false, -- Enable / Disable debug mode

  Textures = {                                                     -- Do not change (files in ui/hud)
    key = 'key',
    dot = 'dot',
    crosshair = 'crosshair',
    font = 'font',
  },

  -- Sizes are fractions of screen height (divide the pixel size at 1080p by 1080).
  Prompt = {
    key = 'E',              -- Letter shown in the key badge (the control itself is INPUT_PICKUP / 38)
    uppercase = true,       -- Show labels in uppercase
    textHeight = 0.0125,    -- Cap height of the label text (~13px at 1080p)
    keySize = 0.0167,       -- Key badge size (~18px)
    keyTextHeight = 0.0095, -- Cap height of the letter inside the badge
    keyGap = 0.0075,        -- Space between the badge and the label
    dotSize = 0.0155,       -- Interaction point dot (~16px)
    crosshairSize = 0.0055, -- Centre-screen crosshair dot (~6px incl. shadow)
    crosshair = true,       -- Draw the crosshair dot while interaction points are nearby
    hoverRadius = 0.06,     -- How close (screen space) the crosshair must be to a point to select it
    rowSpacing = 0.024,
    textColor = { 255, 255, 255, 255 },
    keyColor = { 255, 255, 255, 255 },
    keyTextColor = { 20, 20, 20, 255 },
    dimmedAlpha = 140, -- Alpha of non-selected options when a point has several
    shadowAlpha = 110, -- Text drop shadow, 0 to disable
  },

  Disable = {
    onDeath = true,    -- Disable interactions on death
    onNuiFocus = true, -- Disable interactions while NUI is focused
    onVehicle = true,  -- Disable interactions while in a vehicle
    onHandCuff = true, -- Disable interactions while handcuffed
  },

  -- Nearby object distance check.
  nearbyObjectDistance = 20.0, -- Keep it at 15.0 at minimum.
  nearbyVehicleDistance = 8.0, -- Vehicles closer than this get their bone points (8m so long vehicles like the benson/flatbed work from the back)

  -- Line of sight: points behind walls / objects are hidden and can't be used.
  LineOfSight = {
    enabled = true,
    origin = 'ped',   -- 'ped' = from the player's head (physical reach), 'camera' = from the game camera
    interval = 100,   -- ms between checks
    -- What blocks the ray: 1 = map/world (walls), 2 = vehicles, 16 = objects/props. Peds never block.
    flags = 1 | 2 | 16,
    -- Shape test options: 4 = ignore things without collision. Use 5 to also look through glass.
    options = 4,
    -- If the ray hits something within this distance of the point it still counts as visible
    -- (points are often placed slightly inside a counter/prop). Raise it if valid points disappear,
    -- lower it if you can still reach through thin walls.
    tolerance = 0.25,
  },

  -- Options added to every nearby ped (not players' own ped).
  pedDefaults = {
    enabled = true,
    scanDistance = 5.0,
    distance = 3.0,
    interactDst = 1.8,
    options = {
      {
        name = 'interact:corner_sell',
        label = 'Sell',
        canInteract = function(entity)
          return not IsPedDeadOrDying(entity)
              and exports['fw-misc']:IsCorneringActive()
              and exports['fw-misc']:IsCorneringPed(entity)
        end,
        action = function(entity)
          TriggerEvent('fw-misc:Client:CorneringSale', {}, entity)
        end,
      },
    },
  },




  vehicleBoneDefaults = {
    enabled = true,
    bones = {
      ['boot'] = {
        distance = 3.0,
        interactDst = 1.5,
        offset = vec3(0.0, -10.3, 0.0),
        options = {
          {
            name = 'interact:trunk',
            label = 'Open Trunk',
            canInteract = function(entity, coords, args)
              return not IsFrunkVehicle(entity)
            end,
            action = function(entity, distance, args)
              TriggerEvent('fw-inventory:Client:OpenTrunk', {}, entity)
            end,
          },
          {
            name = 'interact:enter_trunk',
            label = 'Enter Trunk',
            canInteract = function(entity, coords, args)
              return not IsFrunkVehicle(entity)
                  and (GetVehicleDoorAngleRatio(entity, 5) > 0.0 or IsVehicleDoorDamaged(entity, 5))
            end,
            action = function(entity, distance, args)
              TriggerEvent('fw-assets:client:getin:trunk', {}, entity)
            end,
          },
          {
            name = 'interact:cornering',
            label = 'Start Selling',
            canInteract = function(entity, coords, args)
              return not IsFrunkVehicle(entity)
                  and exports['fw-inventory']:HasEnoughOfItem('weed-bag', 5)
                  and not exports['fw-misc']:IsCorneringActive()
            end,
            action = function(entity, distance, args)
              TriggerEvent('fw-misc:Client:StartCornering', { Type = 'weed' }, entity)
            end,
          },
          {
            name = 'interact:stop_cornering',
            label = 'Stop Selling',
            canInteract = function(entity, coords, args)
              return not IsFrunkVehicle(entity)
                  and exports['fw-misc']:IsCorneringActive('weed')
                  and exports['fw-misc']:IsCorneringVehicle(entity)
            end,
            action = function(entity, distance, args)
              TriggerEvent('fw-misc:Client:StopCornering', { Type = 'weed' }, entity)
            end,
          },
          {
            name = 'interact:meth_cornering',
            label = 'Start Selling Meth',
            canInteract = function(entity)
              return not IsFrunkVehicle(entity)
                  and exports['fw-inventory']:HasEnoughOfItem('1gmeth', 5)
                  and not exports['fw-misc']:IsCorneringActive()
            end,
            action = function(entity)
              TriggerEvent('fw-misc:Client:StartCornering', { Type = 'meth' }, entity)
            end,
          },
          {
            name = 'interact:stop_meth_cornering',
            label = 'Stop Selling Meth',
            canInteract = function(entity)
              return not IsFrunkVehicle(entity)
                  and exports['fw-misc']:IsCorneringActive('meth')
                  and exports['fw-misc']:IsCorneringVehicle(entity)
            end,
            action = function(entity)
              TriggerEvent('fw-misc:Client:StopCornering', { Type = 'meth' }, entity)
            end,
          },
          {
            name = 'interact:scan_plate',
            label = 'Check Plate',
            canInteract = function(entity)
              return isCar(entity) and isOnDutyPolice()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:ScanPlate', {}, entity)
            end,
          },
          {
            name = 'interact:sanitation_throw_trash',
            label = 'Throw Trash Bag',
            canInteract = function(entity)
              if GetEntityModel(entity) ~= `trash` or not isTrunkOpen(entity) then return false end
              local job = exports['fw-jobmanager']:GetMyJob()
              if job.CurrentJob ~= 'sanitation' then return false end
              local task = getSanitationTaskId(job)
              return task == 4 or task == 6
            end,
            action = function(entity)
              TriggerEvent('fw-jobmanager:Client:Sanitation:ThrowInTrash', {}, entity)
            end,
          },
          {
            name = 'interact:postop_grab_goods',
            label = 'Grab Goods',
            canInteract = function(entity)
              if GetEntityModel(entity) ~= `benson` then return false end
              if exports['fw-jobmanager']:GetMyJob().CurrentJob ~= 'postop' then return false end
              return exports['fw-jobmanager']:GetCurrentTaskId() == 4
            end,
            action = function(entity)
              TriggerEvent('fw-jobmanager:Client:PostOp:GrabGoods', {}, entity)
            end,
          },
          {
            name = 'interact:oxy_deliver_package',
            label = 'Deliver Goods',
            canInteract = function(entity)
              if exports['fw-jobmanager']:GetMyJob().CurrentJob ~= 'oxy' then return false end
              local task = exports['fw-jobmanager']:GetCurrentTaskId()
              return (task == 4 or task == 6) and exports['fw-jobmanager']:IsOxyVehicle(entity)
            end,
            action = function(entity)
              TriggerEvent('fw-jobmanager:Client:Oxy:DeliverGoods', {}, entity)
            end,
          },
        },
      },
      ['bumper_f'] = {
        distance = 3.0,
        interactDst = 1.5,
        options = {
          {
            name = 'interact:scan_plate_front',
            label = 'Check Plate',
            canInteract = function(entity)
              return isCar(entity) and isOnDutyPolice()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:ScanPlate', {}, entity)
            end,
          },
        },
      },
      ['door_dside_f'] = {
        distance = 3.0,
        interactDst = 1.5,
        options = {
          {
            name = 'interact:seat_in_vehicle',
            label = 'Seat in Vehicle',
            canInteract = function(entity)
              return isCar(entity) and playerNearby()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:SeatVehicle', {}, entity)
            end,
          },
          {
            name = 'interact:unseat_from_vehicle',
            label = 'Unseat from Vehicle',
            canInteract = function(entity)
              return isCar(entity) and playerNearby()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:UnseatVehicle', {}, entity)
            end,
          },
          {
            name = 'interact:check_for_tampering',
            label = 'Check for Tampering',
            canInteract = function(entity)
              return isCar(entity) and isOnDutyPolice()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:CheckTampering', {}, entity)
            end,
          },
          {
            name = 'interact:inspect_vin',
            label = 'Inspect VIN',
            canInteract = function(entity)
              return isCar(entity) and isOnDutyPolice()
            end,
            action = function(entity)
              TriggerEvent('fw-vehicles:Client:InspectVIN', {}, entity)
            end,
          },
          {
            name = 'interact:boosting_vin_scratch',
            label = 'Scratch VIN',
            canInteract = function(entity)
              return exports['fw-boosting']:IsVehicleScratchable(entity)
            end,
            action = function(entity)
              TriggerEvent('fw-boosting:Client:ScratchVin', {}, entity)
            end,
          },
        },
      },
      -- Fuel, towing and drop-offs sit at the rear left wheel (like fw-ui's wheel_lr checks).
      ['wheel_lr'] = {
        distance = 3.0,
        interactDst = 1.5,
        options = {
          {
            name = 'interact:vehicle_refuel',
            label = 'Refuel Vehicle',
            canInteract = function(entity)
              local t = vehicleType(entity)
              return (t == 'car' or t == 'motorcycle') and exports['fw-vehicles']:CanRefuel()
            end,
            action = function(entity)
              TriggerEvent('fw-vehicles:Client:Fuel:RefuelVehicle', {}, entity)
            end,
          },
          {
            name = 'interact:tow_vehicle',
            label = 'Tow Vehicle',
            canInteract = function(entity)
              return GetEntityModel(entity) == `flatbed` and not exports['fw-jobmanager']:IsTowingVehicle()
            end,
            action = function(entity)
              TriggerEvent('fw-jobmanager:Client:TowVehicle', {}, entity)
            end,
          },
          {
            name = 'interact:untow_vehicle',
            label = 'Untow Vehicle',
            canInteract = function(entity)
              return GetEntityModel(entity) == `flatbed` and exports['fw-jobmanager']:IsTowingVehicle()
            end,
            action = function(entity)
              TriggerEvent('fw-jobmanager:Client:UntowVehicle', {}, entity)
            end,
          },
          {
            name = 'interact:methrun_dropoff_goods',
            label = 'Deliver Goods',
            canInteract = function(entity)
              return exports['fw-illegal']:CanDoDropoff(entity)
            end,
            action = function(entity)
              TriggerEvent('fw-illegal:Client:MethrunDropoffGoods', {}, entity)
            end,
          },
          stealRimOption,
        },
      },
      ['wheel_lf'] = { distance = 3.0, interactDst = 1.0, options = wheelOptions },
      ['wheel_rf'] = { distance = 3.0, interactDst = 1.0, options = wheelOptions },
      ['wheel_rr'] = { distance = 3.0, interactDst = 1.0, options = wheelOptions },
      ['attach_female'] = { distance = 3.0, interactDst = 2.0, options = towRopeOptions },
      ['attach_male'] = { distance = 3.0, interactDst = 2.0, options = towRopeOptions },
      -- Whole-vehicle options, and everything for bikes / boats / aircraft (no doors or boot).
      ['chassis'] = {
        distance = 4.0,
        interactDst = 2.5,
        options = {
          {
            name = 'interact:chop_vehicle',
            label = 'Scrap Vehicle',
            canInteract = function(entity)
              return exports['fw-jobmanager']:IsScrappingVehicle(entity)
            end,
            action = function(entity)
              TriggerEvent('fw-jobmanager:Client:StartChopProcess', {}, entity)
            end,
          },
          {
            name = 'interact:pickup_bicycle',
            label = 'Pick Up Bicycle',
            canInteract = function(entity)
              return IsThisModelABicycle(GetEntityModel(entity))
                  and not IsEntityAttachedToAnyPed(entity)
                  and not IsEntityAttachedToAnyPed(cache.ped)
            end,
            action = function(entity)
              TriggerEvent('fw-vehicles:client:carry:bicycle', {}, entity)
            end,
          },
          {
            name = 'interact:save_outfit',
            label = 'Save Current Outfit',
            canInteract = function(entity)
              local t = vehicleType(entity)
              return (t == 'car' or t == 'motorcycle') and isNotPolice() and exports['fw-bennys']:IsInSecretBennys()
            end,
            action = function(entity)
              TriggerEvent('fw-bennys:Client:SaveOutfit', {}, entity)
            end,
          },
          {
            name = 'interact:swap_outfit',
            label = 'Change Current Outfit',
            canInteract = function(entity)
              local t = vehicleType(entity)
              return (t == 'car' or t == 'motorcycle') and isNotPolice() and exports['fw-bennys']:IsInSecretBennys()
            end,
            action = function(entity)
              TriggerEvent('fw-bennys:Client:SwapOutfit', {}, entity)
            end,
          },
          -- Motorcycles / aircraft
          {
            name = 'interact:seat_in_vehicle_other',
            label = 'Seat in Vehicle',
            canInteract = function(entity)
              local t = vehicleType(entity)
              return (t == 'motorcycle' or t == 'aircraft') and playerNearby()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:SeatVehicle', {}, entity)
            end,
          },
          {
            name = 'interact:unseat_from_vehicle_other',
            label = 'Unseat from Vehicle',
            canInteract = function(entity)
              local t = vehicleType(entity)
              return (t == 'motorcycle' or t == 'aircraft') and playerNearby()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:UnseatVehicle', {}, entity)
            end,
          },
          -- Motorcycles
          {
            name = 'interact:scan_plate_bike',
            label = 'Check Plate',
            canInteract = function(entity)
              return vehicleType(entity) == 'motorcycle' and isOnDutyPolice()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:ScanPlate', {}, entity)
            end,
          },
          {
            name = 'interact:check_for_tampering_bike',
            label = 'Check for Tampering',
            canInteract = function(entity)
              return vehicleType(entity) == 'motorcycle' and isOnDutyPolice()
            end,
            action = function(entity)
              TriggerEvent('fw-police:Client:CheckTampering', {}, entity)
            end,
          },
          {
            name = 'interact:inspect_vin_bike',
            label = 'Inspect VIN',
            canInteract = function(entity)
              return vehicleType(entity) == 'motorcycle' and isOnDutyPolice()
            end,
            action = function(entity)
              TriggerEvent('fw-vehicles:Client:InspectVIN', {}, entity)
            end,
          },
          {
            name = 'interact:autocare_check_bike',
            label = 'Inspect Vehicle',
            canInteract = function(entity)
              -- Only bikes without an engine bone, the others get it on the 'engine' point.
              return vehicleType(entity) == 'motorcycle'
                  and GetEntityBoneIndexByName(entity, 'engine') == -1
                  and exports['fw-businesses']:IsAutocare()
            end,
            action = function(entity)
              TriggerEvent('fw-businesses:Client:AutoCare:CheckVehicle', {}, entity)
            end,
          },
          -- Aircraft
          {
            name = 'interact:aircraft_refuel',
            label = 'Refuel Aircraft',
            canInteract = function(entity)
              return vehicleType(entity) == 'aircraft' and exports['fw-vehicles']:CanRefuelAircraft(entity)
            end,
            action = function(entity)
              TriggerServerEvent('fw-vehicles:Server:FuelHelicopter', { SelfServe = true }, NetworkGetNetworkIdFromEntity(entity))
            end,
          },
          -- Boats
          {
            name = 'interact:anchor_down',
            label = 'Drop Anchor',
            canInteract = function(entity)
              return vehicleType(entity) == 'boat' and exports['fw-items']:CanDropAnchor()
            end,
            action = function(entity)
              TriggerEvent('fw-items:use:item:anker', {}, entity)
            end,
          },
          {
            name = 'interact:anchor_up',
            label = 'Raise Anchor',
            canInteract = function(entity)
              return vehicleType(entity) == 'boat' and exports['fw-items']:CanTiltAnchor()
            end,
            action = function(entity)
              TriggerEvent('fw-items:use:item:anker:tilt', {}, entity)
            end,
          },
        },
      },
      ['engine'] = {
        distance = 3.0,
        interactDst = 1.5,
        offset = vec3(0.0, -10.3, 0.0),
        options = {
          {
          name = 'interact:autocare_check_vehicle',
          label = 'Inspect Vehicle',
          canInteract = function(entity, coords, args)
            return exports['fw-businesses']:IsAutocare() and exports['fw-businesses']:isRealVehicle(entity);
          end,
            action = function(entity, distance, args)
            TriggerEvent('fw-businesses:Client:AutoCare:CheckVehicle', {}, entity)
          end,
          },
        },
      },
    },
  },
}



return Settings
