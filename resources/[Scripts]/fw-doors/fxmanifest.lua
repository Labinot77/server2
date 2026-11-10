fx_version 'cerulean'
game 'gta5'

lua54 'yes'

shared_scripts {
    'config.lua',
    'config_hud.lua',
}

client_scripts {
    'client/_cl_main.lua',
    'client/cl_detcord.lua',
    'client/cl_elevators.lua',
    'client/cl_zones.lua',
    'client/cl_hud_font.lua',
    'client/cl_hud.lua',
    'client/cl_creator.lua',
}

server_scripts {
    'server/sv_creator.lua', -- loads data/doors.json before sv_main converts Connected
    'server/sv_main.lua',
}

files {
    'assets/hud/*.png',
}
