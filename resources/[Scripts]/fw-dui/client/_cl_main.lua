-- fw-dui: named screens (e.g. 'atm', 'bennys_laptop').
--   Models with Variants (config): a prop shows a page only while someone uses it (Show .. Release). The server
--   gives it a free copy for its location (cl_pool.lua / sv_pool.lua), everyone around sees that copy + page.
--   Models without Variants (old way): one page on the nearest prop of the screen's models while in range.
--
-- Events for the resource that registered the screen (TriggerEvent, client side):
--   fw-dui:Client:Shown  (Name, Entity, PropId)  page is on Entity (PropId = fw-admin placed prop id, or nil).
--                                                 Variant models: only for the user, watchers get the user's page
--   fw-dui:Client:Hidden (Name)                  out of range, page unloaded
--   fw-dui:Client:Cursor (Name, X, Y)            focused without Mouse: cursor moved (percent)
--   fw-dui:Client:Click  (Name, X, Y)            focused without Mouse: left click
--   fw-dui:Client:Closed (Name)                  the player left the focused screen
--   fw-dui:Client:WatchEnded (Name, Entity)      stopped watching another player's screen (Mirror), show your idle page

Screens = {} -- [Name] = screen state
DESKTOP_URL = ('nui://%s/html/desktop/index.html'):format(GetCurrentResourceName())
local Txd = CreateRuntimeTxd('fw_dui')
local TexCount = 0

-- Runtime texture for a DUI (runtime textures can't be recreated, a new name per DUI). Also used by cl_pool.lua.
function NewDuiTexture(Dui)
    TexCount = TexCount + 1
    local Name = ('dui_%d'):format(TexCount)
    CreateRuntimeTextureFromDuiHandle(Txd, Name, GetDuiHandle(Dui))
    return Name
end

-- What a screen draws on: the user's pool slot while they use a Variant model, else the screen's own (old way) page.
function View(S) return S.Active and S.Active.Slot or S end

-- Flat black texture: put over a screen's specular map it removes sun / light reflections (glare).
do
    local Black = CreateRuntimeTexture(Txd, 'no_spec', 4, 4)
    for X = 0, 3 do
        for Y = 0, 3 do SetRuntimeTexturePixel(Black, X, Y, 0, 0, 0, 255) end
    end
    CommitRuntimeTexture(Black)
end

local ModelsByHash = Config.ModelsByHash -- base model and its copies all point at the model's config (sh_config.lua)

local function LoadModel(Name)
    local Hash = joaat(Name)
    if not IsModelInCdimage(Hash) then return false end
    RequestModel(Hash)
    local Deadline = GetGameTimer() + 5000
    while not HasModelLoaded(Hash) and GetGameTimer() < Deadline do Wait(10) end
    return HasModelLoaded(Hash)
end

-- ── fw-admin placed props ──────────────────────────────────────────────────

local function GetPlacedProps()
    if GetResourceState('fw-admin') ~= 'started' then return {} end
    return exports['fw-admin']:GetPlacedProps() or {}
end

function GetPropId(Entity)
    for Id, Prop in pairs(GetPlacedProps()) do
        if Prop.Entity == Entity then return Id end
    end
end

-- Old way only (models without Variants).
function FindNearest(S, Coords)
    if not next(S.Legacy) then return nil end
    local Best, BestModel, BestDist = nil, nil, S.Distance

    local Interior = S.SameInterior and GetInteriorFromEntity(PlayerPedId())
    local function Check(Entity, Model)
        if Interior and GetInteriorFromEntity(Entity) ~= Interior then return end -- e.g. the neighbour's house
        local Pos = GetEntityCoords(Entity)
        for _, Other in pairs(Screens) do -- a prop another screen (e.g. the 2nd copy) already shows
            if Other ~= S and Other.Entity and DoesEntityExist(Other.Entity) and #(GetEntityCoords(Other.Entity) - Pos) < 0.3 then return end
        end
        local Dist = #(Coords - Pos)
        if Dist <= BestDist then Best, BestModel, BestDist = Entity, Model, Dist end
    end

    if S.Anchor then
        -- Only the one prop closest to the anchor point (e.g. one monitor of the four on a bank desk)
        local Pick, PickModel, PickDist = nil, nil, 3.0
        for Hash, Model in pairs(S.Legacy) do
            local Entity = GetClosestObjectOfType(S.Anchor.x, S.Anchor.y, S.Anchor.z, PickDist, Hash, false, false, false)
            local Dist = Entity ~= 0 and #(S.Anchor - GetEntityCoords(Entity))
            if Dist and Dist <= PickDist then Pick, PickModel, PickDist = Entity, Model, Dist end
        end
        if Pick then Check(Pick, PickModel) end
    elseif S.Placed then
        for _, Prop in pairs(GetPlacedProps()) do
            local Model = S.Legacy[joaat(Prop.Model)]
            if Model and Prop.Entity and DoesEntityExist(Prop.Entity) then Check(Prop.Entity, Model) end
        end
    else
        for Hash, Model in pairs(S.Legacy) do
            local Entity = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, BestDist, Hash, false, false, false)
            if Entity ~= 0 then Check(Entity, Model) end
        end
    end

    -- Static copies are script entities, which GetClosestObjectOfType skips: check them directly
    for _, Obj in pairs(S.Proxies or {}) do
        if Obj and DoesEntityExist(Obj) and S.Legacy[GetEntityModel(Obj)] then Check(Obj, S.Legacy[GetEntityModel(Obj)]) end
    end

    return Best, BestModel
