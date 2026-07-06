LDTaxiDB = {}

local function TryQuery(sql)
    local ok, err = pcall(function()
        MySQL.query.await(sql)
    end)
    if not ok then
        print(('^3[ld_taxi]^7 DB-Hinweis: %s'):format(tostring(err)))
    end
end

function LDTaxiDB.Init()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_events (
            id INT AUTO_INCREMENT PRIMARY KEY,
            event_name VARCHAR(100) NOT NULL,
            payload LONGTEXT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_drivers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(80) NOT NULL UNIQUE,
            name VARCHAR(100) NOT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'offline',
            rank_label VARCHAR(100) NULL,
            is_management TINYINT(1) NOT NULL DEFAULT 0,
            last_login DATETIME NULL,
            last_order_at DATETIME NULL,
            total_orders INT NOT NULL DEFAULT 0,
            total_distance DOUBLE NOT NULL DEFAULT 0,
            total_duty_minutes INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_duty_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(80) NOT NULL,
            started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            ended_at DATETIME NULL,
            duration_minutes INT NULL
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_dispatchers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(80) NOT NULL,
            name VARCHAR(100) NOT NULL,
            slot_number INT NOT NULL,
            active TINYINT(1) NOT NULL DEFAULT 1,
            started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            ended_at DATETIME NULL
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            order_type VARCHAR(50) NOT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'new',
            customer_name VARCHAR(100) NULL,
            customer_identifier VARCHAR(80) NULL,
            pickup_label VARCHAR(150) NULL,
            pickup_x DOUBLE NULL,
            pickup_y DOUBLE NULL,
            pickup_z DOUBLE NULL,
            destination_label VARCHAR(150) NULL,
            destination_x DOUBLE NULL,
            destination_y DOUBLE NULL,
            destination_z DOUBLE NULL,
            note TEXT NULL,
            food_cost INT NOT NULL DEFAULT 0,
            food_payment_method VARCHAR(50) NULL,
            expense_reimbursement INT NOT NULL DEFAULT 0,
            total_payout INT NOT NULL DEFAULT 0,
            assigned_driver VARCHAR(80) NULL,
            assigned_driver_name VARCHAR(100) NULL,
            distance_km DOUBLE NULL,
            fare_amount INT NOT NULL DEFAULT 0,
            charged_amount INT NOT NULL DEFAULT 0,
            tip_amount INT NOT NULL DEFAULT 0,
            created_by VARCHAR(80) NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NULL,
            completed_at DATETIME NULL
        )
    ]])

    TryQuery('ALTER TABLE ld_taxi_orders ADD COLUMN IF NOT EXISTS food_cost INT NOT NULL DEFAULT 0')
    TryQuery('ALTER TABLE ld_taxi_orders ADD COLUMN IF NOT EXISTS food_payment_method VARCHAR(50) NULL')
    TryQuery('ALTER TABLE ld_taxi_orders ADD COLUMN IF NOT EXISTS expense_reimbursement INT NOT NULL DEFAULT 0')
    TryQuery('ALTER TABLE ld_taxi_orders ADD COLUMN IF NOT EXISTS total_payout INT NOT NULL DEFAULT 0')

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_order_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            order_id INT NOT NULL,
            event_name VARCHAR(100) NOT NULL,
            message TEXT NULL,
            payload LONGTEXT NULL,
            created_by VARCHAR(80) NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_payouts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(80) NOT NULL,
            driver_name VARCHAR(100) NULL,
            amount INT NOT NULL DEFAULT 0,
            source_type VARCHAR(50) NOT NULL DEFAULT 'tip',
            order_id INT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'open',
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            paid_at DATETIME NULL
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_finance_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            order_id INT NULL,
            identifier VARCHAR(80) NULL,
            driver_name VARCHAR(100) NULL,
            distance_km DOUBLE NOT NULL DEFAULT 0,
            fare_amount INT NOT NULL DEFAULT 0,
            charged_amount INT NOT NULL DEFAULT 0,
            tip_amount INT NOT NULL DEFAULT 0,
            food_cost INT NOT NULL DEFAULT 0,
            expense_reimbursement INT NOT NULL DEFAULT 0,
            total_payout INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    TryQuery('ALTER TABLE ld_taxi_finance_log ADD COLUMN IF NOT EXISTS food_cost INT NOT NULL DEFAULT 0')
    TryQuery('ALTER TABLE ld_taxi_finance_log ADD COLUMN IF NOT EXISTS expense_reimbursement INT NOT NULL DEFAULT 0')
    TryQuery('ALTER TABLE ld_taxi_finance_log ADD COLUMN IF NOT EXISTS total_payout INT NOT NULL DEFAULT 0')

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_blackboard_posts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(150) NOT NULL,
            content TEXT NOT NULL,
            author_identifier VARCHAR(80) NULL,
            author_name VARCHAR(100) NULL,
            pinned TINYINT(1) NOT NULL DEFAULT 0,
            expires_at DATETIME NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NULL,
            deleted_at DATETIME NULL
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS ld_taxi_blackboard_reads (
            id INT AUTO_INCREMENT PRIMARY KEY,
            post_id INT NOT NULL,
            identifier VARCHAR(80) NOT NULL,
            driver_name VARCHAR(100) NULL,
            read_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_blackboard_read (post_id, identifier)
        )
    ]])

    print('^2[ld_taxi]^7 Datenbanktabellen geprüft/erstellt')
end
