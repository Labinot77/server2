Config = {
    Cell = 0.25,           -- fw-walls grid (smallest kit panel), don't change
    MaxLength = 8.0, MaxHeight = 4.0, WallHeight = 3.0, MaxHoles = 4,
    SpawnDistance = 75.0,  -- shells spawn when you are this close to their centre
    Tint = 0, FrameTint = 13, -- fw-walls palette row (Config.SurfaceColors order in fw-housing): 0 White, 13 Oak

    -- Swatches in the builder: the fw-walls tint palette (same order as Config.SurfaceColors in fw-housing).
    Colors = {
        '#F2F2F2', '#EADDC4', '#CDB891', '#B5B5B5', '#4A4A4A', '#161616', '#9CAF88', '#2F4B37',
        '#9EC5E0', '#1F2E4D', '#B5583B', '#E3B5B0', '#D4A63A', '#8A6239', '#5A3D26', '#5C1F2A',
    },
    CamSpeed = 4.0, -- builder freecam, metres per second (SHIFT = x3)

    -- W / H = hole size in metres (snapped to 0.25). Door props pivot on their hinge; Flip in the menu swaps the side.
    Doors = {
        { Label = 'House door', Model = 'v_ilev_housedoor1', W = 1.0, H = 2.25 },
        { Label = 'White door', Model = 'v_ilev_ra_door2', W = 1.0, H = 2.25 },
        { Label = 'Front door (Trevor)', Model = 'v_ilev_trev_doorfront', W = 1.0, H = 2.25 },
        { Label = 'Apartment door (black)', Model = 'ex_p_mp_door_apart_door_black', W = 1.0, H = 2.25 },
        { Label = 'Janitor door', Model = 'v_ilev_janitor_frontdoor', W = 1.0, H = 2.25 },
    },

    -- Z = height of the bottom of the window above the floor.
    Windows = {
        { Label = 'Small 1 x 1 m', W = 1.0, H = 1.0, Z = 1.0 },
        { Label = 'Wide 2 x 1.25 m', W = 2.0, H = 1.25, Z = 1.0 },
        { Label = 'Tall 1 x 1.75 m', W = 1.0, H = 1.75, Z = 0.5 },
        { Label = 'Large 3 x 1.5 m', W = 3.0, H = 1.5, Z = 0.75 },
    },
}
