-- SavedVariables, profession snapshot, slash commands, and the plan trigger.
-- Nothing here runs on OnUpdate. Bag and reputation events only set a flag
-- and one delayed snapshot.

SkillLedger = SkillLedger or {}
local SL = SkillLedger

local CLASS_BIT = {
  WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16,
  DEATHKNIGHT = 32, SHAMAN = 64, MAGE = 128, WARLOCK = 256, DRUID = 1024,
}
local RACE_BIT = {
  Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Scourge = 16,
  Tauren = 32, Gnome = 64, Troll = 128, BloodElf = 512, Draenei = 1024,
}

local pending = {}

local function soon(key, seconds, fn)
  if pending[key] then return end
  if not C_Timer or not C_Timer.After then return end
  pending[key] = true
  C_Timer.After(seconds, function()
    pending[key] = nil
    fn()
  end)
end

function SL.Now()
  if time then return time() end
  return 0
end

function SL.DB()
  if type(SkillLedgerDB) ~= "table" then SkillLedgerDB = {} end
  local db = SkillLedgerDB
  db.version = 1
  if type(db.chars) ~= "table" then db.chars = {} end
  if type(db.prices) ~= "table" then db.prices = {} end
  if type(db.prices.items) ~= "table" then db.prices.items = {} end
  if type(db.ui) ~= "table" then db.ui = {} end
  return db
end

function SL.CharKey()
  local name = UnitName and UnitName("player") or "Unknown"
  local realm = GetRealmName and GetRealmName() or "Unknown"
  if not name or name == "" then name = "Unknown" end
  if not realm or realm == "" then realm = "Unknown" end
  return name .. "-" .. realm, name, realm
end

function SL.Char()
  local db = SL.DB()
  local key, name, realm = SL.CharKey()
  local char = db.chars[key]
  if type(char) ~= "table" then
    char = {}
    db.chars[key] = char
  end
  char.name = name
  char.realm = realm
  char.key = key
  if UnitFactionGroup then
    local faction = UnitFactionGroup("player")
    if faction and faction ~= "" then char.faction = faction end
  end
  if UnitClass then
    local _, file = UnitClass("player")
    if file then char.classFile = file end
    local localized = UnitClass("player")
    if localized then char.class = localized end
  end
  if UnitRace then
    local _, token = UnitRace("player")
    if token then char.race = token end
  end
  if UnitLevel then char.level = UnitLevel("player") end
  char.updated = SL.Now()
  if type(char.professions) ~= "table" then char.professions = {} end
  if type(char.bags) ~= "table" then char.bags = { items = {} } end
  if type(char.bags.items) ~= "table" then char.bags.items = {} end
  if type(char.bank) ~= "table" then char.bank = { items = {} } end
  if type(char.bank.items) ~= "table" then char.bank.items = {} end
  if type(char.standings) ~= "table" then char.standings = { factions = {} } end
  if type(char.standings.factions) ~= "table" then char.standings.factions = {} end
  if type(char.merchant) ~= "table" then char.merchant = { rows = {} } end
  if type(char.merchant.rows) ~= "table" then char.merchant.rows = {} end
  return char
end

local function skillIdFor(name)
  local rows = SkillLedgerData and SkillLedgerData.professions or {}
  for i = 1, #rows do
    if rows[i].name == name then return rows[i].id, rows[i].secondary end
  end
  return nil, false
end

function SL.SnapshotProfessions()
  local char = SL.Char()
  local rows = {}
  local function add(name, rank, maxRank, reported, secondary)
    if not name or name == "" or not rank or not maxRank or maxRank <= 0 then return end
    local skillLine = skillIdFor(name) or reported
    rows[#rows + 1] = {
      name = name,
      rank = rank,
      maxRank = maxRank,
      skillLine = skillLine,
      secondary = secondary and true or false,
    }
  end
  if GetProfessions and GetProfessionInfo then
    local ok, a, b, c, d, e, f = pcall(GetProfessions)
    if ok then
      local indexes = { a, b, c, d, e, f }
      for i = 1, #indexes do
        local index = indexes[i]
        if index then
          local okInfo, name, _, rank, maxRank, _, _, skillLine = pcall(GetProfessionInfo, index)
          if okInfo then add(name, rank, maxRank, skillLine, i > 2) end
        end
      end
    end
  end
  if #rows == 0 and GetNumSkillLines and GetSkillLineInfo then
    local ok, lines = pcall(GetNumSkillLines)
    if ok and lines then
      local secondary = false
      for i = 1, lines do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
        if isHeader then
          secondary = name and string.find(name, "Secondary", 1, true) and true or false
        else
          add(name, rank, maxRank, nil, secondary)
        end
      end
    end
  end
  char.professions = rows
  return rows
