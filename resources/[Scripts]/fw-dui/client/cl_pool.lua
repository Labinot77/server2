-- Location pools, client side (the server decides, server/sv_pool.lua). Every prop in use near you shows its
-- copy + page: yours (you drive it) or another player's (their page is mirrored onto it). Idle props stay the
-- original model with their normal screen.
--   Slot = one DUI per (model, variant) on this client. The server never gives the same variant to two props
--   within PoolRadius, so a client only ever needs one page per variant.

Pool = {}       -- [Key] = { Key, Type, Variant, Coords (vector3), Owner, Screen }
local Slots = {} -- ['Type#Variant'] = { Type, Variant, Dui, Tex, Width, Height, Loaded, Busy, Key, Entity, Desktop }
local Requests, RequestId = {}, 0
local Me = GetPlayerServerId(PlayerId())

-- ── Trace: every step of claim / apply / swap / release (/duitrace, live in F8 with /duitrace live) ──
local TraceLog, TraceLive = {}, false
function Trace(Fmt, ...)
    local Line = ('[%7.1fs] '):format(GetGameTimer() / 1000) .. Fmt:format(...)
    TraceLog[#TraceLog + 1] = Line
    if #TraceLog > 80 then table.remove(TraceLog, 1) end
    if TraceLive then print('[fw-dui] ' .. Line) end
end

exports('GetTrace', function() return TraceLog end)

local function NameOf(Hash) -- model name of a hash (screen models + their copies), else the hash
    for Name, Data in pairs(Config.Models) do
        if joaat(Name) == Hash then return Name end
        for _, V in ipairs(Data.Variants or {}) do
            if V.Hash == Hash then return V.Model end
        end
    end
    return tostring(Hash)
end

local function Normalise(R)
    if R then R.Coords = vector3(R.Coords.x, R.Coords.y, R.Coords.z) end
    return R
end

local function GetSlot(Type, Variant)
    local Id = Type .. '#' .. Variant
    Slots[Id] = Slots[Id] or { Type = Type, Variant = Variant }
    return Slots[Id]
end

-- The prop of this model (base or any copy) at Coords: map props, fw-admin props and networked props alike.
local function FindProp(Data, C)
    local Best, BestDist = nil, 0.35
    for _, Obj in ipairs(GetGamePool('CObject')) do
        if Config.ModelsByHash[GetEntityModel(Obj)] == Data then
            local Dist = #(GetEntityCoords(Obj) - C)
            if Dist < BestDist then Best, BestDist = Obj, Dist end
        end
    end
    return Best
end

local function LoadModel(Hash)
    if not IsModelInCdimage(Hash) then return false end
    RequestModel(Hash)
    local Deadline = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Deadline do Wait(10) end
    return HasModelLoaded(Hash)
end

-- Makes the prop model ToModel (a copy, or the base back). Returns the entity that stands there now.
local function SwapTo(Entity, Data, ToModel)
    local To, From = joaat(ToModel), GetEntityModel(Entity)
    local C = GetEntityCoords(Entity)
    if From == To then Trace('swap %s: already %s', NameOf(From), ToModel) return Entity end
    if not IsModelInCdimage(To) then
        Trace('swap FAILED %s -> %s: model not in the game files (not streamed / .ytyp archetype missing / name typo)', NameOf(From), ToModel)
        return Entity
    end
    if not LoadModel(To) then Trace('swap FAILED %s -> %s: model did not load in 5s', NameOf(From), ToModel) return Entity end

    local PropId = GetPropId(Entity)
    if PropId then -- fw-admin prop: respawned as the other model in the same frame (local, every client does it)
        local New = exports['fw-admin']:SetPropModel(PropId, ToModel ~= Data.Name and ToModel or nil) or Entity
        Trace('swap %s -> %s (fw-admin prop #%s): %s', NameOf(From), ToModel, PropId, GetEntityModel(New) == To and 'OK' or 'FAILED')
        return New
    end

    if To == joaat(Data.Name) then
        RemoveModelSwap(C.x, C.y, C.z, 0.3, To, From, false)
    else
        CreateModelSwap(C.x, C.y, C.z, 0.3, From, To, false)
    end
    local Deadline = GetGameTimer() + 1000
    while GetGameTimer() < Deadline do
        local New = GetClosestObjectOfType(C.x, C.y, C.z, 0.3, To, false, false, false)
        if New ~= 0 then
            Trace('swap %s -> %s at %.2f, %.2f, %.2f (map prop): OK, entity %d', NameOf(From), ToModel, C.x, C.y, C.z, New)
            return New
        end
        Wait(0)
    end
    Trace('swap FAILED %s -> %s at %.2f, %.2f, %.2f (map prop): no %s there after 1s (CreateModelSwap did nothing)', NameOf(From), ToModel, C.x, C.y, C.z, ToModel)
    return FindProp(Data, C) or Entity
end

local function LoadSlot(Slot, Url, Resolution)
    local W, H = Resolution[1], Resolution[2]
    if Slot.Dui and (Slot.Width ~= W or Slot.Height ~= H) then
        DestroyDui(Slot.Dui)
        Slot.Dui = nil
    end
    if not Slot.Dui then
        Slot.Dui, Slot.Width, Slot.Height = CreateDui(Url, W, H), W, H
        local Deadline = GetGameTimer() + 4000
        while not IsDuiAvailable(Slot.Dui) and GetGameTimer() < Deadline do Wait(0) end
        Slot.Tex = NewDuiTexture(Slot.Dui) -- handle only once the DUI exists, else the texture stays black
        Slot.ReadyAt = GetGameTimer() + 1500 -- cold first load is slower
    elseif Slot.Url ~= Url then
        SetDuiUrl(Slot.Dui, Url)
        Slot.ReadyAt = GetGameTimer() + 500
    end
    Slot.Url = Url
    while GetGameTimer() < (Slot.ReadyAt or 0) do Wait(0) end -- page booted before the first message (no wait when prewarmed)
    Slot.Loaded = true
end

local function SetTexture(Slot, On)
    local Data = Config.Models[Slot.Type]
    local V = Data.Variants[Slot.Variant]
    if On then
        AddReplaceTexture(V.Dict, V.Texture, 'fw_dui', Slot.Tex)
        if Data.Specular then AddReplaceTexture(V.Dict, Data.Specular, 'fw_dui', 'no_spec') end
    else
        RemoveReplaceTexture(V.Dict, V.Texture)
        if Data.Specular then RemoveReplaceTexture(V.Dict, Data.Specular) end
    end
end

-- Puts record R's copy + page on the prop. Hint = the entity the user clicked (owner). Yields.
function PoolApply(R, Hint)
    local Slot, S = GetSlot(R.Type, R.Variant), Screens[R.Screen]
    while Slot.Busy do Wait(0) end
    if Slot.Key == R.Key or not S or not Pool[R.Key] then return Slot end
    if Slot.Key then PoolUnapply(Slot) end

    local Data = Config.Models[R.Type]
    local Entity = (Hint and DoesEntityExist(Hint) and Hint) or FindProp(Data, R.Coords)
    if not Entity then Trace('apply %s: no prop found at the spot yet (retrying)', R.Key) return Slot end -- not streamed in yet
    Trace('apply %s (variant %d, %s): prop %d = %s', R.Key, R.Variant, R.Owner == Me and 'mine' or 'watching ' .. R.Owner, Entity, NameOf(GetEntityModel(Entity)))

    Slot.Busy, Slot.Key, Slot.Desktop = true, R.Key, S.Desktop
    LoadSlot(Slot, S.Url, Data.Resolution)
    Trace('  page %s: %s (DUI %s, %dx%d)', S.Url, Slot.Loaded and 'loaded' or 'NOT loaded', tostring(Slot.Dui), Slot.Width or 0, Slot.Height or 0)
    local V = Data.Variants[R.Variant]
    -- First use after a start: the copy's model + .ytd aren't streamed yet and AddReplaceTexture on an unloaded
    -- dict does nothing (default / black screen until re-entered). Load both before replacing.
    LoadModel(V.Hash)
    RequestStreamedTextureDict(V.Dict, false)
    local Deadline = GetGameTimer() + 2000
    while not HasStreamedTextureDictLoaded(V.Dict) and GetGameTimer() < Deadline do Wait(10) end
    SetTexture(Slot, true) -- page on the copy's texture first, then the swap: the copy shows it from its first frame
    Trace('  texture %s / %s -> fw_dui/%s', V.Dict, V.Texture, tostring(Slot.Tex))
    Slot.Entity = SwapTo(Entity, Data, V.Model)
    SetTexture(Slot, false) SetTexture(Slot, true) -- re-apply now the copy's drawable is in (embedded textures)
    Slot.Busy = false
    if GetEntityModel(Slot.Entity) ~= V.Hash and V.Model ~= R.Type then
        Trace('  !! the prop is still %s, so it shows its own (idle) screen, not this page', NameOf(GetEntityModel(Slot.Entity)))
    end

    if not Pool[R.Key] then PoolUnapply(Slot) return Slot end -- released while loading
    if R.Owner ~= Me then TriggerServerEvent('fw-dui:Server:PoolHistory', R.Key) end -- watcher: everything so far
    return Slot
end

-- Back to the original model, page unloaded. Yields.
function PoolUnapply(Slot)
    while Slot.Busy do Wait(0) end
    if not Slot.Key then return end
    Slot.Busy = true
    Trace('unapply %s (variant %d)', Slot.Key, Slot.Variant)
    local Data = Config.Models[Slot.Type]
    if Slot.Entity and DoesEntityExist(Slot.Entity) then SwapTo(Slot.Entity, Data, Data.Name) end
    SetTexture(Slot, false)
    if Slot.Dui then -- fresh copy of the page right away: clean state, booted by the next use
        SetDuiUrl(Slot.Dui, Slot.Url)
        Slot.ReadyAt = GetGameTimer() + 500
    end
    Slot.Key, Slot.Entity, Slot.Loaded, Slot.Busy = nil, nil, false, false
end

local function SlotOf(Key)
    for _, Slot in pairs(Slots) do
        if Slot.Key == Key then return Slot end
    end
end

-- ── Owner: claim / release (Show / Release in _cl_main.lua) ─────────────────

function PoolClaim(S, Entity, Data)
    RequestId = RequestId + 1
    local Id, P = RequestId, promise.new()
    Requests[Id] = P
    local C = GetEntityCoords(Entity)
    Trace('claim %s for screen %s: prop %d (%s) at %.2f, %.2f, %.2f', Data.Name, S.Name, Entity, NameOf(GetEntityModel(Entity)), C.x, C.y, C.z)
    TriggerServerEvent('fw-dui:Server:PoolClaim', Id, Data.Name, { x = C.x, y = C.y, z = C.z }, S.Name)
    SetTimeout(5000, function()
        if Requests[Id] then Requests[Id] = nil P:resolve({ false, 'timeout' }) end
    end)

    local Result = Citizen.Await(P)
    local R = Normalise(Result[1])
    if not R then Trace('claim REFUSED: %s', tostring(Result[2])) return nil, Result[2] end
    Trace('claim OK: %s -> variant %d (%s)', R.Key, R.Variant, Config.Models[R.Type].Variants[R.Variant].Model)

    Pool[R.Key] = Pool[R.Key] or R
    local Slot = PoolApply(Pool[R.Key], Entity)
    if Slot.Key ~= R.Key or not Slot.Loaded then
        Trace('claim gave up: page not on the prop (slot %s, loaded %s)', tostring(Slot.Key), tostring(Slot.Loaded))
        TriggerServerEvent('fw-dui:Server:PoolRelease', R.Key)
        return nil, 'load'
    end
    return { Key = R.Key, Slot = Slot }
end

function PoolRelease(S)
    local Active = S.Active
    if not Active then return end
    S.Active = nil
    Trace('release %s (screen %s)', Active.Key, S.Name)
    TriggerServerEvent('fw-dui:Server:PoolRelease', Active.Key)
    Pool[Active.Key] = nil
    CreateThread(function() PoolUnapply(Active.Slot) end)
end

RegisterNetEvent('fw-dui:Client:PoolClaimed', function(Id, Record, Reason)
    local P = Requests[Id]
    Requests[Id] = nil
    if P then P:resolve({ Record, Reason }) end
end)

-- ── Everyone: the server's list ────────────────────────────────────────────

local function Removed(Key)
    if Pool[Key] then Trace('server freed %s', Key) end
    Pool[Key] = nil
    for _, S in pairs(Screens) do -- freed by the server while I still used it (walked away, ...)
        if S.Active and S.Active.Key == Key then
            S.Active, S.Entity, S.Model, S.Locked = nil, nil, nil, false
            if Focused and Focused.S == S then
                StopFocus()
                TriggerEvent('fw-dui:Client:Closed', S.Name)
            end
        end
    end
    local Slot = SlotOf(Key)
    if Slot then CreateThread(function() PoolUnapply(Slot) end) end
end

RegisterNetEvent('fw-dui:Client:PoolSet', function(Key, Record)
    if Record then
        if not Pool[Key] then Trace('server: %s in use by %s (variant %d)', Key, Record.Owner, Record.Variant) end
        Pool[Key] = Pool[Key] or Normalise(Record) -- a record never changes after it's made
    else
        Removed(Key)
    end
end)

RegisterNetEvent('fw-dui:Client:PoolSync', function(List)
    for Key, R in pairs(List or {}) do Pool[Key] = Normalise(R) end
end)

CreateThread(function() TriggerServerEvent('fw-dui:Server:PoolSync') end)

-- Per slot the nearest record in range; anything else unloaded.
CreateThread(function()
    while true do
        local C, Want = GetEntityCoords(PlayerPedId()), {}
        for _, R in pairs(Pool) do
            local Dist = #(C - R.Coords)
            if Dist <= Config.PoolRenderDistance and Screens[R.Screen] then
                local Id = R.Type .. '#' .. R.Variant
                if not Want[Id] or Dist < Want[Id].Dist then Want[Id] = { R = R, Dist = Dist } end
            end
        end
        for Id, Slot in pairs(Slots) do
            if Slot.Key and not Slot.Busy and (not Want[Id] or Want[Id].R.Key ~= Slot.Key) then
                CreateThread(function() PoolUnapply(Slot) end)
            end
        end
        for _, W in pairs(Want) do
            local Slot = GetSlot(W.R.Type, W.R.Variant)
            if Slot.Key ~= W.R.Key and not Slot.Busy then CreateThread(function() PoolApply(W.R) end) end
        end
        Wait(500)
    end
end)

-- ── Watching: the user's page messages, cursor and clicks on my copy of their screen ──

local function Replay(Slot, Event)
    local Type = Event[1]
    if Type == 'msg' then
        SendDuiMessage(Slot.Dui, json.encode({ action = Event[2], data = Event[3] }))
    elseif Type == 'move' then
        SendDuiMouseMove(Slot.Dui, math.floor(Event[2] / 100 * Slot.Width), math.floor(Event[3] / 100 * Slot.Height))
        if Slot.Desktop then SendDuiMessage(Slot.Dui, json.encode({ action = 'desktop:cursor', data = { x = Event[2], y = Event[3], visible = true } })) end
    elseif Type == 'down' then
        SendDuiMouseDown(Slot.Dui, 'left')
    elseif Type == 'up' then
        SendDuiMouseUp(Slot.Dui, 'left')
    elseif Type == 'wheel' then
        SendDuiMouseWheel(Slot.Dui, Event[2], 0)
    end
end

RegisterNetEvent('fw-dui:Client:PoolMirror', function(Key, Events)
    local R, Slot = Pool[Key], SlotOf(Key)
    if not R or R.Owner == Me or not Slot or not Slot.Loaded or Slot.Busy then return end -- loading: history follows
    for _, Event in ipairs(Events) do Replay(Slot, Event) end
end)

-- ── Idle page: props nobody uses ───────────────────────────────────────────
-- One shared page per model on the ORIGINAL model's screen texture (Config.Models[x].Idle): every idle prop of that
-- model shows the same thing, so one page is enough however many there are. Props in use are copies, their own
-- texture. Loaded while any prop of the model (idle or in use) is within PoolRenderDistance, so a prop going back
-- to the original model shows the idle page at once instead of its default screen for a second.
--   Desktop screens: an empty desktop. Others: fw-dui:Client:Idle (Name, Model) -> the resource sends its idle
--   content with DUI:SendIdle(Name, Model, Action, Data).
local Idles = {} -- [Type] = { Dui, Tex, Width, Height, Loaded, Busy, Screen, Texture, Dict }

local function ScreenFor(Data) -- the screen that shows this model (first registered one, desktop screens first)
    local Best
    for Name, S in pairs(Screens) do
        if S.Models[joaat(Data.Name)] and (not Best or (S.Desktop and not Best.Desktop)) then Best = S end
    end
    return Best
end

local function IdleOff(Type)
    local I = Idles[Type]
    if not I or not I.Loaded then return end
    RemoveReplaceTexture(I.Dict, I.Texture)
    SetDuiUrl(I.Dui, 'about:blank')
    I.Loaded, I.Screen, I.Url = false, nil, nil
end

local function IdleOn(Data, S)
    local I = Idles[Data.Name] or {}
    Idles[Data.Name] = I
    if I.Busy then return end
    I.Busy = true
    if I.Loaded then IdleOff(Data.Name) end
    LoadSlot(I, S.Url, Data.Resolution)
    I.Screen, I.Texture, I.Dict = S.Name, Data.Idle.Texture, Data.Idle.Dict
    AddReplaceTexture(I.Dict, I.Texture, 'fw_dui', I.Tex)
    Trace('idle page %s on %s / %s (screen %s)', Data.Name, I.Dict, I.Texture, S.Name)
    if S.Desktop then SendDuiMessage(I.Dui, json.encode({ action = 'desktop:setup', data = { apps = {} } })) end
    I.Busy = false
    TriggerEvent('fw-dui:Client:Idle', S.Name, Data.Name)
end

CreateThread(function()
    while true do
        local C, Near = GetEntityCoords(PlayerPedId()), {}
        for _, Obj in ipairs(GetGamePool('CObject')) do
            local Data = Config.ModelsByHash[GetEntityModel(Obj)]
            if Data and Data.Variants and #(GetEntityCoords(Obj) - C) <= Config.PoolRenderDistance then
                Near[Data.Name] = Data
            end
        end
        for Type, Data in pairs(Config.Models) do
            local S = Near[Type] and ScreenFor(Data)
            if Data.Variants then Prewarm(Data, S) end
            local I = Idles[Type]
            if not Data.Idle then -- no idle page
            elseif S and not (I and (I.Busy or (I.Loaded and I.Screen == S.Name and I.Texture == Data.Idle.Texture and I.Dict == Data.Idle.Dict))) then
                CreateThread(function() IdleOn(Data, S) end)
            elseif not S and I and I.Loaded and not I.Busy then
                IdleOff(Type)
            end
        end
        Wait(1000)
    end
end)

-- Prewarm: while a prop of the model is near, its copies' models + .ytds are streamed and every free slot already has
-- the page booted, so Show only waits for the server's answer (~ping). Far away: pages unloaded.
function Prewarm(Data, S)
    for _, V in ipairs(Data.Variants) do
        local Slot = GetSlot(Data.Name, V.Index)
        if S then
            RequestModel(V.Hash)
            RequestStreamedTextureDict(V.Dict, false)
            if not Slot.Key and not Slot.Busy and Slot.Url ~= S.Url then
                CreateThread(function()
                    if Slot.Key or Slot.Busy then return end
                    Slot.Busy = true
                    LoadSlot(Slot, S.Url, Data.Resolution)
                    Slot.Loaded, Slot.Busy = false, false -- booted, not on a prop
                end)
            end
        elseif not Slot.Key and not Slot.Busy and Slot.Url then
            SetDuiUrl(Slot.Dui, 'about:blank')
            Slot.Url = nil
            SetModelAsNoLongerNeeded(V.Hash)
            SetStreamedTextureDictAsNoLongerNeeded(V.Dict)
        end
    end
end

-- Idle content for one model's idle page (e.g. the ATM's idle screen), not mirrored: every client shows the same.
exports('SendIdle', function(Name, Model, Action, Data)
    local I = Idles[Model]
    if I and I.Loaded and I.Screen == Name then SendDuiMessage(I.Dui, json.encode({ action = Action, data = Data })) end
end)

