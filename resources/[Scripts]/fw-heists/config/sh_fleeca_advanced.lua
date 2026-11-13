Config = Config or {}

-- Advanced Fleeca: power box (cutters + laptop hack in a DUI) -> lobby terminal (password from sticky notes)
-- -> door access codes -> keypads. Per bank settings live in Config.Fleeca[x].Advanced (sh_fleeca.lua).
-- Keypad prop at every Fleeca's StaffDoor (client/cl_fleeca_keypad.lua). Opens DoorIds[DoorId] (1 = the service door).
-- Static = positions of keypads placed in a ymap / MLO (not found as objects): vector4(x, y, z, heading), see fw-dui README.
Config.FleecaKeypad = { Model = 'hei_prop_hei_keypad_01', Code = '1111', MaxDigits = 6, DoorId = 1, Static = {} }

Config.FleecaAdvanced = {
    Items = { Cutters = 'heavy-cutters', Laptop = 'heist-laptop' },
    Models = { Laptop = 'custom_laptop_01', Monitor = 'prop_monitor_01a', Note = 'hei_prop_hei_post_note_01', Panel = 'v_corp_bk_secpanel_dui_01',
        PanelMap = 'v_corp_bk_secpanel' }, -- PanelMap = the bank interior's own panel, swapped to Panel at each door's Panel spot

    CutTime = 7500,                               -- ms to cut the box open
    Hack = { Rounds = 3, Time = 45, Cols = 7, Rows = 5 }, -- laptop minigame (seconds per round)
    NoteCount = 5,                                -- notes per bank (max = number of spots)
    NoteScale = 1.6,                              -- sticky notes are scaled up so they're easy to spot
    -- "Backdoor code, last serviced <age> ago": random per robbery, the most recent one has the real password
    ServiceAges = { { '2 days', 2 }, { '5 days', 5 }, { '1 week', 7 }, { '10 days', 10 }, { '2 weeks', 14 }, { '3 weeks', 21 }, { '1 month', 30 }, { '2 months', 60 } },
    MaxAttempts = 3,                              -- wrong passwords before the terminal locks
    Lockout = 60,                                 -- seconds
    CodeLifetime = 30,                            -- seconds an access code stays valid
    CodeMemorise = 4,                             -- seconds the number shows before the instructions
    User = 'Harold Whitmore',
    Trolley = { MarkedBills = { 60, 90 }, Cash = { 2500, 4500 } }, -- vault trolley payout (sv_trolley.lua)

    -- Passwords are Word + 2 digits. The real one and the decoys always start with different letters.
    Words = { 'Biscuit', 'Smokey', 'Harold', 'Legion', 'Pacific', 'Vinewood', 'Marlowe', 'Rockford', 'Zancudo', 'Tongva', 'Grapeseed', 'Elysian' },
}
