-- The SkillLedger window. It is not closed by Escape, and it is not redrawn
-- from OnUpdate or from bag events. Text changes when you open it or plan.

local SL = SkillLedger
local P = SkillLedgerPlan

local frame
local body

local function font(widget, size)
  local face = (GameFontNormal and GameFontNormal.GetFont and GameFontNormal:GetFont()) or "Fonts\\FRIZQT__.TTF"
  widget:SetFont(face, size or 12, "")
end

local function colorize(texture, r, g, b, a)
  if texture.SetColorTexture then
    texture:SetColorTexture(r, g, b, a)
  else
    texture:SetTexture("Interface\\Buttons\\WHITE8x8")
    texture:SetVertexColor(r, g, b, a)
  end
end

local function paint(widget)
  local backdrop = widget:CreateTexture(nil, "BACKGROUND")
  backdrop:SetAllPoints()
  colorize(backdrop, 0.06, 0.06, 0.06, 0.94)
  local edge = widget:CreateTexture(nil, "BORDER")
  edge:SetPoint("TOPLEFT", -1, 1)
  edge:SetPoint("BOTTOMRIGHT", 1, -1)
  colorize(edge, 0.72, 0.45, 0.2, 0.9)
  local inner = widget:CreateTexture(nil, "BORDER")
  inner:SetPoint("TOPLEFT")
  inner:SetPoint("BOTTOMRIGHT")
  colorize(inner, 0.06, 0.06, 0.06, 0.94)
end

local function clock(stamp)
  if not stamp or stamp == 0 then return "never" end
  if date then return date("%Y-%m-%d %H:%M", stamp) end
  return tostring(stamp)
end

local function reagentLine(reagent)
  local buy = reagent.buy or 0
  local stock = reagent.fromStock or 0
  local text = reagent.name
  if stock > 0.05 then text = text .. " " .. string.format("%.1f from bags", stock) end
  if buy > 0.05 then text = text .. " buy " .. string.format("%.1f", buy) end
  return text
end

