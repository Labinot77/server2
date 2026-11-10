local VendingMachines = {
    { Prop = "prop_vend_coffe_01", Vending = "Coffee" },
    { Prop = "prop_vend_fridge01", Vending = "Soda" },
    { Prop = "prop_vend_snak_01", Vending = "Candy" },
    { Prop = "prop_vend_soda_02", Vending = "Soda" },
    { Prop = "prop_vend_water_01", Vending = "Water" },
    { Prop = "prop_vend_snak_01_tu", Vending = "Candy" },
    { Prop = "v_68_broeknvend", Vending = "Soda" },
    { Prop = "prop_vend_soda_01", Vending = "Soda" },
    { Prop = "ch_chint10_vending_smallroom_01", Vending = "Soda" },
    { Prop = "sf_prop_sf_vend_drink_01a", Vending = "Soda" },
    { Prop = "prop_watercooler", Vending = "Water" },
    { Prop = "prop_watercooler_dark", Vending = "Water" },
}

local function AddVendingInteractions()
    for k, v in pairs(VendingMachines) do
        exports.interact:AddModelInteraction({
            modelData = {
                { model = v.Prop, offset = vec3(0.0, -0.3, 1.2) },
            },
            distance = 3.5,   -- was SpriteDistance
            interactDst = 1.5, -- was Distance
            options = {
                {
                    name = "open_vending",
                    label = "Open",
                    args = { Vending = v.Vending },
                    canInteract = function(entity, coords, args)
                        return true
                    end,
                    action = function(entity, coords, args)
                        TriggerEvent("fw-misc:Client:OpenVending", args, entity)
                    end,
                },
            },
        })
    end
end

CreateThread(AddVendingInteractions)

-- Re-register if interact gets restarted while this resource keeps running
AddEventHandler("onResourceStart", function(resource)
    if resource == "interact" then
        AddVendingInteractions()
    end
end)

RegisterNetEvent("fw-misc:Client:OpenVending")
AddEventHandler("fw-misc:Client:OpenVending", function(Data)
    if exports['fw-inventory']:CanOpenInventory() then
        FW.TriggerServer('fw-inventory:Server:OpenInventory', 'Store', 'Vending' .. Data.Vending)
    end
end)