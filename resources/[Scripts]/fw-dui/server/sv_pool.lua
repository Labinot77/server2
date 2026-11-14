-- Location pools: which copy (variant) of a model a prop in use gets. The server is the only one deciding, every
-- client applies the same list (client/cl_pool.lua), so everyone around a prop sees the same copy + page.
--   A variant is free at a prop when no other prop of that model within Config.PoolRadius uses it: the same two
--   copies work at every location on the map, two props in use at once per location.
--   Freed on Release, disconnect, or when the user walked away from the prop (crash, forgot to release).

local Pool = {}    -- [Key] = { Key, Type, Variant, Coords = { x, y, z }, Owner, Screen }
local History = {} -- [Key] = page messages so far (mirror versions), for players who start watching later
local MAX_HISTORY = 150

local function V3(C) return vector3(C.x + 0.0, C.y + 0.0, C.z + 0.0) end
local function Near(Source, Coords, Max) return #(GetEntityCoords(GetPlayerPed(Source)) - V3(Coords)) <= Max end

local function Set(Key, Record)
    if not Record and Pool[Key] and GetConvar('fw_dui_debug', '0') == '1' then print(('[fw-dui] freed %s'):format(Key)) end
    Pool[Key] = Record
    if not Record then History[Key] = nil end
    TriggerClientEvent('fw-dui:Client:PoolSet', -1, Key, Record)
end

-- Lowest variant no other in-use prop of this model within PoolRadius has.
local function FreeVariant(Data, Coords)
    local Used = {}
    for _, R in pairs(Pool) do
        if R.Type == Data.Name and #(V3(R.Coords) - Coords) <= Config.PoolRadius then Used[R.Variant] = true end
    end
    for i = 1, #Data.Variants do
        if not Used[i] then return i end
    end
end

-- Client asks for a variant for the prop at Coords. Answer: fw-dui:Client:PoolClaimed (Request, Record | false, Reason)
RegisterNetEvent('fw-dui:Server:PoolClaim', function(Request, Type, Coords, Screen)
    local Source = source
    local Data = type(Type) == 'string' and Config.Models[Type]
    local function Answer(Record, Reason) TriggerClientEvent('fw-dui:Client:PoolClaimed', Source, Request, Record, Reason) end

    if not Data or not Data.Variants or type(Coords) ~= 'table' or type(Screen) ~= 'string' then return Answer(false, 'invalid') end
    local C = V3(Coords)
    if not Near(Source, C, 6.0) then return Answer(false, 'too far') end

    local Key = ('%s:%.1f:%.1f:%.1f'):format(Type, C.x, C.y, C.z)
    local Existing = Pool[Key]
    if Existing then
        if Existing.Owner == Source then return Answer(Existing) end
        return Answer(false, 'busy') -- someone else is using this exact prop
    end

    local Variant = FreeVariant(Data, C)
    if not Variant then return Answer(false, 'full') end -- both copies in use at this location

    local Record = { Key = Key, Type = Type, Variant = Variant, Coords = { x = C.x, y = C.y, z = C.z }, Owner = Source, Screen = Screen }
    if GetConvar('fw_dui_debug', '0') == '1' then print(('[fw-dui] %s claimed %s -> variant %d'):format(Source, Key, Variant)) end
    History[Key] = {}
    Set(Key, Record)
    Answer(Record)
end)

RegisterNetEvent('fw-dui:Server:PoolRelease', function(Key)
    local R = Pool[Key]
    if R and R.Owner == source then Set(Key, nil) end
end)

-- The whole list for a client that (re)started.
RegisterNetEvent('fw-dui:Server:PoolSync', function()
    TriggerClientEvent('fw-dui:Client:PoolSync', source, Pool)
end)

AddEventHandler('playerDropped', function()
    local Source = source
    for Key, R in pairs(Pool) do
        if R.Owner == Source then Set(Key, nil) end
    end
end)

-- Walked away (or crashed without a drop yet): free it after 10 seconds away from the prop.
CreateThread(function()
    local Away = {}
    while true do
        Wait(2000)
        for Key, R in pairs(Pool) do
            if GetPlayerPed(R.Owner) == 0 or not Near(R.Owner, R.Coords, Config.PoolLeaveDistance) then
                Away[Key] = (Away[Key] or 0) + 2
                if Away[Key] >= 10 then Set(Key, nil) end
            else
                Away[Key] = nil
            end
        end
        for Key in pairs(Away) do
            if not Pool[Key] then Away[Key] = nil end
        end
    end
end)

-- ── Mirror for pooled screens ──────────────────────────────────────────────
-- The user's page messages, cursor and clicks go to the players around the prop. Page messages are also kept,
-- so a player who walks up later (or whose page just loaded) first gets everything sent so far.

RegisterNetEvent('fw-dui:Server:PoolMirror', function(Key, Events)
    local Source, R = source, Pool[Key]
    if not R or R.Owner ~= Source or type(Events) ~= 'table' or #Events == 0 or #Events > 61 then return end

    local Log = History[Key]
    for _, Event in ipairs(Events) do
        if type(Event) == 'table' and Event[1] == 'msg' then
            Log[#Log + 1] = Event
            if #Log > MAX_HISTORY then table.remove(Log, 2) end -- the first message is the page setup, keep it
        end
    end

    local C = V3(R.Coords)
    for _, Player in ipairs(GetPlayers()) do
        local Id = tonumber(Player)
        if Id ~= Source and #(GetEntityCoords(GetPlayerPed(Id)) - C) <= Config.PoolRenderDistance then
            TriggerClientEvent('fw-dui:Client:PoolMirror', Id, Key, Events)
        end
    end
end)

RegisterNetEvent('fw-dui:Server:PoolHistory', function(Key)
    if Pool[Key] and History[Key] and #History[Key] > 0 then
        TriggerClientEvent('fw-dui:Client:PoolMirror', source, Key, History[Key], true)
    end
end)

exports('GetPool', function() return Pool end)
