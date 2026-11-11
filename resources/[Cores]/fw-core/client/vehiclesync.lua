FW.VSync = {}

function FW.VSync.DeleteVehicle(Vehicle)
    if NetworkHasControlOfEntity(Vehicle) then
        SetEntityAsMissionEntity(Vehicle, true, true)
        NetworkRequestControlOfEntity(Vehicle)
        DeleteVehicle(Vehicle)
    else
        RequestSyncExecution("DeleteVehicle", Vehicle)
    end
end

function FW.VSync.SetVehicleDoorOpen(Vehicle, Door, Loose, OpenInstantly)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleDoorOpen(Vehicle, Door, Loose, OpenInstantly)
    else
        RequestSyncExecution("SetVehicleDoorOpen", Vehicle, Door, Loose, OpenInstantly)
    end
end

function FW.VSync.SetVehicleDoorShut(Vehicle, Door, CloseInstantly)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleDoorShut(Vehicle, Door, CloseInstantly)
    else
        RequestSyncExecution("SetVehicleDoorOpen", Vehicle, Door, CloseInstantly)
    end
end

function FW.VSync.SetVehicleFixed(Vehicle)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleFixed(Vehicle)
    else
        RequestSyncExecution("SetVehicleDoorOpen", Vehicle)
    end
end

function FW.VSync.SetVehicleTyreFixed(Vehicle, Index)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleTyreFixed(Vehicle, Index)
    else
        RequestSyncExecution("SetVehicleDoorOpen", Vehicle, Index)
    end
end

function FW.VSync.SetTyreHealth(Vehicle, Index, Health)
    if NetworkHasControlOfEntity(Vehicle) then
        SetTyreHealth(Vehicle, Index, Health)
    else
        RequestSyncExecution("SetVehicleDoorOpen", Vehicle, Index, Health)
    end
end

function FW.VSync.SetVehicleTyreBurst(Vehicle, Index, OnRim, TyreHealth)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleTyreBurst(Vehicle, Index, OnRim, TyreHealth)
    else
        RequestSyncExecution("SetVehicleTyreBurst", Vehicle, Index, OnRim, TyreHealth)
    end
end

function FW.VSync.BreakOffVehicleWheel(Vehicle, WheelIndex, LeaveDebrisTrail, DeleteWheel, UnknownFlag, PutOnFire)
    if NetworkHasControlOfEntity(Vehicle) then
        BreakOffVehicleWheel(Vehicle, WheelIndex, LeaveDebrisTrail, DeleteWheel, UnknownFlag, PutOnFire)
    else
        RequestSyncExecution("BreakOffVehicleWheel", Vehicle, WheelIndex, LeaveDebrisTrail, DeleteWheel, UnknownFlag, PutOnFire)
    end
end

function FW.VSync.SetVehicleDoorBroken(Vehicle, Index, DeleteDoor)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleDoorBroken(Vehicle, Index, DeleteDoor)
    else
        RequestSyncExecution("SetVehicleDoorBroken", Vehicle, Index, DeleteDoor)
    end
end

function FW.VSync.SetVehicleDoorsLocked(Vehicle, State)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleDoorsLocked(Vehicle, State)
    else
        RequestSyncExecution("SetVehicleDoorsLocked", Vehicle, State)
    end
end

function FW.VSync.SetVehicleFixed(Vehicle)
    if NetworkHasControlOfEntity(Vehicle) then
        SetVehicleFixed(Vehicle)
    else
        RequestSyncExecution("SetVehicleFixed", Vehicle)
    end
end

