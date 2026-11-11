fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'fw-dui - DUI pages drawn on one specific prop (laptops, monitors, ATMs, ...)'

shared_script 'config/sh_config.lua'

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    'client/_cl_main.lua',
    'client/cl_focus.lua',
    'client/cl_static.lua',
    'client/cl_calibrate.lua',
}

files { 'html/*.html' }
