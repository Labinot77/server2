RegisterNetEvent("fw-ui:Ready")
AddEventHandler("fw-ui:Ready", function()
    exports['PolyZone']:CreateBox(Config.Zones, {
        name = "banking_zone",
        IsMultiple = true,
    }, function(IsInside, Zone, Points)
        NearBank = IsInside
        if not NearBank then return end

        Citizen.CreateThread(function()
            exports['fw-ui']:ShowInteraction("[E] Bank")

            while NearBank do
                if IsControlJustPressed(0, 38) then
                    exports['fw-ui']:HideInteraction()
                    TriggerEvent('fw-financials:Client:OpenFinancial', true)
                end

                Citizen.Wait(4)
            end
            
            exports['fw-ui']:HideInteraction()
        end)
    end)

    -- exports['fw-ui']:AddEyeEntry(GetHashKey("prop_fleeca_atm"), {
    --     Type = 'Model',
    --     Model = 'prop_fleeca_atm',
    --     SpriteDistance = 1.0,
    --     Options = {
    --         {
    --             Name = 'open_atm',
    --             Icon = 'fas fa-dollar-sign',
    --             Label = 'ATM',
    --             EventType = 'Client',
    --             EventName = 'fw-financials:Client:OpenFinancial',
    --             EventParams = false,
    --             Enabled = function(Entity)
    --                 return true
    --             end,
    --         },
    --         {
    --             Name = 'rob',
    --             Icon = 'fas fa-cog',
    --             Label = 'Attach Rope',
    --             EventType = 'Client',
    --             EventName = 'fw-heists:Client:AttachATM',
    --             EventParams = {},
    --             Enabled = function(Entity)
    --                 return exports['fw-heists']:GetAttachingRope()
    --             end,
    --         }
    --     }
    -- })

    -- for i = 1, 3 do
    --     exports['fw-ui']:AddEyeEntry(GetHashKey("prop_atm_0"..i), {
    --         Type = 'Model',
    --         Model = 'prop_atm_0'..i,
    --         SpriteDistance = 1.5,
    --         Options = {
    --             {
    --                 Name = 'open_atm',
    --                 Icon = 'fas fa-dollar-sign',
    --                 Label = 'ATM',
    --                 EventType = 'Client',
    --                 EventName = 'fw-financials:Client:OpenFinancial',
    --                 EventParams = false,
    --                 Enabled = function(Entity)
    --                     return true
    --                 end,
    --             },
    --             {
    --                 Name = 'rob',
    --                 Icon = 'fas fa-cog',
    --                 Label = 'Attach Rope',
    --                 EventType = 'Client',
    --                 EventName = 'fw-heists:Client:AttachATM',
    --                 EventParams = {},
    --                 Enabled = function(Entity)
    --                     return i > 1 and exports['fw-heists']:GetAttachingRope()
    --                 end,
    --             }
    --         }
    --     })
    -- end
end)

  exports.interact:AddModelInteraction({
        modelData = {
            { model = 'prop_fleeca_atm', offset = vec3(0.0, 0.0, 1.0) },
        },
        distance = 3.0,
        interactDst = 1.5,
        options = {
            {
                label = 'ATM',
                action = function(entity, coords, args)
                    OpenATM(entity)
                end,
            },
            {
                label = 'Attach Rope',
                icon = 'fas fa-cog',
                canInteract = function(entity, coords, args)
                    return exports['fw-heists']:GetAttachingRope()
                end,
                action = function(entity, coords, args)
                    TriggerEvent('fw-heists:Client:AttachATM', {})
                end,
            },
        },
    })

    exports.interact:AddModelInteraction({
        modelData = {
            { model = 'prop_atm_01', offset = vec3(-0.05, -0.15, 1.1) },
            { model = 'prop_atm_02', offset = vec3(-0.05, -0.15, 1.1) },
            { model = 'prop_atm_03', offset = vec3(0.0, -0.05, 1.0) },
        },
        distance = 3.0,
        interactDst = 1.5,
        options = {
            {
                label = 'ATM',
                action = function(entity, coords, args)
                    OpenATM(entity)
                end,
            },
        },
    })

    exports.interact:AddModelInteraction({
        modelData = {
            { model = 'prop_atm_02', offset = vec3(0.0, 0.0, 0.0)   },
            { model = 'prop_atm_03', offset = vec3(0.0, 0.0, 0.0) },
        },
        distance = 3.0,
        interactDst = 1.5,
        options = {
            {
                label = 'Attach Rope',
                canInteract = function(entity, coords, args)
                    return exports['fw-heists']:GetAttachingRope()
                end,
              action = function(entity, coords, args)
    OpenATM(entity)
end,
            },
        },
    })