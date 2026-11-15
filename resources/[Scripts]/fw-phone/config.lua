Config = Config or {}

Config.Crypto = {
    {
        Icon = "caret-square-up",
        Label = "Shungite",
        Id = "SHUNG",
        Costs = 100,
        Purchasable = true,
    },
    {
        Icon = "horse-head",
        Label = "Guinea",
        Id = "GNE",
        Costs = 100,
        Purchasable = false,
    },
    {
        Icon = "shield-check",
        Label = "Evidentia",
        Id = "EVD",
        Costs = 100,
        Purchasable = false,
    },
    {
        Icon = "theater-masks",
        Label = "XTF",
        Id = "XTF",
        Costs = 1000,
        Purchasable = false,
    },
}
-- Phone prop / hand states (Codera foldable phone, streamed from /stream)
Config.PhoneProp = 'prop_codera_phone_fold_black'          -- folded model (falls back to prop_npc_phone_02 when not streamed)
Config.PhonePropOpen = 'prop_codera_phone_fold_black_open' -- unfolded model, shown while the UI is unfolded (T)
Config.PhonePropBone = 28422                               -- 28422 = right hand
-- Per-state hand offsets (default/open/texting/call). Tune in game with /phoneattach x y z rx ry rz [bone].
Config.PhoneAttach = {
    default = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rot = vector3(0.0, 0.0, 0.0) },
}
