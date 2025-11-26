fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game "rdr3"
lua54 'yes'

author 'Ouro Development'
description 'Ouro Society - Multijob & Clan System'
version '1.0.0'

ui_page 'html/ui.html'

shared_scripts {
    'config/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/warmenu.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/clans.lua',
    'server/logs.lua'
}

files {
    'html/ui.html',
    'html/styles.css',
    'html/scripts.js',
    'html/configNui.js',
    'html/assets/**/*'
}

dependencies {
    'vorp_core',
    'vorp_inventory',
    'vorp_inputs',
    'oxmysql'
}

