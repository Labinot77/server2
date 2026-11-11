-- Placed props (was fw-props). Placed from the admin panel (Utility) and saved in `placed_props`.
Config.Props = {
    SpawnDistance = 100.0,  -- props only exist for players within this distance
    PlaceDistance = 15.0,   -- placement raycast reach from the camera
    DeleteDistance = 3.0,   -- range for "delete nearest"
    RotateStep = 5.0,       -- degrees per scroll tick
    RotateStepFine = 1.0,   -- with SHIFT
    HeightStep = 0.05,      -- PAGE UP / PAGE DOWN

    -- Quick picks in the admin panel
    QuickProps = {
        { Val = 'custom_laptop_01', Text = 'Laptop (custom)' },
        { Val = 'prop_toolchest_05', Text = 'Toolchest' },
        { Val = 'prop_worklight_03b', Text = 'Work light' },
        { Val = 'prop_rub_tyre_03', Text = 'Tyre stack' },
        { Val = 'prop_roadcone02a', Text = 'Traffic cone' },
        { Val = 'prop_barrier_work05', Text = 'Barrier' },
        { Val = 'prop_boxpile_07d', Text = 'Crate' },
    },
}

local YesNo = { { Val = 'yes', Text = 'Yes' }, { Val = 'no', Text = 'No' } }

for _, Item in ipairs({
    {
        Category = 'utility',
        Id = 'placeProp',
        Name = 'Place Prop',
        Event = 'Admin:Props:Place',
        Collapse = true,
        Options = {
            { Id = 'model', Name = 'Model (or pick one below)', Type = 'input', InputType = 'text' },
            { Id = 'quick', Name = 'Quick pick', Type = 'input-choice', Choices = Config.Props.QuickProps },
            { Id = 'frozen', Name = 'Frozen', Type = 'input-choice', Choices = YesNo },
            { Id = 'collision', Name = 'Collision', Type = 'input-choice', Choices = YesNo },
        },
    },
    {
        Category = 'utility',
        Id = 'deleteProp',
        Name = 'Delete Prop',
        Event = 'Admin:Props:Delete',
        Collapse = true,
        Options = {
            { Id = 'id', Name = 'Prop id (empty = nearest)', Type = 'input-text', InputType = 'number' },
        },
    },
    {
        Category = 'utility',
        Id = 'reloadProps',
        Name = 'Reload Props',
        Event = 'fw-admin:Server:Props:Reload',
        EventType = 'Server',
        Collapse = false,
    },
}) do
    Config.AdminMenus[#Config.AdminMenus + 1] = Item
end
