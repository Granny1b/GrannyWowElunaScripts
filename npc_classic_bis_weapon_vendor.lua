--[[
  NPC: 600004  (Classic Weapon Vendor, simplified)
  Flow: Choose Category -> Pick Item -> Add to bags
  Categories: 1H, 2H, Off-hand/Shield, Ranged (bows/guns/wands)
  Add/remove items easily in WEAPON_LISTS.
--]]

local NPC_ID = 600004

local SENDER_CAT   = 100
local SENDER_ITEM  = 200
local BACK_CATS    = 9001

-- categories
local CAT_ORDER = { "ONE_HAND","TWO_HAND","OFFHAND_SHIELD","RANGED" }
local CAT_LABEL = {
  ONE_HAND      = "Weapon — 1H",
  TWO_HAND      = "Weapon — 2H",
  OFFHAND_SHIELD= "Off-hand / Shield",
  RANGED        = "Ranged (Bow/Gun/Wand)",
}
local CAT_KEY_TO_ID, CAT_ID_TO_KEY = {}, {}
for i, key in ipairs(CAT_ORDER) do CAT_KEY_TO_ID[key]=i; CAT_ID_TO_KEY[i]=key end

-- Example lists (level 60 iconic picks). Extend freely.
local WEAPON_LISTS = {
  ONE_HAND = {
    {id=18816, name="Perdition's Blade"},            -- Rogue/Dagger
    {id=19352, name="Chromatically Tempered Sword"}, -- 1H Sword
    {id=17103, name="Azuresong Mageblade"},          -- Caster 1H
    {id=19362, name="Doom's Edge"},                  -- Axe 1H
    {id=19363, name="Crul'shorukh, Edge of Chaos"},  -- Sword 1H
  },
  TWO_HAND = {
    {id=19364, name="Ashkandi, Greatsword of the Brotherhood"},
    {id=17182, name="Sulfuras, Hand of Ragnaros"},
    {id=18803, name="Finkle's Lava Dredger"},
    {id=19357, name="Herald of Woe"},                -- 2H Mace
    {id=19019, name="Thunderfury, Blessed Blade of the Windseeker"}, -- still 1H, but often featured; keep if desired or move
  },
  OFFHAND_SHIELD = {
    {id=19349, name="Elementium Reinforced Bulwark"}, -- Shield
    {id=17066, name="Drillborer Disk"},               -- Shield
    {id=19366, name="Master Dragonslayer's Orb"},     -- Off-hand
    {id=17105, name="Aurastone Hammer"},              -- 1H Mace (alt offhand choice if desired)
  },
  RANGED = {
    {id=19361, name="Ashjre'thul, Crossbow of Smiting"}, -- Crossbow
    {id=18713, name="Rhok'delar, Longbow of the Ancient Keepers"}, -- Bow
    {id=18714, name="Ancient Sinew Wrapped Lamina"}, -- (quiver, showcase - optional)
    {id=19350, name="Heartstriker"},                 -- Bow
    {id=19130, name="Cold Snap"},                    -- Wand
    {id=19108, name="Wand of Biting Cold"},         -- Wand
    {id=19368, name="Dragonbreath Hand Cannon"},     -- Gun
  },
}

local function SendCategoryMenu(player, creature)
  player:GossipClearMenu()
  for i, key in ipairs(CAT_ORDER) do
    player:GossipMenuAddItem(0, CAT_LABEL[key], SENDER_CAT, i)
  end
  player:GossipSendMenu(1, creature)
end

local function SendItemMenu(player, creature, catKey)
  player:GossipClearMenu()
  local list = WEAPON_LISTS[catKey] or {}
  if #list == 0 then
    player:GossipMenuAddItem(0, "|cffffa000No items added yet for this category.|r", 0, 0)
  else
    for _, entry in ipairs(list) do
      local label = string.format("%s (ID: %d)", entry.name or "Item", entry.id or 0)
      player:GossipMenuAddItem(0, label, SENDER_ITEM, entry.id)
    end
  end
  player:GossipMenuAddItem(0, "« Back to Categories", 0, BACK_CATS)
  player:GossipSendMenu(1, creature)
end

local function TryGiveItem(player, itemId, itemName)
  if not itemId or itemId <= 0 then
    player:SendBroadcastMessage("|cffff2020Invalid item.|r"); return
  end
  if player:AddItem(itemId, 1) then
    player:SendBroadcastMessage(string.format("|cff20ff20Received:|r %s (ID:%d)", itemName or "Item", itemId))
  else
    player:SendBroadcastMessage("|cffff2020Bags are full or item failed to add.|r")
  end
end

-- Keep selection state minimal (only category) per player
local currentCatByPlayer = {}
local function PKey(p) return p:GetGUIDLow() end

local function OnGossipHello(event, player, creature)
  currentCatByPlayer[PKey(player)] = nil
  SendCategoryMenu(player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid)
  local key = PKey(player)

  if intid == BACK_CATS then
    currentCatByPlayer[key] = nil
    SendCategoryMenu(player, creature); return
  end

  if sender == SENDER_CAT then
    local catKey = CAT_ID_TO_KEY[intid] or "ONE_HAND"
    currentCatByPlayer[key] = catKey
    SendItemMenu(player, creature, catKey); return
  end

  if sender == SENDER_ITEM then
    local catKey = currentCatByPlayer[key] or "ONE_HAND"
    local name
    for _, it in ipairs(WEAPON_LISTS[catKey] or {}) do if it.id == intid then name = it.name break end end
    TryGiveItem(player, intid, name)
    SendItemMenu(player, creature, catKey); return
  end

  SendCategoryMenu(player, creature)
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
