local Pumps = {
    "prop_gas_pump_1a", "prop_gas_pump_1b", "prop_gas_pump_1c", "prop_gas_pump_1d",
    "prop_gas_pump_old2", "prop_gas_pump_old3", "prop_vintage_pump"
}

local NearGasStation, GasStationClass, HasNozzle, FuelRates, InVehicle = false, false, false, {}, false

Citizen.CreateThread(function()
    for k, v in pairs(Config.FuelStations) do
        if v.blip then
            local Blip = AddBlipForCoord(v.center.x, v.center.y, v.center.z)
            SetBlipSprite(Blip, 361)
            SetBlipDisplay(Blip, 4)
            SetBlipScale(Blip, 0.4)
            SetBlipAsShortRange(Blip, true)
            SetBlipColour(Blip, 1)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName("Tankstation")
            EndTextCommandSetBlipName(Blip)
        end

        exports['PolyZone']:CreateBox({ center = v.center, length = v.length, width = v.width, data = v.data }, {
            name = 'gas-station-' .. k,
            heading = v.heading,
            minZ = v.minZ, maxZ = v.maxZ,
            IsMultiple = false, debugPoly = false,
        }, function(IsInside, Zone, Point)
            NearGasStation = IsInside

            if Zone.data and Zone.data.vehicleClass then
                GasStationClass = Zone.data.vehicleClass
            else
                GasStationClass = false
            end

            if not IsInside and HasNozzle then
                HasNozzle = false
                exports['fw-assets']:RemoveProp()
            end
        end)
    end

    for k, v in pairs(Pumps) do
        exports.interact:AddModelInteraction({
            modelData = {
                {
                    model = v,
                    offset = vec3(0.0, 0.0, 1.0)
                },
            },
            distance = 10.0,
            interactDst = 1.5,
            options = {
                {
                    name = 'use_pump',
                    label = 'Use Pump',
                    canInteract = function(entity, coords, args)
                        return NearGasStation and not HasNozzle
                    end,
                    action = function(entity, coords, args)
                        TriggerEvent('fw-vehicles:Client:Fuel:UsePump', entity)
                    end,
                },
                {
                    name = 'return_hose',
                    label = 'Put Nozzle',
                    canInteract = function(entity, coords, args)
                        return NearGasStation and HasNozzle
                    end,
                    action = function(entity, coords, args)
                        TriggerEvent('fw-vehicles:Client:Fuel:ReturnHose')
                    end,
                },
            },
        })
    end
end)

-- ==========================================================
-- Vehicle fuel points (interact), only while holding the nozzle
-- ==========================================================
local FuelPoints = {}   -- [vehicle] = { Id, VehCoords }
local PumpEntity = nil

-- 13 cycles, 14 boats, 15 helis, 16 planes, 21 trains
local SKIP_CLASS = { [13] = true, [14] = true, [15] = true, [16] = true, [21] = true }

-- How far (metres) the fuel point sits inside the model's widest edge.
-- Raise to pull it closer to the car, lower to push it out.
local SIDE_INSET = 0.2

-- Optional exact positions per model: [`model`] = vec3(x, y, z) (entity-relative)
local MODEL_OFFSETS = {
    -- [`sultan`] = vec3(-0.95, -1.35, 0.25),
}

local function GetFuelOffset(Vehicle, FromCoords)
    local Model = GetEntityModel(Vehicle)
    if MODEL_OFFSETS[Model] then return MODEL_OFFSETS[Model] end

    local Min, Max = GetModelDimensions(Model)

    -- Motorbikes: tank on top, middle of the bike
    if GetVehicleClass(Vehicle) == 8 then
        return vec3(0.0, (Min.y + Max.y) * 0.5 + 0.2, Max.z * 0.6)
    end

    -- Side of the car facing the pump (+x right, -x left in entity space)
    local Rel = GetOffsetFromEntityGivenWorldCoords(Vehicle, FromCoords.x, FromCoords.y, FromCoords.z)
    -- Model width includes mirrors, so pull the point in toward the body
    local X = Rel.x >= 0.0 and (Max.x - SIDE_INSET) or (Min.x + SIDE_INSET)

    -- Rear quarter panel, around cap height
    local Y = Min.y + (Max.y - Min.y) * 0.25
    local Z = (Min.z + Max.z) * 0.5

    return vec3(X, Y, Z)