end

-- ── Screen texture ─────────────────────────────────────────────────────────

local function SetTexture(S, Model)
    if S.Model == Model then return end

    local Old = S.Model
    if Old and Old.RenderTarget then
        ReleaseNamedRendertarget(Old.RenderTarget)
    elseif Old then
        RemoveReplaceTexture(Old.Dict or Old.Variant or Old.Name, Old.Texture)
    end
    if Old and Old.Specular then RemoveReplaceTexture(Old.Dict or Old.Variant or Old.Name, Old.Specular) end
    S.Model, S.RenderId = Model, nil
    if not Model then return end

    if Model.RenderTarget then
        if not IsNamedRendertargetRegistered(Model.RenderTarget) then RegisterNamedRendertarget(Model.RenderTarget, false) end
        local Hash = joaat(Model.Variant or Model.Name)
        if not IsNamedRendertargetLinked(Hash) then LinkNamedRendertarget(Hash) end
        S.RenderId = GetNamedRendertargetRenderId(Model.RenderTarget)
    else
        AddReplaceTexture(Model.Dict or Model.Variant or Model.Name, Model.Texture, 'fw_dui', S.Tex)
    end
    if Model.Specular then
        AddReplaceTexture(Model.Dict or Model.Variant or Model.Name, Model.Specular, 'fw_dui', 'no_spec')
    end
end

-- ── Variant swap: only the prop showing the page becomes the copy ──────────

local function FindAt(Coords, Name)
    local Entity = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, 0.3, joaat(Name), false, false, false)
    return Entity ~= 0 and Entity or nil
end

-- Swaps Entity to Model's Variant (ToVariant) or back. Returns the entity that is there now.
local function Swap(Entity, Model, ToVariant)
    local To = ToVariant and Model.Variant or Model.Name
    if GetEntityModel(Entity) == joaat(To) then return Entity end
    if not LoadModel(To) then return Entity end -- loaded before the swap, so there's no frame without a prop

    local PropId = GetPropId(Entity)
    if PropId then
        -- fw-admin prop: copy spawned and original deleted in the same frame
        return exports['fw-admin']:SetPropModel(PropId, ToVariant and Model.Variant or nil) or Entity
    end

    -- Map prop (ATMs)
    local C = GetEntityCoords(Entity)
    if ToVariant then
        CreateModelSwap(C.x, C.y, C.z, 0.3, joaat(Model.Name), joaat(Model.Variant), false)
    else
        RemoveModelSwap(C.x, C.y, C.z, 0.3, joaat(Model.Name), joaat(Model.Variant), false)
    end
    local Deadline = GetGameTimer() + 1000
    while GetGameTimer() < Deadline do
        local New = FindAt(C, To)
        if New then return New end
        Wait(0)
    end
    return FindAt(C, ToVariant and Model.Name or Model.Variant) or Entity
end

local function Unswap(S)
    local Old = S.Swapped
    S.Swapped = nil
    if Old and DoesEntityExist(Old.Entity) then Swap(Old.Entity, Old.Model, false) end
end

-- ── Page ───────────────────────────────────────────────────────────────────

local function Hide(S)
    if S.Loading then return end
    Unswap(S)
    SetTexture(S, nil)
    local WasShown = S.Entity ~= nil
    S.Entity = nil
    if S.Loaded then
        SetDuiUrl(S.Dui, 'about:blank')
        S.Loaded = false
    end
    if WasShown then TriggerEvent('fw-dui:Client:Hidden', S.Name) end
