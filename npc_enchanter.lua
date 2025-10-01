-- npc_enchanter_600002.lua

local NPC_ID = 600002

-- Ensure the NPC actually shows a gossip cursor / opens gossip
local NPC_FLAGS = {
  GOSSIP = 1, -- UNIT_NPC_FLAG_GOSSIP
}

local SLOT = {
  CHEST    = 4,
  WRIST    = 8,
  FEET     = 7,
  BACK     = 14,
  MAINHAND = 15,
}

local ITEM_CLASS_WEAPON = 2
local WEAPON_SUBCLASS = { AXE_1H=0, AXE_2H=1, MACE_1H=4, MACE_2H=5, POLEARM=6, SWORD_1H=7, SWORD_2H=8, STAFF=10, FIST=13, DAGGER=15 }
local INVTYPE = { WEAPON=13, ["2HWEAPON"]=17, WEAPONMAINHAND=21, WEAPONOFFHAND=22 }

-- DBC enchant IDs (verify with `.enchant perm <id>` and adjust if needed)
local ENCHANTS = {
  WEAPON = {
    { "Crusader",            1900, false, true  },
    { "Lifestealing",         805, false, true  },
    { "Fiery Weapon",         803, false, true  },
    { "+15 Agility (1H)",    2564, false, true  },
    { "+25 Agility (2H)",    1898, true,  false },
    { "+30 Intellect (1H)",   723, false, true  },
    { "+20 Spirit (1H)",      724, false, true  },
  },
  ARMOR = {
    CHEST  = { { "+100 Health", 66 }, { "+4 All Stats", 1891 }, },
    BRACER = { { "+9 Stamina", 1886 }, { "+7 Intellect", 1883 }, },
    BOOTS  = { { "Minor Speed", 911 }, { "+7 Agility", 1887 }, },
    CLOAK  = { { "+70 Armor", 848 }, { "+3 Agility", 849 }, },
  }
}

local function msg(player, text)
  player:SendNotification(text)
  player:SendBroadcastMessage("|cff00ff00[Enchanter]|r "..text)
end

local function isTwoHandWeapon(item)
  if not item then return false end
  local t = item:GetTemplate(); if not t then return false end
  if t:GetInventoryType() == INVTYPE["2HWEAPON"] then return true end
  if t:GetClass() == ITEM_CLASS_WEAPON then
    local s = t:GetSubClass()
    return (s == WEAPON_SUBCLASS.AXE_2H or s == WEAPON_SUBCLASS.MACE_2H
         or s == WEAPON_SUBCLASS.SWORD_2H or s == WEAPON_SUBCLASS.POLEARM
         or s == WEAPON_SUBCLASS.STAFF)
  end
  return false
end

local function isOneHandWeapon(item)
  if not item then return false end
  local t = item:GetTemplate(); if not t then return false end
  local inv = t:GetInventoryType()
  if inv == INVTYPE.WEAPON or inv == INVTYPE.WEAPONMAINHAND or inv == INVTYPE.WEAPONOFFHAND then return true end
  if t:GetClass() == ITEM_CLASS_WEAPON then
    local s = t:GetSubClass()
    return (s == WEAPON_SUBCLASS.AXE_1H or s == WEAPON_SUBCLASS.MACE_1H
         or s == WEAPON_SUBCLASS.SWORD_1H or s == WEAPON_SUBCLASS.DAGGER
         or s == WEAPON_SUBCLASS.FIST)
  end
  return false
end

local function applyEnchantToSlot(player, equipSlot, enchantId)
  local item = player:GetEquippedItemBySlot(equipSlot)
  if not item then msg(player, "No item equipped in the selected slot."); return false end
  item:ClearEnchantment(0)
  item:SetEnchantment(enchantId, 0)
  msg(player, ("Applied enchant ID %d to %s."):format(enchantId, item:GetItemLink()))
  return true
end

-- intid constants (we route ONLY on intid)
local I = {
  ROOT            = 1000,
  ENCHANTS        = 1100,
  WEAPON_MENU     = 1200,
  ARMOR_MENU      = 1300,
  ARMOR_CHEST     = 1310,
  ARMOR_BRACER    = 1320,
  ARMOR_BOOTS     = 1330,
  ARMOR_CLOAK     = 1340,
}

