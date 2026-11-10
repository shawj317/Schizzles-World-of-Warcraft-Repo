-- TomTom waypoints and numbered pins on the world map.
-- QuestRoute by Jon Shaw (Schizzle).

local _, ns = ...

local routePins = {}
local routeKey
local waypointKey
local activePlan
local arrowUID
local worldPool = {}
local mapHooked = false

local function RouteSignature(plan)
	local parts = {}
	local steps = plan and plan.steps or {}
	for i = 1, #steps do
		local step = steps[i]
		if step.x and step.y then
			parts[#parts + 1] = i .. ":" .. (step.uiMap or 0) .. ":" .. math.floor(step.x * 10) .. ":" .. math.floor(step.y * 10)
		end
	end
	return table.concat(parts, "|")
end

local function StepTitle(step, index)
	return index .. ". " .. (step.title or step.questName or "Step")
end

local function SameStep(a, b)
	if a == b then
		return true
	end
	if not a or not b then
		return false
	end
	return a.questId == b.questId and a.title == b.title and a.verb == b.verb and a.x == b.x and a.y == b.y
end

local function StepIndex(steps, step)
	for i = 1, #(steps or {}) do
		if SameStep(steps[i], step) then
			return i
		end
	end
	return 1
end

local function PlaceTomTom(steps, allSteps, focusIndex, announce, focusStep)
	if not TomTom or not ns.ReplaceWaypoints then
		if announce then
			ns:Print(ns.L.NO_TOMTOM)
		end
		return
	end
	if focusStep and (not focusStep.x or not focusStep.y) then
		if announce then
			ns:Print(string.format(ns.L.NO_MAP_PIN_STEP, focusStep.title or "That step"))
		end
		return
	end
	local planKey = ns.WaypointPlanKey and ns.WaypointPlanKey(steps, allSteps, focusIndex)
	if planKey and planKey == waypointKey and ns.CacheStillValid and ns.CacheStillValid(TomTom, routePins, planKey) then
		return
	end
	routePins, arrowUID = ns.ReplaceWaypoints(TomTom, routePins, steps, allSteps, focusIndex)
	waypointKey = planKey
	if announce and arrowUID then
		local title = focusStep and (focusStep.title or focusStep.questName) or "the step"
		ns:Print(string.format(ns.L.ARROW_SET, title))
	elseif announce then
		ns:Print(ns.L.TOMTOM_REFUSED)
	end
end

function ns.SweepTomTom()
	if TomTom and ns.RemoveOurWaypoints then
		routePins = ns.RemoveOurWaypoints(TomTom, routePins)
		arrowUID = nil
		waypointKey = nil
	end
end

local function FocusArrow(step, announce)
	if not step then
		return
	end
	local steps = activePlan and activePlan.steps or { step }
	local index = StepIndex(steps, step)
	if not steps[index] or not SameStep(steps[index], step) then
		steps = { step }
		index = 1
	end
	local all = ns.Settings().useTomTom and true or false
	PlaceTomTom(steps, all, index, announce, step)
end

local function PointAt(step, announce)
	FocusArrow(step, announce)
end

local TEX = "Interface\\AddOns\\Wayfarer\\Textures\\"

local function ReleaseAll(pool)
	if type(pool) ~= "table" then
		return
	end
	for i = 1, #pool do
		pool[i].free = true
		if pool[i].Hide then
			pool[i]:Hide()
		end
	end
end

local function Claim(pool, create)
	for i = 1, #pool do
		if pool[i].free then
			pool[i].free = false
			if pool[i].Show then
				pool[i]:Show()
			end
			return pool[i]
		end
	end
	local item = create()
	item.free = false
	pool[#pool + 1] = item
	return item
end

local function HidePool(pool)
	ReleaseAll(pool)
end

local function Tex(parent, layer, name, point, x, y)
	local texture = parent:CreateTexture(nil, layer)
	texture:SetTexture(TEX .. name)
	texture:SetPoint("CENTER", parent, point or "CENTER", x or 0, y or 0)
	return texture
end

local function MakePin(parent)
	local pin = CreateFrame("Button", nil, parent)
	pin:SetSize(20, 20)
	if pin.SetClipsChildren then
		pin:SetClipsChildren(false)
	end
	pin.shadow = Tex(pin, "BACKGROUND", "disc", "CENTER", 1, -2)
	pin.glow = Tex(pin, "BACKGROUND", "glow", "CENTER", 0, 0)
	pin.ring = Tex(pin, "BORDER", "ring", "CENTER", 0, 0)
	pin.disc = Tex(pin, "ARTWORK", "disc", "CENTER", 0, 0)
	local label = pin:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("CENTER", 0.5, 0)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	pin.label = label
	pin:SetScript("OnEnter", function(self)
		if not self.tip or not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tip, 1, 0.82, 0)
		GameTooltip:Show()
	end)
	pin:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	return pin
end

local function TakeMapPin(pool, parent)
	local pin = Claim(pool, function()
		return MakePin(parent)
	end)
	pin:SetParent(parent)
	pin:Show()
	return pin
end

local function PinDisc(verb)
	if verb == "pick up" then
		return 1, 0.82, 0
	end
	if verb == "turn in" then
		return 1, 0.47, 0
	end
	return 0.72, 0.45, 0.2
end

local function StylePin(pin, index, step, current)
	local db = ns.Settings()
	local size = db.pinSize or 20
	local text = tostring(index)
	local wide = string.len(text) > 1
	pin:SetSize(size, size)
	local function fit(texture, scale, dx, dy)
		texture:SetSize(size * scale, size * scale)
		texture:ClearAllPoints()
		texture:SetPoint("CENTER", pin, "CENTER", dx or 0, dy or 0)
	end
	fit(pin.shadow, 0.92, 1, -2)
	pin.shadow:SetVertexColor(0, 0, 0, 0.45)
	fit(pin.glow, 1.55, 0, 0)
	fit(pin.ring, 1, 0, 0)
	fit(pin.disc, 0.72, 0, 0)
	local dr, dg, dbc = PinDisc(step and step.verb)
	pin.disc:SetVertexColor(dr, dg, dbc, 0.96)
	if current then
		local ar, ag, ab = 1, 0.82, 0
		if ns.ResolveTheme then
			local theme = ns.ResolveTheme(ns.Settings().theme, ns.PlayerClassColor and ns.PlayerClassColor() or nil)
			ar, ag, ab = theme.accent[1], theme.accent[2], theme.accent[3]
		end
		pin.ring:SetVertexColor(ar, ag, ab, 1)
		pin.glow:SetVertexColor(ar, ag, ab, 0.55)
		pin.glow:Show()
	else
		local rr, rg, rb = 0.93, 0.88, 0.78
		if ns.ResolveTheme then
			local theme = ns.ResolveTheme(ns.Settings().theme, ns.PlayerClassColor and ns.PlayerClassColor() or nil)
			rr, rg, rb = theme.pinRing[1], theme.pinRing[2], theme.pinRing[3]
		end
		pin.ring:SetVertexColor(rr, rg, rb, 0.95)
		pin.glow:Hide()
	end
	pin.label:SetText(text)
	local face = GameFontHighlight and GameFontHighlight:GetFont()
	local pixels = wide and math.max(8, size * 0.38) or math.max(9, size * 0.46)
	if face then
		pcall(pin.label.SetFont, pin.label, face, pixels, "OUTLINE")
	end
	pin.label:SetTextColor(1, 0.98, 0.94)
end

local function NudgePins(placed)
	local gap = (ns.Settings().pinSize or 20) + 4
	local order = {}
	for index, point in pairs(placed) do
		if type(index) == "number" and point.x then
			order[#order + 1] = index
		end
	end
	table.sort(order)
	for n = 2, #order do
		local point = placed[order[n]]
		for m = 1, n - 1 do
			local other = placed[order[m]]
			local dx = point.x - other.x
			local dy = point.y - other.y
			if dx * dx + dy * dy < gap * gap then
				local angle = n * 1.2
				point.x = other.x + math.cos(angle) * (gap + 2)
				point.y = other.y + math.sin(angle) * (gap + 2)
			end
		end
	end
end

local function ShownWorldMap()
	if not WorldMapFrame or not WorldMapFrame:IsShown() then
		return nil, nil
	end
	local mapID
	if WorldMapFrame.GetMapID then
		mapID = WorldMapFrame:GetMapID()
	elseif GetCurrentMapAreaID then
		mapID = GetCurrentMapAreaID()
	end
	local canvas
	if WorldMapFrame.GetCanvas then
		local ok, value = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
		if ok then
			canvas = value
		end
	end
	if not canvas and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
		canvas = WorldMapFrame.ScrollContainer.Child
	end
	if not canvas then
		canvas = WorldMapDetailFrame or WorldMapButton
	end
	return canvas, mapID
end

local function UpdateWorldPins(plan)
	HidePool(worldPool)
	local canvas, mapID = ShownWorldMap()
	local db = ns.Settings()
	if not canvas or not plan or not db.showOnMap then
		return
	end
	local width, height = canvas:GetWidth(), canvas:GetHeight()
	if not width or width < 20 or ns.IsSecret(width) then
		return
	end
	local baseLevel = 1
	if type(canvas.GetFrameLevel) == "function" then
		baseLevel = canvas:GetFrameLevel() or 1
	end
	local placed = {}
	local steps = plan.steps or {}
	local shown = 0
	for i = 1, #steps do
		local step = steps[i]
		if step.x and step.y and step.uiMap and (not mapID or step.uiMap == mapID) and shown < 40 then
			shown = shown + 1
			local px = step.x / 100 * width
			local py = -step.y / 100 * height
			placed[i] = { x = px, y = py, step = step }
		end
	end
	NudgePins(placed)
	for i = 1, #steps do
		local spot = placed[i]
		if spot then
			local pin = TakeMapPin(worldPool, canvas)
			pin:SetFrameStrata("HIGH")
			pin:SetFrameLevel(baseLevel + 20 + i)
			StylePin(pin, i, spot.step, i == 1)
			pin:ClearAllPoints()
			pin:SetPoint("CENTER", canvas, "TOPLEFT", spot.x, spot.y)
			pin.tip = StepTitle(spot.step, i)
			local captured = spot.step
			pin:SetScript("OnClick", function()
				PointAt(captured, true)
			end)
		end
	end
end

local function EnsureMapHooks()
	if mapHooked or not WorldMapFrame or not WorldMapFrame.HookScript then
		return
	end
	mapHooked = true
	WorldMapFrame:HookScript("OnShow", function()
		if activePlan then
			UpdateWorldPins(activePlan)
		end
	end)
	WorldMapFrame:HookScript("OnHide", function()
		HidePool(worldPool)
	end)
end

local function SyncRoute(plan, focusStep, announce)
	activePlan = plan
	local steps = plan and plan.steps or {}
	local index = focusStep and StepIndex(steps, focusStep) or 1
	local aim = focusStep or steps[index]
	PlaceTomTom(steps, ns.Settings().useTomTom and true or false, index, announce and true or false, aim)
	routeKey = RouteSignature(plan)
	EnsureMapHooks()
	local db = ns.Settings()
	if not db.showOnMap then
		HidePool(worldPool)
		return
	end
	UpdateWorldPins(plan)
end

ns.FocusArrow = FocusArrow
ns.PointAt = PointAt
ns.SyncRoute = SyncRoute
ns.EnsureMapHooks = EnsureMapHooks

function ns.InvalidateRoute()
	routeKey = nil
end