end

local function ClearFuelPoints()
    for Vehicle, Point in pairs(FuelPoints) do
        exports.interact:RemoveInteraction(Point.Id)
        FuelPoints[Vehicle] = nil
    end
end

-- Standalone coords interaction: interact merges every entity interaction on the
-- same vehicle into one point (trunk etc.), so we never attach to the vehicle itself.
local function AddFuelPoint(Vehicle)
    if SKIP_CLASS[GetVehicleClass(Vehicle)] then return end

    local From = (PumpEntity and DoesEntityExist(PumpEntity)) and GetEntityCoords(PumpEntity) or GetEntityCoords(PlayerPedId())
    local Offset = GetFuelOffset(Vehicle, From)
    local Coords = GetOffsetFromEntityInWorldCoords(Vehicle, Offset.x, Offset.y, Offset.z)

    local Id = exports.interact:AddInteraction({
        name = 'fuel:point:' .. Vehicle,
        coords = Coords,
        distance = 3.0,
        interactDst = 1.3,
        options = {
            {
                name = 'fuel:refuel',
                label = 'Refuel Vehicle',
                args = { Vehicle = Vehicle },
                canInteract = function(_, _, Args)
                    return NearGasStation and HasNozzle
                        and DoesEntityExist(Args.Vehicle)
                        and GetVehicleFuelLevel(Args.Vehicle) < 95.0
                end,
                action = function(_, _, Args)
                    TriggerEvent('fw-vehicles:Client:Fuel:RefuelVehicle', { Entity = Args.Vehicle })
                end,
            },
        },
    })

    FuelPoints[Vehicle] = { Id = Id, VehCoords = GetEntityCoords(Vehicle) }
end

local function RemoveFuelPoint(Vehicle)
    local Point = FuelPoints[Vehicle]
    if not Point then return end
    exports.interact:RemoveInteraction(Point.Id)
    FuelPoints[Vehicle] = nil
end

local function StartFuelPointLoop()
    Citizen.CreateThread(function()
        while HasNozzle do
            local PedCoords = GetEntityCoords(PlayerPedId())
            local Vehicles = GetGamePool('CVehicle')
            for i = 1, #Vehicles do
                local Vehicle = Vehicles[i]
                if not FuelPoints[Vehicle] and #(GetEntityCoords(Vehicle) - PedCoords) <= 8.0 then
                    AddFuelPoint(Vehicle)
                end
            end

            for Vehicle, Point in pairs(FuelPoints) do
                if not DoesEntityExist(Vehicle) then
                    RemoveFuelPoint(Vehicle)
                elseif #(GetEntityCoords(Vehicle) - Point.VehCoords) > 0.5 then
                    -- Car moved: rebuild the point at its new position
                    RemoveFuelPoint(Vehicle)
                    if #(GetEntityCoords(Vehicle) - PedCoords) <= 8.0 then AddFuelPoint(Vehicle) end
                end
            end

            Citizen.Wait(500)
        end

        ClearFuelPoints()
        PumpEntity = nil
    end)
end

-- Vehicle passed from interact, or fall back to what the player is looking at
local function GetTargetVehicle(Data)
    if type(Data) == 'table' and Data.Entity and DoesEntityExist(Data.Entity) then
        return Data.Entity
    end

    local Entity, EntityType = exports['fw-ui']:GetEntityPlayerIsLookingAt(4.0, 0.2, 286, PlayerPedId())
    if Entity and Entity > 0 and EntityType == 2 then
        return Entity
    end
end

