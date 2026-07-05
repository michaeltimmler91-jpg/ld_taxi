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
         destination_label, destination_x, destination_y, destination_z, note, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        data.createdBy or ''
    })

    LDTaxi.Orders.AddHistory(orderId, TaxiEvents.OrderCreated, 'Auftrag erstellt', data.createdBy)
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
