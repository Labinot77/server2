-- MLO houses (server): database sync, doors, decorations, garage validation and test commands.
-- FW, Config.Houses, LoadHouses, SaveHouse, HasKeyToHouse come from _sv_main.lua

local KnockCooldown = {}
local DecorDoorStates = {} -- [HouseId] = { [DecorId] = true (open) }

-- // Database sync \\ --

local function EnsureMloColumn()
    local Result = exports['ghmattimysql']:executeSync("SHOW COLUMNS FROM `player_houses` LIKE 'mlo'")
    if Result and Result[1] then return end

    exports['ghmattimysql']:executeSync("ALTER TABLE `player_houses` ADD COLUMN `mlo` VARCHAR(64) NULL DEFAULT NULL")
    print("^2[fw-housing]^7 Added `mlo` column to `player_houses`.")
end

local function GetEntranceCoords(Mlo)
    local Door = Mlo.FrontDoor and Mlo.FrontDoor.Coords or Mlo.Center
    return { x = Door.x, y = Door.y, z = Door.z, w = 0.0 }
end

-- Called from _sv_main.lua right before LoadHouses().
function SyncMloHouses()
    EnsureMloColumn()

    for Key, Mlo in pairs(Config.MLOHouses) do
        local Coords = json.encode(GetEntranceCoords(Mlo))
        local Existing = exports['ghmattimysql']:executeSync("SELECT `id`, `citizenid` FROM `player_houses` WHERE `mlo` = ?", { Key })

        if Existing and Existing[1] then
            if Existing[1].citizenid == nil then
                -- Not owned: keep label / price / class in sync with the config.
                exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `adress` = ?, `coords` = ?, `class` = ?, `price` = ?, `selling` = 1 WHERE `id` = ?", {
                    Mlo.Label, Coords, Mlo.Class or 0, Mlo.Price or 0, Existing[1].id
                })
            else
                exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `adress` = ?, `coords` = ? WHERE `id` = ?", {
                    Mlo.Label, Coords, Existing[1].id
                })
            end
        else
            -- Every JSON column gets a value, LoadHouses() json.decode's all of them.
            exports['ghmattimysql']:executeSync([[
                INSERT INTO `player_houses` (`selling`, `name`, `adress`, `class`, `tier`, `price`, `coords`, `garage`, `locations`, `keyholders`, `business`, `decorations`, `mlo`)
                VALUES (1, ?, ?, ?, 1, ?, ?, '{}', '{}', '[]', '[]', '[]', ?)
            ]], { 'mlo-' .. Key, Mlo.Label, Mlo.Class or 0, Mlo.Price or 0, Coords, Key })
            print(("^2[fw-housing]^7 Created MLO house '%s' (%s)."):format(Key, Mlo.Label))
        end
    end
end

-- // Helpers \\ --

function GetHouseIdByMlo(Key)
    for k, v in pairs(Config.Houses) do
        if v.Mlo == Key then return k end
    end
    return false
end
exports("GetHouseIdByMlo", GetHouseIdByMlo)

local function Notify(Source, Text, Type)
    TriggerClientEvent('FW:Notify', Source, Text, Type or 'primary')
end

local function GetPedCoords(Source)
    return GetEntityCoords(GetPlayerPed(Source))
end

local function GetMloHouse(HouseId)
    local House = Config.Houses[HouseId]
    if House and House.Mlo and Config.MLOHouses[House.Mlo] then
        return House, Config.MLOHouses[House.Mlo]
    end
end

local function SafeNumber(Value)
    Value = tonumber(Value)
    if Value == nil or Value ~= Value or Value == math.huge or Value == -math.huge then return nil end
    return Value
end

local function SanitizeVec(Data)
    if type(Data) ~= 'table' and type(Data) ~= 'vector3' then return nil end
    local X, Y, Z = SafeNumber(Data.x), SafeNumber(Data.y), SafeNumber(Data.z)
    if not X or not Y or not Z then return nil end
    return { x = X + 0.0, y = Y + 0.0, z = Z + 0.0 }
end

