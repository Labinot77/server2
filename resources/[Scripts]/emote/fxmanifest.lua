fx_version "cerulean"
games { "gta5" }
lua54 "yes"

author "codera"
description "codera Developments Animation System V"
version "0.1.0"


ui_page "web/dist/index.html"

files {
    "web/dist/**/*",
    "data/animalModels.json",
}

server_scripts {
    "lib/npx/server.js",
    "@oxmysql/lib/MySQL.lua",
    "server/main.js",
    "lib/sync/server.lua",
}

client_scripts {
    "lib/npx/client.js",
    "lib/sync/lib.lua",
    "lib/sync/client.lua",
    "client/main.js",
    "data/*.js",
    "client/animals.lua",
}
