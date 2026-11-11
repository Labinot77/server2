-- Focus: camera locked on an attached screen, the mouse drives a cursor on it.
--[[ Options (all optional):
    X, Y         start cursor in percent (default 50, 50)
    Sensitivity  cursor speed (default 14)
    Mouse        true = forward real mouse events to the page (SendDuiMouse*)
    Fov, Distance, Height, Transition   camera; distance is auto-fitted to the screen when nil
    OnCursor(X, Y)  cursor moved        OnClick(X, Y)  left click
    CanClose()      return false to block ESC / Backspace / right click
    OnClose()       focus ended (by the player, or the prop disappeared)
]]

Focused = nil -- { Id, Opts, X, Y, Cam }

local function Clamp(V) return math.max(0.0, math.min(100.0, V)) end

local function SetInteractDisabled(Disabled)
    if GetResourceState('interact') == 'started' then exports['interact']:Disable(Disabled) end
end

local function StartCamera(D, Opts)
    local Fov = Opts.Fov or 30.0
    local Pos, Target

    if D.Geometry then
        local TL, TR, BL, BR, N = GetScreenCorners(D)
        Target = (TR + BL) / 2
        local Tan = math.tan(math.rad(Fov / 2)) -- Fov is vertical
        local Distance = Opts.Distance or math.max(#(BL - TL) / 2 / Tan, #(TR - TL) / 2 / (Tan * GetAspectRatio(false))) * 1.15
        Pos = Target + N * Distance + vector3(0.0, 0.0, Opts.Height or 0.0)
    else
        -- Legacy modes have no corners: look at the prop from the front.
        Target = GetOffsetFromEntityInWorldCoords(D.Entity, 0.0, 0.0, 0.15)
        Pos = GetOffsetFromEntityInWorldCoords(D.Entity, 0.0, -(Opts.Distance or 0.55), 0.15 + (Opts.Height or 0.15))
    end

    local Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Cam, Pos.x, Pos.y, Pos.z)
    PointCamAtCoord(Cam, Target.x, Target.y, Target.z)
    SetCamFov(Cam, Fov)
    RenderScriptCams(true, true, Opts.Transition or 500, true, true)
    return Cam
end

function StopFocus(ByPlayer)
    if not Focused then return end
    local F = Focused
    Focused = nil

    RenderScriptCams(false, true, F.Opts.Transition or 500, true, true)
    DestroyCam(F.Cam, false)
    FreezeEntityPosition(PlayerPedId(), false)
    SetInteractDisabled(false)
    TriggerEvent('hud:client:ToggleHUD', true)

    if ByPlayer and F.Opts.OnClose then F.Opts.OnClose() end
end

function StartFocus(Id, Opts)
    local D = Duis[Id]
    if Focused or not D or not D.Entity then return false end
    Opts = Opts or {}

    local F = { Id = Id, Opts = Opts, X = Opts.X or 50.0, Y = Opts.Y or 50.0 }
    F.Cam = StartCamera(D, Opts)
    Focused = F

    FreezeEntityPosition(PlayerPedId(), true)
    SetInteractDisabled(true)
    TriggerEvent('hud:client:ToggleHUD', false)

    CreateThread(function()
        local Sensitivity, Last = Opts.Sensitivity or 14.0, nil
        while Focused == F do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk
            HideHudAndRadarThisFrame()

            if not D.Entity or IsEntityDead(PlayerPedId()) then
                StopFocus(true)
                break
            end

            F.X = Clamp(F.X + GetDisabledControlNormal(0, 1) * Sensitivity)
            F.Y = Clamp(F.Y + GetDisabledControlNormal(0, 2) * Sensitivity)

            local Key = ('%.1f:%.1f'):format(F.X, F.Y)
            if Key ~= Last then
                Last = Key
                if Opts.Mouse then MouseMove(Id, F.X, F.Y) end
                if Opts.OnCursor then Opts.OnCursor(F.X, F.Y) end
            end

            if IsDisabledControlJustPressed(0, 24) then
                if Opts.Mouse then SendDuiMouseDown(D.Dui, 'left') end
                if Opts.OnClick then Opts.OnClick(F.X, F.Y) end
            end
            if Opts.Mouse then
                if IsDisabledControlJustReleased(0, 24) then SendDuiMouseUp(D.Dui, 'left') end
                if IsDisabledControlJustPressed(0, 241) then SendDuiMouseWheel(D.Dui, 120, 0) end
                if IsDisabledControlJustPressed(0, 242) then SendDuiMouseWheel(D.Dui, -120, 0) end
            end

            -- ESC / Backspace / right click
            if (IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 25))
                and (not Opts.CanClose or Opts.CanClose()) then
                StopFocus(true)
                break
            end

            Wait(0)
        end
    end)

    return true
end

exports('Focus', StartFocus)
exports('StopFocus', function() StopFocus(false) end)
exports('IsFocused', function() return Focused ~= nil end)