local function CanDecorate(Source, HouseId)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return false end

    local House = GetMloHouse(HouseId)
    if not House or not House.Owned then return false end

    local Cid = Player.PlayerData.citizenid
    if House.Owner == Cid then return true, Player end
    if Config.Decorate.KeyholdersCanDecorate and HasKeyToHouse(HouseId, Cid) then return true, Player end

    return false
end

local function IsValidPlacement(Source, House, Coords)
    -- The player must stand inside the house and the object must be inside the zone.
    local PlyCoords = GetPedCoords(Source)
    if not IsPointInMloZone(House.Mlo, PlyCoords) then return false end
    if #(PlyCoords - vector3(Coords.x, Coords.y, Coords.z)) > 15.0 then return false end
    return IsPointInMloZone(House.Mlo, Coords)
end

local function GetNextDecorId(Decorations)
    local Max = 0
    for _, v in pairs(Decorations) do
        if tonumber(v.Id) and v.Id > Max then Max = v.Id end
    end
    return Max + 1
end

local function FindDecor(Decorations, DecorId)
    for k, v in ipairs(Decorations) do
        if v.Id == DecorId then return k, v end
    end
end

local function CommitHouse(HouseId)
    SaveHouse(HouseId)
    TriggerClientEvent("fw-housing:Client:SyncHouse", -1, HouseId, Config.Houses[HouseId])
end

-- Gives every decoration a stable Id, called from LoadHouses().
function EnsureDecorIds(Decorations)
    if type(Decorations) ~= 'table' then return {} end
    local NextId = GetNextDecorId(Decorations)
    for _, v in ipairs(Decorations) do
        if not tonumber(v.Id) then
            v.Id, NextId = NextId, NextId + 1
        end
    end
    return Decorations
end

-- Back to the market: no owner, no keys, doors locked, (optionally) no furniture / garage.
function ResetMloHouse(HouseId)
    local House = GetMloHouse(HouseId)
    if not House then return end

    House.Owner, House.Owned, House.Selling, House.Keyholders, House.Business = false, false, true, {}, {}
    House.Locked = true
    House.DoorLocks = { Front = true, Back = true }

    if Config.MLOClearDecorOnSell then
        House.Decorations = {}
        House.Garage = false
        House.Locations.Stash, House.Locations.Wardrobe = false, false
        DecorDoorStates[HouseId] = nil
    end

    exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `citizenid` = NULL, `keyholders` = '[]', `business` = '[]', `selling` = 1 WHERE `id` = ?", { House.DbId })
    CommitHouse(HouseId)
end

-- // Validation used by _sv_main.lua (phone "set location") \\ --

-- Garage: outside the zone, close to its edge, around floor height.
function ValidateMloGarage(HouseId, Coords)
    local House = GetMloHouse(HouseId)
    if not House then return false, "Invalid house." end

    if IsPointInMloZone(House.Mlo, Coords) then
        return false, "The garage has to be outside the house."
    end

    local Mlo = Config.MLOHouses[House.Mlo]
    if Mlo.Zone.minZ and math.abs(Coords.z - Mlo.Zone.minZ) > Config.MLOGarage.MaxHeightDifference then
        return false, "The garage has to be at street level next to the house."
    end

    local Dist = GetDistanceToMloZoneEdge(House.Mlo, Coords)
    if Dist > Config.MLOGarage.MaxDistanceFromZone then
        return false, ("Too far from the house (%.1fm, max %.0fm)."):format(Dist, Config.MLOGarage.MaxDistanceFromZone)
    end

    return true
end

-- Stash / wardrobe: inside the zone.
function ValidateMloInterior(HouseId, Coords)
    local House = GetMloHouse(HouseId)
    if not House then return false end
    return IsPointInMloZone(House.Mlo, Coords)
end

