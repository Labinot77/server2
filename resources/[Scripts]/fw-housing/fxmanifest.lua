fx_version 'cerulean'
game 'gta5'

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    '@PolyZone/client.lua', -- PolyZone:Create for the MLO zones
    'config/sh_*.lua',
    'client/*.lua',
}

server_scripts {
    '@fw-assets/server/sv_errorlog.lua',
    'config/*.lua',
    'server/*.lua',
}

dependencies {
    'PolyZone',
    'interact',
}
