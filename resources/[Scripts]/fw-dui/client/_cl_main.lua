-- fw-dui: named screens (e.g. 'atm', 'bennys_laptop'). A screen is one DUI page shown on the nearest
-- prop of its models while the player is in range, and unloaded when nobody is near.
--
-- Events for the resource that registered the screen (TriggerEvent, client side):
--   fw-dui:Client:Shown  (Name, Entity, PropId)  page is on Entity (PropId = fw-admin placed prop id, or nil)
--   fw-dui:Client:Hidden (Name)                  out of range, page unloaded
--   fw-dui:Client:Cursor (Name, X, Y)            focused without Mouse: cursor moved (percent)
--   fw-dui:Client:Click  (Name, X, Y)            focused without Mouse: left click
--   fw-dui:Client:Closed (Name)                  the player left the focused screen
--   fw-dui:Client:WatchEnded (Name, Entity)      stopped watching another player's screen (Mirror), show your idle page

Screens = {} -- [Name] = screen state
DESKTOP_URL = ('nui://%s/html/desktop/index.html'):format(GetCurrentResourceName())
local Txd = CreateRuntimeTxd('fw_dui')
local TexCount = 0

-- Flat black texture: put over a screen's specular map it removes sun / light reflections (glare).
do
    local Black = CreateRuntimeTexture(Txd, 'no_spec', 4, 4)
    for X = 0, 3 do
        for Y = 0, 3 do SetRuntimeTexturePixel(Black, X, Y, 0, 0, 0, 255) end
    end
    CommitRuntimeTexture(Black)
end

local ModelsByHash = {} -- base model and its Variant both point at the model's config

for Name, Data in pairs(Config.Models) do
    Data.Name = Name
    Data.Resolution = Data.Resolution or { 1280, 720 }
    ModelsByHash[joaat(Name)] = Data
    if Data.Variant then ModelsByHash[joaat(Data.Variant)] = Data end
end

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

function FindNearest(S, Coords)
    local Best, BestModel, BestDist = nil, nil, S.Distance

    local Interior = S.SameInterior and GetInteriorFromEntity(PlayerPedId())
    local function Check(Entity, Model)
        if Interior and GetInteriorFromEntity(Entity) ~= Interior then return end -- e.g. the neighbour's house
        local Dist = #(Coords - GetEntityCoords(Entity))
        if Dist <= BestDist then Best, BestModel, BestDist = Entity, Model, Dist end
    end

    if S.Anchor then
        -- Only the one prop closest to the anchor point (e.g. one monitor of the four on a bank desk)
        local Pick, PickModel, PickDist = nil, nil, 3.0
        for Hash, Model in pairs(S.Models) do
            local Entity = GetClosestObjectOfType(S.Anchor.x, S.Anchor.y, S.Anchor.z, PickDist, Hash, false, false, false)
            local Dist = Entity ~= 0 and #(S.Anchor - GetEntityCoords(Entity))
            if Dist and Dist <= PickDist then Pick, PickModel, PickDist = Entity, Model, Dist end
        end
        if Pick then Check(Pick, PickModel) end
    elseif S.Placed then
        for _, Prop in pairs(GetPlacedProps()) do
            local Model = S.Models[joaat(Prop.Model)]
            if Model and Prop.Entity and DoesEntityExist(Prop.Entity) then Check(Prop.Entity, Model) end
        end
    else
        for Hash, Model in pairs(S.Models) do
            local Entity = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, BestDist, Hash, false, false, false)
            if Entity ~= 0 then Check(Entity, Model) end
        end
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
        TexCount = TexCount + 1
        S.Tex = ('dui_%d'):format(TexCount) -- runtime textures can't be recreated, new name per DUI
        CreateRuntimeTextureFromDuiHandle(Txd, S.Tex, GetDuiHandle(S.Dui))

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

