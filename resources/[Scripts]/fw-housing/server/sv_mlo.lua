-- MLO houses (server): database sync, fw-doors doors, keys / access, surfaces, decorations, garage, commands.
-- FW, Config.Houses, LoadHouses, SaveHouse, HasKeyToHouse come from _sv_main.lua

local DecorDoorStates = {} -- [HouseId] = { [DecorId] = true (open) }

-- // Database sync \\ --

local function EnsureColumn(Name, Type)
    local Result = exports['ghmattimysql']:executeSync(("SHOW COLUMNS FROM `player_houses` LIKE '%s'"):format(Name))
    if Result and Result[1] then return end
    exports['ghmattimysql']:executeSync(("ALTER TABLE `player_houses` ADD COLUMN `%s` %s NULL DEFAULT NULL"):format(Name, Type))
    print(("^2[fw-housing]^7 Added `%s` column to `player_houses`."):format(Name))
end

local function GetEntranceCoords(Mlo)
    local Door = (GetMloDoors(Mlo.Key)[1] or {}).Coords or Mlo.Center
    return { x = Door.x, y = Door.y, z = Door.z, w = 0.0 }
end

-- One `player_houses` row per MLO house (created / kept in sync with the definition).
local function SyncMloHouseRow(Key, Mlo)
    local Coords = json.encode(GetEntranceCoords(Mlo))
    local Existing = exports['ghmattimysql']:executeSync("SELECT `id`, `citizenid` FROM `player_houses` WHERE `mlo` = ?", { Key })

    if Existing and Existing[1] then
        if Existing[1].citizenid == nil then
            exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `adress` = ?, `coords` = ?, `class` = ?, `price` = ?, `selling` = 1 WHERE `id` = ?", {
                Mlo.Label, Coords, Mlo.Class or 0, Mlo.Price or 0, Existing[1].id
            })
        else
            exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `adress` = ?, `coords` = ? WHERE `id` = ?", { Mlo.Label, Coords, Existing[1].id })
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

-- Called from _sv_main.lua right before LoadHouses(). Loads the in-game made houses, then makes sure every house has a row.
function SyncMloHouses()
    EnsureColumn('mlo', 'VARCHAR(64)')
    EnsureColumn('mlo_data', 'LONGTEXT')
    exports['ghmattimysql']:executeSync("CREATE TABLE IF NOT EXISTS `mlo_houses` (`key` VARCHAR(64) NOT NULL PRIMARY KEY, `data` LONGTEXT NOT NULL)")

    for _, Row in ipairs(exports['ghmattimysql']:executeSync("SELECT * FROM `mlo_houses`") or {}) do
        local Def = json.decode(Row.data)
        if Def and Def.Zone then
            Def.Dynamic = true
            RegisterMloDef(Row.key, Def)
        end
    end

    for Key, Mlo in pairs(Config.MLOHouses) do SyncMloHouseRow(Key, Mlo) end
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

-- Owner has everything, keyholders have Doors / Stash / Decorate unless the owner turned it off.
function HasMloAccess(House, Cid, Perm)
    if not House or not House.Owned or not Cid then return false end
    if House.Owner == Cid then return true end
    for _, v in ipairs(House.Keyholders or {}) do
        if v == Cid then
            local A = House.MloData and House.MloData.Access and House.MloData.Access[Cid]
            return not A or A[Perm] ~= false
        end
    end
    return false
end

local function CanDecorate(Source, HouseId)
    local Player = FW.Functions.GetPlayer(Source)
    local House = GetMloHouse(HouseId)
    if Player and HasMloAccess(House, Player.PlayerData.citizenid, 'Decorate') then return true, Player end
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
    RefreshMloDoorAccess(HouseId)
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
    House.MloData = {}
    SetMloDoorsLocked(HouseId, true)

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

-- // Doors (fw-doors) \\ --