RegisterNetEvent("baseevents:enteredVehicle")
AddEventHandler("baseevents:enteredVehicle", function(Vehicle, Seat, DisplayName, NetId)
    InVehicle = true

    if GetEntityModel(Vehicle) == GetHashKey("airone") then
        if FuelRates[GetVehicleNumberPlateText(Vehicle)] ~= 5 then
            FuelRates[GetVehicleNumberPlateText(Vehicle)] = 5
        end
    elseif GetVehicleClass(Vehicle) == 8 then
        if FuelRates[GetVehicleNumberPlateText(Vehicle)] ~= 2 then
            FuelRates[GetVehicleNumberPlateText(Vehicle)] = 2
        end
    end

    Citizen.CreateThread(function()
        while InVehicle do
            if not IsVehicleEngineOn(Vehicle) then
                goto Skip
            end
            
            if GetPedInVehicleSeat(Vehicle, -1) == PlayerPedId() then
                local Plate = GetVehicleNumberPlateText(Vehicle)
                local FuelLevel = GetVehicleMeta(Vehicle, 'Fuel')
                if FuelLevel ~= 0 then
                    if GetEntitySpeed(Vehicle) > 3 then
                        local NewLevel = FuelLevel - (0.3 * (FuelRates[Plate] or 1.0))
                        -- print("Fuel - Current: " .. FuelLevel .. " | New: " .. NewLevel .. " | Rate: " .. (FuelRates[Plate] or 1.0))
                        SetFuelLevel(Vehicle, NewLevel)
                        Citizen.Wait(12500)
                    end
                end
            end

            ::Skip::

            Citizen.Wait(1000)
        end
    end)
end)

RegisterNetEvent("baseevents:leftVehicle")
AddEventHandler("baseevents:leftVehicle", function(Vehicle, Seat, DisplayName, NetId)
    InVehicle = false
end)

RegisterNetEvent("fw-vehicles:Client:Fuel:UsePump")
AddEventHandler("fw-vehicles:Client:Fuel:UsePump", function(Pump)
    PumpEntity = Pump
    FW.Functions.OpenMenu({
        MainMenuItems = {
            {
                Icon = 'gas-pump',
                Title = "Pump",
                Desc = "Select the type of gasoline you want to use",
                CloseMenu = false,
            },
            {
                Icon = 'info-circle',
                Title = "Regular",
                Desc = "Octaan: 95 | Price per litre: " .. exports['fw-businesses']:NumberWithCommas(Config.FuelPrice),
                Data = { Event = 'fw-vehicles:Client:Fuel:GrabHose', Type = 'Client' },
                CloseMenu = true,
            },
        },
    })
end)

RegisterNetEvent("fw-vehicles:Client:Fuel:GrabHose")
AddEventHandler("fw-vehicles:Client:Fuel:GrabHose", function()
    if HasNozzle then return end
    HasNozzle = true
    exports['fw-assets']:AddProp('fuelnuzzle')
    StartFuelPointLoop()

    Citizen.CreateThread(function()
        while HasNozzle do

            if not exports['fw-assets']:GetSpecificPropStatus('fuelnuzzle') then
                exports['fw-assets']:AddProp('fuelnuzzle')
            end

            Citizen.Wait(100)
        end
    end)
end)

RegisterNetEvent("fw-vehicles:Client:Fuel:ReturnHose")
AddEventHandler("fw-vehicles:Client:Fuel:ReturnHose", function()
    HasNozzle = false
    exports['fw-assets']:RemoveProp()
end)

RegisterNetEvent("fw-vehicles:Client:Fuel:RefuelVehicle")
AddEventHandler("fw-vehicles:Client:Fuel:RefuelVehicle", function(Data)
    if not NearGasStation or not HasNozzle then return end

    local Entity = GetTargetVehicle(Data)
    if not Entity then return end

    local FuelLevel = GetVehicleFuelLevel(Entity)
    if 100 - FuelLevel < 5 then return FW.Functions.Notify("Je tank zit nog vol..", "error") end

    local IsBillPaid = FW.SendCallback("fw-vehicles:Server:Fuel:IsBillPaid", GetVehicleNumberPlateText(Entity))

    FW.Functions.OpenMenu({
        MainMenuItems = {
            {
                Icon = 'info-circle',
                Title = "Vehicle Refueling",
                Desc = "Fuel: " .. math.ceil(100 - FuelLevel) .. " | Total: " .. exports['fw-businesses']:NumberWithCommas(FW.Shared.CalculateTax("Gas", (100 - FuelLevel) * Config.FuelPrice)),
            },
            {
                Icon = "gas-pump",
                Title = "Start refueling",
                Data = { Event = 'fw-vehicles:Client:Fuel:StartRefuel', Type = 'Client', Liters = 100 - FuelLevel, Entity = Entity },
                Disabled = not IsBillPaid,
            },
            {
                Icon = "credit-card",
                Title = "Send Invoice",
                Data = { Event = 'fw-vehicles:Client:Fuel:SendBill', Type = 'Client', SelfServe = false, Entity = Entity },
                Disabled = IsBillPaid,
            },
            {
                Icon = "portrait",
                Title = "Self-service",
                Data = { Event = 'fw-vehicles:Client:Fuel:SendBill', Type = 'Client', SelfServe = true, Entity = Entity },
                Disabled = IsBillPaid,
            },
        },
    })
end)

