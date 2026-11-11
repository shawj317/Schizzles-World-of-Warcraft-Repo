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
  if SL.Say then
    SL.Say(text)
  else
    print("|cffe0b060SkillLedger|r " .. text)
  end
end

local function chime()
  if not PlaySound then return end
  if SOUNDKIT and SOUNDKIT.READY_CHECK_READY then
    if pcall(PlaySound, SOUNDKIT.READY_CHECK_READY) then return end
  end
  if SOUNDKIT and SOUNDKIT.AUCTION_WINDOW_CLOSE then
    pcall(PlaySound, SOUNDKIT.AUCTION_WINDOW_CLOSE)
  end
end

local function splash(text)
  if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo.RAID_WARNING then
    if pcall(RaidNotice_AddMessage, RaidWarningFrame, text, ChatTypeInfo.RAID_WARNING) then return end
  end
  if UIErrorsFrame and UIErrorsFrame.AddMessage then
    pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text, 1, 0.82, 0, 1)
  end
end

function SL.CancelScan()
  scan.token = scan.token + 1
  scan.active = false
  scan.mode = nil
end

function SL.ScanStatus()
  if scan.active then
    if scan.waitingThrottle then
      return "Waiting for the auction house throttle (" .. (scan.path or "scan") .. ")."
    end
    if (scan.mode == "reagents" or scan.mode == "search") and scan.queue then
      local at = (scan.query or 1) - 1
      if at < 0 then at = 0 end
      return "Scanning " .. at .. " / " .. #scan.queue .. " (" .. (scan.path or "search") .. ")."
    end
    if scan.total and scan.total > 0 and scan.index then
      return "Reading auctions " .. scan.index .. " / " .. scan.total .. " (" .. (scan.path or "replicate") .. ")."
    end
    return "Scan running (" .. (scan.path or "auction house") .. ")."
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
  local path = scan.path or mode or "scan"
  local detail = priced == 0 and " The auction house returned no listings." or ""
  chat("Scan complete (" .. path .. "): " .. priced .. " prices saved." .. detail)
  splash("SkillLedger: scan complete, " .. priced .. " prices saved")
  chime()
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

function SL.AbortScan(reason)
  if not scan.active then return end
  SL.CancelScan()
  chat(reason)
  splash("SkillLedger: " .. reason)
  showStatus()
end

local function ahOpen()
  if AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown() then return true end
  if AuctionFrame and AuctionFrame.IsShown and AuctionFrame:IsShown() then return true end
  return false
end

local function throttleReady()
  if not C_AuctionHouse or not C_AuctionHouse.IsThrottledMessageSystemReady then return true end
  local ok, value = pcall(C_AuctionHouse.IsThrottledMessageSystemReady)
  if not ok then return true end
  return value and true or false
end

local function noteUnit(itemId, name, unit, listed)
  if not itemId or not unit or unit <= 0 then return end
  listed = listed or 1
  if listed <= 0 then listed = 1 end
  consider(scan.working, itemId, name, unit * listed, listed)
end

local function readCommodity(itemId, name)
  if not C_AuctionHouse.GetNumCommoditySearchResults then return false end
  local ok, count = pcall(C_AuctionHouse.GetNumCommoditySearchResults, itemId)
  if not ok or not count or count < 1 then return false end
  local best, qty = nil, 0
  for i = 1, count do
    local okInfo, info = pcall(C_AuctionHouse.GetCommoditySearchResultInfo, itemId, i)
    if okInfo and type(info) == "table" and info.unitPrice and info.unitPrice > 0 then
      local q = info.quantity or 1
      qty = qty + q
      if not best or info.unitPrice < best then best = info.unitPrice end
    end
  end
  if best then noteUnit(itemId, name, best, qty) end
  return true
end

local function readItemKey(itemKey, name)
  if not itemKey or not C_AuctionHouse.GetNumItemSearchResults then return false end
  local ok, count = pcall(C_AuctionHouse.GetNumItemSearchResults, itemKey)
  if not ok or not count or count < 1 then return false end
  local best, qty = nil, 0
  for i = 1, count do
    local okInfo, info = pcall(C_AuctionHouse.GetItemSearchResultInfo, itemKey, i)
    if okInfo and type(info) == "table" then
      local price = info.buyoutAmount or info.buyoutPrice
      local q = info.quantity or 1
      if price and price > 0 then
        qty = qty + q
        local unit = math.floor(price / q)
        if unit > 0 and (not best or unit < best) then best = unit end
      end
    end
  end
  if best then noteUnit(itemKey.itemID, name, best, qty) end
  return best ~= nil
