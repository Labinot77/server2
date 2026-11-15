fx_version 'cerulean'
game 'gta5'

lua54 'yes'

ui_page 'web/public/index.html'

files {
    'web/public/**/*',
    'stream/codera_phone_ytyp.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/codera_phone_ytyp.ytyp'

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
