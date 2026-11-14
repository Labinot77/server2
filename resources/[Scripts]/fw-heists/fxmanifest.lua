fx_version 'cerulean'
game 'gta5'

author 'Robijn'
description 'Clarity RP Heists & Petty Crime'

lua54 'yes'

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    'config/*sh_*.lua',
    'client/**/*',
}

server_scripts {
    '@fw-assets/server/sv_errorlog.lua',
    'config/*',
    'server/**/*',
}

ui_page 'html/hints.html' -- key hints (trolley grab)
files { 'html/**/*' } -- DUI apps (fleeca laptop + terminal) + hints
