CallData = nil
Contacts = {
    Suggestions = {}
}

RegisterNetEvent("fw-phone:Client:AddContactSuggestion")
AddEventHandler("fw-phone:Client:AddContactSuggestion", function(Data)
    local ContactId = #Contacts.Suggestions + 1
    Data.Id = ContactId
    Contacts.Suggestions[ContactId] = Data

    if CurrentApp == 'contacts' then
        Contacts.SetSuggestedContacts()
    else
        Notification("new-contact-suggestion-" .. ContactId, "fas fa-phone-alt", { "white", "#029587" }, Data.Name, "Contact details shared.")
        SetAppUnread("contacts")
    end
end)

RegisterNetEvent("fw-phone:Client:SetCallData")
AddEventHandler("fw-phone:Client:SetCallData", function(Data)
    CallData = Data

    -- Caller holds the phone up while dialing; the receiver only once answered.
    local Me = GetPlayerServerId(PlayerId())
    SetPhoneState('call', CallData ~= nil and CallData.Dialing ~= nil and (Me ~= CallData.Target or not CallData.Dialing))
end)

RegisterNetEvent('fw-phone:Client:Contacts:SetVoice')
AddEventHandler('fw-phone:Client:Contacts:SetVoice', function(StartCall, PhoneNumber, Receiver)
    if StartCall then
        TriggerServerEvent('fw-voice:Server:Phone:StartCall', PhoneNumber, Receiver)
    else
        TriggerServerEvent('fw-voice:Server:Phone:EndCall', PhoneNumber)
    end
end)

function Contacts.SetContacts()
    local Result = FW.SendCallback("fw-phone:Server:Contacts:GetContacts")
    SendNUIMessage({
        Action = "Contacts/SetContacts",
        Contacts = Result,
    })
end

function Contacts.SetSuggestedContacts()
    SendNUIMessage({
        Action = "Contacts/SetSuggestedContacts",
        Contacts = Contacts.Suggestions,
    })
end

RegisterNUICallback("Contacts/GetContacts", function(Data, Cb)
    if UsingBurner then
        return Cb({})
    end

    local Result = FW.SendCallback("fw-phone:Server:Contacts:GetContacts")
    Cb(Result)
end)

RegisterNUICallback("Contacts/GetSuggestions", function(Data, Cb)
    Cb(Contacts.Suggestions)
end)

RegisterNUICallback("Contacts/CreateContact", function(Data, Cb)
    if UsingBurner then return Cb("Ok") end
    local Result = FW.SendCallback("fw-phone:Server:Contacts:AddContacts", Data)
    Contacts.SetContacts()
    if Data.IsSuggestion then
        table.remove(Contacts.Suggestions, Data.SuggestionId)
        Contacts.SetSuggestedContacts()
    end
    Cb("Ok")
end)

RegisterNUICallback("Contacts/DeleteContact", function(Data, Cb)
    if UsingBurner then return Cb("Ok") end
    local Result = FW.SendCallback("fw-phone:Server:Contacts:DeleteContact", Data)
    Contacts.SetContacts()
    Contacts.SetSuggestedContacts()
    Cb("Ok")
end)

RegisterNUICallback("Contacts/EditContact", function(Data, Cb)
    if UsingBurner then return Cb("Ok") end
    local Result = FW.SendCallback("fw-phone:Server:Contacts:EditContact", Data)
    Contacts.SetContacts()
    Contacts.SetSuggestedContacts()
    Cb("Ok")
end)

RegisterNUICallback("Contacts/DeleteSuggested", function(Data, Cb)
    if UsingBurner then return Cb("Ok") end
    table.remove(Contacts.Suggestions, Data.Id)
    Contacts.SetSuggestedContacts()
    Cb("Ok")
end)

RegisterNUICallback("Contacts/Call", function(Data, Cb)
    TriggerServerEvent("fw-phone:Server:DialContact", Data, UsingBurner)
    Cb("Ok")
end)