-- /duiidle <model> <texture> [dict]: try another texture / .ytd for a model's idle page live (until fw-dui restarts),
-- then put what works in config/sh_config.lua as Idle = { Texture = ..., Dict = ... }.
RegisterCommand('duiidle', function(_, Args)
    local Data = Config.Models[Args[1] or '']
    if not Data or not Data.Variants or not Args[2] then return print('[fw-dui] usage: /duiidle <model with Variants> <texture> [dict]') end
    Data.Idle = { Texture = Args[2], Dict = Args[3] or Data.Name, Hash = joaat(Data.Name) }
    IdleOff(Data.Name) -- the idle thread loads it again with the new texture
    print(("[fw-dui] %s: Idle = { Texture = '%s', Dict = '%s' } (stand near an idle one)"):format(Data.Name, Data.Idle.Texture, Data.Idle.Dict))
end, false)

-- /duitrace: the last 80 steps. /duitrace live: also print every step in F8 as it happens. /duitrace off.
RegisterCommand('duitrace', function(_, Args)
    if Args[1] == 'live' or Args[1] == 'off' then
        TraceLive = Args[1] == 'live'
        return print('[fw-dui] live trace ' .. (TraceLive and 'ON' or 'OFF'))
    end
    print('[fw-dui] ---- trace (oldest first) ----')
    for _, Line in ipairs(TraceLog) do print(Line) end
end, false)

