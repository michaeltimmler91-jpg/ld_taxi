print('^2[ld_taxi]^7 Taxi-System gestartet')

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    LDTaxiDB.Init()
    print('^2[ld_taxi]^7 System bereit')
end)

local function IsDispatcher(identifier, dispatchers)
    if not identifier then return false end
    for _, dispatcher in ipairs(dispatchers or {}) do
        if dispatcher.identifier == identifier then return true end
    end
    return false
end

local function SendTabletData(src, eventName, message)
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer and xPlayer.identifier or ''
    local orders = LDTaxi.Orders.GetOpen()
    local drivers = LDTaxi.Drivers.GetAll()
    local dispatchers = LDTaxi.Dispatch.GetActive()
    local finance = LDTaxi.Finance.GetSummary()
    local blackboard = LDTaxi.Blackboard.GetAll(identifier)

    TriggerClientEvent('ld_tablet:client:taxiData', src, {
        self = {
            identifier = identifier,
            name = xPlayer and xPlayer.getName() or '',
            isDispatcher = IsDispatcher(identifier, dispatchers),
            canManageBlackboard = LDTaxi.Blackboard.CanManage(src)
        },
        orders = orders or {},
        drivers = drivers or {},
        dispatchers = dispatchers or {},
        finance = finance or {},
        blackboard = blackboard or {},
        event = eventName or '',
        message = message or '',
        stats = {
            openOrders = #(orders or {}),
            drivers = #(drivers or {}),
            dispatchers = #(dispatchers or {}),
            unreadBlackboard = #(function()
                local unread = {}
                for _, post in ipairs(blackboard or {}) do
                    if tonumber(post.is_read) ~= 1 then unread[#unread + 1] = post end
                end
                return unread
            end)(),
            maxDispatchers = Config.MaxDispatchers
        }
    })
end

local function BroadcastTabletData(eventName, message)
    for _, playerId in ipairs(GetPlayers()) do
        SendTabletData(tonumber(playerId), eventName, message)
    end
end

local function NotifyAndSync(src, msg, eventName)
    if msg then TriggerClientEvent('ld_taxi:client:notify', src, msg) end
    BroadcastTabletData(eventName or 'taxi.updated', msg or '')
end

RegisterNetEvent('ld_taxi:server:requestTabletData', function()
    SendTabletData(source)
end)

RegisterNetEvent('ld_taxi:server:blackboardCreate', function(data)
    local src = source
    local ok, msg = LDTaxi.Blackboard.Create(src, data)
    NotifyAndSync(src, msg, ok and 'blackboard.created' or 'blackboard.failed')
end)

RegisterNetEvent('ld_taxi:server:blackboardRead', function(postId)
    local src = source
    local ok, msg = LDTaxi.Blackboard.MarkRead(src, postId)
    NotifyAndSync(src, msg, ok and 'blackboard.read' or 'blackboard.failed')
end)

RegisterNetEvent('ld_taxi:server:blackboardDelete', function(postId)
    local src = source
    local ok, msg = LDTaxi.Blackboard.Delete(src, postId)
    NotifyAndSync(src, msg, ok and 'blackboard.deleted' or 'blackboard.failed')
end)

RegisterNetEvent('ld_taxi:server:blackboardPin', function(postId)
    local src = source
    local ok, msg = LDTaxi.Blackboard.TogglePinned(src, postId)
    NotifyAndSync(src, msg, ok and 'blackboard.pinned' or 'blackboard.failed')
end)

RegisterNetEvent('ld_taxi:server:markPayoutPaid', function(identifier)
    local src = source
    if LDTaxi.Finance.MarkPaid(identifier) then
        NotifyAndSync(src, 'Trinkgeld-Auszahlung markiert.', 'finance.paid')
    end
end)

RegisterNetEvent('ld_taxi:server:clockIn', function()
    local src = source
    if LDTaxi.Drivers.ClockIn(src) then
        NotifyAndSync(src, 'Dienst begonnen.', 'driver.clocked_in')
    end
end)

