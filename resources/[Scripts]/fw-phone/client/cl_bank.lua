RegisterNUICallback("Bank/GetAccounts", function(Data, Cb)
    Cb(FW.SendCallback("fw-financials:Server:GetPlayerAccounts") or {})
end)
