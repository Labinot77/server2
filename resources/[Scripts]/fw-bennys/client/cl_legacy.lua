-- Legacy features from the old Lua fw-bennys that other resources still use:
--   fw-ui eye menu  -> fw-bennys:Client:SaveOutfit / SwapOutfit
--   /neon command   -> fw-bennys:Client:ToggleNeon
-- Copied unchanged from fw-bennys/client/_cl_main.lua.
FW = exports['fw-core']:GetCoreObject()

RegisterNetEvent("fw-bennys:Client:SaveOutfit")
AddEventHandler("fw-bennys:Client:SaveOutfit", function(Data, Entity)
    if GetEntityType(Entity) ~= 2 then return end

    local IsOwned = FW.SendCallback("fw-vehicles:Server:GetVehicleByPlate", GetVehicleNumberPlateText(Entity)) ~= nil
    if not IsOwned then
        return FW.Functions.Notify("Kan niet bij dit voertuig..")
    end

    local Result = exports['fw-ui']:CreateInput({
        {
            Label = 'Slot',
            Icon = 'fas fa-sort-numeric-up-alt',
            Name = 'Slot',
            Type = 'number',
            Choices = {
                { Text = '1', Value = 1, },
                { Text = '2', Value = 2, },
            }
        },
    })

    if Result and Result.Slot then
        local Meta = exports['fw-vehicles']:GetVehicleMeta(Entity, 'Outfits')
        local ColorOne, ColorTwo = GetVehicleColours(Entity)
        local PearlescentColor, WheelColor = GetVehicleExtraColours(Entity)
        Meta[Result.Slot] = {
            Livery = GetVehicleMod(Entity, 48),
            ColorOne = ColorOne,
            ColorTwo = ColorTwo,
            DashboardColor = GetVehicleDashboardColour(Entity),
            PearlescentColor = PearlescentColor,
        }
        exports['fw-vehicles']:SetVehicleMeta(Entity, 'Outfits', Meta)
    end
end)

RegisterNetEvent("fw-bennys:Client:SwapOutfit")
AddEventHandler("fw-bennys:Client:SwapOutfit", function(Data, Entity)
    if GetEntityType(Entity) ~= 2 then return end

    local IsOwned = FW.SendCallback("fw-vehicles:Server:GetVehicleByPlate", GetVehicleNumberPlateText(Entity)) ~= nil
    if not IsOwned then
        return FW.Functions.Notify("Kan niet bij dit voertuig..")
    end

    local Result = exports['fw-ui']:CreateInput({
        {
            Label = 'Slot',
            Icon = 'fas fa-sort-numeric-up-alt',
            Name = 'Slot',
            Type = 'number',
            Choices = {
                { Text = '1', Value = 1, },
                { Text = '2', Value = 2, },
            }
        },
    })

    if Result and Result.Slot then
        local Meta = exports['fw-vehicles']:GetVehicleMeta(Entity, 'Outfits')
        local Outfit = Meta[Result.Slot]
        if not Outfit then
            return FW.Functions.Notify("Je hebt geen outfit opgeslagen op slot " .. Result.Slot)
        end

        local Finished = FW.Functions.CompactProgressbar(60000, "Outfitje swappen..", false, false, {disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true}, {}, {}, {}, false)
        if not Finished then return end

        local WheelColor = GetVehicleExtraColours(Entity)
        SetVehicleColours(Entity, Outfit.ColorOne, Outfit.ColorTwo)
        SetVehicleMod(Entity, 48, Outfit.Livery)
        SetVehicleDashboardColor(Entity, Outfit.DashboardColor)
        SetVehicleExtraColours(Entity, Outfit.PearlescentColor, WheelColor)
    end
end)

local NeonState = false
RegisterNetEvent("fw-bennys:Client:ToggleNeon")
AddEventHandler("fw-bennys:Client:ToggleNeon", function()
    local Vehicle = GetVehiclePedIsIn(PlayerPedId())
    if not Vehicle then return end

    NeonState = not NeonState
    if NeonState then
        DisableVehicleNeonLights(Vehicle, true)
    else
        DisableVehicleNeonLights(Vehicle, false)
    end
end)

