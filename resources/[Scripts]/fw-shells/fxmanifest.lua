fx_version 'cerulean'
game 'gta5'
lua54 'yes'
description 'Shell builder for MLO houses: kit walls with door holes and one-way windows'

ui_page 'html/index.html'
files { 'html/index.html' }

shared_scripts { 'config.lua', 'shared/*.lua' }
client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }

dependencies { 'fw-core', 'fw-ui', 'fw-walls' }
