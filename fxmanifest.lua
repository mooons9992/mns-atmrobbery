fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'MNS ATM Robbery'
author 'Mooons'
version '1.0.0'

description 'ATM Robbery Script with Money Washing for QBCore'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/cl_atm.lua',
    'client/cl_moneywash.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/sv_atm.lua',
    'server/sv_moneywash.lua'
}

dependencies {
    'qb-core',
    'ox_lib'
}