RegisterNetEvent("fw-vehicles:Client:Fuel:SendBill")
AddEventHandler("fw-vehicles:Client:Fuel:SendBill", function(Data)
    local Entity = GetTargetVehicle(Data)
    if not Entity then return end

    local FuelLevel = GetVehicleFuelLevel(Entity)
    if 100 - FuelLevel < 5 then return FW.Functions.Notify("Your tank is full..", "error") end

    local Plate = GetVehicleNumberPlateText(Entity)
    local Liters = 100 - FuelLevel

    if Data.SelfServe then
        TriggerServerEvent('fw-vehicles:Server:Fuel:SendBill', Plate, FW.Functions.GetPlayerData().citizenid, Liters)
    else
        Citizen.SetTimeout(250, function()
            local Result = exports['fw-ui']:CreateInput({
                { Label = 'BSN', Icon = 'fas fa-user', Name = 'Cid' },
            })

            if Result and Result.Cid then
                TriggerServerEvent('fw-vehicles:Server:Fuel:SendBill', Plate, Result.Cid, Liters)
            end
        end)
    end
end)

RegisterNetEvent("fw-vehicles:Client:Fuel:StartRefuel")
AddEventHandler("fw-vehicles:Client:Fuel:StartRefuel", function(Data)
    local Entity = GetTargetVehicle(Data)
    if not Entity then return end

    local Fueling = true
    Citizen.CreateThread(function()
        while Fueling do
            if IsVehicleEngineOn(Entity) then
                AddExplosion(GetEntityCoords(Entity), EXPLOSION_CAR, 4.0, true, false, 20.0)
                TriggerServerEvent('fw-mdw:Server:SendAlert:Explosion', GetEntityCoords(Entity), FW.Functions.GetStreetLabel())
                FW.Functions.Notify('Refueling with the engine running doesnt sound like a good idea..', 'error')

                if not exports['fw-police']:IsStatusAlreadyActive('gasoline') then
                    TriggerEvent('fw-police:Client:SetStatus', 'gasoline', 300)
                end
            end

            Citizen.Wait(250)
        end
    end)

    FW.Functions.Progressbar("fuel", "Fueling...", 500 * Data.Liters, false, false, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "timetable@gardener@filling_can",
        anim = "gar_ig_5_filling_can",
        flags = 49,
    }, {}, {}, function() -- Done
        Fueling = false
        local Plate = GetVehicleNumberPlateText(Entity)
        SetFuelLevel(Entity, 100.0)
        StopAnimTask(PlayerPedId(), "timetable@gardener@filling_can", "gar_ig_5_filling_can", 1.0)
        TriggerServerEvent("fw-vehicles:Server:Fuel:SetPaidState", Plate)
    end, function()
        Fueling = false
    end, true)
end)

function SetFuelLevel(Vehicle, Amount)
    if Amount == nil then Amount = 100 end
    if Amount < 0 then Amount = 0 end
    if Amount > 100 then Amount = 100 end
    SetVehicleFuelLevel(Vehicle, Amount + 0.0)
    SetVehicleMeta(Vehicle, 'Fuel', Amount + 0.0)
end
exports("SetFuelLevel", SetFuelLevel)

function GetFuelRate(Plate)
    return FuelRates[Plate] or 1.0
end
exports("GetFuelRate", GetFuelRate)

function SetFuelRateOnVehicle(Plate, Rate)
    FuelRates[Plate] = Rate
end
exports("SetFuelRateOnVehicle", SetFuelRateOnVehicle)

exports("CanRefuel", function()
    return NearGasStation and HasNozzle
end)

exports("CanRefuelAircraft", function(Entity)
    return NearGasStation and GetVehicleClass(Entity) == GasStationClass
end)