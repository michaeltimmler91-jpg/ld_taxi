local tabletOpen = false

local function RequestTaxiData()
    TriggerServerEvent('ld_taxi:server:requestTabletData')
end

local function OpenTablet()
    if tabletOpen then return end
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    RequestTaxiData()
end

local function CloseTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('tablet', function()
    if tabletOpen then
        CloseTablet()
    else
        OpenTablet()
    end
end)

RegisterCommand('tabletreset', function()
    SendNUIMessage({ action = 'reset' })
end)

RegisterKeyMapping('tablet', 'Tablet öffnen/schließen', 'keyboard', 'F6')

RegisterNUICallback('closeTablet', function(_, cb)
    CloseTablet()
    cb(true)
end)

RegisterNUICallback('refreshTaxiData', function(_, cb)
    RequestTaxiData()
    cb(true)
end)

RegisterNetEvent('ld_tablet:client:taxiData', function(data)
    SendNUIMessage({
        action = 'taxiData',
        data = data or {}
    })
end)
