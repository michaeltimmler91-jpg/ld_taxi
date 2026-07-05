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
        SELECT identifier, name, status, rank_label, is_management, last_login, total_orders, total_distance, total_duty_minutes
        FROM ld_taxi_drivers
        ORDER BY FIELD(status, 'dispatch', 'available', 'assigned', 'en_route', 'arrived', 'in_ride', 'delivery', 'pause', 'offline'), name ASC
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
