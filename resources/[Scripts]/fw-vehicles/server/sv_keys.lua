local JackedVehicles = {} -- [NetId] = true, one key drop per carjack

FW.Functions.CreateCallback("fw-vehicles:Server:GetVehicleKeys", function(Source, Cb)
    Cb(Config.VehicleKeys)
end)

local function SetKeys(Plate, Cid, State)
    Config.VehicleKeys[Plate] = Config.VehicleKeys[Plate] or {}
    Config.VehicleKeys[Plate][Cid] = State
    TriggerClientEvent("fw-vehicles:Client:SetVehicleKeys", -1, Plate, Config.VehicleKeys[Plate])
end

local function HasCarKey(Player, Plate)
    for _, v in pairs(Player.PlayerData.inventory) do
        if v and v.Item == 'carkeys' and type(v.Info) == 'table' and v.Info.Plate == Plate then return true end
    end
    return false
end

function GiveCarKey(Player, Plate)
    SetKeys(Plate, Player.PlayerData.citizenid, true)
    if HasCarKey(Player, Plate) then return end
    Player.Functions.AddItem('carkeys', 1, false, { Plate = Plate, _Description = "Kenteken: " .. Plate }, true)
end

function RemoveCarKey(Player, Plate)
    if Player.Functions.RemoveItemByKV('carkeys', 1, Plate:match("^%s*(.-)%s*$"), true) then
        Player.Functions.RefreshInventory()
    end
end

RegisterNetEvent("fw-vehicles:Server:SetVehicleKeys")
AddEventHandler("fw-vehicles:Server:SetVehicleKeys", function(Plate, State, Cid)
    local Player = FW.Functions.GetPlayer(source)
    if Player == nil or Plate == nil then return end

    if Cid then
        local Target = FW.Functions.GetPlayerByCitizenId(Cid)
        if Target == nil or Target.PlayerData.source == Player.PlayerData.source then return end
        SetKeys(Plate, Target.PlayerData.citizenid, State)
        Target.Functions.Notify("Je ontving de sleutels van een voertuig..")
    else
        SetKeys(Plate, Player.PlayerData.citizenid, State)
    end
end)

FW.Functions.CreateUsableItem("carkeys", function(Source, Item)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player or not Item.Info or not Item.Info.Plate then return end
    SetKeys(Item.Info.Plate, Player.PlayerData.citizenid, true)
    Player.Functions.Notify("Sleutels van " .. Item.Info.Plate .. " in je hand.")
end)

-- Carjacking: NPC threw the keys, they become a normal ground item (pick up via interact)
RegisterNetEvent("fw-vehicles:Server:KeysDropped")
AddEventHandler("fw-vehicles:Server:KeysDropped", function(VehNetId, Coords, Heading)
    local Source = source
    local Vehicle = NetworkGetEntityFromNetworkId(VehNetId or 0)
    if Vehicle == 0 or JackedVehicles[VehNetId] or type(Coords) ~= 'vector3' then return end
    if #(GetEntityCoords(GetPlayerPed(Source)) - Coords) > 20.0 then return end

    JackedVehicles[VehNetId] = true
    local Plate = GetVehicleNumberPlateText(Vehicle)
    exports['fw-inventory']:SpawnItemDrop(Coords, 'carkeys', 1, { Plate = Plate, _Description = "Kenteken: " .. Plate }, Heading)
end)
