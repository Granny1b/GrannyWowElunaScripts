--[[ 
  NPC: 600003  (Classic Armor/Accessory Browser)  — weapons removed per request
  Flow: Choose Class -> Choose Slot -> Pick Item -> Add to bags
  Notes:
    - Uses numeric intids (required by Eluna) and maps them back to keys.
    - Add more items in CLASS_ITEMS below.
--]]

local NPC_ID = 600003

-- intid spaces
local SENDER_CLASS   = 100
local SENDER_SLOT    = 200
local SENDER_ITEM    = 300
local BACK_CLASSES   = 9001
local BACK_SLOTS     = 9002

-- per-player nav state
local stateByPlayer = {}
local function PKey(p) return p:GetGUIDLow() end

-- Class maps (intid <-> key)
local CLASS_ORDER = { "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID" }
local CLASS_LABEL = {
  WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue",
  PRIEST="Priest", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid"
}
local CLASS_KEY_TO_ID, CLASS_ID_TO_KEY = {}, {}
for i, key in ipairs(CLASS_ORDER) do CLASS_KEY_TO_ID[key]=i; CLASS_ID_TO_KEY[i]=key end

-- Slot maps (no WEAPON)
local SLOT_ORDER = {
  "HEAD","NECK","SHOULDER","BACK","CHEST","WRIST","HANDS","WAIST","LEGS","FEET","RING","TRINKET"
}
local SLOT_LABEL = {
  HEAD="Head", NECK="Neck", SHOULDER="Shoulder", BACK="Back", CHEST="Chest",
  WRIST="Wrist", HANDS="Hands", WAIST="Waist", LEGS="Legs", FEET="Feet",
  RING="Ring", TRINKET="Trinket"
}
local SLOT_KEY_TO_ID, SLOT_ID_TO_KEY = {}, {}
for i, key in ipairs(SLOT_ORDER) do SLOT_KEY_TO_ID[key]=i; SLOT_ID_TO_KEY[i]=key end

