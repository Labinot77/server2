Config = Config or {}

-- // Door HUD (ox_doorlock style) \\ --
-- Draws an [E] key + LOCKED / UNLOCKED label on the door you're looking at,
-- a small ring marker on other doors nearby, and a centre crosshair.
Config.HUD = {
    Enabled      = true,          -- false = fall back to the old fw-ui ShowInteraction prompts
    -- 'interact' = use the interact resource (exports.interact) for dots + [E] prompt
    -- 'hud'      = built-in ox_doorlock style drawing (no extra resource needed)
    Mode         = 'interact',
    InteractDistance = 2.0,       -- [E] range for doors in interact mode
    GateInteractDistance = 8.0,   -- [E] range for gates in interact mode
    RegisterDistance = 30.0,      -- doors closer than this get registered with interact
    Labels       = { [0] = 'UNLOCKED', [1] = 'LOCKED' },
    Colors       = { [0] = { 255, 255, 255, 255 }, [1] = { 255, 255, 255, 255 } },
    NoAccessAlpha = 160,          -- label opacity when the player has no keys (no [E] key shown)
    KeyColor     = { 255, 255, 255, 255 },
    KeySize      = 0.0125,
    TextSize     = 0.0115,
    TextGap      = 0.0045,
    Tracking     = -3,
    SpaceWidth   = 12,
    RingSize     = 0.0095,
    RingAlpha    = 195,
    CenterSize   = 0.0035,
    RingDistance = 6.0,           -- show ring markers on doors within this range
    ZOffset      = 0.0,           -- raise/lower the marker on the door
    ShowOnGates  = false,         -- gates had no prompt before; set true to draw on them too
}

-- // Door creator (admin panel: Utility > Add Door / Manage Doors) \\ --
Config.Creator = {
    Permissions = { 'admin', 'god' },
    MaxAimDistance = 10.0,
    NearbyRadius   = 15.0,        -- "Doors nearby" list radius
}
