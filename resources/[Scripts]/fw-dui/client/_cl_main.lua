-- Core: create DUI pages and draw each one on a single entity.
--   Corner models: textured quad on that entity only (DrawSpritePoly) -> unlit, no copies.
--   Texture / RenderTarget models: legacy global modes, last attached wins.

local TXD_NAME = 'fw_dui'
local Txd = CreateRuntimeTxd(TXD_NAME)

Duis = {}             -- [Id] = { Id, Dui, Tex, Width, Height, Owner, Entity, Model, Geometry }
local Pool = {}       -- ['WxH'] = { { Dui, Tex } } runtime textures can't be freed, so DUIs are reused
local EntityOwner = {}-- [Entity] = Id drawn on it (newest attach wins)
local GlobalOwner = {}-- [texture / render target] = Id
local ModelsByHash = {}
local NextId, TexCount = 0, 0

for Name, Data in pairs(Config.Models) do
    Data.Name = Name
    ModelsByHash[joaat(Name)] = Data
end

-- Helpers

local function GetModel(Model)
    if type(Model) == 'string' then Model = joaat(Model) end
    return ModelsByHash[Model]
end

local function Cross(A, B)
    return vector3(A.y * B.z - A.z * B.y, A.z * B.x - A.x * B.z, A.x * B.y - A.y * B.x)
end

-- World corners of the screen + the normal pointing out of it (towards the viewer).
function GetScreenCorners(D)
    local G, E = D.Geometry, D.Entity
    local TL = GetOffsetFromEntityInWorldCoords(E, G.TL.x, G.TL.y, G.TL.z)
    local TR = GetOffsetFromEntityInWorldCoords(E, G.TR.x, G.TR.y, G.TR.z)
    local BL = GetOffsetFromEntityInWorldCoords(E, G.BL.x, G.BL.y, G.BL.z)
    local N = Cross(BL - TL, TR - TL)
    N = N / #N
    return TL, TR, BL, TR + BL - TL, N
end

local function GlobalKey(Model)
    return Model.RenderTarget and ('rt:' .. Model.RenderTarget) or ('tx:' .. (Model.Dict or Model.Name) .. ':' .. Model.Texture)
end

-- Create / destroy

function Create(Url, Width, Height)
    Width, Height = Width or Config.DefaultResolution[1], Height or Config.DefaultResolution[2]
    local Key = Width .. 'x' .. Height
    local Entry = Pool[Key] and table.remove(Pool[Key])

    if Entry then
        SetDuiUrl(Entry.Dui, Url)
    else
        local Dui = CreateDui(Url, Width, Height)
        local Deadline = GetGameTimer() + 5000
        while not IsDuiAvailable(Dui) do
            if GetGameTimer() > Deadline then DestroyDui(Dui) return nil end
            Wait(0)
        end
        TexCount = TexCount + 1
        Entry = { Dui = Dui, Tex = ('dui_%d'):format(TexCount) }
        CreateRuntimeTextureFromDuiHandle(Txd, Entry.Tex, GetDuiHandle(Dui))
    end

    Wait(300) -- let the page boot before the first message
    NextId = NextId + 1
    Duis[NextId] = {
        Id = NextId, Dui = Entry.Dui, Tex = Entry.Tex, Key = Key, Width = Width, Height = Height,
        Owner = GetInvokingResource() or GetCurrentResourceName(),
    }
    return NextId
end

function Detach(Id)
    local D = Duis[Id]
    if not D or not D.Entity then return end

    if D.Geometry then
        if EntityOwner[D.Entity] == Id then
            -- Hand the screen back to an older DUI on the same prop (e.g. an idle screen).
            EntityOwner[D.Entity] = nil
            for OtherId, Other in pairs(Duis) do
                if OtherId ~= Id and Other.Entity == D.Entity and Other.Geometry then EntityOwner[D.Entity] = OtherId end
            end
        end
    else
        local Key = GlobalKey(D.Model)
        if GlobalOwner[Key] == Id then
            GlobalOwner[Key] = nil
            if D.Model.RenderTarget then
                ReleaseNamedRendertarget(D.Model.RenderTarget)
            else
                RemoveReplaceTexture(D.Model.Dict or D.Model.Name, D.Model.Texture)
            end
        end
    end

    D.Entity, D.Model, D.Geometry, D.RenderId = nil, nil, nil, nil
end

function Destroy(Id)
    local D = Duis[Id]
    if not D then return end
    if Focused and Focused.Id == Id then StopFocus() end
    Detach(Id)
    SetDuiUrl(D.Dui, 'about:blank')
    Pool[D.Key] = Pool[D.Key] or {}
    table.insert(Pool[D.Key], { Dui = D.Dui, Tex = D.Tex })
    Duis[Id] = nil
end