end

local function readBrowse(onlyId)
  if not C_AuctionHouse.GetBrowseResults then return false end
  local ok, results = pcall(C_AuctionHouse.GetBrowseResults)
  if not ok or type(results) ~= "table" then return false end
  local found = false
  for i = 1, #results do
    local row = results[i]
    local key = row and row.itemKey
    local id = key and key.itemID
    if id and (not onlyId or id == onlyId) and row.minPrice and row.minPrice > 0 then
      noteUnit(id, nil, row.minPrice, row.totalQuantity or 1)
      found = true
    end
  end
  return found
end

local function priceSorts()
  if Enum and Enum.AuctionHouseSortOrder then
    return { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } }
  end
  return {}
end

local function itemKeyFor(itemId)
  if C_AuctionHouse.MakeItemKey then
    local ok, key = pcall(C_AuctionHouse.MakeItemKey, itemId)
    if ok and type(key) == "table" then return key end
  end
  return { itemID = itemId, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 }
end

local sendNextSearch

local function armSearchTimeout()
  local token = scan.token
  if not C_Timer or not C_Timer.After then return end
  C_Timer.After(8, function()
    if not scan.active or scan.token ~= token or not scan.waitingResult then return end
    scan.waitingResult = false
    local entry = scan.pendingItem
    if entry then scan.misses[entry.id] = entry.name end
    scan.query = (scan.query or 1) + 1
    chat("No answer for " .. (entry and entry.name or "a reagent") .. ". Continuing.")
    sendNextSearch()
  end)
end

