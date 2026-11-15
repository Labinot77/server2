Messages = {
    CurrentChat = nil,
}

function Messages.SetChats()
    local Result = FW.SendCallback("fw-phone:Server:Messages:GetChats", UsingBurner)
    SendNUIMessage({
        Action = "Messages/SetChats",
        Chats = Result,
    })
end

RegisterNUICallback("Messages/GetChats", function(Data, Cb)
    local Result = FW.SendCallback("fw-phone:Server:Messages:GetChats", UsingBurner)
    Cb(Result)
end)

RegisterNUICallback("Messages/SetChatRead", function(Data, Cb)
    TriggerServerEvent('fw-phone:Server:Messages:SetChatRead', Data, UsingBurner)
    Cb("Ok")
end)

RegisterNUICallback("Messages/SendMessage", function(Data, Cb)
    local Result = FW.SendCallback("fw-phone:Server:Messages:SendMessage", Data, UsingBurner)
    Cb(Result)
end)

RegisterNUICallback("Messages/CreateGroup", function(Data, Cb)
    Cb(FW.SendCallback("fw-phone:Server:Messages:CreateGroup", Data, UsingBurner))
end)

RegisterNUICallback("Messages/LeaveGroup", function(Data, Cb)
    Cb(FW.SendCallback("fw-phone:Server:Messages:LeaveGroup", Data, UsingBurner))
end)

RegisterNUICallback("Messages/GetLocation", function(Data, Cb)
    local Coords = GetEntityCoords(PlayerPedId())
    Cb(("%.2f,%.2f"):format(Coords.x, Coords.y))
end)

RegisterNUICallback("Messages/SetWaypoint", function(Data, Cb)
    local X, Y = tostring(Data.Loc or ''):match('^(%-?%d+%.?%d*),(%-?%d+%.?%d*)$')
    if X then
        SetNewWaypoint(tonumber(X) + 0.0, tonumber(Y) + 0.0)
        FW.Functions.Notify("Waypoint set on your GPS.")
    end
    Cb("Ok")
end)

RegisterNetEvent("fw-phone:Client:Messages:RefreshMessagesChat")
AddEventHandler("fw-phone:Client:Messages:RefreshMessagesChat", function(Data, Notify)
    if Notify and CurrentApp ~= 'messages' then
        if exports['fw-hud']:GetPreferenceById('Notifications.SMS') and not GetPhoneSetting('MuteMessages') then
            Notification("new-sms-" .. Data.Phone .. '-' .. math.random(1, 999), "fas fa-comment", { "white", "#8FC24C" }, Data.Name, Data.Message)
        end
        SetAppUnread("messages")
        return
    end

    Messages.SetChats()
end)