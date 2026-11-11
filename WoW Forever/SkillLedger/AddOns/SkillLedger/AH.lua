-- Modern AuctionHouseFrame tab (Forever / Camelot).
-- AuctionHouseFrameDisplayModeTabTemplate has parentArray="Tabs", so creating
-- the button on AuctionHouseFrame inserts it into AuctionHouseFrame.Tabs.
-- LibAHTab (Auctionator, and TSM when it uses that library) anchors its row
-- to AuctionHouseFrame.Tabs[#] once. If SkillLedger is that entry, the whole
-- addon row detaches and follows SkillLedger. The button is removed from
-- Tabs immediately and is never passed to PanelTemplates_SetNumTabs. After
-- AUCTION_HOUSE_SHOW yields, it anchors TOPLEFT to the end of the row that
-- starts at the real last Tabs entry. No OnUpdate, and no SetPoint on any
-- other addon's tab.

local SL = SkillLedger

local tab
local panel
local statusText
local layoutToken = 0
local hookedMode = false
local savedW, savedH
local restoring = false
local place

local function camelotOffset()
  if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_CAMELOT
    and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT then
    return -14
  end
  return 3
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

local function rememberSize()
  if restoring or not AuctionHouseFrame or not AuctionHouseFrame.GetSize then return end
  local w, h = AuctionHouseFrame:GetSize()
  if w and h and w > 400 and h > 300 then
    savedW, savedH = w, h
  end
end

local function restoreSize()
  if not savedW or not AuctionHouseFrame or not AuctionHouseFrame.SetSize then return end
  local w, h = AuctionHouseFrame:GetSize()
  if not w or math.abs(w - savedW) < 2 and math.abs(h - savedH) < 2 then return end
  restoring = true
  AuctionHouseFrame:SetSize(savedW, savedH)
  restoring = false
end

local function ejectFromTabs(button)
  local tabs = AuctionHouseFrame and AuctionHouseFrame.Tabs
  if type(tabs) ~= "table" or not button then return end
  for i = #tabs, 1, -1 do
    if tabs[i] == button then
      table.remove(tabs, i)
    end
  end
end

local function safeAnchor(frame)
  if not frame or frame == tab or frame == UIParent then return false end
  return frame.GetPoint ~= nil
end

local function rightEdge(frame)
  if frame and frame.GetRight then
    local right = frame:GetRight()
    if type(right) == "number" then return right end
  end
  return nil
end

local function followersOf(anchor)
  local found = {}
  local function scan(parent, depth)
    if not parent or depth > 8 or not parent.GetChildren then return end
    local children = { parent:GetChildren() }
    for i = 1, #children do
      local child = children[i]
      if child and child ~= tab and child ~= parent and child.GetPoint then
        local point, relativeTo = child:GetPoint(1)
        if point == "TOPLEFT" and relativeTo == anchor and safeAnchor(child) then
          found[#found + 1] = child
        end
        scan(child, depth + 1)
      end
    end
  end
  if AuctionHouseFrame then scan(AuctionHouseFrame, 0) end
  return found
end

local function endOfRow(start)
  local current = start
  local seen = {}
  for _ = 1, 40 do
    if not current or seen[current] then break end
    seen[current] = true
    local nexts = followersOf(current)
    local best, bestRight
    for i = 1, #nexts do
      if nexts[i] ~= tab then
        local right = rightEdge(nexts[i])
        if not best or (right and (not bestRight or right > bestRight)) then
          best = nexts[i]
          bestRight = right
        end
      end
    end
    if not best then break end
    current = best
  end
  return current
end

local function selectUs()
  if not tab or not AuctionHouseFrame then return end
  -- Do not call SetDisplayMode. An empty mode collapses AuctionHouseFrame.
  rememberSize()
  restoreSize()
  if AuctionHouseFrame.Tabs and PanelTemplates_DeselectTab then
    for i = 1, #AuctionHouseFrame.Tabs do
      if AuctionHouseFrame.Tabs[i] ~= tab then
        pcall(PanelTemplates_DeselectTab, AuctionHouseFrame.Tabs[i])
      end
    end
  end
  if PanelTemplates_SelectTab then pcall(PanelTemplates_SelectTab, tab) end
  if panel then
    if savedW and panel.SetSize then
      panel:SetSize(savedW - 12, math.max(120, savedH - 70))
    end
    panel:Show()
    SL.RefreshAHPanel()
  end
  place()
end

place = function()
  if not tab or not AuctionHouseFrame or type(AuctionHouseFrame.Tabs) ~= "table" then return end
  ejectFromTabs(tab)
  if tab.GetParent and tab:GetParent() ~= AuctionHouseFrame and tab.SetParent then
    tab:SetParent(AuctionHouseFrame)
  end
  local tabs = AuctionHouseFrame.Tabs
  local anchor, bestRight
  for i = 1, #tabs do
    local origin = tabs[i]
    if safeAnchor(origin) then
      local finish = endOfRow(origin)
      if not safeAnchor(finish) then finish = origin end
      local right = rightEdge(finish)
      if not anchor or (right and (not bestRight or right >= bestRight)) or (not right and not bestRight) then
        anchor = finish
        bestRight = right
      end
    end
  end
  if not safeAnchor(anchor) then return end
  tab:ClearAllPoints()
  tab:SetPoint("TOPLEFT", anchor, "TOPRIGHT", camelotOffset(), 0)
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
  local w, h = 780, 460
  if AuctionHouseFrame.GetSize then
    local fw, fh = AuctionHouseFrame:GetSize()
    if fw and fw > 200 then w = fw - 12 end
    if fh and fh > 200 then h = fh - 70 end
  end
  frame:SetSize(w, h)
  frame:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPLEFT", 6, -26)
  paint(frame)
  frame:SetFrameLevel((AuctionHouseFrame:GetFrameLevel() or 1) + 20)
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
  -- The template's parentArray inserts this button into AuctionHouseFrame.Tabs
  -- before CreateFrame returns. Take it back out before any other addon reads
  -- the end of that array.
  ejectFromTabs(button)
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
  rememberSize()
  if not hookedMode and AuctionHouseFrame.HookScript then
    hookedMode = true
    if hooksecurefunc and AuctionHouseFrame.SetDisplayMode then
      hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function()
        hidePanel()
      end)
    end
    AuctionHouseFrame:HookScript("OnSizeChanged", function(_, w, h)
      if restoring then return end
      if panel and panel.IsShown and panel:IsShown() then
        restoreSize()
        return
      end
      if w and h and w > 400 and h > 300 then
        savedW, savedH = w, h
      end
    end)
  end
  layoutToken = layoutToken + 1
  local token = layoutToken
  -- Other AH addons add their tabs from this same AUCTION_HOUSE_SHOW, some
  -- of them from C_Timer.After(0). Anchor only after that has run.
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      if token ~= layoutToken then return end
      place()
      C_Timer.After(0, function()
        if token ~= layoutToken then return end
        place()
      end)
    end)
  else
    place()
  end
end
