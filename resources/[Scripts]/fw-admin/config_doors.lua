-- Door creator (fw-doors/client/cl_creator.lua). Server events re-check admin permissions.
for _, Item in ipairs({
    {
        Category = 'utility',
        Id = 'addDoor',
        Name = 'Add Door',
        Event = 'fw-doors:Client:Creator:Add',
        Collapse = true,
        Options = {
            { Id = 'type', Name = 'Type', Type = 'input-choice', Choices = { { Val = 'single', Text = 'Single door' }, { Val = 'double', Text = 'Double door (both halves)' } } },
        },
    },
    {
        Category = 'utility',
        Id = 'manageDoors',
        Name = 'Manage Doors',
        Event = 'fw-doors:Client:Creator:Open',
        Collapse = false,
    },
}) do
    Config.AdminMenus[#Config.AdminMenus + 1] = Item
end
