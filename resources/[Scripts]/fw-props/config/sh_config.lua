Config = {}

-- Permission required for /placeprop and /deleteprop (fw-core permission group)
Config.Permission = 'admin'

-- Props are only spawned for players within this distance (streaming)
Config.SpawnDistance = 100.0

-- Max distance the placement raycast reaches from the camera
Config.PlaceDistance = 15.0

-- Max distance to find a prop with /deleteprop
Config.DeleteDistance = 3.0

-- Rotation step (degrees) per scroll tick, hold SHIFT for fine control
Config.RotateStep = 5.0
Config.RotateStepFine = 1.0

-- Height step per key press (PAGE UP / PAGE DOWN)
Config.HeightStep = 0.05

-- Optional quick-pick list shown in the input. Leave empty to only use free text.
Config.QuickProps = {
    { Text = 'Toolchest', Value = 'prop_toolchest_05' },
    { Text = 'Work light', Value = 'prop_worklight_03b' },
    { Text = 'Tyre stack', Value = 'prop_rub_tyre_03' },
    { Text = 'Traffic cone', Value = 'prop_roadcone02a' },
    { Text = 'Barrier', Value = 'prop_barrier_work05' },
    { Text = 'Crate', Value = 'prop_boxpile_07d' },
}
