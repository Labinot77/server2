local FW = exports['fw-core']:GetCoreObject()
local Resource, File = GetCurrentResourceName(), 'data/shells.json'
local Shells = json.decode(LoadResourceFile(Resource, File) or '{}') or {}

local function Save() SaveResourceFile(Resource, File, json.encode(Shells, { indent = true }), -1) end
local function IsAdmin(Src) return FW.Functions.HasPermission(Src, 'admin') or FW.Functions.HasPermission(Src, 'god') end

-- Map props whose collision is removed (or that are hidden) while the shell is loaded.
local function SanitizeRemoved(List)
    local Out = {}
    for _, R in ipairs(type(List) == 'table' and List or {}) do
        if type(R) == 'table' and tonumber(R.Model) and type(R.Coords) == 'table' then
            Out[#Out + 1] = {
                Model = tonumber(R.Model), Name = tostring(R.Name or ''):sub(1, 64), Hide = R.Hide == true,
                Coords = { x = tonumber(R.Coords.x) or 0.0, y = tonumber(R.Coords.y) or 0.0, z = tonumber(R.Coords.z) or 0.0 },
            }
        end
    end
    return Out
end

FW.Functions.CreateCallback('fw-shells:Server:GetAll', function(_, Cb) Cb(Shells) end)

-- Returns the shell id (new shells get one here).
FW.Functions.CreateCallback('fw-shells:Server:Save', function(Src, Cb, Id, Data)
    if not IsAdmin(Src) or type(Data) ~= 'table' or type(Data.Walls) ~= 'table' or #Data.Walls == 0 then return Cb(false) end
    Id = Shells[Id] and Id or ('shell_%d'):format(os.time())
    local Walls = {}
    for _, W in ipairs(Data.Walls) do Walls[#Walls + 1] = SanitizeWall(W) end
    Shells[Id] = {
        Label = tostring(Data.Label or Id):sub(1, 64), Tint = tonumber(Data.Tint) or Config.Tint, FrameTint = tonumber(Data.FrameTint) or Config.FrameTint,
        Walls = Walls, Removed = SanitizeRemoved(Data.Removed),
    }
    Save()
    TriggerClientEvent('fw-shells:Client:Set', -1, Id, Shells[Id])
    Cb(Id)
end)

RegisterNetEvent('fw-shells:Server:Delete', function(Id)
    if not IsAdmin(source) or not Shells[Id] then return end
    Shells[Id] = nil
    Save()
    TriggerClientEvent('fw-shells:Client:Set', -1, Id, nil)
end)

FW.Commands.Add('shellcreator', 'Build shells for MLO houses', {}, false, function(Src)
    TriggerClientEvent('fw-shells:Client:Menu', Src)
end, 'admin')

exports('GetShell', function(Id) return Shells[Id] end)
exports('GetShells', function() return Shells end)
