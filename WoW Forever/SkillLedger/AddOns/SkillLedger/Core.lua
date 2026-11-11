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
  if type(db.market) ~= "table" then db.market = {} end
  if type(db.market.items) ~= "table" then db.market.items = {} end
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

local MARKET_BATCH = 15
local marketToken = 0

local function tsmNumber(source, itemId)
  if not (TSM_API and TSM_API.GetCustomPriceValue) then return nil end
  local ok, value = pcall(TSM_API.GetCustomPriceValue, source, "i:" .. itemId)
  if not ok or type(value) ~= "number" then return nil end
  return value
end

local function auctionatorApi()
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if type(api) ~= "table" then return nil end
  return api
end

function SL.ReadMarket(itemId)
  if not itemId then return nil end
  local row = { id = itemId, at = SL.Now() }
  local got = false
  local saleRate = tsmNumber("dbregionsalerate", itemId)
  local soldPerDay = tsmNumber("dbregionsoldperday", itemId)
  local market = tsmNumber("dbmarket", itemId)
  local minBuyout = tsmNumber("dbminbuyout", itemId)
  if saleRate ~= nil then row.saleRate = saleRate; got = true end
  if soldPerDay ~= nil then row.soldPerDay = soldPerDay; got = true end
  if market ~= nil then row.market = market; got = true end
  if minBuyout ~= nil then row.minBuyout = minBuyout; got = true end
  local api = auctionatorApi()
  if api and api.GetAuctionPriceByItemID then
    local ok, value = pcall(api.GetAuctionPriceByItemID, "SkillLedger", itemId)
    if ok and type(value) == "number" then row.atrPrice = value; got = true end
  end
  if api and api.GetAuctionAgeByItemID then
    local ok, age = pcall(api.GetAuctionAgeByItemID, "SkillLedger", itemId)
    if ok and type(age) == "number" then row.atrAge = age; got = true end
  end
  if not got then return nil end
  return row
end