function FW.VSync.GetVehicleMods(Vehicle)
    local VehicleColorOne, VehicleColorTwo = GetVehicleColours(Vehicle)
    local PearlescentColor, WheelColor = GetVehicleExtraColours(Vehicle)
    local PaintTypeOne = GetVehicleModColor_1(Vehicle)
    local PaintTypeTwo = GetVehicleModColor_2(Vehicle)
    local VehicleMods = {
        -- Custom RGB paint (false when the vehicle uses a palette colour) and paint finish (Normal/Metallic/...).
        ['CustomColorOne'] = GetIsVehiclePrimaryColourCustom(Vehicle) and { GetVehicleCustomPrimaryColour(Vehicle) } or false,
        ['CustomColorTwo'] = GetIsVehicleSecondaryColourCustom(Vehicle) and { GetVehicleCustomSecondaryColour(Vehicle) } or false,
        ['PaintTypeOne'] = (PaintTypeOne and PaintTypeOne >= 0 and PaintTypeOne <= 5) and PaintTypeOne or nil,
        ['PaintTypeTwo'] = (PaintTypeTwo and PaintTypeTwo >= 0 and PaintTypeTwo <= 5) and PaintTypeTwo or nil,
        -- Wheel stance from fw-bennys (replicated state bag), e.g. { SpacersFront = 0.95, Suspension = 0.05 }.
        ['Stance'] = Entity(Vehicle).state.bennysStance or nil,
        ['DirtLevel'] = GetVehicleDirtLevel(Vehicle),
        ['PlateIndex'] = GetVehicleNumberPlateTextIndex(Vehicle),
        ['ColorOne'] = VehicleColorOne,
        ['ColorTwo'] = VehicleColorTwo,
        ['PearlescentColor'] = PearlescentColor,
        ['WheelColor'] = WheelColor,
        ['DashboardColor'] = GetVehicleDashboardColor(Vehicle),
        ['InteriorColor'] = GetVehicleInteriorColour(Vehicle),
        ['Wheels'] = GetVehicleWheelType(Vehicle),
        ['WindowTint'] = GetVehicleWindowTint(Vehicle),
        ['Neon'] = {
            IsVehicleNeonLightEnabled(Vehicle, 0),
            IsVehicleNeonLightEnabled(Vehicle, 1),
            IsVehicleNeonLightEnabled(Vehicle, 2),
            IsVehicleNeonLightEnabled(Vehicle, 3)
        },
        ['NeonColor'] = table.pack(GetVehicleNeonLightsColour(Vehicle)),
        ['TyreSmokeColor'] = table.pack(GetVehicleTyreSmokeColor(Vehicle)),
        ['ModSpoilers'] = GetVehicleMod(Vehicle, 0),
        ['ModFrontBumper'] = GetVehicleMod(Vehicle, 1),
        ['ModRearBumper'] = GetVehicleMod(Vehicle, 2),
        ['ModSideSkirt'] = GetVehicleMod(Vehicle, 3),
        ['ModExhaust'] = GetVehicleMod(Vehicle, 4),
        ['ModFrame'] = GetVehicleMod(Vehicle, 5),
        ['ModGrille'] = GetVehicleMod(Vehicle, 6),
        ['ModHood'] = GetVehicleMod(Vehicle, 7),
        ['ModFender'] = GetVehicleMod(Vehicle, 8),
        ['ModRightFender'] = GetVehicleMod(Vehicle, 9),
        ['ModRoof'] = GetVehicleMod(Vehicle, 10),
        ['ModEngine'] = GetVehicleMod(Vehicle, 11),
        ['ModBrakes'] = GetVehicleMod(Vehicle, 12),
        ['ModTransmission'] = GetVehicleMod(Vehicle, 13),
        ['ModHorns'] = GetVehicleMod(Vehicle, 14),
        ['ModSuspension'] = GetVehicleMod(Vehicle, 15),
        ['ModArmor'] = GetVehicleMod(Vehicle, 16),
        ['ModTurbo'] = IsToggleModOn(Vehicle, 18),
        ['ModSmokeEnabled'] = IsToggleModOn(Vehicle, 20),
        ['ModXenon'] = IsToggleModOn(Vehicle, 22),
        ['ModXenonColor'] = GetVehicleXenonLightsColor(Vehicle),
        ['ModFrontWheels'] = GetVehicleMod(Vehicle, 23),
        ['ModBackWheels'] = GetVehicleMod(Vehicle, 24),
        ['ModPlateHolder'] = GetVehicleMod(Vehicle, 25),
        ['ModVanityPlate'] = GetVehicleMod(Vehicle, 26),
        ['ModTrimA']  = GetVehicleMod(Vehicle, 27),
        ['ModOrnaments'] = GetVehicleMod(Vehicle, 28),
        ['ModDashboard'] = GetVehicleMod(Vehicle, 29),
        ['ModDial'] = GetVehicleMod(Vehicle, 30),
        ['ModDoorSpeaker'] = GetVehicleMod(Vehicle, 31),
        ['ModSeats'] = GetVehicleMod(Vehicle, 32),
        ['ModSteeringWheel'] = GetVehicleMod(Vehicle, 33),
        ['ModShifterLeavers'] = GetVehicleMod(Vehicle, 34),
        ['ModAPlate'] = GetVehicleMod(Vehicle, 35),
        ['ModSpeakers'] = GetVehicleMod(Vehicle, 36),
        ['ModTrunk'] = GetVehicleMod(Vehicle, 37),
        ['ModHydrolic'] = GetVehicleMod(Vehicle, 38),
        ['ModEngineBlock'] = GetVehicleMod(Vehicle, 39),
        ['ModAirFilter'] = GetVehicleMod(Vehicle, 40),
        ['ModStruts'] = GetVehicleMod(Vehicle, 41),
        ['ModArchCover'] = GetVehicleMod(Vehicle, 42),
        ['ModAerials'] = GetVehicleMod(Vehicle, 43),
        ['ModTrimB'] = GetVehicleMod(Vehicle, 44),
        ['ModTank']  = GetVehicleMod(Vehicle, 45),
        ['ModWindows'] = GetVehicleWindowTint(Vehicle),
        ['ModLivery'] = GetVehicleMod(Vehicle, 48),
        ['ModExtras'] = {
            IsVehicleExtraTurnedOn(Vehicle, 1) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 2) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 3) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 4) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 5) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 6) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 7) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 8) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 9) and 0 or 1,
            IsVehicleExtraTurnedOn(Vehicle, 10) and 0 or 1
        }
    }
    return VehicleMods
