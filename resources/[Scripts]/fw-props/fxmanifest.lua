fx_version 'cerulean'
game 'gta5'

lua54 'yes'

description 'fw-props - place props in the world, saved to the database'

client_script {
    '@fw-assets/client/cl_errorlog.lua',
    'config/sh_*.lua',
    'client/*.lua',
}

server_script {
    '@fw-assets/server/sv_errorlog.lua',
    'config/sh_*.lua',
    'server/*.lua',
}

dependencies {
    'fw-core',
    'fw-ui',
    'ghmattimysql',
}