local function Destroy(S)
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
    MirrorKeys = true: watchers get the typed characters (default: * so passwords don't leak)
]]
local function RegisterScreen(Name, Options)
    if Screens[Name] then Destroy(Screens[Name]) end

    local S = {
        Name = Name, Url = Options.Url or (Options.Desktop and DESKTOP_URL), Desktop = Options.Desktop == true, Distance = Options.Distance or 15.0, Placed = Options.Placed == true, Mirror = Options.Mirror == true,
        SameInterior = Options.SameInterior == true, MirrorKeys = Options.MirrorKeys == true,
        Anchor = Options.Anchor and vector3(Options.Anchor.x, Options.Anchor.y, Options.Anchor.z),
        Owner = GetInvokingResource() or GetCurrentResourceName(), Models = {},
    }
    for _, Model in ipairs(Options.Models or {}) do
        local Data = Config.Models[Model]
        if Data then
            S.Models[joaat(Model)] = Data
            if Data.Variant then S.Models[joaat(Data.Variant)] = Data end
        else
            print(('[fw-dui] %s: model %s is not in fw-dui Config.Models'):format(Name, Model))
        end
    end
    Screens[Name] = S
end

-- Locks the screen on Entity (range check stops moving it). Yields until the page is loaded.
-- Returns true + the entity now showing the page (it changes when the prop was swapped to its Variant).
local function Show(Name, Entity)
    local S = Screens[Name]
    local Model = S and DoesEntityExist(Entity) and S.Models[GetEntityModel(Entity)]
    if not Model then return false end

    S.Locked, S.Watching = true, nil
    if not LoadScreen(S, Model) then
        S.Locked = false
        return false
    end
    ApplyScreen(S, Entity, Model)
    return true, S.Entity
end

-- Unlocks the screen; the page stays on the prop and the range check takes over again.
local function Release(Name)
    if Screens[Name] then Screens[Name].Locked = false end
end

-- MirrorData: what players watching you get instead of Data (e.g. balances hidden); false = not mirrored.
function Send(Name, Action, Data, MirrorData)
    local S = Screens[Name]
    if not S or not S.Loaded then return end
    SendDuiMessage(S.Dui, json.encode({ action = Action, data = Data }))
    if MirrorData ~= false then MirrorPush(S, { 'msg', Action, MirrorData == nil and Data or MirrorData }) end
end

-- ── Desktop (computers) ────────────────────────────────────────────────────

-- The desktop draws its own cursor: the page can't see the mouse while it's over an app window (iframe).
function DesktopCursor(S, X, Y, Visible)
    if S.Desktop and S.Loaded then
        SendDuiMessage(S.Dui, json.encode({ action = 'desktop:cursor', data = { x = X, y = Y, visible = Visible } }))
    end
end

-- Apps = { { id, label, icon = 'fas fa-...', color, url, width, height }, ... }, Open = app id to open (optional).
-- Local only: every client sets the apps for the computer it shows.
local function SetApps(Name, Apps, Open)
    Send(Name, 'desktop:setup', { apps = Apps or {}, open = Open }, false)
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
exports('GetVariant', function(Model) return Config.Models[Model] and Config.Models[Model].Variant end)

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
    if Entity == 0 then return print('[fw-dui] none within 5m') end
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
    print('[fw-dui] ---- screens ----')
    for Name, S in pairs(Screens) do
        local M = S.Model
        print(('%s | url=%s | loaded=%s locked=%s watching=%s | entity=%s'):format(
            Name, tostring(S.Url), tostring(S.Loaded), tostring(S.Locked), tostring(S.Watching ~= nil), tostring(S.Entity)))
        if M then
            local Dict = M.Dict or M.Variant or M.Name
            print(('  model=%s variant=%s (streamed=%s) | %s = %s/%s | prop now=%s'):format(
                M.Name, tostring(M.Variant), tostring(M.Variant and IsModelInCdimage(joaat(M.Variant)) or '-'),
                M.RenderTarget and 'rendertarget' or 'texture', M.RenderTarget or Dict, M.Texture or '',
                S.Entity and DoesEntityExist(S.Entity) and (GetEntityModel(S.Entity) == joaat(M.Variant or '') and 'copy' or 'base') or '-'))
        end
    end
end, false)
