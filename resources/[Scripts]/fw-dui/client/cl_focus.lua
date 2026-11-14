-- Focus: the camera locks on a shown screen and the mouse drives a cursor on it.
--   Options.Mouse = true  -> real mouse events go to the page (SendDuiMouse*)
--   Options.Mouse = false -> fw-dui:Client:Cursor / Click events, the resource hit-tests itself
--   Options.X / Y         -> start cursor in percent (default 50 / 50)
--   Options.Sensitivity   -> cursor speed (default Config.CursorSensitivity)

Focused = nil -- { S, Cam, Transition, X, Y, Options, Closeable }
local Pending = nil -- fly-in scheduled / running while Show loads the page: { Name, Cam?, Transition? }
local LoadTimes = {} -- [model name] = ms the last Show of that model took

local function CreateScreenCam(Entity, Model)
    local C = Model.Camera or Config.Camera
    local Pos = GetOffsetFromEntityInWorldCoords(Entity, C.Offset.x, C.Offset.y, C.Offset.z)
    local Target = GetOffsetFromEntityInWorldCoords(Entity, C.LookAt.x, C.LookAt.y, C.LookAt.z)
    local Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Cam, Pos.x, Pos.y, Pos.z)
    PointCamAtCoord(Cam, Target.x, Target.y, Target.z)
    SetCamFov(Cam, C.Fov or Config.Camera.Fov)
    return Cam, C.Transition or Config.Camera.Transition
end

local function EaseBack(Cam, Transition)
    local FirstPerson = GetFollowPedCamViewMode() == 4 -- easing into first person plays GTA's switch effect: cut
    RenderScriptCams(false, not FirstPerson, FirstPerson and 0 or Transition, true, true)
    DestroyCam(Cam, false)
end

-- The fly-in is timed to END when the page is loaded: it starts (load time - Transition) ms after the click.
-- Load time = how long this model took last time (Config.LoadEstimate the first time). Example: load 1000ms,
-- Transition 500ms -> 500ms wait, then the fly-in. Focus takes the camera over (started or not); without a Focus
-- within 2s after Show returned (lock refused, preview command, ...) it eases back.
function ScheduleCamera(Name, Entity, Model)
    if Focused then return end
    CancelPendingCamera()
    local P = { Name = Name }
    Pending = P
    local Transition = (Model.Camera or Config.Camera).Transition or Config.Camera.Transition
    SetTimeout(math.max(0, (LoadTimes[Model.Name] or Config.LoadEstimate) - Transition), function()
        if Pending ~= P or not DoesEntityExist(Entity) then return end
        P.Cam, P.Transition = CreateScreenCam(Entity, Model)
        RenderScriptCams(true, true, P.Transition, true, true)
    end)
end

function CameraLoaded(Name, Model, Ms)
    LoadTimes[Model.Name] = Ms
    Trace('shown %s in %d ms', Name, Ms) -- /duitrace
    local P = Pending
    if P and P.Name == Name then SetTimeout(2000, function() if Pending == P then CancelPendingCamera() end end) end
end

function CancelPendingCamera(Name)
    if not Pending or (Name and Pending.Name ~= Name) then return end
    if Pending.Cam then EaseBack(Pending.Cam, Pending.Transition) end
    Pending = nil
end

-- HUD + minimap off while focused. fw-hud keeps the radar on itself (pd watch), so it's blocked there.
-- Other HUDs: listen to fw-dui:Client:Focus (true / false) or set Config.OnFocus.
local function SetHud(Focused)
    if GetResourceState('fw-hud') == 'started' then exports['fw-hud']:SetHudBlocked(Focused and 'all' or false) end
    TriggerEvent('hud:client:ToggleHUD', not Focused)
    TriggerEvent('fw-dui:Client:Focus', Focused)
    if Config.OnFocus then Config.OnFocus(Focused) end
end

local function Clamp(V) return math.max(0.0, math.min(100.0, V)) end

local function SetInteractDisabled(Disabled)
    if GetResourceState('interact') == 'started' then exports['interact']:Disable(Disabled) end
end

-- The ESC that closed the screen is still held when controls come back, and GTA opens the pause menu
-- (Settings) on it. Keep the pause keys blocked until ESC is released, plus a short moment.
local function BlockPauseMenu()
    CreateThread(function()
        local Until = GetGameTimer() + 300
        while GetGameTimer() < Until or IsDisabledControlPressed(0, 200) or IsDisabledControlPressed(0, 322) do
            DisableControlAction(0, 199, true) -- P
            DisableControlAction(0, 200, true) -- ESC
            DisableControlAction(0, 322, true) -- ESC (frontend)
            if IsPauseMenuActive() then SetPauseMenuActive(false) end
            Wait(0)
        end
    end)
