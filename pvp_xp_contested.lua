--------------------------------------------------------------------------------
-- PvP XP in Contested Zones + Group XP + Token Reward (No BG/Arena)
-- TrinityCore 3.3.5a + Eluna
--------------------------------------------------------------------------------

-------------------------
-- CONFIGURATION
-------------------------

local DEBUG = true

-- Treat these Zone IDs as "contested". Add/remove as you like (.gps to find ZoneId).
local CONTESTED_ZONES = {
  [33]=true,[45]=true,[36]=true,[406]=true,[440]=true,[16]=true,[15]=true,[47]=true,
  [28]=true,[139]=true,[3520]=true,[3518]=true,[495]=true,[3537]=true,[66]=true,[3711]=true,
}

-- XP per killer level bracket
local LEVEL_BRACKETS = {
  { min=1,  max=19, xp=  250 },
  { min=20, max=29, xp=  400 },
  { min=30, max=39, xp=  600 },
  { min=40, max=49, xp=  900 },
  { min=50, max=59, xp= 1200 },
  { min=60, max=69, xp= 1600 },
  { min=70, max=79, xp= 2200 },
  { min=80, max=80, xp=    0 }, -- No XP at max level (edit if custom cap)
}

-- Level diff cap (no XP/token if abs(level_killer - level_victim) > cap)
local MAX_LEVEL_DIFF = 5

-- Anti-farm per recipient+victim pair (seconds)
local RECENT_KILL_COOLDOWN = 300 -- 5 minutes

-- Realm max level
local MAX_PLAYER_LEVEL = 80

-- TOKEN REWARD
local ITEM_REWARD_ID      = 602001  -- your custom currency token
local ITEM_REWARD_COUNT   = 1       -- how many per valid kill
local GIVE_TOKEN_TO_GROUP = false   -- if true: every eligible group member also gets a token

-- Group XP range (yards). Members must be within this distance of the killer to get XP.
local GROUP_XP_RANGE = 100

-- Toggle chat messages
local NOTIFY_ON_REWARD  = true
local NOTIFY_ON_NO_BAG  = true


-------------------------
-- INTERNAL STATE
-------------------------

-- recentKills[recipientGUIDLow][victimGUIDLow] = lastKillTime
local recentKills = {}

local function CleanRecentKills(now)
  for rGUID, victims in pairs(recentKills) do
    for vGUID, t in pairs(victims) do
      if now - t > (RECENT_KILL_COOLDOWN * 3) then
        victims[vGUID] = nil
      end
    end
    if next(victims) == nil then
      recentKills[rGUID] = nil
    end
  end
end


-------------------------
-- HELPERS
-------------------------

local function IsInContestedZone(player)
  return CONTESTED_ZONES[player:GetZoneId()] == true
end

-- Skip rewards inside BGs and Arenas
local function IsInBGorArena(player)
  local map = player:GetMap()
  if not map then return false end
  if map:IsBattleground() then return true end
  if map:IsArena() then return true end
  return false
end

local function GetBracketXP(level)
  for _, b in ipairs(LEVEL_BRACKETS) do
    if level >= b.min and level <= b.max then
      return b.xp
    end
  end
  return 0
end

local function WithinLevelDiffCap(aLvl, bLvl)
  return math.abs(aLvl - bLvl) <= MAX_LEVEL_DIFF
end

local function IsMaxLevel(player)
  return player:GetLevel() >= MAX_PLAYER_LEVEL
end

local function RecentlyFarmed(recipient, victim, now)
  local rGUID = recipient:GetGUIDLow()
  local vGUID = victim:GetGUIDLow()
  local rv = recentKills[rGUID]
  if not rv then return false end
  local last = rv[vGUID]
  return last and ((now - last) < RECENT_KILL_COOLDOWN) or false
end

local function NoteKill(recipient, victim, now)
  local rGUID = recipient:GetGUIDLow()
  local vGUID = victim:GetGUIDLow()
  recentKills[rGUID] = recentKills[rGUID] or {}
  recentKills[rGUID][vGUID] = now
end

