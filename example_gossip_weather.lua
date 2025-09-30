local NpcId = 600001

local function OnHello(event, player, creature)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "Test Weather", 0, 1)
    player:GossipMenuAddItem(0, "Nevermind..", 0, 2)
    player:GossipSendMenu(1, creature)
end

local function OnSelect(event, player, creature, sender, intid, code)
    if intid == 1 then
        local zone = player:GetZoneId()
        creature:GetMap():SetWeather(zone, math.random(0, 3), 1.0)
    end
    player:GossipComplete()
end

RegisterCreatureGossipEvent(NpcId, 1, OnHello)   -- OnHello
RegisterCreatureGossipEvent(NpcId, 2, OnSelect)  -- OnSelect