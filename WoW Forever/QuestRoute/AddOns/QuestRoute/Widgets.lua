local _, ns = ...

-- Shared type, backdrop, and buttons. Colours match the rest of Schizzle's Forever UI:
-- charcoal, bronze, and gold.

local GOLD = { 1, 0.82, 0 }
local CREAM = { 0.93, 0.88, 0.78 }
local WHITE = { 0.98, 0.96, 0.93 }
local MUTED = { 0.62, 0.56, 0.48 }
local TAN = { 0.78, 0.61, 0.43 }
local EMBER = { 1, 0.47, 0 }
local RED = { 0.86, 0.28, 0.22 }

ns.colors = {
	GOLD = GOLD,
	CREAM = CREAM,
	WHITE = WHITE,
	MUTED = MUTED,
	TAN = TAN,
	EMBER = EMBER,
	RED = RED,
}

local BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Index 1 through 6 is the 1.0.5 font list. Do not reorder it: QuestRouteDB.font stores the index.
local FONT_CHOICES = {
	{ "Game font" },
	{ "Friz Quadrata", "Fonts\\FRIZQT__.TTF" },
	{ "Arial Narrow", "Fonts\\ARIALN.TTF" },
	{ "Morpheus", "Fonts\\MORPHEUS.TTF" },
	{ "Skurri", "Fonts\\SKURRI.TTF" },
	{ "PT Sans Narrow Bold", "Interface\\AddOns\\QuestRoute\\Fonts\\PTSansNarrow-Bold.ttf" },
}
ns.FONT_CHOICES = FONT_CHOICES

local styled = {}

function ns.FontFile()
	local choice = FONT_CHOICES[ns.Settings().font] or FONT_CHOICES[1]
	return choice[1], choice[2]
end

function ns.Scaled(size)
	return math.max(8, math.floor(size * ns.Settings().fontSize / 13 + 0.5))
end

local function ApplyFace(fs, pixels)
	local _, file = ns.FontFile()
	local inherit, _, flags
	if GameFontHighlight and GameFontHighlight.GetFont then
		inherit, _, flags = GameFontHighlight:GetFont()
	end
	flags = flags or ""
	local applied = false
	if file then
		local ok, result = pcall(fs.SetFont, fs, file, pixels, flags)
		applied = ok and result
	end
	if not applied and inherit then
		pcall(fs.SetFont, fs, inherit, pixels, flags)
	end
	if fs.SetShadowColor then
		fs:SetShadowColor(0, 0, 0, 0.85)
		fs:SetShadowOffset(1, -1)
	end
end

local function PaintString(fs, info)
	ApplyFace(fs, ns.Scaled(info.size))
	if info.color then
		fs:SetTextColor(info.color[1], info.color[2], info.color[3])
	end
	fs:SetJustifyH(info.justify or "LEFT")
	fs:SetJustifyV("TOP")
	fs:SetWordWrap(info.wrap ~= false)
end

function ns.Style(fs, size, color, justify, wrap)
	local info = { size = size, color = color, justify = justify or "LEFT", wrap = wrap }
	styled[fs] = info
	PaintString(fs, info)
end

function ns.ApplyTypography()
	if ns.fontNameFS then
		ns.fontNameFS:SetText(ns.FontFile())
	end
	for fs, info in pairs(styled) do
		if fs.SetText then
			PaintString(fs, info)
		end
	end
	if ns.mainFrame and ns.mainFrame:IsShown() and ns.mainFrame.plan and ns.Render then
		ns.Render(ns.mainFrame.plan)
	end
end

function ns.Paint(frame)
	if not frame.SetBackdrop then
		return
	end
	frame:SetBackdrop(BACKDROP)
	frame:SetBackdropColor(0.06, 0.06, 0.06, 0.96)
	frame:SetBackdropBorderColor(0.72, 0.45, 0.2, 1)
end

function ns.Frame(kind, name, parent, template)
	local backdrop = "BackdropTemplate"
	local full = template and (backdrop .. "," .. template) or backdrop
	local ok, frame = pcall(CreateFrame, kind or "Frame", name, parent, full)
	if ok then
		return frame
	end
	return CreateFrame(kind or "Frame", name, parent, template)
end

function ns.SavePoint(frame, key)
	local db = ns.Settings()
	local point, _, relative, x, y = frame:GetPoint(1)
	db[key] = { point, relative, x, y }
end

function ns.LoadPoint(frame, key, fallback)
	local saved = ns.Settings()[key]
	frame:ClearAllPoints()
	if type(saved) == "table" and saved[1] and not ns.IsSecret(saved[1]) then
		frame:SetPoint(saved[1], UIParent, saved[2] or "CENTER", saved[3] or 0, saved[4] or 0)
	else
		frame:SetPoint(fallback[1], UIParent, fallback[2], fallback[3], fallback[4])
	end
end

function ns.Ellipsize(text, maxLen)
	text = text or ""
	if string.len(text) <= maxLen then
		return text
	end
	return string.sub(text, 1, maxLen - 3) .. "..."
end

function ns.Cap(text)
	text = text or ""
	if text == "" then
		return text
	end
	return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

function ns.Tip(owner, title, body)
	if not GameTooltip or not owner then
		return
	end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(title or "", GOLD[1], GOLD[2], GOLD[3])
	if body and body ~= "" then
		GameTooltip:AddLine(body, CREAM[1], CREAM[2], CREAM[3], true)
	end
	GameTooltip:Show()
end

function ns.TextButton(parent, label, onClick, width, tip)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 110, 22)
	button:SetText(label)
	local face = button.GetFontString and button:GetFontString()
	if face then
		ns.Style(face, 12, nil, "CENTER", false)
	end
	button:SetScript("OnClick", onClick)
	if tip then
		button:SetScript("OnEnter", function(self)
			ns.Tip(self, label, tip)
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	return button
end

function ns.CloseButton(parent)
	local button = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
	button:SetSize(24, 24)
	button:SetPoint("TOPRIGHT", -2, -2)
	button:SetScript("OnClick", function()
		parent:Hide()
	end)
	button:SetScript("OnEnter", function(self)
		ns.Tip(self, ns.L.CLOSE, nil)
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	return button
end

function ns.Rule(parent, y, alpha)
	local rule = parent:CreateTexture(nil, "ARTWORK")
	rule:SetPoint("TOPLEFT", 12, y)
	rule:SetPoint("TOPRIGHT", -12, y)
	rule:SetHeight(1)
	rule:SetTexture("Interface\\Buttons\\WHITE8X8")
	rule:SetVertexColor(0.72, 0.45, 0.2, alpha or 0.85)
	return rule
end