sendNextSearch = function()
  if not scan.active or scan.mode ~= "search" then return end
  if not ahOpen() then
    SL.AbortScan("Auction house closed. Scan stopped.")
    return
  end
  local queue = scan.queue or {}
  local index = scan.query or 1
  if index > #queue then
    commitPrices(scan.working, "search")
    return
  end
  if not throttleReady() then
    scan.waitingThrottle = true
    showStatus()
    return
  end
  local entry = queue[index]
  scan.pendingItem = entry
  scan.pendingKey = itemKeyFor(entry.id)
  scan.waitingResult = true
  scan.waitingThrottle = false
  local ok, err = pcall(C_AuctionHouse.SendSearchQuery, scan.pendingKey, priceSorts(), false)
  if not ok and C_AuctionHouse.SendBrowseQuery then
    local filters = {}
    if Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.ExactMatch then
      filters[1] = Enum.AuctionHouseFilter.ExactMatch
    end
    ok, err = pcall(C_AuctionHouse.SendBrowseQuery, {
      searchString = entry.name,
      sorts = priceSorts(),
      filters = filters,
    })
    scan.browseFallback = ok and true or false
  else
    scan.browseFallback = false
  end
  if not ok then
    scan.waitingResult = false
    chat("Query failed for " .. entry.name .. ": " .. tostring(err))
    scan.misses[entry.id] = entry.name
    scan.query = index + 1
    if C_Timer and C_Timer.After then C_Timer.After(0.2, sendNextSearch) else sendNextSearch() end
    return
  end
  if index == 1 or index % 25 == 0 then
    chat("Reagent search " .. index .. "/" .. #queue .. " (" .. entry.name .. ").")
  end
  showStatus()
  armSearchTimeout()
end

local function startReagentSearch(why)
  if not C_AuctionHouse or not (C_AuctionHouse.SendSearchQuery or C_AuctionHouse.SendBrowseQuery) then
    SL.AbortScan("No C_AuctionHouse search API on this client.")
    return
  end
  scan.mode = "search"
  scan.path = "C_AuctionHouse.SendSearchQuery"
  scan.queue = reagentQueue()
  scan.query = 1
  scan.waitingResult = false
  scan.waitingThrottle = false
  if #scan.queue == 0 then
    SL.AbortScan("No reagent names are bundled, so there is nothing to search.")
    return
  end
  chat((why or "Full scan is not available.") .. " Searching " .. #scan.queue .. " reagents with C_AuctionHouse.SendSearchQuery.")
  showStatus()
  sendNextSearch()
end

local function tryReplicate()
  if not scan.active then return end
  if not ahOpen() then
    SL.AbortScan("Auction house closed. Scan stopped.")
    return
  end
  if not throttleReady() then
    scan.waitingThrottle = true
    scan.mode = "replicate"
    chat("The auction house is throttled. Waiting, then C_AuctionHouse.ReplicateItems will run.")
    showStatus()
    return
  end
  scan.mode = "replicate"
  scan.path = "C_AuctionHouse.ReplicateItems"
  scan.waitingThrottle = false
  local ok, err = pcall(C_AuctionHouse.ReplicateItems)
  if not ok then
    chat("C_AuctionHouse.ReplicateItems failed: " .. tostring(err))
    startReagentSearch("Full scan failed.")
    return
  end
  chat("Full scan started (C_AuctionHouse.ReplicateItems).")
  showStatus()
  local token = scan.token
  if C_Timer and C_Timer.After then
    C_Timer.After(20, function()
      if scan.active and scan.token == token and scan.mode == "replicate" and (scan.index or 0) == 0 and not scan.replicateSawEvent then
        chat("Full scan returned nothing. Switching to a reagent search.")
        startReagentSearch("Full scan returned nothing.")
      end
    end)
  end
end

function SL.OnAuctionEvent(event, arg1)
  if event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
    if scan.active and scan.waitingThrottle then
      scan.waitingThrottle = false
      chat("Auction house throttle cleared.")
      if scan.mode == "replicate" then tryReplicate()
      elseif scan.mode == "search" then sendNextSearch() end
    end
    return
  end
  if event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
    if scan.active then
      chat("The auction house dropped a query. It will be sent again when the throttle clears.")
      scan.waitingThrottle = true
      scan.waitingResult = false
      showStatus()
    end
    return
  end
  if event == "REPLICATE_ITEM_LIST_UPDATE" then
    scan.replicateSawEvent = true
    onReplicate()
    return
  end
  if event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
    if not scan.active or scan.mode ~= "search" or not scan.waitingResult then return end
    local entry = scan.pendingItem
    if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
      local id = tonumber(arg1) or (entry and entry.id)
      if entry and id and id ~= entry.id then return end
      if entry then readCommodity(entry.id, entry.name) end
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
      local key = type(arg1) == "table" and arg1 or scan.pendingKey
      if entry and key and key.itemID and key.itemID ~= entry.id then return end
      if entry then readItemKey(key or scan.pendingKey, entry.name) end
    else
      if entry then readBrowse(entry.id) end
    end
    scan.waitingResult = false
    scan.query = (scan.query or 1) + 1
    showStatus()
    if C_Timer and C_Timer.After then C_Timer.After(0.05, sendNextSearch) else sendNextSearch() end
    return
  end
  onListUpdate()
end

function SL.StartScan()
  if not ahOpen() then
    chat("Open the auction house, then use the SkillLedger tab or /skillledger scan.")
    return
  end
  if scan.active then
    chat("A scan is already running.")
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
  scan.replicateSawEvent = false
  scan.index = 0
  scan.total = 0
  showStatus()
  if C_AuctionHouse and C_AuctionHouse.ReplicateItems then
    tryReplicate()
    return
  end
  if C_AuctionHouse and (C_AuctionHouse.SendSearchQuery or C_AuctionHouse.SendBrowseQuery) then
    startReagentSearch("This client has no full-scan call.")
    return
  end
  if QueryAuctionItems and CanSendAuctionQuery then
    local ok, _, canAll = pcall(CanSendAuctionQuery)
    if ok and canAll then
      scan.mode = "getall"
      scan.path = "QueryAuctionItems"
      scan.waiting = true
      local sent, err = pcall(QueryAuctionItems, "", nil, nil, 0, nil, nil, true)
      if sent then
        chat("Full scan started (classic QueryAuctionItems).")
        showStatus()
        return
      end
      chat("Classic full scan failed: " .. tostring(err))
    end
    scan.mode = "reagents"
    scan.path = "QueryAuctionItems"
    scan.queue = reagentQueue()
    if #scan.queue == 0 then
      SL.AbortScan("No reagent names are bundled, so there is nothing to search.")
      return
    end
    chat("Querying " .. #scan.queue .. " reagent names with QueryAuctionItems.")
    showStatus()
    sendQuery()
    return
  end
  SL.AbortScan("This client has no auction scan API.")
end
