-- Focus: the camera locks on a shown screen and the mouse drives a cursor on it.
--   Options.Mouse = true  -> real mouse events go to the page (SendDuiMouse*)
--   Options.Mouse = false -> fw-dui:Client:Cursor / Click events, the resource hit-tests itself
--   Options.X / Y         -> start cursor in percent (default 50 / 50)
--   Options.Sensitivity   -> cursor speed (default Config.CursorSensitivity)

Focused = nil -- { S, Cam, Transition, X, Y, Options, Closeable }

local function Clamp(V) return math.max(0.0, math.min(100.0, V)) end

local function SetInteractDisabled(Disabled)
    if GetResourceState('interact') == 'started' then exports['interact']:Disable(Disabled) end
end

function StopFocus()
    if not Focused then return end
    local F = Focused
    Focused = nil
    MirrorStop(F.S)

    -- Easing back into first person plays GTA's switch effect, so cut straight back there.
    local FirstPerson = GetFollowPedCamViewMode() == 4
    RenderScriptCams(false, not FirstPerson, FirstPerson and 0 or F.Transition, true, true)
    DestroyCam(F.Cam, false)

    FreezeEntityPosition(PlayerPedId(), false)
    SetInteractDisabled(false)
    TriggerEvent('hud:client:ToggleHUD', true)
end

local function Focus(Name, Options)
    local S = Screens[Name]
    if Focused or not S or not S.Entity or not S.Model then return false end
    Options = Options or {}

    local C = S.Model.Camera or Config.Camera
    local Pos = GetOffsetFromEntityInWorldCoords(S.Entity, C.Offset.x, C.Offset.y, C.Offset.z)
    local Target = GetOffsetFromEntityInWorldCoords(S.Entity, C.LookAt.x, C.LookAt.y, C.LookAt.z)

    local Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Cam, Pos.x, Pos.y, Pos.z)
    PointCamAtCoord(Cam, Target.x, Target.y, Target.z)
    SetCamFov(Cam, C.Fov or Config.Camera.Fov)
    local Transition = C.Transition or Config.Camera.Transition
    RenderScriptCams(true, true, Transition, true, true)

    local F = { S = S, Cam = Cam, Transition = Transition, X = Options.X or 50.0, Y = Options.Y or 50.0, Options = Options, Closeable = true }
    Focused = F
    MirrorStart(S)

    FreezeEntityPosition(PlayerPedId(), true)
    SetInteractDisabled(true)
    TriggerEvent('hud:client:ToggleHUD', false)

    CreateThread(function()
        local Sensitivity, Last = Options.Sensitivity or Config.CursorSensitivity, nil
        while Focused == F do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk
            HideHudAndRadarThisFrame()

            local Closed = not S.Entity or not DoesEntityExist(S.Entity) or IsEntityDead(PlayerPedId())
                or (F.Closeable and (IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 25)))
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
                    SendDuiMouseMove(S.Dui, math.floor(F.X / 100 * S.Width), math.floor(F.Y / 100 * S.Height))
                    MirrorPush(S, { 'move', F.X, F.Y })
                else
                    TriggerEvent('fw-dui:Client:Cursor', Name, F.X, F.Y)
                end
            end

            if Options.Mouse then
                if IsDisabledControlJustPressed(0, 24) then SendDuiMouseDown(S.Dui, 'left') MirrorPush(S, { 'down' }) end
                if IsDisabledControlJustReleased(0, 24) then SendDuiMouseUp(S.Dui, 'left') MirrorPush(S, { 'up' }) end
                if IsDisabledControlJustPressed(0, 241) then SendDuiMouseWheel(S.Dui, 120, 0) MirrorPush(S, { 'wheel', 120 }) end
                if IsDisabledControlJustPressed(0, 242) then SendDuiMouseWheel(S.Dui, -120, 0) MirrorPush(S, { 'wheel', -120 }) end
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
