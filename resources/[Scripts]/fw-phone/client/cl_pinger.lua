local PingerBlip = nil

RegisterNUICallback("Pinger/SendPing", function(Data, Cb)
    PlaySound(-1, "Click_Fail", "WEB_NAVIGATION_SOUNDS_PHONE", 0, 0, 1)
    TriggerServerEvent("fw-phone:Server:Pinger:SendPing", Data)

    Cb("Ok")
end)

RegisterNetEvent("fw-phone:Client:Pinger:SetBlip")
AddEventHandler("fw-phone:Client:Pinger:SetBlip", function(Coords)
    if DoesBlipExist(PingerBlip) then
        RemoveBlip(PingerBlip)
    end
    PingerBlip = AddBlipForCoord(Coords)
    SetBlipSprite(PingerBlip, 280)
    SetBlipScale(PingerBlip, 1.2)
    SetBlipColour(PingerBlip, 4)
    SetBlipAsShortRange(PingerBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Accepted GPS Position")
    EndTextCommandSetBlipName(PingerBlip)

    FW.Functions.Notify("GPS ping has been marked on the map.", "success")
    Citizen.SetTimeout((60 * 1000) * 1, function()
        if DoesBlipExist(PingerBlip) then
            RemoveBlip(PingerBlip)
        end
    end)
end)