-- Geometry (optional) overrides the model's corners, used by /duicalib.
function Attach(Id, Entity, Geometry)
    local D = Duis[Id]
    local Model = DoesEntityExist(Entity) and GetModel(GetEntityModel(Entity))
    if not D or not Model then return false end

    Detach(Id)
    D.Entity, D.Model = Entity, Model
    D.Geometry = Geometry or (Model.TL and Model)

    if D.Geometry then
        EntityOwner[Entity] = Id
        return true
    end

    local Key = GlobalKey(Model)
    if GlobalOwner[Key] then Detach(GlobalOwner[Key]) end
    GlobalOwner[Key] = Id

    if Model.RenderTarget then
        if not IsNamedRendertargetRegistered(Model.RenderTarget) then RegisterNamedRendertarget(Model.RenderTarget, false) end
        if not IsNamedRendertargetLinked(GetEntityModel(Entity)) then LinkNamedRendertarget(GetEntityModel(Entity)) end
        D.RenderId = GetNamedRendertargetRenderId(Model.RenderTarget)
    elseif Model.Texture then
        AddReplaceTexture(Model.Dict or Model.Name, Model.Texture, TXD_NAME, D.Tex)
    else
        GlobalOwner[Key], D.Entity, D.Model = nil, nil, nil
        return false
    end
    return true
end

-- Page communication

function Send(Id, Action, Data)
    local D = Duis[Id]
    if D then SendDuiMessage(D.Dui, json.encode({ action = Action, data = Data })) end
end

function SetUrl(Id, Url)
    local D = Duis[Id]
    if D then SetDuiUrl(D.Dui, Url) end
end

-- X / Y in percent of the page (0-100).
function MouseMove(Id, X, Y)
    local D = Duis[Id]
    if D then SendDuiMouseMove(D.Dui, math.floor(X / 100 * D.Width), math.floor(Y / 100 * D.Height)) end
end

function GetResolution(Model)
    local Data = GetModel(Model)
    local Res = Data and Data.Resolution or Config.DefaultResolution
    return Res[1], Res[2]
end

-- 'poly' | 'texture' | 'rendertarget' | nil (unsupported)
function GetScreenMode(Model)
    local Data = GetModel(Model)
    if not Data then return nil end
    return (Data.TL and 'poly') or (Data.RenderTarget and 'rendertarget') or (Data.Texture and 'texture') or nil
end

exports('Create', Create)
exports('Destroy', Destroy)
exports('Attach', Attach)
exports('Detach', Detach)
exports('Send', Send)
exports('SetUrl', SetUrl)
exports('MouseMove', MouseMove)
exports('MouseDown', function(Id, Button) if Duis[Id] then SendDuiMouseDown(Duis[Id].Dui, Button or 'left') end end)
exports('MouseUp', function(Id, Button) if Duis[Id] then SendDuiMouseUp(Duis[Id].Dui, Button or 'left') end end)
exports('MouseWheel', function(Id, Delta) if Duis[Id] then SendDuiMouseWheel(Duis[Id].Dui, Delta, 0) end end)
exports('GetResolution', GetResolution)
exports('GetScreenMode', GetScreenMode)
exports('IsAttached', function(Id) return Duis[Id] ~= nil and Duis[Id].Entity ~= nil end)
function GetEntityDui(Entity) return EntityOwner[Entity] end
exports('GetEntityDui', GetEntityDui)

-- Drawing

local function Tri(A, B, C, Tex, Ua, Va, Ub, Vb, Uc, Vc)
    local L = Config.Brightness
    DrawSpritePoly(A.x, A.y, A.z, B.x, B.y, B.z, C.x, C.y, C.z, L, L, L, 255, TXD_NAME, Tex, Ua, Va, 1.0, Ub, Vb, 1.0, Uc, Vc, 1.0)
end

local function DrawPoly(D, CamCoords)
    if #(CamCoords - GetEntityCoords(D.Entity)) > Config.DrawDistance then return false end
    local TL, TR, BL, BR, N = GetScreenCorners(D)
    local O = N * 0.003 -- just in front of the screen, no z-fighting
    TL, TR, BL, BR = TL + O, TR + O, BL + O, BR + O
    -- both windings, so it shows regardless of face culling
    Tri(TL, TR, BR, D.Tex, 0, 0, 1, 0, 1, 1)
    Tri(TL, BR, BL, D.Tex, 0, 0, 1, 1, 0, 1)
    Tri(TL, BR, TR, D.Tex, 0, 0, 1, 1, 1, 0)
    Tri(TL, BL, BR, D.Tex, 0, 0, 0, 1, 1, 1)
    return true
end

local function DrawTarget(D)
    SetTextRenderId(D.RenderId)
    SetScriptGfxDrawOrder(4)
    SetScriptGfxDrawBehindPausemenu(true)
    DrawSprite(TXD_NAME, D.Tex, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    SetTextRenderId(GetDefaultScriptRendertargetRenderId())
    return true
end

CreateThread(function()
    while true do
        local Drew = false
        local CamCoords = GetFinalRenderedCamCoord()

        for Id, D in pairs(Duis) do
            if D.Entity then
                if not DoesEntityExist(D.Entity) then
                    Detach(Id) -- prop despawned (e.g. fw-props streaming)
                elseif D.Geometry then
                    if EntityOwner[D.Entity] == Id and DrawPoly(D, CamCoords) then Drew = true end
                elseif D.RenderId and DrawTarget(D) then
                    Drew = true
                end
            end
        end

        Wait(Drew and 0 or 250)
    end
end)

-- Cleanup: a stopping resource takes its DUIs with it.

AddEventHandler('onResourceStop', function(Resource)
    local Self = Resource == GetCurrentResourceName()
    for Id, D in pairs(Duis) do
        if Self or D.Owner == Resource then Destroy(Id) end
    end
    if not Self then return end
    for _, List in pairs(Pool) do
        for _, Entry in ipairs(List) do DestroyDui(Entry.Dui) end
    end
end)
