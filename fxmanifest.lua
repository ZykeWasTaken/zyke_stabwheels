fx_version "cerulean"
game "gta5"
author "discord.gg/zykeresources"
lua54 "yes"
version "1.0.2"

shared_scripts {
    "@zyke_lib/imports.lua",
    "config.lua",
}

client_script "client.lua"
file "locales/*.lua"

dependency "zyke_lib"