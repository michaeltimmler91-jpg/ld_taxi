LDTaxi = LDTaxi or {}
LDTaxi.Finance = {}

function LDTaxi.Finance.GetSummary()
    local today = MySQL.single.await([[
        SELECT
            COALESCE(SUM(charged_amount), 0) AS revenue,
            COALESCE(SUM(fare_amount), 0) AS fare,
            COALESCE(SUM(tip_amount), 0) AS tips,
            COALESCE(SUM(distance_km), 0) AS distance,
            COUNT(*) AS rides
        FROM ld_taxi_finance_log
        WHERE DATE(created_at) = CURDATE()
    ]]) or {}

    local openTips = MySQL.single.await([[
        SELECT COALESCE(SUM(amount), 0) AS amount, COUNT(*) AS count
        FROM ld_taxi_payouts
        WHERE status = 'open'
    ]]) or {}

    local lastRides = MySQL.query.await([[
        SELECT order_id, driver_name, distance_km, fare_amount, charged_amount, tip_amount, created_at
        FROM ld_taxi_finance_log
        ORDER BY created_at DESC
        LIMIT 10
    ]]) or {}

    local payouts = MySQL.query.await([[
        SELECT identifier, driver_name, COALESCE(SUM(amount), 0) AS amount, COUNT(*) AS count
        FROM ld_taxi_payouts
        WHERE status = 'open'
        GROUP BY identifier, driver_name
        ORDER BY amount DESC
    ]]) or {}

    return {
        today = today,
        openTips = openTips,
        lastRides = lastRides,
        payouts = payouts
    }
end

function LDTaxi.Finance.MarkPaid(identifier)
    if not identifier or identifier == '' then return false end

    MySQL.update.await([[
        UPDATE ld_taxi_payouts
        SET status = 'paid', paid_at = NOW()
        WHERE identifier = ? AND status = 'open'
    ]], { identifier })

    return true
end