local function saveMarket(row)
  local items = SL.DB().market.items
  for i = 1, #items do
    if items[i].id == row.id then
      items[i] = row
      SL.DB().market.updated = SL.Now()
      return
    end
  end
  items[#items + 1] = row
  SL.DB().market.updated = SL.Now()
end

local function learnedOutputs()
  local char = SL.Char()
  local learned = char.learned and char.learned.recipes or {}
  local recipes = SkillLedgerData and SkillLedgerData.recipes or {}
  local made = {}
  for i = 1, #recipes do
    local recipe = recipes[i]
    if recipe.spell and recipe.made and recipe.made > 0 and not recipe.enchant then
      made[recipe.spell] = recipe.made
    end
  end
  local seen, list = {}, {}
  for i = 1, #learned do
    local row = learned[i]
    local item = row.item
    if (not item or item == 0) and row.spell then item = made[row.spell] end
    if item and item > 0 and not seen[item] then
      seen[item] = true
      list[#list + 1] = item
    end
  end
  return list
end

local function pumpMarket(token)
  local queue = SL._marketQueue
  if not queue or queue.token ~= token then return end
  local last = math.min(queue.index + MARKET_BATCH - 1, #queue.ids)
  for i = queue.index, last do
    local ok, row = pcall(SL.ReadMarket, queue.ids[i])
    if ok and type(row) == "table" then saveMarket(row) end
  end
  queue.index = last + 1
  if queue.index <= #queue.ids then
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function() pumpMarket(token) end)
      return
    end
  end
  SL._marketQueue = nil
end

function SL.SnapshotMarket()
  local tsm = TSM_API and TSM_API.GetCustomPriceValue and true or false
  local api = auctionatorApi()
  local atr = api and (api.GetAuctionPriceByItemID or api.GetAuctionAgeByItemID) and true or false
  if not tsm and not atr then
    if SL.Say then SL.Say("market: TSM and Auctionator are not available.") end
    return 0
  end
  local ids = learnedOutputs()
  if #ids == 0 then return 0 end
  marketToken = marketToken + 1
  SL._marketQueue = { ids = ids, index = 1, token = marketToken }
  pumpMarket(marketToken)
  return #ids
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
  if type(SkillLedgerData) ~= "table" or type(SkillLedgerData.recipes) ~= "table" or #SkillLedgerData.recipes < 1 then
    if SL.Say then SL.Say("recipe data is not loaded, so there is no plan. /reload.") end
    return nil
  end
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
  if SL.SnapshotMarket then SL.SnapshotMarket() end
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

function SL.HandleSlash(message)
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
      if SL.Say then SL.Say("bags: " .. tostring(count) .. " stacks.") end
    end
  elseif message == "bank" then
    if SL.SnapshotBank then SL.SnapshotBank(true) end
  elseif message == "plan" then
    local ok, err = pcall(function()
      local result = SL.Plan()
      if result then
        SL.PrintPlan(result)
        if SL.Show then SL.Show() end
      end
    end)
    if not ok and SL.Say then SL.Say("plan failed: " .. tostring(err)) end
  elseif message == "help" then
    if SL.Say then SL.Say("/skillledger or /sl: show, hide, scan, bags, bank, plan, help") end
  else
    if SL.Say then SL.Say("/skillledger help") end
  end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "SkillLedger" then
    SL.DB()
  elseif event == "PLAYER_LOGIN" then
    SL.SnapshotProfessions()
    if SL.SnapshotMoney then SL.SnapshotMoney() end
    if SL.SnapshotBags then SL.SnapshotBags() end
    if SL.SnapshotRep then SL.SnapshotRep() end
  elseif event == "PLAYER_MONEY" then
    if SL.SnapshotMoney then SL.SnapshotMoney() end
  elseif event == "PLAYER_LOGOUT" then
    if SL.bagsDirty and SL.SnapshotBags then SL.SnapshotBags() end
    if SL.SnapshotRep then SL.SnapshotRep() end
  elseif event == "SKILL_LINES_CHANGED" then
    SL.SnapshotProfessions()
  elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_LIST_UPDATE" then
    soon("tradeskill", 0.3, function()
      if SL.SnapshotTradeSkill then SL.SnapshotTradeSkill() end
    end)
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
    if SL.EnsureAHTab then SL.EnsureAHTab() end
  elseif event == "AUCTION_HOUSE_CLOSED" then
    if SL.AbortScan then SL.AbortScan("Auction house closed. Scan stopped.") end
    if SL.HideAHPanel then SL.HideAHPanel() end
  elseif event == "AUCTION_ITEM_LIST_UPDATE" or event == "REPLICATE_ITEM_LIST_UPDATE"
    or event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" or event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"
    or event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_UPDATED"
    or event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
    if SL.OnAuctionEvent then SL.OnAuctionEvent(event, arg1) end
  end
end)
local function listen(eventName)
  pcall(events.RegisterEvent, events, eventName)
end
listen("ADDON_LOADED")
listen("PLAYER_LOGIN")
listen("PLAYER_LOGOUT")
listen("SKILL_LINES_CHANGED")
listen("PLAYER_MONEY")
listen("TRADE_SKILL_SHOW")
listen("TRADE_SKILL_UPDATE")
listen("TRADE_SKILL_LIST_UPDATE")
listen("BAG_UPDATE")
listen("BANKFRAME_OPENED")
listen("BANKFRAME_CLOSED")
listen("PLAYERBANKSLOTS_CHANGED")
listen("PLAYERREAGENTBANKSLOTS_CHANGED")
listen("UPDATE_FACTION")
listen("MERCHANT_SHOW")
listen("MERCHANT_UPDATE")
listen("AUCTION_HOUSE_SHOW")
listen("AUCTION_HOUSE_CLOSED")
listen("AUCTION_ITEM_LIST_UPDATE")
listen("REPLICATE_ITEM_LIST_UPDATE")
listen("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
listen("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
listen("ITEM_SEARCH_RESULTS_UPDATED")
listen("COMMODITY_SEARCH_RESULTS_UPDATED")
listen("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