local function InRangeForGroupXP(member, killer)
  -- Basic distance check; adjust GROUP_XP_RANGE to taste
  local dist = member:GetDistance(killer)
  return dist and dist <= GROUP_XP_RANGE
end

local function DebugMsg(player, msg)
    if DEBUG and player then
        player:SendBroadcastMessage("|cffff8800[DEBUG]|r "..msg)
    end
end

-------------------------
-- REWARD CORE
-------------------------

local function TryRewardRecipient(recipient, victim, baseZoneId, isKiller)
    if not recipient or not recipient:IsPlayer() then return end

    DebugMsg(recipient, string.format("Checking reward for %s (killer=%s). Victim=%s",
        recipient:GetName(),
        tostring(isKiller),
        victim:GetName()))

    if IsMaxLevel(recipient) then
        DebugMsg(recipient, "No XP: player is max level")
        return
    end

    if recipient:GetZoneId() ~= baseZoneId then
        DebugMsg(recipient, "No XP: not in same zone as killer")
        return
    end

    if not IsInContestedZone(recipient) then
        DebugMsg(recipient, "No XP: not in contested zone")
        return
    end

    local now = os.time()
    if RecentlyFarmed(recipient, victim, now) then
        DebugMsg(recipient, "No XP: farm protection triggered")
        return
    end

    local rLvl = recipient:GetLevel()
    local vLvl = victim:GetLevel()
    if not WithinLevelDiffCap(rLvl, vLvl) then
        DebugMsg(recipient, "No XP: level gap too large")
        return
    end

    local baseXP = GetBracketXP(rLvl)
    if baseXP <= 0 then
        DebugMsg(recipient, "No XP: bracket gave 0 XP")
        return
    end

    local diff   = vLvl - rLvl
    local factor = 1.0 + (0.10 * diff)
    if factor < 0.5 then factor = 0.5 end
    if factor > 1.5 then factor = 1.5 end
    local grant  = math.floor(baseXP * factor)

    -- Actually give XP
    recipient:GiveXP(grant, victim)
    DebugMsg(recipient, string.format("Gained %d XP from killing %s", grant, victim:GetName()))

    -- Token only for killer (or group if enabled)
    if isKiller or GIVE_TOKEN_TO_GROUP then
        local added = recipient:AddItem(ITEM_REWARD_ID, ITEM_REWARD_COUNT)
        if added then
            DebugMsg(recipient, string.format("Received token itemID=%d x%d", ITEM_REWARD_ID, ITEM_REWARD_COUNT))
        else
            DebugMsg(recipient, "Inventory full, token not added")
        end
    end

    NoteKill(recipient, victim, now)
    if (now % 61) == 0 then CleanRecentKills(now) end
end


-------------------------
-- EVENT HANDLER
-------------------------

local function OnKillPlayer(event, killer, victim)
  if not killer or not victim then return end
  if not killer:IsPlayer() or not victim:IsPlayer() then return end

  -- No rewards inside BGs or Arenas
  if IsInBGorArena(killer) then return end

  -- Kill must occur in a contested zone (killer's zone as reference)
  if not IsInContestedZone(killer) then return end

  local zoneIdAtKill = killer:GetZoneId()
  if zoneIdAtKill ~= victim:GetZoneId() then return end

  -- Collect recipients: killer + nearby group members
  local recipients = { {p=killer, isKiller=true} }

  local group = killer:GetGroup()
  if group then
    for _, member in ipairs(group:GetMembers()) do
      if member and member:IsPlayer() and member ~= killer then
        if member:IsInWorld() and killer:IsInWorld() and member:GetMapId() == killer:GetMapId() then
          if InRangeForGroupXP(member, killer) then
            table.insert(recipients, {p=member, isKiller=false})
          end
        end
      end
    end
  end

  -- Reward pass
  for _, entry in ipairs(recipients) do
    TryRewardRecipient(entry.p, victim, zoneIdAtKill, entry.isKiller)
  end
end


---------------------------------
-- EVENT REGISTRATION
---------------------------------
-- 6 = PLAYER_EVENT_ON_KILL_PLAYER for Eluna 3.3.5a (adjust if different)
RegisterPlayerEvent(6, OnKillPlayer)
