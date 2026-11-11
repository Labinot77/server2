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

-- Camera in front of the screen (fw-dui fits the distance to the screen size).
Config.Camera = {
    fov = 30.0,
    transitionTime = 500, -- ms
}

-- ATM models, with where the cash prop slides out (entity-local offsets).
-- The screen itself (corners, resolution) is in fw-dui/config/sh_config.lua.
Config.Models = {
    prop_fleeca_atm = { cash = { x = -0.11, startY = 0.15, endY = -0.15, z = 0.95 } },
    prop_atm_01     = { cash = { x = -0.05, startY = -0.20, endY = -0.35, z = 0.75 } },
    prop_atm_02     = { cash = { x = -0.11, startY = 0.15, endY = -0.15, z = 0.95 } },
    prop_atm_03     = { cash = { x = -0.11, startY = 0.15, endY = -0.15, z = 0.95 } },
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
