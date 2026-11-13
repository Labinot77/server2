fx_version 'cerulean'
game 'gta5'

description 'fw-mainmenu - custom map (GTA native map textures), opened from np-quickmenu or the GTA pause menu'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/tiles/**/*.webp',
}

shared_script 'config.lua'

client_scripts {
    'client/cl_main.lua',
}
