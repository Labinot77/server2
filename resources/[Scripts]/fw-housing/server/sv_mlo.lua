-- MLO houses: database sync, decoration validation and admin helpers.
-- FW, Config.Houses, LoadHouses, SaveHouse, HasKeyToHouse come from _sv_main.lua

-- // Database sync \\ --

local function EnsureMloColumn()
    local Result = exports['ghmattimysql']:executeSync("SHOW COLUMNS FROM `player_houses` LIKE 'mlo'")
    if Result and Result[1] then return end

    exports['ghmattimysql']:executeSync("ALTER TABLE `player_houses` ADD COLUMN `mlo` VARCHAR(64) NULL DEFAULT NULL")
    print("^2[fw-housing]^7 Added `mlo` column to `player_houses`.")
end

local function GetEntrance(Mlo)
    if Mlo.Entrance then return Mlo.Entrance end
    if Mlo.Doors and Mlo.Doors[1] then
        local C = Mlo.Doors[1].Coords
        return vector4(C.x, C.y, C.z, 0.0)
    end
    return vector4(Mlo.Center.x, Mlo.Center.y, Mlo.Zone.minZ + 1.0, 0.0)
end

-- Called from _sv_main.lua before LoadHouses().
function SyncMloHouses()
    EnsureMloColumn()

    for Key, Mlo in pairs(Config.MLOHouses) do
        local Entrance = GetEntrance(Mlo)
        local Coords = json.encode({ x = Entrance.x, y = Entrance.y, z = Entrance.z, w = Entrance.w })
        local Existing = exports['ghmattimysql']:executeSync("SELECT `id`, `citizenid` FROM `player_houses` WHERE `mlo` = ?", { Key })

        if Existing and Existing[1] then
            if Existing[1].citizenid == nil then
                exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `adress` = ?, `coords` = ?, `class` = ?, `price` = ?, `selling` = 1 WHERE `id` = ?", {
                    Mlo.Label, Coords, Mlo.Class or 0, Mlo.Price or 0, Existing[1].id
                })
            else
                exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `adress` = ?, `coords` = ? WHERE `id` = ?", {
                    Mlo.Label, Coords, Existing[1].id
                })
            end
        else
            exports['ghmattimysql']:executeSync("INSERT INTO `player_houses` (`selling`, `name`, `adress`, `class`, `tier`, `price`, `coords`, `mlo`) VALUES (1, ?, ?, ?, 1, ?, ?, ?)", {
                'mlo-' .. Key, Mlo.Label, Mlo.Class or 0, Mlo.Price or 0, Coords, Key
            })
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

    local House = Config.Houses[HouseId]
    if House == nil then return false end

    local Cid = Player.PlayerData.citizenid
    if House.Owned and House.Owner == Cid then return true, Player end

    if Config.Decorate.KeyholdersCanDecorate and HasKeyToHouse(HouseId, Cid) then
        return true, Player
    end

    return false
end

local function IsValidPlacement(Source, House, Coords)
    local PlyCoords = GetEntityCoords(GetPlayerPed(Source))
    if #(PlyCoords - vector3(Coords.x, Coords.y, Coords.z)) > 15.0 then return false end

    if House.Mlo then
        return IsPointInMloZone(House.Mlo, Coords)
    end

    -- Shell houses spawn at z -100 under the house.
    if Coords.z > -50.0 then return false end
    return #(vector2(Coords.x, Coords.y) - vector2(House.Coords.x, House.Coords.y)) <= Config.Decorate.ShellMaxDistance
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

local function GetMaxDecorations(House)
    if House.Mlo and Config.MLOHouses[House.Mlo] then
        return Config.MLOHouses[House.Mlo].MaxDecorations or 100
    end
    return 100
end

local function CommitDecorations(HouseId)
    SaveHouse(HouseId)
    TriggerClientEvent("fw-housing:Client:SyncHouse", -1, HouseId, Config.Houses[HouseId])
end

-- Gives every decoration a stable Id (older entries have none).
function EnsureDecorIds(Decorations)
    if type(Decorations) ~= 'table' then return {} end
    local NextId, Changed = GetNextDecorId(Decorations), false
    for _, v in ipairs(Decorations) do
        if not tonumber(v.Id) then
            v.Id, NextId, Changed = NextId, NextId + 1, true
        end
    end
    return Decorations, Changed
end

-- // Decoration events \\ --

