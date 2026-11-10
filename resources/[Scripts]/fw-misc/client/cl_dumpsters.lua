exports.interact:AddModelInteraction({
    modelData = {
        { model = 'prop_cs_dumpster_01a', offset = vec3(0.0, -0.2, 1.3) },
        { model = 'p_dumpster_t',        offset = vec3(0.0, -0.2, 1.3) },
        { model = 'prop_dumpster_01a',   offset = vec3(0.0, -0.2, 1.3) },
        { model = 'prop_dumpster_02a',   offset = vec3(0.0, -0.2, 1.3) },
        { model = 'prop_dumpster_02b',   offset = vec3(0.0, -0.2, 1.3) },
        { model = 'prop_dumpster_3a',    offset = vec3(0.0, -0.2, 1.3) },
        { model = 'prop_dumpster_4a',    offset = vec3(0.0, -0.2, 1.3) },
        { model = 'prop_dumpster_4b',    offset = vec3(0.0, -0.2, 1.3) },
    },
    distance = 1.0,
    interactDst = 1.0,
    options = {
        {
            label = 'Search Trash',
            action = function(entity, coords, args)
                local coords = GetEntityCoords(entity)

                FW.TriggerServer('fw-inventory:Server:OpenInventory',
                    'Dumpster',
                    'HiddenContainer-' .. math.floor(coords.x) .. '/' .. math.floor(coords.y),
                    200,
                    2000.0
                )
            end,
        },
    },
})