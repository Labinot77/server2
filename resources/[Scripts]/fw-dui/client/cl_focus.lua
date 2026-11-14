-- Focus: the camera locks on a shown screen and the mouse drives a cursor on it.
--   Options.Mouse = true  -> real mouse events go to the page (SendDuiMouse*)
--   Options.Mouse = false -> fw-dui:Client:Cursor / Click events, the resource hit-tests itself
--   Options.X / Y         -> start cursor in percent (default 50 / 50)
--   Options.Sensitivity   -> cursor speed (default Config.CursorSensitivity)

Focused = nil -- { S, Cam, Transition, X, Y, Options, Closeable }

-- HUD + minimap off while focused (pdwatch etc. turn the radar on themselves, so it's forced off every frame).
-- Other HUDs: listen to fw-dui:Client:Focus (true / false) or set Config.OnFocus.
local function SetHud(Focused, F)
    if Focused then F.Radar = not IsRadarHidden() end
    DisplayRadar(not Focused and F.Radar)
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

    -- Easing back into first person plays GTA's switch effect, so cut straight back there.
    local FirstPerson = GetFollowPedCamViewMode() == 4
    RenderScriptCams(false, not FirstPerson, FirstPerson and 0 or F.Transition, true, true)
    DestroyCam(F.Cam, false)

    FreezeEntityPosition(PlayerPedId(), false)
    SetInteractDisabled(false)
    LocalPlayer.state:set('duiFocus', false, false)
    SetHud(false, F)
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
    -- Other resources skip their keys while this is set (fw-core FW.AddKeybind, fw-inventory hotbar).
    LocalPlayer.state:set('duiFocus', true, false)
    SetHud(true, F)

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
