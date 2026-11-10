local PayPhones = {
    "p_phonebox_01b_s",
    "prop_phonebox_01a",
    "prop_phonebox_01b",
    "prop_phonebox_01c",
    "prop_phonebox_02",
    "prop_phonebox_03",
    "prop_phonebox_04",
    "ch_chint02_phonebox001",
    "sf_prop_sf_phonebox_01b_s",
    "sf_prop_sf_phonebox_01b_straight",
}

local CallingFromPayphone, PayphoneCoords = false, false

RegisterNetEvent("fw-ui:Ready")
AddEventHandler("fw-ui:Ready", function()
    local modelData = {}
    for _, model in ipairs(PayPhones) do
        modelData[#modelData + 1] = {
            model = model,
            offset = vec3(0.0, 0.0, 1.0),
        }
    end

    exports['interact']:AddModelInteraction({
        modelData = modelData,
        distance = 5.0,
        interactDst = 1.5,
        options = {
            {
                name = 'call_payphone',
                label = 'Use Payphone',
                action = function(entity, coords, args)
                    TriggerEvent('fw-misc:Client:Payphones:Call', {
                        Costs = 150,
                        Caller = 'Telefooncel',
                        Phone = "69" .. tostring(FW.Shared.RandomInt(9)),
                    })
                end,
            },
        },
    })
end)
RegisterNetEvent("fw-misc:Client:Payphones:Call")
AddEventHandler("fw-misc:Client:Payphones:Call", function(Data, Entity)
    PayphoneCoords = GetEntityCoords(Entity)

    local Result = exports['fw-ui']:CreateInput({
        { Label = 'Phone Number', Icon = 'fas fa-phone', Name = 'Phone' },
    })

    if Result and Result.Phone and #Result.Phone == 10 then
        local CashRemoved = FW.SendCallback("FW:RemoveCash", Data.Costs)
        if not CashRemoved then
            return FW.Functions.Notify("No cash..", "error")
        end
        
        CallingFromPayphone = true
        TriggerServerEvent("fw-phone:Server:DialPayphone", {
            Phone = Result.Phone,
            CallerName = Data.Caller,
            CallingFrom = Data.Phone,
        })
    end
end)

RegisterNetEvent("fw-misc:Client:DialPhone")
AddEventHandler("fw-misc:Client:DialPhone", function(...)
    TriggerServerEvent("fw-phone:Server:DialPayphone", ...)
end)

RegisterNetEvent("fw-phone:Client:SetCallData")
AddEventHandler("fw-phone:Client:SetCallData", function(Data)
    if not PayphoneCoords then return end

    if not Data then
        CallingFromPayphone = false
        return
    end

    CallingFromPayphone = Data.Payphone

    Citizen.CreateThread(function()
        if not PayphoneCoords then end
        while CallingFromPayphone and #(GetEntityCoords(PlayerPedId()) - PayphoneCoords) <= 3.0 do Citizen.Wait(500) end
        if #(GetEntityCoords(PlayerPedId()) - PayphoneCoords) > 3.0 then
            FW.Functions.Notify("You're going too far from the phone booth..", "error")
            TriggerServerEvent('fw-phone:Server:Contacts:DeclineCall', { CallId = Data.CallId })
        end
        PayphoneCoords = false
    end)
end)