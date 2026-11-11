FW = exports['fw-core']:GetCoreObject()

-- [Id] = { Id, Model, Coords = vector3, Rotation = vector3, Frozen, Collision, PlacedBy }
-- Other resources: AddEventHandler('fw-props:Server:PropsChanged', ...) fires after a place / delete / reload.
local Props = {}

-- Database

local function EnsureTable()
    exports['ghmattimysql']:executeSync([[
        CREATE TABLE IF NOT EXISTS `placed_props` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `model` VARCHAR(100) NOT NULL,
            `coords` LONGTEXT NOT NULL,
            `rotation` LONGTEXT NOT NULL,
            `frozen` TINYINT(1) NOT NULL DEFAULT 1,
            `collision` TINYINT(1) NOT NULL DEFAULT 1,
            `placed_by` VARCHAR(50) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
end

local function LoadProps()
    local Result = exports['ghmattimysql']:executeSync("SELECT * FROM `placed_props`", {})
    Props = {}

    for _, Row in pairs(Result or {}) do
        local C, R = json.decode(Row.coords), json.decode(Row.rotation)
        Props[Row.id] = {
            Id = Row.id,
            Model = Row.model,
            Coords = vector3(C.x, C.y, C.z),
            Rotation = vector3(R.x, R.y, R.z),
            Frozen = Row.frozen == 1 or Row.frozen == true,
            Collision = Row.collision == 1 or Row.collision == true,
            PlacedBy = Row.placed_by,
        }
    end

    print(("[fw-props] Loaded %s props from the database."):format(#(Result or {})))
end

-- Net events don't like sparse integer keys, so send props as a plain list
local function GetPropList()
    local List = {}
    for _, Prop in pairs(Props) do List[#List + 1] = Prop end
    return List
end

Citizen.CreateThread(function()
    EnsureTable()
    LoadProps()
    TriggerClientEvent('fw-props:Client:SetProps', -1, GetPropList())
end)

-- Callbacks

FW.Functions.CreateCallback("fw-props:Server:GetProps", function(Source, Cb)
    Cb(GetPropList())
end)

-- Events

RegisterNetEvent("fw-props:Server:PlaceProp", function(Data)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    if not FW.Functions.HasPermission(Source, Config.Permission) then
        return Player.Functions.Notify("You are not allowed to place props.", "error")
    end

    if type(Data) ~= 'table' or type(Data.Model) ~= 'string' or Data.Coords == nil or Data.Rotation == nil then return end

    local Coords = vector3(Data.Coords.x + 0.0, Data.Coords.y + 0.0, Data.Coords.z + 0.0)
    local Rotation = vector3(Data.Rotation.x + 0.0, Data.Rotation.y + 0.0, Data.Rotation.z + 0.0)

    -- Sanity check: player must be near what they place
    if #(GetEntityCoords(GetPlayerPed(Source)) - Coords) > (Config.PlaceDistance + 10.0) then return end

    local Frozen = Data.Frozen ~= false
    local Collision = Data.Collision ~= false

    local Id = exports['ghmattimysql']:executeSync("INSERT INTO `placed_props` (`model`, `coords`, `rotation`, `frozen`, `collision`, `placed_by`) VALUES (@Model, @Coords, @Rotation, @Frozen, @Collision, @PlacedBy)", {
        ['@Model'] = Data.Model,
        ['@Coords'] = json.encode({ x = Coords.x, y = Coords.y, z = Coords.z }),
        ['@Rotation'] = json.encode({ x = Rotation.x, y = Rotation.y, z = Rotation.z }),
        ['@Frozen'] = Frozen and 1 or 0,
        ['@Collision'] = Collision and 1 or 0,
        ['@PlacedBy'] = Player.PlayerData.citizenid,
    })

    Id = Id and (Id.insertId or Id) or nil
    if type(Id) ~= 'number' then
        return Player.Functions.Notify("Failed to save prop.", "error")
    end

    Props[Id] = {
        Id = Id,
        Model = Data.Model,
        Coords = Coords,
        Rotation = Rotation,
        Frozen = Frozen,
        Collision = Collision,
        PlacedBy = Player.PlayerData.citizenid,
    }

    TriggerClientEvent('fw-props:Client:AddProp', -1, Props[Id])
    TriggerEvent('fw-props:Server:PropsChanged')
    Player.Functions.Notify(("Prop placed (#%s)."):format(Id), "success")

    TriggerEvent('fw-logs:Server:Log', 'props', 'Prop Placed', ("User: [%s] - %s - %s %s\nProp: #%s %s\nCoords: %s"):format(Source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Id, Data.Model, tostring(Coords)), 'green')
end)

RegisterNetEvent("fw-props:Server:DeleteProp", function(Id)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil then return end

    if not FW.Functions.HasPermission(Source, Config.Permission) then return end

    Id = tonumber(Id)
    if Id == nil or Props[Id] == nil then
        return Player.Functions.Notify("Prop not found.", "error")
    end

    exports['ghmattimysql']:executeSync("DELETE FROM `placed_props` WHERE `id` = @Id", { ['@Id'] = Id })

    local Model = Props[Id].Model
    Props[Id] = nil

    TriggerClientEvent('fw-props:Client:RemoveProp', -1, Id)
    TriggerEvent('fw-props:Server:PropsChanged')
    Player.Functions.Notify(("Prop #%s removed."):format(Id), "success")

    TriggerEvent('fw-logs:Server:Log', 'props', 'Prop Removed', ("User: [%s] - %s - %s %s\nProp: #%s %s"):format(Source, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, Id, Model), 'red')
end)

-- Commands

FW.Commands.Add("placeprop", "Place a prop that gets saved.", {{ name = "model", help = "Prop model (optional)" }}, false, function(Source, Args)
    TriggerClientEvent("fw-props:Client:StartPlacing", Source, Args[1])
end, Config.Permission)

FW.Commands.Add("deleteprop", "Delete the nearest placed prop, or by id.", {{ name = "id", help = "Prop id (optional)" }}, false, function(Source, Args)
    if Args[1] then
        TriggerEvent("fw-props:Server:DeletePropAs", Source, tonumber(Args[1]))
    else
        TriggerClientEvent("fw-props:Client:DeleteNearest", Source)
    end
end, Config.Permission)

FW.Commands.Add("reloadprops", "Reload all placed props from the database.", {}, false, function(Source)
    LoadProps()
    TriggerClientEvent('fw-props:Client:SetProps', -1, GetPropList())
    TriggerEvent('fw-props:Server:PropsChanged')
end, Config.Permission)

-- Internal: delete from a command (source is the server here)
AddEventHandler("fw-props:Server:DeletePropAs", function(Source, Id)
    local Player = FW.Functions.GetPlayer(Source)
    if Player == nil or Id == nil or Props[Id] == nil then
        if Player then Player.Functions.Notify("Prop not found.", "error") end
        return
    end

    exports['ghmattimysql']:executeSync("DELETE FROM `placed_props` WHERE `id` = @Id", { ['@Id'] = Id })
    Props[Id] = nil
    TriggerClientEvent('fw-props:Client:RemoveProp', -1, Id)
    TriggerEvent('fw-props:Server:PropsChanged')
    Player.Functions.Notify(("Prop #%s removed."):format(Id), "success")
end)
