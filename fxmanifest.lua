fx_version "cerulean"
game "gta5"
author "discord.gg/zykeresources"
lua54 "yes"
version "1.0.4"

shared_script "@zyke_lib/imports.lua"

files {
    "client.lua",
    "config.lua",
    "locales/*.lua",
}

loader {
    "client.lua",
    "shared:config.lua",
}

dependency "zyke_lib"