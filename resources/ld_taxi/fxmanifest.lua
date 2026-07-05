fx_version 'cerulean'
game 'gta5'

author 'Lennox / Los Santos Taxi'
description 'LD Taxi - ESX/FiveM Taxi-System'
version '0.1.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'shared/utils.lua',
    'shared/events.lua',
    'shared/statuses.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/eventbus.lua',
    'server/modules/drivers.lua',
    'server/modules/orders.lua',
    'server/modules/dispatch.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
