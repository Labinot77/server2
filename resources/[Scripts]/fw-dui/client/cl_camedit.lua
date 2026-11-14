-- /duicam [model]: adjust the focus camera of the nearest screen prop (within 3m) live, then print its Camera line
-- for config/sh_config.lua (F8). Applied to Config right away, so the next Focus uses it (until fw-dui restarts).
--   W/S A/D Q/E move the camera (forward/back, left/right, down/up, in the prop's local space)
--   Arrows move the point it looks at (left/right, down/up), Scroll = FOV, SHIFT = fine
--   ENTER = print + apply, BACKSPACE = cancel

local Editing = false
local HINTS = {
    { { 'W', 'A', 'S', 'D' }, 'Move' }, { { 'Q', 'E' }, 'Height' }, { { 'LEFT', 'RIGHT', 'UP', 'DOWN' }, 'Look at' },
    { 'SCROLL', 'FOV' }, { 'SHIFT', 'Fine' }, { 'ENTER', 'Save' }, { 'BACKSPACE', 'Cancel' },
}

local function Hints(Show)
    if GetResourceState('fw-ui') ~= 'started' then return end
    if Show then exports['fw-ui']:ShowKeyHints(HINTS) else exports['fw-ui']:HideKeyHints() end
end

local function NearestScreenProp(Name)
    local C, Best, BestData, BestDist = GetEntityCoords(PlayerPedId()), nil, nil, 3.0
    for _, Obj in ipairs(GetGamePool('CObject')) do
        local Data = Config.ModelsByHash[GetEntityModel(Obj)]
        local Dist = Data and (not Name or Data.Name == Name) and #(GetEntityCoords(Obj) - C)
        if Dist and Dist < BestDist then Best, BestData, BestDist = Obj, Data, Dist end
    end
    return Best, BestData
end

local function V(Vec) return ('vector3(%.3f, %.3f, %.3f)'):format(Vec.x, Vec.y, Vec.z) end

local function Edit(Entity, Data)
    local Base = Data.Camera or Config.Camera
    local Offset, LookAt, Fov = Base.Offset, Base.LookAt, Base.Fov or Config.Camera.Fov
    local Transition = Base.Transition or Config.Camera.Transition

    local Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    RenderScriptCams(true, true, Transition, true, true)
    Hints(true)
    Editing = true
    local Saved = false

    while Editing do
        DisableAllControlActions(0)
        local Speed = (IsDisabledControlPressed(0, 21) and 0.05 or 0.3) * GetFrameTime()
        local function Axis(Pos, Neg) return (IsDisabledControlPressed(0, Pos) and Speed or 0.0) - (IsDisabledControlPressed(0, Neg) and Speed or 0.0) end

        Offset = Offset + vector3(Axis(35, 34), Axis(32, 33), Axis(38, 44))   -- D/A, W/S, E/Q
        LookAt = LookAt + vector3(Axis(175, 174), 0.0, Axis(172, 173))        -- arrows
        if IsDisabledControlJustPressed(0, 241) then Fov = math.max(5.0, Fov - (IsDisabledControlPressed(0, 21) and 0.5 or 2.0)) end
        if IsDisabledControlJustPressed(0, 242) then Fov = math.min(90.0, Fov + (IsDisabledControlPressed(0, 21) and 0.5 or 2.0)) end

        local Pos = GetOffsetFromEntityInWorldCoords(Entity, Offset.x, Offset.y, Offset.z)
        local Target = GetOffsetFromEntityInWorldCoords(Entity, LookAt.x, LookAt.y, LookAt.z)
        SetCamCoord(Cam, Pos.x, Pos.y, Pos.z)
        PointCamAtCoord(Cam, Target.x, Target.y, Target.z)
        SetCamFov(Cam, Fov)
        DrawMarker(28, Target.x, Target.y, Target.z, 0, 0, 0, 0, 0, 0, 0.01, 0.01, 0.01, 255, 60, 60, 220, false, false, 2, false, nil, nil, false)

        if IsDisabledControlJustPressed(0, 191) then Saved, Editing = true, false end
        if IsDisabledControlJustPressed(0, 194) or not DoesEntityExist(Entity) then Editing = false end
        Wait(0)
    end

    Hints(false)
    RenderScriptCams(false, true, Transition, true, true)
    DestroyCam(Cam, false)
    if not Saved then return print('[fw-dui] duicam: cancelled') end

    Data.Camera = { Offset = Offset, LookAt = LookAt, Fov = Fov, Transition = Transition }
    print(('[fw-dui] %s:\n        Camera = { Offset = %s, LookAt = %s, Fov = %.1f, Transition = %d },'):format(Data.Name, V(Offset), V(LookAt), Fov, Transition))
    TriggerEvent('chat:addMessage', { args = { 'fw-dui', ('Camera for %s printed in F8 (applied until restart)'):format(Data.Name) } })
end

RegisterCommand('duicam', function(_, Args)
    if Editing or Focused then return end
    local Entity, Data = NearestScreenProp(Args[1])
    if not Entity then return print(('[fw-dui] duicam: no %s within 3m'):format(Args[1] or 'screen prop')) end
    CreateThread(function() Edit(Entity, Data) end)
end, false)
