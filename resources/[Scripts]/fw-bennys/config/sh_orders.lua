-- Work orders: a customer pays at an "order" Benny's zone (see project/src/client/handler/zone.ts,
-- data.OrderBusiness) and the business' mechanics pick the order up on their laptop.

Config = Config or {}

Config.Orders = {
    -- Businesses that receive orders. The key must match the business name in phone_businesses.
    Businesses = {
        ['Hayes Repairs'] = {
            Label = 'Hayes Repairs',
            -- Laptops are read from the placed_props table (see Config.Laptop.Models). A laptop belongs to
            -- this business when it's placed within Radius of Center.
            Area = { Center = vector3(-1420.0, -450.0, 35.91), Radius = 40.0 },
        },
    },

    -- How long installing one cart item takes (ms), by slot prefix. First match wins.
    InstallTime = {
        { Prefix = 'Repair', Time = 15000, Label = 'Repairing vehicle' },
        { Prefix = 'Color', Time = 10000, Label = 'Spraying' },
        { Prefix = 'TyreSmoke', Time = 6000, Label = 'Installing' },
        { Prefix = 'Mod:11', Time = 14000, Label = 'Tuning' },  -- Engine
        { Prefix = 'Mod:12', Time = 12000, Label = 'Tuning' },  -- Brakes
        { Prefix = 'Mod:13', Time = 12000, Label = 'Tuning' },  -- Transmission
        { Prefix = 'Mod:15', Time = 12000, Label = 'Tuning' },  -- Suspension
        { Prefix = 'Mod:16', Time = 14000, Label = 'Fitting' }, -- Armor
        { Prefix = 'Turbo', Time = 14000, Label = 'Tuning' },
        { Prefix = 'Wheels', Time = 9000, Label = 'Mounting' },
        { Prefix = 'Stance', Time = 9000, Label = 'Adjusting' },
        { Prefix = '', Time = 7500, Label = 'Installing' },
    },

    -- Mechanic must be this close to the vehicle to install (checked server side).
    MaxInstallDistance = 8.0,

    -- Finished/cancelled orders shown on the laptop.
    HistoryCount = 20,
}

-- Laptop DUI. Laptops are read from placed_props; the model decides how the page gets onto the screen:
--   RenderTarget = the prop has a script render target (script_rt_<name>), the page is drawn into it every frame
--   Texture      = the page replaces that texture in the model's txd (AddReplaceTexture)
-- Resolution is the DUI page size; keep it the same aspect ratio as the screen.
Config.Laptop = {
    -- Texture = screen texture to replace, Dict = its texture dictionary (defaults to the model name),
    -- RenderTarget = named render target instead of a texture, Resolution = DUI size.
    Models = {
        ['prop_laptop_jimmy'] = {
            Texture = 'prop_jimmy_screen',
            Resolution = { 1280, 800 },
        },
        ['prop_laptop_lester2'] = {
            RenderTarget = 'tvscreen',          -- script_rt_tvscreen (512x256)
            Resolution = { 1280, 640 },
        },
        ['as_prop_as_laptop_01a'] = {
            Texture = 'prop_moniter_desktop_01',
            Resolution = { 1280, 800 },
        },
    },

    CursorSensitivity = 14.0,

    -- Max distance between the spawned prop and its placed_props coords to be treated as the same laptop.
    MatchDistance = 1.5,

    -- Camera, as offsets from the laptop prop. A model can override this with its own Camera = { ... }.
    Camera = {
        Offset = vector3(0.0, -0.55, 0.30), -- where the camera sits
        LookAt = vector3(0.0, 0.05, 0.13),  -- the middle of the screen
        Fov = 42.0,
        Transition = 600,
    },
}
