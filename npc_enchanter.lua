--[[ 
NPC: 600001
Title: Simple Classic Enchant Vendor
Author: ChatGPT (Eluna)
Description:
  Gossip -> Enchants -> Weapon / Armor
  - Weapon enchants apply to MAIN-HAND.
  - Validates 1H vs 2H compatibility and gives user-friendly errors.
  - Armor enchants auto-target the correct equipped slot where sensible.

Drop into: lua_scripts/npc_enchanter_600001.lua
]]--

local NPC_ID = 600002

-- Inventory slot constants (0-based, WotLK)
local SLOT = {
  HEAD      = 0,
  NECK      = 1,
  SHOULDER  = 2,
  SHIRT     = 3,
  CHEST     = 4,
  WAIST     = 5,
  LEGS      = 6,
  FEET      = 7,
  WRIST     = 8,
  HANDS     = 9,
  FINGER1   = 10,
  FINGER2   = 11,
  TRINKET1  = 12,
  TRINKET2  = 13,
  BACK      = 14,
  MAINHAND  = 15,
  OFFHAND   = 16,
  RANGED    = 17,
  TABARD    = 18,
}

-- Item class/subclass for weapons (DBC standard for 3.3.5)
local ITEM_CLASS_WEAPON = 2
-- Weapon subclasses (not exhaustive; enough for classic styles)
local WEAPON_SUBCLASS = {
  AXE_1H     = 0,
  AXE_2H     = 1,
  BOW        = 2,
  GUN        = 3,
  MACE_1H    = 4,
  MACE_2H    = 5,
  POLEARM    = 6,
  SWORD_1H   = 7,
  SWORD_2H   = 8,
  STAFF      = 10,
  FIST       = 13,
  DAGGER     = 15,
}

-- Inventory types (DBC) used to distinguish 1H vs 2H
local INVTYPE = {
  WEAPON           = 13, -- 1H
  SHIELD           = 14,
  RANGED           = 15,
  2HWEAPON         = 17,
  WEAPONMAINHAND   = 21, -- 1H MH-only
  WEAPONOFFHAND    = 22, -- 1H OH-only
  HOLDABLE         = 23, -- off-hand frills
}

--[[ 
IMPORTANT: ENCHANT IDs BELOW ARE SpellItemEnchantment.dbc IDs (NOT spell IDs).
Confirm on your core with `.enchant perm <id>`. Replace if needed.
]]--

local ENCHANTS = {
  -- Weapon (classic/high-end)
  WEAPON = {
    -- name, enchantId, requiresTwoHand (true/false), requiresOneHand (true/false)
    {"Crusader",           1900, false, true},   -- Classic 1H
    {"Lifestealing",        805, false, true},   -- 1H
    {"Fiery Weapon",        803, false, true},   -- 1H
    {"+15 Agility (1H)",   2564, false, true},
    {"+25 Agility (2H)",   1898, true,  false},  -- 2H
    {"+30 Intellect (1H)",  723, false, true},   -- swap if different on your core
    {"+20 Spirit (1H)",     724, false, true},   -- swap if different on your core
  },

  -- Armor examples (feel free to add more)
  ARMOR = {
    CHEST = {
      {"+100 Health", 66}, -- chest hp
      {"+4 All Stats", 1891},
    },
    BRACER = {
      {"+9 Stamina", 1886},
      {"+7 Intellect", 1883},
    },
    BOOTS = {
      {"Minor Speed", 911},
      {"+7 Agility", 1887},
    },
    CLOAK = {
      {"+70 Armor", 848},
      {"+3 Agility", 849},
    },
  }
}

-- Small helpers for messages
local function msg(player, text)
  player:SendNotification(text) -- small popup
  player:SendBroadcastMessage("|cff00ff00[Enchanter]|r "..text) -- chat line
end

-- Determine if a weapon is 2H by InventoryType or SubClass
local function isTwoHandWeapon(item)
  if not item then return false end
  local tmpl = item:GetTemplate()
  if not tmpl then return false end

  local invType = tmpl:GetInventoryType()
  if invType == INVTYPE["2HWEAPON"] then
    return true
  end

  -- Fallback via subclass (covers polearm/staff labeled WEAPON sometimes)
  local class  = tmpl:GetClass()
  local sub    = tmpl:GetSubClass()
  if class == ITEM_CLASS_WEAPON then
    if sub == WEAPON_SUBCLASS.AXE_2H
    or sub == WEAPON_SUBCLASS.MACE_2H
    or sub == WEAPON_SUBCLASS.SWORD_2H
    or sub == WEAPON_SUBCLASS.POLEARM
    or sub == WEAPON_SUBCLASS.STAFF
    then
      return true
    end
  end
  return false
