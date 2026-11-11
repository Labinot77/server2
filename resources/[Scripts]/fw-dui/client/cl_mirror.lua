-- Mirror: while you use a screen registered with Mirror = true, nearby players see the same thing.
-- Your cursor, clicks and Send() messages are batched (10x per second) and replayed on their copy of the page.

local Queue, Target, LastFlush = {}, nil, 0

local function Flush(Name)
    if not Target then return end
    if #Queue == 0 then
        if GetGameTimer() - LastFlush < 1000 then return end
        Queue[1] = { 'ping' } -- keeps watchers on your screen while you don't move
    end
    TriggerServerEvent('fw-dui:Server:Mirror', Name, Target, Queue)
    Queue, LastFlush = {}, GetGameTimer()
end

-- Events: { 'msg', Action, Data } | { 'move', X, Y } | { 'down' } | { 'up' } | { 'wheel', Delta }
function MirrorPush(S, Event)
    if not (S.Mirror and Target and Focused and Focused.S == S) then return end
    local Last = Queue[#Queue]
    if Event[1] == 'move' and Last and Last[1] == 'move' then
        Queue[#Queue] = Event -- only the latest cursor position matters
    elseif #Queue < 60 then
        Queue[#Queue + 1] = Event
    end
end

function MirrorStart(S)
    if not S.Mirror then return end
    local Coords = GetEntityCoords(S.Entity)
    Target = { Model = GetEntityModel(S.Entity), Coords = { x = Coords.x, y = Coords.y, z = Coords.z } }
    Queue, LastFlush = { { 'ping' } }, 0

    CreateThread(function()
        while Target and Focused and Focused.S == S do
            Flush(S.Name)
            Wait(100)
        end
    end)
end

function MirrorStop(S)
    if not (S.Mirror and Target) then return end
    Queue[#Queue + 1] = { 'stop' }
    Flush(S.Name)
    Target = nil
end

-- ── Watching someone else ──────────────────────────────────────────────────

local function EndWatch(S)
    local W = S.Watching
    S.Watching = nil
    if W then TriggerEvent('fw-dui:Client:WatchEnded', S.Name, W.Entity) end
end

local function Replay(S, Event)
    local Type = Event[1]
    if Type == 'msg' then
        SendDuiMessage(S.Dui, json.encode({ action = Event[2], data = Event[3] }))
    elseif Type == 'move' then
        SendDuiMouseMove(S.Dui, math.floor(Event[2] / 100 * S.Width), math.floor(Event[3] / 100 * S.Height))
    elseif Type == 'down' then
        SendDuiMouseDown(S.Dui, 'left')
    elseif Type == 'up' then
        SendDuiMouseUp(S.Dui, 'left')
    elseif Type == 'wheel' then
        SendDuiMouseWheel(S.Dui, Event[2], 0)
    elseif Type == 'stop' then
        EndWatch(S)
    end
end

RegisterNetEvent('fw-dui:Client:Mirror', function(Name, T, Events)
    local S = Screens[Name]
    if not S or not S.Mirror or S.Locked then return end -- not while using a screen of that type yourself

    local Coords = vector3(T.Coords.x, T.Coords.y, T.Coords.z)
    local Entity = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, 0.5, T.Model, false, false, false)
    local Model = Entity ~= 0 and S.Models[GetEntityModel(Entity)]
    if not Model then return end

    if S.Entity ~= Entity then
        if Events[#Events][1] == 'stop' then return end
        S.Watching = { Entity = Entity, Until = GetGameTimer() + 3000 }
        if not LoadScreen(S, Model) or S.Locked then return end
        ApplyScreen(S, Entity, Model) -- fires Shown, the resource sends its own page setup first
    end

    S.Watching = { Entity = Entity, Until = GetGameTimer() + 3000 }
    for _, Event in ipairs(Events) do Replay(S, Event) end
end)

-- Watching ends when the user stops, or after 3 seconds without updates (left, crashed, ...).
CreateThread(function()
    while true do
        for _, S in pairs(Screens) do
            if S.Watching and GetGameTimer() > S.Watching.Until then EndWatch(S) end
        end
        Wait(500)
    end
end)