-- CLASS -> SLOT -> { {id=, name=}, ... }  (examples only; extend freely)
local CLASS_ITEMS = {
  WARRIOR = {
    HEAD     = { {id=12640, name="Lionheart Helm"}, {id=19372, name="Helm of Endless Rage"} },
    NECK     = { {id=18404, name="Onyxia Tooth Pendant"}, {id=19377, name="Prestor's Talisman of Connivery"} },
    SHOULDER = { {id=19394, name="Drake Talon Pauldrons"}, {id=16868, name="Pauldrons of Might (T1)"} },
    BACK     = { {id=19436, name="Cloak of Draconic Might"} },
    CHEST    = { {id=19405, name="Malfurion's Blessed Bulwark"}, {id=16966, name="Breastplate of Wrath (T2)"} },
    WRIST    = { {id=16959, name="Bracelets of Wrath (T2)"} },
    HANDS    = { {id=16964, name="Gauntlets of Wrath (T2)"} },
    WAIST    = { {id=19392, name="Girdle of the Fallen Crusader"} },
    LEGS     = { {id=16962, name="Legplates of Wrath (T2)"} },
    FEET     = { {id=16965, name="Sabatons of Wrath (T2)"} },
    RING     = { {id=17063, name="Band of Accuria"}, {id=19384, name="Master Dragonslayer's Ring"} },
    TRINKET  = { {id=13965, name="Blackhand's Breadth"}, {id=19406, name="Drake Fang Talisman"} },
  },

  PALADIN = {
    HEAD     = { {id=16955, name="Judgement Crown (T2)"} },
    NECK     = { {id=18404, name="Onyxia Tooth Pendant"} },
    SHOULDER = { {id=16953, name="Judgement Spaulders (T2)"} },
    BACK     = { {id=17102, name="Cloak of the Shrouded Mists"} },
    CHEST    = { {id=16958, name="Breastplate of Judgement (T2)"} },
    WRIST    = { {id=16951, name="Judgement Bindings (T2)"} },
    HANDS    = { {id=16956, name="Judgement Gauntlets (T2)"} },
    WAIST    = { {id=16952, name="Judgement Belt (T2)"} },
    LEGS     = { {id=16954, name="Judgement Legplates (T2)"} },
    FEET     = { {id=16957, name="Judgement Sabatons (T2)"} },
    RING     = { {id=17063, name="Band of Accuria"} },
    TRINKET  = { {id=11815, name="Hand of Justice"} },
  },

  HUNTER = {
    HEAD     = { {id=16939, name="Dragonstalker Helm (T2)"} },
    NECK     = { {id=19377, name="Prestor's Talisman of Connivery"} },
    SHOULDER = { {id=16937, name="Dragonstalker Spaulders (T2)"} },
    BACK     = { {id=19436, name="Cloak of Draconic Might"} },
    CHEST    = { {id=16942, name="Dragonstalker Breastplate (T2)"} },
    WRIST    = { {id=16935, name="Dragonstalker Bracers (T2)"} },
    HANDS    = { {id=16940, name="Dragonstalker Gauntlets (T2)"} },
    WAIST    = { {id=16936, name="Dragonstalker Belt (T2)"} },
    LEGS     = { {id=16938, name="Dragonstalker Legguards (T2)"} },
    FEET     = { {id=16941, name="Dragonstalker Greaves (T2)"} },
    RING     = { {id=17063, name="Band of Accuria"} },
    TRINKET  = { {id=18473, name="Royal Seal of Eldre'Thalas (Hunter)"} },
  },

  ROGUE = {
    HEAD     = { {id=16908, name="Bloodfang Hood (T2)"} },
    NECK     = { {id=18404, name="Onyxia Tooth Pendant"}, {id=19377, name="Prestor's Talisman of Connivery"} },
    SHOULDER = { {id=16832, name="Bloodfang Spaulders (T2)"} },
    BACK     = { {id=13340, name="Cape of the Black Baron"} },
    CHEST    = { {id=16905, name="Bloodfang Chestpiece (T2)"} },
    WRIST    = { {id=16911, name="Bloodfang Bracers (T2)"} },
    HANDS    = { {id=16907, name="Bloodfang Gloves (T2)"} },
    WAIST    = { {id=16910, name="Bloodfang Belt (T2)"} },
    LEGS     = { {id=16909, name="Bloodfang Pants (T2)"} },
    FEET     = { {id=16906, name="Bloodfang Boots (T2)"} },
    RING     = { {id=17063, name="Band of Accuria"} },
    TRINKET  = { {id=13965, name="Blackhand's Breadth"} },
  },

  PRIEST = {
    HEAD     = { {id=16921, name="Halo of Transcendence (T2)"} },
    NECK     = { {id=18814, name="Choker of the Fire Lord"} },
    SHOULDER = { {id=16924, name="Shoulderpads of Transcendence (T2)"} },
    BACK     = { {id=19430, name="Shroud of Pure Thought"} },
    CHEST    = { {id=16923, name="Robes of Transcendence (T2)"} },
    WRIST    = { {id=16926, name="Bindings of Transcendence (T2)"} },
    HANDS    = { {id=16920, name="Handguards of Transcendence (T2)"} },
    WAIST    = { {id=16925, name="Belt of Transcendence (T2)"} },
    LEGS     = { {id=16922, name="Leggings of Transcendence (T2)"} },
    FEET     = { {id=16919, name="Boots of Transcendence (T2)"} },
    RING     = { {id=19147, name="Ring of Spell Power"} },
    TRINKET  = { {id=18469, name="Royal Seal of Eldre'Thalas (Priest)"} },
  },

  SHAMAN = {
    HEAD     = { {id=16947, name="Helmet of Ten Storms (T2)"} },
    NECK     = { {id=18814, name="Choker of the Fire Lord"} },
    SHOULDER = { {id=16945, name="Epaulets of Ten Storms (T2)"} },
    BACK     = { {id=19857, name="Cloak of Consumption"} },
    CHEST    = { {id=16950, name="Breastplate of Ten Storms (T2)"} },
    WRIST    = { {id=16943, name="Bracers of Ten Storms (T2)"} },
    HANDS    = { {id=16948, name="Gauntlets of Ten Storms (T2)"} },
    WAIST    = { {id=16944, name="Belt of Ten Storms (T2)"} },
    LEGS     = { {id=16946, name="Legplates of Ten Storms (T2)"} },
    FEET     = { {id=16949, name="Greaves of Ten Storms (T2)"} },
    RING     = { {id=19147, name="Ring of Spell Power"} },
    TRINKET  = { {id=18470, name="Royal Seal of Eldre'Thalas (Shaman)"} },
  },

  MAGE = {
    HEAD     = { {id=16914, name="Netherwind Crown (T2)"} },
    NECK     = { {id=18814, name="Choker of the Fire Lord"} },
    SHOULDER = { {id=16917, name="Netherwind Mantle (T2)"} },
    BACK     = { {id=19430, name="Shroud of Pure Thought"} },
    CHEST    = { {id=16916, name="Robes of Netherwind (T2)"} },
    WRIST    = { {id=16918, name="Bindings of Transcendence (alt caster)"} },
    HANDS    = { {id=16913, name="Netherwind Gloves (T2)"} },
    WAIST    = { {id=19136, name="Mana Igniting Cord"} },
    LEGS     = { {id=16915, name="Netherwind Pants (T2)"} },
    FEET     = { {id=19131, name="Snowblind Shoes"} },
    RING     = { {id=19147, name="Ring of Spell Power"} },
    TRINKET  = { {id=18467, name="Royal Seal of Eldre'Thalas (Mage)"} },
  },

  WARLOCK = {
    HEAD     = { {id=16929, name="Nemesis Skullcap (T2)"} },
    NECK     = { {id=18814, name="Choker of the Fire Lord"} },
    SHOULDER = { {id=16932, name="Nemesis Spaulders (T2)"} },
    BACK     = { {id=19430, name="Shroud of Pure Thought"} },
    CHEST    = { {id=16931, name="Nemesis Robes (T2)"} },
    WRIST    = { {id=16934, name="Nemesis Bracers (T2)"} },
    HANDS    = { {id=16928, name="Nemesis Gloves (T2)"} },
    WAIST    = { {id=19136, name="Mana Igniting Cord"} },
    LEGS     = { {id=16930, name="Nemesis Leggings (T2)"} },
    FEET     = { {id=19131, name="Snowblind Shoes"} },
    RING     = { {id=19147, name="Ring of Spell Power"} },
    TRINKET  = { {id=18466, name="Royal Seal of Eldre'Thalas (Warlock)"} },
  },

  DRUID = {
    HEAD     = { {id=16900, name="Stormrage Cover (T2)"} },
    NECK     = { {id=18814, name="Choker of the Fire Lord"} },
    SHOULDER = { {id=16902, name="Stormrage Pauldrons (T2)"} },
    BACK     = { {id=19870, name="Hakkari Loa Cloak"} },
    CHEST    = { {id=16897, name="Stormrage Chestguard (T2)"} },
    WRIST    = { {id=16904, name="Stormrage Bracers (T2)"} },
    HANDS    = { {id=16899, name="Stormrage Handguards (T2)"} },
    WAIST    = { {id=16903, name="Stormrage Belt (T2)"} },
    LEGS     = { {id=16901, name="Stormrage Legguards (T2)"} },
    FEET     = { {id=16898, name="Stormrage Boots (T2)"} },
    RING     = { {id=19382, name="Pure Elementium Band"} },
    TRINKET  = { {id=18471, name="Royal Seal of Eldre'Thalas (Druid)"} },
  },
}