end

local function isOneHandWeapon(item)
  if not item then return false end
  local tmpl = item:GetTemplate()
  if not tmpl then return false end

  local invType = tmpl:GetInventoryType()
  -- 1H types
  if invType == INVTYPE.WEAPON or invType == INVTYPE.WEAPONMAINHAND or invType == INVTYPE.WEAPONOFFHAND then
    return true
  end

  -- Fallback: subclass check for common 1H
  local class  = tmpl:GetClass()
  local sub    = tmpl:GetSubClass()
  if class == ITEM_CLASS_WEAPON then
    if sub == WEAPON_SUBCLASS.AXE_1H
    or sub == WEAPON_SUBCLASS.MACE_1H
    or sub == WEAPON_SUBCLASS.SWORD_1H
    or sub == WEAPON_SUBCLASS.DAGGER
    or sub == WEAPON_SUBCLASS.FIST
    then
      return true
    end
  end
  return false
end

-- Apply permanent enchant to an equipped item (slot)
local function applyEnchantToSlot(player, equipSlot, enchantId)
  local item = player:GetEquippedItemBySlot(equipSlot)
  if not item then
    msg(player, "No item equipped in the selected slot.")
    return false
  end

  -- Clear existing permanent enchant (index 0) then set new one
  item:ClearEnchantment(0)
  item:SetEnchantment(enchantId, 0) -- (enchantId, slotIndex0)
  msg(player, string.format("Applied enchant ID %d to %s.", enchantId, item:GetItemLink()))
  return true
end

-- Gossip constants / intids
local GOSSIP_MAIN        = 1000
local GOSSIP_ENCHANTS    = 1100
local GOSSIP_WEAPON      = 1200
local GOSSIP_ARMOR       = 1300

local GOSSIP_ARMOR_CHEST = 1310
local GOSSIP_ARMOR_BRACER= 1320
local GOSSIP_ARMOR_BOOTS = 1330
local GOSSIP_ARMOR_CLOAK = 1340

