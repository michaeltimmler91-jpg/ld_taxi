LDTaxi = LDTaxi or {}
LDTaxi.Drivers = {}

function LDTaxi.Drivers.SetStatus(identifier, status)
    MySQL.update.await('UPDATE ld_taxi_drivers SET status = ? WHERE identifier = ?', {
        status,
        identifier
    })
end

function LDTaxi.Drivers.GetAll()
    return MySQL.query.await([[
        SELECT
            d.identifier,
            d.name,
            d.status,
            d.rank_label,
            d.is_management,
            d.last_login,
            d.total_orders,
            d.total_distance,
            d.total_duty_minutes,
            o.id AS current_order_id,
            o.status AS current_order_status,
            o.customer_name AS current_customer_name,
            o.pickup_label AS current_pickup_label,
            o.destination_label AS current_destination_label,
            CASE
                WHEN o.status = 'accepted' THEN 'Unterwegs zum Kunden'
                WHEN o.status = 'arrived' THEN 'Wartet auf Kunden'
                WHEN o.status = 'started' THEN 'Fahrgast an Bord'
                WHEN d.status = 'available' THEN 'Verfügbar'
                WHEN d.status = 'pause' THEN 'Pause'
                WHEN d.status = 'offline' THEN 'Offline'
                ELSE d.status
            END AS display_status
        FROM ld_taxi_drivers d
        LEFT JOIN ld_taxi_orders o
            ON o.assigned_driver = d.identifier
            AND o.status NOT IN ('completed', 'cancelled')
        ORDER BY FIELD(
            CASE
                WHEN o.status = 'accepted' THEN 'en_route'
                WHEN o.status = 'arrived' THEN 'arrived'
                WHEN o.status = 'started' THEN 'in_ride'
                ELSE d.status
            END,
            'available', 'dispatch', 'en_route', 'arrived', 'in_ride', 'delivery', 'pause', 'offline'
        ), d.name ASC
    ]])
end

function LDTaxi.Drivers.ClockIn(source)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false end

    MySQL.insert.await([[
        INSERT INTO ld_taxi_drivers (identifier, name, status, last_login)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE status = VALUES(status), last_login = NOW()
    ]], {
        xPlayer.identifier,
        xPlayer.getName(),
        DriverStatus.Available
    })

    MySQL.insert.await('INSERT INTO ld_taxi_duty_sessions (identifier) VALUES (?)', {
        xPlayer.identifier
    })

    LDTaxiEventBus.Emit(TaxiEvents.DriverClockedIn, {
        identifier = xPlayer.identifier,
        name = xPlayer.getName()
    })

    return true
end

function LDTaxi.Drivers.ClockOut(source)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false end

    LDTaxi.Drivers.SetStatus(xPlayer.identifier, DriverStatus.Offline)

    MySQL.update.await([[
        UPDATE ld_taxi_duty_sessions
        SET ended_at = NOW(), duration_minutes = TIMESTAMPDIFF(MINUTE, started_at, NOW())
        WHERE identifier = ? AND ended_at IS NULL
    ]], {
        xPlayer.identifier
    })

    LDTaxiEventBus.Emit(TaxiEvents.DriverClockedOut, {
        identifier = xPlayer.identifier
    })

    return true
end
