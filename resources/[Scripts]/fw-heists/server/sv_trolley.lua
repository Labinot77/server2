-- Grabbed = part of the trolley taken (0-1, stopped early with X): the payout scales with it.
FW.RegisterServer("fw-heists:Server:Trolley:PayoutGrab", function(Source, TrolleyId, Trolley, Grabbed)
    local Part = math.max(0.0, math.min(1.0, tonumber(Grabbed) or 1.0))
    local function Rnd(Min, Max) return math.floor(math.random(Min, Max) * Part) end
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end
    local function Bills(N) if N > 0 then Player.Functions.AddItem('markedbills', N, false, nil, true) end end

    if DataManager.Get("trolley-" .. TrolleyId, 0) ~= 2 then
        return
    end

    if TrolleyId == "baycity_1" then
        Bills(Rnd(130, 160))
        Player.Functions.AddMoney('cash', Rnd(3000, 6000), 'Bay City Bank Vault')
    elseif TrolleyId == "vault-1" or TrolleyId == "vault-2" or TrolleyId == "vault-3" or TrolleyId == "vault-4" then -- Cash
        Bills(Rnd(135, 200))
        Player.Functions.AddMoney('cash', Rnd(8000, 11000), 'The City Vault')
    elseif tostring(TrolleyId):match('^fleeca%-') then -- advanced Fleeca vault trolley
        local P = Config.FleecaAdvanced.Trolley
        Bills(Rnd(P.MarkedBills[1], P.MarkedBills[2]))
        Player.Functions.AddMoney('cash', Rnd(P.Cash[1], P.Cash[2]), 'Fleeca Vault')
    else
        print("Invalid Trolley Payout.")
    end
end)
-- Grab speed (Space) relayed to everyone, so the synced grab scene plays at the same speed for all (cl_trolley.lua)
RegisterNetEvent('fw-heists:Server:Trolley:Rate', function(NetScene, Rate)
    TriggerClientEvent('fw-heists:Client:Trolley:Rate', -1, NetScene, math.min(tonumber(Rate) or 1.0, 4.0))
end)
