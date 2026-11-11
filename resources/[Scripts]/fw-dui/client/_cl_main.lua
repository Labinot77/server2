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
local Txd = CreateRuntimeTxd('fw_dui')
local TexCount = 0

for Name, Data in pairs(Config.Models) do
    Data.Name = Name
    Data.Resolution = Data.Resolution or { 1280, 720 }
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

local function FindNearest(S, Coords)
    local Best, BestModel, BestDist = nil, nil, S.Distance

    local function Check(Entity, Model)
        local Dist = #(Coords - GetEntityCoords(Entity))
        if Dist <= BestDist then Best, BestModel, BestDist = Entity, Model, Dist end
    end

    if S.Placed then
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
        RemoveReplaceTexture(Old.Dict or Old.Name, Old.Texture)
    end
    S.Model, S.RenderId = Model, nil
    if not Model then return end

    if Model.RenderTarget then
        if not IsNamedRendertargetRegistered(Model.RenderTarget) then RegisterNamedRendertarget(Model.RenderTarget, false) end
        if not IsNamedRendertargetLinked(joaat(Model.Name)) then LinkNamedRendertarget(joaat(Model.Name)) end
        S.RenderId = GetNamedRendertargetRenderId(Model.RenderTarget)
    else
        AddReplaceTexture(Model.Dict or Model.Name, Model.Texture, 'fw_dui', S.Tex)
    end
end

-- ── Page ───────────────────────────────────────────────────────────────────

local function Hide(S)
    if S.Loading then return end
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

function ApplyScreen(S, Entity, Model)
    SetTexture(S, Model)
    if S.Entity == Entity then return end
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
]]
local function RegisterScreen(Name, Options)
    if Screens[Name] then Destroy(Screens[Name]) end

    local S = {
        Name = Name, Url = Options.Url, Distance = Options.Distance or 15.0, Placed = Options.Placed == true, Mirror = Options.Mirror == true,
        Owner = GetInvokingResource() or GetCurrentResourceName(), Models = {},
    }
    for _, Model in ipairs(Options.Models or {}) do
        if Config.Models[Model] then
            S.Models[joaat(Model)] = Config.Models[Model]
        else
            print(('[fw-dui] %s: model %s is not in fw-dui Config.Models'):format(Name, Model))
        end
    end
    Screens[Name] = S
end

-- Locks the screen on Entity (range check stops moving it). Yields until the page is loaded.
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
    return true
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

exports('RegisterScreen', RegisterScreen)
exports('Show', Show)
exports('Release', Release)
exports('Send', Send)
exports('GetEntity', function(Name) return Screens[Name] and Screens[Name].Entity end)
exports('GetPropId', GetPropId)

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