end

function StopFocus()
    if not Focused then return end
    BlockPauseMenu()
    local F = Focused
    Focused = nil
    MirrorStop(F.S)
    DesktopCursor(F.S, nil, nil, false)

    EaseBack(F.Cam, F.Transition)

    FreezeEntityPosition(PlayerPedId(), false)
    SetInteractDisabled(false)
    LocalPlayer.state:set('duiFocus', false, false)
    SetHud(false)
end

local function Focus(Name, Options)
    local S = Screens[Name]
    if Focused or not S or not S.Entity or not S.Model then return false end
    Options = Options or {}

    local Cam, Transition
    if Pending and Pending.Name == Name and Pending.Cam then -- already flying in: keep going, no second transition
        Cam, Transition, Pending = Pending.Cam, Pending.Transition, nil
    else
        CancelPendingCamera()
        Cam, Transition = CreateScreenCam(S.Entity, S.Model)
        RenderScriptCams(true, true, Transition, true, true)
    end

    local F = { S = S, Cam = Cam, Transition = Transition, X = Options.X or 50.0, Y = Options.Y or 50.0, Options = Options, Closeable = true }
    Focused = F
    MirrorStart(S)

    FreezeEntityPosition(PlayerPedId(), true)
    SetInteractDisabled(true)
    -- Other resources skip their keys while this is set (fw-core FW.AddKeybind, fw-inventory hotbar).
    LocalPlayer.state:set('duiFocus', true, false)
    SetHud(true)

    CreateThread(function()
        local Sensitivity, Last = Options.Sensitivity or Config.CursorSensitivity, nil
        local V = View(S) -- the pool slot while the screen is in use on a Variant model
        while Focused == F do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk
            HideHudAndRadarThisFrame()
            DisplayRadar(false)

            local Closed = not S.Entity or not DoesEntityExist(S.Entity) or IsEntityDead(PlayerPedId())
                or (F.Closeable and not IsNuiFocused() -- an input dialog (fw-ui) is open: ESC is for that dialog
                    and (IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 25))) -- ESC / right click (Backspace types)
            if Closed then
                StopFocus()
                TriggerEvent('fw-dui:Client:Closed', Name)
                break
            end

            F.X = Clamp(F.X + GetDisabledControlNormal(0, 1) * Sensitivity)
            F.Y = Clamp(F.Y + GetDisabledControlNormal(0, 2) * Sensitivity)

            local Key = ('%.1f:%.1f'):format(F.X, F.Y)
            if Key ~= Last then
                Last = Key
                if Options.Mouse then
                    SendDuiMouseMove(V.Dui, math.floor(F.X / 100 * V.Width), math.floor(F.Y / 100 * V.Height))
                    DesktopCursor(S, F.X, F.Y, true)
                    MirrorPush(S, { 'move', F.X, F.Y })
                else
                    TriggerEvent('fw-dui:Client:Cursor', Name, F.X, F.Y)
                end
            end

            if Options.Mouse then
                if IsDisabledControlJustPressed(0, 24) then SendDuiMouseDown(V.Dui, 'left') MirrorPush(S, { 'down' }) end
                if IsDisabledControlJustReleased(0, 24) then SendDuiMouseUp(V.Dui, 'left') MirrorPush(S, { 'up' }) end
                if IsDisabledControlJustPressed(0, 241) then SendDuiMouseWheel(V.Dui, 120, 0) MirrorPush(S, { 'wheel', 120 }) end
                if IsDisabledControlJustPressed(0, 242) then SendDuiMouseWheel(V.Dui, -120, 0) MirrorPush(S, { 'wheel', -120 }) end
            elseif IsDisabledControlJustPressed(0, 24) then
                TriggerEvent('fw-dui:Client:Click', Name, F.X, F.Y)
            end

            Wait(0)
        end
    end)

    return true
end

exports('Focus', Focus)
exports('StopFocus', StopFocus)
exports('IsFocused', function() return Focused ~= nil end)
-- false blocks ESC / Backspace / right click (e.g. while an ATM transaction runs)
exports('SetCloseable', function(Closeable) if Focused then Focused.Closeable = Closeable end end)
