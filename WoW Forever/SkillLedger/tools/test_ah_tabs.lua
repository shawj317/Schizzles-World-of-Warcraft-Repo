-- Proves the auction-house tab anchor against the real LibAHTab rule:
-- rootFrame:SetPoint("TOPLEFT", AuctionHouseFrame.Tabs[#], "TOPRIGHT")
-- and against no other addons. The DisplayMode tab template's parentArray
-- inserts the new button into parent.Tabs. SkillLedger must leave that array.

local root = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("tools[\\/]test_ah_tabs%.lua$", "")
local addon = root .. "AddOns/SkillLedger/AH.lua"

UIParent = { name = "UIParent", children = {} }

local function widget(parent)
  local frame = {
    parent = parent,
    children = {},
    points = nil,
    pointCalls = 0,
    width = 80,
    text = "",
  }
  if parent then
    parent.children = parent.children or {}
    parent.children[#parent.children + 1] = frame
  end
  function frame:SetParent(newParent)
    self.parent = newParent
  end
  function frame:GetParent()
    return self.parent
  end
  function frame:SetSize(w)
    self.width = w or self.width
  end
  function frame:GetSize()
    return 800, 500
  end
  function frame:SetText(text)
    self.text = text
  end
  function frame:GetText()
    return self.text
  end
  function frame:SetScript() end
  function frame:HookScript() end
  function frame:Show() end
  function frame:Hide() end
  function frame:SetFrameLevel() end
  function frame:GetFrameLevel()
    return 1
  end
  function frame:SetAllPoints() end
  function frame:SetColorTexture() end
  function frame:SetTexture() end
  function frame:SetVertexColor() end
  function frame:CreateTexture()
    return widget(nil)
  end
  function frame:CreateFontString()
    local font = widget(nil)
    font.SetFont = function() end
    font.SetTextColor = function() end
    font.SetJustifyH = function() end
    font.SetWidth = function() end
    return font
  end
  function frame:IsObjectType()
    return true
  end
  function frame:ClearAllPoints()
    self.points = nil
  end
  function frame:SetPoint(point, relativeTo, relativePoint, x)
    assert(relativeTo ~= UIParent, self.text .. " anchored to UIParent")
    assert(relativeTo ~= nil, self.text .. " anchored to nil")
    self.points = { point, relativeTo, relativePoint, x or 0 }
    self.pointCalls = self.pointCalls + 1
  end
  function frame:GetPoint()
    if not self.points then return nil end
    return self.points[1], self.points[2], self.points[3], self.points[4], 0
  end
  function frame:GetRight(seen)
    seen = seen or {}
    if seen[self] then return nil end
    seen[self] = true
    if self.fixedRight then return self.fixedRight end
    if not self.points then return nil end
    local rel, relPoint, x = self.points[2], self.points[3], self.points[4]
    if not rel or not rel.GetRight then return nil end
    local base
    if relPoint == "TOPRIGHT" or relPoint == "BOTTOMRIGHT" then
      base = rel:GetRight(seen)
    else
      base = rel.GetLeft and rel:GetLeft(seen)
    end
    if not base then return nil end
    return base + x + (self.width or 80)
  end
  function frame:GetLeft(seen)
    local right = self:GetRight(seen)
    if not right then return nil end
    return right - (self.width or 80)
  end
  function frame:GetChildren()
    return unpack(self.children)
  end
  return frame
end

local timers = {}
C_Timer = {
  After = function(_, fn)
    timers[#timers + 1] = fn
  end,
}
local function flush()
  local batch = timers
  timers = {}
  for i = 1, #batch do batch[i]() end
end

function hooksecurefunc(frame, name, fn)
  local prev = frame[name]
  frame[name] = function(...)
    if prev then prev(...) end
    fn(...)
  end
end
function PanelTemplates_TabResize() end
function PanelTemplates_DeselectTab() end
function PanelTemplates_SelectTab() end

function CreateFrame(_, name, parent, template)
  local frame = widget(parent)
  frame.name = name
  if template == "AuctionHouseFrameDisplayModeTabTemplate" and parent then
    parent.Tabs = parent.Tabs or {}
    parent.Tabs[#parent.Tabs + 1] = frame
  end
  return frame
end

AuctionHouseFrame = widget(UIParent)
AuctionHouseFrame.fixedRight = 1000
AuctionHouseFrame.fixedLeft = 200
AuctionHouseFrame.Tabs = {}
AuctionHouseFrame.SetDisplayMode = function() end
local function chainTab(text, previous)
  local button = CreateFrame("Button", text, AuctionHouseFrame, "AuctionHouseFrameDisplayModeTabTemplate")
  button:SetText(text)
  button.width = 90
  if previous then
    button:SetPoint("TOPLEFT", previous, "TOPRIGHT", 0, 0)
  else
    button:SetPoint("BOTTOMLEFT", AuctionHouseFrame, "BOTTOMLEFT", 20, 0)
  end
  return button
end
local buy = chainTab("Buy", nil)
local sell = chainTab("Sell", buy)
local auctions = chainTab("Auctions", sell)

-- LibAHTab-1-0 (Auctionator/LibAHTab.lua): the root anchors once to
-- AuctionHouseFrame.Tabs[#], and later tabs chain off that root.
local libTabs = {}
local libRoot
local function libCreateTab(tabID)
  if not libRoot then
    libRoot = CreateFrame("Frame", nil, AuctionHouseFrame)
    libRoot:SetSize(10, 10)
    libRoot.width = 10
    libRoot:SetPoint("TOPLEFT", AuctionHouseFrame.Tabs[#AuctionHouseFrame.Tabs], "TOPRIGHT")
  end
  local newTab = CreateFrame("Button", "LibAHFrame-1.0-" .. tabID, libRoot, "AuctionHouseFrameDisplayModeTabTemplate")
  libTabs[#libTabs + 1] = newTab
  newTab:SetText(tabID)
  newTab.width = 100
  if #libTabs > 1 then
    newTab:SetPoint("TOPLEFT", libTabs[#libTabs - 1], "TOPRIGHT", 3, 0)
  else
    newTab:SetPoint("TOPLEFT", libRoot, "TOPLEFT", 3, 0)
  end
  return newTab
end

SkillLedger = {}
dofile(addon)

local function inTabs(button)
  for i = 1, #AuctionHouseFrame.Tabs do
    if AuctionHouseFrame.Tabs[i] == button then return true end
  end
  return false
end

local function anchorOf(button)
  local point, relativeTo, relativePoint = button:GetPoint(1)
  return point, relativeTo, relativePoint
end

SkillLedger.EnsureAHTab()
local ours = _G.SkillLedgerAHTab or nil
-- CreateFrame stored the button only as a local in AH.lua. Find it by name.
local function findNamed(parent, wanted, depth)
  if not parent or depth > 6 then return nil end
  if parent.name == wanted then return parent end
  for i = 1, #parent.children do
    local found = findNamed(parent.children[i], wanted, depth + 1)
    if found then return found end
  end
  return nil
end
ours = findNamed(AuctionHouseFrame, "SkillLedgerAHTab", 0)
assert(ours, "SkillLedger tab was not created")
assert(ours:GetParent() == AuctionHouseFrame, "tab parent is not AuctionHouseFrame")
assert(not inTabs(ours), "template insert was left in AuctionHouseFrame.Tabs")
assert(AuctionHouseFrame.Tabs[#AuctionHouseFrame.Tabs] == auctions, "last Blizzard tab is no longer Auctions")

-- No other addons yet. After the deferred anchor, sit on the Auctions tab.
flush()
flush()
local point, relativeTo, relativePoint = anchorOf(ours)
assert(point == "TOPLEFT", point)
assert(relativePoint == "TOPRIGHT", relativePoint)
assert(relativeTo == auctions, "with no other addons, tab should follow Auctions")
assert(relativeTo ~= UIParent)

-- Auctionator then TSM, in the order Jon sees, using LibAHTab's real rule.
local before = {}
local function snapshot()
  before = {}
  local function walk(frame, depth)
    if not frame or depth > 6 or before[frame] then return end
    before[frame] = frame.pointCalls or 0
    for i = 1, #(frame.children or {}) do walk(frame.children[i], depth + 1) end
  end
  walk(AuctionHouseFrame, 0)
end
local names = { "Shopping", "Selling", "Cancelling", "Auctionator", "TSM" }
local created = {}
for i = 1, #names do
  created[names[i]] = libCreateTab(names[i])
end
local _, libAnchor = libRoot:GetPoint(1)
assert(libAnchor == auctions, "LibAHTab anchored to SkillLedger instead of Auctions")
assert(libAnchor ~= ours, "LibAHTab row starts at SkillLedger")

snapshot()
SkillLedger.EnsureAHTab()
flush()
flush()
point, relativeTo, relativePoint = anchorOf(ours)
assert(point == "TOPLEFT" and relativePoint == "TOPRIGHT", point .. " " .. tostring(relativePoint))
assert(relativeTo == created.TSM, "tab should be after TSM, anchored to " .. tostring(relativeTo and relativeTo.text))
assert(not inTabs(ours), "SkillLedger was put back into AuctionHouseFrame.Tabs")
assert(AuctionHouseFrame.Tabs[1] == buy and AuctionHouseFrame.Tabs[3] == auctions)

local function walk(frame, depth)
  if not frame or depth > 6 then return end
  if frame ~= ours then
    assert((frame.pointCalls or 0) == (before[frame] or 0), "SetPoint ran on " .. tostring(frame.text or frame.name))
  end
  for i = 1, #(frame.children or {}) do walk(frame.children[i], depth + 1) end
end
walk(AuctionHouseFrame, 0)

-- The visible row is Auctions, then the LibAHTab chain, then SkillLedger.
local function nextName(frame)
  local best, bestRight
  local function scan(parent, depth)
    if not parent or depth > 8 then return end
    for i = 1, #(parent.children or {}) do
      local child = parent.children[i]
      local childPoint, rel = child:GetPoint(1)
      if childPoint == "TOPLEFT" and rel == frame then
        local right = child:GetRight()
        if not best or (right and right > (bestRight or -1)) then
          best = child
          bestRight = right
        end
      end
      scan(child, depth + 1)
    end
  end
  scan(AuctionHouseFrame, 0)
  return best
end
local order = {}
local cursor = auctions
for _ = 1, 10 do
  cursor = nextName(cursor)
  if not cursor then break end
  if cursor.text and cursor.text ~= "" then order[#order + 1] = cursor.text end
end
assert(table.concat(order, ",") == "Shopping,Selling,Cancelling,Auctionator,TSM,SkillLedger", table.concat(order, ","))
print("ah tab anchor test passed")