end

-- Loads the page at the model's resolution (the DUI is reused while the size stays the same).
function LoadScreen(S, Model)
    while S.Loading do Wait(50) end
    local W, H = Model.Resolution[1], Model.Resolution[2]

    if S.Dui and (S.Width ~= W or S.Height ~= H) then
        Hide(S)
        DestroyDui(S.Dui)
        S.Dui = nil
    end
    if S.Loaded then return true end

    S.Loading = true
    if S.Dui then
        SetDuiUrl(S.Dui, S.Url)
    else
        S.Dui, S.Width, S.Height = CreateDui(S.Url, W, H), W, H
        S.Tex = NewDuiTexture(S.Dui)

        local Deadline = GetGameTimer() + 4000
        while not IsDuiAvailable(S.Dui) and GetGameTimer() < Deadline do Wait(50) end
    end

    Wait(500) -- let the page boot before the first message
    S.Loaded, S.Loading = true, false
    return true
end

-- Page is loaded and on the texture first, then the prop is swapped: the copy shows the page from its first frame.
function ApplyScreen(S, Entity, Model)
    if S.Entity == Entity then return SetTexture(S, Model) end
    if S.Swapped and S.Swapped.Entity ~= Entity then Unswap(S) end
    SetTexture(S, Model)

    if Model.Variant then
        Entity = Swap(Entity, Model, true)
        S.Swapped = { Entity = Entity, Model = Model }
    end
    S.Entity = Entity
    TriggerEvent('fw-dui:Client:Shown', S.Name, Entity, GetPropId(Entity))
end

