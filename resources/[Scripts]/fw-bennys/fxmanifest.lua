fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Robijn'
description "Benny's Motorworks"

shared_scripts {
    'config/sh_*.lua',
}

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    'client/cl_legacy.lua',
    'client/cl_orders.lua',
    'client/cl_laptop.lua',
    'client/cl_stance.lua',
    'dist/client.js',
}

server_scripts {
    '@fw-assets/server/sv_errorlog.lua',
    'server/sv_legacy.lua',
    'server/sv_orders.lua',
    'dist/server.js',
}

files {
    'html/laptop.html',
}
