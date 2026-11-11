-- Bags, bank, reputation, merchant prices, and the auction scan.
-- The auction scan yields with C_Timer.After. There is no OnUpdate.

local SL = SkillLedger

local scan = { active = false, token = 0 }

function SL.BankIsOpen()
  return BankFrame and BankFrame.IsShown and BankFrame:IsShown() and true or false
end

function SL.MerchantIsOpen()
  return MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() and true or false
end

local function itemIdFromLink(link)
  if type(link) ~= "string" then return nil end
  local id = link:match("item:(%d+)")
  return id and tonumber(id) or nil
end

local function nameFromLink(link, fallback)
  if type(link) == "string" then
    local name = link:match("%[(.-)%]")
    if name and name ~= "" then return name end
  end
  return fallback
end

local function readSlot(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local ok, first, count, _, _, _, _, link, _, _, itemId = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if ok and type(first) == "table" then
      local id = first.itemID or itemIdFromLink(first.hyperlink)
      local stack = first.stackCount or first.stackcount or 0
      if id and stack and stack > 0 then
        return id, stack, nameFromLink(first.hyperlink, first.name)
      end
      return nil
    end
    if ok and (itemId or link or type(first) == "string") then
      local id = itemId or itemIdFromLink(link)
      if id and count and count > 0 then return id, count, nameFromLink(link) end
    end
  end
  if GetContainerItemInfo then
    local ok, _, count, _, _, _, _, link, _, _, itemId = pcall(GetContainerItemInfo, bag, slot)
    if ok then
      local id = itemId or itemIdFromLink(link)
      if id and count and count > 0 then return id, count, nameFromLink(link) end
    end
  end
  return nil
end

local function slotCount(bag)
  if C_Container and C_Container.GetContainerNumSlots then
    local ok, count = pcall(C_Container.GetContainerNumSlots, bag)
    if ok and type(count) == "number" then return count end
  end
  if GetContainerNumSlots then
    local ok, count = pcall(GetContainerNumSlots, bag)
    if ok and type(count) == "number" then return count end
  end
  return 0
end

local function addBag(list, bag)
  if bag == nil then return end
  for _, have in ipairs(list) do
    if have == bag then return end
  end
  list[#list + 1] = bag
end

local function playerBags()
  local list = {}
  addBag(list, BACKPACK_CONTAINER or 0)
  local bags = NUM_BAG_SLOTS or 4
  for i = 1, bags do addBag(list, i) end
  if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then addBag(list, Enum.BagIndex.ReagentBag) end
  if KEYRING_CONTAINER then addBag(list, KEYRING_CONTAINER) end
  return list
end

local function bankBags()
  local list = {}
  addBag(list, BANK_CONTAINER or -1)
  if REAGENTBANK_CONTAINER then addBag(list, REAGENTBANK_CONTAINER) end
  if Enum and Enum.BagIndex and Enum.BagIndex.BankBag_1 then
    local i = 1
    while Enum.BagIndex["BankBag_" .. i] do
      addBag(list, Enum.BagIndex["BankBag_" .. i])
      i = i + 1
    end
  else
    local first = (NUM_BAG_SLOTS or 4) + 1
    local extra = NUM_BANKBAGSLOTS or 7
    for i = first, first + extra - 1 do addBag(list, i) end
  end
  return list
end

local function readBags(bagIds, where)
  local rows = {}
  for b = 1, #bagIds do
    local bag = bagIds[b]
    local slots = slotCount(bag)
    for slot = 1, slots do
      local id, count, name = readSlot(bag, slot)
      if id then
        local known = SkillLedgerData and SkillLedgerData.items and SkillLedgerData.items[id]
        rows[#rows + 1] = {
          id = id,
          name = known or name or ("Item " .. id),
          count = count,
          bag = bag,
          slot = slot,
          where = where,
        }
      end
    end
  end
  return rows
end

function SL.SnapshotBags()
  local char = SL.Char()
  local rows = readBags(playerBags(), "bag")
  char.bags.items = rows
  char.bags.updated = SL.Now()
  SL.bagsDirty = nil
  return #rows
end

function SL.SnapshotBank(complain)
  if not SL.BankIsOpen() then
    if complain then
      print("|cffe0b060SkillLedger|r open the bank first. The last bank snapshot is kept.")
    end
    return 0
  end
  local char = SL.Char()
  local rows = readBags(bankBags(), "bank")
  char.bank.items = rows
  char.bank.updated = SL.Now()
  if complain then
    print("|cffe0b060SkillLedger|r bank: " .. #rows .. " stacks.")
  end
  return #rows
end

local function standingOk(reaction)
  if type(reaction) ~= "number" then return 4 end
  if reaction >= 1 and reaction <= 8 then return math.floor(reaction) end
  return 4
end

function SL.SnapshotRep()
  local char = SL.Char()
  local rows = {}
  local function add(id, name, standing, earned)
    if not id or not name or name == "" then return end
    rows[#rows + 1] = {
      id = id,
      name = name,
      standing = standingOk(standing),
      earned = tonumber(earned) or 0,
    }
  end
  local function readClassic()
    if not (GetNumFactions and GetFactionInfo and ExpandFactionHeader and CollapseFactionHeader) then
      return false
    end
    local collapsed = {}
    local index = 1
    local guard = 0
    while index <= (GetNumFactions() or 0) and guard < 500 do
      guard = guard + 1
      local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(index)
      if isHeader and isCollapsed then
        collapsed[#collapsed + 1] = name
        ExpandFactionHeader(index)
      end
      index = index + 1
    end
    local total = GetNumFactions() or 0
    for i = 1, total do
      local name, _, standing, _, _, barValue, _, _, isHeader, _, _, _, _, factionId = GetFactionInfo(i)
      if not isHeader then add(factionId, name, standing, barValue) end
    end
    for i = GetNumFactions() or 0, 1, -1 do
      local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
      if isHeader and not isCollapsed then
        for c = 1, #collapsed do
          if collapsed[c] == name then
            CollapseFactionHeader(i)
            break
          end
        end
      end
    end
    return true
  end
  local okClassic = pcall(readClassic)
  if not okClassic or #rows == 0 then
    rows = {}
    if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
      pcall(function()
        if C_Reputation.ExpandAllFactionHeaders then C_Reputation.ExpandAllFactionHeaders() end
        local n = C_Reputation.GetNumFactions() or 0
        for i = 1, n do
          local data = C_Reputation.GetFactionDataByIndex(i)
          if type(data) == "table" and not data.isHeader then
            add(data.factionID, data.name, data.reaction, data.currentStanding)
          end
        end
      end)
    end
  end
  if #rows > 0 then
    char.standings.factions = rows
    char.standings.updated = SL.Now()
  end
  return #rows
end

local function npcIdFromUnit()
  if not UnitGUID or not strsplit then return nil, nil end
  local guid = UnitGUID("npc")
  if not guid then return nil, nil end
  local unitType, _, _, _, _, id = strsplit("-", guid)
  local npcId = nil
  if unitType == "Creature" or unitType == "Vehicle" then npcId = tonumber(id) end
  local name = UnitName and UnitName("npc") or nil
  return npcId, name
end

local function merchantCount()
  if GetMerchantNumItems then
    local ok, count = pcall(GetMerchantNumItems)
    if ok and type(count) == "number" then return count end
  end
  return 0
end

local function merchantSlot(index)
  if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
    local ok, info = pcall(C_MerchantFrame.GetItemInfo, index)
    if ok and type(info) == "table" then
      local id = info.itemID or itemIdFromLink(info.itemLink or info.hyperlink)
      local price = info.price or info.stackPrice
      local stack = info.stackCount or info.quantity or 1
      return id, info.name, price, stack
    end
  end
  if GetMerchantItemInfo then
    local name, _, price, quantity = GetMerchantItemInfo(index)
    local link = GetMerchantItemLink and GetMerchantItemLink(index) or nil
    local id = nil
    if GetMerchantItemID then
      local ok, value = pcall(GetMerchantItemID, index)
      if ok then id = value end
    end
    id = id or itemIdFromLink(link)
    return id, name or nameFromLink(link), price, quantity or 1
  end
  return nil
end

function SL.SnapshotMerchant()
  if not SL.MerchantIsOpen() then return 0 end
  local char = SL.Char()
  local npcId, npcName = npcIdFromUnit()
  local factionId, factionName, side
  local known = npcId and SkillLedgerData and SkillLedgerData.npcs and SkillLedgerData.npcs[npcId]
  if known then
    factionId = known.faction
    factionName = known.name
    side = known.side
  end
  local standing = nil
  if factionId then
    for i = 1, #char.standings.factions do
      local row = char.standings.factions[i]
      if row.id == factionId then standing = row.standing end
    end
  end
  local byId = {}
  for i = 1, #char.merchant.rows do
    local row = char.merchant.rows[i]
    if row.id then byId[row.id] = row end
  end
  local now = SL.Now()
  local count = merchantCount()
  local seen = 0
  for index = 1, count do
    local id, name, price, stack = merchantSlot(index)
    stack = stack or 1
    if stack < 1 then stack = 1 end
    if id and price and price > 0 then
      local unit = math.floor(price / stack)
      if unit > 0 then
        local current = byId[id]
        if not current or unit <= (current.unit or unit) then
          local knownName = SkillLedgerData and SkillLedgerData.items and SkillLedgerData.items[id]
          byId[id] = {
            id = id,
            name = knownName or name or ("Item " .. id),
            unit = unit,
            stackPrice = price,
            stack = stack,
            npc = npcName,
            npcId = npcId,
            factionId = factionId,
            faction = factionName,
            side = side,
            standing = standing,
            at = now,
          }
        end
        seen = seen + 1
      end
    end
  end
  local rows = {}
  for _, row in pairs(byId) do rows[#rows + 1] = row end
  table.sort(rows, function(a, b) return a.id < b.id end)
  char.merchant.rows = rows
  char.merchant.updated = now
  return seen
end

local function chat(text)
  print("|cffe0b060SkillLedger|r " .. text)
end

function SL.CancelScan()
  scan.token = scan.token + 1
  scan.active = false
  scan.mode = nil
end

function SL.ScanStatus()
  if scan.active then
    if scan.mode == "reagents" and scan.queue then
      local at = (scan.query or 1) - 1
      if at < 0 then at = 0 end
      return "Scanning reagents " .. at .. " / " .. #scan.queue .. "."
    end
    if scan.total and scan.total > 0 and scan.index then
      return "Reading auctions " .. scan.index .. " / " .. scan.total .. "."
    end
    return "Scan running."
  end
  local prices = SL.DB and SL.DB() and SL.DB().prices
  local when = prices and prices.updated
  if not when or when == 0 then
    return "No scan yet."
  end
  local count = 0
  for i = 1, #(prices.items or {}) do
    if prices.items[i].unit and prices.items[i].unit > 0 then count = count + 1 end
  end
  local clock = when
  if date then clock = date("%Y-%m-%d %H:%M", when) end
  return "Last scan " .. clock .. " (" .. count .. " prices)."
end

local function showStatus()
  if SL.RefreshAHPanel then SL.RefreshAHPanel() end
end

local function consider(working, itemId, name, buyout, count)
  if not itemId or not buyout or buyout <= 0 or not count or count <= 0 then return end
  local unit = math.floor(buyout / count)
  if unit <= 0 then return end
  local row = working[itemId]
  if not row then
    working[itemId] = { unit = unit, qty = count, total = count, name = name }
    return
  end
  row.total = row.total + count
  if name and name ~= "" then row.name = name end
  if unit < row.unit then
    row.unit = unit
    row.qty = count
  elseif unit == row.unit then
    row.qty = row.qty + count
  end
end

local function commitPrices(working, mode)
  local db = SL.DB()
  local now = SL.Now()
  local byId = {}
  if mode ~= "full" then
    for i = 1, #db.prices.items do
      local row = db.prices.items[i]
      if row.id then byId[row.id] = row end
    end
  end
  for itemId, row in pairs(working) do
    local known = SkillLedgerData and SkillLedgerData.items and SkillLedgerData.items[itemId]
    byId[itemId] = {
      id = itemId,
      name = known or row.name or ("Item " .. itemId),
      unit = row.unit,
      qty = row.qty,
      total = row.total,
      at = now,
      source = "scan",
    }
  end
  if scan.misses then
    for itemId, itemName in pairs(scan.misses) do
      if not working[itemId] then
        local known = SkillLedgerData and SkillLedgerData.items and SkillLedgerData.items[itemId]
        byId[itemId] = {
          id = itemId, name = known or itemName, unit = 0, qty = 0, total = 0, at = now, source = "scan",
        }
      end
    end
  end
  local items = {}
  for _, row in pairs(byId) do items[#items + 1] = row end
  table.sort(items, function(a, b) return a.id < b.id end)
  db.prices.items = items
  db.prices.updated = now
  db.prices.full = mode == "full"
  local priced = 0
  for i = 1, #items do if items[i].unit and items[i].unit > 0 then priced = priced + 1 end end
  chat("auction scan saved " .. priced .. " prices.")
  SL.CancelScan()
  showStatus()
  if SL.Refresh then SL.Refresh() end
end

local function finishList(working, mode)
  local total = scan.total or 0
  local function step()
    if not scan.active or scan.token ~= scan.yieldToken then return end
    local last = math.min(scan.index + 200, total)
    while scan.index < last do
      scan.index = scan.index + 1
      local index = scan.index
      if scan.replicateZero then index = scan.index - 1 end
      local name, count, buyout, itemId, link
      if scan.replicate then
        link = C_AuctionHouse.GetReplicateItemLink and C_AuctionHouse.GetReplicateItemLink(index) or nil
        local ok, a, _, c, _, _, _, _, _, _, j, _, _, _, _, _, _, q = pcall(C_AuctionHouse.GetReplicateItemInfo, index)
        if ok and type(a) == "table" then
          name = a.name or a.itemName
          count = a.count or a.stackCount
          buyout = a.buyoutPrice or a.buyout or a.price
          itemId = a.itemID or a.itemId
        elseif ok then
          name, count, buyout, itemId = a, c, j, q
        end
      else
        link = GetAuctionItemLink and GetAuctionItemLink("list", scan.index) or nil
        local ok, a, _, c, _, _, _, _, _, _, j, _, _, _, _, _, _, q = pcall(GetAuctionItemInfo, "list", scan.index)
        if ok and type(a) == "table" then
          name = a.name or a.itemName
          count = a.count or a.stackCount
          buyout = a.buyoutPrice or a.buyout or a.price
          itemId = a.itemID or a.itemId
        elseif ok then
          name, count, buyout, itemId = a, c, j, q
        end
      end
      itemId = itemId or itemIdFromLink(link)
      name = name or nameFromLink(link)
      consider(working, itemId, name, buyout, count)
    end
    if scan.index < total then
      showStatus()
      if C_Timer and C_Timer.After then C_Timer.After(0.01, step) end
    else
      commitPrices(working, mode)
    end
  end
  scan.yieldToken = scan.token
  scan.index = 0
  if total <= 0 then
    commitPrices(working, mode)
    return
  end
  step()
end

local function reagentQueue()
  local wanted, seen = {}, {}
  local recipes = SkillLedgerData and SkillLedgerData.recipes or {}
  for i = 1, #recipes do
    local reagents = recipes[i].reagents
    for r = 1, #reagents do
      local id = reagents[r][1]
      if not seen[id] then
        seen[id] = true
        local name = SkillLedgerData.items and SkillLedgerData.items[id]
        if name then wanted[#wanted + 1] = { id = id, name = name } end
      end
    end
  end
  table.sort(wanted, function(a, b) return a.name < b.name end)
  return wanted
end

local function sendQuery()
  if not scan.active then return end
  local entry = scan.queue[scan.query]
  if not entry then
    commitPrices(scan.working, "reagents")
    return
  end
  local can = true
  if CanSendAuctionQuery then
    local ok, allowed = pcall(CanSendAuctionQuery)
    if ok then can = allowed and true or false end
  end
  if not can then
    if C_Timer and C_Timer.After then C_Timer.After(0.4, sendQuery) end
    return
  end
  scan.waiting = true
  local ok = pcall(QueryAuctionItems, entry.name, nil, nil, scan.page or 0, nil, nil, false, true)
  if not ok then
    pcall(QueryAuctionItems, entry.name, nil, nil, scan.page or 0, false, nil, false)
  end
end

local function onListUpdate()
  if not scan.active or not scan.waiting then return end
  scan.waiting = false
  local count, total = 0, 0
  if GetNumAuctionItems then
    local ok, c, t = pcall(GetNumAuctionItems, "list")
    if ok then count, total = c or 0, t or 0 end
  end
  local entry = scan.queue and scan.queue[scan.query]
  if scan.mode == "getall" then
    scan.total = count
    scan.replicate = false
    finishList(scan.working, "full")
    return
  end
  if count == 0 and entry then
    scan.misses[entry.id] = entry.name
  else
    for i = 1, count do
      local link = GetAuctionItemLink and GetAuctionItemLink("list", i) or nil
      local ok, name, _, stack, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemId = pcall(GetAuctionItemInfo, "list", i)
      if ok then
        consider(scan.working, itemId or itemIdFromLink(link), name or nameFromLink(link), buyout, stack)
      end
    end
  end
  local page = scan.page or 0
  if total > (page + 1) * 50 and page < 20 then
    scan.page = page + 1
    showStatus()
    if C_Timer and C_Timer.After then C_Timer.After(0.3, sendQuery) end
    return
  end
  scan.query = scan.query + 1
  scan.page = 0
  if scan.query % 25 == 0 then
    chat("auction queries " .. (scan.query - 1) .. "/" .. #scan.queue)
  end
  showStatus()
  if C_Timer and C_Timer.After then C_Timer.After(0.3, sendQuery) end
end

local function onReplicate()
  if not scan.active or scan.mode ~= "replicate" then return end
  local count = 0
  if C_AuctionHouse and C_AuctionHouse.GetNumReplicateItems then
    local ok, value = pcall(C_AuctionHouse.GetNumReplicateItems)
    if ok then count = value or 0 end
  end
  scan.pending = count
  local token = scan.token
  if not C_Timer or not C_Timer.After then return end
  C_Timer.After(0.6, function()
    if not scan.active or scan.token ~= token or scan.mode ~= "replicate" then return end
    local now = scan.pending
    if C_AuctionHouse and C_AuctionHouse.GetNumReplicateItems then
      local ok, value = pcall(C_AuctionHouse.GetNumReplicateItems)
      if ok then now = value or 0 end
    end
    if now ~= scan.pending then return end
    scan.total = now
    scan.replicate = true
    scan.replicateZero = true
    if now > 0 then
      local link = C_AuctionHouse.GetReplicateItemLink and C_AuctionHouse.GetReplicateItemLink(0) or nil
      if not link then
        local one = C_AuctionHouse.GetReplicateItemLink and C_AuctionHouse.GetReplicateItemLink(1) or nil
        if one then scan.replicateZero = false end
      end
    end
    finishList(scan.working, "full")
  end)
end

function SL.OnAuctionEvent(event)
  if event == "REPLICATE_ITEM_LIST_UPDATE" then
    onReplicate()
  else
    onListUpdate()
  end
end

function SL.StartScan()
  local open = (AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown())
    or (AuctionFrame and AuctionFrame.IsShown and AuctionFrame:IsShown())
  if not open then
    chat("open the auction house, then use the SkillLedger tab or /skillledger scan.")
    return
  end
  if scan.active then
    chat("a scan is already running.")
    return
  end
  scan.token = scan.token + 1
  scan.active = true
  scan.working = {}
  scan.misses = {}
  scan.page = 0
  scan.query = 1
  scan.waiting = false
  scan.replicate = false
  showStatus()
  if C_AuctionHouse and C_AuctionHouse.ReplicateItems then
    local ready = true
    if C_AuctionHouse.IsThrottledMessageSystemReady then
      local ok, value = pcall(C_AuctionHouse.IsThrottledMessageSystemReady)
      if ok and value == false then ready = false end
    end
    if ready then
      local ok = pcall(C_AuctionHouse.ReplicateItems)
      if ok then
        scan.mode = "replicate"
        chat("full auction scan started.")
        return
      end
    else
      chat("the auction house is still throttled. Try the scan again in a moment.")
      SL.CancelScan()
      return
    end
  end
  if QueryAuctionItems and CanSendAuctionQuery then
    local ok, _, canAll = pcall(CanSendAuctionQuery)
    if ok and canAll then
      local sent = pcall(QueryAuctionItems, "", nil, nil, 0, nil, nil, true)
      if sent then
        scan.mode = "getall"
        scan.waiting = true
        chat("full auction scan started.")
        return
      end
    end
  end
  if not QueryAuctionItems then
    chat("this client has no auction query API.")
    SL.CancelScan()
    return
  end
  scan.mode = "reagents"
  scan.queue = reagentQueue()
  chat("full scan is not available. Querying " .. #scan.queue .. " reagent names, slowly.")
  sendQuery()
end
