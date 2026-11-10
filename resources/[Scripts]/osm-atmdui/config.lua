Config = {}

-- Open the ATM from your interact script:
--   exports['osm-atmdui']:OpenATM(entity)   -- entity optional, nearest ATM if nil
-- /atmtest opens the nearest ATM (false to disable).
Config.TestCommand = 'atmtest'

Config.BankName = 'FLEECA'

Config.Withdraw = {
    quickAmounts = { 100, 500, 1000, 5000 },
    maxPerTransaction = 10000,
    dailyLimit = 50000, -- per character per day (resets at midnight / restart)
    maxDigits = 6,
}

Config.CursorSensitivity = 13.0

Config.Camera = {
    transitionTime = 500, -- ms
    distance = 0.50,      -- metres in front of the screen
    height = 0.07,        -- metres above the screen centre
    fov = 30.0,
}

-- Per ATM model (entity-local offsets):
--   texture: the screen texture the DUI replaces
--   screen:  screen edges, used to aim the camera
--   cash:    where the cash prop slides out
Config.Models = {
    prop_fleeca_atm = {
        texture = { dict = 'prop_fleeca_atm', name = 'prop_fleece_emis' },
        screen  = { left = -0.306, right = 0.065, top = 1.23, bottom = 1.055, y = 0.085 },
        cash    = { x = -0.11, startY = 0.15, endY = -0.15, z = 0.95 },
    },
    prop_atm_01 = {
        texture = { dict = 'prop_atm_01', name = 'prop_cashpoint_screen' },
        screen  = { left = -0.19, right = 0.084, top = 1.14, bottom = 1.02, y = -0.12 },
        cash    = { x = -0.05, startY = -0.20, endY = -0.35, z = 0.75 },
    },
    prop_atm_02 = {
        texture = { dict = 'prop_atm_02', name = 'prop_cashpoint_screen' },
        screen  = { left = -0.306, right = 0.065, top = 1.23, bottom = 1.05, y = 0.085 },
        cash    = { x = -0.11, startY = 0.15, endY = -0.15, z = 0.95 },
    },
    prop_atm_03 = {
        texture = { dict = 'prop_atm_03', name = 'prop_cashpoint_screen' },
        screen  = { left = -0.306, right = 0.065, top = 1.23, bottom = 1.05, y = 0.07 },
        cash    = { x = -0.11, startY = 0.15, endY = -0.15, z = 0.95 },
    },
}

Config.Text = {
    invalid_amount = 'Invalid amount',
    insufficient_funds = 'Insufficient funds',
    over_limit = 'Over the single withdrawal limit',
    daily_limit = 'Daily limit reached',
    no_permission = 'No withdraw access on this account',
    error = 'Transaction failed',
    take_cash = 'Please take your cash',
    no_accounts = 'No accounts found',
    no_atm = 'No ATM nearby',
}
