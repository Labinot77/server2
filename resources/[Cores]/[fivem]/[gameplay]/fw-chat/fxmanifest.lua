fx_version 'cerulean'
game 'gta5'

description 'Chat server side + spam filter (named fw-chat so it never clashes with the artifact\'s built-in chat). The chat UI lives in fw-ui (Hud/layers/Chat.svelte), input in fw-hud.'

client_script 'cl_chat.lua'
server_script 'sv_chat.lua'
