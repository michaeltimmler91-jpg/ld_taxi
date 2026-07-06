LDTaxi = LDTaxi or {}
LDTaxi.Blackboard = {}

local function PlayerName(source)
    local xPlayer = LDTaxi.Utils.Player(source)
    if not xPlayer then return '', '' end
    return xPlayer.identifier, xPlayer.getName()
end

local function IsManager(identifier)
    local row = MySQL.single.await('SELECT is_management FROM ld_taxi_drivers WHERE identifier = ?', { identifier })
    return row and tonumber(row.is_management) == 1
end

function LDTaxi.Blackboard.CanManage(source)
    local identifier = PlayerName(source)
    if identifier == '' then return false end
    if IsManager(identifier) then return true end
    local dispatchers = LDTaxi.Dispatch.GetActive()
    for _, dispatcher in ipairs(dispatchers or {}) do
        if dispatcher.identifier == identifier then return true end
    end
    return false
end

function LDTaxi.Blackboard.GetAll(forIdentifier)
    local posts = MySQL.query.await([[
        SELECT
            p.id,
            p.title,
            p.content,
            p.author_identifier,
            p.author_name,
            p.pinned,
            p.expires_at,
            p.created_at,
            p.updated_at,
            CASE WHEN r.id IS NULL THEN 0 ELSE 1 END AS is_read,
            r.read_at,
            (SELECT COUNT(*) FROM ld_taxi_blackboard_reads br WHERE br.post_id = p.id) AS read_count,
            (SELECT COUNT(*) FROM ld_taxi_drivers d WHERE d.status <> 'offline') AS driver_count
        FROM ld_taxi_blackboard_posts p
        LEFT JOIN ld_taxi_blackboard_reads r ON r.post_id = p.id AND r.identifier = ?
        WHERE p.deleted_at IS NULL
          AND (p.expires_at IS NULL OR p.expires_at > NOW())
        ORDER BY p.pinned DESC, p.created_at DESC
    ]], { forIdentifier or '' }) or {}

    return posts
end

function LDTaxi.Blackboard.GetReads(postId)
    return MySQL.query.await([[
        SELECT
            d.identifier,
            d.name,
            r.read_at
        FROM ld_taxi_drivers d
        LEFT JOIN ld_taxi_blackboard_reads r ON r.identifier = d.identifier AND r.post_id = ?
        WHERE d.status <> 'offline'
        ORDER BY CASE WHEN r.id IS NULL THEN 1 ELSE 0 END, d.name ASC
    ]], { tonumber(postId) or 0 }) or {}
end

function LDTaxi.Blackboard.Create(source, data)
    if not LDTaxi.Blackboard.CanManage(source) then return false, 'Keine Berechtigung.' end
    local identifier, name = PlayerName(source)
    data = data or {}
    local title = tostring(data.title or '')
    local content = tostring(data.content or '')
    if title == '' then return false, 'Titel fehlt.' end
    if content == '' then return false, 'Text fehlt.' end

    local id = MySQL.insert.await([[
        INSERT INTO ld_taxi_blackboard_posts (title, content, author_identifier, author_name, pinned, expires_at)
        VALUES (?, ?, ?, ?, ?, NULL)
    ]], { title, content, identifier, name, data.pinned and 1 or 0 })

    return true, ('Beitrag #%s erstellt.'):format(id)
end

function LDTaxi.Blackboard.MarkRead(source, postId)
    local identifier, name = PlayerName(source)
    if identifier == '' then return false, 'Spieler nicht gefunden.' end
    MySQL.insert.await([[
        INSERT INTO ld_taxi_blackboard_reads (post_id, identifier, driver_name, read_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE read_at = NOW(), driver_name = VALUES(driver_name)
    ]], { tonumber(postId) or 0, identifier, name })
    return true, 'Als gelesen markiert.'
end

function LDTaxi.Blackboard.Delete(source, postId)
    if not LDTaxi.Blackboard.CanManage(source) then return false, 'Keine Berechtigung.' end
    MySQL.update.await('UPDATE ld_taxi_blackboard_posts SET deleted_at = NOW() WHERE id = ?', { tonumber(postId) or 0 })
    return true, 'Beitrag gelöscht.'
end

function LDTaxi.Blackboard.TogglePinned(source, postId)
    if not LDTaxi.Blackboard.CanManage(source) then return false, 'Keine Berechtigung.' end
    MySQL.update.await('UPDATE ld_taxi_blackboard_posts SET pinned = IF(pinned = 1, 0, 1), updated_at = NOW() WHERE id = ?', { tonumber(postId) or 0 })
    return true, 'Pin geändert.'
end
