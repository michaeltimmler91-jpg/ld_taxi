LDTaxiDB = {}

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

    print('^2[ld_taxi]^7 Datenbanktabellen geprüft/erstellt')
end
