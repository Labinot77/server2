-- Camera locked in front of the ATM screen (the mouse drives the on-screen cursor).

local Camera = { handle = nil }

function Camera.Start(entity, model)
    local s = Config.Models[model].screen
    local cx, cz = (s.left + s.right) / 2, (s.top + s.bottom) / 2
    local target = GetOffsetFromEntityInWorldCoords(entity, cx, s.y, cz)
    local pos = GetOffsetFromEntityInWorldCoords(entity, cx, s.y - Config.Camera.distance, cz + Config.Camera.height)

    Camera.handle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Camera.handle, pos.x, pos.y, pos.z)
    PointCamAtCoord(Camera.handle, target.x, target.y, target.z)
    SetCamFov(Camera.handle, Config.Camera.fov)
    RenderScriptCams(true, true, Config.Camera.transitionTime, true, true)

    FreezeEntityPosition(PlayerPedId(), true)
    TriggerEvent('hud:client:ToggleHUD', false)
end

function Camera.Stop()
    if not Camera.handle then return end
    RenderScriptCams(false, true, Config.Camera.transitionTime, true, true)
    DestroyCam(Camera.handle, false)
    Camera.handle = nil

    FreezeEntityPosition(PlayerPedId(), false)
    TriggerEvent('hud:client:ToggleHUD', true)
end

ATM_Camera = Camera