function SetMloGarage(Source, HouseId)
    local House = GetMloHouse(HouseId)
    if not House then return false end

    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil or not House.Owned or not HasKeyToHouse(HouseId, Player.PlayerData.citizenid) then
        Notify(Source, "You don't have keys to this house.", "error")
        return false
    end

    -- Always use the server-side position, never coords sent by the client.
    local Ped = GetPlayerPed(Source)
    local Vehicle = GetVehiclePedIsIn(Ped, false)
    local Entity = (Vehicle and Vehicle ~= 0) and Vehicle or Ped
    local Coords, Heading = GetEntityCoords(Entity), GetEntityHeading(Entity)

    local Valid, Reason = ValidateMloGarage(HouseId, Coords)
    if not Valid then
        Notify(Source, Reason, "error")
        return false
    end

    House.Garage = vector4(Coords.x, Coords.y, Coords.z, Heading)
    TriggerEvent("fw-vehicles:Client:SetHousingGarage", House.Name, House.Garage)
    CommitHouse(HouseId)
    Notify(Source, "Garage placed.", "success")
    return true
end

-- // Doors \\ --

FW.Functions.CreateCallback("fw-housing:Server:Mlo:ToggleDoor", function(Source, Cb, HouseId, DoorKey)
    local House, Mlo = GetMloHouse(HouseId)
    local Player = FW.Functions.GetPlayer(Source)
    if not House or not Player then return Cb(false) end

    local Door = DoorKey == 'Front' and Mlo.FrontDoor or (DoorKey == 'Back' and Mlo.BackDoor or nil)
    if not Door then return Cb(false) end

    if #(GetPedCoords(Source) - Door.Coords) > 4.0 then return Cb(false) end
    if not HasKeyToHouse(HouseId, Player.PlayerData.citizenid) then
        Notify(Source, "You don't have keys to this house.", "error")
        return Cb(false)
    end

    House.DoorLocks = House.DoorLocks or { Front = true, Back = true }
    House.DoorLocks[DoorKey] = not House.DoorLocks[DoorKey]
    House.Locked = House.DoorLocks.Front -- keeps the phone / other scripts in sync with the front door

    TriggerClientEvent("fw-housing:Client:Mlo:SetDoorLock", -1, HouseId, DoorKey, House.DoorLocks[DoorKey])
    Cb({ Success = true, Locked = House.DoorLocks[DoorKey] })
end)

RegisterNetEvent("fw-housing:Server:Mlo:Knock")
AddEventHandler("fw-housing:Server:Mlo:Knock", function(HouseId, DoorKey)
    local Source = source
    local House, Mlo = GetMloHouse(HouseId)
    if not House then return end

    local Door = DoorKey == 'Front' and Mlo.FrontDoor or (DoorKey == 'Back' and Mlo.BackDoor or nil)
    if not Door or #(GetPedCoords(Source) - Door.Coords) > 4.0 then return end

    if KnockCooldown[Source] and KnockCooldown[Source] > os.time() then return end
    KnockCooldown[Source] = os.time() + 5

    for _, PlayerId in ipairs(GetPlayers()) do
        local Target = tonumber(PlayerId)
        if Target ~= Source and IsPointInMloZone(House.Mlo, GetPedCoords(Target)) then
            Notify(Target, ("Someone is knocking on the %s door."):format(DoorKey == 'Front' and 'front' or 'back'), "primary")
        end
    end
end)

AddEventHandler('playerDropped', function()
    KnockCooldown[source] = nil
end)

-- // Decorations \\ --

RegisterNetEvent("fw-housing:Server:Decor:Add")
AddEventHandler("fw-housing:Server:Decor:Add", function(HouseId, Model, Coords, Rot)
    local Source = source
    local Allowed, Player = CanDecorate(Source, HouseId)
    if not Allowed then return Notify(Source, "You can't decorate this house.", "error") end

    local House, Mlo = GetMloHouse(HouseId)
    local Item = Config.DecorByModel[Model]
    Coords, Rot = SanitizeVec(Coords), SanitizeVec(Rot)
    if not Item or not Coords or not Rot then return end

    if not IsValidPlacement(Source, House, Coords) then
        return Notify(Source, "That's outside of the house.", "error")
    end

    House.Decorations = House.Decorations or {}
    if #House.Decorations >= (Mlo.MaxDecorations or 100) then
        return Notify(Source, "This house is full, remove something first.", "error")
    end

    if Config.Decorate.ChargeMoney and (Item.Price or 0) > 0 then
        if not exports['fw-financials']:RemoveMoneyFromAccount("1001", "1", Player.PlayerData.charinfo.account, Item.Price, 'PURCHASE', 'Furniture purchased: ' .. Item.Label .. ' (' .. House.Adress .. ')') then
            return Notify(Source, "Not enough money in your bank account.", "error")
        end
    end

    House.Decorations[#House.Decorations + 1] = {
        Id = GetNextDecorId(House.Decorations),
        Model = Model,
        Type = Item.Type,
        Coords = Coords,
        Rot = Rot,
    }

    CommitHouse(HouseId)
    Notify(Source, Item.Label .. " placed.", "success")
end)

