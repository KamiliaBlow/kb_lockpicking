fx_version 'adamant'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'KamiliaBlow'
description 'Oblivion Style Lockpicking Minigame'
version '0.8.5'

ui_page 'html/index.html'

client_scripts {
	'config.lua',
    'client.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/textures/Pin.png',
    'html/textures/LockedPin.png',
    'html/textures/Lockpick.png',
	'html/textures/Lockpick_broken.png',
	'html/textures/Lockpick_head.png',
    'html/textures/slice1.png',
	'html/textures/spring.png',
    'html/sounds/pinup.mp3',
    'html/sounds/sping.mp3',
    'html/sounds/podsechka.mp3',
    'html/sounds/pin_succes.mp3',
    'html/sounds/pin_fail.mp3',
    'html/sounds/lockpick_broken.mp3',
	'html/sounds/lockpick_succes.mp3'
}