local function SendClassMenu(player, creature)
  player:GossipClearMenu()
  for i, key in ipairs(CLASS_ORDER) do
    player:GossipMenuAddItem(0, CLASS_LABEL[key], SENDER_CLASS, i)
  end
  player:GossipSendMenu(1, creature)
end

local function SendSlotMenu(player, creature, classKey)
  player:GossipClearMenu()
  for i, slotKey in ipairs(SLOT_ORDER) do
    player:GossipMenuAddItem(0, SLOT_LABEL[slotKey], SENDER_SLOT, i)
  end
  player:GossipMenuAddItem(0, "« Back to Classes", 0, BACK_CLASSES)
  player:GossipSendMenu(1, creature)
end

local function SendItemMenu(player, creature, classKey, slotKey)
  player:GossipClearMenu()
  local items = (CLASS_ITEMS[classKey] and CLASS_ITEMS[classKey][slotKey]) or {}
  if #items == 0 then
    player:GossipMenuAddItem(0, "|cffffa000No examples added yet for this slot.|r", 0, 0)
  else
    for _, entry in ipairs(items) do
      local label = string.format("%s (ID: %d)", entry.name or "Item", entry.id or 0)
      player:GossipMenuAddItem(0, label, SENDER_ITEM, entry.id)
    end
  end
  player:GossipMenuAddItem(0, "« Back to Slots", 0, BACK_SLOTS)
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

local function OnGossipHello(event, player, creature)
  stateByPlayer[PKey(player)] = { class=nil, slot=nil }
  SendClassMenu(player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid)
  local key = PKey(player)
  local st = stateByPlayer[key] or {}
  stateByPlayer[key] = st

  if intid == BACK_CLASSES then
    st.class, st.slot = nil, nil
    SendClassMenu(player, creature); return
  elseif intid == BACK_SLOTS then
    st.slot = nil
    local classKey = st.class or "WARRIOR"
    SendSlotMenu(player, creature, classKey); return
  end

  if sender == SENDER_CLASS then
    st.class = CLASS_ID_TO_KEY[intid] or "WARRIOR"
    st.slot = nil
    SendSlotMenu(player, creature, st.class); return
  end

  if sender == SENDER_SLOT then
    st.slot = SLOT_ID_TO_KEY[intid] or "HEAD"
    SendItemMenu(player, creature, st.class or "WARRIOR", st.slot); return
  end

  if sender == SENDER_ITEM then
    -- Find the name (optional nicety)
    local classKey = st.class or "WARRIOR"
    local slotKey  = st.slot  or "HEAD"
    local name
    local items = (CLASS_ITEMS[classKey] and CLASS_ITEMS[classKey][slotKey]) or {}
    for _, it in ipairs(items) do if it.id == intid then name = it.name break end end
    TryGiveItem(player, intid, name)
    SendItemMenu(player, creature, classKey, slotKey); return
  end

  SendClassMenu(player, creature)
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
