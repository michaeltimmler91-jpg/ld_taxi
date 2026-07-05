RegisterCommand('taxidienst', function()
    TriggerServerEvent('ld_taxi:server:clockIn')
end)

RegisterCommand('taxioff', function()
    TriggerServerEvent('ld_taxi:server:clockOut')
end)

RegisterCommand('leitstelle', function()
    TriggerServerEvent('ld_taxi:server:takeDispatch')
end)

RegisterCommand('leitstelleoff', function()
    TriggerServerEvent('ld_taxi:server:leaveDispatch')
end)

RegisterCommand('taxitest', function()
    TriggerServerEvent('ld_taxi:server:testOrder')
end)

RegisterNetEvent('ld_taxi:client:notify', function(message)
    ESX.ShowNotification(message)
end)