-- /duiswap [model]: swaps the nearest prop of a screen model (within 3m) to each of its copies for 3 seconds, without the
-- pool, and says if the copy appeared. Shows if the copies are streamed + swappable at all.
RegisterCommand('duiswap', function(_, Args)
    CreateThread(function()
        local C, Entity, Data = GetEntityCoords(PlayerPedId()), nil, nil
        local Best = 3.0
        for _, Obj in ipairs(GetGamePool('CObject')) do
            local D = Config.ModelsByHash[GetEntityModel(Obj)]
            if D and D.Variants and (not Args[1] or D.Name == Args[1]) and #(GetEntityCoords(Obj) - C) < Best then
                Entity, Data, Best = Obj, D, #(GetEntityCoords(Obj) - C)
            end
        end
        if not Entity then return print('[fw-dui] duiswap: no prop of a model with Variants within 3m') end
        local P = GetEntityCoords(Entity)
        print(('[fw-dui] duiswap: prop %d = %s at %.2f, %.2f, %.2f (fw-admin prop: %s)'):format(Entity, NameOf(GetEntityModel(Entity)), P.x, P.y, P.z, tostring(GetPropId(Entity))))
        if GetEntityModel(Entity) ~= joaat(Data.Name) then
            return print('[fw-dui] duiswap: that prop is a copy right now (in use?), stand at an idle one')
        end
        for i, V in ipairs(Data.Variants) do
            print(('[fw-dui]   copy %d %s: in game files=%s valid=%s | texture %s / %s'):format(i, V.Model,
                tostring(IsModelInCdimage(V.Hash)), tostring(IsModelValid(V.Hash)), V.Dict, V.Texture))
            if V.Model ~= Data.Name and IsModelInCdimage(V.Hash) then
                local Swapped = SwapTo(Entity, Data, V.Model)
                local Ok = GetEntityModel(Swapped) == V.Hash
                print(('[fw-dui]     swap -> %s'):format(Ok and 'OK (the copy should be standing there now, 3s)' or 'FAILED (see /duitrace)'))
                Wait(3000)
                Entity = SwapTo(Swapped, Data, Data.Name)
                print(('[fw-dui]     back -> %s'):format(GetEntityModel(Entity) == joaat(Data.Name) and 'OK' or 'FAILED'))
            end
        end
    end)
end, false)

