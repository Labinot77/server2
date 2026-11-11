fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'osm-atmdui'
description 'Fleeca-style DUI ATM for crp-framework (fw-core / fw-financials)'
author 'osmfxmods.com, crp-framework port'
version '2.1.0'

dependencies { 'ox_lib', 'fw-core', 'fw-financials', 'fw-dui' }

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/layout.lua',
    'client/dui.lua',
    'client/main.lua',
}

server_scripts {
    'server/financials.lua',
    'server/main.lua',
}

files { 'html/index.html' }
