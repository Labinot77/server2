fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'fw-dui - DUI screens on props (ATMs, laptops, ...), incl. props placed from fw-admin'

shared_script 'config/sh_config.lua'

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    'client/*.lua',
}

server_script 'server/*.lua'
