fx_version 'cerulean'
game 'gta5'

lua54 'yes'

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    'config.lua',
    'client/*.lua',
}

server_scripts {
    '@fw-assets/server/sv_errorlog.lua',
    'config.lua',
    'sv_config.lua',
    'server/*.lua',
}
files {
    'html/atm/index.html', -- ATM page, built from web-atm/ (npm run build)
    'html/atm/*.png',      -- prop_fleece_emis.png: the stock Fleeca ATM sheet behind the idle screen (export from the game)
}
