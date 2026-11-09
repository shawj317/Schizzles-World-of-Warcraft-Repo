local _, ns = ...

-- Table of window themes. Add a key here to grow the list.
-- Class Colors copies the Wayfarer layout and tints the border, accents,
-- pin rings, and the default trail with the player's class color.

local function copyInsets(insets)
	return {
		left = insets.left,
		right = insets.right,
		top = insets.top,
		bottom = insets.bottom,
	}
end

local function copyColor(color)
	return { color[1], color[2], color[3] }
end

ns.THEMES = {
	wayfarer = {
		id = "wayfarer",
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
		bg = { 0.06, 0.06, 0.06 },
		border = { 0.72, 0.45, 0.2 },
		header = { 0.10, 0.08, 0.06 },
		title = { 1, 0.82, 0 },
		text = { 0.98, 0.96, 0.93 },
		cream = { 0.93, 0.88, 0.78 },
		muted = { 0.62, 0.56, 0.48 },
		accent = { 1, 0.82, 0 },
		tan = { 0.78, 0.61, 0.43 },
		ember = { 1, 0.47, 0 },
		trail = { 1, 0.82, 0 },
		pinRing = { 0.93, 0.88, 0.78 },
	},
	blizzard = {
		id = "blizzard",
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
		bg = { 1, 1, 1 },
		border = { 1, 0.82, 0 },
		header = { 0.12, 0.08, 0.02 },
		title = { 1, 0.82, 0 },
		text = { 1, 1, 1 },
		cream = { 1, 0.96, 0.82 },
		muted = { 0.78, 0.74, 0.62 },
		accent = { 1, 0.82, 0 },
		tan = { 1, 0.82, 0.45 },
		ember = { 1, 0.55, 0.1 },
		trail = { 1, 0.82, 0 },
		pinRing = { 1, 0.82, 0 },
	},
}

local CLASS_FALLBACK = { r = 0.72, g = 0.45, b = 0.2 }

function ns.ClassColorOrFallback(classColor)
	if type(classColor) == "table" then
		local r, g, b = tonumber(classColor.r), tonumber(classColor.g), tonumber(classColor.b)
		if r and g and b then
			return { r = r, g = g, b = b }, false
		end
	end
	return { r = CLASS_FALLBACK.r, g = CLASS_FALLBACK.g, b = CLASS_FALLBACK.b }, true
end

local function CloneTheme(source)
	local theme = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			if value.left then
				theme[key] = copyInsets(value)
			else
				theme[key] = copyColor(value)
			end
		else
			theme[key] = value
		end
	end
	return theme
end

function ns.ResolveTheme(id, classColor)
	local source = ns.THEMES[id] or ns.THEMES.wayfarer
	local theme = CloneTheme(source)
	if id == "class" then
		theme.id = "class"
		local color = ns.ClassColorOrFallback(classColor)
		local tint = { color.r, color.g, color.b }
		theme.border = copyColor(tint)
		theme.accent = copyColor(tint)
		theme.trail = copyColor(tint)
		theme.pinRing = copyColor(tint)
		theme.header = { color.r * 0.22, color.g * 0.22, color.b * 0.22 }
		theme.bg = { 0.05, 0.05, 0.05 }
		theme.bgFile = ns.THEMES.wayfarer.bgFile
		theme.edgeFile = ns.THEMES.wayfarer.edgeFile
		theme.edgeSize = ns.THEMES.wayfarer.edgeSize
		theme.insets = copyInsets(ns.THEMES.wayfarer.insets)
	end
	return theme
end

-- Backdrop description. showBorder false drops the edge and the insets so the
-- header can sit flush with the frame.
function ns.BackdropSpec(theme, alpha, showBorder)
	alpha = tonumber(alpha)
	if alpha == nil then
		alpha = 0.85
	end
	if alpha < 0 then
		alpha = 0
	elseif alpha > 1 then
		alpha = 1
	end
	local spec = {
		bgFile = theme.bgFile,
		tile = true,
		tileSize = 16,
		edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
		bg = theme.bg,
		bgAlpha = alpha,
		border = nil,
		pad = 2,
	}
	if showBorder ~= false then
		spec.edgeFile = theme.edgeFile
		spec.edgeSize = theme.edgeSize or 14
		spec.insets = copyInsets(theme.insets)
		spec.border = theme.border
		spec.pad = (spec.edgeSize >= 24) and 12 or 5
	end
	return spec
end

function ns.PlayerClassColor()
	if not UnitClass or not RAID_CLASS_COLORS then
		return nil
	end
	local ok, _, token = pcall(UnitClass, "player")
	if not ok or not token or (ns.IsSecret and ns.IsSecret(token)) then
		return nil
	end
	local entry = RAID_CLASS_COLORS[token]
	if type(entry) ~= "table" then
		return nil
	end
	local r, g, b = entry.r, entry.g, entry.b
	if ns.IsSecret and (ns.IsSecret(r) or ns.IsSecret(g) or ns.IsSecret(b)) then
		return nil
	end
	r, g, b = tonumber(r), tonumber(g), tonumber(b)
	if not r or not g or not b then
		return nil
	end
	return { r = r, g = g, b = b }
end
