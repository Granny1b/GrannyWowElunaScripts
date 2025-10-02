--[[ 
NPC: 600005 (Custom World Buff Vendor)
Realm: TrinityCore 3.3.5 + Eluna
Features:
- Gossip menu to apply classic world buffs:
  * Spirit of Zandalar (Zandalari buff)
  * Warchief's Blessing
  * Rallying Cry of the Dragonslayer
  * Darkmoon Faire 10% Damage
  * Darkmoon Faire 10% Intellect
  * Dire Maul buffs: Stamina, Attack Power, "Spell Power" (Slip'kik's Savvy = Spell Crit)
- "All Buffs" button to apply everything in one click
Notes:
- Blocks usage while the player is in combat.
- Uses AddAura for guaranteed application without visual cast time.
--]]

local NPC_ID = 600005

-- Spell IDs (3.3.5a)
local SPELLS = {
  ZANDALAR       = 24425, -- Spirit of Zandalar
  WARCHIEF       = 16609, -- Warchief's Blessing
  DRAGONSLAYER   = 22888, -- Rallying Cry of the Dragonslayer
  DMF_DAMAGE     = 23768, -- Sayge's Dark Fortune of Damage (+10% damage)
  DMF_INT        = 23766, -- Sayge's Dark Fortune of Intelligence (+10% Int)
  DM_STAMINA     = 22818, -- Mol'dar's Moxie (+15% Stamina)
  DM_ATTACKPOWER = 22817, -- Fengus' Ferocity (+200 AP)
  DM_SPELLPOWER  = 22820, -- Slip'kik's Savvy (+3% Spell Crit) - used as "spell power" buff
}

-- Gossip INTIDs
local MENU = {
  ROOT             = 1,
  ZANDALAR         = 10,
  WARCHIEF         = 11,
  DRAGONSLAYER     = 12,
  DMF_DAMAGE       = 13,
  DMF_INT          = 14,
  DM_STAMINA       = 15,
  DM_ATTACKPOWER   = 16,
  DM_SPELLPOWER    = 17,
  ALL              = 99,
}

local function addRootMenu(player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Zandalari buff (Spirit of Zandalar)", MENU.ROOT, MENU.ZANDALAR)
  player:GossipMenuAddItem(0, "Warchief's Blessing",                MENU.ROOT, MENU.WARCHIEF)
  player:GossipMenuAddItem(0, "Rallying Cry of the Dragonslayer",   MENU.ROOT, MENU.DRAGONSLAYER)
  player:GossipMenuAddItem(0, "Darkmoon Faire: +10% Damage",        MENU.ROOT, MENU.DMF_DAMAGE)
  player:GossipMenuAddItem(0, "Darkmoon Faire: +10% Intellect",     MENU.ROOT, MENU.DMF_INT)
  player:GossipMenuAddItem(0, "Dire Maul: +15% Stamina (Mol'dar)",  MENU.ROOT, MENU.DM_STAMINA)
  player:GossipMenuAddItem(0, "Dire Maul: +200 Attack Power (Fengus)", MENU.ROOT, MENU.DM_ATTACKPOWER)
  player:GossipMenuAddItem(0, "Dire Maul: Spell Crit (Slip'kik)",   MENU.ROOT, MENU.DM_SPELLPOWER)
  player:GossipMenuAddItem(0, "|TInterface/Icons/Spell_Holy_MagicalSentry:24|t Apply ALL buffs", MENU.ROOT, MENU.ALL)
  player:GossipSendMenu(1, creature)
end

local function tryBuff(player, spellId)
  -- Use AddAura for instant application.
  player:AddAura(spellId, player)
end

local function applyAll(player)
  for _, id in pairs(SPELLS) do
    tryBuff(player, id)
  end
end

local function OnGossipHello(event, player, creature)
  addRootMenu(player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
  if player:IsInCombat() then
    player:SendAreaTriggerMessage("You cannot receive buffs while in combat.")
    player:GossipComplete()
    return
  end

  if sender ~= MENU.ROOT then
    addRootMenu(player, creature)
    return
  end

  if intid == MENU.ZANDALAR then
    tryBuff(player, SPELLS.ZANDALAR)
    player:SendBroadcastMessage("Spirit of Zandalar applied.")
  elseif intid == MENU.WARCHIEF then
    tryBuff(player, SPELLS.WARCHIEF)
    player:SendBroadcastMessage("Warchief's Blessing applied.")
  elseif intid == MENU.DRAGONSLAYER then
    tryBuff(player, SPELLS.DRAGONSLAYER)
    player:SendBroadcastMessage("Rallying Cry of the Dragonslayer applied.")
  elseif intid == MENU.DMF_DAMAGE then
    tryBuff(player, SPELLS.DMF_DAMAGE)
    player:SendBroadcastMessage("Darkmoon Faire: +10% Damage applied.")
  elseif intid == MENU.DMF_INT then
    tryBuff(player, SPELLS.DMF_INT)
    player:SendBroadcastMessage("Darkmoon Faire: +10% Intellect applied.")
  elseif intid == MENU.DM_STAMINA then
    tryBuff(player, SPELLS.DM_STAMINA)
    player:SendBroadcastMessage("Dire Maul: Mol'dar's Moxie (+15% Stamina) applied.")
  elseif intid == MENU.DM_ATTACKPOWER then
    tryBuff(player, SPELLS.DM_ATTACKPOWER)
    player:SendBroadcastMessage("Dire Maul: Fengus' Ferocity (+200 AP) applied.")
  elseif intid == MENU.DM_SPELLPOWER then
    tryBuff(player, SPELLS.DM_SPELLPOWER)
    player:SendBroadcastMessage("Dire Maul: Slip'kik's Savvy (+spell crit) applied.")
  elseif intid == MENU.ALL then
    applyAll(player)
    player:SendBroadcastMessage("All selected world buffs applied.")
  end

  -- Return to the root menu for convenience
  addRootMenu(player, creature)
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
