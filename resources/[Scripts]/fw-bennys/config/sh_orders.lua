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

-- Work-order laptop. Laptops are props placed from the admin panel (fw-admin) inside a business Area above.
-- How the page gets on each model's screen (texture / render target, resolution, camera) is set in fw-dui/config/sh_config.lua.
Config.Laptop = {
    Models = {
        ['custom_laptop_01'] = true,
    },

    CursorSensitivity = 14.0,

    -- The nearest laptop within this many metres shows the live dashboard (members) or the locked screen.
    RenderDistance = 15.0,
}
