fx_version 'cerulean'
game 'gta5'

client_scripts {
    '@fw-assets/client/cl_errorlog.lua',
    "config.lua",
    "client/*.lua",
}

server_scripts {
    '@fw-assets/server/sv_errorlog.lua',
    "config.lua",
    "server/*.lua",
}

shared_scripts {
    '@ox_lib/init.lua',
    --}
}

exports {
    'HasVehicleNosActive',
}

dependency 'ox_lib'