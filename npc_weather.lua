local NPC_ID = 600001

local function GossipHello(event, player, unit)
    unit:GossipClearMenu()
    unit:GossipMenuAddItem(0, "Clear skies", 0, 10)
    unit:GossipMenuAddItem(0, "Rain",       0, 11)
    unit:GossipMenuAddItem(0, "Snow",       0, 12)
    unit:GossipMenuAddItem(0, "Storm",      0, 13)
    unit:GossipSendMenu(1, player)
end

local function GossipSelect(event, player, unit, sender, intid, code)
    local zone = player:GetZoneId()
    if intid == 10 then SetWeather(zone, 0, 0.0); unit:SendUnitSay("Skies cleared!", 0)
    elseif intid == 11 then SetWeather(zone, 1, 1.0); unit:SendUnitSay("Let it rain!", 0)
    elseif intid == 12 then SetWeather(zone, 2, 1.0); unit:SendUnitSay("Snow is falling!", 0)
    elseif intid == 13 then SetWeather(zone, 3, 1.0); unit:SendUnitSay("A storm gathers!", 0)
    end
    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_ID, 1, GossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, GossipSelect)