RegisterNetEvent("fw-housing:Server:Decor:Update")
AddEventHandler("fw-housing:Server:Decor:Update", function(HouseId, DecorId, Coords, Rot)
    local Source = source
    if not CanDecorate(Source, HouseId) then return end

    local House = GetMloHouse(HouseId)
    local Index = FindDecor(House.Decorations or {}, DecorId)
    Coords, Rot = SanitizeVec(Coords), SanitizeVec(Rot)
    if not Index or not Coords or not Rot then return end

    if not IsValidPlacement(Source, House, Coords) then
        return Notify(Source, "That's outside of the house.", "error")
    end

    House.Decorations[Index].Coords = Coords
    House.Decorations[Index].Rot = Rot
    if DecorDoorStates[HouseId] then DecorDoorStates[HouseId][DecorId] = nil end
    CommitHouse(HouseId)
end)

RegisterNetEvent("fw-housing:Server:Decor:Remove")
AddEventHandler("fw-housing:Server:Decor:Remove", function(HouseId, DecorId)
    local Source = source
    local Allowed, Player = CanDecorate(Source, HouseId)
    if not Allowed then return end

    local House = GetMloHouse(HouseId)
    local Index, Decor = FindDecor(House.Decorations or {}, DecorId)
    if not Index then return end

    table.remove(House.Decorations, Index)
    if DecorDoorStates[HouseId] then DecorDoorStates[HouseId][DecorId] = nil end
    CommitHouse(HouseId)

    local Item = Config.DecorByModel[Decor.Model]
    local Refund = Item and math.floor((Item.Price or 0) * ((Config.Decorate.RefundPercentage or 0) / 100)) or 0
    if Config.Decorate.ChargeMoney and Refund > 0 then
        exports['fw-financials']:AddMoneyToAccount('1001', "1", Player.PlayerData.charinfo.account, Refund, 'SELL', 'Furniture sold: ' .. Item.Label .. ' (' .. House.Adress .. ')')
        Notify(Source, ("Removed, refunded $%s."):format(Refund), "success")
    else
        Notify(Source, "Removed.", "success")
    end
end)

-- Placed doors: open / close (not persisted, everything is closed after a restart).
RegisterNetEvent("fw-housing:Server:Decor:ToggleDoor")
AddEventHandler("fw-housing:Server:Decor:ToggleDoor", function(HouseId, DecorId)
    local Source = source
    local House = GetMloHouse(HouseId)
    local Player = FW.Functions.GetPlayer(Source)
    if not House or not Player then return end

    local _, Decor = FindDecor(House.Decorations or {}, DecorId)
    if not Decor or Decor.Type ~= 'door' then return end
    if #(GetPedCoords(Source) - vector3(Decor.Coords.x, Decor.Coords.y, Decor.Coords.z)) > 4.0 then return end

    DecorDoorStates[HouseId] = DecorDoorStates[HouseId] or {}
    local Open = not DecorDoorStates[HouseId][DecorId]
    DecorDoorStates[HouseId][DecorId] = Open or nil

    TriggerClientEvent("fw-housing:Client:Decor:SetDoorOpen", -1, HouseId, DecorId, Open)
end)

FW.Functions.CreateCallback("fw-housing:Server:Decor:GetDoorStates", function(Source, Cb, HouseId)
    Cb(DecorDoorStates[HouseId] or {})
end)

FW.Functions.CreateCallback("fw-housing:Server:Decor:CanDecorate", function(Source, Cb, HouseId)
    Cb(CanDecorate(Source, HouseId) == true)
end)

RegisterNetEvent("fw-housing:Server:Mlo:SetGarage")
AddEventHandler("fw-housing:Server:Mlo:SetGarage", function(HouseId)
    SetMloGarage(source, HouseId)
end)

