local TeaZones = {
    vector4(-1428.94, -455.92, 35.90, 50.0), -- Hayes Repairs
    -- vector4(-586.91, -1061.92, 22.54, 270.0), -- UwU Cafe
    vector4(355.42, -1414.57, 32.51, 140.0), -- Crusade Hospital
    vector4(811.31, -764.41, 27.0, 0.0), -- Maldinis Pizza
    vector4(-580.9, -211.25, 38.53, 390.0), -- City Hall
}

function InitTea()
    for k, v in pairs(TeaZones) do
        exports.interact:AddInteraction({
            coords = vector3(v.x, v.y, v.z),
            distance = 10.0,
            interactDst = 1.5,
            name = 'tea_kettle_' .. k,
            options = {
                {
                    name = 'kettle',
                    label = 'Make tea',
                    event = 'fw-misc:Client:MakeTea',
                    args = {
                        Coords = vector3(v.x, v.y, v.z)
                    },
                    canInteract = function()
                        return true
                    end,
                },
            },
        })
    end
end

RegisterNetEvent("fw-misc:Client:MakeTea")
AddEventHandler("fw-misc:Client:MakeTea", function(Data, Entity)
    local HasWater = exports['fw-inventory']:HasEnoughOfItem('water_bottle', 1)
    if not HasWater then
        return FW.Functions.Notify("You need water to make tea.")
    end

    TaskTurnPedToFaceCoord(PlayerPedId(), Data.Coords, 1000)
    Citizen.Wait(1000)

    local Finished = FW.Functions.CompactProgressbar(30000, "Making tea...", false, true, {disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true}, { anim = "fullcut_cycle_v6_cokecutter", animDict = "anim@amb@business@coc@coc_unpack_cut@", flags = 0 }, {}, {}, false)

    StopAnimTask(PlayerPedId(), "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", 1.0)
    if not Finished then return end

    FW.TriggerServer("fw-misc:Server:GetTea")
end)

local IsDrinkingTea = false
RegisterNetEvent("fw-misc:Client:UsedTea")
AddEventHandler("fw-misc:Client:UsedTea", function(Item)
    if IsDrinkingTea then return end
    IsDrinkingTea = true

    local Drinks = 4

    local Removed = FW.SendCallback("FW:RemoveItem", 'mugoftea', 1)
    if not Removed then return end

    FW.Functions.Notify("Press E to take a sip of tea, or X to stop drinking.", "success", 10000)
    exports['fw-assets']:AddProp('tea')

    while not HasAnimDictLoaded("amb@world_human_drinking@coffee@male@idle_a") do
        RequestAnimDict("amb@world_human_drinking@coffee@male@idle_a")
        Citizen.Wait(0)
    end

    Citizen.CreateThread(function()
        while IsDrinkingTea do
            if not IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@idle_a", "idle_c", 3) then
                TaskPlayAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@idle_a", "idle_c", 1.0, 0.1, -1, 49, 0, 0, 0, 0)
            end

            -- Sip
            if IsControlJustPressed(0, 38) then
                if Drinks <= 0 then
                    FW.Functions.Notify("Cup of tea is empty..")
                    goto Skip
                end

                Drinks = Drinks - 1
                TaskPlayAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@idle_a", "idle_b", 1.0, 0.1, -1, 50, 0, 0, 0, 0)
                TriggerServerEvent("FW:Server:SetMetaData", "thirst", FW.Functions.GetPlayerData().metadata.thirst + 5)

                ::Skip::

                Citizen.Wait(5500)
            end

            -- Cancel
            if IsControlJustPressed(0, 73) then
                IsDrinkingTea = false
            end

            Citizen.Wait(4)
        end

        StopAnimTask(PlayerPedId(), "amb@world_human_drinking@coffee@male@idle_a", "idle_c", 1.0)
        exports['fw-assets']:RemoveProp()
    end)
end)