RegisterNetEvent("fw-housing:Server:Decor:Add")
AddEventHandler("fw-housing:Server:Decor:Add", function(HouseId, Model, Coords, Rot)
    local Source = source
    local Allowed, Player = CanDecorate(Source, HouseId)
    if not Allowed then return TriggerClientEvent('FW:Notify', Source, "You can't decorate this house.", "error") end

    local House = Config.Houses[HouseId]
    local Item = Config.FurnitureByModel[Model]
    Coords, Rot = SanitizeVec(Coords), SanitizeVec(Rot)

    if not Item or not Coords or not Rot then return end
    if not IsValidPlacement(Source, House, Coords) then
        return TriggerClientEvent('FW:Notify', Source, "That's outside of the house.", "error")
    end

    House.Decorations = House.Decorations or {}
    if #House.Decorations >= GetMaxDecorations(House) then
        return TriggerClientEvent('FW:Notify', Source, "This house is full, remove something first.", "error")
    end

    if Config.Decorate.ChargeMoney and (Item.Price or 0) > 0 then
        if not exports['fw-financials']:RemoveMoneyFromAccount("1001", "1", Player.PlayerData.charinfo.account, Item.Price, 'PURCHASE', 'Furniture purchased: ' .. Item.Label .. ' (' .. House.Adress .. ')') then
            return TriggerClientEvent('FW:Notify', Source, "Not enough money in your bank account.", "error")
        end
    end

    House.Decorations[#House.Decorations + 1] = {
        Id = GetNextDecorId(House.Decorations),
        Model = Model,
        Coords = Coords,
        Rot = Rot,
    }

    CommitDecorations(HouseId)
    TriggerClientEvent('FW:Notify', Source, Item.Label .. " placed.", "success")
end)

RegisterNetEvent("fw-housing:Server:Decor:Update")
AddEventHandler("fw-housing:Server:Decor:Update", function(HouseId, DecorId, Coords, Rot)
    local Source = source
    if not CanDecorate(Source, HouseId) then return end

    local House = Config.Houses[HouseId]
    local Index = FindDecor(House.Decorations or {}, DecorId)
    Coords, Rot = SanitizeVec(Coords), SanitizeVec(Rot)
    if not Index or not Coords or not Rot then return end

    if not IsValidPlacement(Source, House, Coords) then
        return TriggerClientEvent('FW:Notify', Source, "That's outside of the house.", "error")
    end

    House.Decorations[Index].Coords = Coords
    House.Decorations[Index].Rot = Rot
    CommitDecorations(HouseId)
end)

RegisterNetEvent("fw-housing:Server:Decor:Remove")
AddEventHandler("fw-housing:Server:Decor:Remove", function(HouseId, DecorId)
    local Source = source
    local Allowed, Player = CanDecorate(Source, HouseId)
    if not Allowed then return end

    local House = Config.Houses[HouseId]
    local Index, Decor = FindDecor(House.Decorations or {}, DecorId)
    if not Index then return end

    table.remove(House.Decorations, Index)
    CommitDecorations(HouseId)

    local Item = Config.FurnitureByModel[Decor.Model]
    local Refund = Item and math.floor((Item.Price or 0) * ((Config.Decorate.RefundPercentage or 0) / 100)) or 0
    if Config.Decorate.ChargeMoney and Refund > 0 then
        exports['fw-financials']:AddMoneyToAccount('1001', "1", Player.PlayerData.charinfo.account, Refund, 'SELL', 'Furniture sold: ' .. Item.Label .. ' (' .. House.Adress .. ')')
        TriggerClientEvent('FW:Notify', Source, ("Removed, refunded $%s."):format(Refund), "success")
    else
        TriggerClientEvent('FW:Notify', Source, "Removed.", "success")
    end
end)

FW.Functions.CreateCallback("fw-housing:Server:Decor:CanDecorate", function(Source, Cb, HouseId)
    Cb(CanDecorate(Source, HouseId) == true)
end)

-- // Admin \\ --

FW.Commands.Add("mlohouse:setowner", "Set the owner of an MLO house (cid 'none' to put it back on sale)", {
    { name = "house", help = "MLO key from sh_mlo.lua (e.g. test)" },
    { name = "cid", help = "Citizen ID or 'none'" },
}, true, function(Source, Args)
    local HouseId = GetHouseIdByMlo(Args[1])
    if not HouseId then return TriggerClientEvent('FW:Notify', Source, "Unknown MLO house.", "error") end

    local House, Cid = Config.Houses[HouseId], tostring(Args[2])
    if Cid:lower() == 'none' then
        House.Owner, House.Owned, House.Selling, House.Keyholders, House.Locked = false, false, true, {}, true
        exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `citizenid` = NULL, `keyholders` = '[]', `selling` = 1 WHERE `id` = ?", { House.DbId })
    else
        House.Owner, House.Owned, House.Selling, House.Keyholders = Cid, true, false, { Cid }
        exports['ghmattimysql']:executeSync("UPDATE `player_houses` SET `citizenid` = ?, `keyholders` = ?, `selling` = 0 WHERE `id` = ?", { Cid, json.encode({ Cid }), House.DbId })
    end

    TriggerClientEvent("fw-housing:Client:SyncHouse", -1, HouseId, House)
    TriggerClientEvent('FW:Notify', Source, ("%s owner set to %s."):format(House.Adress, Cid), "success")
end, "admin")

FW.Commands.Add("mlodoor", "Print the model + coords of the door you are looking at (for sh_mlo.lua)", {}, false, function(Source)
    TriggerClientEvent("fw-housing:Client:Mlo:DoorInfo", Source)
end, "admin")