-- Build menus (sender always 0, route on intid)
local function RootMenu(player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Enchants", 0, I.ENCHANTS)
  player:GossipSendMenu(1, creature)
end

local function EnchantsMenu(player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Weapon", 0, I.WEAPON_MENU)
  player:GossipMenuAddItem(0, "Armor",  0, I.ARMOR_MENU)
  player:GossipMenuAddItem(0, "Back",   0, I.ROOT)
  player:GossipSendMenu(1, creature)
end

local function WeaponMenu(player, creature)
  player:GossipClearMenu()
  for idx, data in ipairs(ENCHANTS.WEAPON) do
    player:GossipMenuAddItem(0, data[1], 0, I.WEAPON_MENU + idx)
  end
  player:GossipMenuAddItem(0, "Back", 0, I.ENCHANTS)
  player:GossipSendMenu(1, creature)
end

local function ArmorMenu(player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Chest",  0, I.ARMOR_CHEST)
  player:GossipMenuAddItem(0, "Bracer", 0, I.ARMOR_BRACER)
  player:GossipMenuAddItem(0, "Boots",  0, I.ARMOR_BOOTS)
  player:GossipMenuAddItem(0, "Cloak",  0, I.ARMOR_CLOAK)
  player:GossipMenuAddItem(0, "Back",   0, I.ENCHANTS)
  player:GossipSendMenu(1, creature)
end

local function ArmorSubMenu(player, creature, list, baseIntid, backTo)
  player:GossipClearMenu()
  for idx, data in ipairs(list) do
    player:GossipMenuAddItem(0, data[1], 0, baseIntid + idx)
  end
  player:GossipMenuAddItem(0, "Back", 0, backTo)
  player:GossipSendMenu(1, creature)
end

-- Events
local function OnSpawn(event, creature)
  -- Force Gossip flag so right-click opens the menu
  creature:SetNPCFlags(creature:GetNPCFlags() | NPC_FLAGS.GOSSIP)
end

local function OnGossipHello(event, player, creature)
  RootMenu(player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
  if intid == I.ROOT then
    RootMenu(player, creature); return
  elseif intid == I.ENCHANTS then
    EnchantsMenu(player, creature); return
  elseif intid == I.WEAPON_MENU then
    WeaponMenu(player, creature); return
  elseif intid == I.ARMOR_MENU then
    ArmorMenu(player, creature); return
  end

  -- Weapon choices
  if intid > I.WEAPON_MENU and intid < I.ARMOR_MENU then
    local idx = intid - I.WEAPON_MENU
    local opt = ENCHANTS.WEAPON[idx]
    if not opt then player:GossipComplete(); return end
    local name, enchantId, needs2H, needs1H = table.unpack(opt)
    local mh = player:GetEquippedItemBySlot(SLOT.MAINHAND)
    if not mh then msg(player, "Equip a weapon in your main-hand first."); player:GossipComplete(); return end
    if needs2H and not isTwoHandWeapon(mh) then msg(player, ("'%s' requires a two-handed weapon."):format(name)); player:GossipComplete(); return end
    if needs1H and not isOneHandWeapon(mh) then msg(player, ("'%s' requires a one-handed weapon."):format(name)); player:GossipComplete(); return end
    applyEnchantToSlot(player, SLOT.MAINHAND, enchantId)
    player:GossipComplete(); return
  end

  -- Armor submenus
  if intid == I.ARMOR_CHEST  then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.CHEST,  I.ARMOR_CHEST,  I.ARMOR_MENU); return end
  if intid == I.ARMOR_BRACER then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.BRACER, I.ARMOR_BRACER, I.ARMOR_MENU); return end
  if intid == I.ARMOR_BOOTS  then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.BOOTS,  I.ARMOR_BOOTS,  I.ARMOR_MENU); return end
  if intid == I.ARMOR_CLOAK  then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.CLOAK,  I.ARMOR_CLOAK,  I.ARMOR_MENU); return end

  -- Armor apply
  if intid > I.ARMOR_CHEST and intid < I.ARMOR_BRACER then
    local idx = intid - I.ARMOR_CHEST;  local opt = ENCHANTS.ARMOR.CHEST[idx]
    if opt then applyEnchantToSlot(player, SLOT.CHEST, opt[2]) end; player:GossipComplete(); return
  end
  if intid > I.ARMOR_BRACER and intid < I.ARMOR_BOOTS then
    local idx = intid - I.ARMOR_BRACER; local opt = ENCHANTS.ARMOR.BRACER[idx]
    if opt then applyEnchantToSlot(player, SLOT.WRIST, opt[2]) end; player:GossipComplete(); return
  end
  if intid > I.ARMOR_BOOTS and intid < I.ARMOR_CLOAK then
    local idx = intid - I.ARMOR_BOOTS;  local opt = ENCHANTS.ARMOR.BOOTS[idx]
    if opt then applyEnchantToSlot(player, SLOT.FEET, opt[2]) end;  player:GossipComplete(); return
  end
  if intid > I.ARMOR_CLOAK and intid < I.ARMOR_CLOAK + 100 then
    local idx = intid - I.ARMOR_CLOAK;  local opt = ENCHANTS.ARMOR.CLOAK[idx]
    if opt then applyEnchantToSlot(player, SLOT.BACK, opt[2]) end;  player:GossipComplete(); return
  end

  player:GossipComplete()
end

RegisterCreatureEvent(NPC_ID, 5, OnSpawn) -- 5 = OnSpawn
RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