end

local function sumItems(lists)
  local totals = {}
  for n = 1, #lists do
    local items = lists[n]
    if items then
      for i = 1, #items do
        local row = items[i]
        if row.id and row.count and row.count > 0 then
          totals[row.id] = (totals[row.id] or 0) + row.count
        end
      end
    end
  end
  return totals
end

local function mapRows(rows, field)
  local out = {}
  for i = 1, #rows do
    local row = rows[i]
    if row.id and row[field] then out[row.id] = row end
  end
  return out
end

function SL.ExternalPrice(itemId)
  if TSM_API and TSM_API.GetCustomPriceValue then
    local ok, value = pcall(TSM_API.GetCustomPriceValue, "first(DBMinBuyout, AtrValue)", "i:" .. itemId)
    if ok and type(value) == "number" and value > 0 then return math.floor(value), "tsm" end
  end
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if api and api.GetAuctionPriceByItemID then
    local ok, value = pcall(api.GetAuctionPriceByItemID, "SkillLedger", itemId)
    if ok and type(value) == "number" and value > 0 then return math.floor(value), "auctionator" end
  end
  return nil, nil
end

function SL.Plan()
  SL.SnapshotProfessions()
  if SL.SnapshotBags then SL.SnapshotBags() end
  if SL.SnapshotRep then SL.SnapshotRep() end
  local char = SL.Char()
  local db = SL.DB()
  local inventory = sumItems({ char.bags.items, char.bank.items })
  local prices, sources = {}, {}
  for i = 1, #(db.prices.items or {}) do
    local row = db.prices.items[i]
    if row.id and row.unit and row.unit > 0 then
      prices[row.id] = row.unit
      sources[row.id] = row.source or "scan"
    end
  end
  local reagents = {}
  local wanted = {}
  for i = 1, #char.professions do wanted[char.professions[i].skillLine] = true end
  local recipes = SkillLedgerData.recipes or {}
  for i = 1, #recipes do
    if wanted[recipes[i].skill] then
      for r = 1, #recipes[i].reagents do reagents[recipes[i].reagents[r][1]] = true end
    end
  end
  for itemId in pairs(reagents) do
    if not prices[itemId] then
      local value, source = SL.ExternalPrice(itemId)
      if value then
        prices[itemId] = value
        sources[itemId] = source
      end
    end
  end
  local standings = {}
  for i = 1, #char.standings.factions do
    local row = char.standings.factions[i]
    if row.id and row.standing then standings[row.id] = row.standing end
  end
  local captured = {}
  for i = 1, #char.merchant.rows do
    local row = char.merchant.rows[i]
    if row.id and row.unit and row.unit > 0 then
      local have = captured[row.id]
      if not have or row.unit < have.unit then
        captured[row.id] = {
          unit = row.unit,
          factionId = row.factionId,
          faction = row.faction,
          standingId = row.standing,
        }
      end
    end
  end
  local classMask = CLASS_BIT[char.classFile or ""] or 0
  local raceMask = RACE_BIT[char.race or ""] or 0
  local plans, shopping = SkillLedgerPlan.PlanCharacter(
    SkillLedgerData, inventory, char.professions, prices, standings, captured,
    char.faction or "", classMask, raceMask, sources
  )
  SL.lastPlan = { plans = plans, shopping = shopping, at = SL.Now() }
  return SL.lastPlan
end

function SL.PrintPlan(result)
  result = result or SL.lastPlan
  if not result then return end
  local P = SkillLedgerPlan
  for i = 1, #result.plans do
    local plan = result.plans[i]
    local missing = #plan.unpriced
    local line = plan.name .. " " .. plan.rank .. "-" .. plan.cap .. ": " .. P.Money(plan.total)
    line = line .. ", " .. #plan.steps .. " steps"
    if missing > 0 then line = line .. ", " .. missing .. " unpriced" end
    print("|cffe0b060SkillLedger|r " .. line)
  end
