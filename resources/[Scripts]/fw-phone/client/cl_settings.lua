-- Phone settings, persisted per client.
PhoneSettings = json.decode(GetResourceKvpString("fw-phone:settings") or "{}") or {}

function GetPhoneSetting(Key)
    return PhoneSettings[Key]
end

RegisterNUICallback("Settings/Set", function(Data, Cb)
    PhoneSettings[Data.Key] = Data.Value
    SetResourceKvp("fw-phone:settings", json.encode(PhoneSettings))
    Cb("Ok")
end)
