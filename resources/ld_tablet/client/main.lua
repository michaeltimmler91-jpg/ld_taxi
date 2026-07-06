local tabletOpen = false
local tabletProp = nil

local function RequestTaxiData()
    TriggerServerEvent('ld_taxi:server:requestTabletData')
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function LoadModel(model)
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    return hash
end

local function CreateTabletProp()
    if tabletProp then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = LoadModel('prop_cs_tablet')
    tabletProp = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 28422), 0.0, -0.03, 0.0, 20.0, -90.0, 0.0, true, true, false, true, 1, true)
end

local function RemoveTabletProp()
    if tabletProp then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end

local function OpenTablet()
    if tabletOpen then return end
    tabletOpen = true
    LoadAnimDict('amb@world_human_seat_wall_tablet@female@base')
    TaskPlayAnim(PlayerPedId(), 'amb@world_human_seat_wall_tablet@female@base', 'base', 8.0, -8.0, -1, 49, 0, false, false, false)
    CreateTabletProp()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    RequestTaxiData()
end

local function CloseTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    ClearPedTasks(PlayerPedId())
    RemoveTabletProp()
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('tablet', function()
    if tabletOpen then CloseTablet() else OpenTablet() end
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

RegisterNUICallback('takeDispatch', function(_, cb)
    TriggerServerEvent('ld_taxi:server:takeDispatch')
    cb(true)
end)

RegisterNUICallback('leaveDispatch', function(_, cb)
    TriggerServerEvent('ld_taxi:server:leaveDispatch')
    cb(true)
end)

RegisterNUICallback('createOrder', function(data, cb)
    TriggerServerEvent('ld_taxi:server:createOrder', data or {})
    cb(true)
end)

RegisterNUICallback('markPayoutPaid', function(data, cb)
    TriggerServerEvent('ld_taxi:server:markPayoutPaid', data and data.identifier or '')
    cb(true)
end)

RegisterNUICallback('assignOrder', function(data, cb)
    TriggerServerEvent('ld_taxi:server:assignOrder', data and data.orderId or 0, data and data.identifier or '', data and data.name or '')
    cb(true)
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    local x = tonumber(data and data.x)
    local y = tonumber(data and data.y)
    if x and y then
        SetNewWaypoint(x + 0.0, y + 0.0)
        ESX.ShowNotification('GPS gesetzt.')
    end
    cb(true)
end)

RegisterNUICallback('orderAction', function(data, cb)
    local action = data and data.action
    local orderId = data and data.orderId

    if action == 'accept' then
        TriggerServerEvent('ld_taxi:server:acceptOrder', orderId)
    elseif action == 'arrive' then
        TriggerServerEvent('ld_taxi:server:arriveOrder', orderId)
    elseif action == 'start' then
        TriggerServerEvent('ld_taxi:server:startOrder', orderId)
    elseif action == 'return' then
        TriggerServerEvent('ld_taxi:server:returnOrder', orderId, data.reason or 'Vom Tablet zurückgegeben')
    elseif action == 'complete' then
        TriggerServerEvent('ld_taxi:server:completeOrder', orderId, data.distance or 1, data.charged or 5, data.foodPaymentMethod or '')
    end

    cb(true)
end)

RegisterNetEvent('ld_tablet:client:taxiData', function(data)
    SendNUIMessage({ action = 'taxiData', data = data or {} })
end)