end

function FW.VSync.ApplyVehicleMods(Vehicle, VehicleMods, Plate, FadeIgnore)
    if VehicleMods == 'Request' then
        VehicleMods = FW.SendCallback("FW:Server:GetVehicleMods", Plate)
    end

    if VehicleMods ~= nil and VehicleMods ~= false and next(VehicleMods) ~= nil then
        SetVehicleModKit(Vehicle, 0)

        Citizen.Wait(250)

        -- Paint keys are applied after the loop: the paint-type native overwrites colour indices.
        local PaintKeys = { CustomColorOne = true, CustomColorTwo = true, PaintTypeOne = true, PaintTypeTwo = true, Stance = true }

        for k, v in pairs(VehicleMods) do
            if PaintKeys[k] then
                -- handled below
            elseif k == 'PlateIndex' then
                SetVehicleNumberPlateTextIndex(Vehicle, v)
            elseif k == 'DirtLevel' then
                SetVehicleDirtLevel(Vehicle, v)
            elseif k == 'ColorOne' then
                local ColorOne, ColorTwo = GetVehicleColours(Vehicle)
                SetVehicleColours(Vehicle, v, ColorTwo)
            elseif k == 'ColorTwo' then
                local ColorOne, ColorTwo = GetVehicleColours(Vehicle)
                SetVehicleColours(Vehicle, ColorOne, v)
            elseif k == 'PearlescentColor' then
                local PearlescentColor, WheelColor = GetVehicleExtraColours(Vehicle)
                SetVehicleExtraColours(Vehicle, v, WheelColor)
            elseif k == 'WheelColor' then
                local PearlescentColor, WheelColor = GetVehicleExtraColours(Vehicle)
                SetVehicleExtraColours(Vehicle, PearlescentColor, v)
            elseif k == 'DashboardColor' then
                SetVehicleDashboardColor(Vehicle, v)
            elseif k == 'InteriorColor' then
                SetVehicleInteriorColor(Vehicle, v)
            elseif k == 'Wheels' then
                SetVehicleWheelType(Vehicle, v)
            elseif k == 'WindowTint' then
                SetVehicleWindowTint(Vehicle, v)
            elseif k == 'Neon' then
                SetVehicleNeonLightEnabled(Vehicle, 0, v[1])
                SetVehicleNeonLightEnabled(Vehicle, 1, v[2])
                SetVehicleNeonLightEnabled(Vehicle, 2, v[3])
                SetVehicleNeonLightEnabled(Vehicle, 3, v[4])
            elseif k == 'NeonColor' then
                SetVehicleNeonLightsColour(Vehicle, v[1], v[2], v[3])
            elseif k == 'ModXenonColor' then
                SetVehicleHeadlightsColour(Vehicle, v)
            elseif k == 'ModSmokeEnabled' and v then
                ToggleVehicleMod(Vehicle, 20, true)
            elseif k == 'TyreSmokeColor' then
                SetVehicleTyreSmokeColor(Vehicle, v[1], v[2], v[3])
            elseif k == 'ModExtras' then
                SetVehicleExtra(Vehicle, 1, v[1])
                SetVehicleExtra(Vehicle, 2, v[2])
                SetVehicleExtra(Vehicle, 3, v[3])
                SetVehicleExtra(Vehicle, 4, v[4])
                SetVehicleExtra(Vehicle, 5, v[5])
                SetVehicleExtra(Vehicle, 6, v[6])
                SetVehicleExtra(Vehicle, 7, v[7])
                SetVehicleExtra(Vehicle, 8, v[8])
                SetVehicleExtra(Vehicle, 9, v[9])
                SetVehicleExtra(Vehicle, 10, v[10])
            elseif k == 'ModTurbo' then
                ToggleVehicleMod(Vehicle, 18, v)
            elseif k == 'ModXenon' then
                ToggleVehicleMod(Vehicle, 22, v)
            else
                local VehicleModNumber = Shared.VehicleMods[k]
                Citizen.SetTimeout(10, function()
                    SetVehicleMod(Vehicle, VehicleModNumber, v, false)
                end)
            end
        end
        if VehicleMods.PaintTypeOne or VehicleMods.PaintTypeTwo or VehicleMods.CustomColorOne or VehicleMods.CustomColorTwo then
            local ColorOne, ColorTwo = GetVehicleColours(Vehicle)
            local PearlescentColor, WheelColor = GetVehicleExtraColours(Vehicle)

            if VehicleMods.PaintTypeOne then SetVehicleModColor_1(Vehicle, VehicleMods.PaintTypeOne, ColorOne, PearlescentColor) end
            if VehicleMods.PaintTypeTwo then SetVehicleModColor_2(Vehicle, VehicleMods.PaintTypeTwo, ColorTwo) end

            local One, Two = VehicleMods.CustomColorOne, VehicleMods.CustomColorTwo
            -- Accept arrays and objects ({"1":..}) in case the JSON came back keyed.
            local function Rgb(C) return tonumber(C[1] or C['1'] or C.r), tonumber(C[2] or C['2'] or C.g), tonumber(C[3] or C['3'] or C.b) end
            if type(One) == 'table' then local R, G, B = Rgb(One); if R then SetVehicleCustomPrimaryColour(Vehicle, R, G, B) end end
            if type(Two) == 'table' then local R, G, B = Rgb(Two); if R then SetVehicleCustomSecondaryColour(Vehicle, R, G, B) end end

            SetVehicleExtraColours(Vehicle, PearlescentColor, WheelColor)
        end

        -- Stance is applied every frame by fw-bennys (client/cl_stance.lua) from this state bag.
        if type(VehicleMods.Stance) == 'table' and next(VehicleMods.Stance) and NetworkGetEntityIsNetworked(Vehicle) then
            Entity(Vehicle).state:set('bennysStance', VehicleMods.Stance, true)
            -- Only the entity owner can set it client side; the server re-reads it from player_vehicles to be sure.
            if Plate then TriggerServerEvent('fw-bennys:Server:SyncStance', NetworkGetNetworkIdFromEntity(Vehicle), Plate) end
        end

        -- NetworkRequestControlOfEntity(Vehicle) NetworkRequestControlOfEntity(Vehicle)
        -- NetworkRequestControlOfNetworkId(NetworkGetNetworkIdFromEntity(Vehicle))
        if not FadeIgnore then NetworkFadeInEntity(Vehicle, 0) end
        return true
    else
        return false
    end
