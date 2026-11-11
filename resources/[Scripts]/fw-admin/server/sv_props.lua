-- Placed props (was fw-props): stored in `placed_props`, streamed to clients by client/cl_props.lua.
-- Other resources: AddEventHandler('fw-admin:Server:PropsChanged', ...) fires after a place / delete / reload.
local FW = exports['fw-core']:GetCoreObject()

local Props = {} -- [Id] = { Id, Model, Coords, Rotation, Frozen, Collision, PlacedBy }

local function LoadProps()
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

    Props = {}
    for _, Row in pairs(exports['ghmattimysql']:executeSync("SELECT * FROM `placed_props`", {}) or {}) do
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
end

-- Net events don't like sparse integer keys, so props are sent as a plain list.
local function GetPropList()
    local List = {}
    for _, Prop in pairs(Props) do List[#List + 1] = Prop end
    return List
end

local function SyncAll()
    TriggerClientEvent('fw-admin:Client:Props:Set', -1, GetPropList())
    TriggerEvent('fw-admin:Server:PropsChanged')
end

local function Log(Source, Title, Text, Color)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player then return end
    local C = Player.PlayerData.charinfo
    TriggerEvent('fw-logs:Server:Log', 'props', Title, ('User: [%s] - %s - %s %s\n%s'):format(Source, Player.PlayerData.citizenid, C.firstname, C.lastname, Text), Color)
end

local function DeleteProp(Source, Id)
    local Player = FW.Functions.GetPlayer(Source)
    if not Player or not IsPlayerAdmin(Source) then return end

    Id = tonumber(Id)
    if not Id or not Props[Id] then return Player.Functions.Notify("Prop not found.", "error") end

    exports['ghmattimysql']:executeSync("DELETE FROM `placed_props` WHERE `id` = @Id", { ['@Id'] = Id })
    local Model = Props[Id].Model
    Props[Id] = nil

    TriggerClientEvent('fw-admin:Client:Props:Remove', -1, Id)
    TriggerEvent('fw-admin:Server:PropsChanged')
    Player.Functions.Notify(("Prop #%s removed."):format(Id), "success")
    Log(Source, 'Prop Removed', ("Prop: #%s %s"):format(Id, Model), 'red')
end

CreateThread(function()
    LoadProps()
    SyncAll()
end)

FW.Functions.CreateCallback("fw-admin:Server:Props:Get", function(Source, Cb)
    Cb(GetPropList())
end)

RegisterNetEvent("fw-admin:Server:Props:Place", function(Data)
    local Source = source
    local Player = FW.Functions.GetPlayer(Source)
    if not Player or not IsPlayerAdmin(Source) then return end
    if type(Data) ~= 'table' or type(Data.Model) ~= 'string' or not Data.Coords or not Data.Rotation then return end

    local Coords = vector3(Data.Coords.x + 0.0, Data.Coords.y + 0.0, Data.Coords.z + 0.0)
    local Rotation = vector3(Data.Rotation.x + 0.0, Data.Rotation.y + 0.0, Data.Rotation.z + 0.0)
    if #(GetEntityCoords(GetPlayerPed(Source)) - Coords) > Config.Props.PlaceDistance + 10.0 then return end

    local Frozen, Collision = Data.Frozen ~= false, Data.Collision ~= false
    local Id = exports['ghmattimysql']:executeSync("INSERT INTO `placed_props` (`model`, `coords`, `rotation`, `frozen`, `collision`, `placed_by`) VALUES (@Model, @Coords, @Rotation, @Frozen, @Collision, @PlacedBy)", {
        ['@Model'] = Data.Model,
        ['@Coords'] = json.encode({ x = Coords.x, y = Coords.y, z = Coords.z }),
        ['@Rotation'] = json.encode({ x = Rotation.x, y = Rotation.y, z = Rotation.z }),
        ['@Frozen'] = Frozen and 1 or 0,
        ['@Collision'] = Collision and 1 or 0,
        ['@PlacedBy'] = Player.PlayerData.citizenid,
    })

    Id = Id and (Id.insertId or Id) or nil
    if type(Id) ~= 'number' then return Player.Functions.Notify("Failed to save prop.", "error") end

    Props[Id] = {
        Id = Id, Model = Data.Model, Coords = Coords, Rotation = Rotation,
        Frozen = Frozen, Collision = Collision, PlacedBy = Player.PlayerData.citizenid,
    }

    TriggerClientEvent('fw-admin:Client:Props:Add', -1, Props[Id])
    TriggerEvent('fw-admin:Server:PropsChanged')
    Player.Functions.Notify(("Prop placed (#%s)."):format(Id), "success")
    Log(Source, 'Prop Placed', ("Prop: #%s %s\nCoords: %s"):format(Id, Data.Model, tostring(Coords)), 'green')
end)

RegisterNetEvent("fw-admin:Server:Props:Delete", function(Id)
    DeleteProp(source, Id)
end)

RegisterNetEvent("fw-admin:Server:Props:Reload", function()
    if not IsPlayerAdmin(source) then return end
    LoadProps()
    SyncAll()
    TriggerClientEvent('FW:Notify', source, ("Reloaded %s props."):format(#GetPropList()), 'success')
end)

-- Commands (same as the panel buttons)
FW.Commands.Add("placeprop", "Place a prop that gets saved.", {{ name = "model", help = "Prop model (optional)" }}, false, function(Source, Args)
    TriggerClientEvent("Admin:Props:Place", Source, { model = Args[1] })
end, 'admin')

FW.Commands.Add("deleteprop", "Delete the nearest placed prop, or by id.", {{ name = "id", help = "Prop id (optional)" }}, false, function(Source, Args)
    if Args[1] then return DeleteProp(Source, Args[1]) end
    TriggerClientEvent("Admin:Props:Delete", Source, {})
end, 'admin')
