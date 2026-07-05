LDTaxi = LDTaxi or {}
LDTaxi.Dispatch = {}

function LDTaxi.Dispatch.Take(source)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    local active = MySQL.query.await('SELECT * FROM ld_taxi_dispatchers WHERE active = 1 ORDER BY slot_number ASC')
    if #active >= Config.MaxDispatchers then
        return false, 'Es sind bereits zwei Leitstellen aktiv.'
    end

    local used = {}
    for _, row in ipairs(active) do used[row.slot_number] = true end
    local slot = used[1] and 2 or 1

    MySQL.insert.await([[
        INSERT INTO ld_taxi_dispatchers (identifier, name, slot_number, active)
        VALUES (?, ?, ?, 1)
    ]], {
        xPlayer.identifier,
        xPlayer.getName(),
        slot
    })

    LDTaxi.Drivers.SetStatus(xPlayer.identifier, DriverStatus.Dispatch)
    LDTaxiEventBus.Emit(TaxiEvents.DispatchStarted, { identifier = xPlayer.identifier, slot = slot })

    return true, ('Du bist jetzt Leitstelle LS%s.'):format(slot)
end

function LDTaxi.Dispatch.Leave(source)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    MySQL.update.await('UPDATE ld_taxi_dispatchers SET active = 0, ended_at = NOW() WHERE identifier = ? AND active = 1', {
        xPlayer.identifier
    })

    LDTaxi.Drivers.SetStatus(xPlayer.identifier, DriverStatus.Available)
    LDTaxiEventBus.Emit(TaxiEvents.DispatchEnded, { identifier = xPlayer.identifier })

    return true, 'Du hast die Leitstelle verlassen.'
end