end

local function handleSlash(message)
  message = string.lower(message or "")
  message = string.gsub(message, "^%s+", "")
  message = string.gsub(message, "%s+$", "")
  if message == "" or message == "show" or message == "toggle" then
    if SL.Toggle then SL.Toggle() end
  elseif message == "hide" then
    if SL.Hide then SL.Hide() end
  elseif message == "scan" then
    if SL.StartScan then SL.StartScan() end
  elseif message == "bags" then
    if SL.SnapshotBags then
      local count = SL.SnapshotBags()
      print("|cffe0b060SkillLedger|r bags: " .. tostring(count) .. " stacks.")
    end
  elseif message == "bank" then
    if SL.SnapshotBank then SL.SnapshotBank(true) end
  elseif message == "plan" then
    SL.PrintPlan(SL.Plan())
    if SL.Show then SL.Show() end
  elseif message == "help" then
    print("|cffe0b060SkillLedger|r /sl show, hide, scan, bags, bank, plan, help")
  else
    print("|cffe0b060SkillLedger|r /sl help")
  end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "SkillLedger" then
    SL.DB()
  elseif event == "PLAYER_LOGIN" then
    SL.SnapshotProfessions()
    if SL.SnapshotBags then SL.SnapshotBags() end
    if SL.SnapshotRep then SL.SnapshotRep() end
  elseif event == "PLAYER_LOGOUT" then
    if SL.bagsDirty and SL.SnapshotBags then SL.SnapshotBags() end
    if SL.SnapshotRep then SL.SnapshotRep() end
  elseif event == "SKILL_LINES_CHANGED" then
    SL.SnapshotProfessions()
  elseif event == "BAG_UPDATE" then
    SL.bagsDirty = true
    soon("bags", 2, function()
      SL.bagsDirty = nil
      if SL.SnapshotBags then SL.SnapshotBags() end
    end)
  elseif event == "BANKFRAME_OPENED" then
    if SL.SnapshotBank then SL.SnapshotBank(false) end
  elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
    if SL.BankIsOpen and SL.BankIsOpen() then
      soon("bank", 0.4, function()
        if SL.BankIsOpen and SL.BankIsOpen() and SL.SnapshotBank then SL.SnapshotBank(false) end
      end)
    end
  elseif event == "BANKFRAME_CLOSED" then
    if SL.SnapshotBank then SL.SnapshotBank(false) end
  elseif event == "UPDATE_FACTION" then
    soon("rep", 2, function()
      if SL.SnapshotRep then SL.SnapshotRep() end
    end)
  elseif event == "MERCHANT_SHOW" then
    if SL.SnapshotMerchant then SL.SnapshotMerchant() end
    if SL.SnapshotRep then SL.SnapshotRep() end
  elseif event == "MERCHANT_UPDATE" then
    soon("merchant", 0.4, function()
      if SL.MerchantIsOpen and SL.MerchantIsOpen() and SL.SnapshotMerchant then SL.SnapshotMerchant() end
    end)
  elseif event == "AUCTION_HOUSE_SHOW" then
    if SL.AnchorScanButton then SL.AnchorScanButton() end
  elseif event == "AUCTION_HOUSE_CLOSED" then
    if SL.CancelScan then SL.CancelScan() end
  elseif event == "AUCTION_ITEM_LIST_UPDATE" or event == "REPLICATE_ITEM_LIST_UPDATE" then
    if SL.OnAuctionEvent then SL.OnAuctionEvent(event) end
  end
end)
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("BANKFRAME_CLOSED")
events:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
events:RegisterEvent("UPDATE_FACTION")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_UPDATE")
events:RegisterEvent("AUCTION_HOUSE_SHOW")
events:RegisterEvent("AUCTION_HOUSE_CLOSED")
events:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
pcall(events.RegisterEvent, events, "PLAYERREAGENTBANKSLOTS_CHANGED")
pcall(events.RegisterEvent, events, "REPLICATE_ITEM_LIST_UPDATE")

SLASH_SKILLLEDGER1 = "/sl"
SLASH_SKILLLEDGER2 = "/skillledger"
SlashCmdList.SKILLLEDGER = handleSlash