RegisterNetEvent('ld_taxi:server:clockOut', function()
    local src = source
    LDTaxi.Drivers.ClockOut(src)
    NotifyAndSync(src, 'Dienst beendet.', 'driver.clocked_out')
end)

RegisterNetEvent('ld_taxi:server:takeDispatch', function()
    local src = source
    local ok, msg = LDTaxi.Dispatch.Take(src)
    NotifyAndSync(src, msg, 'dispatch.started')
end)

RegisterNetEvent('ld_taxi:server:leaveDispatch', function()
    local src = source
    local ok, msg = LDTaxi.Dispatch.Leave(src)
    NotifyAndSync(src, msg, 'dispatch.ended')
end)

RegisterNetEvent('ld_taxi:server:createOrder', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local dispatchers = LDTaxi.Dispatch.GetActive()
    if not xPlayer or not IsDispatcher(xPlayer.identifier, dispatchers) then
        NotifyAndSync(src, 'Du bist nicht in der Leitstelle.', 'order.create_denied')
        return
    end

    data = data or {}
    local id = LDTaxi.Orders.Create({
        orderType = data.orderType or OrderType.Person,
        customerName = data.customerName or '',
        customerIdentifier = '',
        pickupLabel = data.pickupLabel or '',
        pickup = { x = 0.0, y = 0.0, z = 0.0 },
        destinationLabel = data.destinationLabel or '',
        destination = { x = 0.0, y = 0.0, z = 0.0 },
        note = data.note or '',
        foodCost = tonumber(data.foodCost) or 0,
        createdBy = xPlayer.identifier
    })

    NotifyAndSync(src, ('Auftrag #%s erstellt.'):format(id), 'order.created')
end)

RegisterNetEvent('ld_taxi:server:assignOrder', function(orderId, driverIdentifier, driverName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local dispatchers = LDTaxi.Dispatch.GetActive()
    if not xPlayer or not IsDispatcher(xPlayer.identifier, dispatchers) then
        NotifyAndSync(src, 'Du bist nicht in der Leitstelle.', 'order.assign_denied')
        return
    end

    local ok, msg = LDTaxi.Orders.Assign(orderId, driverIdentifier, driverName, xPlayer.identifier)
    NotifyAndSync(src, msg, ok and 'order.assigned' or 'order.assign_failed')
end)

RegisterNetEvent('ld_taxi:server:acceptOrder', function(orderId)
    local src = source
    local ok, msg = LDTaxi.Orders.Accept(orderId, src)
    NotifyAndSync(src, msg, 'order.accepted')
end)

RegisterNetEvent('ld_taxi:server:arriveOrder', function(orderId)
    local src = source
    local ok, msg = LDTaxi.Orders.SetStatus(orderId, src, OrderStatus.Arrived, DriverStatus.Arrived, 'Am Abholort angekommen.')
    NotifyAndSync(src, msg, 'order.arrived')
end)

RegisterNetEvent('ld_taxi:server:startOrder', function(orderId)
    local src = source
    local ok, msg = LDTaxi.Orders.SetStatus(orderId, src, OrderStatus.Started, DriverStatus.InRide, 'Fahrt gestartet.')
    NotifyAndSync(src, msg, 'order.started')
end)

RegisterNetEvent('ld_taxi:server:returnOrder', function(orderId, reason)
    local src = source
    local ok, msg = LDTaxi.Orders.Return(orderId, src, reason)
    NotifyAndSync(src, msg, 'order.returned')
end)

RegisterNetEvent('ld_taxi:server:completeOrder', function(orderId, distanceKm, chargedAmount, foodPaymentMethod)
    local src = source
    local ok, msg = LDTaxi.Orders.Complete(orderId, src, distanceKm, chargedAmount, foodPaymentMethod)
    NotifyAndSync(src, msg, 'order.completed')
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
    BroadcastTabletData('order.created', ('Neuer Auftrag #%s'):format(id))
end)
