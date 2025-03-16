RegisterNetEvent('grappling:playSound')
AddEventHandler('grappling:playSound', function(soundName)
    local source = source
    TriggerClientEvent('grappling:playCustomSound', -1, soundName, source)
end) 