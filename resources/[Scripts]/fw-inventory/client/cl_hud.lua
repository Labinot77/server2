-- Hide the status HUD, speedometer, compass, minimap and GTA's own street/area names while the inventory is open.
local HudHidden = false

local function SetFwHud(Visible, VehicleVisible)
    pcall(function()
        exports['fw-hud']:SetHudVisibleState(Visible)
        exports['fw-ui']:SendUIMessage("Hud", "SetVehicleVisibility", { Visible = VehicleVisible })
        exports['fw-ui']:SendUIMessage("Hud", "SetCompassVisibility", { Visible = VehicleVisible })
    end)
end

function HideGameHud()
    if HudHidden then return end
    HudHidden = true
    SetFwHud(false, false)
    DisplayRadar(false)

    Citizen.CreateThread(function()
        local NextResend = 0
        while HudHidden do
            HideHudAndRadarThisFrame() -- native street name, area, minimap frame
            -- fw-hud turns its HUD back on when you finish getting in / start the engine; keep it off.
            if GetGameTimer() > NextResend then
                NextResend = GetGameTimer() + 500
                SetFwHud(false, false)
            end
            Citizen.Wait(0)
        end
    end)
end

function RestoreGameHud()
    if not HudHidden then return end
    HudHidden = false

    -- Same rule fw-hud uses: vehicle HUD + minimap only while in a car with the engine on.
    local Vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local InVehicle = Vehicle ~= 0 and GetIsVehicleEngineRunning(Vehicle)
    local Ok, BlackBars = pcall(function() return exports['fw-hud']:GetPreferenceById('BlackBars.Show') end)

    SetFwHud(true, InVehicle)
    DisplayRadar(InVehicle and not (Ok and BlackBars))
end
