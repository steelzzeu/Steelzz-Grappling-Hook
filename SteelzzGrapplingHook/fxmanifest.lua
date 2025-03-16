fx_version 'cerulean'
game 'gta5'

author 'Steelzz'
description 'Standalone Grappling Hook System'
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua'
}

-- Sound files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/sounds/*.mp3'
}

dependencies {
    'interact-sound'
}

lua54 'yes' 