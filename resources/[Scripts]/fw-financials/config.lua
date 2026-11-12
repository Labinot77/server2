Config = Config or {}

Config.Zones = {
    {
        center = vector3(149.42, -1040.29, 29.34),
        heading = 70.0,
        length = 6.3,
        width = 1.5,
        minZ = 28.34,
        maxZ = 30.34
    },
    {
        center = vector3(314.13, -278.76, 54.17),
        heading = 340.0,
        length = 1.3,
        width = 2.3,
        minZ = 53.17,
        maxZ = 55.57
    },
    {
        center = vector3(-351.11, -49.51, 49.05),
        heading = 340.0,
        length = 1.3,
        width = 2.5,
        minZ = 48.05,
        maxZ = 50.25
    },
    {
        center = vector3(-1213.43, -330.82, 37.79),
        heading = 27.0,
        length = 1.3,
        width = 2.1,
        minZ = 36.79,
        maxZ = 38.25
    },
    {
        center = vector3(-2962.78, 482.38, 15.71),
        heading = 358.0,
        length = 1.9,
        width = 1.1,
        minZ = 14.71,
        maxZ = 16.71
    },
    {
        center = vector3(1175.44, 2706.58, 38.09),
        heading = 0.0,
        length = 1.15,
        width = 2.1,
        minZ = 37.09,
        maxZ = 39.69
    },
    {
        center = vector3(-109.8, 6468.95, 31.63),
        length = 1.0,
        width = 1.0,
        heading = 315,
        minZ = 30.63,
        maxZ = 32.63
    },
    {
        center = vector3(-1308.54, -823.69, 17.15),
        heading = 37.0,
        length = 1.0,
        width = 1.8,
        minZ = 16.15,
        maxZ = 18.15
    },
    {
        center = vector3(268.05, 217.65, 106.28),
        length = 3.75,
        width = 1.0,
        heading = 340,
        minZ = 105.28,
        maxZ = 107.88
    }
}

-- ATM screen (DUI on the ATM itself, drawn by fw-dui). Screen textures + cameras: fw-dui/config/sh_config.lua
Config.ATM = {
    BankName = 'FLEECA',
    RenderDistance = 15.0,  -- the nearest ATM within this range shows the idle screen
    CursorSensitivity = 13.0,
    TestCommand = 'atmtest', -- opens the nearest ATM (false to disable)

    Withdraw = {
        QuickAmounts = { 100, 500, 1000, 5000 },
        MaxPerTransaction = 10000,
        DailyLimit = 50000, -- per character per day (resets at midnight / restart)
        MaxDigits = 6,
    },

    -- Cash = where the cash prop slides out (offsets from the ATM).
    -- Sheet = true: the screen is only a corner of a shared texture (stock prop_fleeca_atm uses prop_fleece_emis),
    -- so the page squeezes its UI into that corner. Leave it off when the model has its own screen texture.
    Models = {
        ['prop_fleeca_atm'] = { Cash = { X = -0.11, StartY = 0.15, EndY = -0.15, Z = 0.95 } }, -- own screen in prop_fleeca_atm_dui
        ['prop_atm_01'] = { Cash = { X = -0.05, StartY = -0.20, EndY = -0.35, Z = 0.75 } },
        ['prop_atm_02'] = { Cash = { X = -0.11, StartY = 0.15, EndY = -0.15, Z = 0.95 } },
        ['prop_atm_03'] = { Cash = { X = -0.11, StartY = 0.15, EndY = -0.15, Z = 0.95 } },
    },

    Text = {
        invalid_amount = 'Invalid amount',
        insufficient_funds = 'Insufficient funds',
        over_limit = 'Over the single withdrawal limit',
        daily_limit = 'Daily limit reached',
        no_permission = 'No withdraw access on this account',
        error = 'Transaction failed',
        take_cash = 'Please take your cash',
        no_accounts = 'No accounts found',
        no_atm = 'No ATM nearby',
    },
}
