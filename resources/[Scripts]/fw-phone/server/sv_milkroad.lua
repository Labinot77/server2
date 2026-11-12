FW.Functions.CreateCallback("fw-phone:Server:MilkRoad:GetProducts", function(Source, Cb, Network)
    Cb(Config.MilkRoadProducts[Network])
end)

FW.Functions.CreateCallback("fw-phone:Server:MilkRoad:PurchaseProduct", function(Source, Cb, Network, Data)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    if not IsNetworkEnabled then
        return Cb({Success = false, Msg = "No internet access.."})
    end

    local Product = Config.MilkRoadProducts[Network][Data.Id]
    if not Product then return Cb({Success = false, Msg = "Invalid product"}) end

    local Crypto = Config.Crypto[Product.Costs.CryptoId]

    if not Player.Functions.RemoveCrypto(Crypto.Id, tonumber(Product.Costs.Amount)) then
        Cb({Success = false, Msg = "Not enough crypto"})
        return
    end

    Citizen.CreateThread(function()
        TriggerEvent('fw-phone:Server:Mails:AddMail', 'Dark Market', '#A-1001', "You know where to go.", Source)
        TriggerClientEvent("fw-heists:Client:MarkPickupGPS", Source, vector3(436.31, 2996.2, 41.28))
        while true do
            if #(GetEntityCoords(GetPlayerPed(Source)) - vector3(436.31, 2996.2, 41.28)) < 2.0 then
                Player.Functions.Notify("You got your stuff, now get out of here..", "error")
                Player.Functions.AddItem(Product.Reward.Item, 1, nil, nil, true, Product.Reward.CustomType)

                if Product.Reward.Item == "vpn" then
                    if not IsPlayerInGroup(Player.PlayerData.citizenid) then
                        TriggerEvent("fw-phone:Server:Mails:AddMail", "The Unknown", "Welcome to the dark side.", "Hey, I noticed you got yourself a VPN. You now have the 'TierUp!' app on your phone. Create a group in it to start building your reputation... Happy robbing!", Source)
                    end
                end
                
                return
            end

            Citizen.Wait(1500)
        end
    end)

    Cb({Success = true})
end)