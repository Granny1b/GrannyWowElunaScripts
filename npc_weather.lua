-- npc_weather.lua
local NPC_ID = 600001

local function GossipHello(event, player, creature)
    creature:SetNPCFlags(1) -- make sure it has Gossip flag
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "Clear skies", 0, 10)
    player:GossipMenuAddItem(0, "Rain",       0, 11)
    player:GossipMenuAddItem(0, "Snow",       0, 12)
    player:GossipMenuAddItem(0, "Storm",      0, 13)
    player:GossipSendMenu(1, creature)
end

local function GossipSelect(event, player, creature, sender, intid, code)
    local zone = player:GetZoneId()
    local map  = player:GetMap()

    if intid == 10 then
        map:SetWeather(zone, 0, 0.0); creature:SendUnitSay("Skies cleared!", 0)    -- FINE
    elseif intid == 11 then
        map:SetWeather(zone, 1, 1.0); creature:SendUnitSay("Let it rain!", 0)      -- RAIN
    elseif intid == 12 then
        map:SetWeather(zone, 2, 1.0); creature:SendUnitSay("Snow is falling!", 0)  -- SNOW
    elseif intid == 13 then
        map:SetWeather(zone, 3, 1.0); creature:SendUnitSay("A storm gathers!", 0)  -- STORM
    end

    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_ID, 1, GossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, GossipSelect)