end

function FW.VSync.GetVehicleDamage(Vehicle)
    local VehicleDamage = {
        Windows = {
            [0] = IsVehicleWindowIntact(Vehicle, 0) == 1 or false,
            [1] = IsVehicleWindowIntact(Vehicle, 1) == 1 or false,
            [2] = IsVehicleWindowIntact(Vehicle, 2) == 1 or false,
            [3] = IsVehicleWindowIntact(Vehicle, 3) == 1 or false,
            [4] = IsVehicleWindowIntact(Vehicle, 4) == 1 or false,
            [5] = IsVehicleWindowIntact(Vehicle, 5) == 1 or false,
            [6] = IsVehicleWindowIntact(Vehicle, 6) == 1 or false,
            [7] = IsVehicleWindowIntact(Vehicle, 7) == 1 or false
        },
        Doors = {
            [0] = IsVehicleDoorDamaged(Vehicle, 0) == 1 or false,
            [1] = IsVehicleDoorDamaged(Vehicle, 1) == 1 or false,
            [2] = IsVehicleDoorDamaged(Vehicle, 2) == 1 or false,
            [3] = IsVehicleDoorDamaged(Vehicle, 3) == 1 or false,
            [4] = IsVehicleDoorDamaged(Vehicle, 4) == 1 or false,
            [5] = IsVehicleDoorDamaged(Vehicle, 5) == 1 or false
        },
        Tyres = {
            [0] = IsVehicleTyreBurst(Vehicle, 0) == 1 or false,
            [1] = IsVehicleTyreBurst(Vehicle, 1) == 1 or false,
            [2] = IsVehicleTyreBurst(Vehicle, 2) == 1 or false,
            [3] = IsVehicleTyreBurst(Vehicle, 3) == 1 or false,
            [4] = IsVehicleTyreBurst(Vehicle, 4) == 1 or false,
            [5] = IsVehicleTyreBurst(Vehicle, 5) == 1 or false
        }
    }

    return VehicleDamage
