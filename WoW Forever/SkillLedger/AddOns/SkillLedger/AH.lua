-- Auction House tab. Sits on the bottom tab row after whatever tabs are already
-- there (Browse, Bids, Auctions, Auctionator, TSM, and so on). No OnUpdate.

local SL = SkillLedger

local tab
local panel
local statusText
local host
local hookedSetTab = false
local layoutToken = 0

local function classicHost()
  if AuctionFrame and (AuctionFrameBrowse or _G.AuctionFrameTab1) then
    return AuctionFrame
  end
  return nil
end

local function modernHost()
  if AuctionHouseFrame then return AuctionHouseFrame end
  return nil
end

local function remember(list, button)
  if not button or button == tab then return end
  for i = 1, #list do
    if list[i] == button then return end
  end
  list[#list + 1] = button
end

local function namedTabs()
  local list = {}
  local i = 1
  while i < 30 do
    local button = _G["AuctionFrameTab" .. i] or _G["AuctionHouseFrameTab" .. i]
    if not button then break end
    remember(list, button)
    i = i + 1
  end
  return list
end

local function alongBottom(parent)
  local list = namedTabs()
  if not parent or not parent.GetChildren or not parent.GetBottom then return list end
  local parentBottom = parent:GetBottom()
  if not parentBottom then return list end
  local children = { parent:GetChildren() }
  for i = 1, #children do
    local child = children[i]
    if child and child.GetObjectType and child:GetObjectType() == "Button" and child.GetBottom and child:GetBottom() then
      local id = child.GetID and child:GetID() or 0
      local gap = child:GetBottom() - parentBottom
      if id > 0 and gap > -30 and gap < 40 then
        remember(list, child)
      end
    end
  end
  if parent.Tabs then
    for i = 1, #parent.Tabs do remember(list, parent.Tabs[i]) end
  end
  return list
end

local function rightmost(list)
  local best, bestRight
  for i = 1, #list do
    local button = list[i]
    local right = button.GetRight and button:GetRight()
    if right and (not bestRight or right > bestRight) then
      best = button
      bestRight = right
    end
  end
  return best
end

local function hideBlizzardPages()
  if AuctionFrameBrowse then AuctionFrameBrowse:Hide() end
  if AuctionFrameBids then AuctionFrameBids:Hide() end
  if AuctionFrameAuctions then AuctionFrameAuctions:Hide() end
end

local function showOthers()
  if panel then panel:Hide() end
end

function SL.HideAHPanel()
  showOthers()
end

function SL.RefreshAHPanel()
  if statusText then statusText:SetText(SL.ScanStatus and SL.ScanStatus() or "") end
end

local function selectUs()
  if not tab or not host then return end
  if AuctionFrameTab_OnClick and host == AuctionFrame then
    pcall(AuctionFrameTab_OnClick, tab)
  elseif PanelTemplates_SetTab then
    pcall(PanelTemplates_SetTab, host, tab:GetID())
  end
  hideBlizzardPages()
  if panel then
    panel:Show()
    SL.RefreshAHPanel()
  end
end

local function watchTab(button)
  if not button or button == tab or button.skillLedgerHooked or not button.HookScript then return end
  button.skillLedgerHooked = true
  button:HookScript("OnClick", function(self)
    if self ~= tab then showOthers() end
  end)
end

local function place()
  if not tab or not host then return end
  local others = alongBottom(host)
  for i = 1, #others do watchTab(others[i]) end
  local anchor = rightmost(others)
  tab:ClearAllPoints()
  if anchor then
    tab:SetPoint("LEFT", anchor, "RIGHT", -15, 0)
  elseif _G.AuctionFrameTab1 then
    tab:SetPoint("LEFT", _G.AuctionFrameTab1, "RIGHT", -15, 0)
  else
    tab:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 20, -30)
  end
end

local function paint(widget)
  local backdrop = widget:CreateTexture(nil, "BACKGROUND")
  backdrop:SetAllPoints()
  if backdrop.SetColorTexture then
    backdrop:SetColorTexture(0.06, 0.06, 0.06, 0.92)
  else
    backdrop:SetTexture("Interface\\Buttons\\WHITE8x8")
    backdrop:SetVertexColor(0.06, 0.06, 0.06, 0.92)
  end
end

local function makeTab(parent)
  local id = (parent.numTabs or 0) + 1
  while _G["AuctionFrameTab" .. id] or _G["AuctionHouseFrameTab" .. id] do
    id = id + 1
  end
  local name = (parent == AuctionFrame) and ("AuctionFrameTab" .. id) or ("AuctionHouseFrameTab" .. id)
  local button
  local templates = { "AuctionTabTemplate", "CharacterFrameTabButtonTemplate", "PanelTabButtonTemplate" }
  for i = 1, #templates do
    local ok, created = pcall(CreateFrame, "Button", name, parent, templates[i])
    if ok and created then
      button = created
      break
    end
  end
  if not button then
    button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetSize(110, 24)
  end
  button:SetID(id)
  button:SetText("SkillLedger")
  if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, button, 0) end
  if PanelTemplates_SetNumTabs then
    local count = parent.numTabs or 0
    if id > count then pcall(PanelTemplates_SetNumTabs, parent, id) end
  end
  if PanelTemplates_EnableTab then pcall(PanelTemplates_EnableTab, parent, id) end
  button:SetScript("OnClick", function()
    selectUs()
  end)
  return button
end

local function makePanel(parent)
  local frame = CreateFrame("Frame", "SkillLedgerAHPanel", parent)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -70)
  frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -18, 36)
  paint(frame)
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("SkillLedger")
  statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  statusText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  statusText:SetJustifyH("LEFT")
  statusText:SetWidth(420)
  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetSize(120, 24)
  button:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -16)
  button:SetText("Scan")
  button:SetScript("OnClick", function()
    if SL.StartScan then SL.StartScan() end
    SL.RefreshAHPanel()
  end)
  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  note:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -12)
  note:SetJustifyH("LEFT")
  note:SetWidth(420)
  note:SetText("One full scan when the client allows it. Otherwise the reagent list, slowly. The window stays on this tab until you pick another.")
  frame:Hide()
  return frame
end

function SL.EnsureAHTab()
  host = classicHost() or modernHost()
  if not host or not CreateFrame then return end
  if not tab then
    local ok, created = pcall(makeTab, host)
    if not ok or not created then return end
    tab = created
  end
  if not panel then
    local ok, created = pcall(makePanel, host)
    if ok then panel = created end
  end
  if not hookedSetTab and hooksecurefunc and PanelTemplates_SetTab then
    hookedSetTab = true
    hooksecurefunc("PanelTemplates_SetTab", function(frame, id)
      if frame == host and tab and id ~= tab:GetID() then
        showOthers()
      end
    end)
  end
  if AuctionFrameTab_OnClick and not SL.ahClickHooked and hooksecurefunc then
    SL.ahClickHooked = true
    hooksecurefunc("AuctionFrameTab_OnClick", function(clicked)
      local id = clicked and clicked.GetID and clicked:GetID()
      if tab and id == tab:GetID() then
        hideBlizzardPages()
        if panel then panel:Show() end
        SL.RefreshAHPanel()
      else
        showOthers()
      end
    end)
  end
  layoutToken = layoutToken + 1
  local token = layoutToken
  place()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      if token ~= layoutToken then return end
      place()
    end)
  end
end
