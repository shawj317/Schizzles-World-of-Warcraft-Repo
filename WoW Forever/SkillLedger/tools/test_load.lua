-- Load every addon file the way the TOC does, with a client that rejects
-- unknown events. Slash commands must exist even if a later RegisterEvent throws.
local root = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("tools[\\/]test_load%.lua$", "")
local addon = root .. "AddOns/SkillLedger/"

hash_SlashCmdList = {}
SlashCmdList = {}
local frames = {}
function CreateFrame()
  local frame = { events = {} }
  function frame:SetScript(_, fn) self.script = fn end
  function frame:RegisterEvent(name)
    if name == "AUCTION_ITEM_LIST_UPDATE" then
      error("unknown event " .. name)
    end
    self.events[name] = true
  end
  function frame:SetSize() end
  function frame:SetFrameStrata() end
  function frame:SetClampedToScreen() end
  function frame:SetMovable() end
  function frame:EnableMouse() end
  function frame:RegisterForDrag() end
  function frame:EnableKeyboard() end
  function frame:SetPropagateKeyboardInput() end
  function frame:SetPoint() end
  function frame:Show() self.shown = true end
  function frame:Hide() self.shown = false end
  function frame:IsShown() return self.shown end
  function frame:CreateFontString()
    local fs = {}
    function fs:SetFont() end
    function fs:SetTextColor() end
    function fs:SetText() end
    function fs:SetPoint() end
    function fs:SetJustifyH() end
    function fs:SetJustifyV() end
    function fs:SetWidth() end
    function fs:GetStringHeight() return 10 end
    function fs:SetHeight() end
    function fs:GetParent() return frame end
    return fs
  end
  function frame:CreateTexture()
    local tex = {}
    function tex:SetAllPoints() end
    function tex:SetPoint() end
    function tex:SetColorTexture() end
    function tex:SetTexture() end
    function tex:SetVertexColor() end
    return tex
  end
  frames[#frames + 1] = frame
  return frame
end

local files = {}
for line in io.lines(addon .. "SkillLedger.toc") do
  local name = line:match("^%s*([^#%s].-%.lua)%s*$")
  if name then files[#files + 1] = name end
end
assert(#files > 10, "TOC did not list the data files")
for i = 1, #files do
  local chunk, err = loadfile(addon .. files[i])
  if not chunk then
    io.stderr:write(files[i] .. " failed to compile: " .. tostring(err) .. "\n")
    os.exit(1)
  end
  local ok, runErr = pcall(chunk)
  if not ok then
    io.stderr:write(files[i] .. " failed to run: " .. tostring(runErr) .. "\n")
    os.exit(1)
  end
end

assert(SlashCmdList.SKILLLEDGER, "slash handler missing")
assert(SLASH_SKILLLEDGER1 == "/skillledger", SLASH_SKILLLEDGER1)
assert(SLASH_SKILLLEDGER2 == "/sl", SLASH_SKILLLEDGER2)
assert(hash_SlashCmdList["/SKILLLEDGER"] == "SKILLLEDGER")
assert(hash_SlashCmdList["/SL"] == "SKILLLEDGER")
assert(SkillLedger.ready, "ready flag missing")
assert(SkillLedger.EnsureAHTab, "auction tab missing")
assert(not SkillLedger.AnchorScanButton, "old overlapping button is still defined")
SlashCmdList.SKILLLEDGER("help")

local said = {}
function SkillLedger.Say(message) said[#said + 1] = message end
C_AuctionHouse = {
  ReplicateItems = function() end,
  IsThrottledMessageSystemReady = function() return true end,
}
AuctionHouseFrame = {}
function AuctionHouseFrame:IsShown() return true end
SkillLedger.StartScan()
local started = false
for i = 1, #said do
  if said[i]:find("ReplicateItems", 1, true) then started = true end
end
assert(started, "full scan did not announce C_AuctionHouse.ReplicateItems")

assert(type(SkillLedgerData) == "table", "SkillLedgerData global missing")
assert(type(SkillLedgerData.recipes) == "table" and #SkillLedgerData.recipes > 1000, "recipes missing")
local plans = SkillLedgerPlan.PlanCharacter(
  SkillLedgerData, {},
  { { name = "First Aid", skillLine = 129, rank = 1, maxRank = 20 } },
  { [2589] = 100 }, {}, {}, "Horde", 1, 2, {}
)
assert(plans and plans[1] and plans[1].steps and plans[1].steps[1], "plan produced no steps")
assert(plans[1].steps[1].spell == 3275, "expected Linen Bandage, got " .. tostring(plans[1].steps[1] and plans[1].steps[1].recipe))

local kept = SkillLedgerData
SkillLedgerData = nil
local missing = {}
local previous = SkillLedger.Say
SkillLedger.Say = function(message) missing[#missing + 1] = message end
assert(SkillLedger.Plan() == nil, "plan should stop when data is missing")
assert(missing[1] and missing[1]:find("not loaded", 1, true), "missing-data message not printed")
SkillLedgerData = kept
SkillLedger.Say = previous

local queued = {}
C_Timer = { After = function(_, fn) queued[#queued + 1] = fn end }
TSM_API = {
  GetCustomPriceValue = function(source, item)
    if item ~= "i:2840" then return nil end
    if item == "i:2770" or item == "i:2589" then error("tsm on reagent " .. item) end
    if source == "dbmarket" or source == "dbminbuyout" then error("tsm price " .. source) end
    if item ~= "i:2840" then return nil end
    if source == "dbregionsalerate" then return 0.25 end
    if source == "dbregionsoldperday" then return 3 end
    return nil
  end,
}
Auctionator = { API = { v1 = {
  GetAuctionPriceByItemID = function(_, itemId)
    if itemId == 1251 then return 200 end
    if itemId == 2840 then return 500 end
    if itemId == 800001 then return 10 end
    return nil
  end,
  GetAuctionAgeByItemID = function(_, itemId)
    if itemId == 1251 then return 3600 end
    if itemId == 2840 then return 10 end
    if itemId == 800001 then return 5000 end
    return nil
  end,
}}}
local char = SkillLedger.Char()
local learned = { { spell = 2657, item = 2840, name = "Smelt Copper" } }
for i = 1, 14 do
  learned[#learned + 1] = { item = 800000 + i, name = "Extra" }
end
learned[#learned + 1] = { spell = 3275, item = 1251, name = "Linen Bandage" }
char.learned = { recipes = learned }
local now = SkillLedger.Now()
SkillLedgerDB.prices.items = {
  { id = 2840, unit = 400, at = now - 5000 },
  { id = 800001, unit = 80, at = now - 10 },
}
assert(SkillLedger.SnapshotMarket() == 18)
local function savedMarket()
  local out = {}
  for i = 1, #SkillLedgerDB.market.items do
    out[SkillLedgerDB.market.items[i].id] = SkillLedgerDB.market.items[i]
  end
  return out
end
local saved = savedMarket()
assert(saved[2840] and saved[2840].saleRate == 0.25 and saved[2840].soldPerDay == 3)
assert(saved[2840].market == nil and saved[2840].minBuyout == nil, "TSM market prices should not be stored")
assert(saved[2840].price == 500 and saved[2840].priceSource == "auctionator" and saved[2840].priceAge == 10)
assert(saved[800001] and saved[800001].price == 80 and saved[800001].priceSource == "scan")
assert(saved[1251] == nil, "the item past the first batch should wait")
assert(#queued == 1, "the rest of the market read should wait for a timer, not OnUpdate")
queued[1]()
saved = savedMarket()
assert(saved[1251] and saved[1251].atrPrice == 200 and saved[1251].atrAge == 3600 and saved[1251].saleRate == nil)
assert(saved[1251].price == 200 and saved[1251].priceSource == "auctionator" and saved[1251].priceAge == 3600)
assert(saved[2770] == nil and saved[2589] == nil, "a reagent with no Auctionator price is not stored")
print("load test passed", #SkillLedgerData.recipes, "recipes", plans[1].steps[1].recipe)