-- Build menus
local function SendRootMenu(player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Enchants", GOSSIP_ENCHANTS, 0)
  player:GossipSendMenu(1, creature)
end

local function SendEnchantsMenu(player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Weapon", GOSSIP_WEAPON, 0)
  player:GossipMenuAddItem(0, "Armor",  GOSSIP_ARMOR,  0)
  player:GossipMenuAddItem(0, "Back",   GOSSIP_MAIN,   0)
  player:GossipSendMenu(1, creature)
end

local function SendWeaponMenu(player, creature)
  player:GossipClearMenu()
  for i, data in ipairs(ENCHANTS.WEAPON) do
    local name = data[1]
    local intid = GOSSIP_WEAPON + i -- unique per option
    player:GossipMenuAddItem(0, name, intid, 0)
  end
  player:GossipMenuAddItem(0, "Back", GOSSIP_ENCHANTS, 0)
  player:GossipSendMenu(1, creature)
end

local function SendArmorMenu(player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Chest",  GOSSIP_ARMOR_CHEST,  0)
  player:GossipMenuAddItem(0, "Bracer", GOSSIP_ARMOR_BRACER, 0)
  player:GossipMenuAddItem(0, "Boots",  GOSSIP_ARMOR_BOOTS,  0)
  player:GossipMenuAddItem(0, "Cloak",  GOSSIP_ARMOR_CLOAK,  0)
  player:GossipMenuAddItem(0, "Back",   GOSSIP_ENCHANTS,     0)
  player:GossipSendMenu(1, creature)
end

local function SendArmorSubMenu(player, creature, list, backIntid)
  player:GossipClearMenu()
  for i, data in ipairs(list) do
    local name = data[1]
    local intid = backIntid + i -- unique per group
    player:GossipMenuAddItem(0, name, intid, 0)
  end
  player:GossipMenuAddItem(0, "Back", GOSSIP_ARMOR, 0)
  player:GossipSendMenu(1, creature)
end

-- GOSSIP HANDLERS
local function OnGossipHello(event, player, creature)
  SendRootMenu(player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
  -- Main navigation
  if intid == GOSSIP_MAIN then
    SendRootMenu(player, creature)
    return
  elseif intid == GOSSIP_ENCHANTS then
    SendEnchantsMenu(player, creature)
    return
  elseif intid == GOSSIP_WEAPON then
    SendWeaponMenu(player, creature)
    return
  elseif intid == GOSSIP_ARMOR then
    SendArmorMenu(player, creature)
    return
  end

  -- Weapon selections
  if intid > GOSSIP_WEAPON and intid < GOSSIP_ARMOR then
    local index = intid - GOSSIP_WEAPON
    local opt = ENCHANTS.WEAPON[index]
    if not opt then
      msg(player, "Invalid selection.")
      player:GossipComplete()
      return
    end

    local name, enchantId, needs2H, needs1H = table.unpack(opt)
    local mh = player:GetEquippedItemBySlot(SLOT.MAINHAND)
    if not mh then
      msg(player, "Equip a weapon in your main-hand first.")
      player:GossipComplete()
      return
    end

    -- Validate 1H/2H compatibility if flagged
    if needs2H and not isTwoHandWeapon(mh) then
      msg(player, string.format("'%s' requires a two-handed weapon in main-hand.", name))
      player:GossipComplete()
      return
    end
    if needs1H and not isOneHandWeapon(mh) then
      msg(player, string.format("'%s' requires a one-handed weapon in main-hand.", name))
      player:GossipComplete()
      return
    end

    if applyEnchantToSlot(player, SLOT.MAINHAND, enchantId) then
      -- success message is inside applyEnchantToSlot
    else
      msg(player, "Failed to apply weapon enchant.")
    end
    player:GossipComplete()
    return
  end

  -- Armor branching
  if intid == GOSSIP_ARMOR_CHEST then
    SendArmorSubMenu(player, creature, ENCHANTS.ARMOR.CHEST, GOSSIP_ARMOR_CHEST)
    return
  elseif intid == GOSSIP_ARMOR_BRACER then
    SendArmorSubMenu(player, creature, ENCHANTS.ARMOR.BRACER, GOSSIP_ARMOR_BRACER)
    return
  elseif intid == GOSSIP_ARMOR_BOOTS then
    SendArmorSubMenu(player, creature, ENCHANTS.ARMOR.BOOTS, GOSSIP_ARMOR_BOOTS)
    return
  elseif intid == GOSSIP_ARMOR_CLOAK then
    SendArmorSubMenu(player, creature, ENCHANTS.ARMOR.CLOAK, GOSSIP_ARMOR_CLOAK)
    return
  end

  -- Armor final apply (Chest)
  if intid > GOSSIP_ARMOR_CHEST and intid < GOSSIP_ARMOR_BRACER then
    local index = intid - GOSSIP_ARMOR_CHEST
    local opt = ENCHANTS.ARMOR.CHEST[index]
    if opt then
      local _, enchantId = table.unpack(opt)
      if applyEnchantToSlot(player, SLOT.CHEST, enchantId) then end
    else
      msg(player, "Invalid chest enchant selection.")
    end
    player:GossipComplete()
    return
  end

  -- Armor final apply (Bracer)
  if intid > GOSSIP_ARMOR_BRACER and intid < GOSSIP_ARMOR_BOOTS then
    local index = intid - GOSSIP_ARMOR_BRACER
    local opt = ENCHANTS.ARMOR.BRACER[index]
    if opt then
      local _, enchantId = table.unpack(opt)
      if applyEnchantToSlot(player, SLOT.WRIST, enchantId) then end
    else
      msg(player, "Invalid bracer enchant selection.")
    end
    player:GossipComplete()
    return
  end

  -- Armor final apply (Boots)
  if intid > GOSSIP_ARMOR_BOOTS and intid < GOSSIP_ARMOR_CLOAK then
    local index = intid - GOSSIP_ARMOR_BOOTS
    local opt = ENCHANTS.ARMOR.BOOTS[index]
    if opt then
      local _, enchantId = table.unpack(opt)
      if applyEnchantToSlot(player, SLOT.FEET, enchantId) then end
    else
      msg(player, "Invalid boots enchant selection.")
    end
    player:GossipComplete()
    return
  end

  -- Armor final apply (Cloak)
  if intid > GOSSIP_ARMOR_CLOAK and intid < (GOSSIP_ARMOR_CLOAK + 100) then
    local index = intid - GOSSIP_ARMOR_CLOAK
    local opt = ENCHANTS.ARMOR.CLOAK[index]
    if opt then
      local _, enchantId = table.unpack(opt)
      if applyEnchantToSlot(player, SLOT.BACK, enchantId) then end
    else
      msg(player, "Invalid cloak enchant selection.")
    end
    player:GossipComplete()
    return
  end

  -- Fallback
  player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
