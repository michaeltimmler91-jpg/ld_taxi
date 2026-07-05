LDTaxi = LDTaxi or {}
LDTaxi.Utils = {}

function LDTaxi.Utils.Player(source)
    return ESX.GetPlayerFromId(source)
end

function LDTaxi.Utils.Identifier(source)
    local xPlayer = LDTaxi.Utils.Player(source)
    return xPlayer and xPlayer.identifier or nil
end

function LDTaxi.Utils.StartedKilometers(distance)
    local km = math.ceil(tonumber(distance) or 0)
    if km < 1 then km = 1 end
    return km
end

function LDTaxi.Utils.CalculateFare(distance)
    return LDTaxi.Utils.StartedKilometers(distance) * Config.PricePerStartedKm
end
