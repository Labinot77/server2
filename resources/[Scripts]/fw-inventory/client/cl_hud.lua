-- Hide the whole fw-hud (status, vehicle HUD, minimap) while the inventory is open.
function HideGameHud()
    exports['fw-hud']:SetHudBlocked('all')
end

function RestoreGameHud()
    exports['fw-hud']:SetHudBlocked(false)
end