function SL.PlanText(result)
  local char = SL.Char()
  local lines = {}
  lines[#lines + 1] = (char.name or "") .. "  " .. (char.faction or "") .. " " .. (char.classFile or "")
  local priced = 0
  local prices = SL.DB().prices
  for i = 1, #(prices.items or {}) do
    if prices.items[i].unit and prices.items[i].unit > 0 then priced = priced + 1 end
  end
  lines[#lines + 1] = "Bags " .. clock(char.bags.updated) .. "   Bank " .. clock(char.bank.updated)
  lines[#lines + 1] = "Auctions " .. clock(prices.updated) .. " (" .. priced .. " prices)"
  lines[#lines + 1] = "Reputation " .. clock(char.standings.updated) .. "   Merchant " .. clock(char.merchant.updated)
  lines[#lines + 1] = "Vendor discount: Friendly 5%, Honored 10%, Revered 15%, Exalted 20%."
  lines[#lines + 1] = "A price from a merchant window is used while that standing is unchanged."
  if not result then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Press Plan. Nothing is calculated until you ask."
    return table.concat(lines, "\n")
  end
  for i = 1, #result.plans do
    local plan = result.plans[i]
    lines[#lines + 1] = ""
    lines[#lines + 1] = plan.name .. "  " .. plan.rank .. " to " .. plan.cap .. "   " .. P.Money(plan.total)
    for n = 1, #plan.notes do lines[#lines + 1] = plan.notes[n] end
    if #plan.steps == 0 then lines[#lines + 1] = "No craft steps." end
    for s = 1, #plan.steps do
      local step = plan.steps[s]
      lines[#lines + 1] = step.start .. "-" .. step.finish .. "  " .. step.recipe .. "  x" .. string.format("%.1f", step.crafts) .. "  " .. P.Money(step.cost)
      local bits = {}
      for r = 1, #step.reagents do bits[#bits + 1] = reagentLine(step.reagents[r]) end
      if #bits > 0 then lines[#lines + 1] = "  " .. table.concat(bits, "; ") end
      for d = 1, #step.discounts do lines[#lines + 1] = "  " .. step.discounts[d] end
      for u = 1, #step.unpriced do lines[#lines + 1] = "  no price: " .. step.unpriced[u] end
    end
  end
  if result.shopping and #result.shopping > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Shopping list (your stock is subtracted once)"
    local total = 0
    for i = 1, #result.shopping do
      local row = result.shopping[i]
      if row.buyWhole and row.buyWhole > 0 then
        total = total + (row.cost or 0)
        local discount = ""
        if row.discount and row.discount > 0 then discount = "  " .. row.discount .. "% " .. (row.faction or "") end
        if row.source == "merchant" then discount = "  merchant" .. discount end
        lines[#lines + 1] = row.buyWhole .. " " .. row.name .. "  " .. P.Money(row.cost or 0) .. discount
      end
    end
    lines[#lines + 1] = "Buy total " .. P.Money(total)
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Log out or /reload, then run export.py on SavedVariables\\SkillLedger.lua."
  return table.concat(lines, "\n")
end

function SL.Refresh()
  if not body then return end
  body:SetText(SL.PlanText(SL.lastPlan))
  local height = body:GetStringHeight() or 40
  if height < 40 then height = 40 end
  body:SetHeight(height)
  if body:GetParent() then body:GetParent():SetHeight(height + 8) end
end

local function button(parent, label, x, fn)
  local widget = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  widget:SetSize(72, 20)
  widget:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, 8)
  widget:SetText(label)
  widget:SetScript("OnClick", fn)
  return widget
end

function SL.Show()
  if not frame then
    frame = CreateFrame("Frame", "SkillLedgerFrame", UIParent)
    frame:SetSize(460, 520)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(widget) widget:StartMoving() end)
    frame:SetScript("OnDragStop", function(widget)
      widget:StopMovingOrSizing()
      local _, _, _, x, y = widget:GetPoint(1)
      local ui = SL.DB().ui
      ui.x = x
      ui.y = y
    end)
    if frame.EnableKeyboard then frame:EnableKeyboard(false) end
    if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(true) end
    paint(frame)
    local ui = SL.DB().ui
    frame:SetPoint("CENTER", UIParent, "CENTER", ui.x or -480, ui.y or 40)
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", 12, -10)
    font(title, 16)
    title:SetTextColor(1, 0.82, 0)
    title:SetText("SkillLedger")
    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", 10, -32)
    scroll:SetPoint("BOTTOMRIGHT", -28, 36)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(400, 40)
    scroll:SetScrollChild(child)
    body = child:CreateFontString(nil, "OVERLAY")
    body:SetPoint("TOPLEFT", 4, -4)
    body:SetWidth(400)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    font(body, 12)
    body:SetTextColor(0.9, 0.86, 0.78)
    local slider = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
    slider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -48)
    slider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 48)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(20)
    slider:SetValue(0)
    slider:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    scroll:SetScript("OnScrollRangeChanged", function(_, _, range)
      local maxValue = range or 0
      if maxValue < 0 then maxValue = 0 end
      slider:SetMinMaxValues(0, maxValue)
    end)
    button(frame, "Plan", 8, function()
      SL.PrintPlan(SL.Plan())
      SL.Refresh()
    end)
    button(frame, "Scan", 84, function() SL.StartScan() end)
    button(frame, "Bags", 160, function()
      SL.SnapshotBags()
      SL.Refresh()
    end)
    button(frame, "Bank", 236, function()
      SL.SnapshotBank(true)
      SL.Refresh()
    end)
    button(frame, "Close", 312, function() frame:Hide() end)
  end
  frame:Show()
  SL.Refresh()
end

function SL.Hide()
  if frame then frame:Hide() end
end

function SL.Toggle()
  if frame and frame:IsShown() then SL.Hide() else SL.Show() end
end
