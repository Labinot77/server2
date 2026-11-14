fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'html/index.html'
files { 'html/index.html' }

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    '@PolyZone/client.lua', -- PolyZone:Create for the MLO zones
    '@PolyZone/ComboZone.lua',
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
