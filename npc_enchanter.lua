local NPC_ID = 600002

-- Equipment slots
local SLOT = { CHEST=4, WRIST=8, FEET=7, BACK=14, MAINHAND=15 }

-- Inventory types (for 1H/2H check)
local INVTYPE = {
  WEAPON         = 13,  -- 1H
  ["2HWEAPON"]   = 17,  -- 2H
  WEAPONMAINHAND = 21,  -- 1H MH-only
  WEAPONOFFHAND  = 22,  -- 1H OH-only
}

-- One iteration of "best-guess" enchant IDs for TC 3.3.5a.
-- If any don't apply, test with `.enchant perm <id>` and send me the working ID.
local ENCHANTS = {
  WEAPON = {
    -- { name, enchantId, only2H }
    { "Crusader",             1900, false },
    { "Lifestealing",          805, false },
    { "Fiery Weapon",          803, false },
    { "+15 Agility (1H)",     2564, false },
    { "+25 Agility (2H)",     1898, true  }, -- 2H-only
    { "+30 Intellect (1H)",    943, false }, -- some cores use 943 for +30 Int 1H
    { "+20 Spirit (1H)",       724, false },
  },
  ARMOR = {
    CHEST  = { { "+100 Health", 66 }, { "+4 All Stats", 1891 }, },
    BRACER = { { "+9 Stamina", 1886 }, { "+7 Intellect", 1883 }, },
    BOOTS  = { { "Minor Speed", 911 }, { "+7 Agility", 1887 }, },
    CLOAK  = { { "+70 Armor", 848 }, { "+3 Agility", 849 }, },
  }
}

local function msg(p, t)
  p:SendNotification(t)
  p:SendBroadcastMessage("|cff00ff00[Enchanter]|r "..t)
end

local function isTwoHandWeapon(item)
  if not item then return false end
  local inv = item:GetInventoryType()
  return inv == INVTYPE["2HWEAPON"]
end

local function applyEnchantToSlot(player, slot, enchantId)
  local item = player:GetEquippedItemBySlot(slot)
  if not item then msg(player, "No item equipped in the selected slot."); return false end
  item:ClearEnchantment(0)
  item:SetEnchantment(enchantId, 0)
  msg(player, ("Applied enchant ID %d to %s."):format(enchantId, item:GetItemLink()))
  return true
end

-- Gossip intids
local I = {
  ROOT=1000, ENCHANTS=1100, WEAPON_MENU=1200, ARMOR_MENU=1300,
  ARMOR_CHEST=1310, ARMOR_BRACER=1320, ARMOR_BOOTS=1330, ARMOR_CLOAK=1340,
}

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
  for idx, opt in ipairs(ENCHANTS.WEAPON) do
    player:GossipMenuAddItem(0, opt[1], 0, I.WEAPON_MENU + idx)
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
  for idx, opt in ipairs(list) do
    player:GossipMenuAddItem(0, opt[1], 0, baseIntid + idx)
  end
  player:GossipMenuAddItem(0, "Back", 0, backTo)
  player:GossipSendMenu(1, creature)
end

local function OnGossipHello(event, player, creature)
  RootMenu(player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
  if intid == I.ROOT        then RootMenu(player, creature); return end
  if intid == I.ENCHANTS    then EnchantsMenu(player, creature); return end
  if intid == I.WEAPON_MENU then WeaponMenu(player, creature); return end
  if intid == I.ARMOR_MENU  then ArmorMenu(player, creature); return end

  -- Weapon selections
  if intid > I.WEAPON_MENU and intid < I.ARMOR_MENU then
    local idx = intid - I.WEAPON_MENU
    local opt = ENCHANTS.WEAPON[idx]
    if not opt then player:GossipComplete(); return end

    local name, enchantId, only2H = opt[1], opt[2], opt[3]
    local mh = player:GetEquippedItemBySlot(SLOT.MAINHAND)
    if not mh then msg(player, "Equip a weapon in your main-hand first."); player:GossipComplete(); return end

    if only2H and not isTwoHandWeapon(mh) then
      msg(player, ("'%s' requires a two-handed weapon."):format(name))
      player:GossipComplete(); return
    end

    applyEnchantToSlot(player, SLOT.MAINHAND, enchantId)
    player:GossipComplete(); return
  end

  -- Armor submenus
  if intid == I.ARMOR_CHEST  then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.CHEST,  I.ARMOR_CHEST,  I.ARMOR_MENU); return end
  if intid == I.ARMOR_BRACER then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.BRACER, I.ARMOR_BRACER, I.ARMOR_MENU); return end
  if intid == I.ARMOR_BOOTS  then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.BOOTS,  I.ARMOR_BOOTS,  I.ARMOR_MENU); return end
  if intid == I.ARMOR_CLOAK  then ArmorSubMenu(player, creature, ENCHANTS.ARMOR.CLOAK,  I.ARMOR_CLOAK,  I.ARMOR_MENU); return end

  -- Armor applies
  if intid > I.ARMOR_CHEST and intid < I.ARMOR_BRACER then
    local opt = ENCHANTS.ARMOR.CHEST[intid - I.ARMOR_CHEST]
    if opt then applyEnchantToSlot(player, SLOT.CHEST, opt[2]) end
    player:GossipComplete(); return
  end
  if intid > I.ARMOR_BRACER and intid < I.ARMOR_BOOTS then
    local opt = ENCHANTS.ARMOR.BRACER[intid - I.ARMOR_BRACER]
    if opt then applyEnchantToSlot(player, SLOT.WRIST, opt[2]) end
    player:GossipComplete(); return
  end
  if intid > I.ARMOR_BOOTS and intid < I.ARMOR_CLOAK then
    local opt = ENCHANTS.ARMOR.BOOTS[intid - I.ARMOR_BOOTS]
    if opt then applyEnchantToSlot(player, SLOT.FEET, opt[2]) end
    player:GossipComplete(); return
  end
  if intid > I.ARMOR_CLOAK and intid < I.ARMOR_CLOAK + 100 then
    local opt = ENCHANTS.ARMOR.CLOAK[intid - I.ARMOR_CLOAK]
    if opt then applyEnchantToSlot(player, SLOT.BACK, opt[2]) end
    player:GossipComplete(); return
  end

  player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)