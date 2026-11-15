RegisterNUICallback("Bank/GetAccounts", function(Data, Cb)
    Cb(FW.SendCallback("fw-financials:Server:GetPlayerAccounts") or {})
end)

RegisterNUICallback("Bank/GetTransactions", function(Data, Cb)
    Cb(FW.SendCallback("fw-phone:Server:Bank:GetTransactions", Data) or {})
end)

RegisterNUICallback("Bank/Transfer", function(Data, Cb)
    Cb(FW.SendCallback("fw-phone:Server:Bank:Transfer", Data))
end)
