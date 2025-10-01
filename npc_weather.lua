-- example_gossip_weather.lua
local NPC_ID = 600001

-- ===== Gossip Handlers =====
local function GossipHello(event, player, creature)
    -- make sure it can show gossip
    creature:SetNPCFlags(1)

    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "Clear skies", 0, 10)
    player:GossipMenuAddItem(0, "Rain (max)",  0, 11)
    player:GossipMenuAddItem(0, "Snow (max)",  0, 12)
    player:GossipMenuAddItem(0, "Storm (max)", 0, 13)
    player:GossipSendMenu(1, creature)
end

local function GossipSelect(event, player, creature, sender, intid, code)
    local zone = player:GetZoneId()
    local map  = player:GetMap()

    if intid == 10 then
        map:SetWeather(zone, 0, 0.0); creature:SendUnitSay("Skies cleared!", 0)
    elseif intid == 11 then
        map:SetWeather(zone, 1, 1.0); creature:SendUnitSay("Let it rain!", 0)
    elseif intid == 12 then
        map:SetWeather(zone, 2, 1.0); creature:SendUnitSay("Snow is falling!", 0)
    elseif intid == 13 then
        map:SetWeather(zone, 3, 1.0); creature:SendUnitSay("A storm gathers!", 0)
    end

    player:GossipComplete()
end

-- ===== Register AFTER functions exist =====
RegisterCreatureGossipEvent(NPC_ID, 1, GossipHello)  -- no parentheses!
RegisterCreatureGossipEvent(NPC_ID, 2, GossipSelect) -- no parentheses!
