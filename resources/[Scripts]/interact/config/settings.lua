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
-- Eye entries (copied 1:1 from fw-ui/config/sh_config.lua -> Config.EyeEntries)
-- You can paste new fw-ui Eye options straight in here, same format:
--   Name, Label, Icon, EventType ('Client' / 'Server'), EventName, EventParams, Enabled(Entity)
-- `GetBoneDistanceFromVehicle` and `FW` work the same as in fw-ui (see client/eye.lua).
-- Categories: peds, vehicles, motorcycle, watercraft, aircraft, train.
-- ============================================================================
local EyeEntries = {
    ["peds"] = {
        Type = "Default",
        SpriteDistance = 0.0,
        State = false,
        Options = {
            {
                Name = "sell_meth",
                Icon = "fas fa-comment-dollar",
                Label = "Verkopen",
                EventType = "Client",
                EventName = "fw-misc:Client:CorneringSale",
                EventParams = {},
                Enabled = function(Entity)
                    if IsPedDeadOrDying(Entity) then
                        return false
                    end

                    return exports['fw-misc']:IsCorneringActive() and exports['fw-misc']:IsCorneringPed(Entity)
                end,
            },
        },
    },
    ["vehicles"] = {
        Type = "Default",
        SpriteDistance = 0.0,
        State = false,
        Options = {
            {
                Name = "boosting-vin-scratch",
                Icon = "fas fa-eye-slash",
                Label = "VIN Wegkrassen",
                EventType = "Client",
                EventName = "fw-boosting:Client:ScratchVin",
                EventParams = {},
                Enabled = function(Entity)
                    return exports["fw-boosting"]:IsVehicleScratchable(Entity)
                end,
            },
            {
                Name = "chop_vehicle",
                Icon = "fas fa-boxes",
                Label = "Voertuig Scrappen",
                EventType = "Client",
                EventName = "fw-jobmanager:Client:StartChopProcess",
                EventParams = {},
                Enabled = function(Entity)
                    return exports["fw-jobmanager"]:IsScrappingVehicle(Entity)
                end,
            },
            {
                Name = 'sanitation_throw_trash',
                Label = 'Vuilniszak Weggooien',
                Icon = 'fas fa-trash-restore',
                EventType = 'Client',
                EventName = 'fw-jobmanager:Client:Sanitation:ThrowInTrash',
                EventParams = {},
                Enabled = function(Entity)
                    local MyJob = exports['fw-jobmanager']:GetMyJob()
                    if MyJob.CurrentJob ~= 'sanitation' then return false end
                    local CurrentTask = FW.SendCallback("fw-jobmanager:Server:GetGroupCurrentTask", MyJob.CurrentJob, MyJob.CurrentGroup.Id)

                    if CurrentTask.TaskId ~= 4 and CurrentTask.TaskId ~= 6 then
                        return false
                    end

                    if GetEntityModel(Entity) == GetHashKey("trash") and GetBoneDistanceFromVehicle(2, "boot") < 5.0 and GetVehicleDoorAngleRatio(Entity, 5) > 0.0 then
                        return true
                    else
                        return false
                    end
                end,
            },
            {
                Name = 'postop_grab_goods',
                Label = 'Goederen Pakken',
                Icon = 'fas fa-box-open',
                EventType = 'Client',
                EventName = 'fw-jobmanager:Client:PostOp:GrabGoods',
                EventParams = {},
                Enabled = function(Entity)
                    local MyJob = exports['fw-jobmanager']:GetMyJob()
                    if MyJob.CurrentJob ~= 'postop' then return false end

                    local CurrentTaskId = exports['fw-jobmanager']:GetCurrentTaskId()
                    if CurrentTaskId ~= 4 then return false end

                    return GetEntityModel(Entity) == GetHashKey("benson")
                end,
            },
            {
                Name = 'oxy_deliver_package',
                Label = 'Goederen Afleveren',
                Icon = 'fas fa-cubes',
                EventType = 'Client',
                EventName = 'fw-jobmanager:Client:Oxy:DeliverGoods',
                EventParams = {},
                Enabled = function(Entity)
                    local MyJob = exports['fw-jobmanager']:GetMyJob()
                    if MyJob.CurrentJob ~= 'oxy' then return false end

                    local CurrentTaskId = exports['fw-jobmanager']:GetCurrentTaskId()
                    if CurrentTaskId ~= 4 and CurrentTaskId ~= 6 then return false end

                    if exports['fw-jobmanager']:IsOxyVehicle(Entity) then
                        return true
                    else
                        return false
                    end
                end,
            },
            {
                Name = 'scan_plate',
                Label = 'Kenteken Nakijken',
                Icon = 'fas fa-closed-captioning',
                EventType = 'Client',
                EventName = 'fw-police:Client:ScanPlate',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerData = FW.Functions.GetPlayerData()
                    return (GetBoneDistanceFromVehicle(2, "bumper_r") < 1.5 or GetBoneDistanceFromVehicle(2, "bumper_f") < 1.5) and PlayerData.job.name == 'police' and PlayerData.job.onduty
                end,
            },
            {
                Name = 'check_for_tampering',
                Label = 'Controleer op Sabotage',
                Icon = 'fas fa-unlink',
                EventType = 'Client',
                EventName = 'fw-police:Client:CheckTampering',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerData = FW.Functions.GetPlayerData()
                    return GetBoneDistanceFromVehicle(2, "door_dside_f") < 1.5 and PlayerData.job.name == 'police' and PlayerData.job.onduty
                end,
            },
            {
                Name = 'vehicle_refuel',
                Label = 'Voertuig Tanken',
                Icon = 'fas fa-gas-pump',
                EventType = 'Client',
                EventName = 'fw-vehicles:Client:Fuel:RefuelVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    return exports['fw-vehicles']:CanRefuel()
                end,
            },
            {
                Name = 'enter_trunk',
                Label = 'In Kofferbak Liggen',
                Icon = 'fas fa-user-secret',
                EventType = 'Client',
                EventName = 'fw-assets:client:getin:trunk',
                EventParams = {},
                Enabled = function(Entity)
                    return GetBoneDistanceFromVehicle(2, "bumper_r") < 2.0 and (GetVehicleDoorAngleRatio(Entity, 5) > 0.0 or IsVehicleDoorDamaged(Entity, 5))
                end,
            },
            {
                Name = 'open_trunk',
                Label = 'Kofferbak Openen',
                Icon = 'fas fa-truck-loading',
                EventType = 'Client',
                EventName = 'fw-inventory:Client:OpenTrunk',
                EventParams = {},
                Enabled = function(Entity)
                    return GetBoneDistanceFromVehicle(2, "bumper_r") < 2.0 and GetVehicleDoorLockStatus(Entity) ~= 2
                end,
            },

            {
                Name = 'seat_in_vehicle',
                Label = 'Zet in Voertuig',
                Icon = 'fas fa-chevron-circle-left',
                EventType = 'Client',
                EventName = 'fw-police:Client:SeatVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    local Player, Distance = FW.Functions.GetClosestPlayer()
                    if Player == -1 or Distance > 2.0 then
                        return false
                    end

                    return true
                end,
            },
            {
                Name = 'unseat_from_vehicle',
                Label = 'Haal uit Voertuig',
                Icon = 'fas fa-chevron-circle-right',
                EventType = 'Client',
                EventName = 'fw-police:Client:UnseatVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    local Player, Distance = FW.Functions.GetClosestPlayer()
                    if Player == -1 or Distance > 2.0 then
                        return false
                    end

                    return true
                end,
            },

            {
                Name = 'pickup_bicycle',
                Label = 'Fiets Oppakken',
                Icon = 'fas fa-spinner',
                EventType = 'Client',
                EventName = 'fw-vehicles:client:carry:bicycle',
                EventParams = {},
                Enabled = function(Entity)
                    return IsThisModelABicycle(GetEntityModel(Entity)) and not IsEntityAttachedToAnyPed(Entity) and not IsEntityAttachedToAnyPed(PlayerPedId())
                end,
            },
            {
                Name = 'save_outfit',
                Label = 'Huidige Outfit Opslaan',
                Icon = 'fas fa-plus',
                EventType = 'Client',
                EventName = 'fw-bennys:Client:SaveOutfit',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerJob = FW.Functions.GetPlayerData()
                    return PlayerJob.name ~= 'police' and exports['fw-bennys']:IsInSecretBennys()
                end,
            },
            {
                Name = 'swap_outfit',
                Label = 'Huidige Outfit Veranderen',
                Icon = 'fas fa-redo',
                EventType = 'Client',
                EventName = 'fw-bennys:Client:SwapOutfit',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerJob = FW.Functions.GetPlayerData()
                    return PlayerJob.name ~= 'police' and exports['fw-bennys']:IsInSecretBennys()
                end,
            },
            {
                Name = 'steal_rim',
                Label = 'Velg Stelen',
                Icon = 'fas fa-cog',
                EventType = 'Client',
                EventName = 'fw-vehicles:Client:StealRim',
                EventParams = {},
                Enabled = function(Entity)
                    if not exports['fw-inventory']:HasEnoughOfItem('screwdriver', 1) then
                        return false
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_lf") < 1.0 then
                        return true
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_rf") < 1.0 then
                        return true
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_lr") < 1.0 then
                        return true
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_rr") < 1.0 then
                        return true
                    end
                end,
            },
            {
                Name = 'tow_vehicle',
                Label = 'Voertuig Takelen',
                Icon = 'fas fa-trailer',
                EventType = 'Client',
                EventName = 'fw-jobmanager:Client:TowVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    if GetEntityModel(Entity) ~= GetHashKey("flatbed") then return false end
                    if GetBoneDistanceFromVehicle(2, "wheel_lr") > 2.5 then return false end
                    return not exports['fw-jobmanager']:IsTowingVehicle()
                end,
            },
            {
                Name = 'untow_vehicle',
                Label = 'Voertuig Aftakelen',
                Icon = 'fas fa-trailer',
                EventType = 'Client',
                EventName = 'fw-jobmanager:Client:UntowVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    if GetEntityModel(Entity) ~= GetHashKey("flatbed") then return false end
                    if GetBoneDistanceFromVehicle(2, "wheel_lr") > 2.5 then return false end
                    return exports['fw-jobmanager']:IsTowingVehicle()
                end,
            },
            {
                Name = 'methrun_dropoff_goods',
                Label = 'Goederen Afleveren',
                Icon = 'fas fa-boxes',
                EventType = 'Client',
                EventName = 'fw-illegal:Client:MethrunDropoffGoods',
                EventParams = {},
                Enabled = function(Entity)
                    if GetBoneDistanceFromVehicle(2, "wheel_lr") > 1.5 then return false end
                    return exports['fw-illegal']:CanDoDropoff(Entity)
                end,
            },

            -- Meth Cornering
            {
                Name = 'sell_meth',
                Label = 'Start Methverkoop',
                Icon = 'fas fa-handshake',
                EventType = 'Client',
                EventName = 'fw-misc:Client:StartCornering',
                EventParams = { Type = 'meth' },
                Enabled = function(Entity)
                    return exports['fw-inventory']:HasEnoughOfItem('1gmeth', 5) and not exports['fw-misc']:IsCorneringActive()
                end,
            },
            {
                Name = 'stop_meth_cornering',
                Label = 'Stop Methverkoop',
                Icon = 'fas fa-handshake',
                EventType = 'Client',
                EventName = 'fw-misc:Client:StopCornering',
                EventParams = { Type = 'meth' },
                Enabled = function(Entity)
                    return exports['fw-misc']:IsCorneringActive('meth') and exports['fw-misc']:IsCorneringVehicle(Entity)
                end,
            },

            -- Weed Cornering
            {
                Name = 'sell_weed',
                Label = 'Start Wietverkoop',
                Icon = 'fas fa-handshake',
                EventType = 'Client',
                EventName = 'fw-misc:Client:StartCornering',
                EventParams = { Type = 'weed' },
                Enabled = function(Entity)
                    return exports['fw-inventory']:HasEnoughOfItem('weed-bag', 5) and not exports['fw-misc']:IsCorneringActive()
                end,
            },
            {
                Name = 'stop_weed_cornering',
                Label = 'Stop Wietverkoop',
                Icon = 'fas fa-handshake',
                EventType = 'Client',
                EventName = 'fw-misc:Client:StopCornering',
                EventParams = { Type = 'weed' },
                Enabled = function(Entity)
                    return exports['fw-misc']:IsCorneringActive('weed') and exports['fw-misc']:IsCorneringVehicle(Entity)
                end,
            },
            {
                Name = 'attach_rope',
                Label = 'Koppel sleeptouw aan voertuig',
                Icon = 'fas fa-cog',
                EventType = 'Client',
                EventName = 'fw-heists:Client:AttachRope',
                EventParams = {},
                Enabled = function(Entity)
                    return exports['fw-inventory']:HasEnoughOfItem('tow-rope', 1) and (GetBoneDistanceFromVehicle(2, "attach_female") < 2.0 or GetBoneDistanceFromVehicle(2, "attach_male") < 2.0)
                end,
            },
            {
                Name = 'detach_rope',
                Label = 'Ontkoppel sleeptouw',
                Icon = 'fas fa-cog',
                EventType = 'Client',
                EventName = 'fw-heists:Client:DetachRope',
                EventParams = {},
                Enabled = function(Entity)
                    return exports['fw-heists']:IsRopeAttached(Entity) and (GetBoneDistanceFromVehicle(2, "attach_female") < 2.0 or GetBoneDistanceFromVehicle(2, "attach_male") < 2.0)
                end,
            },
            {
                Name = 'inspect_vin',
                Label = 'Controleer VIN',
                Icon = 'fas fa-sim-card',
                EventType = 'Client',
                EventName = 'fw-vehicles:Client:InspectVIN',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerData = FW.Functions.GetPlayerData()
                    return PlayerData.job.name == 'police' and PlayerData.job.onduty
                end,
            },
        }
    },
    ["motorcycle"] = {
        Type = "Default",
        SpriteDistance = 0.0,
        State = false,
        Options = {
            {
                Name = 'vehicle_refuel',
                Label = 'Voertuig Tanken',
                Icon = 'fas fa-gas-pump',
                EventType = 'Client',
                EventName = 'fw-vehicles:Client:Fuel:RefuelVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    return exports['fw-vehicles']:CanRefuel()
                end,
            },
            {
                Name = "autocare_check_vehicle",
                Icon = "fas fa-cog",
                Label = "Voertuig Controleren",
                EventType = "Client",
                EventName = "fw-businesses:Client:AutoCare:CheckVehicle",
                EventParams = {},
                Enabled = function(Entity)
                    return exports["fw-businesses"]:IsAutocare()
                end,
            },
            {
                Name = 'scan_plate',
                Label = 'Kenteken Nakijken',
                Icon = 'fas fa-closed-captioning',
                EventType = 'Client',
                EventName = 'fw-police:Client:ScanPlate',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerData = FW.Functions.GetPlayerData()
                    return (GetBoneDistanceFromVehicle(2, "brakelight_l") < 1.0 or GetBoneDistanceFromVehicle(2, "headlight_l") < 1.0) and PlayerData.job.name == 'police' and PlayerData.job.onduty
                end,
            },
            {
                Name = 'save_outfit',
                Label = 'Huidige Outfit Opslaan',
                Icon = 'fas fa-plus',
                EventType = 'Client',
                EventName = 'fw-bennys:Client:SaveOutfit',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerJob = FW.Functions.GetPlayerData()
                    return PlayerJob.name ~= 'police' and exports['fw-bennys']:IsInSecretBennys()
                end,
            },
            {
                Name = 'swap_outfit',
                Label = 'Huidige Outfit Veranderen',
                Icon = 'fas fa-redo',
                EventType = 'Client',
                EventName = 'fw-bennys:Client:SwapOutfit',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerJob = FW.Functions.GetPlayerData()
                    return PlayerJob.name ~= 'police' and exports['fw-bennys']:IsInSecretBennys()
                end,
            },
            {
                Name = 'steal_rim',
                Label = 'Velg Stelen',
                Icon = 'fas fa-cog',
                EventType = 'Client',
                EventName = 'fw-vehicles:Client:StealRim',
                EventParams = {},
                Enabled = function(Entity)
                    if not exports['fw-inventory']:HasEnoughOfItem('screwdriver', 1) then
                        return false
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_lf") < 1.0 then
                        return true
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_rf") < 1.0 then
                        return true
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_lr") < 1.0 then
                        return true
                    end

                    if GetBoneDistanceFromVehicle(2, "wheel_rr") < 1.0 then
                        return true
                    end
                end,
            },
            {
                Name = 'seat_in_vehicle',
                Label = 'Zet in Voertuig',
                Icon = 'fas fa-chevron-circle-left',
                EventType = 'Client',
                EventName = 'fw-police:Client:SeatVehicle',
                EventParams = { Type = 'weed' },
                Enabled = function(Entity)
                    local Player, Distance = FW.Functions.GetClosestPlayer()
                    if Player == -1 or Distance > 2.0 then
                        return false
                    end

                    return true
                end,
            },
            {
                Name = 'unseat_from_vehicle',
                Label = 'Haal uit Voertuig',
                Icon = 'fas fa-chevron-circle-right',
                EventType = 'Client',
                EventName = 'fw-police:Client:UnseatVehicle',
                EventParams = { Type = 'weed' },
                Enabled = function(Entity)
                    local Player, Distance = FW.Functions.GetClosestPlayer()
                    if Player == -1 or Distance > 2.0 then
                        return false
                    end

                    return true
                end,
            },
            {
                Name = 'check_for_tampering',
                Label = 'Controleer op Sabotage',
                Icon = 'fas fa-unlink',
                EventType = 'Client',
                EventName = 'fw-police:Client:CheckTampering',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerData = FW.Functions.GetPlayerData()
                    return PlayerData.job.name == 'police' and PlayerData.job.onduty
                end,
            },
            {
                Name = 'inspect_vin',
                Label = 'Controleer VIN',
                Icon = 'fas fa-sim-card',
                EventType = 'Client',
                EventName = 'fw-vehicles:Client:InspectVIN',
                EventParams = {},
                Enabled = function(Entity)
                    local PlayerData = FW.Functions.GetPlayerData()
                    return PlayerData.job.name == 'police' and PlayerData.job.onduty
                end,
            },
        }
    },
    ["watercraft"] = {
        Type = "Default",
        SpriteDistance = 0.0,
        State = false,
        Options = {
            {
                Name = 'anchor-down',
                Label = 'Anker Zakken',
                Icon = 'fas fa-anchor',
                EventType = 'Client',
                EventName = 'fw-items:use:item:anker',
                EventParams = {},
                Enabled = function(Entity)
                    return exports['fw-items']:CanDropAnchor()
                end,
            },
            {
                Name = 'anchor-up',
                Label = 'Anker Oppakken',
                Icon = 'fas fa-anchor',
                EventType = 'Client',
                EventName = 'fw-items:use:item:anker:tilt',
                EventParams = {},
                Enabled = function(Entity)
                    return exports['fw-items']:CanTiltAnchor()
                end,
            },
        }
    },
    ["aircraft"] = {
        Type = "Default",
        SpriteDistance = 0.0,
        State = false,
        Options = {
            {
                Name = 'vehicle_refuel',
                Label = 'Voertuig Tanken',
                Icon = 'fas fa-gas-pump',
                EventType = 'Server',
                EventName = 'fw-vehicles:Server:FuelHelicopter',
                EventParams = { SelfServe = true },
                Enabled = function(Entity)
                    return exports['fw-vehicles']:CanRefuelAircraft(Entity)
                end,
            },
            {
                Name = 'seat_in_vehicle',
                Label = 'Zet in Voertuig',
                Icon = 'fas fa-chevron-circle-left',
                EventType = 'Client',
                EventName = 'fw-police:Client:SeatVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    local Player, Distance = FW.Functions.GetClosestPlayer()
                    if Player == -1 or Distance > 2.0 then
                        return false
                    end

                    return true
                end,
            },
            {
                Name = 'unseat_from_vehicle',
                Label = 'Haal uit Voertuig',
                Icon = 'fas fa-chevron-circle-right',
                EventType = 'Client',
                EventName = 'fw-police:Client:UnseatVehicle',
                EventParams = {},
                Enabled = function(Entity)
                    local Player, Distance = FW.Functions.GetClosestPlayer()
                    if Player == -1 or Distance > 2.0 then
                        return false
                    end

                    return true
                end,
            },
        }
    },
    ["train"] = { -- why not xd
        Type = "Default",
        SpriteDistance = 0.0,
        State = false,
        Options = {}
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
  nearbyVehicleDistance = 4.0,

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

  -- fw-ui Eye options shown through interact (see EyeEntries at the top of this file).
  Eye = {
    enabled = true,
    scanInterval = 1000,     -- ms between scans for nearby vehicles / peds
    refreshInterval = 300,   -- ms between re-checking each option's Enabled() function
    vehicleScanRadius = 8.0, -- vehicles closer than this get an Eye point
    vehicleReach = 1.0,      -- prompt range = half the vehicle's length + this
    pedScanRadius = 5.0,
    pedDistance = 3.0,       -- dot range on peds
    pedInteractDst = 1.8,    -- prompt range on peds (same as fw-ui's 1.8)
    -- Eye options NOT shown, because interact already has them on the boot bone (vehicleBoneDefaults).
    -- Empty a list to show them anyway.
    skip = {
      vehicles = { 'open_trunk', 'enter_trunk', 'sell_weed', 'stop_weed_cornering' },
    },
  },

  EyeEntries = EyeEntries,




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