-- ── Cleanup + debug ────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end
    for _, Slot in pairs(Slots) do
        if Slot.Key then
            local Data = Config.Models[Slot.Type]
            if Slot.Entity and DoesEntityExist(Slot.Entity) and not GetPropId(Slot.Entity) then
                local C = GetEntityCoords(Slot.Entity)
                RemoveModelSwap(C.x, C.y, C.z, 0.3, joaat(Data.Name), GetEntityModel(Slot.Entity), false)
            end
            SetTexture(Slot, false)
        end
        if Slot.Dui then DestroyDui(Slot.Dui) end
    end
    for Type, I in pairs(Idles) do
        if I.Loaded then RemoveReplaceTexture(I.Dict, I.Texture) end
        if I.Dui then DestroyDui(I.Dui) end
    end
end)

function PoolDebug()
    print('[fw-dui] ---- models with copies (in game files? = streamed + archetype found) ----')
    for Name, Data in pairs(Config.Models) do
        if Data.Variants then
            local List = {}
            for i, V in ipairs(Data.Variants) do
                List[i] = ('%s=%s'):format(V.Model, IsModelInCdimage(V.Hash) and 'yes' or 'NO')
            end
            print(('%s | %s | copy texture %s'):format(Name, table.concat(List, ', '), Data.Variants[1].Texture))
        end
    end
    print('[fw-dui] ---- idle pages ----')
    for Type, I in pairs(Idles) do
        print(('%s | %s | %s/%s | screen %s'):format(Type, I.Loaded and 'showing' or 'off', tostring(I.Dict), tostring(I.Texture), tostring(I.Screen)))
    end
    print('[fw-dui] ---- pool (in use near the server) ----')
    local C = GetEntityCoords(PlayerPedId())
    for Key, R in pairs(Pool) do
        local Slot = SlotOf(Key)
        print(('%s | variant %d | owner %s%s | screen %s | %.0fm | %s'):format(Key, R.Variant, R.Owner, R.Owner == Me and ' (me)' or '',
            R.Screen, #(C - R.Coords), Slot and (Slot.Loaded and 'showing here' or 'loading') or 'not shown here'))
    end
end
