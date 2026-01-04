fx_version 'cerulean'
game 'gta5'

author 'Klaus'
description 'Standalone Plaka Sistemi - Ülkelere Göre Plaka Formatları'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

lua54 'yes'