end

function FW.VSync.DoVehicleDamage(Vehicle, VehicleDamage, Metadata)
    if VehicleDamage == nil then return end

    if VehicleDamage.Windows ~= nil then
        for k, v in pairs(VehicleDamage.Windows) do
            if not v then
                SmashVehicleWindow(Vehicle, tonumber(k))
            end
        end
    end
    if VehicleDamage.Tyres ~= nil then
        for k, v in pairs(VehicleDamage.Tyres) do
            if v then
                SetVehicleTyreBurst(Vehicle, tonumber(k), false, 990.0)
            end
        end
    end
    if Metadata ~= nil then
        SetVehicleEngineHealth(Vehicle, (Metadata.Engine + 0.0))
        SetVehicleBodyHealth(Vehicle, (Metadata.Body + 0.0))
    end
end

function RequestSyncExecution(Native, Entity, ...)
    if DoesEntityExist(Entity) then
        TriggerServerEvent('FW:Server:Sync:Request', Native, GetPlayerServerId(NetworkGetEntityOwner(Entity)), NetworkGetNetworkIdFromEntity(Entity), ...)
    end
end

RegisterNetEvent("FW:Client:Sync:Execute", function(Native, NetId, ...)
    local Entity = NetworkGetEntityFromNetworkId(NetId)
    if DoesEntityExist(Entity) then
        if FW.VSync[Native] ~= nil then
            FW.VSync[Native](Entity, ...)
        end
    end
end)