local function DoorCids(House)
    local List = {}
    if House.Owned then
        List[1] = House.Owner
        for _, Cid in ipairs(House.Keyholders or {}) do
            if Cid ~= House.Owner and HasMloAccess(House, Cid, 'Doors') then List[#List + 1] = Cid end
        end
    end
    return List
end

function RegisterAllMloDoors()
    if GetResourceState('fw-doors') ~= 'started' then return end
    for HouseId, House in pairs(Config.Houses) do
        if House.Mlo then
            local Doors, Cids = GetMloDoors(House.Mlo), DoorCids(House)
            for _, D in ipairs(Doors) do
                local Connected = {}
                for _, O in ipairs(Doors) do
                    if O.Side == D.Side and O.Info ~= D.Info then Connected[#Connected + 1] = O.Info end
                end
                exports['fw-doors']:SetRuntimeDoor({ Info = D.Info, Model = D.Model, Coords = D.Coords, CitizenIds = Cids, Connected = Connected })
            end
            House.Locked = exports['fw-doors']:IsDoorLocked(Doors[1] and Doors[1].Info)
        end
    end
end

function RefreshMloDoorAccess(HouseId)
    local House = GetMloHouse(HouseId)
    if not House then return end
    local Cids = DoorCids(House)
    for _, D in ipairs(GetMloDoors(House.Mlo)) do exports['fw-doors']:SetDoorAccess(D.Info, Cids) end
end

function SetMloDoorsLocked(HouseId, Locked, Side)
    local House = GetMloHouse(HouseId)
    if not House then return end
    for _, D in ipairs(GetMloDoors(House.Mlo)) do
        if not Side or D.Side == Side then exports['fw-doors']:SetDoorLocked(D.Info, Locked) end
    end
end

-- Front door locked / unlocked through fw-doors -> keep House.Locked (phone, radial) in sync.
AddEventHandler('fw-doors:Server:DoorChanged', function(Info, Locked)
    local Key, Side = tostring(Info):match('^HOUSE_(.+)_(%a+)_%d+$')
    local HouseId = Key and Side == 'Front' and GetHouseIdByMlo(Key)
    if not HouseId or Config.Houses[HouseId].Locked == Locked then return end
    Config.Houses[HouseId].Locked = Locked
    TriggerClientEvent("fw-housing:Client:SyncHouse", -1, HouseId, Config.Houses[HouseId])
end)

AddEventHandler('onResourceStart', function(Res)
    if Res == 'fw-doors' and Config.Houses then SetTimeout(1000, RegisterAllMloDoors) end
end)

-- // Owner menu: keys, access, surfaces \\ --

local function GetOwnedHouse(Source, HouseId)
    local Player = FW.Functions.GetPlayer(Source)
    local House = GetMloHouse(HouseId)
    if Player and House and House.Owner == Player.PlayerData.citizenid then return House end
end

local function SaveKeys(HouseId)
    local House = Config.Houses[HouseId]
    exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `keyholders` = ? WHERE `id` = ?", { json.encode(House.Keyholders), House.DbId })
    CommitHouse(HouseId)
end

FW.Functions.CreateCallback("fw-housing:Server:Mlo:GetManage", function(Source, Cb, HouseId)
    local House = GetOwnedHouse(Source, HouseId)
    if not House then return Cb(false) end

    local Keys, Nearby, Ped = {}, {}, GetPedCoords(Source)
    for _, Cid in ipairs(House.Keyholders) do
        if Cid ~= House.Owner then
            local A = House.MloData.Access and House.MloData.Access[Cid] or {}
            Keys[#Keys + 1] = { Cid = Cid, Name = FW.Functions.GetPlayerCharName(Cid), Doors = A.Doors ~= false, Stash = A.Stash ~= false, Decorate = A.Decorate ~= false }
        end
    end
    for _, Id in ipairs(GetPlayers()) do
        local Target = FW.Functions.GetPlayer(tonumber(Id))
        if Target and tonumber(Id) ~= Source and #(GetPedCoords(Id) - Ped) < 5.0 then
            Nearby[#Nearby + 1] = { Id = tonumber(Id), Name = Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname }
        end
    end
    Cb({ Keys = Keys, Nearby = Nearby, Surfaces = House.MloData.Surfaces or {} })
end)

RegisterNetEvent("fw-housing:Server:Mlo:AddKey", function(HouseId, TargetId)
    local Source = source
    local House, Target = GetOwnedHouse(Source, HouseId), FW.Functions.GetPlayer(tonumber(TargetId) or -1)
    if not House or not Target or #(GetPedCoords(Source) - GetPedCoords(Target.PlayerData.source)) > 5.0 then return end

    local Cid = Target.PlayerData.citizenid
    if HasKeyToHouse(HouseId, Cid) then return Notify(Source, "They already have keys.", "error") end
    table.insert(House.Keyholders, Cid)
    SaveKeys(HouseId)
    Notify(Source, "Keys given.", "success")
    Notify(Target.PlayerData.source, "You received the keys of " .. House.Adress .. ".", "success")
end)

RegisterNetEvent("fw-housing:Server:Mlo:RemoveKey", function(HouseId, Cid)
    local House = GetOwnedHouse(source, HouseId)
    if not House or Cid == House.Owner then return end
    for I, v in ipairs(House.Keyholders) do
        if v == Cid then table.remove(House.Keyholders, I) break end
    end
    if House.MloData.Access then House.MloData.Access[Cid] = nil end
    SaveKeys(HouseId)
    Notify(source, "Keys removed.", "success")
end)

local Perms = { Doors = true, Stash = true, Decorate = true }
RegisterNetEvent("fw-housing:Server:Mlo:SetAccess", function(HouseId, Cid, Perm, Value)
    local House = GetOwnedHouse(source, HouseId)
    if not House or not Perms[Perm] or not HasKeyToHouse(HouseId, Cid) then return end
    House.MloData.Access = House.MloData.Access or {}
    House.MloData.Access[Cid] = House.MloData.Access[Cid] or {}
    House.MloData.Access[Cid][Perm] = Value == true
    CommitHouse(HouseId)
end)

local Surfaces = { Walls = true, Floor = true, Ceiling = true }
RegisterNetEvent("fw-housing:Server:Mlo:SetSurface", function(HouseId, Surface, Hex)
    local House = GetOwnedHouse(source, HouseId)
    if not House or not Surfaces[Surface] or (Hex and not tostring(Hex):match('^#%x%x%x%x%x%x$')) then return end
    House.MloData.Surfaces = House.MloData.Surfaces or {}
    House.MloData.Surfaces[Surface] = Hex or nil
    CommitHouse(HouseId)
end)

-- // Decorations \\ --

RegisterNetEvent("fw-housing:Server:Decor:Add")
AddEventHandler("fw-housing:Server:Decor:Add", function(HouseId, Model, Coords, Rot, Wall)
    local Source = source
    local Allowed, Player = CanDecorate(Source, HouseId)
    if not Allowed then return Notify(Source, "You can't decorate this house.", "error") end

    local House, Mlo = GetMloHouse(HouseId)
    local Item, Label, Price = GetDecorItem(Model), GetItemLabel(tostring(Model)), Config.Decorate.Price or 0
    Coords, Rot = SanitizeVec(Coords), SanitizeVec(Rot)
    if not Item or not Coords or not Rot then return end
    if Item.Type == 'wall' then
        Wall = SanitizeWall(Wall)
        if not Wall then return end
    end

    if not IsValidPlacement(Source, House, Coords) then
        return Notify(Source, "That's outside of the house.", "error")
    end

    House.Decorations = House.Decorations or {}
    if #House.Decorations >= (Mlo.MaxDecorations or 100) then
        return Notify(Source, "This house is full, remove something first.", "error")
    end

    if Config.Decorate.ChargeMoney and Price > 0 then
        if not exports['fw-financials']:RemoveMoneyFromAccount("1001", "1", Player.PlayerData.charinfo.account, Price, 'PURCHASE', 'Furniture purchased: ' .. Label .. ' (' .. House.Adress .. ')') then
            return Notify(Source, "Not enough money in your bank account.", "error")
        end
    end

    House.Decorations[#House.Decorations + 1] = {
        Id = GetNextDecorId(House.Decorations),
        Model = Model,
        Type = Item.Type,
        Wall = Item.Type == 'wall' and Wall or nil,
        Coords = Coords,
        Rot = Rot,
    }

    CommitHouse(HouseId)
    Notify(Source, Label .. " placed.", "success")
end)

RegisterNetEvent("fw-housing:Server:Decor:Update")
AddEventHandler("fw-housing:Server:Decor:Update", function(HouseId, DecorId, Coords, Rot, Wall)
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
    if Wall and House.Decorations[Index].Type == 'wall' then House.Decorations[Index].Wall = SanitizeWall(Wall) or House.Decorations[Index].Wall end
    if DecorDoorStates[HouseId] then DecorDoorStates[HouseId][DecorId] = nil end
    CommitHouse(HouseId)
end)

local function SanitizeTint(Tint)
    Tint = math.floor(tonumber(Tint) or 0)
    return Tint > 0 and Tint < (Config.Decorate.Tints or 16) and Tint or nil
end

-- Batch save from the decorate editor: { Adds = { { Model, Coords, Rot, Wall, Tint } }, Updates = { { Id, Coords, Rot, Wall, Tint } }, Removes = { Id } }
RegisterNetEvent("fw-housing:Server:Decor:Save")
AddEventHandler("fw-housing:Server:Decor:Save", function(HouseId, Changes)
    local Source = source
    local Allowed, Player = CanDecorate(Source, HouseId)
    if not Allowed or type(Changes) ~= 'table' then return end

    local House, Mlo = GetMloHouse(HouseId)
    if not IsPointInMloZone(House.Mlo, GetPedCoords(Source)) then return Notify(Source, "You have to be inside the house.", "error") end
    House.Decorations = House.Decorations or {}
    local Account, Price = Player.PlayerData.charinfo.account, Config.Decorate.Price or 0
    local Refund = math.floor(Price * (Config.Decorate.RefundPercentage or 0) / 100)
    local Skipped = 0

    for _, Id in ipairs(type(Changes.Removes) == 'table' and Changes.Removes or {}) do
        local Index, Decor = FindDecor(House.Decorations, Id)
        if Index then
            table.remove(House.Decorations, Index)
            if DecorDoorStates[HouseId] then DecorDoorStates[HouseId][Id] = nil end
            if Config.Decorate.ChargeMoney and Refund > 0 then
                exports['fw-financials']:AddMoneyToAccount('1001', "1", Account, Refund, 'SELL', 'Furniture sold: ' .. GetItemLabel(Decor.Model) .. ' (' .. House.Adress .. ')')
            end
        end
    end

    for _, U in ipairs(type(Changes.Updates) == 'table' and Changes.Updates or {}) do
        local _, Decor = FindDecor(House.Decorations, U.Id)
        local Coords, Rot = SanitizeVec(U.Coords), SanitizeVec(U.Rot)
        if Decor and Coords and Rot and IsPointInMloZone(House.Mlo, Coords) then
            Decor.Coords, Decor.Rot = Coords, Rot
            if Decor.Type == 'wall' and U.Wall then Decor.Wall = SanitizeWall(U.Wall) or Decor.Wall end
            Decor.Tint = SanitizeTint(U.Tint)
            if DecorDoorStates[HouseId] then DecorDoorStates[HouseId][Decor.Id] = nil end
        else
            Skipped = Skipped + 1
        end
    end

    for _, A in ipairs(type(Changes.Adds) == 'table' and Changes.Adds or {}) do
        local Item = GetDecorItem(A.Model)
        local Coords, Rot = SanitizeVec(A.Coords), SanitizeVec(A.Rot)
        local Wall = Item and Item.Type == 'wall' and SanitizeWall(A.Wall) or nil
        if not Item or not Coords or not Rot or not IsPointInMloZone(House.Mlo, Coords) or (Item.Type == 'wall' and not Wall) then
            Skipped = Skipped + 1
        elseif #House.Decorations >= (Mlo.MaxDecorations or 100) then
            Notify(Source, "This house is full, not everything was placed.", "error")
            break
        elseif Config.Decorate.ChargeMoney and Price > 0 and not exports['fw-financials']:RemoveMoneyFromAccount("1001", "1", Account, Price, 'PURCHASE', 'Furniture purchased: ' .. GetItemLabel(A.Model) .. ' (' .. House.Adress .. ')') then
            Notify(Source, "Not enough money in your bank account.", "error")
            break
        else
            House.Decorations[#House.Decorations + 1] = { Id = GetNextDecorId(House.Decorations), Model = A.Model, Type = Item.Type, Wall = Wall, Coords = Coords, Rot = Rot, Tint = SanitizeTint(A.Tint) }
        end
    end

    CommitHouse(HouseId)
    Notify(Source, Skipped > 0 and ("Saved (%d skipped, outside of the house)."):format(Skipped) or "House saved.", Skipped > 0 and "error" or "success")
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

    local Refund = math.floor((Config.Decorate.Price or 0) * (Config.Decorate.RefundPercentage or 0) / 100)
    if Config.Decorate.ChargeMoney and Refund > 0 then
        exports['fw-financials']:AddMoneyToAccount('1001', "1", Player.PlayerData.charinfo.account, Refund, 'SELL', 'Furniture sold: ' .. GetItemLabel(Decor.Model) .. ' (' .. House.Adress .. ')')
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

FW.Functions.CreateCallback("fw-housing:Server:Decor:GetBalance", function(Source, Cb)
    local Player = FW.Functions.GetPlayer(Source)
    Cb(Player and exports['fw-financials']:GetAccountBalance(Player.PlayerData.charinfo.account) or 0)
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
        for _, Door in ipairs(GetMloDoors(Key)) do
            if #(Coords - Door.Coords) <= 5.0 then Near = true end
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

-- // House creator (admin, client/cl_mlo_creator.lua) \\ --

local function IsAdmin(Source)
    return FW.Functions.HasPermission(Source, 'admin') or FW.Functions.HasPermission(Source, 'god')
end

local function AllDefs()
    local Defs = {}
    for Key, Mlo in pairs(Config.MLOHouses) do Defs[Key] = MloDefToData(Mlo) end
    return Defs
end

-- Reloads every house and pushes the definitions + houses to all clients.
local function ReloadAll()
    LoadHouses()
    TriggerClientEvent("fw-housing:Client:Mlo:Reload", -1, AllDefs(), Config.Houses)
end

local function Num(V, Min, Max, Default)
    V = tonumber(V) or Default
    return V and math.max(Min, math.min(Max, V)) or nil
end

local function Vec(T, W)
    if type(T) ~= 'table' or not tonumber(T.x) or not tonumber(T.y) or not tonumber(T.z) then return end
    return { x = tonumber(T.x), y = tonumber(T.y), z = tonumber(T.z), w = W and (tonumber(T.w) or 0.0) or nil }
end

local function CleanDef(D)
    if type(D) ~= 'table' or type(D.Zone) ~= 'table' or type(D.Zone.points) ~= 'table' or #D.Zone.points < 3 then
        return nil, "Draw at least 3 zone points."
    end

    local Def = {
        Label = tostring(D.Label or ''):sub(1, 64),
        Price = math.floor(Num(D.Price, 0, 1e9, 0)), Class = math.floor(Num(D.Class, 0, 10, 0)),
        MaxDecorations = math.floor(Num(D.MaxDecorations, 1, 1000, 150)),
        Stash = { Slots = math.floor(Num(D.Stash and D.Stash.Slots, 1, 200, 40)), Weight = math.floor(Num(D.Stash and D.Stash.Weight, 1, 100000, 1000)) },
        Zone = { minZ = tonumber(D.Zone.minZ), maxZ = tonumber(D.Zone.maxZ), points = {} },
        Spawn = Vec(D.Spawn, true),
    }
    if Def.Label == '' then return nil, "Give the house a name." end
    if not Def.Zone.minZ or not Def.Zone.maxZ or Def.Zone.minZ >= Def.Zone.maxZ then return nil, "Invalid zone height." end

    for I, P in ipairs(D.Zone.points) do
        if I > 64 or not tonumber(P.x) or not tonumber(P.y) then return nil, "Invalid zone point." end
        Def.Zone.points[I] = { x = tonumber(P.x), y = tonumber(P.y) }
    end

    for _, Side in ipairs({ 'FrontDoor', 'BackDoor' }) do
        local Doors = {}
        for I, Door in ipairs(type(D[Side]) == 'table' and type(D[Side].Doors) == 'table' and D[Side].Doors or {}) do
            local Coords = Vec(Door.Coords)
            if I <= 2 and Coords and tonumber(Door.Model) then Doors[#Doors + 1] = { Model = tonumber(Door.Model), Coords = Coords } end
        end
        if #Doors > 0 then Def[Side] = { Doors = Doors } end
    end
    if not Def.FrontDoor then return nil, "Add the front door." end

    if type(D.Surfaces) == 'table' and type(D.Surfaces.Txd) == 'string' and D.Surfaces.Txd ~= '' then
        Def.Surfaces = { Txd = D.Surfaces.Txd:sub(1, 64) }
        for _, Surface in ipairs({ 'Walls', 'Floor', 'Ceiling' }) do
            Def.Surfaces[Surface] = {}
            for I, Tex in ipairs(type(D.Surfaces[Surface]) == 'table' and D.Surfaces[Surface] or {}) do
                if I <= 10 and type(Tex) == 'string' and Tex ~= '' then table.insert(Def.Surfaces[Surface], Tex:sub(1, 64)) end
            end
        end
    end
    return Def
end

local function NewKey(Label)
    local Base = Label:lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', ''):sub(1, 40)
    if Base == '' then Base = 'house' end
    local Key, N = Base, 1
    while Config.MLOHouses[Key] do N = N + 1 Key = Base .. '_' .. N end
    return Key
end

local function DisableDoors(Key)
    if GetResourceState('fw-doors') == 'started' then exports['fw-doors']:DisableDoorsByPrefix('HOUSE_' .. Key .. '_') end
end

FW.Functions.CreateCallback("fw-housing:Server:Mlo:GetDefs", function(Source, Cb)
    Cb(AllDefs())
end)

FW.Functions.CreateCallback("fw-housing:Server:Creator:List", function(Source, Cb)
    if not IsAdmin(Source) then return Cb(false) end
    local List = {}
    for Key, Mlo in pairs(Config.MLOHouses) do
        local HouseId = GetHouseIdByMlo(Key)
        local House = HouseId and Config.Houses[HouseId]
        List[#List + 1] = { Key = Key, Label = Mlo.Label, Price = Mlo.Price, Dynamic = Mlo.Dynamic == true, Owned = House and House.Owned or false, Data = MloDefToData(Mlo) }
    end
    table.sort(List, function(A, B) return A.Label < B.Label end)
    Cb(List)
end)

RegisterNetEvent("fw-housing:Server:Creator:Save", function(Key, Data)
    local Source = source
    if not IsAdmin(Source) then return end
    local Def, Err = CleanDef(Data)
    if not Def then return Notify(Source, Err, "error") end

    if not (Key and Config.MLOHouses[Key]) then Key = NewKey(Def.Label) end
    Def.Dynamic = true
    exports['ghmattimysql']:executeSync("REPLACE INTO `mlo_houses` (`key`, `data`) VALUES (?, ?)", { Key, json.encode(Def) })

    DisableDoors(Key)
    RegisterMloDef(Key, Def)
    SyncMloHouseRow(Key, Config.MLOHouses[Key])
    ReloadAll()
    Notify(Source, ("House '%s' saved (key: %s)."):format(Def.Label, Key), "success")
end)

RegisterNetEvent("fw-housing:Server:Creator:Delete", function(Key)
    local Source = source
    if not IsAdmin(Source) then return end
    local Mlo = Config.MLOHouses[Key]
    if not Mlo then return end
    if not Mlo.Dynamic then return Notify(Source, "This house is in config/sh_mlo.lua, remove it there.", "error") end
    local HouseId = GetHouseIdByMlo(Key)
    if HouseId and Config.Houses[HouseId].Owned then return Notify(Source, "Someone owns this house, use /sellmlo first.", "error") end

    exports['ghmattimysql']:executeSync("DELETE FROM `mlo_houses` WHERE `key` = ?", { Key })
    exports['ghmattimysql']:executeSync("DELETE FROM `player_houses` WHERE `mlo` = ?", { Key })
    DisableDoors(Key)
    RegisterMloDef(Key, nil)
    ReloadAll()
    Notify(Source, ("House '%s' deleted."):format(Mlo.Label), "success")
end)

FW.Commands.Add("housecreator", "Create / edit MLO houses", {}, false, function(Source)
    TriggerClientEvent("fw-housing:Client:Creator:Open", Source)
end, "admin")
