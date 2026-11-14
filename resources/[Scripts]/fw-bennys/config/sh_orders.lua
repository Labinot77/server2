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
        -- Apps = the computer's dock (default { 'Orders', 'Management' }), Shop = fw-businesses vehicle shop id.
        ["Mosley's Dealership"] = {
            Label = "Mosley's Dealership",
            Area = { Center = vector3(-31.25, -1664.87, 29.49), Radius = 40.0 },
            Apps = { 'Dealership', 'Management' },
            Shop = 'mosley',
            -- Monitors that are part of the MLO (not admin placed): rough positions, the computer model within 2.5m is used.
            -- Apps overrides the business' Apps for that computer.
            Computers = {
                vector3(-31.25, -1664.87, 29.49), -- showroom
                { Coords = vector3(-12.0, -1653.91, 30.43), Apps = { 'Orders' } }, -- workshop
            },
            -- Created on start when missing: the business + bank account, and the catalog (model = stock).
            Account = '64829173',
            Catalog = {
                asea = 9, blista = 7, emperor = 5, glendale = 3, ingot = 3, intruder = 5, issi2 = 5, manana = 4,
                picador = 3, premier = 8, primo = 8, sadler = 2, stanier = 9, tornado = 5, washington = 6,
            },
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
        ['prop_laptop_jimmy'] = true,
        ['prop_laptop_lester2'] = true,
        ['as_prop_as_laptop_01a'] = true,
        ['v_res_lest_monitor'] = true, -- Mosley's showroom
        ['prop_monitor_01b'] = true, -- Mosley's workshop
    },

    CursorSensitivity = 14.0,

    -- Apps on the laptop's desktop (fw-dui). %s in a label = the business label.
    Apps = {
        Orders = { id = 'orders', label = 'Work Orders', icon = 'fas fa-car-mechanic', color = 'linear-gradient(160deg, #3fd8e6, #1b9fb0)', page = 'laptop.html' },
        -- Hire, fire, pay, roles, bank access. Only the owner and roles with a management permission can use it.
        Management = { id = 'management', label = '%s Management', icon = 'fas fa-briefcase', color = 'linear-gradient(160deg, #ffa53a, #f47a17)', page = 'management.html' },
        -- Showroom spots + selling from the shop's catalog (needs VehicleSales).
        Dealership = { id = 'dealership', label = '%s', icon = 'fas fa-car', color = 'linear-gradient(160deg, #7ee06a, #2f9e44)', page = 'dealership.html' },
    },

    -- The nearest laptop within this many metres shows the live dashboard (members) or the locked screen.
    RenderDistance = 15.0,
}

-- Dealership cash register: an admin placed prop inside the business Area. The buyer pays price + these taxes.
Config.Dealership = {
    RegisterModel = 'prop_till_02',
    Taxes = { 'Vehicle Sales', 'Vehicle Registration Tax' }, -- fw-core tax names
}
