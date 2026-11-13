Config = Config or {}

-- Advanced Fleeca: power box (cutters + laptop hack in a DUI) -> lobby terminal (password from sticky notes)
-- -> door access codes -> keypads. Per bank settings live in Config.Fleeca[x].Advanced (sh_fleeca.lua).
-- Keypad prop at every Fleeca's StaffDoor (client/cl_fleeca_keypad.lua). Opens DoorIds[DoorId] (1 = the service door).
-- Advanced banks also take the live code generated for their door with that DoorId.
Config.FleecaKeypad = { Model = 'hei_prop_hei_keypad_01', Code = '1111', MaxDigits = 6, DoorId = 1 }

Config.FleecaAdvanced = {
    Items = { Cutters = 'heavy-cutters', Laptop = 'heist-laptop' },
    Models = { Laptop = 'custom_laptop_01', Monitor = 'prop_monitor_01a', Note = 'hei_prop_hei_post_note_01' },

    CutTime = 7500,                               -- ms to cut the box open
    Hack = { Rounds = 3, Time = 45, Cols = 7, Rows = 5 }, -- laptop minigame (seconds per round)
    NoteCount = 3,                                -- notes per bank (max = number of spots)
    NoteScale = 3.0,                              -- sticky notes are scaled up so they're easy to spot
    MaxAttempts = 3,                              -- wrong passwords before the terminal locks
    Lockout = 60,                                 -- seconds
    CodeLifetime = 15,                            -- seconds an access code stays valid
    User = 'Harold Whitmore',

    -- Passwords are Word + 2 digits. The real one and the decoys always start with different letters.
    Words = { 'Biscuit', 'Smokey', 'Harold', 'Legion', 'Pacific', 'Vinewood', 'Marlowe', 'Rockford', 'Zancudo', 'Tongva', 'Grapeseed', 'Elysian' },
}