-- ── Static map props ───────────────────────────────────────────────────────
-- A prop placed in a ymap / MLO without physics is a building, not an object: GetClosestObjectOfType (and interact)
-- can't find it. For Static = { vector4(x, y, z, heading) } an invisible local copy of the screen's model is kept at
-- each point while you're near, so range, camera and interact work. The texture swap is per model, so the real
-- map prop shows the page. Skipped where a real object of the model already stands.
-- SwapFrom = 'map_model': the map prop at each Static point is another model (e.g. the interior's own panel), swap it
-- to the screen's model there (keeps its exact position / rotation), so it gets the DUI texture.
local function Swap(S, P, On)
    if not S.SwapFrom then return end
    local From, To = joaat(S.SwapFrom), next(S.Legacy)
    if On then CreateModelSwap(P.x, P.y, P.z, 1.0, From, To, false) else RemoveModelSwap(P.x, P.y, P.z, 1.0, From, To, false) end
end

local function ClearProxies(S)
    for i, Obj in pairs(S.Proxies or {}) do
        if Obj and DoesEntityExist(Obj) then DeleteEntity(Obj) end
        Swap(S, S.Static[i], false)
    end
    S.Proxies = {}
end

CreateThread(function()
    while true do
        local C = GetEntityCoords(PlayerPedId())
        for _, S in pairs(Screens) do
            local Hash = S.Static and next(S.Legacy)
            for i, P in ipairs(Hash and S.Static or {}) do
                local Near, Obj = #(C - vector3(P.x, P.y, P.z)) < 60.0, S.Proxies[i]
                if Near and Obj == nil then
                    Swap(S, P, true)
                    if GetClosestObjectOfType(P.x, P.y, P.z, 0.3, Hash, false, false, false) ~= 0 then
                        S.Proxies[i] = false -- a real object is there
                    else
                        RequestModel(Hash)
                        local Deadline = GetGameTimer() + 3000
                        while not HasModelLoaded(Hash) and GetGameTimer() < Deadline do Wait(10) end
                        Obj = CreateObject(Hash, P.x, P.y, P.z, false, false, false)
                        SetEntityHeading(Obj, P.w or 0.0)
                        FreezeEntityPosition(Obj, true)
                        SetEntityCollision(Obj, false, false)
                        SetEntityAlpha(Obj, 0, false) -- transparent, not invisible: invisible entities are skipped by some lookups
                        SetModelAsNoLongerNeeded(Hash)
                        S.Proxies[i] = Obj
                    end
                elseif not Near and Obj ~= nil then
                    if Obj then DeleteEntity(Obj) end
                    Swap(S, P, false)
                    S.Proxies[i] = nil
                end
            end
        end
        Wait(2000)
    end
end)

local function Destroy(S)
    PoolRelease(S)
    ClearProxies(S)
    if Focused and Focused.S == S then StopFocus() end
    S.Loading = false
    Hide(S)
    if S.Dui then DestroyDui(S.Dui) end
    Screens[S.Name] = nil
end

-- ── Exports ────────────────────────────────────────────────────────────────

--[[ Options:
    Url      = page, e.g. 'nui://fw-financials/html/atm/index.html'
    Models   = { 'prop_fleeca_atm', ... } (keys of Config.Models)
    Distance = range in metres (default 15)
    Placed   = true: only props placed from the fw-admin panel
    Mirror   = true: players nearby see what the user does on it (cursor, clicks, Send messages)
    SameInterior = true: only props in the interior the player is in (houses next to each other)
    Desktop  = true: the shared computer desktop (html/desktop) as the page, apps set with SetApps
    Anchor   = vector3: only the prop closest to this point (within 3m) is used
    Static   = { vector4(x, y, z, heading), ... }: positions of the model placed as static map props (see above)
    SwapFrom = 'map_model': the props at the Static points are this model, swapped to the screen's model there
    MirrorKeys = true: watchers get the typed characters (default: * so passwords don't leak)

    Distance / Placed / Anchor / Static / SwapFrom / SameInterior only matter for models without Variants (old way).
]]
local function RegisterScreen(Name, Options)
    if Screens[Name] then Destroy(Screens[Name]) end

    local S = {
        Name = Name, Url = Options.Url or (Options.Desktop and DESKTOP_URL), Desktop = Options.Desktop == true, Distance = Options.Distance or 15.0, Placed = Options.Placed == true, Mirror = Options.Mirror == true,
        SameInterior = Options.SameInterior == true, MirrorKeys = Options.MirrorKeys == true,
        Anchor = Options.Anchor and vector3(Options.Anchor.x, Options.Anchor.y, Options.Anchor.z),
        Static = Options.Static, Proxies = {}, SwapFrom = Options.SwapFrom,
        Owner = GetInvokingResource() or GetCurrentResourceName(), Models = {}, Legacy = {},
    }
    for _, Model in ipairs(Options.Models or {}) do
        local Data = Config.Models[Model]
        if Data then
            S.Models[joaat(Model)] = Data
            for _, V in ipairs(Data.Variants or {}) do S.Models[V.Hash] = Data end
            if not Data.Variants then S.Legacy[joaat(Model)] = Data end
        else
            print(('[fw-dui] %s: model %s is not in fw-dui Config.Models'):format(Name, Model))
        end
    end
    Screens[Name] = S
end

-- Starts using the screen on Entity. Yields until the page is loaded.
-- Returns true + the entity now showing the page (it changes when the prop was swapped to a copy),
-- or false + a reason ('busy' = someone uses this prop, 'full' = both copies in use at this location).
local function Show(Name, Entity)
    local S = Screens[Name]
    local Model = S and DoesEntityExist(Entity) and S.Models[GetEntityModel(Entity)]
    if not Model then return false, 'model' end

    if Model.Variants then
        if S.Active and S.Entity == Entity then return true, S.Entity end
        PoolRelease(S)
        S.Locked = true
        local Active, Reason = PoolClaim(S, Entity, Model)
        if not Active or Screens[Name] ~= S then
            S.Locked = false
            return false, Reason
        end
        S.Active, S.Entity, S.Model = Active, Active.Slot.Entity, Model
        MirrorPoolStart(S)
        TriggerEvent('fw-dui:Client:Shown', S.Name, S.Entity, GetPropId(S.Entity))
        return true, S.Entity
    end

    PoolRelease(S)
    S.Locked, S.Watching = true, nil
    if not LoadScreen(S, Model) then
        S.Locked = false
        return false
    end
    ApplyScreen(S, Entity, Model)
    return true, S.Entity
end

-- Done using it. Variant models: the copy goes back to the original prop for everyone, the variant is free again.
-- Old way: the page stays on the prop and the range check takes over again.
local function Release(Name)
    local S = Screens[Name]
    if not S then return end
    if S.Active then
        PoolRelease(S)
        S.Entity, S.Model = nil, nil
        TriggerEvent('fw-dui:Client:Hidden', Name)
    end
    S.Locked = false
end

-- MirrorData: what players watching you get instead of Data (e.g. balances hidden); false = not mirrored.
function Send(Name, Action, Data, MirrorData)
    local S = Screens[Name]
    local V = S and View(S)
    if not V or not V.Loaded then return end
    SendDuiMessage(V.Dui, json.encode({ action = Action, data = Data }))
    if MirrorData ~= false then MirrorPush(S, { 'msg', Action, MirrorData == nil and Data or MirrorData }) end
end

-- ── Desktop (computers) ────────────────────────────────────────────────────

-- The desktop draws its own cursor: the page can't see the mouse while it's over an app window (iframe).
function DesktopCursor(S, X, Y, Visible)
    local V = View(S)
    if S.Desktop and V.Loaded then
        SendDuiMessage(V.Dui, json.encode({ action = 'desktop:cursor', data = { x = X, y = Y, visible = Visible } }))
    end
end

-- Apps = { { id, label, icon = 'fas fa-...', color, url, width, height }, ... }, Open = app id to open (optional).
-- Variant models: mirrored, watchers get the same apps. Old way: local, every client sets the apps for the computer it shows.
local function SetApps(Name, Apps, Open)
    local Mirror = false
    if Screens[Name] and Screens[Name].Active then Mirror = nil end
    Send(Name, 'desktop:setup', { apps = Apps or {}, open = Open }, Mirror)
end

-- Message for one app; it receives { action = Action, data = Data }. MirrorData as in Send.
local function SendApp(Name, AppId, Action, Data, MirrorData)
    local Mirror = MirrorData
    if MirrorData ~= nil and MirrorData ~= false then Mirror = { id = AppId, action = Action, data = MirrorData } end
    Send(Name, 'desktop:app', { id = AppId, action = Action, data = Data }, Mirror)
end

exports('SetApps', SetApps)
exports('SendApp', SendApp)
exports('OpenApp', function(Name, AppId) Send(Name, 'desktop:open', { id = AppId }) end)
exports('CloseApp', function(Name, AppId) Send(Name, 'desktop:close', { id = AppId }) end)

exports('RegisterScreen', RegisterScreen)
exports('Show', Show)
exports('Release', Release)
exports('Send', Send)
exports('GetEntity', function(Name) return Screens[Name] and Screens[Name].Entity end)
exports('GetPropId', GetPropId)
-- Base model name of an entity, also when it is the Variant copy (nil = not a screen model)
exports('GetBaseModel', function(Entity) local Data = ModelsByHash[GetEntityModel(Entity)] return Data and Data.Name end)
-- First copy of a model (nil = none), and all of them
exports('GetVariant', function(Model)
    local V = Config.Models[Model] and Config.Models[Model].Variants
    return V and V[1].Model ~= Model and V[1].Model or nil
end)
exports('GetVariants', function(Model)
    local List = {}
    for _, V in ipairs(Config.Models[Model] and Config.Models[Model].Variants or {}) do
        if V.Model ~= Model then List[#List + 1] = V.Model end
    end
    return List
end)
exports('IsInUse', function(Entity) -- a player uses this prop right now (pool)
    local C = GetEntityCoords(Entity)
    for _, R in pairs(Pool) do
        if #(R.Coords - C) < 0.35 then return true, R.Owner end
    end
    return false
end)
-- Name of the screen showing its page on Entity, if any
exports('GetScreenOf', function(Entity)
    for Name, S in pairs(Screens) do
        if S.Entity == Entity then return Name end
    end
end)

-- ── Threads ────────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        local Coords = GetEntityCoords(PlayerPedId())
        for _, S in pairs(Screens) do
            if not S.Locked and not S.Watching then
                local Entity, Model = FindNearest(S, Coords)
                if not Entity then
                    Hide(S)
                elseif (S.Entity ~= Entity or S.Model ~= Model) and LoadScreen(S, Model) and not S.Locked and not S.Watching and Screens[S.Name] == S then
                    ApplyScreen(S, Entity, Model)
                end
            end
        end
        Wait(1000)
    end
end)

-- Render targets have to be drawn every frame.
CreateThread(function()
    while true do
        local Drew = false
        for _, S in pairs(Screens) do
            if S.RenderId then
                Drew = true
                SetTextRenderId(S.RenderId)
                SetScriptGfxDrawOrder(4)
                SetScriptGfxDrawBehindPausemenu(true)
                DrawSprite('fw_dui', S.Tex, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            end
        end
        Wait(Drew and 0 or 250)
    end
end)

-- A stopping resource takes its screens with it.
AddEventHandler('onResourceStop', function(Resource)
    local Self = Resource == GetCurrentResourceName()
    for _, S in pairs(Screens) do
        if Self or S.Owner == Resource then Destroy(S) end
    end
end)

-- /duiprop <model>: coords of the nearest prop of that model (for Anchor / config coords)
RegisterCommand('duiprop', function(_, Args)
    local C = GetEntityCoords(PlayerPedId())
    local Entity = GetClosestObjectOfType(C.x, C.y, C.z, 5.0, joaat(Args[1] or ''), false, false, false)
    if Entity == 0 then
        -- Probably a static map prop (not an object). Print where you're looking at, as a start for Static = { vector4 }.
        local Cam, Rot = GetGameplayCamCoord(), GetGameplayCamRot(2)
        local X, Z = math.rad(Rot.x), math.rad(Rot.z)
        local Dir = vector3(-math.sin(Z) * math.abs(math.cos(X)), math.cos(Z) * math.abs(math.cos(X)), math.sin(X))
        local _, Hit, Pos, Normal = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(Cam.x, Cam.y, Cam.z, Cam.x + Dir.x * 8.0, Cam.y + Dir.y * 8.0, Cam.z + Dir.z * 8.0, 1, PlayerPedId(), 0))
        print(('[fw-dui] no %s object within 5m: a static map prop (ymap / MLO). Use its ymap position + heading in Static.'):format(Args[1] or '?'))
        if Hit == 1 then
            print(('[fw-dui] you are looking at: vector4(%.2f, %.2f, %.2f, %.1f) (heading from the surface, may need +180)'):format(Pos.x, Pos.y, Pos.z, (GetHeadingFromVector_2d(Normal.x, Normal.y) + 180.0) % 360.0))
        end
        return
    end
    local P = GetEntityCoords(Entity)
    print(('[fw-dui] %s: vector3(%.2f, %.2f, %.2f), heading %.1f'):format(Args[1], P.x, P.y, P.z, GetEntityHeading(Entity)))
end, false)

-- /duitex <screen> <texture> [dict]: try another screen texture / .ytd live, e.g. when the prop still shows its
-- normal screen. Paste what works into config/sh_config.lua (Texture, Dict). Lasts until the resource restarts.
RegisterCommand('duitex', function(_, Args)
    local S = Screens[Args[1] or '']
    local M = S and S.Model
    if not M or not Args[2] then return print('[fw-dui] usage: /duitex <screen> <texture> [dict]  (stand at the prop so the page is on it)') end
    local Old = M.Dict or M.Variant or M.Name
    RemoveReplaceTexture(Old, M.Texture)
    M.Texture, M.Dict = Args[2], Args[3] or M.Dict
    AddReplaceTexture(M.Dict or M.Variant or M.Name, M.Texture, 'fw_dui', S.Tex)
    print(('[fw-dui] %s: Texture = \'%s\', Dict = \'%s\''):format(S.Name, M.Texture, M.Dict or M.Variant or M.Name))
end, false)

-- /duidebug: what every screen is doing (F8). Black screen? Check Loaded, the URL and the texture lines.
RegisterCommand('duidebug', function()
    PoolDebug()
    print('[fw-dui] ---- screens ----')
    for Name, S in pairs(Screens) do
        local M = S.Model
        print(('%s | url=%s | loaded=%s locked=%s watching=%s | entity=%s | in use: %s'):format(
            Name, tostring(S.Url), tostring(View(S).Loaded), tostring(S.Locked), tostring(S.Watching ~= nil), tostring(S.Entity), S.Active and S.Active.Key or 'no'))
        if M then
            local Dict = M.Dict or M.Variant or M.Name
            print(('  model=%s variant=%s (streamed=%s) | %s = %s/%s | prop now=%s'):format(
                M.Name, tostring(M.Variant), tostring(M.Variant and IsModelInCdimage(joaat(M.Variant)) or '-'),
                M.RenderTarget and 'rendertarget' or 'texture', M.RenderTarget or Dict, M.Texture or '',
                S.Entity and DoesEntityExist(S.Entity) and (GetEntityModel(S.Entity) == joaat(M.Variant or '') and 'copy' or 'base') or '-'))
        end
        local C = GetEntityCoords(PlayerPedId())
        for i, P in ipairs(S.Static or {}) do
            local Obj = S.Proxies[i]
            print(('  static %d: vector4(%.2f, %.2f, %.2f, %.1f) | %.1fm away (range %.1f) | %s%s'):format(i, P.x, P.y, P.z, P.w or 0.0,
                #(C - vector3(P.x, P.y, P.z)), S.Distance,
                Obj and DoesEntityExist(Obj) and 'invisible copy' or Obj == false and 'real object there' or 'no copy (over 60m?)',
                S.SwapFrom and (' | swapped from ' .. S.SwapFrom) or ''))
        end
    end
end, false)
