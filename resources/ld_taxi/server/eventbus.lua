LDTaxiEventBus = {}

function LDTaxiEventBus.Emit(eventName, payload)
    eventName = tostring(eventName or 'unknown')
    payload = payload or {}

    if Config.Debug then
        print(('[ld_taxi:event] %s'):format(eventName))
    end

    local ok, encoded = pcall(json.encode, payload)
    if not ok or not encoded then encoded = '{}' end

    MySQL.query.await(
        'INSERT INTO ld_taxi_events (event_name, payload, created_at) VALUES (?, ?, NOW())',
        { eventName, encoded }
    )

    TriggerEvent('ld_taxi:event', eventName, payload)
end
