print('^2[ld_taxi]^7 Taxi-System gestartet')

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    LDTaxiDB.Init()
    print('^2[ld_taxi]^7 System bereit')
end)

RegisterNetEvent('ld_taxi:server:clockIn', function()
    local src = source
    if LDTaxi.Drivers.ClockIn(src) then
        TriggerClientEvent('ld_taxi:client:notify', src, 'Dienst begonnen.')
    end
end)

RegisterNetEvent('ld_taxi:server:clockOut', function()
    local src = source
    LDTaxi.Drivers.ClockOut(src)
    TriggerClientEvent('ld_taxi:client:notify', src, 'Dienst beendet.')
end)

RegisterNetEvent('ld_taxi:server:takeDispatch', function()
    local src = source
    local ok, msg = LDTaxi.Dispatch.Take(src)
    TriggerClientEvent('ld_taxi:client:notify', src, msg)
end)

RegisterNetEvent('ld_taxi:server:leaveDispatch', function()
    local src = source
    local ok, msg = LDTaxi.Dispatch.Leave(src)
    TriggerClientEvent('ld_taxi:client:notify', src, msg)
end)

RegisterNetEvent('ld_taxi:server:testOrder', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local id = LDTaxi.Orders.Create({
        orderType = OrderType.Person,
        customerName = xPlayer.getName(),
        customerIdentifier = xPlayer.identifier,
        pickupLabel = 'Aktuelle Position',
        pickup = { x = coords.x or 0.0, y = coords.y or 0.0, z = coords.z or 0.0 },
        destinationLabel = '',
        destination = { x = 0.0, y = 0.0, z = 0.0 },
        note = 'Testauftrag',
        createdBy = xPlayer.identifier
    })

    TriggerClientEvent('ld_taxi:client:notify', src, ('Testauftrag #%s erstellt.'):format(id))
end)
