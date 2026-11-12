local Camera, CameraActive, CamHeading, CurrentCamStage, IsSwitchingStage = nil, false, nil, 2, false

function CreateClothingCamera(Bool, WithBlur, ForceStage)
    exports['fw-inventory']:SetBusyState(Bool)
    TriggerEvent('fw-assets:Client:Toggle:Items', Bool)

    if Bool then
        -- Changed 
        CameraActive = true

        local CamRot = GetGameplayCamRot(2)
        SetEntityHeading(PlayerPedId(), CamRot[3] + 180.0)

        CamHeading = GetEntityHeading(PlayerPedId()) + 90
        SetFollowPedCamViewMode(0)
        SetPedCanPlayAmbientIdles(PlayerPedId(), true, true)

        CurrentCamStage = ForceStage ~= nil and ForceStage or 2
        Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

        local Coords = GetEntityCoords(PlayerPedId())
        SetCamCoord(Camera, Coords.x, Coords.y, Coords.z)

        local CamSettings = Config.CameraSettings[CurrentCamStage]
        SetCamFov(Camera, CamSettings.Fov)
        SetCameraParams(PlayerPedId(), Camera, 0.0, CamHeading)
        Citizen.Wait(3)
        SetCameraParams(PlayerPedId(), Camera, 0.1)

        RenderScriptCams(true, false, 500, true, true)

        CameraController()
    else
        -- Changed
        CameraActive = false

        RenderScriptCams(false, false, 500, false, false)
        -- DestroyCam(Camera, true)

        SetGameplayCamRelativeHeading(0)
        SetGameplayCamRelativePitch(0, 1)

        -- Reset the camera settings
        if Camera then
            SetCamActive(Camera, false)
            DestroyCam(Camera, true)
            Camera = nil
        end
        
        ClearFocus()
        StopAnimTask(PlayerPedId(), 'mp_sleep', 'bind_pose_180', 3.0)
        SetFocusEntity(PlayerPedId())
    end
end

function SetCameraParams(Ped, Camera, Increasement, Heading)
    CamHeading = (CamHeading + Increasement) % 360
    local _Heading = Heading ~= nil and Heading or CamHeading
    local CamSettings = Config.CameraSettings[CurrentCamStage]
    local Distance = GetClearCamDistance(Ped, _Heading, CamSettings)

    local EntityCos = math.cos(_Heading * math.pi / 180) * Distance
    local EntitySin = math.sin(_Heading * math.pi / 180) * Distance
    AttachCamToEntity(Camera, Ped, EntityCos, EntitySin, CamSettings.AttachZ, false)

    local ScreenSin = math.sin(CamHeading * math.pi / 180) * CamSettings.WidthOffset
    local ScreenCos = math.cos(CamHeading * math.pi / 180) * CamSettings.WidthOffset
    PointCamAtEntity(Camera, Ped, ScreenCos, ScreenSin, CamSettings.AttachZ, false)
end

-- Raycast from the ped to where the camera wants to be, so it stops in front of walls instead of going through.
function GetClearCamDistance(Ped, Heading, CamSettings)
    local Distance = CamSettings.AttachOffset
    local X, Y = math.cos(Heading * math.pi / 180) * Distance, math.sin(Heading * math.pi / 180) * Distance

    local From = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 0.0, CamSettings.AttachZ)
    local To = GetOffsetFromEntityInWorldCoords(Ped, X, Y, CamSettings.AttachZ)
    local Ray = StartExpensiveSynchronousShapeTestLosProbe(From.x, From.y, From.z, To.x, To.y, To.z, 1 | 16, Ped, 4) -- world + objects
    local _, Hit, HitCoords = GetShapeTestResult(Ray)

    if Hit == 1 then
        Distance = math.max(#(HitCoords - From) - Config.CameraWallMargin, Config.CameraMinDistance)
    end
    return Distance
end

function UpdateCameraPosition(Ped, Upwards)
    if not Camera or IsSwitchingStage then return end

    if CurrentCamStage == #Config.CameraSettings and Upwards then
        Upwards = false
    end

    SetCameraStage(Ped, Upwards and math.min(CurrentCamStage + 1, #Config.CameraSettings) or math.max(CurrentCamStage - 1, 1))
end

-- Smoothly move the clothing camera to one of Config.CameraSettings.
function SetCameraStage(Ped, Stage)
    Stage = math.max(1, math.min(tonumber(Stage) or 2, #Config.CameraSettings))
    if not Camera or IsSwitchingStage or Stage == CurrentCamStage then return end
    IsSwitchingStage = true

    CurrentCamStage = Stage
    local CamSettings = Config.CameraSettings[CurrentCamStage]

    local TempCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamFov(TempCam, CamSettings.Fov)
    SetCameraParams(Ped, TempCam, 0.0, PedHeading)
    SetCamActiveWithInterp(TempCam, Camera, 500, true, true)

    if CurrentCamStage == 1 then
        exports['fw-assets']:RequestAnimationDict("mp_sleep")
        TaskPlayAnim(Ped, 'mp_sleep', 'bind_pose_180', 8.0, -8.0, -1, 49, 0, false, false, false)
    else
        ClearPedTasks(Ped)
    end

    SetTimeout(500, function()
        IsSwitchingStage = false
        DestroyCam(Camera, false)
        Camera = TempCam
    end)
end

function CameraController()
    local IsMouseInField, LastHeading = false, nil
    Citizen.CreateThread(function()
        while CameraActive and Camera and DoesCamExist(Camera) do
            -- The camera hangs off the ped, so turning the ped swings it around: check for walls again.
            local Heading = GetEntityHeading(PlayerPedId())
            if Heading ~= LastHeading and not IsSwitchingStage then
                LastHeading = Heading
                SetCameraParams(PlayerPedId(), Camera, 0.0)
            end

            local CursorX, CursorY = GetNuiCursorPosition()

            -- Disable the controls.
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)

            EnableControlAction(0, 249, true) -- PUSH_TO_TALK

            -- Camera Rotation
            local ScreenX, ScreenY = GetActiveScreenResolution()
            local DragArea = Config.CameraDragArea or { 0.0, 0.72 }
            if CursorX > (ScreenX * DragArea[1]) and CursorX < (ScreenX * DragArea[2]) then
                if IsDisabledControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 25) then
                    IsMouseInField = true
                end

                if IsMouseInField then
                    -- Ped
                    local Direction = GetDisabledControlNormal(0, 220)
                    if IsDisabledControlPressed(0, 24) then
                        SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId()) + (Direction * ScreenX * 0.0125))
                    end

                    -- Camera
                    if IsDisabledControlPressed(0, 25) then
                        SetCameraParams(PlayerPedId(), Camera, Direction * ScreenX * 0.0125)
                    end
                end

                -- Camera Position
                if IsDisabledControlPressed(0, 16) then
                    UpdateCameraPosition(PlayerPedId(), true)
                end

                if IsDisabledControlPressed(0, 17) then
                    UpdateCameraPosition(PlayerPedId(), false)
                end
            elseif IsMouseInField then
                IsMouseInField = false
            end

            Citizen.Wait(0)
        end
    end)
end
