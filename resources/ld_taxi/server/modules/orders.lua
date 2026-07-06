LDTaxi = LDTaxi or {}
LDTaxi.Orders = {}

function LDTaxi.Orders.AddHistory(orderId, eventName, message, createdBy, payload)
    local ok, encoded = pcall(json.encode, payload or {})
    if not ok or not encoded then encoded = '{}' end

    MySQL.insert.await([[
        INSERT INTO ld_taxi_order_history (order_id, event_name, message, payload, created_by)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        tonumber(orderId) or 0,
        tostring(eventName or 'unknown'),
        tostring(message or ''),
        encoded,
        tostring(createdBy or '')
    })
end

function LDTaxi.Orders.Create(data)
    data = data or {}
    data.pickup = data.pickup or {}
    data.destination = data.destination or {}

    local orderId = MySQL.insert.await([[
        INSERT INTO ld_taxi_orders
        (order_type, status, customer_name, customer_identifier, pickup_label, pickup_x, pickup_y, pickup_z,
         destination_label, destination_x, destination_y, destination_z, note, food_cost, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.orderType or OrderType.Person,
        OrderStatus.Dispatch,
        data.customerName or '',
        data.customerIdentifier or '',
        data.pickupLabel or '',
        tonumber(data.pickup.x) or 0.0,
        tonumber(data.pickup.y) or 0.0,
        tonumber(data.pickup.z) or 0.0,
        data.destinationLabel or '',
        tonumber(data.destination.x) or 0.0,
        tonumber(data.destination.y) or 0.0,
        tonumber(data.destination.z) or 0.0,
        data.note or '',
        tonumber(data.foodCost) or 0,
        data.createdBy or ''
    })

    LDTaxi.Orders.AddHistory(orderId, TaxiEvents.OrderCreated, 'Auftrag erstellt', data.createdBy, { orderType = data.orderType, foodCost = data.foodCost })
    LDTaxiEventBus.Emit(TaxiEvents.OrderCreated, { orderId = orderId })

    return orderId
end

function LDTaxi.Orders.GetOpen()
    return MySQL.query.await([[
        SELECT * FROM ld_taxi_orders
        WHERE status NOT IN ('completed', 'cancelled')
        ORDER BY created_at ASC
    ]])
end

function LDTaxi.Orders.Get(orderId)
    return MySQL.single.await('SELECT * FROM ld_taxi_orders WHERE id = ?', { tonumber(orderId) or 0 })
end

function LDTaxi.Orders.Assign(orderId, driverIdentifier, driverName, createdBy)
    local order = LDTaxi.Orders.Get(orderId)
    if not order then return false, 'Auftrag nicht gefunden.' end
    if not driverIdentifier or driverIdentifier == '' then return false, 'Kein Fahrer ausgewählt.' end

    MySQL.update.await([[
        UPDATE ld_taxi_orders
        SET status = ?, assigned_driver = ?, assigned_driver_name = ?, updated_at = NOW()
        WHERE id = ?
    ]], { OrderStatus.Accepted, driverIdentifier, driverName or driverIdentifier, tonumber(orderId) })

    LDTaxi.Drivers.SetStatus(driverIdentifier, DriverStatus.EnRoute)
    LDTaxi.Orders.AddHistory(orderId, 'order.assigned', 'Auftrag zugewiesen', createdBy, { driver = driverIdentifier, driverName = driverName })
    LDTaxiEventBus.Emit('order.assigned', { orderId = tonumber(orderId), driver = driverIdentifier })

    return true, ('Auftrag #%s zugewiesen.'):format(orderId)
end

function LDTaxi.Orders.Accept(orderId, source)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    local order = LDTaxi.Orders.Get(orderId)
    if not order then return false, 'Auftrag nicht gefunden.' end
    if order.assigned_driver and order.assigned_driver ~= '' and order.assigned_driver ~= xPlayer.identifier then
        return false, 'Auftrag ist bereits vergeben.'
    end

    MySQL.update.await([[
        UPDATE ld_taxi_orders
        SET status = ?, assigned_driver = ?, assigned_driver_name = ?, updated_at = NOW()
        WHERE id = ?
    ]], { OrderStatus.Accepted, xPlayer.identifier, xPlayer.getName(), tonumber(orderId) })

    LDTaxi.Drivers.SetStatus(xPlayer.identifier, DriverStatus.EnRoute)
    LDTaxi.Orders.AddHistory(orderId, TaxiEvents.OrderAccepted, 'Auftrag angenommen', xPlayer.identifier)
    LDTaxiEventBus.Emit(TaxiEvents.OrderAccepted, { orderId = orderId, driver = xPlayer.identifier })

    return true, 'Auftrag angenommen.'
end

function LDTaxi.Orders.SetStatus(orderId, source, status, driverStatus, message)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    local order = LDTaxi.Orders.Get(orderId)
    if not order then return false, 'Auftrag nicht gefunden.' end
    if order.assigned_driver and order.assigned_driver ~= '' and order.assigned_driver ~= xPlayer.identifier then
        return false, 'Dieser Auftrag gehört einem anderen Fahrer.'
    end

    MySQL.update.await('UPDATE ld_taxi_orders SET status = ?, updated_at = NOW() WHERE id = ?', { status, tonumber(orderId) })

    if driverStatus then
        LDTaxi.Drivers.SetStatus(xPlayer.identifier, driverStatus)
    end

    LDTaxi.Orders.AddHistory(orderId, 'order.status_changed', message or status, xPlayer.identifier, { status = status })
    LDTaxiEventBus.Emit('order.status_changed', { orderId = orderId, status = status, driver = xPlayer.identifier })

    return true, message or 'Status geändert.'
end

function LDTaxi.Orders.Return(orderId, source, reason)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    MySQL.update.await([[
        UPDATE ld_taxi_orders
        SET status = ?, assigned_driver = NULL, assigned_driver_name = NULL, updated_at = NOW()
        WHERE id = ?
    ]], { OrderStatus.Returned, tonumber(orderId) })

    LDTaxi.Drivers.SetStatus(xPlayer.identifier, DriverStatus.Available)
    LDTaxi.Orders.AddHistory(orderId, TaxiEvents.OrderReturned, reason or 'Auftrag zurückgegeben', xPlayer.identifier)
    LDTaxiEventBus.Emit(TaxiEvents.OrderReturned, { orderId = orderId, driver = xPlayer.identifier, reason = reason or '' })

    return true, 'Auftrag an die Leitstelle zurückgegeben.'
end

function LDTaxi.Orders.NoShow(orderId, source, reason)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    local order = LDTaxi.Orders.Get(orderId)
    if not order then return false, 'Auftrag nicht gefunden.' end
    if order.assigned_driver and order.assigned_driver ~= '' and order.assigned_driver ~= xPlayer.identifier then
        return false, 'Dieser Auftrag gehört einem anderen Fahrer.'
    end

    MySQL.update.await([[
        UPDATE ld_taxi_orders
        SET status = 'cancelled', updated_at = NOW(), completed_at = NOW()
        WHERE id = ?
    ]], { tonumber(orderId) })

    LDTaxi.Drivers.SetStatus(xPlayer.identifier, DriverStatus.Available)
    LDTaxi.Orders.AddHistory(orderId, 'order.no_show', reason or 'Kein Fahrgast angetroffen', xPlayer.identifier)
    LDTaxiEventBus.Emit('order.no_show', { orderId = orderId, driver = xPlayer.identifier })

    return true, 'Auftrag gelöscht: kein Fahrgast angetroffen.'
end

function LDTaxi.Orders.Complete(orderId, source, distanceKm, chargedAmount, foodPaymentMethod)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    local order = LDTaxi.Orders.Get(orderId)
    if not order then return false, 'Auftrag nicht gefunden.' end

    local distance = tonumber(distanceKm) or 0
    local fare = LDTaxi.Utils.CalculateFare(distance)
    local foodCost = tonumber(order.food_cost) or 0
    local isFood = order.order_type == 'food' or order.order_type == 'delivery' or order.order_type == 'essen'
    local charged = tonumber(chargedAmount) or fare
    local minimum = fare + (isFood and foodCost or 0)
    if charged < minimum then charged = minimum end

    local tip = charged - fare
    local reimbursement = 0
    if isFood then
        tip = charged - fare - foodCost
        if tip < 0 then tip = 0 end
        if foodPaymentMethod == 'own_pocket' then
            reimbursement = foodCost
        else
            foodPaymentMethod = 'storage'
        end
    end

    if tip < 0 then tip = 0 end
    local totalPayout = tip + reimbursement

    MySQL.update.await([[
        UPDATE ld_taxi_orders
        SET status = ?, distance_km = ?, fare_amount = ?, charged_amount = ?, tip_amount = ?,
            food_payment_method = ?, expense_reimbursement = ?, total_payout = ?, updated_at = NOW(), completed_at = NOW()
        WHERE id = ?
    ]], { OrderStatus.Completed, distance, fare, charged, tip, foodPaymentMethod or '', reimbursement, totalPayout, tonumber(orderId) })

    MySQL.update.await([[
        UPDATE ld_taxi_drivers
        SET status = ?, total_orders = total_orders + 1, total_distance = total_distance + ?, last_order_at = NOW()
        WHERE identifier = ?
    ]], { DriverStatus.Available, distance, xPlayer.identifier })

    MySQL.insert.await([[
        INSERT INTO ld_taxi_finance_log (order_id, identifier, driver_name, distance_km, fare_amount, charged_amount, tip_amount, food_cost, expense_reimbursement, total_payout)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { tonumber(orderId), xPlayer.identifier, xPlayer.getName(), distance, fare, charged, tip, foodCost, reimbursement, totalPayout })

    if tip > 0 then
        MySQL.insert.await([[
            INSERT INTO ld_taxi_payouts (identifier, driver_name, amount, source_type, order_id, status)
            VALUES (?, ?, ?, 'tip', ?, 'open')
        ]], { xPlayer.identifier, xPlayer.getName(), tip, tonumber(orderId) })
    end

    if reimbursement > 0 then
        MySQL.insert.await([[
            INSERT INTO ld_taxi_payouts (identifier, driver_name, amount, source_type, order_id, status)
            VALUES (?, ?, ?, 'food_reimbursement', ?, 'open')
        ]], { xPlayer.identifier, xPlayer.getName(), reimbursement, tonumber(orderId) })
    end

    LDTaxi.Orders.AddHistory(orderId, TaxiEvents.OrderCompleted, 'Auftrag abgeschlossen', xPlayer.identifier, { fare = fare, charged = charged, tip = tip, foodCost = foodCost, reimbursement = reimbursement })
    LDTaxiEventBus.Emit(TaxiEvents.OrderCompleted, { orderId = orderId, driver = xPlayer.identifier, fare = fare, charged = charged, tip = tip, reimbursement = reimbursement })

    return true, ('Auftrag abgeschlossen. Fahrt: %s $, Rechnung: %s $, Trinkgeld: %s $, Erstattung: %s $'):format(fare, charged, tip, reimbursement)
end