-- // Commands \\ --

-- The MLO house the player is in, or standing at the front/back door of.
local function GetMloHouseAtPlayer(Source)
    local Coords = GetPedCoords(Source)
    for Key, Mlo in pairs(Config.MLOHouses) do
        local Near = IsPointInMloZone(Key, Coords)
        for _, Door in ipairs(GetMloDoorList(Key)) do
            if #(Coords - Door.Data.Coords) <= 5.0 then Near = true end
        end
        if Near then return GetHouseIdByMlo(Key) end
    end
end

local function ResolveHouse(Source, Arg)
    if Arg and Arg ~= '' then return GetHouseIdByMlo(Arg) end
    return GetMloHouseAtPlayer(Source)
end

if Config.MLOTest.Enabled then
    FW.Commands.Add("buymlo", "[TEST] Buy the MLO house you are at (or by key)", {
        { name = "house", help = "(optional) MLO key from sh_mlo.lua, e.g. test" },
    }, false, function(Source, Args)
        local Player = FW.Functions.GetPlayer(Source)
        if Player == nil then return end

        local HouseId = ResolveHouse(Source, Args[1])
        local House = HouseId and GetMloHouse(HouseId)
        if not House then return Notify(Source, "Stand inside or at the door of an MLO house.", "error") end
        if House.Owned then return Notify(Source, "This house already has an owner.", "error") end

        local Price = House.Price or 0
        if Config.MLOTest.ChargeMoney and Price > 0 then
            if not exports['fw-financials']:RemoveMoneyFromAccount("1001", "1", Player.PlayerData.charinfo.account, Price, 'PURCHASE', 'House purchased: ' .. House.Adress) then
                return Notify(Source, "Not enough money in your bank account.", "error")
            end
        end

        local Cid = Player.PlayerData.citizenid
        House.Owner, House.Owned, House.Selling, House.Keyholders = Cid, true, false, { Cid }
        exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `citizenid` = ?, `keyholders` = ?, `selling` = 0 WHERE `id` = ?", {
            Cid, json.encode({ Cid }), House.DbId
        })

        CommitHouse(HouseId)
        Notify(Source, ("You bought %s%s."):format(House.Adress, Config.MLOTest.ChargeMoney and (" for $" .. Price) or ""), "success")
    end, Config.MLOTest.Permission)

    FW.Commands.Add("sellmlo", "[TEST] Put an MLO house back on the market", {
        { name = "house", help = "(optional) MLO key from sh_mlo.lua, e.g. test" },
    }, false, function(Source, Args)
        local HouseId = ResolveHouse(Source, Args[1])
        if not HouseId or not GetMloHouse(HouseId) then return Notify(Source, "Unknown MLO house.", "error") end

        ResetMloHouse(HouseId)
        Notify(Source, "House reset, it is for sale again.", "success")
    end, Config.MLOTest.Permission)
end

FW.Commands.Add("mlogarage", "Place the garage of the MLO house you have keys to (stand where the car should park)", {
    { name = "house", help = "(optional) MLO key, e.g. test" },
}, false, function(Source, Args)
    local HouseId = Args[1] and GetHouseIdByMlo(Args[1])
    if not HouseId then
        -- Closest MLO house (by zone edge) the player has keys to.
        local Player, Coords, Best = FW.Functions.GetPlayer(Source), GetPedCoords(Source), math.huge
        if Player == nil then return end
        for Key in pairs(Config.MLOHouses) do
            local Id = GetHouseIdByMlo(Key)
            local Dist = GetDistanceToMloZoneEdge(Key, Coords)
            if Id and Dist < Best and HasKeyToHouse(Id, Player.PlayerData.citizenid) then
                HouseId, Best = Id, Dist
            end
        end
    end

    if not HouseId then return Notify(Source, "You don't have keys to an MLO house nearby.", "error") end
    SetMloGarage(Source, HouseId)
end)

FW.Commands.Add("mlodoor", "Print the model + coords of the door you are looking at (for sh_mlo.lua)", {}, false, function(Source)
    TriggerClientEvent("fw-housing:Client:Mlo:DoorInfo", Source)
end, "admin")
