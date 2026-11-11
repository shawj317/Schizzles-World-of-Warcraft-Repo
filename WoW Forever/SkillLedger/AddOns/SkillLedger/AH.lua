-- Modern AuctionHouseFrame tab (Forever / Camelot). Anchored after the last
-- tab already in the row, using AuctionHouseFrameDisplayModeTabTemplate the
-- way LibAHTab (Auctionator) does. Not inserted into AuctionHouseFrame.Tabs
-- and not passed to PanelTemplates_SetNumTabs, so Buy/Sell/Auctions and the
-- TSM tabs keep their own widths. No OnUpdate.

local SL = SkillLedger

local tab
local panel
local statusText
local layoutToken = 0
local hookedMode = false

local function camelotOffset()
  if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_CAMELOT
    and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT then
    return -14
  end
  return 3
end

local function remember(list, button)
  if not button or button == tab then return end
  for i = 1, #list do
    if list[i] == button then return end
  end
  list[#list + 1] = button
end

local function collect(parent, list, depth)
  if not parent or not parent.GetChildren or depth > 4 then return end
  local children = { parent:GetChildren() }
  for i = 1, #children do
    local child = children[i]
    if child and child.GetObjectType and child:GetObjectType() == "Button" then
      local text = child.GetText and child:GetText()
      local bottom = child.GetBottom and child:GetBottom()
      local parentBottom = parent.GetBottom and parent:GetBottom()
      if text and text ~= "" and bottom and parentBottom then
        local gap = bottom - parentBottom
        if gap > -40 and gap < 70 then remember(list, child) end
      end
    end
    if child then collect(child, list, depth + 1) end
  end
end

local function tabButtons()
  local list = {}
  local frame = AuctionHouseFrame
  if frame and frame.Tabs then
    for i = 1, #frame.Tabs do remember(list, frame.Tabs[i]) end
  end
  if frame then collect(frame, list, 0) end
  return list
end

local function rightmost(list)
  local best, bestRight
  for i = 1, #list do
    local button = list[i]
    local right = button.GetRight and button:GetRight()
    if right and (not bestRight or right > bestRight + 0.5) then
      best = button
      bestRight = right
    end
  end
  return best
end

local function hidePanel()
  if panel then panel:Hide() end
  if tab and PanelTemplates_DeselectTab then pcall(PanelTemplates_DeselectTab, tab) end
end

function SL.HideAHPanel()
  hidePanel()
end

function SL.RefreshAHPanel()
  if statusText and SL.ScanStatus then statusText:SetText(SL.ScanStatus()) end
end

local function watch(button)
  if not button or button == tab or button.skillLedgerHooked or not button.HookScript then return end
  button.skillLedgerHooked = true
  button:HookScript("OnClick", function(self)
    if self ~= tab then hidePanel() end
  end)
end

local function selectUs()
  if not tab or not AuctionHouseFrame then return end
  if AuctionHouseFrame.SetDisplayMode then
    pcall(AuctionHouseFrame.SetDisplayMode, AuctionHouseFrame, {})
  end
  if AuctionHouseFrame.Tabs and PanelTemplates_DeselectTab then
    for i = 1, #AuctionHouseFrame.Tabs do
      pcall(PanelTemplates_DeselectTab, AuctionHouseFrame.Tabs[i])
    end
  end
  local others = tabButtons()
  if PanelTemplates_DeselectTab then
    for i = 1, #others do pcall(PanelTemplates_DeselectTab, others[i]) end
  end
  if PanelTemplates_SelectTab then pcall(PanelTemplates_SelectTab, tab) end
  if AuctionHouseFrame.SetTitle then pcall(AuctionHouseFrame.SetTitle, AuctionHouseFrame, "SkillLedger") end
  if panel then
    panel:Show()
    SL.RefreshAHPanel()
  end
end

local function place()
  if not tab or not AuctionHouseFrame then return end
  local others = tabButtons()
  for i = 1, #others do watch(others[i]) end
  local anchor = rightmost(others)
  tab:ClearAllPoints()
  if anchor then
    tab:SetPoint("TOPLEFT", anchor, "TOPRIGHT", camelotOffset(), 0)
  elseif AuctionHouseFrame.Tabs and AuctionHouseFrame.Tabs[#AuctionHouseFrame.Tabs] then
    tab:SetPoint("TOPLEFT", AuctionHouseFrame.Tabs[#AuctionHouseFrame.Tabs], "TOPRIGHT", camelotOffset(), 0)
  end
end

local function paint(widget)
  local backdrop = widget:CreateTexture(nil, "BACKGROUND")
  backdrop:SetAllPoints()
  if backdrop.SetColorTexture then
    backdrop:SetColorTexture(0.05, 0.05, 0.05, 0.94)
  else
    backdrop:SetTexture("Interface\\Buttons\\WHITE8x8")
    backdrop:SetVertexColor(0.05, 0.05, 0.05, 0.94)
  end
end

local function makePanel()
  local frame = CreateFrame("Frame", "SkillLedgerAHPanel", AuctionHouseFrame)
  frame:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPLEFT", 6, -26)
  frame:SetPoint("BOTTOMRIGHT", AuctionHouseFrame, "BOTTOMRIGHT", -6, 38)
  paint(frame)
  frame:SetFrameLevel((AuctionHouseFrame:GetFrameLevel() or 1) + 10)
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("SkillLedger")
  statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  statusText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  statusText:SetJustifyH("LEFT")
  statusText:SetWidth(460)
  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetSize(140, 24)
  button:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -16)
  button:SetText("Scan")
  button:SetScript("OnClick", function()
    if SL.StartScan then SL.StartScan() end
    SL.RefreshAHPanel()
  end)
  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  note:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -12)
  note:SetWidth(460)
  note:SetJustifyH("LEFT")
  note:SetText("Forever uses the retail auction house. The scan calls C_AuctionHouse.ReplicateItems when the client allows it, and otherwise searches each reagent with SendSearchQuery, waiting out the throttle.")
  frame:Hide()
  return frame
end

local function makeTab()
  local button = CreateFrame("Button", "SkillLedgerAHTab", AuctionHouseFrame, "AuctionHouseFrameDisplayModeTabTemplate")
  button:SetText("SkillLedger")
  if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, button, 20, nil, 70) end
  if PanelTemplates_DeselectTab then pcall(PanelTemplates_DeselectTab, button) end
  button:SetScript("OnClick", selectUs)
  return button
end

function SL.EnsureAHTab()
  if not AuctionHouseFrame or not CreateFrame then return end
  if not tab then
    local ok, created = pcall(makeTab)
    if not ok or not created then
      if SL.Say then SL.Say("could not add an auction house tab (" .. tostring(created) .. ").") end
      return
    end
    tab = created
  end
  if not panel then
    local ok, created = pcall(makePanel)
    if ok then panel = created end
  end
  if not hookedMode and hooksecurefunc and AuctionHouseFrame.SetDisplayMode then
    hookedMode = true
    hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function(_, mode)
      if mode == nil then return end
      if type(mode) == "table" and #mode == 0 then return end
      hidePanel()
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
    C_Timer.After(0.3, function()
      if token ~= layoutToken then return end
      place()
    end)
  end
end
