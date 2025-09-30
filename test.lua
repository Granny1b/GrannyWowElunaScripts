local function OnLogin(event, player)
    player:SendBroadcastMessage("Eluna is working! Hello, " .. player:GetName() .. "!")
end

RegisterPlayerEvent(3, OnLogin)  -- Event 3: PLAYER_EVENT_ON_LOGIN